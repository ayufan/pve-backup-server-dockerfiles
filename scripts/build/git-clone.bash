#!/bin/bash

set -eo pipefail

if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
  echo "usage: $0 <repos-file> [repo_name]"
  exit 1
fi

perform() {
  local repo_name="${3:-$1}"
  local primary_base="${GIT_CLONE_PRIMARY:-git://git.proxmox.com/git}"
  local fallback_base="${GIT_CLONE_FALLBACK:-https://git.proxmox.com/git}"

  if [[ ! -d "$1" ]]; then
    if ! git clone "${primary_base}/${repo_name}.git" "$1"; then
      git clone "${fallback_base}/${repo_name}.git" "$1"
    fi
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

while true; do
  REPO=""
  COMMIT_SHA=""
  REST=""

  if ! read REPO COMMIT_SHA REST; then
    [[ -n "$REPO" ]] || break
  fi
  
  [[ -n "$2" ]] && [[ "$REPO" != "$2" ]] && continue
  echo "$REPO $COMMIT_SHA..." 1>&2
  REPO_URL=${REST%%#*}
  ( perform "$REPO" "$COMMIT_SHA" $REPO_URL )
done < "$1"