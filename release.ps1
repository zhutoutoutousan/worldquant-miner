# Release Script for Generation Two
# Creates a version tag and triggers GitHub Actions release workflow

param(
    [string]$Version = "",
    [switch]$Patch,
    [switch]$Minor,
    [switch]$Major,
    [switch]$SkipVersionUpdate,
    [switch]$DryRun
)

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Get-CurrentVersion {
    $pyprojectPath = "generation_two\pyproject.toml"
    if (Test-Path $pyprojectPath) {
        $content = Get-Content $pyprojectPath -Raw
        if ($content -match 'version\s*=\s*"([^"]+)"') {
            return $matches[1]
        }
    }
    return "1.0.0"
}

function Update-VersionFiles($Version) {
    Write-ColorOutput Cyan "Updating version files..."
    
    # Update pyproject.toml
    $pyprojectPath = "generation_two\pyproject.toml"
    if (Test-Path $pyprojectPath) {
        $content = Get-Content $pyprojectPath -Raw
        $content = $content -replace 'version\s*=\s*"[^"]+"', "version = `"$Version`""
        Set-Content $pyprojectPath $content -NoNewline
        Write-ColorOutput Green "  ✓ Updated pyproject.toml"
    }
    
    # Update setup.py
    $setupPath = "generation_two\setup.py"
    if (Test-Path $setupPath) {
        $content = Get-Content $setupPath -Raw
        $content = $content -replace 'version\s*=\s*"[^"]+"', "version=`"$Version`""
        Set-Content $setupPath $content -NoNewline
        Write-ColorOutput Green "  ✓ Updated setup.py"
    }
}

function Increment-Version($CurrentVersion, $Type) {
    $parts = $CurrentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    
    switch ($Type) {
        "major" { 
            $major++
            $minor = 0
            $patch = 0
        }
        "minor" { 
            $minor++
            $patch = 0
        }
        "patch" { 
            $patch++
        }
    }
    
    return "$major.$minor.$patch"
}

function Get-LatestTag {
    $tags = git tag -l "v*" | Sort-Object { [version]($_ -replace '^v', '') } -Descending
    if ($tags) {
        return $tags[0]
    }
    return $null
}

function Test-VersionFormat($Version) {
    return $Version -match '^\d+\.\d+\.\d+$'
}

# Main script
Write-ColorOutput Cyan @"
╔═══════════════════════════════════════════════════════════╗
║         Generation Two Release Script                     ║
╚═══════════════════════════════════════════════════════════╝
"@

# Get current version
$currentVersion = Get-CurrentVersion
Write-ColorOutput Yellow "Current version: $currentVersion"

# Determine new version
$newVersion = $Version

if ([string]::IsNullOrEmpty($newVersion)) {
    if ($Patch) {
        $newVersion = Increment-Version $currentVersion "patch"
        Write-ColorOutput Cyan "Incrementing patch version..."
    }
    elseif ($Minor) {
        $newVersion = Increment-Version $currentVersion "minor"
        Write-ColorOutput Cyan "Incrementing minor version..."
    }
    elseif ($Major) {
        $newVersion = Increment-Version $currentVersion "major"
        Write-ColorOutput Cyan "Incrementing major version..."
    }
    else {
        # Ask user
        Write-Host "`nVersion options:"
        Write-Host "  1. Patch increment ($currentVersion -> $(Increment-Version $currentVersion 'patch'))"
        Write-Host "  2. Minor increment ($currentVersion -> $(Increment-Version $currentVersion 'minor'))"
        Write-Host "  3. Major increment ($currentVersion -> $(Increment-Version $currentVersion 'major'))"
        Write-Host "  4. Custom version"
        
        $choice = Read-Host "`nSelect option (1-4)"
        
        switch ($choice) {
            "1" { $newVersion = Increment-Version $currentVersion "patch" }
            "2" { $newVersion = Increment-Version $currentVersion "minor" }
            "3" { $newVersion = Increment-Version $currentVersion "major" }
            "4" { 
                do {
                    $newVersion = Read-Host "Enter version (format: X.Y.Z)"
                    if (-not (Test-VersionFormat $newVersion)) {
                        Write-ColorOutput Red "Invalid version format. Use X.Y.Z (e.g., 1.0.0)"
                    }
                } while (-not (Test-VersionFormat $newVersion))
            }
            default { 
                Write-ColorOutput Red "Invalid choice. Exiting."
                exit 1
            }
        }
    }
}

# Validate version format
if (-not (Test-VersionFormat $newVersion)) {
    Write-ColorOutput Red "Invalid version format: $newVersion. Use X.Y.Z format (e.g., 1.0.0)"
    exit 1
}

Write-ColorOutput Green "`nNew version: $newVersion"

# Check if tag already exists
$tagName = "v$newVersion"
$existingTag = git tag -l $tagName
if ($existingTag) {
    Write-ColorOutput Red "`nTag $tagName already exists!"
    $overwrite = Read-Host "Delete and recreate? (y/n)"
    if ($overwrite -eq "y") {
        git tag -d $tagName
        git push origin :refs/tags/$tagName 2>$null
    } else {
        Write-ColorOutput Yellow "Exiting without creating release."
        exit 1
    }
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status -and -not $SkipVersionUpdate) {
    Write-ColorOutput Yellow "`nWarning: You have uncommitted changes:"
    git status --short
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Update version files
if (-not $SkipVersionUpdate) {
    if ($newVersion -ne $currentVersion) {
        Update-VersionFiles $newVersion
        
        # Ask to commit version update
        $commitVersion = Read-Host "`nCommit version update? (y/n)"
        if ($commitVersion -eq "y") {
            git add generation_two\pyproject.toml generation_two\setup.py
            git commit -m "Bump version to $newVersion"
            Write-ColorOutput Green "✓ Version files committed"
        }
    }
}

# Show what will happen
Write-ColorOutput Cyan "`nRelease Summary:"
Write-Host "  Version: $newVersion"
Write-Host "  Tag: $tagName"
Write-Host "  Current branch: $(git branch --show-current)"

if ($DryRun) {
    Write-ColorOutput Yellow "`n[DRY RUN] Would execute:"
    Write-Host "  git tag -a $tagName -m `"Release version $newVersion`""
    Write-Host "  git push origin $tagName"
    Write-Host "  git push origin $(git branch --show-current)"
    exit 0
}

# Confirm
Write-ColorOutput Yellow "`nThis will:"
Write-Host "  1. Create tag: $tagName"
Write-Host "  2. Push tag to origin (triggers GitHub Actions)"
if (-not $SkipVersionUpdate -and $newVersion -ne $currentVersion) {
    Write-Host "  3. Push version commit (if committed)"
}
$confirm = Read-Host "`nProceed? (y/n)"

if ($confirm -ne "y") {
    Write-ColorOutput Yellow "Release cancelled."
    exit 0
}

# Create and push tag
Write-ColorOutput Cyan "`nCreating tag..."
git tag -a $tagName -m "Release version $newVersion"
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "Failed to create tag!"
    exit 1
}
Write-ColorOutput Green "✓ Tag created: $tagName"

# Push tag
Write-ColorOutput Cyan "Pushing tag to origin..."
git push origin $tagName
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "Failed to push tag!"
    exit 1
}
Write-ColorOutput Green "✓ Tag pushed to origin"

# Push current branch if version was updated
if (-not $SkipVersionUpdate -and $newVersion -ne $currentVersion) {
    $currentBranch = git branch --show-current
    $pushBranch = Read-Host "`nPush branch '$currentBranch' to origin? (y/n)"
    if ($pushBranch -eq "y") {
        git push origin $currentBranch
        Write-ColorOutput Green "✓ Branch pushed"
    }
}

# Success message
Write-ColorOutput Green @"

╔═══════════════════════════════════════════════════════════╗
║                    Release Created!                       ║
╚═══════════════════════════════════════════════════════════╝

Version: $newVersion
Tag: $tagName

GitHub Actions will now:
  ✓ Build Windows EXE
  ✓ Build Linux DEB
  ✓ Build macOS DMG
  ✓ Create GitHub Release

Monitor progress at:
  https://github.com/$(git config --get remote.origin.url -replace '.*[:/]([^/]+/[^/]+?)(?:\.git)?$', '$1')/actions

"@
