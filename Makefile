ARCHS = arm64v8 amd64
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= master
TAG ?= $(VERSION)
DEV_IMAGE ?= $(REGISTRY):$(TAG)-dev

.PHONY: dev-build dev-push dev-run dev-shell

%-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$*/ \
		--build-arg PROXMOX_BACKUP_VERSION=$(VERSION) \
		.

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*

manifest:
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	docker manifest create --amend $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(ARCHS))
	docker push $(REGISTRY):$(TAG)

ifneq (master,$(VERSION))
	docker tag $(REGISTRY):$(TAG) $(REGISTRY):latest
	docker push $(REGISTRY):latest
endif

dev-build:
	docker build \
		--tag $(DEV_IMAGE) \
		--build-arg PROXMOX_BACKUP_VERSION=$(VERSION) \
		.

dev-push: dev-build
	docker push $(DEV_IMAGE)

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host -it --rm $(DEV_IMAGE)

dev-shell: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(DEV_IMAGE) /bin/bash
