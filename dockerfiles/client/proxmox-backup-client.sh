#!/bin/sh

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

exec "$SCRIPT_DIR/proxmox-backup-client" "$@"
