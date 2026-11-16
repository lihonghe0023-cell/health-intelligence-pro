#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodegen >/dev/null; then
  echo '请先在 macOS 上安装 XcodeGen：brew install xcodegen' >&2
  exit 1
fi
xcodegen generate --spec project.yml
# Some XcodeGen releases embed Watch apps under Watch/ (older Xcode behavior),
# but Xcode 26+ needs PlugIns/. Only patch the specific copy phase if present.
python3 Scripts/patch_watch_embed.py HealthIntelligence.xcodeproj/project.pbxproj
xcodebuild -list -project HealthIntelligence.xcodeproj
