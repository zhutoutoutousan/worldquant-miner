# How GitHub Actions Uses Workflow Files

## Important: Workflow File Location

**GitHub Actions uses the workflow file from the branch that triggers the workflow.**

For tag-based triggers:
- Uses the workflow from the **branch the tag points to**
- Or from the **default branch** (master) if tag doesn't exist yet

## Your Workflow (develop → master)

Since you work on `develop` and merge to `master`:

### Step 1: Update develop branch
```powershell
# Make your changes on develop
git checkout develop
git add .
git commit -m "Update workflow and build scripts"
git push origin develop
```

### Step 2: Merge to master
```powershell
# Merge develop into master
git checkout master
git merge develop
git push origin master
```

### Step 3: Create release tag from master
```powershell
# Create tag from master (so it uses master's workflow)
git tag v1.0.0
git push origin v1.0.0
```

## Why This Matters

If you create a tag from `develop` before merging to `master`:
- The tag points to a commit on `develop`
- GitHub Actions uses the workflow from `develop`
- But if `develop` doesn't have the latest workflow, it uses an old version

**Solution:** Always merge to `master` first, then create tags from `master`.

## Quick Checklist

Before creating a release:
- [ ] All changes committed to `develop`
- [ ] `develop` merged to `master`
- [ ] `master` pushed to GitHub
- [ ] Create tag from `master` branch
- [ ] Push tag to trigger workflow

## Alternative: Use workflow_dispatch

You can also manually trigger the workflow from GitHub UI:
1. Go to **Actions** → **Build and Release**
2. Click **Run workflow**
3. Select `master` branch
4. Enter version number
5. Click **Run workflow**

This uses the workflow from `master` branch directly.
