#!/bin/bash

replace_patch_crates_io() {
  sed -i -e '/^\[patch\.crates-io\]/,/^\[/{//!d}' -e '/^\[patch\.crates-io\]/d' "$1"
  echo "[patch.crates-io]" >> "$1"
}

get_deps() {
  local all=$(sed -n -e '/^\[dependencies\]/,/^\[/{//!p}' "$1")
  echo "$all" | grep git | sed -n -e 's/^\([a-z0-9_-]*\)\(\.workspace\)*\s*=.*$/\1 git/p'
  echo "$all" | grep -v git | sed -n -e 's/^\([a-z0-9_-]*\)\(\.workspace\)*\s*=.*$/\1/p'

  local all=$(sed -n -e '/^\[workspace\.dependencies\]/,/^\[/{//!p}' "$1")
  echo "$all" | grep git | sed -n -e 's/^\([a-z0-9_-]*\)\(\.workspace\)*\s*=.*$/\1 git/p'
  echo "$all" | grep -v git | sed -n -e 's/^\([a-z0-9_-]*\)\(\.workspace\)*\s*=.*$/\1/p'
}

get_deps_with_path() {
  local parent_dep_path="$1"
  local parent_dep="$2"
  local parent_dep_git="$3"

  local cargo_dep
  local cargo_git

  while read cargo_dep cargo_git; do
    local cargo_dep_path="${found_deps["$cargo_dep"]}"
    [[ -z "$cargo_dep_path" ]] && cargo_dep_path="${found_deps["$cargo_dep-rs"]}"
    [[ -z "$cargo_dep_path" ]] && continue

    if [[ -n "$parent_dep_git" ]] && [[ "${git_deps["$parent_dep"]}" == "${git_deps["$cargo_dep"]}" ]]; then
      get_deps_with_path "$cargo_dep_path/Cargo.toml" "$cargo_dep" "$parent_dep_git"
    elif [[ "${git_deps["$parent_dep"]}" == "${git_deps["$cargo_dep"]}" ]]; then
      get_deps_with_path "$cargo_dep_path/Cargo.toml" "$cargo_dep" "$parent_dep_git"
    else
      echo "$cargo_dep $cargo_dep_path"
      get_deps_with_path "$cargo_dep_path/Cargo.toml" "$cargo_dep" "$cargo_git"
    fi
  done < <(get_deps "$parent_dep_path")
}

update_deps() {
  local cargo_toml="$1"
  local cargo_package=$(basename $(dirname "$cargo_toml"))

  replace_patch_crates_io "$cargo_toml"

  while read cargo_dep cargo_dep_path; do
    echo "$cargo_dep => $cargo_dep_path"
    grep -q "$cargo_dep.*git" "$cargo_toml" && continue # TODO: this is not fully working

    echo "$cargo_package: Cargo dep: $cargo_dep => found => $cargo_dep_path"
    echo "$cargo_dep = { path = \"$cargo_dep_path\" }" >> "$cargo_toml"
  done < <(get_deps_with_path "$cargo_toml" "$cargo_package" "" | sort -u)
}

search_dir="${1:-.}"

declare -A found_deps
declare -A git_deps

while read cargo_path; do
  cargo_path=$(dirname "$cargo_path")
  cargo_dep=$(basename "$cargo_path")
  git_repo=$(git -C "$cargo_path" rev-parse --show-toplevel)
  found_deps[$cargo_dep]="$cargo_path"
  git_deps[$cargo_dep]="$git_repo"
done < <(find "$PWD" -wholename "*/Cargo.toml" | sort)

while read CARGO_TOML; do
  update_deps "$CARGO_TOML"

  git_repo=$(git -C "$(dirname "$CARGO_TOML")" rev-parse --show-toplevel)
  git -C "$git_repo" add "$(realpath "$CARGO_TOML")"
  if ! git -C "$git_repo" diff --cached --exit-code --quiet; then
    git -C "$git_repo" diff --cached | cat
    git -C "$git_repo" commit -m "resolve-dependencies.bash"
  fi
done < <(find $1 -name Cargo.toml)

echo "Done."
