# Quick Release Guide 🚀

## TL;DR - How to Release

### Method 1: Use Release Script (Easiest! ⭐)
```powershell
# Windows PowerShell
.\release.ps1

# Or with auto-increment
.\release.ps1 --patch    # 1.0.0 -> 1.0.1
.\release.ps1 --minor    # 1.0.0 -> 1.1.0
.\release.ps1 --major    # 1.0.0 -> 2.0.0
```

```bash
# Linux/Mac
chmod +x release.sh
./release.sh

# Or with auto-increment
./release.sh --patch
./release.sh --minor
./release.sh --major
```

### Method 2: Manual Tag-Based Release
```bash
# 1. Commit your changes
git add .
git commit -m "Ready for release"

# 2. Create and push a version tag
git tag v1.0.0
git push origin v1.0.0

# 3. GitHub Actions will automatically build and release!
```

### Method 2: Manual Release
1. Go to GitHub → **Actions** → **Build and Release**
2. Click **Run workflow**
3. Enter version (e.g., `1.0.0`)
4. Click **Run workflow**
5. Wait ~10-15 minutes for builds to complete

## What Gets Built

- ✅ **Windows**: `generation-two-1.0.0-windows.exe`
- ✅ **Linux**: `generation-two_1.0.0-1_all.deb`
- ✅ **macOS**: `generation-two.dmg`

## Where to Find Releases

GitHub → **Releases** → Latest release

All files are automatically attached and ready to download!

## Files Created

- `.github/workflows/release.yml` - GitHub Actions workflow
- `RELEASE_GUIDE.md` - Detailed documentation
- `generation_two/build.py` - Updated build script (CI-friendly)

## Next Steps

1. **Test locally first** (optional):
   ```bash
   cd generation_two
   python build.py --exe  # or --deb, --dmg
   ```

2. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Add release automation"
   git push origin main
   ```

3. **Create your first release**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **Monitor progress**:
   - Go to **Actions** tab
   - Watch the workflow run
   - Check **Releases** when done

## Troubleshooting

**Build fails?**
- Check Actions logs
- Verify `requirements.txt` is complete
- Test build locally first

**Release not created?**
- Ensure all 3 builds succeeded
- Check you have release permissions
- Verify tag format: `v1.0.0` (not `1.0.0`)

---

For detailed information, see [RELEASE_GUIDE.md](RELEASE_GUIDE.md)
