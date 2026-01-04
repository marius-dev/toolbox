#!/bin/bash
set -e

# Build Linux packages (DEB, RPM, AppImage)
# Usage: ./build-linux-packages.sh [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Get version from pubspec.yaml if not provided
VERSION=${1:-$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)}
APP_NAME="project_launcher"
APP_DISPLAY_NAME="Project Launcher"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"

echo "Building Linux packages for version $VERSION"

# Check if build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found. Run 'flutter build linux --release' first."
    exit 1
fi

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/dist/linux"
mkdir -p "$OUTPUT_DIR"

# ============================================================
# 1. Create Tarball
# ============================================================
echo "Creating tarball..."
cd "$BUILD_DIR"
tar -czf "$OUTPUT_DIR/${APP_NAME}-${VERSION}-linux-x64.tar.gz" *
echo "✓ Tarball created: ${APP_NAME}-${VERSION}-linux-x64.tar.gz"

# ============================================================
# 2. Create AppImage
# ============================================================
echo "Creating AppImage..."
cd "$PROJECT_ROOT"

# Download appimagetool if not exists
if [ ! -f "appimagetool" ]; then
    wget -O appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool
fi

# Create AppDir structure
rm -rf AppDir
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
mkdir -p AppDir/usr/lib

# Copy application files
cp -r "$BUILD_DIR"/* AppDir/usr/bin/

# Copy icon
if [ -f "assets/icon.png" ]; then
    cp assets/icon.png "AppDir/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
    cp assets/icon.png "AppDir/${APP_NAME}.png"
else
    echo "Warning: assets/icon.png not found. AppImage will not have an icon."
fi

# Create desktop file
cat > "AppDir/usr/share/applications/${APP_NAME}.desktop" << EOF
[Desktop Entry]
Name=${APP_DISPLAY_NAME}
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Utility;Development;
Comment=A lightweight cross-platform IDE project management tool
Terminal=false
EOF

# Create AppRun script
cat > AppDir/AppRun << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr/bin"
exec "${HERE}/usr/bin/project_launcher" "$@"
APPRUN
chmod +x AppDir/AppRun

# Create symlink
ln -sf "usr/share/applications/${APP_NAME}.desktop" "AppDir/${APP_NAME}.desktop"

# Build AppImage
ARCH=x86_64 ./appimagetool AppDir "$OUTPUT_DIR/${APP_NAME}-${VERSION}-linux-x64.AppImage"
chmod +x "$OUTPUT_DIR/${APP_NAME}-${VERSION}-linux-x64.AppImage"
echo "✓ AppImage created: ${APP_NAME}-${VERSION}-linux-x64.AppImage"

# Clean up
rm -rf AppDir

# ============================================================
# 3. Create DEB package
# ============================================================
echo "Creating DEB package..."

PACKAGE_DIR="${APP_NAME}_${VERSION}_amd64"
rm -rf "$PACKAGE_DIR"

# Create package structure
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR/opt/${APP_NAME}"
mkdir -p "$PACKAGE_DIR/usr/share/applications"
mkdir -p "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PACKAGE_DIR/usr/bin"

# Copy application files
cp -r "$BUILD_DIR"/* "$PACKAGE_DIR/opt/${APP_NAME}/"

# Copy icon
if [ -f "assets/icon.png" ]; then
    cp assets/icon.png "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
fi

# Create desktop file
cat > "$PACKAGE_DIR/usr/share/applications/${APP_NAME}.desktop" << EOF
[Desktop Entry]
Name=${APP_DISPLAY_NAME}
Exec=/opt/${APP_NAME}/${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Utility;Development;
Comment=A lightweight cross-platform IDE project management tool
Terminal=false
EOF

# Create symlink
ln -s "/opt/${APP_NAME}/${APP_NAME}" "$PACKAGE_DIR/usr/bin/${APP_NAME}"

# Create control file
INSTALLED_SIZE=$(du -sk "$PACKAGE_DIR/opt/${APP_NAME}" | cut -f1)
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: ${INSTALLED_SIZE}
Maintainer: Project Launcher Team <team@projectlauncher.dev>
Description: A lightweight cross-platform IDE project management tool
 Project Launcher helps you manage your IDE projects efficiently
 across different development environments.
 .
 Features:
  - Quick project switching
  - Workspace management
  - Cross-platform support
EOF

# Create postinst script
cat > "$PACKAGE_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database -q /usr/share/applications || true
fi

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi

exit 0
EOF
chmod +x "$PACKAGE_DIR/DEBIAN/postinst"

# Create prerm script
cat > "$PACKAGE_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e
exit 0
EOF
chmod +x "$PACKAGE_DIR/DEBIAN/prerm"

# Build DEB package
dpkg-deb --build "$PACKAGE_DIR"
mv "${PACKAGE_DIR}.deb" "$OUTPUT_DIR/${APP_NAME}-${VERSION}-linux-x64.deb"
echo "✓ DEB package created: ${APP_NAME}-${VERSION}-linux-x64.deb"

# Clean up
rm -rf "$PACKAGE_DIR"

# ============================================================
# 4. Create RPM package
# ============================================================
echo "Creating RPM package..."

if command -v alien &> /dev/null; then
    cd "$OUTPUT_DIR"
    alien --to-rpm --keep-version "${APP_NAME}-${VERSION}-linux-x64.deb"

    # Rename to consistent name
    if [ -f "${APP_NAME}-${VERSION}-1.x86_64.rpm" ]; then
        mv "${APP_NAME}-${VERSION}-1.x86_64.rpm" "${APP_NAME}-${VERSION}-linux-x64.rpm"
    fi

    echo "✓ RPM package created: ${APP_NAME}-${VERSION}-linux-x64.rpm"
else
    echo "Warning: alien not found. Skipping RPM creation."
    echo "Install alien: sudo apt-get install alien"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=========================================="
echo "Linux packages built successfully!"
echo "=========================================="
echo "Output directory: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo "Installation commands:"
echo "  Tarball:   tar -xzf ${APP_NAME}-${VERSION}-linux-x64.tar.gz"
echo "  AppImage:  chmod +x ${APP_NAME}-${VERSION}-linux-x64.AppImage && ./${APP_NAME}-${VERSION}-linux-x64.AppImage"
echo "  DEB:       sudo dpkg -i ${APP_NAME}-${VERSION}-linux-x64.deb"
echo "  RPM:       sudo rpm -i ${APP_NAME}-${VERSION}-linux-x64.rpm"
echo ""
