#!/bin/sh -e

_version=3.6.0-1cb0d36b39
_repo=OpenSSL-Qt
_name=openssl

if [ "$PLATFORM" = macos ]; then
	_arch=universal
elif [ "$PLATFORM" != linux ] && [ "$ARCH" = aarch64 ]; then
	_arch=arm64
else
	_arch="$ARCH"
fi

_dir="$_name-$PLATFORM-$_arch-$_version"
_artifact="$_dir.tar.zst"

_download="https://github.com/crueter-ci/$_repo/releases/download/v$_version/$_artifact"

_fulldir="$ROOTDIR/$_dir"

if [ ! -d "$_fulldir" ]; then
	_group "Downloading $_repo"
	echo "$_download"
	[ -f "$_artifact" ] || curl -L "$_download" -o "$_artifact"
	mkdir -p "$_fulldir"
	$TAR xf "$_artifact" -C "$_fulldir"
	rm -f "$_fulldir"/CMakeLists.txt
	find "$_fulldir" \( -name "*.so*" -o -name "*.dll*" -o -name "*.dylib*" \) -exec rm {} \;

	# awesome pkg-config stuff
	mkdir -p "$_fulldir"/usr
	ln -s "$_fulldir"/lib "$_fulldir"/usr/lib

	find "$_fulldir" -name "*.pc" | while read -r pc; do
		echo "-- * Patching pc file $pc"
		sed "s|^prefix=\/.*$|prefix=$_fulldir|g" "$pc" > "$pc".tmp
		mv "$pc".tmp "$pc"
	done

	_end
fi

export OPENSSL_DIR="$_fulldir"
