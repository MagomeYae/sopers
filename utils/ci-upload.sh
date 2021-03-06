#!/bin/bash

# end up when failed
set -Eeuo pipefail

# clean up when exit
trap cleanup SIGINT SIGTERM ERR EXIT
cleanup() {
	trap - SIGINT SIGTERM ERR EXIT
	unset ARCH
	unset PKGDEST
}

ARCH=$(uname -m)
PKGDEST="${PWD}/packages/$ARCH"

if [ $(find $PKGDEST -name \*.pkg\* | wc -l) -eq 0 ]; then
	echo -e "\033[0;31mCould not find any packaged packages, skip upload\033[0m"
	if [ -r .fail ]; then
		exit 2;
	fi
	exit 0
fi

curl -d "token=$UPLOAD_TOKEN&action=REQUIRE_CLEAN&arch=$ARCH" -fsSL "$REMOTE_PATH"

pushd $PKGDEST

for file in *.pkg*; do
	echo "Start upload package $file size: $(ls -lh $file | awk '{print  $5}')..."
    curl -F "file=@$file" -F "token=$UPLOAD_TOKEN" -F "arch=$ARCH" -fsSL "$REMOTE_PATH"
	#echo "Stop upload package $file"
done

popd

curl -d "token=$UPLOAD_TOKEN&action=UPLOADED&arch=$ARCH" -fsSL "$REMOTE_PATH"

if [ -r .fail ]; then
	exit 2;
fi
