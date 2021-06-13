#!/bin/sh

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

export LD_LIBRARY_PATH=$(dirname "$SCRIPT_PATH"):$LD_LIBRARY_PATH

exec "$SCRIPT_DIR/proxmox-backup-client" "$@"
