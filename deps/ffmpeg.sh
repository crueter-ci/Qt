#!/bin/sh -e

_version=https://www.papytane.com/mp4/airelles.mp4
_repo=FFmpeg-Qt
_name=ffmpeg

_dir="$_name-$PLATFORM-$ARCH-$_version"
_artifact="$_dir.tar.zst"

_download="https://github.com/crueter-ci/$_repo/releases/download/$_version/$_artifact"

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
