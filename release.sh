#!/bin/bash
# Release script for Ouroboros
# Usage: ./release.sh <version>
# Example: ./release.sh 1.10.1

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.10.1"
    exit 1
fi

# Remove 'v' prefix if present
VERSION=${VERSION#v}

# Validate version format (semantic versioning)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.10.1)"
    exit 1
fi

echo "Preparing release v${VERSION}..."

# Check if tag already exists locally
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo "⚠️  WARNING: Tag v${VERSION} already exists locally"
    read -p "Delete local tag and continue? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "v${VERSION}"
        echo "Local tag deleted."
    else
        echo "Release cancelled."
        exit 1
    fi
fi

# Check if tag exists on remote
if git ls-remote --tags origin "v${VERSION}" | grep -q "v${VERSION}"; then
    echo "⚠️  WARNING: Tag v${VERSION} already exists on remote"
    read -p "This will overwrite the remote tag. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled."
        exit 1
    fi
fi

# Update version in __init__.py
echo "Updating version in pyouroboros/__init__.py..."
sed -i.bak "s/VERSION = \".*\"/VERSION = \"${VERSION}\"/" pyouroboros/__init__.py
rm -f pyouroboros/__init__.py.bak

# Check if CHANGELOG needs updating
if ! grep -q "## \[v${VERSION}\]" CHANGELOG.md; then
    echo ""
    echo "⚠️  WARNING: CHANGELOG.md doesn't have an entry for v${VERSION}"
    echo "Please add release notes to CHANGELOG.md before proceeding."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled."
        git checkout pyouroboros/__init__.py
        exit 1
    fi
fi

# Show what will be committed
echo ""
echo "Changes to be committed:"
git diff pyouroboros/__init__.py

echo ""
read -p "Create release v${VERSION}? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    git checkout pyouroboros/__init__.py
    exit 1
fi

# Commit version change
git add pyouroboros/__init__.py
git commit -m "Bump version to v${VERSION}"

# Create tag
echo "Creating tag v${VERSION}..."
git tag -a "v${VERSION}" -m "Release v${VERSION}"

# Ask if user wants to push
echo ""
read -p "Push commit and tag to remote? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo "✅ Release v${VERSION} prepared locally!"
    echo ""
    echo "Next steps:"
    echo "  1. Review the changes: git show HEAD"
    echo "  2. Push the commit: git push"
    echo "  3. Push the tag: git push origin v${VERSION}"
    if git ls-remote --tags origin "v${VERSION}" | grep -q "v${VERSION}"; then
        echo "     (or force push if overwriting: git push -f origin v${VERSION})"
    fi
else
    # Push commit
    echo "Pushing commit..."
    git push
    
    # Push tag (force if overwriting)
    echo "Pushing tag v${VERSION}..."
    if git ls-remote --tags origin "v${VERSION}" | grep -q "v${VERSION}"; then
        echo "Tag exists on remote, force pushing..."
        git push -f origin "v${VERSION}"
    else
        git push origin "v${VERSION}"
    fi
    
    echo ""
    echo "✅ Release v${VERSION} pushed!"
    echo ""
    echo "The GitHub Actions workflow will automatically:"
    echo "  - Build multi-arch Docker images (amd64, arm64)"
    echo "  - Push to GHCR: ghcr.io/styliteag/ouroboros:${VERSION}"
    echo "  - Create a GitHub release"
    echo ""
    echo "Monitor the workflow at: https://github.com/styliteag/ouroboros/actions"
fi
