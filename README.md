# Proxmox Backup Server in a Container

This is a try to compile Proxmox Backup Server
to run it in a container.

## Run

```bash
docker-compose up -d
```

Then login to `https://<ip>:8007/` with `admin / pbspbs`.
After that change a password.

## Features

There are some features missing, ex.:

- ZFS (it is not installed in a container)

## Configure

### 1. Add to Proxmox VE

Since it runs in a container, it is by default self-signed.
Follow the tutorial: https://pbs.proxmox.com/docs/pve-integration.html.

You might need to read a PBS fingerprint:

```bash
docker-compose exec server proxmox-backup-manager cert info | grep Fingerprint
```

### 2. Persist config, graphs, and logs

Create a new file: `docker-compose.override.yml`:

```yaml
version: '2.1'

volumes:
  cfg:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/pbs/cfg
  logs:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/pbs/logs
  lib:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/pbs/lib
```

### 3. Add a new directory to store data

Create a new file: `docker-compose.override.yml`:

```yaml
version: '2.1'

services:
  server:
    volumes:
      - backups:/backups

volumes:
  backups:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/dev-disk-by-label-backups
```

Then, add a new datastore in a PBS: `https://<IP>:8007/`.

## Build on your own

```bash
make dev-build
```

It builds on any platform, which can be: `amd64`, `arm32v7`, `arm64v8`,
etc. Wait a around 1-3h to compile.

Then you can push to your registry:

```bash
make dev-push
```

Or run locally:

```bash
make dev-shell
make dev-run
```

You might as well pull the `*.deb` from within the image
and install on Debian Bullseye.

## Author

This is just built by Kamil Trzciński, 2020
from the sources found on http://git.proxmox.com/.
