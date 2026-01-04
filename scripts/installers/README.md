# Installer Build Scripts

This directory contains scripts to build professional installers for all supported platforms.

## Prerequisites

### Linux
```bash
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  dpkg-deb alien rpm
```

### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install create-dmg
brew install create-dmg
```

### Windows
```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Inno Setup
choco install innosetup -y
```

## Usage

### Linux Packages

Build all Linux packages (tarball, AppImage, DEB, RPM):

```bash
cd scripts/installers
chmod +x build-linux-packages.sh
./build-linux-packages.sh [version]
```

Output files in `dist/linux/`:
- `project_launcher-{version}-linux-x64.tar.gz` - Universal tarball
- `project_launcher-{version}-linux-x64.AppImage` - Portable AppImage
- `project_launcher-{version}-linux-x64.deb` - Debian/Ubuntu package
- `project_launcher-{version}-linux-x64.rpm` - Fedora/RHEL package

### macOS DMG

Build macOS DMG installer:

```bash
cd scripts/installers
chmod +x build-macos-dmg.sh
./build-macos-dmg.sh [version]
```

Output files in `dist/macos/`:
- `project_launcher-{version}-macos-universal.dmg` - DMG installer
- `project_launcher-{version}-macos-universal.zip` - ZIP archive

### Windows Installer

Build Windows installer:

```powershell
cd scripts\installers
.\build-windows-installer.ps1 [version]
```

Output files in `dist/windows/`:
- `project_launcher-{version}-windows-x64-installer.exe` - Inno Setup installer
- `project_launcher-{version}-windows-x64-portable.zip` - Portable version
- `project_launcher-{version}-windows-x64.zip` - Standard ZIP archive

## Code Signing

### macOS Code Signing

1. Export your Developer ID certificate from Keychain
2. Set environment variables:
   ```bash
   export MACOS_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
   export APPLE_ID="your-apple-id@example.com"
   export APPLE_ID_PASSWORD="app-specific-password"
   export APPLE_TEAM_ID="TEAM_ID"
   ```
3. Run the build script

### Windows Code Signing

1. Obtain a code signing certificate (e.g., from DigiCert, Sectigo)
2. Sign the executable after building:
   ```powershell
   signtool.exe sign /f certificate.pfx /p password /tr http://timestamp.digicert.com /td sha256 /fd sha256 file.exe
   ```

## GitHub Actions Integration

The installer build scripts are integrated into the GitHub Actions workflows:

- **CI Workflow** (`.github/workflows/ci.yml`) - Runs on every push/PR
- **Release Workflow** (`.github/workflows/release.yml`) - Builds installers on tag push
- **Version Bump** (`.github/workflows/version-bump.yml`) - Automates versioning
- **Security Scanning** (`.github/workflows/security.yml`) - Security checks

## Versioning

Use the version-bump workflow to automatically increment versions:

```bash
# Via GitHub Actions UI
# Go to Actions → Version Bump → Run workflow
# Select: patch, minor, or major

# Or manually update pubspec.yaml
version: 1.2.3+4
```

## Distribution Channels

After building installers, you can distribute through:

### Linux
- **Snap Store**: Submit to snapcraft.io
- **Flathub**: Submit to flathub.org
- **AUR (Arch)**: Create PKGBUILD
- **GitHub Releases**: Automated via workflows

### macOS
- **Homebrew**: Create formula
- **GitHub Releases**: Automated via workflows

### Windows
- **Chocolatey**: Create package
- **Winget**: Submit to winget-pkgs
- **GitHub Releases**: Automated via workflows

## Testing Installers

### Linux
```bash
# AppImage
chmod +x project_launcher-*.AppImage
./project_launcher-*.AppImage

# DEB
sudo dpkg -i project_launcher-*.deb

# RPM
sudo rpm -i project_launcher-*.rpm
```

### macOS
```bash
# DMG
open project_launcher-*.dmg
# Drag to Applications and run

# ZIP
unzip project_launcher-*.zip
open *.app
```

### Windows
```powershell
# Installer
.\project_launcher-*-installer.exe

# Portable
Expand-Archive project_launcher-*-portable.zip
cd project_launcher-*-portable
.\project_launcher.exe
```

## Troubleshooting

### Linux AppImage not running
- Install FUSE: `sudo apt-get install libfuse2`
- Make executable: `chmod +x *.AppImage`

### macOS "App is damaged" error
- Remove quarantine: `xargs -n 1 xattr -d com.apple.quarantine < <(find . -name "*.app")`
- Or: Right-click → Open → Open

### Windows SmartScreen warning
- Click "More info" → "Run anyway"
- For production, sign the executable

## Additional Resources

- [Inno Setup Documentation](https://jrsoftware.org/ishelp/)
- [create-dmg Documentation](https://github.com/create-dmg/create-dmg)
- [AppImage Documentation](https://docs.appimage.org/)
- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
