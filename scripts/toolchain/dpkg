#!/bin/bash

# Convert the `dpkg -i` to `apt install -y`
if [[ "$1" == "-i" ]]; then
  shift
  expand_paths() {
    for deb; do
      if [[ -e "$deb" ]]; then
        echo "$(realpath "$deb")"
      else
        echo "$deb"
      fi
    done
  }
  exec /usr/bin/apt install -y $(expand_paths "$@")
fi

exec /usr/bin/dpkg "$@"
