#!/bin/bash

set -eo pipefail

for package in *; do
  # enable experimental features
  for cargo in $(find "$package/" -name Cargo.toml); do
    echo "Changing $cargo..."
    sed -i '1s/^/cargo-features = ["workspace-inheritance"]\n\n/' "$cargo"
  done

  git -C "$package" add .
  if ! git -C "$package" diff --cached --exit-code --quiet; then
    git -C "$package" diff --cached | cat
    git -C "$package" commit -m "experimental-cargo.bash"
  fi
done
