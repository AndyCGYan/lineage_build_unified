#!/bin/bash
echo ""
echo "LineageOS 19.x Unified Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

if [ $# -lt 2 ]
then
    echo "Not enough arguments - exiting"
    echo ""
    exit 1
fi

MODE=${1}
if [ ${MODE} != "device" ] && [ ${MODE} != "treble" ]
then
    echo "Invalid mode - exiting"
    echo ""
    exit 1
fi

PERSONAL=false
if [ ${!#} == "personal" ]
then
    PERSONAL=true
fi

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
WITHOUT_CHECK_API=true
WITH_SU=true

echo "Preparing local manifests"
mkdir -p .repo/local_manifests
cp ./lineage_build_unified/local_manifests_${MODE}/*.xml .repo/local_manifests
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
mkdir -p ~/build-output
echo ""

repopick -t android-12.0.0_r12
repopick -t twelve-monet
repopick -Q "status:open+project:LineageOS/android_packages_apps_AudioFX+branch:lineage-19.0"
repopick -Q "status:open+project:LineageOS/android_packages_apps_Etar+branch:lineage-19.0"
repopick 317119 # Unset BOARD_EXT4_SHARE_DUP_BLOCKS
repopick 317574 -f # ThemePicker: Grant missing wallpaper permissions
repopick 317602 # Keyguard: don't use large clock on landscape
repopick 317606 # LineageParts: Temporary hax
repopick 317608 # Support for device specific key handlers
repopick 317609 # Allow adjusting progress on touch events.
repopick 318037 # Statusbar: show vibration icon in collapsed statusbar
repopick 318379 # Partially revert "lineage-sdk: Comment out LineageAudioService"
repopick 318380 # lineage: Temporarily disable LineageAudioService overlay

apply_patches() {
    echo "Applying patch group ${1}"
    bash ~/treble_experimentations/apply-patches.sh ./lineage_patches_unified/${1}
}

prep_device() {
    :
}

prep_treble() {
    apply_patches patches_treble_prerequisite
    apply_patches patches_treble_phh
}

finalize_device() {
    :
}

finalize_treble() {
    rm -f device/*/sepolicy/common/private/genfs_contexts
    cd device/phh/treble
    git clean -fdx
    bash generate.sh lineage
    cd ../../..
}

build_device() {
    brunch ${1}
    mv $OUT/lineage-*.zip ~/build-output/lineage-19.0-$BUILD_DATE-UNOFFICIAL-${1}$($PERSONAL && echo "-personal" || echo "").zip
}

build_treble() {
    case "${1}" in
        #("32B") TARGET=treble_arm_bvS;;
        ("A64B") TARGET=treble_a64_bvS;;
        ("64B") TARGET=treble_arm64_bvS;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
    lunch lineage_${TARGET}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img ~/build-output/lineage-19.0-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "").img
    make vndk-test-sepolicy
}

echo "Applying patches"
prep_${MODE}
apply_patches patches_platform
apply_patches patches_${MODE}
if ${PERSONAL}
then
    apply_patches patches_platform_personal
    apply_patches patches_${MODE}_personal
fi
finalize_${MODE}
echo ""

for var in "${@:2}"
do
    if [ ${var} == "personal" ]
    then
        continue
    fi
    echo "Starting $(${PERSONAL} && echo "personal " || echo "")build for ${MODE} ${var}"
    build_${MODE} ${var}
done
ls ~/build-output | grep 'lineage' || true

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
