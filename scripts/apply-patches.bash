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
  patch -p1 -d $patch_dest < "$patch"
done
