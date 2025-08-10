#!/bin/bash

set -eo pipefail

if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
  echo "usage: $0 <repos-file> [repo_name]"
  exit 1
fi

perform() {
  if [[ ! -d "$1" ]]; then
    git clone "git://git.proxmox.com/git/$1.git"
  else
    git -C "$1" fetch
  fi
  git -C "$1" checkout "$2" -f
  git -C "$1" clean -ffdx
  git -C "$1" submodule update --init --recursive
  git -C "$1" submodule foreach git reset --hard
  git -C "$1" submodule foreach git clean -ffdx

  # set the same timestamps for all files, required by some Makefiles
  ( cd "$1"; git ls-files -z | xargs -0 touch -h )
}

while read REPO COMMIT_SHA REST; do
  [[ -n "$2" ]] && [[ "$REPO" != "$2" ]] && continue
  echo "$REPO $COMMIT_SHA..." 1>&2
  ( perform "$REPO" "$COMMIT_SHA" )
done < "$1"
