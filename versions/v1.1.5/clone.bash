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

perform proxmox-backup f0d23e5370a8f31db81f2d75afd8425171892a35
perform proxmox 4dda9b5865ba0db1b85d5acf76f42330d3e8f1a5
perform proxmox-fuse 238e315c11ee4da77fd412b47bddfe01a2d72166
perform pxar b203d38bcd399f852f898d24403f3d592e5f75f8
perform proxmox-mini-journalreader 8d3028a9a24faea620810f80b5723221310a3f76
perform proxmox-widget-toolkit 33d34da8a7570d97d31b37f09714f53dcd3eb6c0
perform extjs bef50766a5854f5961c86bc3385751557c4efc44
perform proxmox-i18n 57465621efaf500e972ac6d239f0acad6c6c63fb
perform pve-xtermjs d82a762636249e80e67b4de4fdf99fbbda57983c
perform proxmox-acme-rs a6ff69404b9f8e80d78d2a29eda977a3d8f90bfd
perform libjs-qrcodejs 1cc4649f55853d7d890aa444a7a58a8466f10493
