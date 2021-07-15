#!/bin/bash
echo ""
echo "LineageOS 18.x Treble Buildbot - PERSONAL"
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
cd build/make
git am $BL/patches/0001-Make-broken-copy-headers-the-default.patch
cd ../..
cd frameworks/base
git am $BL/patches/0001-UI-Revive-navbar-layout-tuning-via-sysui_nav_bar-tun.patch
git am $BL/patches/0001-UI-Disable-wallpaper-zoom.patch
git am $BL/patches/0001-Disable-vendor-mismatch-warning.patch
cd ../..
cd lineage-sdk
git am $BL/patches/0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
cd ..
cd packages/apps/Jelly
git am $BL/patches/0001-Jelly-MainActivity-Restore-applyThemeColor.patch
cd ../../..
cd packages/apps/LineageParts
git am $BL/patches/0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
cd ../../..
cd packages/apps/Trebuchet
git am $BL/patches/0001-Trebuchet-Move-clear-all-button-to-actions-view.patch
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
git revert 78c28df40f72fdcbe3f82a83828060ad19765fa1 --no-edit # mainline_system: Exclude vendor.lineage.power@1.0 from artifact path requirements
cd ../..
cd device/phh/treble
git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit # Update lineage.mk for LineageOS 16.0
git am $BL/patches/0001-Remove-fsck-SELinux-labels.patch
git am $BL/patches/0001-treble-Add-overlay-lineage.patch
git am $BL/patches/0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch
git am $BL/patches/0001-treble-Don-t-handle-apns-conf.patch
git am $BL/patches/0001-add-offline-charger-sepolicy.patch
cd ../../..
cd frameworks/av
git revert 5a5606dbd92f01de322c797a7128fce69902d067 --no-edit # camera: Allow devices to load custom CameraParameter code
cd ../..
cd frameworks/native
git revert 581c22f979af05e48ad4843cdfa9605186d286da --no-edit # Add suspend_resume trace events to the atrace 'freq' category.
cd ../..
cd packages/apps/Bluetooth
git revert 4ceb47e32c1be30640e40f81b6f741942f8598ed --no-edit # Bluetooth: Reset packages/apps/Bluetooth to upstream
cd ../../..
cd system/core
git am $BL/patches/0001-Revert-init-Add-vendor-specific-initialization-hooks.patch
git am $BL/patches/0001-Panic-into-recovery-rather-than-bootloader.patch
git am $BL/patches/0001-Restore-sbin-for-Magisk-compatibility.patch
git am $BL/patches/0001-fix-offline-charger-v7.patch
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

echo "Applying personal patches"
cd build/make
git am $BL/patches_personal/0001-build-Integrate-prop-modifications-1-2.patch
cd ../..
cd device/phh/treble
git revert 30071d042053b67e4ec6d7332ae187d6cd4542db --no-edit # Use ext4 share duplicate blocks
git am $BL/patches_personal/0001-Add-Meizu-18-vibrator-support.patch
git am $BL/patches_personal/0001-HACK-Only-use-meizu-vibrator-on-Meizu-18.patch
cd ../../..
cd frameworks/base
git am $BL/patches_personal/0001-UI-Disable-left-seascape-navigation-bar-optionally.patch
git am $BL/patches_personal/0001-UI-Use-SNAP_FIXED_RATIO-for-multi-window-globally.patch
git am $BL/patches_personal/0001-UI-Increase-default-status-bar-height.patch
git am $BL/patches_personal/0001-UI-Always-render-windows-into-cutouts.patch
git am $BL/patches_personal/0001-UI-Remove-black-background-from-power-menu.patch
git am $BL/patches_personal/0001-UI-Reconfigure-power-menu-items.patch
git am $BL/patches_personal/0001-UI-Tap-outside-to-dismiss-power-menu.patch
git am $BL/patches_personal/0001-UI-Relax-requirement-for-HINT_SUPPORTS_DARK_TEXT.patch
git am $BL/patches_personal/0001-UI-Force-dark-QS-scrim.patch
git am $BL/patches_personal/0001-Keyguard-Show-shortcuts-by-default.patch
git am $BL/patches_personal/0001-Keyguard-Revert-date-and-clock-to-Lollipop-style.patch
git am $BL/patches_personal/0001-Keyguard-Fix-clock-position.patch
git am $BL/patches_personal/0001-Keyguard-Hide-padlock.patch
git am $BL/patches_personal/0001-Keyguard-Refine-indication-text.patch
git am $BL/patches_personal/0001-Keyguard-UI-Fix-status-bar-margins-and-paddings.patch
git am $BL/patches_personal/0001-Disable-FP-lockouts.patch
git am $BL/patches_personal/0001-Add-MiuiNavbarOverlay.patch
git revert c3182c54802105c614848b26250c2682eb9900bf --no-edit # Reduce padding in QS for small screens
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
    mv $OUT/system.img ~/build-output/lineage-18.1-$BUILD_DATE-UNOFFICIAL-${1}-personal.img
}

buildVariant treble_arm64_bvS
ls ~/build-output | grep 'lineage'

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
