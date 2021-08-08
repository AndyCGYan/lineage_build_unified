#!/bin/bash
echo ""
echo "LineageOS 17.x Treble Buildbot - PERSONAL"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

# Abort early on error
set -eE
trap '(\
echo;\
echo \!\!\! An error happened during script execution;\
echo \!\!\! Please check console output for bad sync,;\
echo \!\!\! failed patch application, etc.;\
echo\
)' ERR

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
BL=$PWD/treble_build_los

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/manifest.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Reverting LOS FOD implementation"
cd frameworks/base
git am $BL/patches/0001-Squashed-revert-of-LOS-FOD-implementation.patch
cd ../..
cd frameworks/native
git am $BL/patches/0001-Revert-surfaceflinger-Add-support-for-extension-lib.patch
cd ../..
cd vendor/lineage
git revert 612c5a846ea5aed339fe1275c119ee111faae78c --no-edit # soong: Add flag for fod extension
cd ../..
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
bash generate.sh lineage
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches/patches
echo ""

echo "Applying universal patches"
cd frameworks/base
git am $BL/patches/0001-UI-Revive-navbar-layout-tuning-via-sysui_nav_bar-tun.patch
git am $BL/patches/0001-Disable-vendor-mismatch-warning.patch
git am $BL/patches/0001-Allow-selective-signature-spoofing-for-microG.patch
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
cd build/make
git am $BL/patches/0001-build-Don-t-handle-apns-conf.patch
cd ../..
cd device/phh/treble
git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit # Update lineage.mk for LineageOS 16.0
git am $BL/patches/0001-Remove-fsck-SELinux-labels.patch
git am $BL/patches/0001-treble-Add-overlay-lineage.patch
git am $BL/patches/0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch
git am $BL/patches/0001-treble-Don-t-handle-apns-conf.patch
git am $BL/patches/0001-TEMP-treble-Fix-init.treble-environ.rc-hardcode-for-.patch
cd ../../..
cd frameworks/native
git revert 581c22f979af05e48ad4843cdfa9605186d286da --no-edit # Add suspend_resume trace events to the atrace 'freq' category.
cd ../..
cd hardware/lineage/interfaces
git am $BL/patches/0001-cryptfshw-Remove-dependency-on-generated-kernel-head.patch
cd ../../..
cd system/hardware/interfaces
git revert 5c145c49cc83bfe37c740bcfd3f82715ee051122 --no-edit # system_suspend: start early
cd ../../..
cd system/sepolicy
git revert d12551bf1a6e8a9ece6bbb98344a27bde7f9b3e1 --no-edit # sepolicy: Relabel wifi. properties as wifi_prop
git am $BL/patches/0001-Revert-sepolicy-Address-denials-for-legacy-last_kmsg.patch
cd ../..
cd vendor/lineage
git am $BL/patches/0001-build_soong-Disable-generated_kernel_headers.patch
cd ../..
echo ""

echo "Applying personal patches"
cd build/make
git am $BL/patches_personal/0001-build-Integrate-prop-modifications-1-2.patch
cd ../..
cd frameworks/base
git am $BL/patches_personal/0001-UI-Disable-left-seascape-navigation-bar-optionally.patch
git am $BL/patches_personal/0001-UI-Use-SNAP_FIXED_RATIO-for-multi-window-globally.patch
git am $BL/patches_personal/0001-UI-Increase-default-status-bar-height.patch
git am $BL/patches_personal/0001-UI-Always-render-windows-into-cutouts.patch
git am $BL/patches_personal/0001-UI-Relax-requirement-for-HINT_SUPPORTS_DARK_TEXT.patch
git am $BL/patches_personal/0001-UI-Force-dark-QS-scrim.patch
git am $BL/patches_personal/0001-TEMP-UI-Restore-status-bar-inset-behaviour.patch
git am $BL/patches_personal/0001-Keyguard-Show-shortcuts-by-default.patch
git am $BL/patches_personal/0001-Keyguard-Revert-date-and-clock-to-Lollipop-style.patch
git am $BL/patches_personal/0001-Keyguard-Fix-clock-position.patch
git am $BL/patches_personal/0001-Keyguard-Hide-padlock.patch
git am $BL/patches_personal/0001-Keyguard-Refine-indication-text.patch
git am $BL/patches_personal/0001-Disable-FP-lockouts.patch
git am $BL/patches_personal/0001-Add-MiuiNavbarOverlay.patch
cd ../..
cd frameworks/opt/net/wifi
git am $BL/patches_personal/0001-WiFi-Relax-throttling-greatly-for-foreground-apps.patch
cd ../../../..
cd frameworks/opt/telephony
git am $BL/patches_personal/0001-Telephony-Disable-SPN-retrieval.patch
cd ../../..
cd lineage-sdk
git am $BL/patches_personal/0001-sdk-Do-not-warn-about-SELinux-and-build-signature-st.patch
cd ..
cd packages/apps/DeskClock
git am $BL/patches_personal/0001-DeskClock-Adjust-colors-and-layout.patch
git am $BL/patches_personal/0001-DeskClock-Revert-date-and-clock-to-Lollipop-style.patch
cd ../../..
cd packages/apps/Messaging
git am $BL/patches_personal/0001-Messaging-Use-blue-accent.patch
cd ../../..
cd vendor/lineage
git am $BL/patches_personal/0001-vendor_lineage-Ignore-neverallows.-again.patch
git am $BL/patches_personal/0001-build-Integrate-prop-modifications-2-2.patch
cd ../..
git clone https://github.com/kumikooumae/android_vendor_extra vendor/extra # SystemUIWithLegacyRecents
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
	mv $OUT/system.img ~/build-output/lineage-17.1-$BUILD_DATE-UNOFFICIAL-${1}-personal.img
}

buildVariant treble_arm64_bvS
ls ~/build-output | grep 'lineage'
rm -rf vendor/extra

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
