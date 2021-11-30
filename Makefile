BUILD_ARCHS = amd64 arm64v8
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= $(shell ls versions | grep -E -v '.(tmp|debug)' | sort -V | tail -n 1)

TAG ?= $(VERSION)

.PHONY: dev-run dev-shell all-deb all-build all-push

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

arm32v7-client: DOCKER_ARCH=arm32v7
arm32v7-client: DOCKERFILE=Dockerfile.client-buster

arm64v8-client: DOCKER_ARCH=arm64v8
arm64v8-client: DOCKERFILE=Dockerfile.client-buster

amd64-client: DOCKER_ARCH=amd64
amd64-client: DOCKERFILE=Dockerfile.client-buster

%-client:
	docker build \
		--tag $(REGISTRY):$(TAG)-client-$* \
		--build-arg DOCKER_ARCH=$(DOCKER_ARCH) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f $(DOCKERFILE) \
		.

	docker run --rm $(REGISTRY):$(TAG)-client-$* sh -c 'cat /proxmox-backup-client*.tgz' > proxmox-backup-client-$(VERSION)-$*.tgz

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*

all-build: $(addsuffix -build, $(BUILD_ARCHS))

all-push: $(addsuffix -push, $(BUILD_ARCHS))
	make all-manifest

all-manifest:
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):$(TAG)

%-latest:
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):latest-$*
	docker push $(REGISTRY):latest-$*

all-latest: $(addsuffix -latest, $(BUILD_ARCHS))
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):latest \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):latest

dev-run: dev-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host --rm $(REGISTRY):$(TAG)-dev

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

fork-version:
ifndef NEW_VERSION
	@echo "Missing 'make fork-version NEW_VERSION=...'"
	@exit 1
endif

	rm -rf "versions/v$(NEW_VERSION).tmp"
	cp -rv "versions/$(VERSION)" "versions/v$(NEW_VERSION).tmp"
	"versions/v$(NEW_VERSION).tmp/clone.bash" show-sha $(NEW_VERSION) > "versions/v$(NEW_VERSION).tmp/versions.tmp"
	mv "versions/v$(NEW_VERSION).tmp/versions.tmp" "versions/v$(NEW_VERSION).tmp/versions"
	mv "versions/v$(NEW_VERSION).tmp" "versions/v$(NEW_VERSION)"

tmp-env:
	mkdir -p "tmp/$(VERSION)"
	cd "tmp/$(VERSION)" && ../../versions/$(VERSION)/clone.bash
	cd "tmp/$(VERSION)" && ../../scripts/apply-patches.bash ../../versions/$(VERSION)/server/*.patch
	cd "tmp/$(VERSION)" && ../../scripts/strip-cargo.bash
