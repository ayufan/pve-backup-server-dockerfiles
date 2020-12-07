ARG ARCH=
FROM ${ARCH}debian:bullseye AS builder

RUN apt-get -y update && \
  apt-get -y install \
    build-essential git-core \
    lintian pkg-config quilt patch cargo \
    nodejs node-colors node-commander \
    libudev-dev libapt-pkg-dev \
    libacl1-dev libpam0g-dev libfuse3-dev \
    libsystemd-dev uuid-dev libssl-dev \
    libclang-dev libjson-perl libcurl4-openssl-dev \
    dh-exec

WORKDIR /src

ENV PATH=/root/.cargo/bin:$PATH
ENV PATH=/root/bin:$PATH

# Install PVE eslint (as it is dev dependency)
RUN git clone git://git.proxmox.com/git/pve-eslint.git
RUN apt-get -y build-dep $PWD/pve-eslint
RUN cd pve-eslint/ && make dinstall

# Clone ALL
RUN git clone git://git.proxmox.com/git/proxmox-backup.git
RUN git clone git://git.proxmox.com/git/proxmox.git
RUN git clone git://git.proxmox.com/git/proxmox-fuse.git
RUN git clone git://git.proxmox.com/git/pxar.git
RUN git clone git://git.proxmox.com/git/proxmox-mini-journalreader.git
RUN git clone git://git.proxmox.com/git/proxmox-widget-toolkit.git
RUN git clone git://git.proxmox.com/git/extjs.git
RUN git clone git://git.proxmox.com/git/proxmox-i18n.git
RUN git clone git://git.proxmox.com/git/pve-xtermjs.git

ARG GIT_PROXMOX_BACKUP_VERSION=master
ARG GIT_PROXMOX_VERSION=master

RUN git -C proxmox-backup checkout -b ${GIT_PROXMOX_BACKUP_VERSION}
RUN git -C proxmox checkout -b ${GIT_PROXMOX_VERSION}

# Patch ALL
ADD /patches/ /patches/
RUN patch -p1 -d proxmox/ < /patches/proxmox-${GIT_PROXMOX_VERSION}.patch
RUN patch -p1 -d proxmox-backup/ < /patches/proxmox-backup-${GIT_PROXMOX_BACKUP_VERSION}.patch
RUN patch -p1 -d pve-xtermjs/ < /patches/pve-xtermjs.patch
RUN patch -p1 -d proxmox-mini-journalreader/ < /patches/proxmox-mini-journalreader.patch

# Deps for all rest
RUN apt-get -y build-dep $PWD/proxmox-backup
RUN apt-get -y build-dep $PWD/proxmox-mini-journalreader
RUN apt-get -y build-dep $PWD/extjs
RUN apt-get -y build-dep $PWD/proxmox-widget-toolkit
RUN apt-get -y build-dep $PWD/proxmox-i18n
RUN apt-get -y build-dep $PWD/pve-xtermjs

# Compile ALL
RUN cd proxmox-backup/ && dpkg-buildpackage -us -uc -b
RUN cd extjs/ && make deb && mv *.deb ../
RUN cd proxmox-widget-toolkit/ && make deb && mv *.deb ../
RUN cd proxmox-i18n/ && make deb && mv *.deb ../
RUN cd pve-xtermjs/ && dpkg-buildpackage -us -uc -b
RUN cd proxmox-mini-journalreader/ && make deb && mv *.deb ../

#=================================

FROM debian:bullseye
COPY --from=builder /src/*.deb /src/

# Install all packages
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update -y && \
  apt-get install -y runit && \
  apt install -y /src/*.deb

# Add default configs
ADD /pbs/ /etc/proxmox-backup/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD runit/ /runit/
CMD ["runsvdir", "/runit"]
