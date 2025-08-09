#!/bin/bash

set -eo pipefail

if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
  echo "usage: $0 [version-file|version] [sticky-rev]"
  exit 1
fi

if [[ -f "$1" ]]; then
  DEPS_FILE=$(realpath "$1")
  VERSION_FILE=""
  VERSION=""
elif [[ -f "repos/deps" ]]; then
  DEPS_FILE=$(realpath "repos/deps")
  VERSION_FILE=$(realpath "VERSION")
  VERSION="${1}"
else 
  echo "Missing 'repos/deps' file." 1>&2
  echo "$@" 1>&2
  exit 1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_ROOT=$(realpath "$0")
ROOT_REV="$2"
ROOT_TS=""

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
trap 'cd ; rm -rf $tmp_dir' EXIT

perform() {
  git clone "git://git.proxmox.com/git/$1.git" 2>/dev/null

  if [[ -z "$ROOT_REV" ]] || [[ -z "$ROOT_TS" ]]; then
    REPO_REV=$(git -C "$1" rev-parse "${ROOT_REV:-HEAD}")
    ROOT_TS=$(git -C "$1" log -1 --format=%ct "$REPO_REV")
  else
    while read REPO_TS REPO_REV; do
      [[ $REPO_TS -le $ROOT_TS ]] && break
    done < <(git -C "$1" log --format="%ct %H")
  fi

  CHANGE_TIME=$(git -C "$1" log -1 --format="%cd" $REPO_REV)

  echo "$1 $REPO_REV # $CHANGE_TIME"
}

cd "$tmp_dir/"

while read REPO COMMIT_SHA REST; do
  echo "$REPO $COMMIT_SHA..." 1>&2
  REPO_TS=
  REPO_REV=
  perform "$REPO" "$COMMIT_SHA"

  REPO_DEPS_FILE="$(dirname "$DEPS_FILE")/$REPO.deps"

  if [[ -e "$REPO_DEPS_FILE" ]] && [[ -n "$VERSION" ]] && [[ -n "$REPO_REV" ]]; then
    $SCRIPT_ROOT "$REPO_DEPS_FILE" "$REPO_REV"
  fi
done < "$DEPS_FILE" > "$DEPS_FILE.tmp"

mv "$DEPS_FILE.tmp" "$DEPS_FILE"

if [[ -n "$VERSION_FILE" ]]; then
  echo "${VERSION}" > "$VERSION_FILE"
fi
