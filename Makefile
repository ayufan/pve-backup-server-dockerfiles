BUILD_ARCHS = amd64 arm64v8
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= master

TAG ?= $(VERSION)
ifeq (1,$(LATEST))
LATEST_TAG ?= latest
endif
LATEST ?= 0

.PHONY: dev-build dev-push dev-run dev-shell

arm32v7-build: DOCKER_ARCH=arm32v7
arm64v8-build: DOCKER_ARCH=arm64v8
amd64-build: DOCKER_ARCH=amd64
dev-build: DOCKER_ARCH=amd64

%-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$(DOCKER_ARCH)/ \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile \
		.
ifneq (,$(LATEST_TAG))
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):$(LATEST_TAG)-$*
endif

arm32v7-client: DOCKER_ARCH=arm32v7
arm32v7-client: MUSL_ARCH=arm-linux-musleabihf
arm32v7-client: RUST_ARCH=arm-unknown-linux-musleabihf
arm32v7-client: DOCKERFILE=Dockerfile.client-cross

arm64v8-client: DOCKER_ARCH=arm64v8
arm64v8-client: MUSL_ARCH=aarch64-linux-musl
arm64v8-client: RUST_ARCH=aarch64-unknown-linux-musl
arm64v8-client: DOCKERFILE=Dockerfile.client-alpine

amd64-client: DOCKER_ARCH=amd64
amd64-client: MUSL_ARCH=x86_64-linux-musl
amd64-client: RUST_ARCH=x86_64-unknown-linux-musl
amd64-client: DOCKERFILE=Dockerfile.client-alpine

%-client:
	docker build \
		--tag $(REGISTRY):$(TAG)-client-$* \
		--build-arg DOCKER_ARCH=$(DOCKER_ARCH) \
		--build-arg RUST_ARCH=$(RUST_ARCH) \
		--build-arg MUSL_ARCH=$(MUSL_ARCH) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f $(DOCKERFILE) \
		.

	docker run --rm $(REGISTRY):$(TAG)-client-$* sh -c 'cat /proxmox-backup-client*.tgz' > proxmox-backup-client-$(VERSION)-$*.tgz

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*
ifneq (,$(LATEST_TAG))
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):$(LATEST_TAG)-$*
	docker push $(REGISTRY):$(LATEST_TAG)-$*
endif

all-build: $(addsuffix -build, $(BUILD_ARCHS))

all-push: $(addsuffix -push, $(BUILD_ARCHS))
	make manifest

manifest:
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):$(TAG)

ifneq (,$(LATEST_TAG))
	docker manifest create $(REGISTRY):$(LATEST_TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):$(LATEST_TAG)
endif

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host -it --rm $(REGISTRY):$(TAG)-dev

dev-shell: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(REGISTRY):$(TAG)-dev /bin/bash

%-deb:
	mkdir -p deb/$(TAG)
	-docker rm -f proxmox-backup-$(TAG)-$*
	docker create --name=proxmox-backup-$(TAG)-$* $(REGISTRY):$(TAG)-$*
	docker cp proxmox-backup-$(TAG)-$*:/src/ deb/$(TAG)
	-docker rm -f proxmox-backup-$(TAG)-$*

all-deb: $(addsuffix -deb, $(BUILD_ARCHS))
