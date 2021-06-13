#!/bin/bash

set -eo pipefail

for package in *; do
  if [[ ! -d "$package/.cargo/config" ]]; then
    continue
  fi

  # remove .cargo/config
  rm "$package/.cargo/config"

  # remove ex.: librust-anyhow-1+default-dev
  sed -i 's/librust-.*-dev[^,]*/libstd-rust-dev/g' "$package/debian/control"
done
