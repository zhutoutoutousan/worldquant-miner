# Script to manually create a GitHub release from existing tag
# Useful if the workflow created the tag but didn't create the release

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [string]$Token = "",
    [switch]$CheckWorkflow
)

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Get GitHub repo info
$remoteUrl = git config --get remote.origin.url
if ($remoteUrl -match 'github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$') {
    $owner = $matches[1]
    $repo = $matches[2] -replace '\.git$', ''
} else {
    Write-ColorOutput Red "Could not determine GitHub repository from remote URL: $remoteUrl"
    exit 1
}

Write-ColorOutput Cyan "Repository: $owner/$repo"
Write-ColorOutput Cyan "Version: $Version"
Write-ColorOutput Cyan "Tag: v$Version"

# Get GitHub token
if ([string]::IsNullOrEmpty($Token)) {
    $Token = $env:GITHUB_TOKEN
    if ([string]::IsNullOrEmpty($Token)) {
        Write-ColorOutput Yellow "GitHub token not provided."
        Write-ColorOutput Yellow "Please provide a GitHub Personal Access Token with 'repo' scope:"
        Write-Host "  Create one at: https://github.com/settings/tokens"
        Write-Host "  Or set environment variable: `$env:GITHUB_TOKEN = 'your-token'"
        $Token = Read-Host "Enter GitHub token"
    }
}

if ([string]::IsNullOrEmpty($Token)) {
    Write-ColorOutput Red "GitHub token is required!"
    exit 1
}

$tagName = "v$Version"
$headers = @{
    "Authorization" = "token $Token"
    "Accept" = "application/vnd.github.v3+json"
}

# Check if tag exists locally first
Write-ColorOutput Cyan "`nChecking if tag exists..."
$localTag = git tag -l $tagName
if ($localTag) {
    Write-ColorOutput Green "✓ Tag $tagName exists locally"
} else {
    Write-ColorOutput Yellow "⚠️  Tag $tagName does not exist locally"
    $createTag = Read-Host "Create tag now? (y/n)"
    if ($createTag -eq "y") {
        git tag -a $tagName -m "Release version $Version"
        Write-ColorOutput Green "✓ Tag created locally"
    } else {
        Write-ColorOutput Red "Cannot proceed without tag"
        exit 1
    }
}

# Check if tag exists on GitHub
try {
    $tagResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/git/refs/tags/$tagName" -Headers $headers -Method Get
    Write-ColorOutput Green "✓ Tag $tagName exists on GitHub"
} catch {
    Write-ColorOutput Yellow "⚠️  Tag $tagName does not exist on GitHub"
    $pushTag = Read-Host "Push tag to GitHub now? (y/n)"
    if ($pushTag -eq "y") {
        git push origin $tagName
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput Green "✓ Tag pushed to GitHub"
            # Wait a moment for GitHub to process
            Start-Sleep -Seconds 2
        } else {
            Write-ColorOutput Red "❌ Failed to push tag!"
            exit 1
        }
    } else {
        Write-ColorOutput Red "Cannot create release without tag on GitHub"
        Write-ColorOutput Yellow "Push it manually with: git push origin $tagName"
        exit 1
    }
}

# Check if release already exists
Write-ColorOutput Cyan "Checking if release already exists..."
try {
    $releaseResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/tags/$tagName" -Headers $headers -Method Get
    Write-ColorOutput Yellow "⚠️  Release for tag $tagName already exists!"
    Write-Host "  URL: $($releaseResponse.html_url)"
    $overwrite = Read-Host "Delete and recreate? (y/n)"
    if ($overwrite -eq "y") {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/$($releaseResponse.id)" -Headers $headers -Method Delete
        Write-ColorOutput Green "✓ Existing release deleted"
    } else {
        exit 0
    }
} catch {
    Write-ColorOutput Green "✓ No existing release found (this is good)"
}

# Check workflow status if requested
if ($CheckWorkflow) {
    Write-ColorOutput Cyan "`nChecking workflow status..."
    try {
        $workflows = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/actions/runs" -Headers $headers -Method Get
        $latestRun = $workflows.workflow_runs | Where-Object { $_.name -eq "Build and Release" } | Select-Object -First 1
        if ($latestRun) {
            Write-Host "  Latest workflow run: $($latestRun.status) - $($latestRun.conclusion)"
            Write-Host "  URL: $($latestRun.html_url)"
            if ($latestRun.status -eq "completed" -and $latestRun.conclusion -eq "success") {
                Write-ColorOutput Green "✓ Workflow completed successfully"
            } elseif ($latestRun.status -eq "in_progress" -or $latestRun.status -eq "queued") {
                Write-ColorOutput Yellow "⚠️  Workflow is still running. Wait for it to complete."
            } else {
                Write-ColorOutput Yellow "⚠️  Workflow did not complete successfully"
            }
        }
    } catch {
        Write-ColorOutput Yellow "Could not check workflow status: $_"
    }
}

# Create release
Write-ColorOutput Cyan "`nCreating GitHub release..."

$releaseBody = @"
## Generation Two $Version

### Downloads
- **Windows**: `generation-two-$Version-windows.exe`
- **Linux**: `generation-two_*.deb` (Debian/Ubuntu package)
- **macOS**: `generation-two.dmg`

### Installation
1. Download the appropriate file for your platform
2. **Windows**: Run the `.exe` file
3. **Linux**: Install with `sudo dpkg -i generation-two_*.deb`
4. **macOS**: Open the `.dmg` file and drag the app to Applications

### Notes
- Credentials are NOT included. You must provide your own `credential.txt` file.
- See [README.md](generation_two/README.md) for usage instructions.
"@

$releaseData = @{
    tag_name = $tagName
    name = "Release $Version"
    body = $releaseBody
    draft = $false
    prerelease = $false
} | ConvertTo-Json

try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases" -Headers $headers -Method Post -Body $releaseData -ContentType "application/json"
    Write-ColorOutput Green "✓ Release created successfully!"
    Write-Host "  URL: $($release.html_url)"
    Write-ColorOutput Yellow "`nNote: This release is empty (no artifacts)."
    Write-ColorOutput Yellow "To add artifacts, either:"
    Write-Host "  1. Wait for GitHub Actions to complete and it will add them automatically"
    Write-Host "  2. Manually upload files via GitHub web interface"
    Write-Host "  3. Use GitHub CLI: gh release upload $tagName <files>"
} catch {
    Write-ColorOutput Red "❌ Failed to create release!"
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody"
    }
    exit 1
}

Write-ColorOutput Green @"

╔═══════════════════════════════════════════════════════════╗
║              Release Created Successfully!                ║
╚═══════════════════════════════════════════════════════════╝

Release URL: $($release.html_url)

Next steps:
1. Check GitHub Actions to see if builds are running
2. Once builds complete, artifacts will be added automatically
3. Or manually upload files to the release

"@
