#!/bin/sh -e

set -e

# shellcheck disable=SC1091

. tools/common.sh

ROOTDIR="$PWD"

copy_build_artifacts() {
	_group "Copying artifacts"

	cd "$DIRECTORY"
	cmake --install . --prefix "$OUT_DIR"
	rm -rf "$OUT_DIR"/doc

	# TODO(crueter): See if some unnecessary executables can be cleaned out. They take up >half of the
	# space on MinGW and Windows.

	# TODO(crueter): Some of the stuff like qtdiag, qmljsrootgen, qml.exe seem unnecessary.
	# Run some tests to confirm.

	if ! linux; then
		rm -f "$OUT_DIR"/bin/*dbus*
	fi

	cd ..

	_end
}

copy_build_artifacts
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in out"
