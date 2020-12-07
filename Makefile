ARCHS = arm64v8 amd64
REGISTRY ?= ayufan/proxmox-backup-server
TAG ?= latest
DEV_IMAGE ?= $(REGISTRY):$(TAG)-dev

.PHONY: dev-build dev-push dev-run dev-shell

%-build:
	docker build -t $(REGISTRY):$(TAG)-$* --build-arg ARCH=$*/ .

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*

manifest:
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	docker manifest create --amend $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(ARCHS))
	docker push $(REGISTRY):$(TAG)

dev-build:
	docker build -t $(DEV_IMAGE) .

dev-push: dev-build
	docker push $(DEV_IMAGE)

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host -it --rm $(DEV_IMAGE)

dev-shell: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(DEV_IMAGE) /bin/bash
