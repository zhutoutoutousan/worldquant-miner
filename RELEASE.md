# How to Create Releases

Create GitHub releases with built executables (.exe, .deb, .dmg) for all platforms.

## Quick Start

### Use the Release Script (Recommended)

**Windows:**
```powershell
.\release.ps1 --patch    # 1.0.0 -> 1.0.1
```

**Linux/Mac:**
```bash
./release.sh --patch
```

The script will:
1. Read current version from `pyproject.toml`
2. Update version files automatically
3. Create and push a Git tag
4. Trigger GitHub Actions to build and release

### Manual Method

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically build for all platforms and create a release.

## What Gets Built

- **Windows**: `generation-two-1.0.0-windows.exe`
- **Linux**: `generation-two_1.0.0-1_all.deb`
- **macOS**: `generation-two.dmg`

All files are automatically attached to the GitHub Release.

## Troubleshooting

### Release Not Created

If you created a tag but no release appeared:

```powershell
.\create_release.ps1 -Version 1.0.0
```

### Build Fails

1. Check **Actions** tab for error logs
2. Verify `generation_two/constants/operatorRAW.json` exists in the repository
3. Test locally first: `cd generation_two && python build.py --exe`

---

**That's it!** Run `.\release.ps1 --patch` to create a new release.
