#!/bin/sh -e

## Common variables ##

export VERSION="6.11.3"

VERSION_SHORT=$(echo "$VERSION" | cut -d'.' -f1-2)
export VERSION_SHORT

export PRETTY_NAME="Qt"
export FILENAME="qt"
export DIRECTORY="qt-$VERSION"
export ARTIFACT="$DIRECTORY.tar.zst"

# Download URLs and such
_base="https://github.com/crueter-ci/Qt/releases/download/src"
export DOWNLOAD_URL="$_base/$ARTIFACT"

# build timestamp: generated once and persisted so every job in the run shares it
if [ -f TIMESTAMP ]; then
	TIMESTAMP="$(cat TIMESTAMP)"
else
	TIMESTAMP=$(date +"%s")
	echo "$TIMESTAMP" > TIMESTAMP
fi
export TIMESTAMP

# full version used to name artifacts and tag releases (versioned by timestamp)
export VERSION_FULL="$VERSION-$TIMESTAMP"

# Version check functions
qt_611() {
	[ "$VERSION" = 6.11.3 ]
}
