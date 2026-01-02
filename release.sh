#!/bin/bash
# Release Script for Generation Two
# Creates a version tag and triggers GitHub Actions release workflow

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
VERSION=""
PATCH=false
MINOR=false
MAJOR=false
SKIP_VERSION_UPDATE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --patch)
            PATCH=true
            shift
            ;;
        --minor)
            MINOR=true
            shift
            ;;
        --major)
            MAJOR=true
            shift
            ;;
        --skip-version-update)
            SKIP_VERSION_UPDATE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

get_current_version() {
    local pyproject="generation_two/pyproject.toml"
    if [ -f "$pyproject" ]; then
        grep -oP 'version\s*=\s*"\K[^"]+' "$pyproject" | head -1 || echo "1.0.0"
    else
        echo "1.0.0"
    fi
}

increment_version() {
    local version=$1
    local type=$2
    IFS='.' read -ra PARTS <<< "$version"
    local major=${PARTS[0]}
    local minor=${PARTS[1]}
    local patch=${PARTS[2]}
    
    case $type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

update_version_files() {
    local version=$1
    echo -e "${CYAN}Updating version files...${NC}"
    
    # Update pyproject.toml
    if [ -f "generation_two/pyproject.toml" ]; then
        sed -i.bak "s/version = \"[^\"]*\"/version = \"$version\"/" "generation_two/pyproject.toml"
        rm -f "generation_two/pyproject.toml.bak"
        echo -e "${GREEN}  ✓ Updated pyproject.toml${NC}"
    fi
    
    # Update setup.py
    if [ -f "generation_two/setup.py" ]; then
        sed -i.bak "s/version=\"[^\"]*\"/version=\"$version\"/" "generation_two/setup.py"
        rm -f "generation_two/setup.py.bak"
        echo -e "${GREEN}  ✓ Updated setup.py${NC}"
    fi
}

# Main script
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         Generation Two Release Script                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get current version
CURRENT_VERSION=$(get_current_version)
echo -e "${YELLOW}Current version: $CURRENT_VERSION${NC}"

# Determine new version
NEW_VERSION=$VERSION

if [ -z "$NEW_VERSION" ]; then
    if [ "$PATCH" = true ]; then
        NEW_VERSION=$(increment_version "$CURRENT_VERSION" "patch")
        echo -e "${CYAN}Incrementing patch version...${NC}"
    elif [ "$MINOR" = true ]; then
        NEW_VERSION=$(increment_version "$CURRENT_VERSION" "minor")
        echo -e "${CYAN}Incrementing minor version...${NC}"
    elif [ "$MAJOR" = true ]; then
        NEW_VERSION=$(increment_version "$CURRENT_VERSION" "major")
        echo -e "${CYAN}Incrementing major version...${NC}"
    else
        # Interactive mode
        echo ""
        echo "Version options:"
        echo "  1. Patch increment ($CURRENT_VERSION -> $(increment_version "$CURRENT_VERSION" "patch"))"
        echo "  2. Minor increment ($CURRENT_VERSION -> $(increment_version "$CURRENT_VERSION" "minor"))"
        echo "  3. Major increment ($CURRENT_VERSION -> $(increment_version "$CURRENT_VERSION" "major"))"
        echo "  4. Custom version"
        read -p "Select option (1-4): " choice
        
        case $choice in
            1) NEW_VERSION=$(increment_version "$CURRENT_VERSION" "patch") ;;
            2) NEW_VERSION=$(increment_version "$CURRENT_VERSION" "minor") ;;
            3) NEW_VERSION=$(increment_version "$CURRENT_VERSION" "major") ;;
            4) 
                while true; do
                    read -p "Enter version (format: X.Y.Z): " NEW_VERSION
                    if [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                        break
                    fi
                    echo -e "${RED}Invalid version format. Use X.Y.Z (e.g., 1.0.0)${NC}"
                done
                ;;
            *) 
                echo -e "${RED}Invalid choice. Exiting.${NC}"
                exit 1
                ;;
        esac
    fi
fi

# Validate version format
if [[ ! $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Invalid version format: $NEW_VERSION. Use X.Y.Z format (e.g., 1.0.0)${NC}"
    exit 1
fi

echo -e "${GREEN}New version: $NEW_VERSION${NC}"

# Check if tag already exists
TAG_NAME="v$NEW_VERSION"
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo -e "${RED}Tag $TAG_NAME already exists!${NC}"
    read -p "Delete and recreate? (y/n): " overwrite
    if [ "$overwrite" = "y" ]; then
        git tag -d "$TAG_NAME" 2>/dev/null || true
        git push origin ":refs/tags/$TAG_NAME" 2>/dev/null || true
    else
        echo -e "${YELLOW}Exiting without creating release.${NC}"
        exit 1
    fi
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ] && [ "$SKIP_VERSION_UPDATE" = false ]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes:${NC}"
    git status --short
    read -p "Continue anyway? (y/n): " continue_anyway
    if [ "$continue_anyway" != "y" ]; then
        exit 1
    fi
fi

# Update version files
if [ "$SKIP_VERSION_UPDATE" = false ] && [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    update_version_files "$NEW_VERSION"
    
    # Ask to commit version update
    read -p "Commit version update? (y/n): " commit_version
    if [ "$commit_version" = "y" ]; then
        git add generation_two/pyproject.toml generation_two/setup.py
        git commit -m "Bump version to $NEW_VERSION"
        echo -e "${GREEN}✓ Version files committed${NC}"
    fi
fi

# Show what will happen
echo -e "${CYAN}Release Summary:${NC}"
echo "  Version: $NEW_VERSION"
echo "  Tag: $TAG_NAME"
echo "  Current branch: $(git branch --show-current)"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN] Would execute:${NC}"
    echo "  git tag -a $TAG_NAME -m \"Release version $NEW_VERSION\""
    echo "  git push origin $TAG_NAME"
    exit 0
fi

# Confirm
echo -e "${YELLOW}This will:${NC}"
echo "  1. Create tag: $TAG_NAME"
echo "  2. Push tag to origin (triggers GitHub Actions)"
if [ "$SKIP_VERSION_UPDATE" = false ] && [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    echo "  3. Push version commit (if committed)"
fi
read -p "Proceed? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo -e "${YELLOW}Release cancelled.${NC}"
    exit 0
fi

# Create and push tag
echo -e "${CYAN}Creating tag...${NC}"
git tag -a "$TAG_NAME" -m "Release version $NEW_VERSION"
echo -e "${GREEN}✓ Tag created: $TAG_NAME${NC}"

echo -e "${CYAN}Pushing tag to origin...${NC}"
git push origin "$TAG_NAME"
echo -e "${GREEN}✓ Tag pushed to origin${NC}"

# Push current branch if version was updated
if [ "$SKIP_VERSION_UPDATE" = false ] && [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    CURRENT_BRANCH=$(git branch --show-current)
    read -p "Push branch '$CURRENT_BRANCH' to origin? (y/n): " push_branch
    if [ "$push_branch" = "y" ]; then
        git push origin "$CURRENT_BRANCH"
        echo -e "${GREEN}✓ Branch pushed${NC}"
    fi
fi

# Success message
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Release Created!                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Version: $NEW_VERSION"
echo "Tag: $TAG_NAME"
echo ""
echo "GitHub Actions will now:"
echo "  ✓ Build Windows EXE"
echo "  ✓ Build Linux DEB"
echo "  ✓ Build macOS DMG"
echo "  ✓ Create GitHub Release"
echo ""
REPO_URL=$(git config --get remote.origin.url | sed -E 's/.*[:/]([^/]+\/[^/]+?)(?:\.git)?$/\1/')
echo "Monitor progress at:"
echo "  https://github.com/$REPO_URL/actions"
echo ""
