#!/bin/bash

repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)

cd frameworks/base
git revert 9213b9f5aa79d25a9633df99a7922c4c7f72dfda --no-edit #FODCircleView: rewrite and simplify implementation
git revert 71e6d97d3fe05ebd2fe3dc7f5eee846b13b88131 --no-edit #FODCircleView: place above other UI elements
git revert 6077075200cce9f66a688012786b054d0843ed6c --no-edit #fw/b: Fix systemui tests with in-display fingerprint
git revert 737170f406d850c79efc961e9d4026dd10db4f88 --no-edit #FODCircleView: defer removal to next re-layout
git revert 471cf7dc1478fce893e77ac1fb97dfbeeb5af2e7 --no-edit #Initial support for in-display fingerprint sensors
cd ../..

rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
bash generate.sh lineage
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Picking temporary stuff"
repopick -t ten-vold
echo ""

#read -p "Press any key to start building, or CTRL-C to exit" nothing

echo "Applying universal patches"
cd frameworks/base
git am ../../0001-UI-Revive-navbar-layout-tuning-via-sysui_nav_bar-tun.patch
git am ../../0001-Disable-vendor-mismatch-warning.patch
git am ../../0001-core-Add-support-for-MicroG.patch
cd ../..
cd lineage-sdk
git am ../0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
cd ..
cd packages/apps/LineageParts
git am ../../../0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
cd ../../..
cd vendor/lineage
git am ../../0001-vendor_lineage-Log-privapp-permissions-whitelist-vio.patch
cd ../..
echo ""

echo "Applying GSI-specific patches"
cd build/make
git am ../../0001-build-Don-t-handle-apns-conf.patch
cd ../..
cd device/phh/treble
git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit #Update lineage.mk for LineageOS 16.0
git am ../../../0001-Remove-fsck-SELinux-labels.patch
git am ../../../0001-treble-Add-overlay-lineage.patch
git am ../../../0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch
git am ../../../0001-Increase-system-partition-size-for-arm_ab.patch
git am ../../../0001-TEMP-treble-Fix-init.treble-environ.rc-hardcode-for-.patch
cd ../../..
cd external/tinycompress
git revert 41d822fd7edfe1e629cdebe5645dab41ea4efb59 --no-edit #tinycompress: Use generated kernel headers
cd ../..
cd hardware/lineage/interfaces
git am ../../../0001-cryptfshw-Remove-dependency-on-generated-kernel-head.patch
cd ../../..
cd vendor/lineage
git am ../../0001-build_soong-Disable-generated_kernel_headers.patch
cd ../..
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

lunch treble_arm64_avN-userdebug
make WITHOUT_CHECK_API=true installclean
make WITHOUT_CHECK_API=true systemimage
make WITHOUT_CHECK_API=true vndk-test-sepolicy
BUILD_DATE=`date +%Y%m%d`
mv $OUT/system.img ~/build-output/lineage-17.0-$BUILD_DATE-UNOFFICIAL-treble_arm64_avN.img
cat $OUT/system/build.prop | grep security_patch
echo ""
