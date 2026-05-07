#!/bin/bash

mkdir -p /run/systemd/journal

# Provide the journald socket path expected by libsystemd callers.
# In this container /dev/log already exists, but /run/systemd/journal/socket
# does not, which causes proxmox-daily-update to fail with:
#   Unable to open syslog: ... No such file or directory
if [ ! -e /run/systemd/journal/socket ]; then
    ln -s /dev/log /run/systemd/journal/socket
fi

exec "$@"
