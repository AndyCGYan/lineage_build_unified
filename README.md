
## Building PHH-based LineageOS GSIs ##

To get started with building LineageOS GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html), and set up your environment by referring to [LineageOS Wiki](https://wiki.lineageos.org/devices/redfin/build) (mainly "Install the build packages") and [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

First, open a new Terminal window, which defaults to your home directory. Create a new working directory for your LineageOS build and navigate to it:

    mkdir lineage-19.x-build-gsi; cd lineage-19.x-build-gsi

Initialize your LineageOS workspace:

    repo init -u https://github.com/LineageOS/android.git -b lineage-19.1 --git-lfs

Clone both this and the patches repos:

    git clone https://github.com/AndyCGYan/lineage_build_unified lineage_build_unified -b lineage-19.1
    git clone https://github.com/AndyCGYan/lineage_patches_unified lineage_patches_unified -b lineage-19.1

Finally, start the build script - for example, to build for all supported archs:

    bash lineage_build_unified/buildbot_unified.sh treble A64VN A64VS A64GN 64VN 64VS 64GN

Be sure to update the cloned repos from time to time!

---

Note: VNDKLite and Secure targets are generated from built images instead of source-built - refer to [sas-creator](https://github.com/AndyCGYan/sas-creator).

---

This script is also used to make device-specific and/or personal builds. To do so, understand the script, and try the `device` and `personal` keywords.
