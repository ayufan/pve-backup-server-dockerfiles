#!/bin/bash

set -eo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ "$1" == "show-sha" ]]; then
  VERSION="${2:-master}"
  VERSION_DATE=""

  tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
  cd "$tmp_dir/"
  trap 'cd ; rm -rf $tmp_dir' EXIT

  perform() {
    git clone "git://git.proxmox.com/git/$1.git" 2>/dev/null
    if [[ -z "$VERSION_TIMESTAMP" ]]; then
      REVISION=$(git -C "$1" rev-parse "$VERSION")
      VERSION_TIMESTAMP=$(git -C "$1" log -1 --format=%ct "$VERSION")
    else
      while read TIMESTAMP REVISION; do
        if [[ $TIMESTAMP -le $VERSION_TIMESTAMP ]]; then
          break
        fi
      done < <(git -C "$1" log --format="%ct %H")
    fi

    CHANGE_TIME=$(git -C "$1" log -1 --format="%cd" $REVISION)

    echo "$1 $REVISION # $CHANGE_TIME"
  }
else
  if [[ -n "$1" ]]; then
    cd "$1"
  fi

  perform() {
    if [[ ! -d "$1" ]]; then
      git clone "git://git.proxmox.com/git/$1.git"
    else
      git -C "$1" fetch
    fi
    git -C "$1" checkout "$2"
  }
fi

if [[ ! -e "$SCRIPT_DIR/versions" ]]; then
  echo "Missing 'versions' file."
  exit 1
fi

while read REPO COMMIT_SHA REST; do
  echo "$REPO $COMMIT_SHA..." 1>&2
  perform "$REPO" "$COMMIT_SHA"
done < "$SCRIPT_DIR/versions"
