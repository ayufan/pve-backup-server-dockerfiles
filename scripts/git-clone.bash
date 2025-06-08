#!/bin/bash

set -eo pipefail

if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
  echo "usage: $0 <repos-file> [path]"
  exit 1
fi

perform() {
  if [[ ! -d "$1" ]]; then
    git clone "git://git.proxmox.com/git/$1.git"
  else
    git -C "$1" fetch
  fi
  git -C "$1" checkout "$2" -f
  git -C "$1" clean -fdx
}

while read REPO COMMIT_SHA REST; do
  echo "$REPO $COMMIT_SHA..." 1>&2
  (
    [[ -n "$2" ]] && cd "$2"
    perform "$REPO" "$COMMIT_SHA"
  )
done < "$1"
