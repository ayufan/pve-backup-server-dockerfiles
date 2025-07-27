#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/"

set -eo pipefail

TAG=pve-backup-build-env
TARGET=build

IMAGE="$TAG"
NAME="$IMAGE-run"

if ! docker inspect "$IMAGE" &>/dev/null; then
  echo ">> Building..."
  docker build -f "dockerfiles/Dockerfile.build" -t "$TAG" --target toolchain "."
  IMAGE="$TAG"
fi

if [[ $(docker inspect -f '{{.State.Status}}' "$NAME" 2>/dev/null) == "running" ]]; then
  echo ">> Re-using..."
  if [[ $# -eq 0 ]]; then
    set -- "bash"
  fi
  docker exec -it "$NAME" "$@" || true
else
  docker rm -f "$NAME" &>/dev/null || true

  echo ">> Starting..."
  docker run -it \
    -w "/src" \
    -v "$PWD:/src" \
    -v "$PWD/tmp/root:/root" \
    --name="$NAME" "$IMAGE" "$@" || true
fi

echo ">> Done."
