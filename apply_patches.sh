#!/bin/bash

set -e

patches="$(readlink -f -- $1)"

shopt -s nullglob
for project in $(cd $patches; echo *);do
	p="$(tr _ / <<<$project |sed -e 's;platform/;;g')"
	[ "$p" == build ] && p=build/make
	[ "$p" == vendor/hardware/overlay ] && p=vendor/hardware_overlay
	[ "$p" == vendor/partner/gms ] && p=vendor/partner_gms
	pushd $p
	git clean -fdx; git reset --hard
	for patch in $patches/$project/*.patch;do
		if git apply --check $patch;then
			git am $patch
		elif patch -f -p1 --dry-run < $patch > /dev/null;then
			#This will fail
			git am $patch || true
			patch -f -p1 < $patch
			git add -u
			git am --continue
		else
			echo "Failed applying $patch"
			exit 1
		fi
	done
	popd
done

