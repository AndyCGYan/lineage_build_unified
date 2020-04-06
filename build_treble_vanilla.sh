#!/bin/bash

jobs=$(nproc --all)
rom_fp="$(date +%Y%m%d)"
tbl=$PWD/treble_build_los

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $tbl/roomservice.xml .repo/local_manifests/manifest.xml
sed -i -E '/external\/exfat/d' .repo/local_manifests/manifest.xml

repo sync -c --force-sync --no-clone-bundle --no-tags -j$jobs

cd frameworks/base
git revert e0a5469cf5a2345fae7e81d16d717d285acd3a6e --no-edit #FODCircleView: defer removal to next re-layout
git revert 817541a8353014e40fa07a1ee27d9d2f35ea2c16 --no-edit #Initial support for in-display fingerprint sensors
cd ../..

rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
bash generate.sh lineage
cd ../../..

echo "Applying treble patches"
bash ~/treble_experimentations/apply-patches.sh treble_patches

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Applying universal patches"
cd frameworks/base
git am $tbl/0001-Disable-vendor-mismatch-warning.patch
git am $tbl/0001-Keyguard-Show-shortcuts-by-default.patch
git am $tbl/0001-core-Add-support-for-MicroG.patch
cd ../..
cd lineage-sdk
git am $tbl/0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
cd ..
cd packages/apps/LineageParts
git am $tbl/0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
cd ../../..
cd vendor/lineage
git am $tbl/0001-vendor_lineage-Log-privapp-permissions-whitelist-vio.patch
cd ../..
echo ""

echo "Applying GSI-specific patches"
cd build/make
git am $tbl/0001-Revert-Enable-dyanmic-image-size-for-GSI.patch
cd ../..
cd device/phh/treble
git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit #Update lineage.mk for LineageOS 16.0
git am $tbl/0001-Remove-fsck-SELinux-labels.patch
git am $tbl/0001-treble-Add-overlay-lineage.patch
git am $tbl/0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch
git am $tbl/0001-Increase-system-partition-size-for-arm_ab.patch
cd ../../..
cd external/tinycompress
git revert fbe2bd5c3d670234c3c92f875986acc148e6d792 --no-edit #tinycompress: Use generated kernel headers
cd ../..
cd vendor/lineage
git am $tbl/0001-build_soong-Disable-generated_kernel_headers.patch
cd ../..
cd vendor/qcom/opensource/cryptfs_hw
git revert 6a3fc11bcc95d1abebb60e5d714adf75ece83102 --no-edit #cryptfs_hw: Use generated kernel headers
git am $tbl/0001-Header-hack-to-compile-for-8974.patch
cd ../../../..
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

export WITHOUT_CHECK_API=true
export ALLOW_MISSING_DEPENDENCIES=true
export WITH_SU=true
export BUILD_NUMBER=$rom_fp
mkdir -p release/$rom_fp/

buildVariant() {
	lunch treble_${1}-userdebug
	make installclean
	make -j$jobs systemimage
	make vndk-test-sepolicy
	mv $OUT/system.img release/$rom_fp/lineage-16.0-$rom_fp-UNOFFICIAL-treble_${1}.img
}

buildVariant arm_avN
buildVariant arm_bvN
buildVariant a64_avN
buildVariant a64_bvN
buildVariant arm64_avN
buildVariant arm64_bvN

cat $OUT/system/build.prop | grep security_patch
echo ""
