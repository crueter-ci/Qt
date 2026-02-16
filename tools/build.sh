#!/bin/bash

# shellcheck disable=SC1091

set -e

. tools/common.sh

## Buildtime/Input Variables ##

: "${ARCH:=amd64}"
: "${BUILD_DIR:=build}"
mkdir -p "$BUILD_DIR"

## Build Functions ##

CCACHE_PATH=$(which ccache || echo "ccache")
if [ "$PLATFORM" = windows ] || [ "$PLATFORM" = mingw ]; then
	CCACHE_PATH=$(cygpath -w "$CCACHE_PATH")
fi

show_stats() {
	"$CCACHE_PATH" -s
}

# Deps
if [ "$PACKAGE" != "true" ]; then
	! unix || . deps/libva.sh
	! linux || . deps/libdrm.sh
fi

! msvc || . deps/vulkan.sh

if ! windows; then
	. deps/ffmpeg.sh
	. deps/openssl.sh
fi

# cmake
configure() {
	echo "-- Configuring $PRETTY_NAME..."

	#########################################
	# C/CXX flags.                          #
	#########################################
	FLAGS="-g0 -Os"

	# Custom MSVC options, and also frame pointer stuff.
	case "$PLATFORM" in
		windows)
			# /Gy - function-sectors
			# /Gw - data-sections
			# /EHs- /EHc- - EXCEPTIONS ARE FOR LOSERS
			# /await:strict - force new coroutine abi
			FLAGS="/Gy /Gw /EHs- /EHc- /await:strict"

			# /DYNAMICBASE:NO - disable ASLR on amd64 bcz why not
			arm || FLAGS="$FLAGS /DYNAMICBASE:NO"
			set -- "$@" -DQT_BUILD_QDOC=OFF
			;;
		mingw) ;;
		*) FLAGS="$FLAGS -fomit-frame-pointer -fno-unwind-tables" ;;
	esac

	# PIC/PIE handling
	case "$PLATFORM" in
		openbsd|linux) FLAGS="$FLAGS -fPIC" ;;
		freebsd|macos|mingw) FLAGS="$FLAGS -fno-pie" ;;
		*) ;;
	esac

	#########################################
	# QPA Handling.                         #
	#########################################
	case "$PLATFORM" in
		mingw|windows) dqpa=windows ;;
		macos) dqpa=cocoa ;;
		linux) dqpa=xcb
			CONFIG+=(
				-xcb
				-qpa "xcb;wayland"
				-gtk
			)

			FEATURES+=(wayland)
			;;
		*    )
			dqpa=xcb
			CONFIG+=(-xcb -qpa xcb -gtk)
			;;
	esac

	if qt_67; then
		CONFIG+=(-qpa "$dqpa")
	else
		CONFIG+=(-default-qpa "$dqpa")
	fi

	#########################################
	# Multimedia Handling.                  #
	#########################################

	# backends
	case "$PLATFORM" in
		mingw|windows) ;;
		macos) FEATURES+=(avfoundation videotoolbox) ;;
		*) FEATURES+=(pulseaudio) ;;
	esac

	# FFmpeg + OpenSSL
	if ! windows; then
		! qt_67 || FEATURES+=(ffmpeg thread)

		CONFIG+=(-openssl-linked)
		CMAKE+=(
			-DOPENSSL_USE_STATIC_LIBS=ON
			-DFFMPEG_DIR="$FFMPEG_DIR"
			-DOPENSSL_ROOT_DIR="$OPENSSL_DIR"
			-DCMAKE_FIND_LIBRARY_SUFFIXES=".a"
			-DCMAKE_PREFIX_PATH="$OPENSSL_DIR"
			-DOpenSSL_ROOT="$OPENSSL_DIR"
		)

		export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"

		echo "-- * FFmpeg dir: $FFMPEG_DIR"
		echo "-- * OpenSSL dir: $OPENSSL_DIR"
	fi

	#########################################
	# Dependency Handling.                  #
	#########################################

	# libva
	if unix; then
		export PKG_CONFIG_PATH="$LIBVA_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
		printf -- "-- * libva pkg-config: "
		pkg-config --cflags --libs libva
		printf -- "-- * libva-drm pkg-config: "
		pkg-config --cflags --libs libva-drm

		# force libva custom dir into the thing
		FLAGS="$FLAGS $(pkg-config --cflags --libs libva-drm) "
		LDFLAGS="$LDFLAGS $(pkg-config --cflags --libs libva-drm) "
	fi

	# libdrm
	if linux; then
		export PKG_CONFIG_PATH="$LIBDRM_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
		printf -- "-- * libdrm pkg-config: "
		pkg-config --cflags --libs libdrm
	fi

	# CCache
	if [ "${CCACHE:-true}" = true ]; then
		echo "-- Using ccache at: $CCACHE_PATH"

		CMAKE+=(
			-DCMAKE_CXX_COMPILER_LAUNCHER="${CCACHE_PATH}"
			-DCMAKE_C_COMPILER_LAUNCHER="${CCACHE_PATH}"
		)
	fi

	# MSVC on ARM needs static runtime for some glorious reason.
	if msvc && [ "$ARCH" = arm64 ]; then
		CONFIG+=(-static-runtime)
	fi

	# UNIX builds are shared.
	CMAKE+=(-DBUILD_SHARED_LIBS="$SHARED")

	# also, gc-binaries can't be done on shared
	[ "$SHARED" = true ] || CONFIG+=(-gc-binaries)

	#########################################
	# Options passed directly to configure. #
	#########################################
	CONFIG+=(
		-optimize-size -no-pch -no-ltcg
		-nomake tests -nomake examples
	)

	msvc || CONFIG+=(-reduce-exports)

	#########################################
	# Disabled features.                    #
	#########################################

	DISABLED_FEATURES+=(
		icu qml-network libresolv dladdr
		sql printdialog printer printsupport
		androiddeployqt windeployqt macdeployqt
		designer assistant pixeltool testlib
		qml-preview qml-profiler
	)

	if qt_610; then
		DISABLED_FEATURES+=(localserver)
	fi

	if ! qt_67; then
		DISABLED_FEATURES+=(quickcontrols2-fluentwinui3)
	fi

	if mingw; then
		DISABLED_FEATURES+=(
			system-jpeg system-zlib system-freetype system-pcre2
		)
		CONFIG+=(-qt-libmd4c -qt-webp)
	fi

	DISABLED+=(zstd)

	# DBus disabled on everything not named linux
	if linux; then
		FEATURES+=(dbus)
	else
		DISABLED_FEATURES+=(dbus)
	fi

	for feat in "${DISABLED_FEATURES[@]}"; do
		CONFIG+=(-no-feature-"$feat")
	done

	for feat in "${DISABLED[@]}"; do
		CONFIG+=(-no-"$feat")
	done

	#########################################
	# Enabled features.                     #
	#########################################
	macos || FEATURES+=(vulkan)
	FEATURES+=(filesystemwatcher)

	for feat in "${FEATURES[@]}"; do
		CONFIG+=(-feature-"$feat")
	done

	#########################################
	# Enabled submodules.                   #
	#########################################
	SUBMODULES=qtbase,qtdeclarative,qttools,qtcharts
	if unix; then SUBMODULES+=,qtwayland; fi

	case "$VERSION" in
		6.7*) ;;
		6.9*) SUBMODULES+=,qtmultimedia ;;
		6.10*) SUBMODULES+=,qtmultimedia,qtgraphs,qtquick3d ;;
	esac

	CONFIG+=(-submodules "$SUBMODULES")

	#########################################
	# Skipped submodules.                   #
	#########################################
	SKIP=qtlanguageserver,qtquicktimeline,qtactiveqt,qtquick3dphysics,qtdoc,qt5compat
	case "$VERSION" in
		6.7*) SKIP+=,qtquick3d,qtmultimedia ;;
		6.9*) SKIP+=,qtquick3d ;;
		6.10*) ;;
	esac

	CONFIG+=(-skip "$SKIP")

	#########################################
	# Linker flags.                         #
	#########################################

	# all of these are just garbage collection basically, also identical code folding
	case "$PLATFORM" in
		windows) LDFLAGS+="/OPT:REF /OPT:ICF" ;;
		macos) LDFLAGS+="-Wl,-dead_strip -Wl,-dead_strip" ;;
		*) LDFLAGS+="-Wl,--gc-sections" ;;
	esac

	#########################################
	# CMake options.                        #
	#########################################
	CMAKE+=(
		-DCMAKE_CXX_FLAGS="$FLAGS"
		-DCMAKE_C_FLAGS="$FLAGS"
		-DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS"
	)

	if qt_69; then
		CMAKE+=(-DQT_FEATURE_cpp_winrt=OFF)
	fi

	# package target (arch linux)
	if [ "$PACKAGE" = true ]; then
		CMAKE+=(
			-DCMAKE_INSTALL_PREFIX=/usr
			-DINSTALL_BINDIR=lib/qt6/bin
			-DINSTALL_PUBLICBINDIR=usr/bin
			-DINSTALL_LIBEXECDIR=lib/qt6
			-DINSTALL_DOCDIR=share/doc/qt6
			-DINSTALL_ARCHDATADIR=lib/qt6
			-DINSTALL_DATADIR=share/qt6
			-DINSTALL_INCLUDEDIR=include/qt6
			-DINSTALL_MKSPECSDIR=lib/qt6/mkspecs
		)
	fi


	#########################################
	## NOW CONFIGURE!                      ##
	#########################################

	echo "-- Compiler flags: $FLAGS"; echo
	echo "-- Linker flags: $LDFLAGS"; echo
	echo "-- Enabled features: ${FEATURES[*]}"; echo
	echo "-- Disabled features: ${DISABLED_FEATURES[*]}"; echo
	echo "-- Disabled flags: ${DISABLED[*]}"; echo
	echo "-- Configure flags: ${CONFIG[*]}"; echo
	echo "-- CMake flags: ${CMAKE[*]}"; echo
	echo "-- Submodules: $SUBMODULES"; echo
	echo "-- Skipping: $SKIP"; echo

	./configure "${CONFIG[@]}" -- "${CMAKE[@]}"
}

build() {
    echo "-- Building $PRETTY_NAME..."
    cmake --build . --parallel || { show_stats; exit 1; }
	show_stats
}

## Packaging ##
copy_build_artifacts() {
	cd "$ROOTDIR/$BUILD_DIR/$DIRECTORY"
    echo "-- Copying artifacts..."

	cmake --install . --prefix "$OUT_DIR"

    rm -rf "$OUT_DIR"/doc

	# TODO(crueter): See if some unnecessary executables can be cleaned out. They take up >half of the
	# space on MinGW and Windows.

	# TODO(crueter): Some of the stuff like qtdiag, qmljsrootgen, qml.exe seem unnecessary.
	# Run some tests to confirm.

	if ! unix; then
		rm -f "$OUT_DIR"/bin/*dbus*
	fi
}

## Cleanup ##
rm -rf "$BUILD_DIR" # "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

## Download + Extract ##
download
cd "$ROOTDIR/$BUILD_DIR"
extract

rm -f CMakeCache.txt

## Configure ##
cd "$ROOTDIR/$BUILD_DIR/$DIRECTORY"
configure

## Build ##
build
copy_build_artifacts

## Package ##
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
