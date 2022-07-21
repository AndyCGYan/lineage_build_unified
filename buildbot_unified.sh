#!/bin/bash
echo ""
echo "LineageOS 19.x Unified Buildbot"
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

NOSYNC=false
PERSONAL=false
for var in "${@:2}"
do
    if [ ${var} == "nosync" ]
    then
        NOSYNC=true
    fi
    if [ ${var} == "personal" ]
    then
        PERSONAL=true
    fi
done

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

prep_build() {
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

    repopick -Q "(status:open+AND+NOT+is:wip)+(label:Code-Review>=0+AND+label:Verified>=0)+project:LineageOS/android_packages_apps_Trebuchet+branch:lineage-19.1+NOT+332083"
    repopick -t twelve-burnin
    repopick 321337 # Deprioritize important developer notifications
    repopick 321338 # Allow disabling important developer notifications
    repopick 321339 # Allow disabling USB notifications
    repopick 329229 -f # Alter model name to avoid SafetyNet HW attestation enforcement
    repopick 329230 -f # keystore: Block key attestation for SafetyNet
    repopick 329409 # SystemUI: screenshot: open the screenshot instead of edit
    repopick 331534 -f # SystemUI: Add support to add/remove QS tiles with one tap
    repopick 331791 # Skip checking SystemUI's permission for observing sensor privacy
}

apply_patches() {
    echo "Applying patch group ${1}"
    bash ./lineage_build_unified/apply_patches.sh ./lineage_patches_unified/${1}
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
    if [ ${1} == "arm64" ]
    then
        lunch lineage_arm64-userdebug
        make -j$(nproc --all) systemimage
        mv $OUT/system.img ~/build-output/lineage-19.1-$BUILD_DATE-UNOFFICIAL-arm64$(${PERSONAL} && echo "-personal" || echo "").img
    else
        brunch ${1}
        mv $OUT/lineage-*.zip ~/build-output/lineage-19.1-$BUILD_DATE-UNOFFICIAL-${1}$($PERSONAL && echo "-personal" || echo "").zip
    fi
}

build_treble() {
    case "${1}" in
        ("A64B") TARGET=a64_bvS;;
        ("A64BG") TARGET=a64_bgS;;
        ("64B") TARGET=arm64_bvS;;
        ("64BG") TARGET=arm64_bgS;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
    lunch lineage_${TARGET}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img ~/build-output/lineage-19.1-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "").img
    make vndk-test-sepolicy
}

if ${NOSYNC}
then
    echo "ATTENTION: syncing/patching skipped!"
    echo ""
    echo "Setting up build environment"
    source build/envsetup.sh &> /dev/null
    echo ""
else
    prep_build
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
fi


for var in "${@:2}"
do
    if [ ${var} == "nosync" ] || [ ${var} == "personal" ]
    then
        continue
    fi
    echo "Starting $(${PERSONAL} && echo "personal " || echo "")build for ${MODE} ${var}"
    build_${MODE} ${var}
done
ls ~/build-output | grep 'lineage' || true
if [ ${MODE} == "treble" ]
then
    echo $START > ~/build-output/ota-timestamp.txt
fi

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
