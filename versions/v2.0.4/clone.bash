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
  if [[ -n "$1" ]]; then
    cd "$1"
  fi

  perform() {
    if [[ ! -d "$1" ]]; then
      git clone "git://git.proxmox.com/git/$1.git"
    else
      git -C "$1" fetch
    fi
    git -C "$1" checkout "$2"
  }
fi

perform proxmox-backup 9ef88578aff278c0c67c82ad1669ae4914420f84 # Mon Jul 12 18:51:41 2021 +0200
perform proxmox fff7b926eee01462a047444bfe61649741ed1a44 # Tue May 18 10:31:51 2021 +0200
perform proxmox-fuse a2933ee6e7b20cec1bc790b375471e1487004652 # Tue Jul 6 08:56:37 2021 +0200
perform proxmox-apt 9a51a30f4673cdc3777f3b40380c4d75a713db1a # Fri Jul 2 13:04:00 2021 +0200
perform proxmox-openid-rs 558fbff1d72d21b3aa146203153bad89042f1d99 # Wed Jun 30 08:43:40 2021 +0200
perform pxar e5a2495ed3d047db4f2918122662cf8495a34ac1 # Mon May 17 14:09:19 2021 +0200
perform proxmox-mini-journalreader 5ce05d16f63b5bddc0ffffa7070c490763eeda22 # Fri May 14 16:57:03 2021 +0200
perform proxmox-widget-toolkit a4fc99f7abb95533062258e2c90b889da542eec0 # Mon Jul 12 09:52:32 2021 +0200
perform extjs 58b59e2e04ae5cc29a12c10350db15cceb556277 # Wed Jun 2 16:18:48 2021 +0200
perform proxmox-i18n 0a877479b28ce4e0478a9016e427f2bb18587e6f # Mon Jul 5 18:20:42 2021 +0200
perform pve-xtermjs 3b087ebf80621a39e2977cad327056ff4b425efe # Fri May 14 14:50:51 2021 +0200
perform proxmox-acme-rs f28a85da5e9658b84956136d2789a0596c0abbc9 # Fri Jun 11 14:00:55 2021 +0200
perform libjs-qrcodejs 1cc4649f55853d7d890aa444a7a58a8466f10493 # Sun Nov 22 18:57:27 2020 +0100
perform proxmox-acme 1a9d0b7bad30f125e54ef1437cb6e1a96e29be3a # Mon Jul 5 18:58:34 2021 +0200
perform pve-eslint ef0a5638b025ec9b9e3aa4df61a5b3b6bd471439 # Wed Jun 9 16:40:31 2021 +0200
