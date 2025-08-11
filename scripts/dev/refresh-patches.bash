#!/bin/bash

mkdir -p /steps

set -eo pipefail

refresh() {
  echo ">> Refreshing $1..."

  while ! ./scripts/build/make.bash "$1"; do
    [[ ! -t 0 ]] && return 1

    read -p "Build failed for '$1'. Retry? [y/N] " choice
    [[ "$choice" != "y" ]] && return 1
  done

  echo ">> Done refreshing $1."
}

shopt -s nullglob

for repo_path in repos/patches/*; do
  repo_name=${repo_path##*/}
  refresh "$repo_name"
done

for arch in arm32 arm64 amd64; do
  for repo_path in repos/patches-$arch/*; do
    repo_name=${repo_path##*/}
    CROSS_ARCH="$arch" refresh "$repo_name"
  done
done

echo ">> Done."
