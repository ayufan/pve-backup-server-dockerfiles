ARG ARCH=
FROM ${ARCH}debian:bullseye AS toolchain

RUN echo deb http://deb.debian.org/debian bullseye-backports main >> /etc/apt/sources.list.d/backports.list && \
  apt-get -y update && \
  apt-get -y install \
    build-essential git-core \
    lintian pkg-config quilt patch cargo \
    node-colors node-commander \
    libudev-dev libapt-pkg-dev \
    libacl1-dev libpam0g-dev libfuse3-dev \
    libsystemd-dev uuid-dev libssl-dev \
    libclang-dev libjson-perl libcurl4-openssl-dev \
    dh-exec wget \
    # workaround security repo woes with dh-nodejs
    dh-nodejs/bullseye-backports pkg-js-tools/bullseye-backports \
    nodejs=12.22.5~dfsg-2~11u1 libnode72=12.22.5~dfsg-2~11u1

RUN wget https://static.rust-lang.org/rustup/rustup-init.sh && \
  chmod +x rustup-init.sh && \
  ./rustup-init.sh -y --default-toolchain nightly

WORKDIR /src

RUN for tool in /root/.cargo/bin/*; do ln -vsf $tool /usr/bin/; done
RUN /usr/bin/rustc --version
RUN git config --global user.email "docker@compile.dev" && \
  git config --global user.name "Docker Compile"

FROM toolchain as builder

# Clone all sources
ARG VERSION=master
ADD /versions/${VERSION}/ /patches/
RUN /patches/clone.bash

# Apply all patches
ADD /scripts/ /scripts/
RUN /scripts/apply-patches.bash /patches/server/*.patch
RUN /scripts/strip-cargo.bash
RUN /scripts/resolve-dependencies.bash

# A first required dep
RUN apt-get -y build-dep $PWD/pve-eslint
RUN cd pve-eslint/ && make dinstall

# A pve-common required deps
RUN apt-get -y build-dep $PWD/proxmox-perl-rs/pve-rs
RUN cd proxmox-perl-rs/ && make pve-rs pve-deb common-deb && dpkg -i build/*.deb
RUN apt-get -y build-dep $PWD/pve-common
RUN cd pve-common/ && ( make dinstall || apt-get -f -y install && make dinstall )

# Install dev dependencies of widget toolkit
RUN apt-get -y build-dep $PWD/proxmox-widget-toolkit
RUN cd proxmox-widget-toolkit/ && make deb && dpkg -i proxmox-widget-toolkit-dev*.deb

# Deps for all rest
RUN apt-get -y build-dep $PWD/proxmox-acme
RUN apt-get -y build-dep $PWD/proxmox-backup
RUN apt-get -y build-dep $PWD/proxmox-mini-journalreader
RUN apt-get -y build-dep $PWD/extjs
RUN apt-get -y build-dep $PWD/proxmox-i18n
RUN apt-get -y build-dep $PWD/pve-xtermjs
RUN apt-get -y build-dep $PWD/libjs-qrcodejs

# Compile ALL
RUN . /root/.cargo/env && cd proxmox-backup/ && DEB_VERSION_UPSTREAM=${VERSION} dpkg-buildpackage -us -uc -b
RUN cd extjs/ && make deb
RUN cd proxmox-i18n/ && make deb
RUN ln -sf /bin/true /usr/share/cargo/bin/dh-cargo-built-using # license is fine (but due to how we compile it, help dpkg for xtermjs)
RUN cd pve-xtermjs/ && dpkg-buildpackage -us -uc -b
RUN cd proxmox-mini-journalreader/ && make deb
RUN cd libjs-qrcodejs/ && make deb
RUN cd proxmox-acme/ && make deb

# Copy all debian packages
RUN mkdir -p /deb && \
  find /src/ -name '*.deb' -exec cp -av {} /deb/ \;

#=================================

FROM ${ARCH}debian:bullseye
COPY --from=builder /deb/ /deb/

# Install all packages
RUN export DEBIAN_FRONTEND=noninteractive && \
  echo deb http://deb.debian.org/debian bullseye-backports main >> /etc/apt/sources.list.d/backports.list && \
  apt-get -y update && \
  apt install -y runit ssmtp /deb/*.deb

# Add default configs
ADD /pbs/ /etc/proxmox-backup-default/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD runit/ /runit/
CMD ["runsvdir", "/runit"]
