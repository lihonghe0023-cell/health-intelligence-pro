#!/bin/bash
# Captures two real screenshots of the Watch app on a watch simulator:
# the dashboard home and the sleep section, on a 42mm (or smallest
# available) device. Writes both PNGs plus watch-manifest.json into the
# output directory.
# Usage: bash Scripts/capture_watch_screenshot.sh <HealthWatch.app path> <output dir>
# Exits 0 only when both non-empty screenshots and the manifest exist.
# The Watch app is independent of the iPhone app, so only the watch app
# is installed; HealthKit on the simulator returns no data, so both shots
# show the honest empty state, never manufactured readings.
set -u
APP_PATH="${1:?usage: capture_watch_screenshot.sh <HealthWatch.app path> <output dir>}"
OUT_DIR="${2:?usage: capture_watch_screenshot.sh <HealthWatch.app path> <output dir>}"
BUNDLE_ID="com.example.healthintelligence.watchkitapp"
mkdir -p "$OUT_DIR"

fail() { echo "FAIL: $1"; exit 1; }

echo "== watch simulators =="
xcrun simctl list devices available | grep -i "Apple Watch" || true

# Prefer a 42mm (small-screen) device, then 41mm, then any watch device.
UDID=""
for SIZE in 42mm 41mm; do
    UDID=$(xcrun simctl list devices available | grep -i "$SIZE" \
        | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
    [ -n "$UDID" ] && break
done
if [ -z "$UDID" ]; then
    UDID=$(xcrun simctl list devices available | grep -i "Apple Watch" \
        | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1)
fi
if [ -z "$UDID" ]; then
    echo "== no watch simulator found, creating a 42mm one =="
    DEVTYPE=$(xcrun simctl list devicetypes | grep -i "Apple Watch" | grep -i "42mm" \
        | head -1 | sed -E 's/^[[:space:]]*//; s/ \(com\.apple.*//')
    RUNTIME=$(xcrun simctl list runtimes | grep -i "watchOS" | tail -1 \
        | sed -E 's/^[[:space:]]*([A-Za-z]+ [0-9.]+).*/\1/')
    [ -n "$DEVTYPE" ] || fail "no 42mm watch device type on this runner"
    echo "device type: $DEVTYPE"
    echo "runtime: $RUNTIME"
    UDID=$(xcrun simctl create ScreenshotWatch "$DEVTYPE" "$RUNTIME") \
        || fail "simctl create failed"
    echo "created: $UDID"
fi
echo "using watch simulator: $UDID"

DEVICE_NAME=$(xcrun simctl list devices available | grep "$UDID" \
    | sed -E 's/^[[:space:]]*//; s/ \([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\).*//')
RUNTIME=$(xcrun simctl list devices available | grep -B 100 "$UDID" \
    | grep -iE '^[[:space:]]*-- .* --[[:space:]]*$' | tail -1 \
    | sed -E 's/^[[:space:]]*-- //; s/ --[[:space:]]*$//')
[ -n "$DEVICE_NAME" ] || DEVICE_NAME="unknown watch device"
[ -n "$RUNTIME" ] || RUNTIME="unknown runtime"
SLUG=$(printf '%s-%s' "$DEVICE_NAME" "$RUNTIME" | tr ' .' '--' | tr -d '()' | tr -s '-')
echo "device: $DEVICE_NAME"
echo "runtime: $RUNTIME"
echo "slug: $SLUG"

echo "== boot =="
xcrun simctl boot "$UDID" 2>&1 || echo "(already booted or boot skipped)"
echo "== wait for boot (bounded 120s) =="
for i in $(seq 1 60); do
    if xcrun simctl list devices available | grep "$UDID" | grep -q "(Booted)"; then
        echo "booted after ~$((i * 2))s"
        break
    fi
    sleep 2
done
xcrun simctl list devices available | grep "$UDID" | grep -q "(Booted)" \
    || fail "watch simulator did not reach Booted state within 120s"

echo "== install $APP_PATH =="
xcrun simctl install "$UDID" "$APP_PATH" || fail "install failed"

launch_and_check() {
    # $1 = extra launch arg (may be empty), $2 = label for logs.
    # Diagnostics go to stderr; only the launched PID goes to stdout.
    local extra="$1" label="$2"
    echo "== launch $BUNDLE_ID ($label) ==" >&2
    local out status
    if [ -n "$extra" ]; then
        out=$(xcrun simctl launch "$UDID" "$BUNDLE_ID" "$extra" 2>&1)
    else
        out=$(xcrun simctl launch "$UDID" "$BUNDLE_ID" 2>&1)
    fi
    status=$?
    echo "$out" >&2
    [ $status -eq 0 ] || fail "Watch app failed to launch ($label, exit $status)"
    local pid
    pid=$(printf '%s' "$out" | grep -oE '[0-9]+' | head -1)
    echo "launched pid: $pid" >&2
    sleep 6
    echo "== verify the app itself is running ($label) ==" >&2
    local state
    state=$(xcrun simctl spawn "$UDID" launchctl print "gui/501/$BUNDLE_ID" 2>&1 || true)
    echo "$state" >&2
    echo "$state" | grep -q "state = running" || fail "Watch app is not running after launch ($label)"
    printf '%s' "$pid"
}

shoot() {
    # $1 = output png
    xcrun simctl io "$UDID" screenshot "$1" || fail "screenshot failed ($1)"
    [ -s "$1" ] || fail "empty screenshot ($1)"
    echo "OK: $(wc -c < "$1") bytes -> $1"
}

HOME_PNG="$OUT_DIR/watch-home-$SLUG.png"
SLEEP_PNG="$OUT_DIR/watch-sleep-$SLUG.png"

HOME_PID=$(launch_and_check "" "home")
shoot "$HOME_PNG"

echo "== relaunch for the sleep section =="
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>&1 || echo "(terminate skipped)"
SLEEP_PID=$(launch_and_check "-watchScreenshotSleep" "sleep")
sleep 2
shoot "$SLEEP_PNG"

HOME_BYTES=$(wc -c < "$HOME_PNG")
SLEEP_BYTES=$(wc -c < "$SLEEP_PNG")
printf '{\n  "device": "%s",\n  "runtime": "%s",\n  "mode": "dark",\n  "bundleId": "%s",\n  "home": {"file": "%s", "bytes": %s, "pid": %s},\n  "sleep": {"file": "%s", "bytes": %s, "pid": %s},\n  "note": "Simulator has no HealthKit data; both shots show the honest empty state."\n}\n' \
    "$DEVICE_NAME" "$RUNTIME" "$BUNDLE_ID" \
    "$(basename "$HOME_PNG")" "$HOME_BYTES" "$HOME_PID" \
    "$(basename "$SLEEP_PNG")" "$SLEEP_BYTES" "$SLEEP_PID" \
    > "$OUT_DIR/watch-manifest.json"
echo "== manifest =="
cat "$OUT_DIR/watch-manifest.json"
echo "OK: watch home + sleep captured"
