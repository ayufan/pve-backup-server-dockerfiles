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

ENV RUSTUP_TOOLCHAIN=stable
RUN wget https://static.rust-lang.org/rustup/rustup-init.sh && \
  chmod +x rustup-init.sh && \
  ./rustup-init.sh -y --default-toolchain "$RUSTUP_TOOLCHAIN"

WORKDIR /src

RUN for tool in /root/.cargo/bin/*; do ln -vsf $tool /usr/bin/; done
RUN /usr/bin/rustc --version
RUN git config --global user.email "docker@compile.dev" && \
  git config --global user.name "Docker Compile"

FROM toolchain as builder

# Clone all sources
ADD /scripts/ /scripts/
ADD /repos/versions /repos/
RUN /scripts/git-clone.bash /repos/versions

# Apply all patches
ADD /repos/patches/ /repos/patches/
RUN /scripts/apply-patches.bash /repos/patches/
RUN /scripts/strip-cargo.bash
RUN /scripts/resolve-dependencies.bash

# A first required dep
RUN apt-get -y build-dep $PWD/pve-eslint
RUN make -C pve-eslint dinstall

# A proxmox-perl-rs required deps
RUN apt-get -y build-dep $PWD/perlmod/perlmod $PWD/perlmod/perlmod-bin $PWD/perlmod/perlmod-macro
RUN cd perlmod/perlmod-bin && dpkg-buildpackage -us -uc -b && dpkg -i ../perlmod-bin*.deb

# A pve-common required deps
RUN apt-get -y build-dep $PWD/proxmox-perl-rs/pve-rs
RUN make -C proxmox-perl-rs/common/pkg deb install
RUN make -C proxmox-perl-rs/pve-rs deb
RUN dpkg -i proxmox-perl-rs/common/pkg/*.deb proxmox-perl-rs/pve-rs/*.deb
RUN apt-get -y build-dep $PWD/pve-common
RUN make -C pve-common dinstall || apt-get -f -y install && make -C pve-common dinstall

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
RUN make -C proxmox-backup deb
RUN make -C extjs deb
RUN make -C proxmox-i18n deb
RUN make -C pve-xtermjs/termproxy deb
RUN make -C pve-xtermjs/xterm.js deb
RUN make -C proxmox-mini-journalreader deb
RUN make -C libjs-qrcodejs deb
RUN make -C proxmox-acme deb

# Copy all debian packages
RUN mkdir -p /deb && \
  find /src/ -name '*.deb' -exec cp -av {} /deb/ \;

#=================================

FROM ${ARCH}debian:bookworm
COPY --from=builder /deb/ /deb/
RUN mkdir -p /deb/static && \
  mv /deb/proxmox-backup-client-static*.deb /deb/static/

# Install all packages
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get -y update && \
  apt install -y runit ssmtp cron /deb/*.deb

# Add default configs
ADD /dockerfiles/pbs/ /etc/proxmox-backup-default/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD /dockerfiles/runit/ /runit/
CMD ["runsvdir", "/runit"]
