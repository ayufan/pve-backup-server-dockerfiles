#!/bin/bash

set -xeo pipefail

package="$1"
out="$PWD/repos/patches/$package/"
shift

MSG="$@"

ls -al "$(dirname "$out")"

if git -C "build/$package" commit -am "$MSG"; then
  git -C "build/$package" show | cat
  git -C "build/$package" format-patch --output-directory "$out" HEAD~1
fi
