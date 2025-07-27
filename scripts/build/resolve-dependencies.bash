#!/bin/bash

get_deps() {
  sed -n -e '/^\[\(workspace\.\)\{0,1\}dependencies\]/,/^\[/{ 
    /^[[]/d
    /git/ s/^\([a-z0-9_-]*\)\(\.workspace\)*\s*=.*$/\1 git/p
    /git/! s/^\([a-z0-9_-]*\)\(\.workspace\)*\s*=.*$/\1/p
  }' "$1"
}

declare -A found_deps
declare -A git_deps
declare -A got_deps

echo "Resolving dependencies in $search_dir"

while read cargo_path; do
  cargo_path=$(dirname "$cargo_path")
  cargo_dep=$(basename "$cargo_path")
  git_repo=$(git -C "$cargo_path" rev-parse --show-toplevel)
  found_deps[$cargo_dep]="$cargo_path"
  git_deps[$cargo_dep]="$git_repo"
  got_deps[$(realpath "$cargo_path/Cargo.toml")]="$(get_deps "$cargo_path/Cargo.toml" | sort -u)"
done < <(find "$PWD" -wholename "*/Cargo.toml" -not -path "*/vendor/*" -not -path "*/.build/*")

echo "Found dependencies:"
echo "Total: ${#found_deps[@]}"

get_deps_with_path() {
  local parent_dep_path="$1"
  local parent_dep="$2"
  local parent_dep_git="$3"

  local cargo_dep
  local cargo_git

  [[ -n "${traversed_deps[$parent_dep_path]}" ]] && return
  traversed_deps[$parent_dep_path]=1

  while read cargo_dep cargo_git; do
    [[ -z "$cargo_dep" ]] && continue
    [[ -z "${found_deps["$cargo_dep"]}" ]] && continue
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
  done < <(echo "${got_deps[$(realpath "$parent_dep_path")]}")
}

replace_patch_crates_io() {
  sed -i -e '/^\[patch\.crates-io\]/,/^\[/{//!d}' -e '/^\[patch\.crates-io\]/d' "$1"
  echo "[patch.crates-io]" >> "$1"
}

update_deps() {
  local cargo_toml="$1"
  local cargo_package=$(basename $(dirname "$cargo_toml"))

  local replaced=

  unset traversed_deps
  declare -A traversed_deps

  while read cargo_dep cargo_dep_path; do
    echo "$cargo_dep => $cargo_dep_path"
    grep -q "$cargo_dep.*git" "$cargo_toml" && continue # TODO: this is not fully working\

    if [[ -z "$replaced" ]]; then
      replace_patch_crates_io "$cargo_toml"
      replaced=1
    fi

    echo "$cargo_package: Cargo dep: $cargo_dep => found => $cargo_dep_path"
    echo "$cargo_dep = { path = \"$cargo_dep_path\" }" >> "$cargo_toml"
  done < <(get_deps_with_path "$cargo_toml" "$cargo_package" "" | sort -u)
}

search_dir="${1:-.}"

while read CARGO_TOML; do
  echo "Updating $CARGO_TOML"
  update_deps "$CARGO_TOML"

  git_repo=$(git -C "$(dirname "$CARGO_TOML")" rev-parse --show-toplevel)
  git -C "$git_repo" add "$(realpath "$CARGO_TOML")"
  if ! git -C "$git_repo" diff --cached --exit-code --quiet; then
    git -C "$git_repo" diff --cached | cat
    git -C "$git_repo" commit -m "resolve-dependencies.bash"
  fi
done < <(find "$search_dir" -name Cargo.toml -not -path "*/vendor/*" -not -path "*/.build/*")

echo "Done."
