#!/bin/bash
# Captures a screenshot of the Watch app on a watch simulator.
# Usage: bash Scripts/capture_watch_screenshot.sh <HealthWatch.app path> <output png>
# Exits 0 only when a non-empty screenshot file was written.
# The Watch app is independent of the iPhone app, so only the watch app is
# installed; HealthKit on the simulator returns no data, so the shot shows
# the honest empty state, never manufactured readings.
set -u
APP_PATH="${1:?usage: capture_watch_screenshot.sh <HealthWatch.app path> <output png>}"
OUT="${2:?usage: capture_watch_screenshot.sh <HealthWatch.app path> <output png>}"

echo "== watch simulators =="
xcrun simctl list devices available | grep -i "Apple Watch" || true

UDID=$(xcrun simctl list devices available | grep -i "Apple Watch" \
    | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
if [ -z "$UDID" ]; then
    echo "== no watch simulator found, creating one =="
    DEVTYPE=$(xcrun simctl list devicetypes | grep -i "Apple Watch" | grep -iE "45mm|46mm" \
        | head -1 | sed -E 's/^[[:space:]]*//; s/ \(com\.apple.*//')
    RUNTIME=$(xcrun simctl list runtimes | grep -i "watchOS" | tail -1 \
        | sed -E 's/^[[:space:]]*([A-Za-z]+ [0-9.]+).*/\1/')
    echo "device type: $DEVTYPE"
    echo "runtime: $RUNTIME"
    UDID=$(xcrun simctl create ScreenshotWatch "$DEVTYPE" "$RUNTIME")
    echo "created: $UDID"
fi
echo "using watch simulator: $UDID"

echo "== boot =="
xcrun simctl boot "$UDID" 2>&1 || echo "(already booted or boot skipped)"

echo "== install $APP_PATH =="
xcrun simctl install "$UDID" "$APP_PATH"

echo "== launch com.example.healthintelligence.watchkitapp =="
xcrun simctl launch "$UDID" com.example.healthintelligence.watchkitapp || true
sleep 6

echo "== screenshot -> $OUT =="
mkdir -p "$(dirname "$OUT")"
xcrun simctl io "$UDID" screenshot "$OUT"

if [ -s "$OUT" ]; then
    echo "OK: $(wc -c < "$OUT") bytes written to $OUT"
    exit 0
fi
echo "FAIL: no screenshot at $OUT"
exit 1
