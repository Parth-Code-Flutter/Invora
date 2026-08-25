#!/usr/bin/env bash
# Build a 15-day client demo APK. Default / Play builds must NOT use this script.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

client_name="${1:-Client demo}"

if date -v+15d +%Y-%m-%d >/dev/null 2>&1; then
  build_day="$(date +%Y-%m-%d)"
  expires_day="$(date -v+15d +%Y-%m-%d)"
else
  build_day="$(date +%Y-%m-%d)"
  expires_day="$(date -d '+15 days' +%Y-%m-%d)"
fi

echo "Packaging demo APK"
echo "  client : $client_name"
echo "  built  : $build_day"
echo "  last day (inclusive): $expires_day"

flutter build apk --release \
  --dart-define="DEMO_EXPIRES_AT=$expires_day" \
  --dart-define="DEMO_BUILD_TIME=$build_day" \
  --dart-define="DEMO_CLIENT_NAME=$client_name"

echo
echo "APK: $root/build/app/outputs/flutter-apk/app-release.apk"
echo "After $expires_day the app only shows: Please contact your sales person"
