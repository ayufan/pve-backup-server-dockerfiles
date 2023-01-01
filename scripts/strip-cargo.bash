#!/bin/bash

set -eo pipefail

for package in *; do
  if [[ -f "$package/.cargo/config" ]]; then
    rm -v "$package/.cargo/config"
  fi

  if [[ -f "$package/debian/control" ]]; then
    echo "Stripping '$package/debian/control'..."

    # remove ex.: librust-anyhow-1+default-dev (when it ends with `,`)
    sed -i '/^\s*librust-.*-dev[^,]*,/d' "$package/debian/control"

    # in some cases just replace to `libstd-rust-dev`
    sed -i 's/^\s*librust-.*-dev[^,]*/ libstd-rust-dev/g' "$package/debian/control"

    # change `cargo:native (>= 0.65.0-1),` to `cargo:native <!nocheck>`
    sed -i 's/cargo:native\s*(>=.*)/cargo:native <!nocheck>/g' "$package/debian/control"
  fi

  git -C "$package" add .
  if ! git -C "$package" diff --cached --exit-code --quiet; then
    git -C "$package" diff --cached | cat
    git -C "$package" commit -m "strip-cargo.bash"
  fi
done
