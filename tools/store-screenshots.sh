#!/bin/bash
#
#  App Store screenshots for one simulator, in light then dark mode, saved
#  at the simulator's full resolution (qrhUITests/StoreScreenshots.swift sets
#  up each screen; this takes the shot). From the repository folder:
#
#    tools/store-screenshots.sh "iPhone 17 Pro Max" ~/Desktop/screenshots
#    tools/store-screenshots.sh "iPhone 17" ~/Desktop/screenshots-6.3
#    tools/store-screenshots.sh "iPad Pro 13-inch (M5)" ~/Desktop/screenshots
#

set -euo pipefail

device=$1
mkdir -p "$2"
out=$(cd "$2" && pwd)

xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" > /dev/null
xcrun simctl status_bar "$device" override --time "9:41" --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

for appearance in light dark; do
    xcrun simctl ui "$device" appearance "$appearance"

#    Takes each screenshot the test asks for
    (
        while true; do
            for ready in "$out"/*.ready; do
                [ -e "$ready" ] || continue
                png="${ready%.ready}.png"
                xcrun simctl io "$device" screenshot "$png.tmp" > /dev/null 2>&1
#                The iPad is in landscape, but the capture is the screen's
#                portrait buffer
                case "$device" in
                    iPad*) sips -r 270 "$png.tmp" > /dev/null ;;
                esac
                mv "$png.tmp" "$png"
                rm "$ready"
            done
            sleep 1
        done
    ) &
    taker=$!

    TEST_RUNNER_QRH_STORE_DIR="$out" TEST_RUNNER_QRH_STORE_APPEARANCE="$appearance" \
        xcodebuild test -workspace qrh.xcworkspace -scheme qrh \
        -destination "platform=iOS Simulator,name=$device" \
        -only-testing:qrhUITests/StoreScreenshots -quiet || status=$?

    kill "$taker" 2> /dev/null; wait "$taker" 2> /dev/null || true
    if [ "${status:-0}" -ne 0 ]; then
        echo "Screenshots in $appearance mode failed" >&2
        exit 1
    fi
done

ls "$out"
