ARCHS = arm64v8 amd64
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= master

TAG ?= $(VERSION)
DEV_IMAGE ?= $(REGISTRY):$(TAG)-dev
LATEST ?= 0

.PHONY: dev-build dev-push dev-run dev-shell

%-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$*/ \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		.
ifeq (1,$(LATEST))
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):latest-$*
endif

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*
ifeq (1,$(LATEST))
	docker push $(REGISTRY):latest-$*
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

ifeq (1,$(LATEST))
	docker manifest create $(REGISTRY):latest \
		$(addprefix $(REGISTRY):latest-, $(ARCHS))
	docker manifest push $(REGISTRY):latest
endif

dev-build:
	docker build \
		--tag $(DEV_IMAGE) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		.

dev-push: dev-build
	docker push $(DEV_IMAGE)

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host -it --rm $(DEV_IMAGE)

dev-shell: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(DEV_IMAGE) /bin/bash
