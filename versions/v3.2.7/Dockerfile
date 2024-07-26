ARG ARCH=
FROM ${ARCH}debian:bookworm AS toolchain

RUN apt-get -y update && \
  apt-get -y install \
    build-essential git-core \
    lintian pkg-config quilt patch cargo \
    nodejs node-colors node-commander \
    libudev-dev libapt-pkg-dev \
    libacl1-dev libpam0g-dev libfuse3-dev \
    libsystemd-dev uuid-dev libssl-dev \
    libclang-dev libjson-perl libcurl4-openssl-dev \
    dh-exec dh-nodejs wget

RUN wget https://static.rust-lang.org/rustup/rustup-init.sh && \
  chmod +x rustup-init.sh && \
  ./rustup-init.sh -y --default-toolchain stable

ENV RUSTUP_TOOLCHAIN=stable

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

# A proxmox-perl-rs required deps
RUN apt-get -y build-dep $PWD/perlmod/perlmod $PWD/perlmod/perlmod-bin $PWD/perlmod/perlmod-macro
RUN cd perlmod/perlmod-bin && dpkg-buildpackage -us -uc -b && dpkg -i ../perlmod-bin*.deb

# A pve-common required deps
RUN apt-get -y build-dep $PWD/proxmox-perl-rs/pve-rs
RUN cd proxmox-perl-rs/pve-rs && make dinstall
RUN cd proxmox-perl-rs/common/pkg && make deb && dpkg -i *.deb
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
RUN apt-get -y build-dep $PWD/pve-xtermjs/termproxy
RUN apt-get -y build-dep $PWD/pve-xtermjs/xterm.js
RUN apt-get -y build-dep $PWD/libjs-qrcodejs

# Compile ALL
RUN cd proxmox-backup/ && make deb
RUN cd extjs/ && make deb
RUN cd proxmox-i18n/ && make deb
RUN cd pve-xtermjs/termproxy/ && make deb
RUN cd pve-xtermjs/xterm.js/ && make deb
RUN cd proxmox-mini-journalreader/ && make deb
RUN cd libjs-qrcodejs/ && make deb
RUN cd proxmox-acme/ && make deb

# Copy all debian packages
RUN mkdir -p /deb && \
  find /src/ -name '*.deb' -exec cp -av {} /deb/ \;

#=================================

FROM ${ARCH}debian:bookworm
COPY --from=builder /deb/ /deb/

# Install all packages
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get -y update && \
  apt install -y runit ssmtp /deb/*.deb

# Add default configs
ADD /pbs/ /etc/proxmox-backup-default/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD runit/ /runit/
CMD ["runsvdir", "/runit"]
