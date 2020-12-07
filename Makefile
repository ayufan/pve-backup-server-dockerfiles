ARCHS = arm64v8 amd64
REGISTRY ?= ayufan/proxmox-backup-server
DEV_IMAGE ?= $(REGISTRY):latest-dev

.PHONY: dev-build dev-push dev-run dev-shell

%-build:
	docker build -t $(REGISTRY):latest-$* --build-arg ARCH=$*/ .

%-push: %-build
	docker push $(REGISTRY):latest-$*

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
