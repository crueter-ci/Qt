#!/bin/bash -e

## Build variables ##

# shellcheck disable=SC1091
. ./tools/vars.sh

_group() {
	if [ -n "$GITHUB_RUN_ID" ]; then
		echo "##[group]$*"
	else
		echo "======= $* ======="
	fi
}

_end() {
	if [ -n "$GITHUB_RUN_ID" ]; then
		echo "##[endgroup]"
	fi
}

# default platform + architecture (auto-detected unless already supplied)
case "$(uname -s)" in
	Linux)
		: "${PLATFORM:=linux}"
		case "$(uname -m)" in
			x86_64)    : "${ARCH:=amd64}" ;;
			aarch64|arm64) : "${ARCH:=aarch64}" ;;
		esac
		;;
	Darwin)
		: "${PLATFORM:=macos}"
		case "$(uname -m)" in
			x86_64) : "${ARCH:=amd64}" ;;
			arm64)  : "${ARCH:=aarch64}" ;;
		esac
		;;
	CYGWIN* | MINGW* | MSYS*)
		# MSYS2 sets MYSTEM; regular setups are windows/msvc (windows is case-insensitive)
		if [ -n "$MYSTEM" ]; then
			: "${PLATFORM:=mingw}"
		else
			: "${PLATFORM:=windows}"
		fi
		case "$(uname)" in
			*ARM64) : "${ARCH:=aarch64}" ;;
			*)      : "${ARCH:=amd64}" ;;
		esac
		;;
	*) : "${PLATFORM:?-- You must supply the PLATFORM environment variable.}" ;;
esac

ROOTDIR="$PWD"
: "${OUT_DIR:=$PWD/out}"
: "${BUILD_DIR:=$PWD/build}"
: "${MACOSX_DEPLOYMENT_TARGET:=13.0}"

mkdir -p "$ROOTDIR"/artifacts "$BUILD_DIR"

## Command Checks ##

must_install() {
	for cmd in "$@"; do
		command -v "$cmd" >/dev/null 2>&1 || { echo "-- $cmd must be installed" && exit 1; }
	done
}

case "$ARTIFACT" in
	*.zip) must_install unzip ;;
	*.tar.*) ;;
	*.7z) must_install 7z ;;
	*)
		echo "-- Unsupported extension ${ARTIFACT##.*}"
		exit 1
		;;
esac

## Utility Functions ##

# generate sha1, 256, and 512 sums for a file
sums() {
	for file in "$@"; do
		for algo in 1 256 512; do
			if ! command -v sha${algo}sum >/dev/null 2>&1; then
				sha${algo} "$file" | awk '{print $4}' | tr -d "\n" >"$file".sha${algo}sum
			else
				sha${algo}sum "$file" | cut -d " " -f1 | tr -d "\n" >"$file".sha${algo}sum
			fi
		done
	done
}

## Packaging ##
strip_libs() {
	if macos; then
		find "$OUT_DIR" -type f -name '*.dylib*' -exec strip -u -r {} \;
	elif linux; then
		find "$OUT_DIR" -type f -name '*.so*' -exec strip {} \;
	elif mingw; then
		find "$OUT_DIR" -type f -name '*.dll' -exec strip {} \;
	fi
}

# package
package() {
	_group "Packaging"
	mkdir -p "$ROOTDIR/artifacts"

	TARBALL=$FILENAME-$PLATFORM-$ARCH-$VERSION_FULL.tar

	cd "$OUT_DIR"
	strip_libs
	tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

	cd "$ROOTDIR/artifacts"
	zstd -10 "$TARBALL"
	rm "$TARBALL"

	sums "$TARBALL.zst"
	_end
}

## Platform Stuff ##
TAR="tar"
SHARED=false

case "$PLATFORM" in
	*linux)
		SHARED=true
		;;
esac

export TAR
export SHARED

## Platform Utility Functions ##

linux() {
	[ "$PLATFORM" = linux ]
}

macos() {
	[ "$PLATFORM" = macos ]
}

msvc() {
	[ "$PLATFORM" = windows ]
}

mingw() {
	[ "$PLATFORM" = mingw ]
}

windows() {
	msvc || mingw
}

arm() {
	[ "$ARCH" = aarch64 ]
}

amd() {
	[ "$ARCH" = amd64 ]
}
