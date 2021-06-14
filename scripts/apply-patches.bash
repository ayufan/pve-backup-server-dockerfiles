#!/bin/bash

set -eo pipefail

for patch; do
  if [[ ! -e $patch ]]; then
    continue
  fi

  local patch_dest=${patch%%~.*}

  echo "$patch => $patch_dest..."
  patch -p1 -d $patch_dest < "$patch"
done
