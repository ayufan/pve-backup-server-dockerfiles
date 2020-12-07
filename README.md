# Proxmox Backup Server in a Container

This is a try to compile Proxmox Backup Server
to run it in a container.

## Run

```bash
docker-compose up -d
```

Then login to `https://<ip>:8007/` with `admin / pbspbs`.
After that change a password.

## Configure

### 1. Persist config, graphs, and logs

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

### 2. Add a new directory to store data

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
make build
```

It builds on any platform, which can be: `amd64`, `arm32v7`, `arm64v8`,
etc. Wait a around 1-3h to compile.

Then you can push to your registry:

```bash

```

## Author

This is just built by Kamil Trzciński, 2020
from the sources found on http://git.proxmox.com/.
