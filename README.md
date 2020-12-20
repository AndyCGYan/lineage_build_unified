
## Building PHH-based LineageOS GSIs ##

To get started with building LineageOS GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html) as well as [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

First, open a new Terminal window, which defaults to your home directory.  Clone the modified treble_experimentations repo there:

    git clone https://github.com/AndyCGYan/treble_experimentations

Create a new working directory for your LineageOS build and navigate to it:

    mkdir lineage-18.x-build-gsi; cd lineage-18.x-build-gsi

Initialize your LineageOS workspace:

    repo init -u https://github.com/LineageOS/android.git -b lineage-18.1

Clone the modified treble patches and this repo:

    git clone https://github.com/AndyCGYan/treble_patches -b lineage-18.1
    git clone https://github.com/AndyCGYan/treble_build_los -b lineage-18.1

Finally, start the build script:

    bash treble_build_los/buildbot_treble.sh

Be sure to update the cloned repos from time to time!

---

Note: A-only and VNDKLite targets are now generated from AB images - refer to [sas-creator](https://github.com/phhusson/sas-creator).
