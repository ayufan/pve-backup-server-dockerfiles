# Proxmox Backup Server in a Container

[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/ayufan/proxmox-backup-server?sort=semver)](https://hub.docker.com/repository/docker/ayufan/proxmox-backup-server)

This is an unofficial compilation of Proxmox Backup Server
to run it in a container for AMD64 and ARM64.

Running in a container might result in some functions not working
properly. Feel free to create an issue to debug those.

## Common problems

- Some people see authentication failure using `admin@pbs`: Ensure that `/run` is mounted to `tmpfs` which is requirement of `2.1.x`
- Some Synology devices use a really old kernel (3.1), for such the https://github.com/ayufan/pve-backup-server-dockerfiles/pull/15
  is needed, and image needs to be manually recompiled.

## Pre-built images

For starting quickly all images are precompiled and hosted
at https://hub.docker.com/r/ayufan/proxmox-backup-server.

Or:

```bash
docker pull ayufan/proxmox-backup-server:latest
```

## Run

```bash
docker-compose up -d
```

Then login to `https://<ip>:8007/` with `admin / pbspbs`.
After that change a password.

## Features

The core features should work, but there are ones do not work due to container architecture:

- ZFS: it is not installed in a container
- Shell: since the PVE (not PAM) authentication is being used, and since the shell access does not make sense in an ephemeral container environment
- PAM authentication: since containers are by definition ephemeral and no `/etc/` configs are being persisted

## Changelog

- v2.1.5 - 10 Feb, 2022 - also fixes bug with missing ksm
- v2.1.2 - 30 Nov, 2021 - this version requires `tmpfs` to be used for `/run`. Inspect `docker-compose.yml`
- v2.0.7 - Jul 31, 2021
- v2.0.4 - Jul 14, 2021
- v1.1.9 - Jun 14, 2021

## Configure

### 1. Add to Proxmox VE

Since it runs in a container, it is by default self-signed.
Follow the tutorial: https://pbs.proxmox.com/docs/pve-integration.html.

You might need to read a PBS fingerprint:

```bash
docker-compose exec server proxmox-backup-manager cert info | grep Fingerprint
```

### 2. Add a new directory to store data

Create a new file (or merge with existing): `docker-compose.override.yml`:

```yaml
version: '2.1'

services:
  pbs:
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

### 3. Configure TZ (optional)

If you are running in Docker it might be advised to configure timezone.

Create a new file (or merge with existing): `docker-compose.override.yml`:

```yaml
version: '2.1'

services:
  pbs:
    environment:
      TZ: Europe/Warsaw
```

### 4. Allow smartctl access

To be able to view SMART parameters via UI you need to expose drives and give container
a special capability.

Create a new file (or merge with existing): `docker-compose.override.yml`:

```yaml
version: '2.1'

services:
  pbs:
    devices:
      - /dev/sda
      - /dev/sdb
    cap_add:
      - SYS_RAWIO
```

### 5. Persist config, graphs, and logs (optional, but advised)

Create a new file (or merge with existing): `docker-compose.override.yml`:

```yaml
version: '2.1'

volumes:
  pbs_etc:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/pbs/etc
  pbs_logs:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/pbs/logs
  pbs_lib:
    driver: local
    driver_opts:
      type: ''
      o: bind
      device: /srv/pbs/lib
```

### 6. Configure backup user UID & GID (optional)

To change the case you wish to change what user and group id the container runs at then set the following

Create a new file (or merge with existing): `docker-compose.override.yml`:

```yaml
version: '2.1'

services:
  pbs:
    environment:
      BGID: 1000
      BUID: 1001
```

## Install on bare-metal host

Docker is convienient, but in some cases it might be simply better to install natively.
Since the packages are built against `Debian Buster` your system needs to run soon
to be stable distribution.

You can copy compiled `*.deb` (it will automatically pick `amd64` or `arm64v8` based on your distribution)
from the container and install:

```bash
cd /tmp
docker run --rm ayufan/proxmox-backup-server:latest tar c /src/ | tar x
apt install $PWD/src/*.deb
```

## Recompile latest version or master

You can compile latest version or master with a set of commands
and push them to the registry.

```bash
# build v1.0.5
make all-build VERSION=v1.0.5

# build master
make all-build

# build and push to registry v1.0.5
make all-push VERSION=v1.0.5 REGISTRY=my.registry.com/pbs

# build and push to registry v1.0.5
make all-push REGISTRY=my.registry.com/pbs

# make the given version latest
make all-latest VERSION=v1.0.5
```

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

This is just built by Kamil Trzciński, 2020-2021
from the sources found on http://git.proxmox.com/.
