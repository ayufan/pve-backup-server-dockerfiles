#!/bin/bash

set -eo pipefail

for patch; do
  if [[ -e $patch ]]; then
    echo $patch...
    patch -p1 -d $(basename "$patch" .patch) < "$patch"
  fi
done
