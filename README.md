## Building "generic" LineageOS-light GSIs ##

[![Download MoxiuGSIs](https://img.shields.io/sourceforge/dm/moxiugsis.svg)](https://sourceforge.net/projects/moxiugsis/files/latest/download)

Set up your environment by referring to [LineageOS Wiki](https://wiki.lineageos.org/devices/TP1803/build) (mainly "Install the build packages" and "Install the repo command").

Create a new working directory for your LineageOS build and navigate to it:

    mkdir lineage-21-build-gsi; cd lineage-21-build-gsi

Initialize your LineageOS workspace:

    repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --git-lfs

Clone both this and the patches repos:

    git clone https://github.com/moxi-u7/LineageOS_gsi lineage_build_gsi -b lineage-21-light
    git clone https://github.com/moxi-u7/lineage_patches_unified lineage_patches_unified -b lineage-21-light

Finally, start the build script - for example, to build for all supported archs:

    bash lineage_build_unified/buildbot_unified.sh treble 64VN 64VS 64GN

Be sure to update the cloned repos from time to time!

---

This script is also used to make device-specific and/or personal builds. To do so, understand the script, and try the `device` and `personal` keywords.

### Issues
[Open Issue](https://github.com/moxi-u7/LineageOS_gsi/issues/new)

### Thanks to:

- The LineageOS team - helping me out  even when they don't offer GSIs themselves

- [phhusson](https://github.com/phhusson) - shaped the treble  community, and even the "Light" approach  uses his fixes/infra extensively

- [PeterCxy](https://github.com/PeterCxy) - inspired me with his  personal-use GSI, and coded critical fixes such as sysbta

- [andycgyan](https://github.com/andycgyan) inspired me to start making GSIs.
 - ...and more
