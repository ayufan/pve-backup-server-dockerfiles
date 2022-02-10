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
    dh-exec wget

RUN wget https://static.rust-lang.org/rustup/rustup-init.sh && \
  chmod +x rustup-init.sh && \
  ./rustup-init.sh -y --default-toolchain nightly

WORKDIR /src

RUN /usr/bin/rustc --version
RUN /root/.cargo/bin/rustc --version
RUN git config --global user.email "docker@compile.dev" && \
  git config --global user.name "Docker Compile"

# Clone all sources
ARG VERSION=master
ADD /versions/${VERSION}/ /patches/
RUN /patches/clone.bash

# Apply all patches
ADD /scripts/ /scripts/
RUN /scripts/apply-patches.bash /patches/server/*.patch
RUN /scripts/strip-cargo.bash

# A first required dep
RUN apt-get -y build-dep $PWD/pve-eslint
RUN cd pve-eslint/ && make dinstall

# Install dev dependencies of widget toolkit
RUN apt-get -y build-dep $PWD/proxmox-widget-toolkit
RUN cd proxmox-widget-toolkit/ && make deb && dpkg -i proxmox-widget-toolkit-dev*.deb && mv *.deb ../

# Deps for all rest
RUN apt-get -y build-dep $PWD/proxmox-backup
RUN apt-get -y build-dep $PWD/proxmox-mini-journalreader
RUN apt-get -y build-dep $PWD/extjs
RUN apt-get -y build-dep $PWD/proxmox-i18n
RUN apt-get -y build-dep $PWD/pve-xtermjs
RUN apt-get -y build-dep $PWD/libjs-qrcodejs
RUN apt-get -y build-dep $PWD/proxmox-acme

# Compile ALL
RUN . /root/.cargo/env && cd proxmox-backup/ && dpkg-buildpackage -us -uc -b
RUN cd extjs/ && make deb && mv *.deb ../
RUN cd proxmox-i18n/ && make deb && mv *.deb ../
RUN ln -sf /bin/true /usr/share/cargo/bin/dh-cargo-built-using # license is fine (but due to how we compile it, help dpkg for xtermjs)
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
ADD /pbs/ /etc/proxmox-backup-default/

VOLUME /etc/proxmox-backup
VOLUME /var/log/proxmox-backup
VOLUME /var/lib/proxmox-backup

ADD runit/ /runit/
CMD ["runsvdir", "/runit"]
