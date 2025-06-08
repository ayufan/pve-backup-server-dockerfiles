#!/bin/bash

set -eo pipefail

for dir; do
  for patch in $dir/*/*.patch; do
    [[ ! -e $dir ]] && continue

    repo_name=$(basename $(dirname "$patch"))
    echo "$patch => $repo_name..."
    if ! git -C "$repo_name" apply --index "$(realpath "$patch")"; then
      patch -p1 -d "$repo_name" < "$patch"
      find "$repo_name" -name '*.orig' -delete
      find "$repo_name" -name '*.rej' -delete
      git -C "$repo_name" add .
    fi
    git -C "$repo_name" diff --cached > "$patch"
    git -C "$repo_name" commit -m "$(basename $patch)"
  done
done
