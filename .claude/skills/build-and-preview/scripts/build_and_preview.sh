#!/bin/bash
# Build, install, launch, and screenshot the AdorableBites app on the iPad simulator.
# Outputs the path to a landscape-oriented screenshot on success.
# Exit codes: 0 = success, 1 = xcodegen failed, 2 = build failed, 3 = install/launch failed, 4 = screenshot failed

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
BUNDLE_ID="com.adorablebites.app"
SIMULATOR="iPad mini (A17 Pro)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOTS_DIR="${PROJECT_DIR}/.screenshots"
SCREENSHOT="${SCREENSHOTS_DIR}/raw_${TIMESTAMP}.png"
SCREENSHOT_FINAL="${SCREENSHOTS_DIR}/preview_${TIMESTAMP}.png"

cd "$PROJECT_DIR"

# Ensure .screenshots directory exists and is gitignored
mkdir -p "$SCREENSHOTS_DIR"
if ! grep -q '\.screenshots/' .gitignore 2>/dev/null; then
    echo '.screenshots/' >> .gitignore
fi

# Step 1: Generate Xcode project
echo "==> Generating Xcode project..."
if ! xcodegen generate 2>&1; then
    echo "ERROR: xcodegen generate failed"
    exit 1
fi

# Step 2: Build
echo "==> Building for simulator..."
BUILD_LOG="${SCREENSHOTS_DIR}/build_${TIMESTAMP}.log"
if ! xcodebuild \
    -project AdorableBites.xcodeproj \
    -scheme AdorableBites \
    -destination "platform=iOS Simulator,name=${SIMULATOR}" \
    build > "$BUILD_LOG" 2>&1; then
    echo "ERROR: Build failed. Last 30 lines:"
    tail -30 "$BUILD_LOG"
    exit 2
fi
echo "==> Build succeeded"

# Step 3: Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 6 -path "*/AdorableBites-*/Build/Products/Debug-iphonesimulator/AdorableBites.app" -not -path "*/Index.noindex/*" -type d 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built app in DerivedData"
    exit 3
fi

# Step 4: Boot simulator if needed
echo "==> Preparing simulator..."
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true

# Step 5: Terminate existing instance, install, and launch
xcrun simctl terminate "$SIMULATOR" "$BUNDLE_ID" 2>/dev/null || true
echo "==> Installing app..."
if ! xcrun simctl install "$SIMULATOR" "$APP_PATH" 2>&1; then
    echo "ERROR: Failed to install app"
    exit 3
fi
echo "==> Launching app..."
if ! xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" 2>&1; then
    echo "ERROR: Failed to launch app"
    exit 3
fi

# Step 6: Wait for render and screenshot
sleep 2
echo "==> Taking screenshot..."
if ! xcrun simctl io "$SIMULATOR" screenshot "$SCREENSHOT" 2>&1; then
    echo "ERROR: Failed to take screenshot"
    exit 4
fi

# Step 7: Rotate to landscape only if needed (portrait = height > width)
echo "==> Processing screenshot..."
python3 -c "
from PIL import Image
img = Image.open('${SCREENSHOT}')
w, h = img.size
if h > w:
    img = img.rotate(-90, expand=True)
img.save('${SCREENSHOT_FINAL}')
" 2>&1

echo "==> Done!"
echo "SCREENSHOT_PATH=${SCREENSHOT_FINAL}"
