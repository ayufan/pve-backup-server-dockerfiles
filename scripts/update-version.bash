#!/bin/bash

set -eo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <version> [sha]"
  exit 1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VERSION="${1}"
LATEST_SHA="${2:-master}"
LATEST_TS=""

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
trap 'cd ; rm -rf $tmp_dir' EXIT

perform() {
  git clone "git://git.proxmox.com/git/$1.git" 2>/dev/null
  if [[ -z "$LATEST_TS" ]]; then
    REV=$(git -C "$1" rev-parse "$LATEST_SHA")
    LATEST_TS=$(git -C "$1" log -1 --format=%ct "$LATEST_SHA")
  else
    while read TS REV; do
      if [[ $TS -le $LATEST_TS ]]; then
        break
      fi
    done < <(git -C "$1" log --format="%ct %H")
  fi

  CHANGE_TIME=$(git -C "$1" log -1 --format="%cd" $REV)

  echo "$1 $REV # $CHANGE_TIME"
}

if [[ ! -e "repos/versions" ]]; then
  echo "Missing 'versions' file."
  exit 1
fi

while read REPO COMMIT_SHA REST; do
  echo "$REPO $COMMIT_SHA..." 1>&2
  (
    cd "$tmp_dir/"
    perform "$REPO" "$COMMIT_SHA"
  )
done < "repos/versions" > "repos/versions.tmp"

mv "repos/versions.tmp" "repos/versions"
echo "VERSION := ${VERSION}" > "repos/version.mk"
