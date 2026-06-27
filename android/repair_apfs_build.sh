#!/usr/bin/env bash
# Wipes Gradle intermediates on APFS and the legacy Flutter project build/ folder.
# Android builds use ~/Library/Caches/toukh_provider_android_build/project_build (see android/build.gradle.kts).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${HOME}/Library/Caches/toukh_provider_android_build/project_build"

echo "[toukh_provider] Removing: ${CACHE} and ${ROOT}/build"
rm -rf "${CACHE}" "${ROOT}/build"
mkdir -p "${CACHE}"

if [[ -f "${ROOT}/android/local.properties" ]]; then
  FLUTTER_SDK="$(grep '^flutter.sdk=' "${ROOT}/android/local.properties" | cut -d= -f2-)"
  FLUTTER_GRADLE="${FLUTTER_SDK}/packages/flutter_tools/gradle"
  if [[ -d "${FLUTTER_GRADLE}" ]]; then
    CACHE_ID="$(python3 -c "s='${FLUTTER_GRADLE}'; h=0
for c in s:
 h=(31*h+ord(c))&0xFFFFFFFF
 if h>=0x80000000: h-=0x100000000
print(hex(h & 0xFFFFFFFF)[2:])")"
    FG_CACHE="${HOME}/Library/Caches/toukh_flutter_tools_gradle/${CACHE_ID}"
    echo "[toukh_provider] Repairing Flutter SDK gradle build symlink -> ${FG_CACHE}"
    rm -rf "${FLUTTER_GRADLE}/build"
    mkdir -p "${FG_CACHE}"
    ln -sfn "${FG_CACHE}" "${FLUTTER_GRADLE}/build"
  fi
fi

echo "[toukh_provider] Done. From ${ROOT}: flutter pub get && flutter run"
