#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="CCQuick"
VERSION="1.0.0"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION"
DMG_DIR="$BUILD_DIR/dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"

# Step 1: Build
echo "=== Building $APP_NAME ==="
bash build.sh

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: Build failed"
    exit 1
fi

# Step 2: Stage
echo ""
echo "=== Creating DMG ==="
rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Step 3: Create writable DMG first
TEMP_DMG="$BUILD_DIR/temp_$DMG_NAME.dmg"
rm -f "$TEMP_DMG"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "$TEMP_DMG" \
    > /dev/null 2>&1

# Step 4: Mount, configure auto-open and layout
MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen 2>/dev/null | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

# Tell Finder to open this volume automatically when mounted
bless --folder "$MOUNT_DIR" --openfolder "$MOUNT_DIR" 2>/dev/null || true

# Hide .fseventsd and other junk
rm -rf "$MOUNT_DIR/.fseventsd" 2>/dev/null || true
mkdir -p "$MOUNT_DIR/.fseventsd"
touch "$MOUNT_DIR/.fseventsd/no_log"

sync
sleep 1
hdiutil detach "$MOUNT_DIR" > /dev/null 2>&1

# Step 5: Compress to final DMG
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" > /dev/null 2>&1
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
echo ""
echo "=== Distribution Ready ==="
echo "  DMG: $DMG_PATH ($DMG_SIZE)"
echo ""
echo "To install:"
echo "  1. Open $DMG_PATH"
echo "  2. Drag $APP_NAME to Applications"
echo "  3. Right-click > Open (first launch only)"
