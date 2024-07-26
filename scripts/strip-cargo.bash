#!/bin/bash

set -eo pipefail

for package in *; do
  [[ ! -d "$package" ]] && continue

  while read cargo_config; do
    echo -n > "$cargo_config"
    git -C "$package" add "$(realpath "$cargo_config")"
  done < <(find "$package" -wholename '*/.cargo/config' -o -wholename '*/.cargo/config.toml')

  while read cargo_config; do
    echo -n > "$cargo_config"
    git -C "$package" add "$(realpath "$cargo_config")"
  done < <(find "$package" -wholename '*/debian/cargo_home/config' -o -wholename '*/debian/cargo_home/config.toml')

  while read debian_control; do
    echo "Stripping '$debian_control'..."

    # remove ex.: librust-anyhow-1+default-dev (when it ends with `,`)
    sed -i '/^\s*librust-.*-dev[^,]*,/d' "$debian_control"

    # in some cases just replace to `libstd-rust-dev`
    sed -i 's/^\s*librust-.*-dev[^,]*/ libstd-rust-dev/g' "$debian_control"

    # change `cargo:native (>= 0.65.0-1),` to `cargo:native <!nocheck>`
    sed -i 's/cargo:native\s*(>=.*)/cargo:native <!nocheck>/g' "$debian_control"

    # change `dh-cargo (>= 25),` to `dh-cargo`
    sed -i 's/dh-cargo\s*(>=.*)/dh-cargo/g' "$debian_control"
    git -C "$package" add "$(realpath "$debian_control")" || true
  done < <(find "$package" -wholename '*/debian/control')

  if ! git -C "$package" diff --cached --exit-code --quiet; then
    git -C "$package" diff --cached | cat
    git -C "$package" commit -m "strip-cargo.bash"
  fi
done
