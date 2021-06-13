#!/bin/bash

set -eo pipefail

if [[ "$1" == "show-sha" ]]; then
  tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
  cd "$tmp_dir/"
  trap 'cd ; rm -rf $tmp_dir' EXIT

  perform() {
    git clone "git://git.proxmox.com/git/$1.git" 2>/dev/null
    echo "perform $1 $(git -C "$1" rev-parse "HEAD")"
  }
else
  perform() {
    git clone "git://git.proxmox.com/git/$1.git"
    git -C "$1" checkout "$2"
  }
fi

perform proxmox-backup master
perform proxmox master
perform proxmox-fuse master
perform pxar master
perform proxmox-mini-journalreader master
perform proxmox-widget-toolkit master
perform extjs master
perform proxmox-i18n master
perform pve-xtermjs master
perform proxmox-acme-rs master
perform libjs-qrcodejs master
perform proxmox-acme master
