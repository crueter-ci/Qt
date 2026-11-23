#!/bin/sh -e

_version=8.2-f16c3cc5aa
_repo=FFmpeg-Qt
_name=ffmpeg

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
	_end
fi

export FFMPEG_DIR="$_fulldir"
