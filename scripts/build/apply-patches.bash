#!/bin/bash

set -eo pipefail

for dir; do
  while read patch; do
    repo_name=$(basename $(dirname "$patch"))
    [[ ! -d "$repo_name" ]] && continue

    echo "$patch => $repo_name..."
    if ! git -C "$repo_name" apply --index "$(realpath "$patch")"; then
      patch -p1 -d "$repo_name" < "$patch"
      find "$repo_name" -name '*.orig' -delete
      find "$repo_name" -name '*.rej' -delete
      git -C "$repo_name" add .
    fi

    if [[ -z "$(git -C "$repo_name" diff --cached)" ]]; then
      echo "Patch applied, but is in a submodule?"
      continue
    fi

    git -C "$repo_name" diff --cached | grep -v "^index " > "$patch"
    git -C "$repo_name" commit -m "$(basename $patch)"
  done < <(find "$dir" -name "*.patch" | sort)
done
