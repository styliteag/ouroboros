#!/bin/bash
# Release script for Ouroboros
# Usage: ./release.sh <version> [--push-to-dockerhub]
# Example: ./release.sh 1.10.1

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [--push-to-dockerhub]"
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

# Create and push tag
echo "Creating tag v${VERSION}..."
git tag -a "v${VERSION}" -m "Release v${VERSION}"

echo ""
echo "✅ Release v${VERSION} prepared!"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git show HEAD"
echo "  2. Push the commit: git push"
echo "  3. Push the tag: git push origin v${VERSION}"
echo ""
echo "The GitHub Actions workflow will automatically:"
echo "  - Build multi-arch Docker images (amd64, arm64)"
echo "  - Push to GHCR: ghcr.io/styliteag/ouroboros:${VERSION}"
echo "  - Create a GitHub release"
echo ""
echo "To also push to Docker Hub, use the workflow_dispatch in GitHub Actions"
echo "and enable 'push_to_dockerhub' option."
