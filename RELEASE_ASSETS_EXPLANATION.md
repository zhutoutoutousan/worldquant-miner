# Release Assets Explanation

## What Gets Attached to Releases

When you create a GitHub release, **two types of files** are included:

### 1. Built Executables (from GitHub Actions) ✅
These are the **main files** users should download:

- **Windows**: `generation-two-1.0.0-windows.exe` - Standalone executable
- **Linux**: `generation-two_1.0.0-1_all.deb` - Debian package
- **macOS**: `generation-two.dmg` - Disk image

These are built by the GitHub Actions workflow and automatically attached to the release.

### 2. Source Code Archive (automatic from GitHub) 📦
GitHub **automatically** includes:
- `Source code (zip)` - Full source code as ZIP
- `Source code (tar.gz)` - Full source code as TAR.GZ

**You cannot disable these** - GitHub always includes them for every release.

## How It Works

1. **You push a tag** (e.g., `v1.0.0`)
2. **GitHub Actions builds** the executables:
   - Windows: Builds `.exe` using PyInstaller
   - Linux: Builds `.deb` package
   - macOS: Builds `.dmg` disk image
3. **Workflow attaches executables** to the release
4. **GitHub automatically adds** source code archives

## What Users See

On the release page, users will see:

```
Assets (5)
├── generation-two-1.0.0-windows.exe  ← Download this for Windows
├── generation-two_1.0.0-1_all.deb     ← Download this for Linux
├── generation-two.dmg                 ← Download this for macOS
├── Source code (zip)                  ← Auto-included by GitHub
└── Source code (tar.gz)               ← Auto-included by GitHub
```

## The Workflow Configuration

The workflow file (`.github/workflows/release.yml`) is configured to:

1. **Build executables** on each platform
2. **Upload as artifacts** during build
3. **Download artifacts** in the release job
4. **Copy to `release-assets/`** directory
5. **Attach to release** using `files: release-assets/*`

This means the executables **will be attached** to the release automatically.

## If Executables Are Missing

If you see a release but no executables:

1. **Check GitHub Actions** - Did the builds complete successfully?
2. **Check build logs** - Look for errors in the build steps
3. **Verify artifacts** - Check if artifacts were uploaded
4. **Check release step** - See if the release creation succeeded

The workflow will fail if no executables are found (due to `fail_on_unmatched_files: true`).

## Summary

✅ **Executables are attached** by the workflow  
📦 **Source code is included** automatically by GitHub (can't be disabled)  
🎯 **Users should download the executables**, not the source code

The release contains **both** - but the executables are what end users need!
