
## Building TrebleDroid-based LineageOS GSIs ##

Set up your environment by referring to [LineageOS Wiki](https://wiki.lineageos.org/devices/TP1803/build) (mainly "Install the build packages" and "Install the repo command").

Create a new working directory for your LineageOS build and navigate to it:

    mkdir lineage-21-pre-qpr2-build-td; cd lineage-21-pre-qpr2-build-td

Initialize your LineageOS workspace:

    repo init -u https://github.com/LOS21-pre-QPR2/android.git -b lineage-21.0 --git-lfs

Clone both this and the patches repos:

    git clone https://github.com/AndyCGYan/lineage_build_unified lineage_build_unified -b lineage-21-pre-qpr2-td
    git clone https://github.com/AndyCGYan/lineage_patches_unified lineage_patches_unified -b lineage-21-pre-qpr2-td

Finally, start the build script - for example, to build for all supported archs:

    bash lineage_build_unified/build_unified.sh treble A64VN A64GN 64VN 64GN

Be sure to update the cloned repos from time to time!

---

Note: VNDKLite targets are generated from built images instead of source-built - refer to [sas-creator](https://github.com/AndyCGYan/sas-creator).

---

This script is also used to make device-specific and/or personal builds. To do so, understand the script, and try the `device` and `personal` keywords.
