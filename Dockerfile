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
    dh-exec runit

WORKDIR /src
ADD /patches/ /patches/

ENV JOBS=4
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

# Install PVE eslint
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

# mini-journalreader.c: In function 'main':
# mini-journalreader.c:220:61: error: comparison is always true due to limited range of data type [-Werror=type-limits]
#   220 |     while ((c = (char)getopt (argc, argv, "b:e:d:n:f:t:h")) != -1) {
#       |                                                             ^~
# cc1: all warnings being treated as errors
RUN sed -i -e 's/char c;/int c;/g' -e 's/(char)getopt/getopt/g' proxmox-mini-journalreader/src/mini-journalreader.c
RUN cd proxmox-mini-journalreader/ && make deb && mv *.deb ../


FROM debian:bullseye
COPY --from=builder /src/*.deb /src/

# Install all packages
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update -y && \
  apt install -y /src/*.deb

RUN apt-get install -y runit
ADD /pbs/ /etc/proxmox-backup/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD runit/ /runit/
CMD ["runsvdir", "/runit"]
