#!/bin/bash

set -eo pipefail

if [[ "$1" == "show-sha" ]]; then
  VERSION="${2:-master}"
  VERSION_DATE=""

  tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
  cd "$tmp_dir/"
  trap 'cd ; rm -rf $tmp_dir' EXIT

  perform() {
    git clone "git://git.proxmox.com/git/$1.git" 2>/dev/null
    if [[ -z "$VERSION_TIMESTAMP" ]]; then
      REVISION=$(git -C "$1" rev-parse "$VERSION")
      VERSION_TIMESTAMP=$(git -C "$1" log -1 --format=%ct "$VERSION")
    else
      while read TIMESTAMP REVISION; do
        if [[ $TIMESTAMP -le $VERSION_TIMESTAMP ]]; then
          break
        fi
      done < <(git -C "$1" log --format="%ct %H")
    fi

    echo "perform $1 $REVISION # $(git -C "$1" log -1 --format="%cd" $REVISION)"
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

perform proxmox-backup 4d86df04a0739bfeb8594564474ae1c9754baf3f # Wed Jun 16 09:55:47 2021 +0200
perform proxmox fff7b926eee01462a047444bfe61649741ed1a44 # Tue May 18 10:31:51 2021 +0200
perform proxmox-fuse cdf306f9d2fcd5410957211c8fe0df97903b01cc # Fri May 7 10:57:08 2021 +0200
perform pxar e5a2495ed3d047db4f2918122662cf8495a34ac1 # Mon May 17 14:09:19 2021 +0200
perform proxmox-mini-journalreader 5ce05d16f63b5bddc0ffffa7070c490763eeda22 # Fri May 14 16:57:03 2021 +0200
perform proxmox-widget-toolkit 3d886f94228daece3d0a993c5bef2aae121cf6a8 # Tue Jun 15 14:43:58 2021 +0200
perform extjs 58b59e2e04ae5cc29a12c10350db15cceb556277 # Wed Jun 2 16:18:48 2021 +0200
perform proxmox-i18n 57465621efaf500e972ac6d239f0acad6c6c63fb # Mon Apr 26 16:27:55 2021 +0200
perform pve-xtermjs 3b087ebf80621a39e2977cad327056ff4b425efe # Fri May 14 14:50:51 2021 +0200
perform proxmox-acme-rs f28a85da5e9658b84956136d2789a0596c0abbc9 # Fri Jun 11 14:00:55 2021 +0200
perform libjs-qrcodejs 1cc4649f55853d7d890aa444a7a58a8466f10493 # Sun Nov 22 18:57:27 2020 +0100
perform proxmox-acme 085b9535c4cbd581a277d93e2af0bc84fc2c8bac # Tue Jun 8 10:29:08 2021 +0200
perform pve-eslint ef0a5638b025ec9b9e3aa4df61a5b3b6bd471439 # Wed Jun 9 16:40:31 2021 +0200
