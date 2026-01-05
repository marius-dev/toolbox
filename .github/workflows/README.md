# GitHub Actions Workflows Documentation

This directory contains professional CI/CD workflows for Project Launcher.

## Overview

Our CI/CD pipeline consists of four main workflows:

1. **CI (Continuous Integration)** - Code quality and testing
2. **Release** - Build and publish releases with installers
3. **Version Bump** - Automated version management
4. **Security** - Security scanning and compliance

## Workflows

### 1. CI Workflow (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger via workflow_dispatch

**Jobs:**

#### Analyze
- Code formatting verification (`dart format`)
- Static analysis (`flutter analyze`)
- Dependency checks
- Runs on: Ubuntu latest

#### Test
- Unit and widget tests
- Code coverage generation
- Coverage upload to Codecov
- Coverage threshold checking
- Runs on: Ubuntu latest

#### Build Verification
- Builds for all platforms:
  - Linux (x64)
  - macOS (universal)
  - Windows (x64)
- Verifies build outputs
- Runs on: Platform-specific runners

#### CI Success
- Summary job that checks all previous jobs
- Posts PR comments (on pull requests)
- Fails if any CI job fails

**Usage:**
```bash
# Automatically runs on push/PR
# Or manually trigger from GitHub Actions UI
```

---

### 2. Release Workflow (`release.yml`)

**Triggers:**
- Git tags matching `v*.*.*` (e.g., v1.0.0)
- Manual trigger with version input

**Jobs:**

#### Validate
- Validates version format
- Determines if prerelease (alpha/beta/rc)
- Outputs version information

#### Changelog
- Generates changelog from git commits
- Compares with previous release
- Creates formatted release notes

#### Build Linux
- Builds for x64 and ARM64
- Creates multiple package formats:
  - `.tar.gz` - Universal tarball
  - `.AppImage` - Portable executable
  - `.deb` - Debian/Ubuntu package
  - `.rpm` - Fedora/RHEL package

#### Build macOS
- Builds for Intel (x64), Apple Silicon (ARM64), and Universal
- Creates:
  - `.zip` - Application archive
  - `.dmg` - Installer disk image
- Optional code signing and notarization

#### Build Windows
- Builds for x64 and ARM64
- Creates:
  - `.zip` - Standard archive
  - `.exe` - Inno Setup installer
  - Portable version

#### Create Release
- Collects all artifacts
- Creates GitHub release
- Uploads all installers
- Generates release notes

**Usage:**

```bash
# Option 1: Create and push a tag
git tag v1.0.0
git push origin v1.0.0

# Option 2: Use version-bump workflow (recommended)
# See Version Bump section below

# Option 3: Manual trigger from GitHub Actions UI
# Actions → Release Pipeline → Run workflow
# Enter version: v1.0.0
```

**Release Artifacts:**

Linux (x64):
- `project_launcher-{version}-linux-x64.tar.gz`
- `project_launcher-{version}-linux-x64.AppImage`
- `project-launcher-{version}-linux-x64.deb` (note: package name uses hyphens for Debian compliance)
- `project-launcher-{version}-linux-x64.rpm` (note: package name uses hyphens for RPM compliance)

macOS (Universal - Intel & Apple Silicon):
- `project_launcher-{version}-macos-universal.zip`
- `project_launcher-{version}-macos-universal.dmg`

Windows (x64):
- `project_launcher-{version}-windows-x64.zip`
- `project_launcher-{version}-windows-x64-installer.exe`

**Notes**:
- **ARM64 builds** for Linux and Windows are not available because:
  1. GitHub Actions provides x64 runners only (no ARM64 runners in free tier)
  2. Flutter desktop doesn't support cross-compilation via `--target-platform`
  3. macOS universal binaries include both x64 and ARM64 architectures

- **Package naming**: DEB and RPM packages use `project-launcher` (with hyphens) instead of `project_launcher` (with underscores) to comply with Debian package naming policy. Debian package names must only contain lowercase letters, digits, hyphens, plus signs, and periods. The application binary and directories still use `project_launcher` with underscores.

---

### 3. Version Bump Workflow (`version-bump.yml`)

**Triggers:**
- Manual trigger only (workflow_dispatch)

**Inputs:**
- `bump_type`: patch, minor, or major
- `prerelease`: Optional prerelease identifier (alpha, beta, rc)

**Process:**
1. Reads current version from `pubspec.yaml`
2. Calculates new version based on bump type
3. Updates `pubspec.yaml`
4. Updates `CHANGELOG.md` with new version entry
5. Commits changes to main branch
6. Creates and pushes git tag
7. Triggers release workflow automatically

**Usage:**

```bash
# Via GitHub Actions UI:
# 1. Go to Actions → Version Bump → Run workflow
# 2. Select bump type: patch (1.0.0 → 1.0.1)
#                      minor (1.0.0 → 1.1.0)
#                      major (1.0.0 → 2.0.0)
# 3. Optional: Enter prerelease (e.g., "beta.1" → 1.1.0-beta.1)
# 4. Click "Run workflow"
```

**Versioning Scheme:**
- Format: `MAJOR.MINOR.PATCH[-PRERELEASE]+BUILD`
- Examples:
  - `1.0.0+1` - Stable release
  - `1.0.1-beta.1+2` - Beta prerelease
  - `2.0.0-rc.1+5` - Release candidate

**After Running:**
1. Workflow commits version changes
2. Creates git tag (e.g., `v1.0.1`)
3. Tag push triggers release workflow
4. Release workflow builds and publishes installers

---

### 4. Security Workflow (`security.yml`)

**Triggers:**
- Push to `main` or `develop`
- Pull requests
- Weekly schedule (Mondays at 9 AM UTC)
- Manual trigger

**Jobs:**

#### Dependency Check
- Scans for vulnerable dependencies
- Runs `flutter pub outdated`
- Checks for security advisories
- Generates dependency graph

#### SAST Scan (Static Application Security Testing)
- Security-focused code analysis
- Searches for hardcoded secrets
- Checks for SQL injection risks
- Identifies insecure random usage
- Scans for sensitive files

#### CodeQL Analysis
- Advanced security scanning
- Detects common vulnerabilities
- Tracks security issues over time

#### License Check
- Verifies dependency licenses
- Checks for GPL/AGPL conflicts
- Generates license report

#### Secret Scan
- TruffleHog secret scanning
- Gitleaks secret detection
- Prevents credential leaks

#### Security Summary
- Aggregates all scan results
- Provides recommendations
- Fails if critical issues found

**Usage:**
```bash
# Automatically runs on push/PR and weekly
# Or manually trigger for immediate scan
```

---

## Setup Instructions

### 1. Repository Secrets

Configure these secrets in GitHub Settings → Secrets and variables → Actions:

#### Required:
- `GITHUB_TOKEN` - Automatically provided by GitHub

#### Optional (for code signing):

**macOS:**
```
MACOS_CERTIFICATE - Base64 encoded .p12 certificate
MACOS_CERTIFICATE_PASSWORD - Certificate password
APPLE_ID - Apple Developer ID email
APPLE_ID_PASSWORD - App-specific password
APPLE_TEAM_ID - Team ID
```

**Windows:**
```
WINDOWS_CERTIFICATE - Base64 encoded .pfx certificate
WINDOWS_CERTIFICATE_PASSWORD - Certificate password
```

#### Optional (for enhanced features):
```
CODECOV_TOKEN - Codecov API token for coverage tracking
```

### 2. Branch Protection

Configure branch protection for `main`:

1. Go to Settings → Branches → Branch protection rules
2. Add rule for `main`:
   - ✓ Require status checks to pass before merging
   - Select required checks:
     - Code Analysis & Formatting
     - Unit & Widget Tests
     - Build Check (all platforms)
   - ✓ Require branches to be up to date before merging
   - ✓ Require linear history (optional)

### 3. Enable GitHub Features

- **Actions**: Enabled by default
- **Discussions**: For community engagement
- **Security**:
  - Enable Dependabot alerts
  - Enable Dependabot security updates
  - Enable Code scanning (CodeQL)
  - Enable Secret scanning

---

## Common Tasks

### Creating a New Release

**Recommended Method (Using Version Bump):**

```bash
# 1. Ensure main branch is clean and up to date
git checkout main
git pull origin main

# 2. Trigger version bump workflow via GitHub UI
# Actions → Version Bump → Run workflow
# Select bump type and click "Run workflow"

# 3. Workflow will:
#    - Update version in pubspec.yaml
#    - Update CHANGELOG.md
#    - Create git tag
#    - Trigger release workflow

# 4. Monitor release progress in Actions tab

# 5. Release will appear in Releases page with all installers
```

**Manual Method:**

```bash
# 1. Update version in pubspec.yaml
version: 1.0.1+2

# 2. Update CHANGELOG.md with changes

# 3. Commit changes
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 1.0.1"
git push origin main

# 4. Create and push tag
git tag v1.0.1
git push origin v1.0.1

# 5. Release workflow triggers automatically
```

### Creating a Prerelease

```bash
# Via version bump workflow:
# - Bump type: minor (or patch/major)
# - Prerelease: beta.1
# Results in: v1.1.0-beta.1

# The release will be marked as prerelease automatically
```

### Running CI Locally

```bash
# Install act (https://github.com/nektos/act)
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run CI locally
act -j analyze
act -j test
act -j build-verification
```

### Fixing Failed CI

```bash
# 1. Check the failure in Actions tab
# 2. Fix the issue locally
# 3. Commit and push fixes

# For formatting issues:
dart format .

# For analysis issues:
flutter analyze

# For test failures:
flutter test

# For build issues:
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

---

## Workflow Triggers Summary

| Workflow | Push (main) | Push (develop) | PR | Tag | Schedule | Manual |
|----------|-------------|----------------|----|----|----------|--------|
| CI | ✓ | ✓ | ✓ | - | - | ✓ |
| Release | - | - | - | ✓ | - | ✓ |
| Version Bump | - | - | - | - | - | ✓ |
| Security | ✓ | ✓ | ✓ | - | Weekly | ✓ |

---

## Best Practices

### 1. Development Workflow

```bash
# Feature development
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature
# Create PR → CI runs → Review → Merge

# After merge to main
# Use version bump workflow for release
```

### 2. Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new feature
fix: resolve bug
docs: update documentation
chore: update dependencies
refactor: restructure code
test: add tests
ci: update workflows
```

### 3. Version Strategy

- **Patch** (1.0.x): Bug fixes, minor changes
- **Minor** (1.x.0): New features, backwards compatible
- **Major** (x.0.0): Breaking changes

### 4. Security

- Never commit secrets or credentials
- Review security scan results weekly
- Keep dependencies up to date
- Sign releases for production

### 5. Testing

- Write tests for new features
- Maintain >80% code coverage
- Test on all platforms before release

---

## Troubleshooting

### Workflow Not Triggering

**Issue:** Workflow doesn't run after push/tag

**Solutions:**
1. Check if Actions are enabled: Settings → Actions → General
2. Verify workflow syntax: `yamllint .github/workflows/*.yml`
3. Check branch/tag name matches trigger pattern
4. Ensure you have push permissions

### Build Failures

**Issue:** Platform build fails

**Linux:**
```bash
# Install missing dependencies
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev libkeybinder-3.0-dev \
  libayatana-appindicator3-dev
```
**Note**: `libkeybinder-3.0-dev` is required for hotkey_manager, `libayatana-appindicator3-dev` for tray_manager

**macOS:**
```bash
# Update Flutter and Xcode
flutter upgrade
sudo xcode-select --switch /Applications/Xcode.app
```

**Windows:**
```powershell
# Update Visual Studio
# Ensure Windows SDK is installed
```

### Code Signing Issues

**macOS:**
- Verify certificate is valid: `security find-identity -v -p codesigning`
- Check expiration date
- Ensure correct Team ID

**Windows:**
- Verify certificate format (PFX)
- Check timestamp server is accessible
- Ensure certificate is trusted

### Release Upload Failures

**Issue:** Artifacts not uploading to release

**Solutions:**
1. Check `GITHUB_TOKEN` permissions
2. Verify artifact paths are correct
3. Ensure files were created in build jobs
4. Check workflow dependencies (needs: [jobs])

---

## Monitoring and Metrics

### GitHub Actions Dashboard

View workflow runs:
- **Actions tab**: See all workflow runs
- **Insights → Actions**: View usage and performance
- **Pull request checks**: See CI status

### Coverage Reports

- View in Codecov dashboard
- Check trend over time
- Identify uncovered code

### Security Alerts

- **Security tab**: View Dependabot alerts
- **Code scanning**: View CodeQL findings
- **Secret scanning**: View leaked credentials

---

## Future Enhancements

Potential improvements to consider:

1. **Auto-merge** - Automatically merge approved PRs
2. **Performance testing** - Add benchmark workflows
3. **Deployment** - Auto-deploy to Snapcraft, Flathub, etc.
4. **Slack/Discord notifications** - Post release announcements
5. **Automated changelog** - Generate from conventional commits
6. **Matrix testing** - Test on multiple Flutter versions
7. **Integration tests** - Add E2E testing workflow

---

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Code Signing Guide](https://docs.flutter.dev/deployment/macos#codesigning)

---

## Support

For issues with workflows:
1. Check this documentation
2. Review workflow run logs in Actions tab
3. Search existing GitHub Issues
4. Create new issue with:
   - Workflow name
   - Error message
   - Steps to reproduce

---

**Last Updated:** 2026-01-04
**Maintained By:** Project Launcher Team
