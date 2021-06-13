#!/bin/bash

set -eo pipefail

for patch; do
  echo $i...
  patch -p1 -d $(basename "$patch" .patch) < "$patch"
done
