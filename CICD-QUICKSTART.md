# CI/CD Quick Start Guide

This guide will help you get started with the professional CI/CD pipelines for Project Launcher.

## 🚀 Quick Start

### Step 1: Verify Workflows

All workflows are located in `.github/workflows/`:
- ✅ `ci.yml` - Continuous Integration
- ✅ `release.yml` - Release Pipeline
- ✅ `version-bump.yml` - Version Management
- ✅ `security.yml` - Security Scanning

### Step 2: First Release

**Option A: Automated (Recommended)**

1. Go to GitHub Actions tab
2. Select "Version Bump" workflow
3. Click "Run workflow"
4. Choose bump type (patch/minor/major)
5. Click "Run workflow" button

The workflow will:
- Update version in `pubspec.yaml`
- Update `CHANGELOG.md`
- Create git tag
- Trigger release build automatically
- Create GitHub release with installers

**Option B: Manual**

```bash
# 1. Update version
# Edit pubspec.yaml: version: 1.0.0+1

# 2. Commit and push
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.0"
git push origin main

# 3. Create tag
git tag v1.0.0
git push origin v1.0.0

# 4. Wait for release workflow to complete
```

### Step 3: Monitor Release

1. Go to Actions tab
2. Watch "Release Pipeline" workflow
3. When complete, go to Releases page
4. Your release is ready with all installers!

---

## 📦 What Gets Built

### Linux
- `project_launcher-linux-x64.tar.gz` - Universal tarball
- `project_launcher-linux-x64.AppImage` - Portable app
- `project_launcher-linux-x64.deb` - Debian/Ubuntu
- `project_launcher-linux-x64.rpm` - Fedora/RHEL
- `project_launcher-linux-arm64.tar.gz` - ARM64

### macOS
- `project_launcher-macos-x64.zip` - Intel Macs
- `project_launcher-macos-arm64.zip` - Apple Silicon
- `project_launcher-macos-universal.zip` - Universal binary
- `project_launcher-macos-universal.dmg` - Installer

### Windows
- `project_launcher-windows-x64.zip` - Standard archive
- `project_launcher-windows-x64-installer.exe` - Installer
- `project_launcher-windows-arm64.zip` - ARM64

---

## 🔧 Configuration

### Optional: Code Signing

For production releases, configure code signing secrets:

**macOS Secrets:**
```
MACOS_CERTIFICATE
MACOS_CERTIFICATE_PASSWORD
APPLE_ID
APPLE_ID_PASSWORD
APPLE_TEAM_ID
```

**Windows Secrets:**
```
WINDOWS_CERTIFICATE
WINDOWS_CERTIFICATE_PASSWORD
```

Go to: Settings → Secrets and variables → Actions → New repository secret

---

## 📊 Continuous Integration

CI runs automatically on:
- Every push to `main` or `develop`
- Every pull request

**CI Checks:**
- ✓ Code formatting (`dart format`)
- ✓ Static analysis (`flutter analyze`)
- ✓ Unit & widget tests
- ✓ Code coverage
- ✓ Build verification (all platforms)

**View Results:**
- Check the green ✓ or red ✗ on commits
- Click "Details" to see logs
- PR comments show status

---

## 🔒 Security Scanning

Security scans run:
- On every push/PR
- Every Monday at 9 AM UTC
- On-demand via Actions tab

**Scans Include:**
- Dependency vulnerabilities
- Secret detection
- License compliance
- Static security analysis

**View Results:**
- Actions tab → Security Scanning
- Security tab → Dependabot/Code scanning

---

## 🛠️ Local Development

### Before Pushing

Run these commands locally to avoid CI failures:

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Test build
flutter build linux --release
# or
flutter build macos --release
# or
flutter build windows --release
```

### Build Installers Locally

Use the installer scripts:

**Linux:**
```bash
./scripts/installers/build-linux-packages.sh
```

**macOS:**
```bash
./scripts/installers/build-macos-dmg.sh
```

**Windows:**
```powershell
.\scripts\installers\build-windows-installer.ps1
```

Output in `dist/` directory.

---

## 📝 Version Management

### Semantic Versioning

Follow [SemVer](https://semver.org/):

- **Patch** (1.0.x): Bug fixes
  ```bash
  # 1.0.0 → 1.0.1
  bump_type: patch
  ```

- **Minor** (1.x.0): New features
  ```bash
  # 1.0.0 → 1.1.0
  bump_type: minor
  ```

- **Major** (x.0.0): Breaking changes
  ```bash
  # 1.0.0 → 2.0.0
  bump_type: major
  ```

### Prereleases

For beta/alpha releases:

```
bump_type: minor
prerelease: beta.1
Result: 1.1.0-beta.1
```

---

## 🎯 Common Workflows

### Bug Fix Release

```bash
# 1. Create branch
git checkout -b fix/bug-description

# 2. Fix bug and test
flutter test

# 3. Create PR
gh pr create --title "fix: bug description"

# 4. After merge, bump version
# Actions → Version Bump → patch

# 5. Release created automatically
```

### Feature Release

```bash
# 1. Create branch
git checkout -b feature/new-feature

# 2. Develop feature
# ... write code ...

# 3. Create PR
gh pr create --title "feat: new feature"

# 4. After merge, bump version
# Actions → Version Bump → minor

# 5. Release created automatically
```

### Hotfix

```bash
# 1. Create from main
git checkout -b hotfix/critical-fix

# 2. Fix issue
# ... write fix ...

# 3. Direct commit to main (if urgent)
git checkout main
git merge hotfix/critical-fix
git push

# 4. Immediate release
# Actions → Version Bump → patch
```

---

## 📈 Monitoring

### Check CI Status

- **All workflows**: Actions tab
- **Latest runs**: Actions tab → All workflows
- **Specific workflow**: Actions tab → Select workflow

### View Metrics

- **Coverage**: Codecov dashboard
- **Security**: Security tab
- **Dependencies**: Insights → Dependency graph

### Get Notifications

Enable notifications:
1. Watch repository (top right)
2. Settings → Notifications
3. Choose: Participating and @mentions

---

## 🚨 Troubleshooting

### CI Failing

**Check:**
1. Read error in Actions tab
2. Run locally: `dart format . && flutter analyze && flutter test`
3. Fix issues
4. Push again

### Release Not Creating

**Check:**
1. Tag format: Must be `v1.0.0` (lowercase v)
2. Tag pushed: `git push origin v1.0.0`
3. Workflow permissions: Settings → Actions → General → Workflow permissions

### Build Failing

**Check:**
1. Flutter version in workflows (currently 3.38.5)
2. Dependencies: `flutter pub get`
3. Platform-specific requirements (see installer scripts README)

---

## 📚 Documentation

Detailed documentation:
- **Workflows**: `.github/workflows/README.md`
- **Installer Scripts**: `scripts/installers/README.md`
- **Main README**: `README.md`

---

## 🎉 Success Checklist

After first release:
- [ ] Release appears in Releases page
- [ ] All installer files present
- [ ] Download and test installer
- [ ] Verify version number correct
- [ ] Check release notes

---

## 💡 Tips

1. **Always use version bump workflow** - Prevents errors
2. **Write good commit messages** - They appear in changelogs
3. **Test locally first** - Saves CI time
4. **Monitor security scans** - Fix issues promptly
5. **Update CHANGELOG.md** - After version bump
6. **Sign releases for production** - Adds trust

---

## 🔗 Quick Links

- [Actions Tab](../../actions)
- [Releases Page](../../releases)
- [Security Tab](../../security)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter Desktop Docs](https://docs.flutter.dev/desktop)

---

## 🆘 Need Help?

1. Check `.github/workflows/README.md`
2. Check `scripts/installers/README.md`
3. Review GitHub Actions logs
4. Search existing issues
5. Create new issue with details

---

**Happy Releasing! 🚀**
