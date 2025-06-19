#!/usr/bin/env bash

source build/envsetup.sh
source vendor/lineage/vars/aosp_target_release
lunch lineage_gsi_arm64-$aosp_target_release-userdebug
make clobber
