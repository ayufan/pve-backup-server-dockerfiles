#!/bin/bash

while read REPO REST; do
  if grep -q "./scripts/build/make.bash $REPO " dockerfiles/Dockerfile.build; then
    echo "$REPO $REST"
  fi
done < "repos/deps" > "repos/deps.tmp"

mv repos/deps{.tmp,}
