BUILD_ARCHS = amd64 arm64v8
CLIENT_BUILD_ARCHS = amd64 arm64v8
REGISTRY ?= ayufan/proxmox-backup-server
SHELL = /usr/bin/env bash
include repos/version.mk

ifeq (,$(TAG))
TAG := $(VERSION)
endif

LATEST_TAGS := $(basename $(TAG)) latest
LATEST_TAGS += $(basename $(LATEST_TAGS))
LATEST_TAGS += $(basename $(LATEST_TAGS))
LATEST_TAGS := $(sort $(LATEST_TAGS))

ifneq (,$(wildcard .env.mk))
include .env.mk
endif

define newline


endef

# Architectures

arm32v7-%: DOCKER_ARCH=arm32v7
arm64v8-%: DOCKER_ARCH=arm64v8
amd64-%: DOCKER_ARCH=amd64
dev-%:

# Docker Images

%-docker-build:
	docker build \
		--tag $(REGISTRY):$(TAG)-$* \
		--build-arg ARCH=$(addsuffix /,$(DOCKER_ARCH)) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f dockerfiles/Dockerfile \
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
	$(foreach latest_tag,$(LATEST_TAGS), \
		docker tag $(REGISTRY):$(TAG)-$* $(REGISTRY):$(latest_tag)-$* $(newline) \
		docker push $(REGISTRY):$(latest_tag)-$* $(newline) \
	)

dockerhub-latest-release: $(addsuffix -dockerhub-latest-release, $(BUILD_ARCHS))
	# This requires `echo '{"experimental":"enabled"}' > ~/.docker/config.json`
	-rm -rf ~/.docker/manifests
	$(foreach latest_tag,$(LATEST_TAGS), \
		docker manifest create $(REGISTRY):$(latest_tag) \
			$(addprefix $(REGISTRY):$(TAG)-, $(BUILD_ARCHS)) $(newline) \
		docker manifest push $(REGISTRY):$(latest_tag) $(newline) \
	)

# Client Binaries

%-client:
	docker build \
		--tag $(REGISTRY):$(TAG)-client-$* \
		--build-arg DOCKER_ARCH=$(DOCKER_ARCH) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		-f dockerfiles/Dockerfile.client \
		.

	mkdir -p release/$(TAG)
	docker run --rm $(REGISTRY):$(TAG)-client-$* sh -c 'cat /proxmox-backup-client*.tgz' > release/$(TAG)/proxmox-backup-client-$(VERSION)-$*.tgz

client: $(addsuffix -client, $(CLIENT_BUILD_ARCHS))

# Debian Packages

%-deb: %-dockerhub-pull
	mkdir -p release/$(TAG)
	-docker rm -f proxmox-backup-$(TAG)-$*
	docker create --name=proxmox-backup-$(TAG)-$* $(REGISTRY):$(TAG)-$*
	docker cp proxmox-backup-$(TAG)-$*:/deb/. release/$(TAG)/$*
	-docker rm -f proxmox-backup-$(TAG)-$*

deb: $(addsuffix -deb, $(BUILD_ARCHS))

# Development Helpers

tmp-env:
	mkdir -p build
	cd build && ../../scripts/git-clone.bash ../../repos/versions
	cd build && ../../scripts/apply-patches.bash ../../repos/patches/
	cd build && ../../scripts/strip-cargo.bash
	cd build && ../../scripts/resolve-dependencies.bash

tmp-env-client: tmp-env
	cd build && ../../scripts/apply-patches.bash ../../repos/patches-client*/

tmp-docker-shell:
	docker build \
		--tag tmp-docker-shell \
		--build-arg ARCH=$(addsuffix /,$(DOCKER_ARCH)) \
		--build-arg TAG=$(TAG) \
		--build-arg VERSION=$(VERSION) \
		--target toolchain \
		-f dockerfiles/Dockerfile \
		.
	docker run --name=tmp-docker-shell --net=host --rm -it \
		-v "$(CURDIR):$(CURDIR)" \
		-w "$(CURDIR)/build" \
		tmp-docker-shell

dev-run: dev-docker-build
	-docker-compose rm -s -f -v
	TAG=$(TAG)-dev docker-compose up

dev-shell: dev-docker-build
	TAG=$(TAG)-dev docker-compose run --rm pbs bash

# Release Helpers

release: dockerhub client deb

# GitHub Releases

export GITHUB_USER ?= ayufan
export GITHUB_REPO ?= pve-backup-server-dockerfiles
GITHUB_RELEASE_BIN ?= go run github.com/github-release/github-release@latest

github-create-draft:
	$(GITHUB_RELEASE_BIN) info -t $(TAG) || $(GITHUB_RELEASE_BIN) release -t $(TAG) --draft --description "$$(cat RELEASE.md)"

github-upload-all:
	@set -e; shopt -s nullglob; for file in release/$(TAG)/*.tgz release/$(TAG)/*/*.deb; do \
		echo "Uploading $$file..."; \
		$(GITHUB_RELEASE_BIN) upload -t $(TAG) -R -n $$(basename $$file) -f $$file; \
	done

github-create-pre-release:
	$(GITHUB_RELEASE_BIN) edit -t $(TAG) --pre-release --description "$$(cat RELEASE.md)"

github-pre-release:
	rm -rf release/$(TAG)
	make release
	git push
	make github-create-draft
	make github-upload-all
	make github-create-pre-release

github-latest-release:
	make dockerhub-latest-release
	$(GITHUB_RELEASE_BIN) edit -t $(TAG) --description "$$(cat RELEASE.md)"
