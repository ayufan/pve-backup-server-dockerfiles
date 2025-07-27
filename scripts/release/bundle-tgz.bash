#!/bin/bash

set -eo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <name.tgz> [files...]"
  exit 1
fi

DESTDIR=$(dirname "$1")
NAME=$(basename "$1" .tgz)
FULL_NAME=$(realpath "$DESTDIR/$NAME")
shift

echo "Creating directory: $FULL_NAME"
mkdir -p "$FULL_NAME"
for file in "$@"; do
  cp -rv "$file" "$FULL_NAME"
done

echo "Creating tarball: $FULL_NAME.tgz"
cd "$DESTDIR"
tar zcfv "$NAME.tgz" "$NAME"
rm -rf "$NAME"
echo "Tarball created successfully at $FULL_NAME.tgz"
