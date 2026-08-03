#!/usr/bin/env bash
set -euo pipefail

if [ -d flutter ]; then
  git -C flutter fetch --depth 1 origin stable
  git -C flutter checkout FETCH_HEAD
else
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

flutter/bin/flutter config --no-analytics
flutter/bin/flutter precache --web
