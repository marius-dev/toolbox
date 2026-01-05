# macOS Distribution Guide

This guide explains how to handle macOS Gatekeeper warnings and optionally set up code signing and notarization for production releases.

## Understanding the Warning

When you download and try to open the app, you'll see:

> **"Apple could not verify "project_launcher.app" is free of malware that may harm your Mac or compromise your privacy."**

This is macOS **Gatekeeper**, Apple's security feature that blocks unsigned applications. This happens because our automated builds don't include code signing (which requires an Apple Developer Account costing $99/year).

## For Users: How to Open the App

### Method 1: Right-Click → Open (Recommended)

1. **Locate the app** in Finder (in Applications or wherever you extracted it)
2. **Right-click** (or Control+Click) on `project_launcher.app`
3. Select **"Open"** from the menu
4. Click **"Open"** in the dialog that appears
5. The app will now run and won't ask again

### Method 2: Remove Quarantine Attribute

Open Terminal and run:

```bash
xattr -cr /Applications/project_launcher.app
```

Then you can open the app normally by double-clicking.

### Method 3: System Settings (macOS 13+)

1. Try to open the app (it will be blocked)
2. Go to **System Settings** → **Privacy & Security**
3. Scroll down to find **"project_launcher.app was blocked"**
4. Click **"Open Anyway"**
5. Confirm by clicking **"Open"**

---

## For Developers: Code Signing Setup

To distribute signed and notarized builds (eliminates the warning), you need:

1. **Apple Developer Account** ($99/year)
2. **Developer ID Application Certificate**
3. **App-specific password** for notarization

### Step 1: Get Developer Certificates

1. Join the [Apple Developer Program](https://developer.apple.com/programs/)
2. In Xcode, go to **Preferences** → **Accounts**
3. Add your Apple ID and download certificates
4. Export your **Developer ID Application** certificate as `.p12`:
   - Open **Keychain Access**
   - Find your certificate under **My Certificates**
   - Right-click → Export → Save as `.p12`
   - Set a strong password

### Step 2: Set Up GitHub Secrets

Add these secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

```bash
# 1. MACOS_CERTIFICATE
# Convert .p12 to base64:
base64 -i certificate.p12 | pbcopy
# Paste the output as secret value

# 2. MACOS_CERTIFICATE_PASSWORD
# The password you set when exporting the .p12

# 3. APPLE_ID
# Your Apple ID email (e.g., developer@example.com)

# 4. APPLE_ID_PASSWORD
# Generate app-specific password:
# 1. Go to appleid.apple.com
# 2. Sign in → Security → App-Specific Passwords
# 3. Generate password and save it

# 5. APPLE_TEAM_ID
# Find at: https://developer.apple.com/account
# Under "Membership Details"
```

### Step 3: Enable Code Signing in Workflow

Edit `.github/workflows/release.yml` and uncomment the signing sections:

```yaml
# Around line 337-353: Uncomment this section
- name: Sign macOS application
  env:
    MACOS_CERTIFICATE: ${{ secrets.MACOS_CERTIFICATE }}
    MACOS_CERTIFICATE_PASSWORD: ${{ secrets.MACOS_CERTIFICATE_PASSWORD }}
  run: |
    # Import certificate
    echo $MACOS_CERTIFICATE | base64 --decode > certificate.p12
    security create-keychain -p actions temp.keychain
    security default-keychain -s temp.keychain
    security unlock-keychain -p actions temp.keychain
    security import certificate.p12 -k temp.keychain -P $MACOS_CERTIFICATE_PASSWORD -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions temp.keychain

    # Sign application
    /usr/bin/codesign --force -s "Developer ID Application" --options runtime \
      --entitlements "macos/Runner/Release.entitlements" \
      build/macos/Build/Products/Release/*.app -v

    # Verify signature
    codesign --verify --verbose build/macos/Build/Products/Release/*.app
    spctl --assess --verbose build/macos/Build/Products/Release/*.app

# Around line 378-388: Uncomment notarization
- name: Notarize macOS application
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_ID_PASSWORD: ${{ secrets.APPLE_ID_PASSWORD }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
  run: |
    # Create a ZIP for notarization
    ditto -c -k --sequesterRsrc --keepParent \
      build/macos/Build/Products/Release/*.app \
      app-for-notarization.zip

    # Upload for notarization
    xcrun notarytool submit app-for-notarization.zip \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_ID_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait

    # Staple the notarization ticket to the app
    xcrun stapler staple build/macos/Build/Products/Release/*.app
```

### Step 4: Test Locally

Before pushing to GitHub, test signing locally:

```bash
# 1. Build the app
flutter build macos --release

# 2. Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --entitlements "macos/Runner/Release.entitlements" \
  build/macos/Build/Products/Release/project_launcher.app

# 3. Verify signature
codesign --verify --verbose build/macos/Build/Products/Release/project_launcher.app
spctl --assess --verbose build/macos/Build/Products/Release/project_launcher.app

# 4. Create ZIP and notarize
ditto -c -k --sequesterRsrc --keepParent \
  build/macos/Build/Products/Release/project_launcher.app \
  project_launcher.zip

xcrun notarytool submit project_launcher.zip \
  --apple-id "your-apple-id@example.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# 5. Staple the ticket
xcrun stapler staple build/macos/Build/Products/Release/project_launcher.app

# 6. Verify notarization
spctl -a -vv -t install build/macos/Build/Products/Release/project_launcher.app
```

---

## Entitlements

The app requires hardened runtime entitlements. Ensure `macos/Runner/Release.entitlements` exists:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for app to run with hardened runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <!-- Add additional entitlements as needed for your app's functionality -->
</dict>
</plist>
```

---

## Troubleshooting

### "Certificate not found" error

Make sure you've exported the **Developer ID Application** certificate (not the iOS Development certificate).

### "Invalid signature" error

The app was modified after signing. Make sure to:
1. Sign the app
2. Don't modify any files
3. Create DMG/ZIP immediately after signing

### Notarization fails

Common reasons:
- App-specific password expired (generate a new one)
- Team ID incorrect (check developer.apple.com)
- App not signed with Developer ID Application certificate
- Missing hardened runtime entitlements

Check notarization log:
```bash
xcrun notarytool log SUBMISSION_ID \
  --apple-id "your-apple-id@example.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID"
```

### Gatekeeper still blocks signed app

1. Check signature:
   ```bash
   codesign -dv --verbose=4 project_launcher.app
   ```

2. Check notarization:
   ```bash
   spctl -a -vv -t install project_launcher.app
   ```

3. Staple ticket if not already:
   ```bash
   xcrun stapler staple project_launcher.app
   ```

---

## Distribution Options

### Option 1: Unsigned (Current)
- **Pros**: Free, no Apple account needed
- **Cons**: Users see security warning
- **Best for**: Open source, personal use, testing

### Option 2: Signed Only
- **Pros**: Verified developer identity
- **Cons**: Still shows warning (needs notarization too)
- **Cost**: $99/year

### Option 3: Signed + Notarized (Recommended for Production)
- **Pros**: No warnings, trusted by macOS
- **Cons**: Requires Apple Developer Account
- **Cost**: $99/year
- **Best for**: Public distribution, commercial apps

### Option 4: Mac App Store
- **Pros**: Maximum trust, automatic updates
- **Cons**: App Review required, sandboxing restrictions
- **Cost**: $99/year + 30% revenue share
- **Best for**: Consumer apps with broad distribution

---

## Resources

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Gatekeeper and Runtime Protection](https://support.apple.com/guide/security/gatekeeper-and-runtime-protection-sec5599b66df/web)

---

## Quick Reference

### User Instructions (Include in Release Notes)

```markdown
## macOS Installation

### First-Time Setup (Important!)

macOS will block the app because it's not signed with an Apple Developer certificate.

**To open the app:**
1. Right-click on project_launcher.app
2. Select "Open"
3. Click "Open" in the dialog

**Or via Terminal:**
```bash
xattr -cr /Applications/project_launcher.app
```

After the first time, you can open the app normally.
```

---

**Need help?** Open an issue at: https://github.com/your-repo/project_launcher/issues
