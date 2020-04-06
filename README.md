## Getting Started ##
---------------

To get started with building LineageOS GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html) as well as [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

First, open a new Terminal window, which defaults to your home directory.  Clone the treble experimentations repo there:

    git clone https://github.com/phhusson/treble_experimentations

Create a new working directory for your LineageOS build and navigate to it:

    mkdir lineage-16.0; cd lineage-16.0

To initialize your local repository of LineageOS, use a command like this:

    repo init -u https://github.com/LineageOS/android.git -b lineage-16.0

Then add repositories for the treble patches and LineageOS build tweaks:

    git clone https://github.com/AndyCGYan/treble_patches -b lineage-16.0
    git clone https://github.com/Magendanz/treble_build_los -b lineage-16.0

Finally, start the build script:

    bash treble_build_los/build_treble_vanilla.sh
