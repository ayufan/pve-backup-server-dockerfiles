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
ADD /patches/ /patches/

ENV PATH=/root/.cargo/bin:$PATH
ENV PATH=/root/bin:$PATH

# Clone ALL
RUN git clone git://git.proxmox.com/git/pve-eslint.git
RUN git clone git://git.proxmox.com/git/proxmox-backup.git
RUN git clone git://git.proxmox.com/git/proxmox.git
RUN git clone git://git.proxmox.com/git/proxmox-fuse.git
RUN git clone git://git.proxmox.com/git/pxar.git
RUN git clone git://git.proxmox.com/git/proxmox-mini-journalreader.git
RUN git clone git://git.proxmox.com/git/proxmox-widget-toolkit.git
RUN git clone git://git.proxmox.com/git/extjs.git
RUN git clone git://git.proxmox.com/git/proxmox-i18n.git
RUN git clone git://git.proxmox.com/git/pve-xtermjs.git

# Patch ALL
RUN patch -p1 -d proxmox-backup/ < /patches/proxmox-backup.patch
RUN patch -p1 -d pve-xtermjs/ < /patches/pve-xtermjs.patch
RUN patch -p1 -d proxmox-mini-journalreader/ < /patches/proxmox-mini-journalreader.patch

# Install PVE eslint (as it is dev dependency)
RUN apt-get -y build-dep $PWD/pve-eslint
RUN cd pve-eslint/ && make dinstall

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
