# Release Script Usage Guide

## 🚀 Quick Start

The release script automates creating GitHub releases. It:
- Reads current version from `pyproject.toml`
- Updates version files automatically
- Creates and pushes a Git tag
- Triggers GitHub Actions to build and release

## Windows (PowerShell)

### Basic Usage
```powershell
.\release.ps1
```

The script will:
1. Show current version
2. Ask you to choose: patch, minor, major, or custom version
3. Update version files (pyproject.toml, setup.py)
4. Create and push the tag
5. Trigger GitHub Actions

### Auto-Increment Options
```powershell
# Patch version (1.0.0 -> 1.0.1)
.\release.ps1 --patch

# Minor version (1.0.0 -> 1.1.0)
.\release.ps1 --minor

# Major version (1.0.0 -> 2.0.0)
.\release.ps1 --major

# Custom version
.\release.ps1 --version "1.2.3"
```

### Advanced Options
```powershell
# Skip updating version files
.\release.ps1 --patch --SkipVersionUpdate

# Dry run (see what would happen without doing it)
.\release.ps1 --patch --DryRun
```

## Linux/Mac (Bash)

### Basic Usage
```bash
chmod +x release.sh
./release.sh
```

### Auto-Increment Options
```bash
# Patch version
./release.sh --patch

# Minor version
./release.sh --minor

# Major version
./release.sh --major

# Custom version
./release.sh --version "1.2.3"
```

### Advanced Options
```bash
# Skip updating version files
./release.sh --patch --skip-version-update

# Dry run
./release.sh --patch --dry-run
```

## Examples

### Example 1: Quick Patch Release
```powershell
# You just fixed a bug, want to release 1.0.0 -> 1.0.1
.\release.ps1 --patch
```

### Example 2: Feature Release
```powershell
# Added new features, want to release 1.0.0 -> 1.1.0
.\release.ps1 --minor
```

### Example 3: Major Release
```powershell
# Breaking changes, want to release 1.0.0 -> 2.0.0
.\release.ps1 --major
```

### Example 4: Custom Version
```powershell
# Release a specific version
.\release.ps1 --version "1.5.2"
```

## What Happens

1. **Version Detection**: Reads current version from `generation_two/pyproject.toml`
2. **Version Update**: Updates `pyproject.toml` and `setup.py` (optional)
3. **Tag Creation**: Creates Git tag `v{version}` (e.g., `v1.0.0`)
4. **Tag Push**: Pushes tag to GitHub
5. **GitHub Actions**: Automatically triggers build workflow
6. **Release**: GitHub Actions builds and creates release

## Workflow

```
┌─────────────────┐
│  release.ps1    │
└────────┬────────┘
         │
         ├─> Read current version
         ├─> Determine new version
         ├─> Update version files
         ├─> Create Git tag
         ├─> Push tag to GitHub
         │
         └─> GitHub Actions triggered
              │
              ├─> Build Windows EXE
              ├─> Build Linux DEB
              ├─> Build macOS DMG
              └─> Create GitHub Release
```

## Troubleshooting

### "Tag already exists"
The script will ask if you want to delete and recreate it. Say `y` to overwrite.

### "Uncommitted changes"
The script will warn you. You can:
- Commit changes first
- Use `--SkipVersionUpdate` to skip version file updates
- Continue anyway (not recommended)

### "Failed to push tag"
- Check you have push permissions
- Verify remote is set: `git remote -v`
- Check network connection

### Script doesn't run
**Windows:**
```powershell
# If you get execution policy error:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Linux/Mac:**
```bash
# Make sure it's executable:
chmod +x release.sh
```

## Tips

1. **Test First**: Use `--DryRun` to see what would happen
2. **Check Status**: Make sure you're on the right branch
3. **Monitor Progress**: After running, check GitHub Actions tab
4. **Version Format**: Must be X.Y.Z (e.g., 1.0.0, 2.1.3)

## Integration with fast_commit.ps1

You can combine both scripts:

```powershell
# 1. Commit your changes
.\fast_commit.ps1

# 2. Create a release
.\release.ps1 --patch
```

## Next Steps

After running the script:
1. Go to GitHub → **Actions** tab
2. Watch the workflow run (~10-15 minutes)
3. Check **Releases** tab when complete
4. Download and test the artifacts

---

**That's it! The script handles everything for you.** 🎉
