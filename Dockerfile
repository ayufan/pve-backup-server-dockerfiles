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

# Apply all patches
ARG VERSION=master
ADD /versions/${VERSION}/ /patches/
RUN /patches/clone.bash
RUN set -e; for i in /patches/*.patch; do echo $i... && patch -p1 -d $(basename "$i" .patch) < "$i"; done

# A first required dep
RUN apt-get -y build-dep $PWD/pve-eslint
RUN cd pve-eslint/ && make dinstall

# Deps for all rest
RUN apt-get -y build-dep $PWD/proxmox-backup
RUN apt-get -y build-dep $PWD/proxmox-mini-journalreader
RUN apt-get -y build-dep $PWD/extjs
RUN apt-get -y build-dep $PWD/proxmox-widget-toolkit
RUN apt-get -y build-dep $PWD/proxmox-i18n
RUN apt-get -y build-dep $PWD/pve-xtermjs
RUN apt-get -y build-dep $PWD/libjs-qrcodejs
RUN apt-get -y build-dep $PWD/proxmox-acme

# Compile ALL
RUN cd proxmox-backup/ && dpkg-buildpackage -us -uc -b
RUN cd extjs/ && make deb && mv *.deb ../
RUN cd proxmox-widget-toolkit/ && make deb && mv *.deb ../
RUN cd proxmox-i18n/ && make deb && mv *.deb ../
RUN cd pve-xtermjs/ && dpkg-buildpackage -us -uc -b
RUN cd proxmox-mini-journalreader/ && make deb && mv *.deb ../
RUN cd libjs-qrcodejs/ && make deb && mv *.deb ../
RUN export DEB_BUILD_OPTIONS=nocheck && cd proxmox-acme/ && make deb && rm libproxmox-acme-perl* && mv *.deb ../

#=================================

FROM ${ARCH}debian:bullseye
COPY --from=builder /src/*.deb /src/

# Install all packages
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update -y && \
  apt install -y runit /src/*.deb

# Add default configs
ADD /pbs/ /etc/proxmox-backup/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD runit/ /runit/
CMD ["runsvdir", "/runit"]
