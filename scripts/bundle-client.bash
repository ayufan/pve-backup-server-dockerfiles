#!/bin/bash

DESTDIR=/
NAME=proxmox-backup-client-$VERSION
BINARIES=( /src/proxmox-backup/target/static-build/*/release/{pxar,proxmox-backup-client} )

mkdir -p "$DESTDIR/$NAME"

cp -v ${BINARIES[@]} "$DESTDIR/$NAME"
cp -v /scripts/client/* "$DESTDIR/$NAME"

cd $DESTDIR
tar zcfv "$NAME.tgz" $NAME
