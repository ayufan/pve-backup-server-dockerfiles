#!/bin/bash

set -xeo pipefail

for package; do
  [[ ! -d "$package" ]] && continue

  (
    cd "$package/"
    # # enable experimental features
    # for cargo in $(find . -path './.build' -prune -o -name Cargo.toml); do
    #   echo "Changing $cargo..."
    #   sed -i '1s/^/cargo-features = ["workspace-inheritance"]\n\n/' "$cargo"
    #   git add "$cargo" || true
    # done

    if ! git diff --cached --exit-code --quiet; then
      git diff --cached | cat
      git commit -m "experimental-cargo.bash"
    fi
  )
done
