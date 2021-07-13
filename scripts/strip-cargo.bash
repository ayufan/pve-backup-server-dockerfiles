#!/bin/bash

set -eo pipefail

for package in *; do
  if [[ -f "$package/.cargo/config" ]]; then
    rm -v "$package/.cargo/config"
  fi

  # remove ex.: librust-anyhow-1+default-dev
  if [[ -f "$package/debian/control" ]]; then
    echo "Stripping '$package/debian/control'..."
    sed -i 's/librust-.*-dev[^,]*/libstd-rust-dev/g' "$package/debian/control"
  fi
done
