ARCHS = arm32v7 arm64v8 amd64
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= master

VARIANT ?=
TAG ?= $(VERSION)$(VARIANT)
ifeq (1,$(LATEST))
LATEST_TAG ?= latest$(VARIANT)
endif
DEV_IMAGE ?= $(REGISTRY):$(TAG)-dev
LATEST ?= 0

.PHONY: dev-build dev-push dev-run dev-shell

%-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$*/ \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile$(VARIANT) \
		.
ifneq (,$(LATEST_TAG))
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):$(LATEST_TAG)-$*
endif

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

dev-build:
	docker build \
		--tag $(DEV_IMAGE) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile$(VARIANT) \
		.

dev-push: dev-build
	docker push $(DEV_IMAGE)

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host -it --rm $(DEV_IMAGE)

dev-shell: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(DEV_IMAGE) /bin/bash
