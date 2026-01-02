#!/bin/bash
# Script to manually create a GitHub release from existing tag
# Useful if the workflow created the tag but didn't create the release

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
VERSION=""
TOKEN=""
CHECK_WORKFLOW=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            VERSION="$2"
            shift 2
            ;;
        --token|-t)
            TOKEN="$2"
            shift 2
            ;;
        --check-workflow)
            CHECK_WORKFLOW=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 --version VERSION [--token TOKEN] [--check-workflow]"
            exit 1
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo -e "${RED}Version is required!${NC}"
    echo "Usage: $0 --version VERSION [--token TOKEN] [--check-workflow]"
    exit 1
fi

# Get GitHub repo info
REMOTE_URL=$(git config --get remote.origin.url)
if [[ $REMOTE_URL =~ github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    REPO="${REPO%.git}"
else
    echo -e "${RED}Could not determine GitHub repository from remote URL: $REMOTE_URL${NC}"
    exit 1
fi

echo -e "${CYAN}Repository: $OWNER/$REPO${NC}"
echo -e "${CYAN}Version: $VERSION${NC}"
echo -e "${CYAN}Tag: v$VERSION${NC}"

# Get GitHub token
if [ -z "$TOKEN" ]; then
    TOKEN="$GITHUB_TOKEN"
    if [ -z "$TOKEN" ]; then
        echo -e "${YELLOW}GitHub token not provided.${NC}"
        echo "Please provide a GitHub Personal Access Token with 'repo' scope:"
        echo "  Create one at: https://github.com/settings/tokens"
        read -sp "Enter GitHub token: " TOKEN
        echo
    fi
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}GitHub token is required!${NC}"
    exit 1
fi

TAG_NAME="v$VERSION"

# Check if tag exists
echo -e "${CYAN}Checking if tag exists...${NC}"
if curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$OWNER/$REPO/git/refs/tags/$TAG_NAME" > /dev/null; then
    echo -e "${GREEN}✓ Tag $TAG_NAME exists${NC}"
else
    echo -e "${RED}❌ Tag $TAG_NAME does not exist!${NC}"
    echo -e "${YELLOW}Create it first with: git tag v$VERSION && git push origin v$VERSION${NC}"
    exit 1
fi

# Check if release already exists
echo -e "${CYAN}Checking if release already exists...${NC}"
EXISTING_RELEASE=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG_NAME" | jq -r '.id // empty')

if [ -n "$EXISTING_RELEASE" ]; then
    RELEASE_URL=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$TAG_NAME" | jq -r '.html_url')
    echo -e "${YELLOW}⚠️  Release for tag $TAG_NAME already exists!${NC}"
    echo "  URL: $RELEASE_URL"
    read -p "Delete and recreate? (y/n): " OVERWRITE
    if [ "$OVERWRITE" = "y" ]; then
        curl -s -X DELETE -H "Authorization: token $TOKEN" \
            "https://api.github.com/repos/$OWNER/$REPO/releases/$EXISTING_RELEASE" > /dev/null
        echo -e "${GREEN}✓ Existing release deleted${NC}"
    else
        exit 0
    fi
else
    echo -e "${GREEN}✓ No existing release found (this is good)${NC}"
fi

# Check workflow status if requested
if [ "$CHECK_WORKFLOW" = true ]; then
    echo -e "${CYAN}Checking workflow status...${NC}"
    WORKFLOW_RUNS=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/actions/runs")
    LATEST_RUN=$(echo "$WORKFLOW_RUNS" | jq -r '.workflow_runs[] | select(.name == "Build and Release") | .id' | head -1)
    if [ -n "$LATEST_RUN" ]; then
        STATUS=$(echo "$WORKFLOW_RUNS" | jq -r ".workflow_runs[] | select(.id == $LATEST_RUN) | .status")
        CONCLUSION=$(echo "$WORKFLOW_RUNS" | jq -r ".workflow_runs[] | select(.id == $LATEST_RUN) | .conclusion")
        RUN_URL=$(echo "$WORKFLOW_RUNS" | jq -r ".workflow_runs[] | select(.id == $LATEST_RUN) | .html_url")
        echo "  Latest workflow run: $STATUS - $CONCLUSION"
        echo "  URL: $RUN_URL"
        if [ "$STATUS" = "completed" ] && [ "$CONCLUSION" = "success" ]; then
            echo -e "${GREEN}✓ Workflow completed successfully${NC}"
        elif [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; then
            echo -e "${YELLOW}⚠️  Workflow is still running. Wait for it to complete.${NC}"
        else
            echo -e "${YELLOW}⚠️  Workflow did not complete successfully${NC}"
        fi
    fi
fi

# Create release
echo -e "${CYAN}Creating GitHub release...${NC}"

RELEASE_BODY="## Generation Two $VERSION

### Downloads
- **Windows**: \`generation-two-$VERSION-windows.exe\`
- **Linux**: \`generation-two_*.deb\` (Debian/Ubuntu package)
- **macOS**: \`generation-two.dmg\`

### Installation
1. Download the appropriate file for your platform
2. **Windows**: Run the \`.exe\` file
3. **Linux**: Install with \`sudo dpkg -i generation-two_*.deb\`
4. **macOS**: Open the \`.dmg\` file and drag the app to Applications

### Notes
- Credentials are NOT included. You must provide your own \`credential.txt\` file.
- See [README.md](generation_two/README.md) for usage instructions."

RELEASE_DATA=$(jq -n \
    --arg tag "$TAG_NAME" \
    --arg name "Release $VERSION" \
    --arg body "$RELEASE_BODY" \
    '{tag_name: $tag, name: $name, body: $body, draft: false, prerelease: false}')

RELEASE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$RELEASE_DATA" \
    "https://api.github.com/repos/$OWNER/$REPO/releases")

RELEASE_URL=$(echo "$RELEASE_RESPONSE" | jq -r '.html_url // empty')
RELEASE_ID=$(echo "$RELEASE_RESPONSE" | jq -r '.id // empty')

if [ -n "$RELEASE_URL" ] && [ "$RELEASE_ID" != "null" ]; then
    echo -e "${GREEN}✓ Release created successfully!${NC}"
    echo "  URL: $RELEASE_URL"
    echo -e "${YELLOW}Note: This release is empty (no artifacts).${NC}"
    echo -e "${YELLOW}To add artifacts, either:${NC}"
    echo "  1. Wait for GitHub Actions to complete and it will add them automatically"
    echo "  2. Manually upload files via GitHub web interface"
    echo "  3. Use GitHub CLI: gh release upload $TAG_NAME <files>"
else
    echo -e "${RED}❌ Failed to create release!${NC}"
    echo "$RELEASE_RESPONSE" | jq '.' || echo "$RELEASE_RESPONSE"
    exit 1
fi

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Release Created Successfully!                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Release URL: $RELEASE_URL"
echo ""
echo "Next steps:"
echo "1. Check GitHub Actions to see if builds are running"
echo "2. Once builds complete, artifacts will be added automatically"
echo "3. Or manually upload files to the release"
echo ""
