ARCHS = amd64 arm32v7 arm64v8
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= master

TAG ?= $(VERSION)
ifeq (1,$(LATEST))
LATEST_TAG ?= latest
endif
LATEST ?= 0

.PHONY: dev-build dev-push dev-run dev-shell

%-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$(filter $*/, $(addsuffix /, $(ARCHS))) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile \
		.
ifneq (,$(LATEST_TAG))
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):$(LATEST_TAG)-$*
endif

%-client:
	docker build \
		--tag $(REGISTRY):$(TAG)-client-$* \
		--build-arg ARCH=$(filter $*/, $(addsuffix /, $(ARCHS))) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile.client \
		.

	docker run --rm $(REGISTRY):$(TAG)-client-$* sh -c 'cat /proxmox-backup-client*.tgz' > proxmox-backup-client-$(VERSION)-$*.tgz

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*
ifneq (,$(LATEST_TAG))
	docker push $(REGISTRY):$(LATEST_TAG)-$*
endif

all-build: $(addsuffix -build, $(ARCHS))

all-push: $(addsuffix -push, $(ARCHS))
	make manifest

manifest:
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(ARCHS))
	docker manifest push $(REGISTRY):$(TAG)

ifneq (,$(LATEST_TAG))
	docker manifest create $(REGISTRY):$(LATEST_TAG) \
		$(addprefix $(REGISTRY):$(LATEST_TAG)-, $(ARCHS))
	docker manifest push $(REGISTRY):$(LATEST_TAG)
endif

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host -it --rm $(REGISTRY):$(TAG)-dev

dev-shell: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(REGISTRY):$(TAG)-dev /bin/bash
