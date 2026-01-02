# Fix: Tag Created But No Release

If you created a tag but no GitHub release was created, here's how to fix it:

## Quick Fix

### Option 1: Use the Script (Easiest)

**Windows:**
```powershell
.\create_release.ps1 -Version 1.0.0
```

**Linux/Mac:**
```bash
chmod +x create_release.sh
./create_release.sh --version 1.0.0
```

The script will:
- Check if the tag exists
- Create the GitHub release
- Show you the release URL

### Option 2: Manual via GitHub Web

1. Go to your GitHub repository
2. Click **Releases** → **Draft a new release**
3. Select the tag (e.g., `v1.0.0`)
4. Fill in release title and description
5. Click **Publish release**

### Option 3: Check GitHub Actions

The release might be created automatically when builds complete:

1. Go to **Actions** tab
2. Find the "Build and Release" workflow
3. Check if it's still running or completed
4. If it failed, check the logs

## Why This Happens

1. **Workflow didn't trigger**: Tag pattern might not match
2. **Workflow is still running**: Release is created after all builds complete
3. **Workflow failed**: Check Actions logs for errors
4. **Permissions issue**: GitHub token might not have write access

## Verify Tag Exists

```bash
# Check local tags
git tag -l "v*"

# Check remote tags
git ls-remote --tags origin

# If tag doesn't exist remotely, push it:
git push origin v1.0.0
```

## Verify Workflow Triggered

1. Go to GitHub → **Actions**
2. Look for "Build and Release" workflow
3. Check if it ran when you pushed the tag
4. If not, the workflow might not be in the repository yet

## Create Release Script Usage

### Windows PowerShell

```powershell
# Basic usage
.\create_release.ps1 -Version 1.0.0

# With GitHub token (if not in environment)
$env:GITHUB_TOKEN = "your-token-here"
.\create_release.ps1 -Version 1.0.0

# Check workflow status too
.\create_release.ps1 -Version 1.0.0 -CheckWorkflow
```

### Linux/Mac Bash

```bash
# Basic usage
./create_release.sh --version 1.0.0

# With GitHub token
export GITHUB_TOKEN="your-token-here"
./create_release.sh --version 1.0.0

# Check workflow status too
./create_release.sh --version 1.0.0 --check-workflow
```

## Get GitHub Token

1. Go to https://github.com/settings/tokens
2. Click **Generate new token (classic)**
3. Select scope: **repo** (full control of private repositories)
4. Generate and copy the token
5. Use it with the script or set as environment variable:
   ```powershell
   $env:GITHUB_TOKEN = "your-token"
   ```

## Troubleshooting

### "Tag does not exist"
- Make sure you pushed the tag: `git push origin v1.0.0`
- Check tag name format: should be `v1.0.0` not `1.0.0`

### "Release already exists"
- The script will ask if you want to overwrite
- Or delete it manually on GitHub first

### "Authentication failed"
- Check your GitHub token is valid
- Make sure token has `repo` scope
- Token might have expired

### "Workflow not running"
- Check `.github/workflows/release.yml` exists in repository
- Verify workflow is committed and pushed
- Check Actions are enabled in repository settings

## Prevention

The updated `release.ps1` script now:
- Offers to create release immediately after tagging
- Shows workflow status
- Provides better feedback

Just run:
```powershell
.\release.ps1 --patch
```

And when prompted, say `y` to create the release immediately!
