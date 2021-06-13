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
    if [[ ! -d "$1" ]]; then
      git clone "git://git.proxmox.com/git/$1.git"
    else
      git -C "$1" fetch
    fi
    git -C "$1" checkout "$2"
  }
fi

perform proxmox-backup 4c00391d78c6c1181385a3b0c25314b98140f3f6
perform proxmox fff7b926eee01462a047444bfe61649741ed1a44
perform proxmox-fuse cdf306f9d2fcd5410957211c8fe0df97903b01cc
perform pxar e5a2495ed3d047db4f2918122662cf8495a34ac1
perform proxmox-mini-journalreader 5ce05d16f63b5bddc0ffffa7070c490763eeda22
perform proxmox-widget-toolkit 557c45056c62edaa480341c262b0286eecb6a56a
perform extjs bef50766a5854f5961c86bc3385751557c4efc44
perform proxmox-i18n 57465621efaf500e972ac6d239f0acad6c6c63fb
perform pve-xtermjs 3b087ebf80621a39e2977cad327056ff4b425efe
perform proxmox-acme-rs ee7fe8f93c9ca5823ec65ce87dc301f2d8c6a55c
perform libjs-qrcodejs 1cc4649f55853d7d890aa444a7a58a8466f10493
perform proxmox-acme 085b9535c4cbd581a277d93e2af0bc84fc2c8bac
