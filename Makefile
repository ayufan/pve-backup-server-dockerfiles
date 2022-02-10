BUILD_ARCHS = amd64 arm64v8
CLIENT_BUILD_ARCHS = amd64 arm64v8 arm32v7
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= $(shell ls versions | grep -E -v '.(tmp|debug)' | sort -V | tail -n 1)

TAG ?= $(VERSION)

.PHONY: dev-run dev-shell all-deb all-build all-push all-client

ifneq (,$(wildcard .env.mk))
include .env.mk
endif

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
arm32v7-client: DOCKERFILE=Dockerfile.client

arm64v8-client: DOCKER_ARCH=arm64v8
arm64v8-client: DOCKERFILE=Dockerfile.client

amd64-client: DOCKER_ARCH=amd64
amd64-client: DOCKERFILE=Dockerfile.client

%-client:
	docker build \
		--tag $(REGISTRY):$(TAG)-client-$* \
		--build-arg DOCKER_ARCH=$(DOCKER_ARCH) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f $(DOCKERFILE) \
		.

	mkdir -p release/$(TAG)
	docker run --rm $(REGISTRY):$(TAG)-client-$* sh -c 'cat /proxmox-backup-client*.tgz' > release/$(TAG)/proxmox-backup-client-$(VERSION)-$*.tgz

%-push: %-build
	docker push $(REGISTRY):$(TAG)-$*

%-pull:
	docker pull $(REGISTRY):$(TAG)-$*

all-client: $(addsuffix -client, $(CLIENT_BUILD_ARCHS))

all-build: $(addsuffix -build, $(BUILD_ARCHS))

all-push: $(addsuffix -push, $(BUILD_ARCHS))
	make all-manifest

all-manifest: $(addsuffix -pull, $(BUILD_ARCHS))
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):$(TAG)

%-latest: %-pull
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
	mkdir -p release/$(TAG)
	-docker rm -f proxmox-backup-$(TAG)-$*
	docker create --name=proxmox-backup-$(TAG)-$* $(REGISTRY):$(TAG)-$*
	docker cp proxmox-backup-$(TAG)-$*:/src/. release/$(TAG)/$*
	-docker rm -f proxmox-backup-$(TAG)-$*

all-deb: $(addsuffix -deb, $(BUILD_ARCHS))

all-release: all-deb all-client

fork-version:
ifndef NEW_VERSION
	@echo "Missing 'make fork-version NEW_VERSION=...'"
	@exit 1
endif

	rm -rf "versions/v$(NEW_VERSION).tmp"
	cp -rv "versions/$(VERSION)" "versions/v$(NEW_VERSION).tmp"
	"versions/v$(NEW_VERSION).tmp/clone.bash" show-sha $(firstword $(NEW_SHA) $(NEW_VERSION)) > "versions/v$(NEW_VERSION).tmp/versions.tmp"
	mv "versions/v$(NEW_VERSION).tmp/versions.tmp" "versions/v$(NEW_VERSION).tmp/versions"
	mv "versions/v$(NEW_VERSION).tmp" "versions/v$(NEW_VERSION)"

tmp-env:
	mkdir -p "tmp/$(VERSION)"
	cd "tmp/$(VERSION)" && ../../versions/$(VERSION)/clone.bash
	cd "tmp/$(VERSION)" && ../../scripts/apply-patches.bash ../../versions/$(VERSION)/server/*.patch ../../versions/$(VERSION)/client*/*.patch
	cd "tmp/$(VERSION)" && ../../scripts/strip-cargo.bash

# GitHub Releases

export GITHUB_USER ?= ayufan
export GITHUB_REPO ?= pve-backup-server-dockerfiles

github-upload-all:
	@set -e; for file in release/$(TAG)/*.tgz release/$(TAG)/*/*.deb; do \
		echo "Uploading $$file..."; \
		github-release upload -t $(TAG) -R -n $$(basename $$file) -f $$file; \
	done

github-pre-release: all-release all-push
	go get github.com/github-release/github-release
	git push
	github-release info -t $(TAG) || github-release release -t $(TAG) --draft
	make github-upload-all
	github-release edit -t $(TAG) --pre-release

github-latest-release:
	github-release edit -t $(TAG)
	make all-latest
