#!/bin/bash
echo ""
echo "LineageOS 20 Unified Buildbot"
echo ""

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

NOSYNC=true
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
mkdir -p release/$BUILD_DATE/

prep_build() {
    echo "Preparing local manifests"
    mkdir -p .repo/local_manifests
    cp ./lineage_build_unified/local_manifests_${MODE}/*.xml .repo/local_manifests
    echo ""

    echo "Syncing repos"
    repo sync -c --force-sync --no-clone-bundle --no-tags -j8
    repo forall -r '.*opengapps.*' -c 'git lfs fetch && git lfs checkout'
    echo ""

    echo "Setting up build environment"
    source build/envsetup.sh &> /dev/null
    echo ""

    repopick 321337 -f # Deprioritize important developer notifications
    repopick 321338 -f # Allow disabling important developer notifications
    repopick 321339 -f # Allow disabling USB notifications
    repopick 340916 # SystemUI: add burnIn protection
    repopick 342860 # codec2: Use numClientBuffers to control the pipeline
    repopick 342861 # CCodec: Control the inputs to avoid pipeline overflow
    repopick 342862 # [WA] Codec2: queue a empty work to HAL to wake up allocation thread
    repopick 342863 # CCodec: Use pipelineRoom only for HW decoder
    repopick 342864 # codec2: Change a Info print into Verbose
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
    apply_patches patches_treble_td
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
    mv $OUT/lineage-*.zip release/$BUILD_DATE/lineage-20.0-$BUILD_DATE-UNOFFICIAL-${1}$($PERSONAL && echo "-personal" || echo "").zip
}

build_treble() {
    case "${1}" in
        ("A64VN") TARGET=a64_bvN;;
        ("A64VS") TARGET=a64_bvS;;
        ("A64GN") TARGET=a64_bgN;;
        ("64VN") TARGET=arm64_bvN;;
        ("64VS") TARGET=arm64_bvS;;
        ("64GN") TARGET=arm64_bgN;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
    lunch lineage_${TARGET}-userdebug
    make installclean
    make RELAX_USES_LIBRARY_CHECK=true -j8 systemimage
    xz -c $OUT/system.img -T0 > release/$BUILD_DATE/lineage-20.0-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "").img.xz
    #make vndk-test-sepolicy
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

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""

( cd sas-creator; bash securize.sh $OUT/system.img; xz -c s-secure.img -T0 > ../release/$BUILD_DATE/lineage-20.0-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "")-secure.img.xz )
( cd sas-creator; bash lite-adapter.sh 64 $OUT/system.img; xz -c s.img -T0 > ../release/$BUILD_DATE/lineage-20.0-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "")-vndklite.img.xz )
( cd sas-creator; bash securize.sh s.img; xz -c s-secure.img -T0 > ../release/$BUILD_DATE/lineage-20.0-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "")-vndklite-secure.img.xz )

