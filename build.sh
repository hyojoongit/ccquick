#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="CCQuick"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"

echo "Cleaning previous build..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"

# Find all Swift source files
SOURCES=$(find CCQuick -name "*.swift" -type f)

SDK_PATH=$(xcrun --show-sdk-path)

# Create VFS overlay to fix duplicate SwiftBridging module.modulemap
VFS_OVERLAY="/tmp/ccquick_vfs_overlay.yaml"
cat > "$VFS_OVERLAY" << 'VFSEOF'
{
  "version": 0,
  "roots": [
    {
      "name": "/Library/Developer/CommandLineTools/usr/include/swift",
      "type": "directory",
      "contents": [
        {
          "name": "module.modulemap",
          "type": "file",
          "external-contents": "/Library/Developer/CommandLineTools/usr/include/swift/bridging.modulemap"
        }
      ]
    }
  ]
}
VFSEOF

echo "Compiling..."

swiftc \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macosx15.0 \
    -sdk "$SDK_PATH" \
    -Xfrontend -vfsoverlay -Xfrontend "$VFS_OVERLAY" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Carbon \
    -parse-as-library \
    -swift-version 5 \
    -suppress-warnings \
    $SOURCES

# Copy Info.plist
cp CCQuick/Resources/Info.plist "$CONTENTS/"

# Copy resources
RESOURCES="$CONTENTS/Resources"
mkdir -p "$RESOURCES"
cp icon/ccquick_logo.png "$RESOURCES/AppIcon.png"
cp icon/ccquick_logo_transparent.png "$RESOURCES/MenuBarIcon.png"
cp icon/DMSerifDisplay-Italic.ttf "$RESOURCES/DMSerifDisplay-Italic.ttf"

# Generate .icns app icon
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
sips -z 16 16     icon/ccquick_logo.png --out "$ICONSET/icon_16x16.png"      > /dev/null 2>&1
sips -z 32 32     icon/ccquick_logo.png --out "$ICONSET/icon_16x16@2x.png"   > /dev/null 2>&1
sips -z 32 32     icon/ccquick_logo.png --out "$ICONSET/icon_32x32.png"      > /dev/null 2>&1
sips -z 64 64     icon/ccquick_logo.png --out "$ICONSET/icon_32x32@2x.png"   > /dev/null 2>&1
sips -z 128 128   icon/ccquick_logo.png --out "$ICONSET/icon_128x128.png"    > /dev/null 2>&1
sips -z 256 256   icon/ccquick_logo.png --out "$ICONSET/icon_128x128@2x.png" > /dev/null 2>&1
sips -z 256 256   icon/ccquick_logo.png --out "$ICONSET/icon_256x256.png"    > /dev/null 2>&1
sips -z 512 512   icon/ccquick_logo.png --out "$ICONSET/icon_256x256@2x.png" > /dev/null 2>&1
sips -z 512 512   icon/ccquick_logo.png --out "$ICONSET/icon_512x512.png"    > /dev/null 2>&1
sips -z 1024 1024 icon/ccquick_logo.png --out "$ICONSET/icon_512x512@2x.png" > /dev/null 2>&1
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns" 2>/dev/null
rm -rf "$ICONSET"

echo ""
echo "Build successful: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
