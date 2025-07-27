#!/bin/bash

mkdir -p /steps

set -eo pipefail

while read RUN CMD; do
  TOUCH_FILE="${CMD}"
  TOUCH_FILE="${TOUCH_FILE//\//_}"
  TOUCH_FILE="${TOUCH_FILE//\{/_}"
  TOUCH_FILE="${TOUCH_FILE//\}/_}"
  TOUCH_FILE="${TOUCH_FILE//\"/_}"
  TOUCH_FILE="${TOUCH_FILE//\'/_}"
  TOUCH_FILE="${TOUCH_FILE//./_}"
  TOUCH_FILE="${TOUCH_FILE//,/_}"
  TOUCH_FILE="${TOUCH_FILE//\&/_}"
  TOUCH_FILE="${TOUCH_FILE// /_}"
  TOUCH_FILE="${TOUCH_FILE//____/_}"
  TOUCH_FILE="${TOUCH_FILE//__/_}"
  TOUCH_FILE="${TOUCH_FILE//__/_}"
  TRACK_FILE="/steps/$TOUCH_FILE"
  [[ -e "$TRACK_FILE" ]] && continue
  echo ">> Executing $CMD..."
  ( eval "$CMD" )
  touch "$TRACK_FILE"
done < <(grep "^RUN ./scripts/build/make.bash" dockerfiles/Dockerfile.build)
