#!/usr/bin/env bash
set -euo pipefail

# Pin to the Flutter version this repo is developed against (intl 0.19).
FLUTTER_VERSION="${FLUTTER_VERSION:-3.29.3}"

if [ -d flutter ]; then
  git -C flutter fetch --depth 1 origin "refs/tags/$FLUTTER_VERSION"
  git -C flutter checkout FETCH_HEAD
else
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1
fi

flutter/bin/flutter config --no-analytics
flutter/bin/flutter precache --web
