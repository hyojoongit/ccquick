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

# Step 1: Build the app
echo "=== Building $APP_NAME ==="
bash build.sh

# Verify build
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: Build failed, $APP_BUNDLE not found"
    exit 1
fi

# Step 2: Create DMG staging area
echo ""
echo "=== Creating DMG ==="
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

# Copy app to staging
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create Applications symlink (for drag-to-install)
ln -s /Applications "$DMG_DIR/Applications"

# Step 3: Create temporary DMG
TEMP_DMG="$BUILD_DIR/temp_$DMG_NAME.dmg"
rm -f "$TEMP_DMG" "$DMG_PATH"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDRW \
    "$TEMP_DMG" \
    > /dev/null 2>&1

# Step 4: Mount and customize appearance
MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen | grep "/Volumes/" | awk '{print $NF}')

# Set Finder window appearance via AppleScript
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 200, 900, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set position of item "$APP_NAME.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        close
    end tell
end tell
APPLESCRIPT

# Wait for Finder to process
sleep 1

# Set custom volume icon if available
if [ -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ]; then
    cp "$APP_BUNDLE/Contents/Resources/AppIcon.icns" "$MOUNT_DIR/.VolumeIcon.icns"
    SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true
fi

# Unmount
sync
hdiutil detach "$MOUNT_DIR" > /dev/null 2>&1

# Step 5: Convert to compressed read-only DMG
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" > /dev/null 2>&1
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

# Step 6: Summary
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
echo ""
echo "=== Distribution Ready ==="
echo "  DMG: $DMG_PATH ($DMG_SIZE)"
echo "  App: $APP_BUNDLE"
echo ""
echo "To install:"
echo "  1. Open $DMG_PATH"
echo "  2. Drag $APP_NAME to Applications"
echo "  3. Right-click > Open (first launch only, since unsigned)"
