BUILD_ARCHS = amd64 arm64v8
CLIENT_BUILD_ARCHS = amd64 arm64v8
REGISTRY ?= ayufan/proxmox-backup-server
VERSION ?= $(shell ls versions | grep -E -v '.(tmp|debug)' | sort -V | tail -n 1)

TAG ?= $(VERSION)

ifneq (,$(wildcard .env.mk))
include .env.mk
endif

# Architectures

arm32v7-%: DOCKER_ARCH=arm32v7
arm64v8-%: DOCKER_ARCH=arm64v8
amd64-%: DOCKER_ARCH=amd64
dev-%: DOCKER_ARCH=amd64

# Docker Images

%-docker-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$(DOCKER_ARCH)/ \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile \
		.

docker-build: $(addsuffix -docker-build, $(BUILD_ARCHS))

# Docker Hub Images

%-dockerhub: %-docker-build
	docker push $(REGISTRY):$(TAG)-$*

%-dockerhub-pull:
	docker pull $(REGISTRY):$(TAG)-$*

dockerhub-manifest: $(addsuffix -dockerhub-pull, $(BUILD_ARCHS))
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):$(TAG) \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):$(TAG)

dockerhub: $(addsuffix -dockerhub, $(BUILD_ARCHS))
	make dockerhub-manifest

%-dockerhub-latest-release: %-dockerhub-pull
	docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):latest-$*
	docker push $(REGISTRY):latest-$*

dockerhub-latest-release: $(addsuffix -dockerhub-latest-release, $(BUILD_ARCHS))
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	docker manifest create $(REGISTRY):latest \
		$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS))
	docker manifest push $(REGISTRY):latest

# Client Binaries

%-client:
	docker build \
		--tag $(REGISTRY):$(TAG)-client-$* \
		--build-arg DOCKER_ARCH=$(DOCKER_ARCH) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f Dockerfile.client \
		.

	mkdir -p release/$(TAG)
	docker run --rm $(REGISTRY):$(TAG)-client-$* sh -c 'cat /proxmox-backup-client*.tgz' > release/$(TAG)/proxmox-backup-client-$(VERSION)-$*.tgz

client: $(addsuffix -client, $(CLIENT_BUILD_ARCHS))

# Debian Packages

%-deb: %-dockerhub-pull
	mkdir -p release/$(TAG)
	-docker rm -f proxmox-backup-$(TAG)-$*
	docker create --name=proxmox-backup-$(TAG)-$* $(REGISTRY):$(TAG)-$*
	docker cp proxmox-backup-$(TAG)-$*:/src/. release/$(TAG)/$*
	-docker rm -f proxmox-backup-$(TAG)-$*

deb: $(addsuffix -deb, $(BUILD_ARCHS))

# Development Helpers

tmp-env:
	mkdir -p "tmp/$(VERSION)"
	cd "tmp/$(VERSION)" && ../../versions/$(VERSION)/clone.bash
	cd "tmp/$(VERSION)" && ../../scripts/apply-patches.bash ../../versions/$(VERSION)/server/*.patch
	cd "tmp/$(VERSION)" && ../../scripts/strip-cargo.bash

tmp-env-client:
	mkdir -p "tmp/$(VERSION)-client"
	cd "tmp/$(VERSION)-client" && ../../versions/$(VERSION)/clone.bash
	cd "tmp/$(VERSION)-client" && ../../scripts/apply-patches.bash ../../versions/$(VERSION)/server/*.patch ./../versions/$(VERSION)/client*/*.patch
	cd "tmp/$(VERSION)-client" && ../../scripts/strip-cargo.bash

dev-run: dev-docker-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup --net=host --rm $(REGISTRY):$(TAG)-dev

dev-shell: dev-docker-build
	-docker rm -f proxmox-backup
	docker run --name=proxmox-backup -it --rm $(REGISTRY):$(TAG)-dev /bin/bash

# Version management

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

release: dockerhub client deb

# GitHub Releases

export GITHUB_USER ?= ayufan
export GITHUB_REPO ?= pve-backup-server-dockerfiles

github-upload-all:
	@set -e; for file in release/$(TAG)/*.tgz release/$(TAG)/*/*.deb; do \
		echo "Uploading $$file..."; \
		github-release upload -t $(TAG) -R -n $$(basename $$file) -f $$file; \
	done

github-pre-release:
	rm -rf release/$(TAG)
	make release
	github-release --version || go get github.com/github-release/github-release
	git push
	github-release info -t $(TAG) || github-release release -t $(TAG) --draft --description "$$(cat RELEASE.md)"
	make github-upload-all
	github-release edit -t $(TAG) --pre-release --description "$$(cat RELEASE.md)"

github-latest-release:
	github-release edit -t $(TAG) --description "$$(cat RELEASE.md)"
	make dockerhub-latest-release
