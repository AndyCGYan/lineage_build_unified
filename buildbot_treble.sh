#!/bin/bash
echo ""
echo "LineageOS 18.x Treble Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
BL=$PWD/treble_build_los

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/manifest.xml
cp $BL/foss.xml .repo/local_manifests/manifest.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

#(Optional patch) remove foss apps except me.phh.superuser
#If you just use superuser don't want build foss, you can use this patch
cd vendor/foss
git am $BL/patches/0001-Just-keep-me.phh.superuser-and-remove-others.patch
cd ../..

#Update foss apps
echo "Update foss apps"
cd vendor/foss
git clean -fdx #Remove old apps or tmp
bash update.sh
cd ../..

repopick -t eleven-dialer-master
repopick -t eleven-telephony-master
repopick 289372 # Messaging: Add "Mark as read" quick action for message notifications

echo "Reverting LOS FOD implementation"
cd frameworks/base
git am $BL/patches/0001-Squashed-revert-of-LOS-FOD-implementation.patch
cd ../..
cd frameworks/native
git revert 381416d540ea92dca5f64cd48fd8c9dc887cac7b --no-edit # surfaceflinger: Add support for extension lib
cd ../..
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
bash generate.sh lineage
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches
echo ""

echo "Applying universal patches"
cd frameworks/base
git am $BL/patches/0001-UI-Revive-navbar-layout-tuning-via-sysui_nav_bar-tun.patch
git am $BL/patches/0001-Disable-vendor-mismatch-warning.patch
cd ../..
cd lineage-sdk
git am $BL/patches/0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
cd ..
cd packages/apps/LineageParts
git am $BL/patches/0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
cd ../../..
cd vendor/lineage
git am $BL/patches/0001-vendor_lineage-Log-privapp-permissions-whitelist-vio.patch
cd ../..
echo ""

echo "Applying GSI-specific patches"
cd bootable/recovery
git revert 0e369f42b82c4d12edba9a46dd20bee0d4b783ec --no-edit # recovery: Allow custom bootloader msg offset in block misc
cd ../..
cd build/make
git am $BL/patches/0001-build-Don-t-handle-apns-conf.patch
cd ../..
cd device/phh/treble
git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit # Update lineage.mk for LineageOS 16.0
git am $BL/patches/0001-Remove-fsck-SELinux-labels.patch
git am $BL/patches/0001-treble-Add-overlay-lineage.patch
git am $BL/patches/0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch
cd ../../..
cd frameworks/av
git revert 5a5606dbd92f01de322c797a7128fce69902d067 --no-edit # camera: Allow devices to load custom CameraParameter code
cd ../..
cd frameworks/native
git revert 581c22f979af05e48ad4843cdfa9605186d286da --no-edit # Add suspend_resume trace events to the atrace 'freq' category.
cd ../..
cd system/core
git am $BL/patches/0001-Revert-init-Add-vendor-specific-initialization-hooks.patch
cd ../..
cd system/hardware/interfaces
git revert cb732f9b635b5f6f79e447ddaf743ebb800b8535 --no-edit # system_suspend: start early
cd ../../..
cd system/sepolicy
git am $BL/patches/0001-Revert-sepolicy-Relabel-wifi.-properties-as-wifi_pro.patch
cd ../..
cd vendor/lineage
git am $BL/patches/0001-build_soong-Disable-generated_kernel_headers.patch
cd ../..
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

export WITHOUT_CHECK_API=true
export WITH_SU=true
mkdir -p ~/build-output/

buildVariant() {
    lunch ${1}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    mv $OUT/system.img ~/build-output/lineage-18.1-$BUILD_DATE-UNOFFICIAL-${1}.img
}

buildVariant treble_arm_bvS
buildVariant treble_a64_bvS
buildVariant treble_arm64_bvS
ls ~/build-output | grep 'lineage'

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
