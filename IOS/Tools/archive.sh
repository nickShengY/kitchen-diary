#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to the Apple Developer team that owns com.kitchendiary.app}"
: "${BUILD_NUMBER:?Set BUILD_NUMBER to an unused, increasing App Store Connect build number}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$PWD/.build/archives/KitchenDiary.xcarchive}"
if ! security find-identity -v -p codesigning | grep -q '"Apple '; then
  echo 'No Apple signing identity. Sign into Xcode and create/download a certificate first.' >&2
  exit 1
fi
xcodebuild -project KitchenDiary.xcodeproj -scheme KitchenDiary -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  -allowProvisioningUpdates archive
printf 'Archive created: %s\nValidate and distribute it using Xcode Organizer.\n' "$ARCHIVE_PATH"
