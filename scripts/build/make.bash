#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <name> [operations...]"
  exit 1
fi

set -xeo pipefail
export DEBIAN_FRONTEND=noninteractive
export DEB_BUILD_OPTIONS=nocheck
KEEP=

while [[ -n "$1" ]]; do
  case "$1" in
    --nightly)
      export RUSTUP_TOOLCHAIN=nightly
      ;;

    --keep)
      KEEP=1
      ;;

    *)
      break
      ;;
  esac

  shift
done

REPO="$1"
DEPS=
shift

mkdir -p build
cd build

case "$(dpkg --print-architecture)" in
  amd64) ARCH="amd64" ;;
  arm64) ARCH="arm64" ;;
  armhf) ARCH="arm32" ;;
  *)
    echo "Unsupported architecture: $(dpkg --print-architecture)"
    exit 1
    ;;
esac

case "$CROSS_ARCH" in
  arm32)
    export PKG_CONFIG_ALLOW_CROSS_armv7_unknown_linux_gnueabihf=1
    export PKG_CONFIG_LIBDIR_armv7_unknown_linux_gnueabihf=/usr/lib/arm-linux-gnueabihf/pkgconfig
    export DEB_HOST_RUST_TYPE=armv7-unknown-linux-gnueabihf
    export ARCH=arm32
    ;;

  *)
    ;;
esac

if [[ -z "$DEBUG" ]]; then
  if [[ -f "../repos/$REPO.deps" ]]; then
    ../scripts/build/git-clone.bash "../repos/$REPO.deps"
    DEPS=1
  else
    ../scripts/build/git-clone.bash ../repos/deps "$REPO"
  fi
  ../scripts/build/strip-cargo.bash "$REPO"
  ../scripts/build/apply-patches.bash "../repos/patches/$REPO" "../repos/patches-$ARCH/$REPO"
  ../scripts/build/resolve-dependencies.bash "$REPO"
  ../scripts/build/experimental-cargo.bash "$REPO"
fi

do_dpkg_build_dep() {
  local d="${1:-.}"
  shift || true

  pushd "$d/"
  [[ -e "debian/control" ]] && apt-get -y build-dep "$PWD"
  popd
  do_archive
}

do_dpkg_build() {
  local d="${1:-.}"
  shift || true

  pushd "$d/"
  [[ -e "debian/control" ]] && apt-get -y build-dep "$PWD"
  mkdir -p .build
  cp -av * .build/
  pushd .build/
  dpkg-buildpackage -uc -us -b
  popd
  popd
  do_archive
}

do_dpkg_install() {
  find "." -name "*.deb" | xargs -r apt -y install
}

run_until_broken() {
  for i in $(seq 1 10); do
    if eval "$@"; then
      return 0
    fi

    if apt-get check >/dev/null 2>&1; then
      echo "Build failure."
      return 1
    fi

    echo "APT reports broken dependencies."
    apt-get install -f -y
  done

  return 1
}

do_make_dinstall() {
  local d="${1:-.}"
  local p="${2:-.}"
  shift || true
  shift || true

  pushd "$d/"
  git clean -ffdx -e '*.deb'
  [[ -e "$p/debian/control" ]] && apt-get -y build-dep "$PWD/$p"
  run_until_broken make dinstall "$@"
  popd
  do_archive
}

do_make() {
  local d="${1:-.}"
  local p="${2:-.}"
  shift || true
  shift || true

  pushd "$d/"
  git clean -ffdx -e '*.deb'
  [[ -e "$p/debian/control" ]] && apt-get -y build-dep "$PWD/$p"
  run_until_broken make "$@"
  popd
  do_archive
}

do_make_deb() {
  local d="${1:-.}"
  local p="${2:-.}"
  shift || true
  shift || true

  pushd "$d/"
  git clean -ffdx -e '*.deb'
  [[ -e "$p/debian/control" ]] && apt-get -y build-dep "$PWD/$p"
  run_until_broken make deb "$@"
  popd
  do_archive
}

do_make_build() {
  local d="${1:-.}"
  local p="${2:-.}"
  shift || true
  shift || true

  pushd "$d/"
  run_until_broken make build "$@"
  popd
}

do_archive() {
  mkdir -p "../../release/$REPO"
  find "." -name "*.deb" | xargs -r -I{} cp -v "{}" "../../release/$REPO"
}

do_strip_cargo() {
  ../../scripts/strip-cargo.bash .
}

do_rust_pkg() {
  while read pkg_toml; do
    pkg_dir=$(dirname "$pkg_toml")
    (
      cd "$pkg_dir"
      cargo package --target-dir=/cargo/registry/src/index.crates.io-*
    )
  done < <(find . -path './.build' -prune -o -name Cargo.toml)
}

cd "$REPO"
for arg; do
  ( eval "do_$arg" )
done

if [[ -z "$KEEP" ]]; then
  if [[ -n "$DEPS" ]]; then
    cd ../..
    rm -r build
  else
    cd ..
    rm -r "$REPO"
  fi
fi
