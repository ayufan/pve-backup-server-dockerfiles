#!/bin/bash

# If missing timezone and localtime set them
set_timezone() {
    local zone="$1"

    if [ ! -f "/usr/share/zoneinfo/$zone" ]; then
        echo "Invalid timezone: $zone" >&2
        exit 1
    fi

    ln -snf "/usr/share/zoneinfo/$zone" /etc/localtime
    echo "$zone" > /etc/timezone
}

check_localtime() {
    if [ ! -e /etc/localtime ] && [ ! -L /etc/localtime ]; then
        return 1
    fi

    local target
    target="$(readlink -f /etc/localtime 2>/dev/null || true)"

    if [ -z "$target" ] || [ ! -f "$target" ] || [ ! -s "$target" ]; then
        echo "Invalid TZ value." >&2
        exit 1
    fi

    return 0
}

if [ -n "${TZ:-}" ]; then
    set_timezone "$TZ"
elif ! check_localtime; then
    set_timezone "UTC"
fi

mkdir -p /run/systemd/journal

# Provide the journald socket path expected by libsystemd callers.
# In this container /dev/log already exists, but /run/systemd/journal/socket
# does not, which causes proxmox-daily-update to fail with:
#   Unable to open syslog: ... No such file or directory
#
# To use journald container must be running with command /sbin/init
# and /dev/log must be mount in volumes.
if [ ! -e /run/systemd/journal/socket ]; then
    ln -s /dev/log /run/systemd/journal/socket
fi

exec "$@"
