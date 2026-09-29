#!/usr/bin/env bash
# ==============================================================================
# Automated SemVer Release Script for vps-infra
# Usage:
#   ./scripts/release.sh [patch|minor|major|<specific_version>] [--dry-run]
# Examples:
#   ./scripts/release.sh patch       # e.g. v2.2.0 -> v2.2.1
#   ./scripts/release.sh minor       # e.g. v2.2.0 -> v2.3.0
#   ./scripts/release.sh major       # e.g. v2.2.0 -> v3.0.0
#   ./scripts/release.sh v2.3.0      # Explicit version
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"

BUMP_TYPE="${1:-patch}"
DRY_RUN=false
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
    fi
done

cd "${ROOT_DIR}"

# 1. Read current version
if [[ -f "${VERSION_FILE}" ]]; then
    CURRENT_VERSION=$(tr -d '[:space:]' < "${VERSION_FILE}")
else
    CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v2.2.0")
fi

# Ensure leading 'v'
[[ "${CURRENT_VERSION}" != v* ]] && CURRENT_VERSION="v${CURRENT_VERSION}"

# Parse SemVer numbers
RAW_VER="${CURRENT_VERSION#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "${RAW_VER}"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

case "${BUMP_TYPE}" in
    patch)
        NEW_PATCH=$((PATCH + 1))
        NEW_VERSION="v${MAJOR}.${MINOR}.${NEW_PATCH}"
        ;;
    minor)
        NEW_MINOR=$((MINOR + 1))
        NEW_VERSION="v${MAJOR}.${NEW_MINOR}.0"
        ;;
    major)
        NEW_MAJOR=$((MAJOR + 1))
        NEW_VERSION="v${NEW_MAJOR}.0.0"
        ;;
    v*|[0-9]*)
        if [[ "${BUMP_TYPE}" != v* ]]; then
            NEW_VERSION="v${BUMP_TYPE}"
        else
            NEW_VERSION="${BUMP_TYPE}"
        fi
        ;;
    *)
        echo "❌ Error: Invalid bump type or version '${BUMP_TYPE}'. Use patch, minor, major, or a version like v2.2.1" >&2
        exit 1
        ;;
esac

echo "=========================================="
echo " 🚀 Platform Release Management"
echo "=========================================="
echo " Repository : ${ROOT_DIR}"
echo " Current    : ${CURRENT_VERSION}"
echo " New Target : ${NEW_VERSION}"
if [ "${DRY_RUN}" = true ]; then
    echo " Mode       : DRY RUN (no changes applied)"
    echo "=========================================="
    exit 0
fi
echo "=========================================="

# Check if git tag already exists locally
if git rev-parse "${NEW_VERSION}" >/dev/null 2>&1; then
    echo "⚠️ Warning: Git tag ${NEW_VERSION} already exists locally."
    echo "If you intend to retag, remove the tag first (git tag -d ${NEW_VERSION})."
    exit 1
fi

# Update VERSION file
echo "${NEW_VERSION}" > "${VERSION_FILE}"
git add "${VERSION_FILE}"

if [[ -f "${SCRIPT_DIR}/release.sh" ]]; then
    git add "${SCRIPT_DIR}/release.sh"
fi

# Commit
git commit -m "chore(release): bump version to ${NEW_VERSION}" || true

# Tag
git tag -a "${NEW_VERSION}" -m "Release ${NEW_VERSION}"

# Push commit and tag
echo "Pushing commit and tag to origin..."
git push origin main
git push origin "${NEW_VERSION}"

echo "✅ Successfully released and pushed ${NEW_VERSION}!"
