#!/bin/bash

repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
bash generate.sh lineage
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Applying universal patches"
cd frameworks/base
git am ../../0001-Disable-vendor-mismatch-warning.patch
git am ../../0001-Keyguard-Show-shortcuts-by-default.patch
git am ../../0001-core-Add-support-for-MicroG.patch
cd ../..
cd lineage-sdk
git am ../0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
cd ..
cd packages/apps/LineageParts
git am ../../../0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
cd ../../..
echo ""

echo "Applying GSI-specific patches"
cd build/make
git am ../../0001-Revert-Enable-dyanmic-image-size-for-GSI.patch
cd ../..
cd device/phh/treble
git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit #Update lineage.mk for LineageOS 16.0
git revert df25576594f684ed35610b7cc1db2b72bc1fc4d6 --no-edit #exfat fsck/mkfs selinux label
git am ../../../0001-treble-Add-overlay-lineage.patch
cd ../../..
cd external/tinycompress
git revert fbe2bd5c3d670234c3c92f875986acc148e6d792 --no-edit #tinycompress: Use generated kernel headers
cd ../..
cd vendor/lineage
git am ../../0001-build_soong-Disable-generated_kernel_headers.patch
cd ../..
cd vendor/qcom/opensource/cryptfs_hw
git revert 6a3fc11bcc95d1abebb60e5d714adf75ece83102 --no-edit #cryptfs_hw: Use generated kernel headers
git am ../../../../0001-Header-hack-to-compile-for-8974.patch
cd ../../../..
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

lunch treble_arm64_avN-userdebug
make WITHOUT_CHECK_API=true installclean
make WITHOUT_CHECK_API=true systemimage
make WITHOUT_CHECK_API=true vndk-test-sepolicy
BUILD_DATE=`date +%Y%m%d`
mv $OUT/system.img $OUT/lineage-16.0-$BUILD_DATE-UNOFFICIAL-treble_arm64_avN.img
cat $OUT/system/build.prop | grep security_patch
echo ""
