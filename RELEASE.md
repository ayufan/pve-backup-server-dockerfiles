## Buy me a Coffee

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/Y8Y8GCP24)

If you found it useful :)

## Use docker image

For starting quickly all images are precompiled and hosted at https://hub.docker.com/r/ayufan/proxmox-backup-server/tags.

```bash
docker pull ayufan/proxmox-backup-server:#{GIT_TAG_NAME}
```

## Run as a docker container

```bash
wget https://raw.githubusercontent.com/ayufan/pve-backup-server-dockerfiles/refs/heads/master/docker-compose.yml
TAG=#{GIT_TAG_NAME} docker-compose up -d
```

Adapt `docker-compose.yml` to your environment,
and re-run the `TAG=#{GIT_TAG_NAME} docker-compose up -d`.

Then login to `https://<ip>:8007/` with `admin / pbspbs`.
After that change a password.

## Install server on bare-metal or virtualized host

```bash
wget https://github.com/ayufan/pve-backup-server-dockerfiles/releases/download/#{GIT_TAG_NAME}/proxmox-backup-server-#{GIT_TAG_NAME}-$(dpkg --print-architecture).tgz
tar zxf proxmox-backup-server-*.tgz
proxmox-backup-server-*/install
```

## Use static client binary

Similar to server, the client binary is available for various architectures. The `arm32` is considered unstable, and should only be able to backup, but likely cannot be used to restore data.

```bash
wget https://github.com/ayufan/pve-backup-server-dockerfiles/releases/download/v4.0.12/proxmox-backup-client-#{GIT_TAG_NAME}-$(dpkg --print-architecture).tgz
tar zxf proxmox-backup-client-*.tgz
proxmox-backup-client-*/proxmox-backup-client.sh
```
