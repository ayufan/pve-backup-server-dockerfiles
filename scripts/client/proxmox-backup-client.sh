#!/bin/sh

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SCRIPT_LIB="$SCRIPT_DIR/lib"

exec "$SCRIPT_LIB"/ld-linux-* --library-path "$SCRIPT_LIB" "$SCRIPT_DIR/proxmox-backup-client" "$@"
