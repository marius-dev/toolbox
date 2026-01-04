#!/bin/bash
set -e

# Build macOS DMG installer
# Usage: ./build-macos-dmg.sh [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Get version from pubspec.yaml if not provided
VERSION=${1:-$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)}
APP_NAME="project_launcher"
APP_DISPLAY_NAME="Project Launcher"
BUILD_DIR="$PROJECT_ROOT/build/macos/Build/Products/Release"

echo "Building macOS DMG for version $VERSION"

# Check if build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found. Run 'flutter build macos --release' first."
    exit 1
fi

# Find the .app bundle
APP_BUNDLE=$(find "$BUILD_DIR" -name "*.app" -type d -maxdepth 1 | head -n 1)
if [ -z "$APP_BUNDLE" ]; then
    echo "Error: No .app bundle found in $BUILD_DIR"
    exit 1
fi

APP_BUNDLE_NAME=$(basename "$APP_BUNDLE")
echo "Found app bundle: $APP_BUNDLE_NAME"

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/dist/macos"
mkdir -p "$OUTPUT_DIR"

# ============================================================
# 1. Create ZIP archive
# ============================================================
echo "Creating ZIP archive..."
cd "$BUILD_DIR"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE_NAME" "$OUTPUT_DIR/${APP_NAME}-${VERSION}-macos-universal.zip"
echo "✓ ZIP archive created: ${APP_NAME}-${VERSION}-macos-universal.zip"

# ============================================================
# 2. Create DMG installer
# ============================================================
echo "Creating DMG installer..."
cd "$PROJECT_ROOT"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Installing create-dmg..."
    if command -v npm &> /dev/null; then
        npm install -g create-dmg
    elif command -v brew &> /dev/null; then
        brew install create-dmg
    else
        echo "Error: Neither npm nor brew found. Please install create-dmg manually."
        exit 1
    fi
fi

# Create temporary directory for DMG creation
DMG_TEMP_DIR=$(mktemp -d)
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"

# Create DMG with custom settings
DMG_FILE="$OUTPUT_DIR/${APP_NAME}-${VERSION}-macos-universal.dmg"

# Generate DMG background image if it doesn't exist
DMG_BACKGROUND="$SCRIPT_DIR/dmg-background.png"
if [ ! -f "$DMG_BACKGROUND" ]; then
    echo "Generating DMG background..."
    python3 "$SCRIPT_DIR/generate-dmg-background.py" || {
        echo "Warning: Failed to generate DMG background, continuing without it..."
        DMG_BACKGROUND=""
    }
fi

# Prepare background argument for create-dmg
BACKGROUND_ARGS=""
if [ -n "$DMG_BACKGROUND" ] && [ -f "$DMG_BACKGROUND" ]; then
    BACKGROUND_ARGS="--background $DMG_BACKGROUND"
fi

create-dmg \
  --volname "$APP_DISPLAY_NAME" \
  --volicon "assets/icon.png" \
  --window-pos 200 120 \
  --window-size 800 450 \
  --icon-size 100 \
  --icon "$APP_BUNDLE_NAME" 200 190 \
  --hide-extension "$APP_BUNDLE_NAME" \
  --app-drop-link 600 185 \
  $BACKGROUND_ARGS \
  --no-internet-enable \
  "$DMG_FILE" \
  "$DMG_TEMP_DIR/" \
  || {
    # create-dmg sometimes returns error even when successful
    if [ -f "$DMG_FILE" ]; then
      echo "✓ DMG created (with warnings)"
    else
      echo "Error: DMG creation failed"
      exit 1
    fi
  }

# Clean up
rm -rf "$DMG_TEMP_DIR"

echo "✓ DMG installer created: ${APP_NAME}-${VERSION}-macos-universal.dmg"

# ============================================================
# 3. Code Signing (Optional - requires Apple Developer Account)
# ============================================================
if [ -n "$MACOS_SIGNING_IDENTITY" ]; then
    echo "Signing macOS application..."

    # Sign the app bundle
    codesign --force --deep --sign "$MACOS_SIGNING_IDENTITY" \
      --options runtime \
      --entitlements "macos/Runner/Release.entitlements" \
      "$APP_BUNDLE"

    echo "✓ Application signed with identity: $MACOS_SIGNING_IDENTITY"

    # Verify signature
    codesign --verify --verbose "$APP_BUNDLE"
    spctl --assess --verbose "$APP_BUNDLE"
else
    echo "Note: Skipping code signing (MACOS_SIGNING_IDENTITY not set)"
    echo "For distribution, you should sign the app with:"
    echo "  export MACOS_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAM_ID)'"
fi

# ============================================================
# 4. Notarization (Optional - requires Apple Developer Account)
# ============================================================
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ] && [ -n "$APPLE_TEAM_ID" ]; then
    echo "Notarizing DMG..."

    # Upload for notarization
    xcrun notarytool submit "$DMG_FILE" \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_ID_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait

    # Staple the notarization ticket
    xcrun stapler staple "$DMG_FILE"

    echo "✓ DMG notarized and stapled"
else
    echo "Note: Skipping notarization (Apple credentials not set)"
    echo "For distribution outside the App Store, notarization is recommended."
    echo "Set these environment variables:"
    echo "  export APPLE_ID='your-apple-id@example.com'"
    echo "  export APPLE_ID_PASSWORD='app-specific-password'"
    echo "  export APPLE_TEAM_ID='TEAM_ID'"
fi

# ============================================================
# 5. Generate installation instructions
# ============================================================
cat > "$OUTPUT_DIR/INSTALL.txt" << EOF
Project Launcher - macOS Installation
======================================

Version: $VERSION

⚠️  IMPORTANT: First-Time Security Setup Required

macOS will block this app because it's not signed with an Apple Developer
certificate. This is normal for open-source apps.

FIRST-TIME SETUP (Required):
----------------------------
Method 1 (Easiest):
  1. Right-click on ${APP_DISPLAY_NAME}.app
  2. Select "Open" from the menu
  3. Click "Open" in the dialog that appears

Method 2 (Terminal):
  Open Terminal and run:
  xattr -cr /Applications/${APP_NAME}.app

Method 3 (System Settings - macOS 13+):
  1. Try to open the app (it will be blocked)
  2. Go to System Settings → Privacy & Security
  3. Find "${APP_DISPLAY_NAME} was blocked" and click "Open Anyway"

After the first time, the app will open normally with double-click.

Installation Instructions:
--------------------------

Option 1: DMG Installer (Recommended)
1. Double-click ${APP_NAME}-${VERSION}-macos-universal.dmg
2. Drag ${APP_DISPLAY_NAME} to the Applications folder
3. Eject the DMG
4. Follow the First-Time Setup above to open the app

Option 2: ZIP Archive
1. Extract ${APP_NAME}-${VERSION}-macos-universal.zip
2. Move ${APP_NAME}.app to /Applications
3. Follow the First-Time Setup above to open the app

System Requirements:
-------------------
- macOS 10.15 (Catalina) or later
- Universal Binary: Works on both Intel and Apple Silicon Macs

Why This Warning Appears:
-------------------------
This app is built by automated CI/CD without an Apple Developer certificate
(\$99/year). The app is safe - it's open source and you can review the code.

For Developers: See MACOS-DISTRIBUTION.md for code signing setup.

Uninstall:
----------
Drag ${APP_DISPLAY_NAME}.app from Applications to Trash

For more information: https://github.com/your-repo/project_launcher

EOF

echo "✓ Installation instructions created"

# ============================================================
# Summary
# ============================================================
echo ""
echo "=========================================="
echo "macOS packages built successfully!"
echo "=========================================="
echo "Output directory: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo "Distribution packages:"
echo "  DMG: ${APP_NAME}-${VERSION}-macos-universal.dmg (recommended)"
echo "  ZIP: ${APP_NAME}-${VERSION}-macos-universal.zip"
echo ""

if [ -z "$MACOS_SIGNING_IDENTITY" ]; then
    echo "⚠️  WARNING: Application is not signed"
    echo "   Users will see security warnings when opening"
    echo "   For production releases, configure code signing"
fi

if [ -z "$APPLE_ID" ]; then
    echo "⚠️  WARNING: Application is not notarized"
    echo "   macOS Gatekeeper may prevent users from opening"
    echo "   For production releases, configure notarization"
fi

echo ""
