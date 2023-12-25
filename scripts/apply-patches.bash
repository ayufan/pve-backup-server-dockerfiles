#!/bin/bash

set -eo pipefail

for patch; do
  if [[ ! -e $patch ]]; then
    continue
  fi

  patch_dest=$(basename "$patch". patch)
  patch_dest=${patch_dest%%~*}
  patch_dest=${patch_dest%%.*}

  echo "$patch => $patch_dest..."
  if ! git -C "$patch_dest" apply --index "$(realpath "$patch")"; then
    patch -p1 -d "$patch_dest" < "$patch"
    find "$patch_dest" -name '*.orig' -delete
    find "$patch_dest" -name '*.rej' -delete
    git -C "$patch_dest" add .
  fi
  git -C "$patch_dest" diff --cached > "$patch"
  git -C "$patch_dest" commit -m "$(basename $patch)"
done
