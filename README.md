# Proxmox Backup Server in a Container

- [![GitHub release (latest by date)](https://img.shields.io/github/v/release/ayufan/pve-backup-server-dockerfiles?label=GitHub%20Release)](https://github.com/ayufan/pve-backup-server-dockerfiles/releases) [![Docker Image Version (latest stable (amd64))](https://img.shields.io/docker/v/ayufan/proxmox-backup-server/latest?arch=amd64&label=Docker:%20latest)](https://hub.docker.com/r/ayufan/proxmox-backup-server/tags) [![Docker Image Version (latest stable (arm64))](https://img.shields.io/docker/v/ayufan/proxmox-backup-server/latest?arch=arm64&label=Docker:%20latest)](https://hub.docker.com/r/ayufan/proxmox-backup-server/tags)
- [![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/ayufan/pve-backup-server-dockerfiles?include_prereleases&color=red&label=GitHub%20Pre-Release)](https://github.com/ayufan/pve-backup-server-dockerfiles/releases/latest) [![Docker Image Version (latest stable (amd64))](https://img.shields.io/docker/v/ayufan/proxmox-backup-server/beta?arch=amd64&color=red&label=Docker:%20beta)](https://hub.docker.com/r/ayufan/proxmox-backup-server/tags) [![Docker Image Version (latest stable (arm64))](https://img.shields.io/docker/v/ayufan/proxmox-backup-server/beta?arch=amd64&color=red&label=Docker:%20beta)](https://hub.docker.com/r/ayufan/proxmox-backup-server/tags)

This is an unofficial compilation of Proxmox Backup Server
to run it in a container for AMD64 and ARM64.

Running in a container might result in some functions not working
properly. Feel free to create an issue to debug those.

## Buy me a Coffee

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y8GCP24)

If you found it useful :)

## Common problems

- Some people see authentication failure using `admin@pbs`: Ensure that `/run` is mounted to `tmpfs` which is requirement of `2.1.x`
- Some Synology devices use a really old kernel (3.1), for such the https://github.com/ayufan/pve-backup-server-dockerfiles/pull/15
  is needed, and image needs to be manually recompiled.

## Pre-built images

For starting quickly all images are precompiled and hosted
at https://hub.docker.com/r/ayufan/proxmox-backup-server.

Or:

```bash
# Latest stable / release tag
docker pull ayufan/proxmox-backup-server:latest

# Latest pre-release / beta tag
docker pull ayufan/proxmox-backup-server:beta
```

## Run

```bash
wget https://raw.githubusercontent.com/ayufan/pve-backup-server-dockerfiles/refs/heads/master/docker-compose.yml
docker-compose up -d
```

**Run beta variant:**

```bash
wget https://raw.githubusercontent.com/ayufan/pve-backup-server-dockerfiles/refs/heads/master/docker-compose.yml
TAG=beta docker-compose up -d
```

Then login to `https://<ip>:8007/` with `admin / pbspbs`.
After that change a password.

See the example [docker-compose.yml](./docker-compose.yml).

## Features

The core features should work, but there are ones do not work due to container architecture:

- ZFS: it is not installed in a container
- Shell: since the PVE (not PAM) authentication is being used, and since the shell access does not make sense in an ephemeral container environment
- PAM authentication: since containers are by definition ephemeral and no `/etc/` configs are being persisted

## Changelog

See [Releases](https://github.com/ayufan/pve-backup-server-dockerfiles/releases).

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

Refer to [PROCESS.md](PROCESS.md).

## Build on your own

Refer to [PROCESS.md](PROCESS.md).

## Author

This is just built by Kamil Trzciński, 2020-2023
from the sources found on http://git.proxmox.com/.
