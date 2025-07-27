#!/bin/bash

case "$1" in
  arm32)
    TARGET_ARCH="armv7-unknown-linux-gnueabihf"
    DPKG_ARCH="armhf"
    PKG="gcc-arm-linux-gnueabihf"
    ;;

  *)
    exit 0
    ;;
esac

rustup target add "$TARGET_ARCH"
dpkg --add-architecture "$DPKG_ARCH"
apt update -y
apt install -y "$PKG"
apt install -y libssl-dev:"$DPKG_ARCH" libzstd-dev:"$DPKG_ARCH" libfuse3-dev:"$DPKG_ARCH" libacl1-dev:"$DPKG_ARCH" uuid-dev:"$DPKG_ARCH" libz-dev:"$DPKG_ARCH"
