#!/bin/bash

if [[ $# -le 1 ]]; then
  echo "$0: usage <tag> [build] [release]"
  exit 1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/"

IMAGE_TAG="$1"
shift

set -xeo pipefail

ARCHS="arm64 amd64"
VERSION="${VERSION:-$(cat VERSION)}"

if [[ -z "$ARCH" ]]; then
  case "$(dpkg --print-architecture)" in
    arm64) ARCH="arm64" ;;
    amd64) ARCH="amd64" ;;
    *) echo "Unsupported architecture: $(dpkg --print-architecture)"; exit 1 ;;
  esac
fi

case "$ARCH" in
  arm64)
    IMAGE_PREFIX="arm64v8/"
    TARGET_PLATFORM="linux/arm64/v8"
    CROSS_ARCH=""
    ;;
  amd64)
    IMAGE_PREFIX="amd64/"
    TARGET_PLATFORM="linux/amd64"
    CROSS_ARCH=""
    ;;
  arm32)
    IMAGE_PREFIX="arm64v8/"
    TARGET_PLATFORM="linux/arm64/v8"
    CROSS_ARCH="arm32"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

RELEASE_IMAGE_TAG="$IMAGE_TAG-${CROSS_ARCH:-$ARCH}"
BUILD_IMAGE_TAG="$IMAGE_TAG-build-${CROSS_ARCH:-$ARCH}"
DEB_IMAGE_TAG="$IMAGE_TAG-deb-${CROSS_ARCH:-$ARCH}"
CLIENT_IMAGE_TAG="$IMAGE_TAG-client-${CROSS_ARCH:-$ARCH}"

docker_build() {
  docker build \
    --build-arg=ARCH="$ARCH" \
    --build-arg=CROSS_ARCH="$CROSS_ARCH" \
    --build-arg=VERSION="$VERSION" \
    --build-arg=TAG="$TAG" \
    --build-arg=IMAGE_PREFIX="$IMAGE_PREFIX" \
    --platform="$TARGET_PLATFORM" \
    "$@"
}

for i; do
  case "$i" in
    build-deb)
      docker_build --file=dockerfiles/Dockerfile.build --target="deb_env" --tag="$DEB_IMAGE_TAG" "."
      docker run --rm -v "$PWD":/dest "$DEB_IMAGE_TAG" sh -c 'cp -rv /release /dest'
      ;;

    build-tgz)
      docker_build --file=dockerfiles/Dockerfile.build --target="deb_env" --tag="$DEB_IMAGE_TAG" "."
      mkdir -p release/
      docker run --rm -v "$PWD":/dest "$DEB_IMAGE_TAG" sh -c 'cp -rv /*.tgz /dest/release/'
      ;;

    build-image)
      docker_build --file=dockerfiles/Dockerfile.build --target="release_env" --tag="$RELEASE_IMAGE_TAG" "."
      ;;

    client-tgz)
      docker_build --file=dockerfiles/Dockerfile.client --tag="$CLIENT_IMAGE_TAG" "."
      mkdir -p release/
      docker run --rm -v "$PWD":/dest "$CLIENT_IMAGE_TAG" sh -c 'cp -rv /*.tgz /dest/release/'
      ;;

    push-image)
      docker push "$RELEASE_IMAGE_TAG"
      ;;

    manifest)
      MANIFEST_ARCHS=""
      for i in $ARCHS; do
        if docker manifest inspect "$IMAGE_TAG-$i" &>/dev/null; then
          MANIFEST_ARCHS="$MANIFEST_ARCHS $IMAGE_TAG-$i"
        else
          echo "Manifest for $IMAGE_TAG-$i does not exist, skipping."
        fi
      done

      manifest_names() {
        local repo="${1%%:*}"
        local version="${1##*:}"
        shift

        echo "$repo:$version"
  
        for tag; do
          if [[ "$tag" == "semver" ]]; then
            while [[ "$version" == *[.-]* ]]; do
              version="${version%[.-]*}"
              echo "$repo:$version"
            done
          else
            echo "$repo:$tag"
          fi
        done
      }

      shift

      for i in $(manifest_names "$IMAGE_TAG" "$@"); do
        docker manifest create "$i" $MANIFEST_ARCHS
        docker manifest push "$i"
      done

      # This is last command, as it consumes all arguments
      break
      ;;

    *)
      echo "Unsure what to do with '$1'."
      exit 1
      ;;
  esac
done
