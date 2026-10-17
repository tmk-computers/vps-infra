#!/bin/bash
# ==============================================================================
# 🚀 VPS-INFRA: E2E TEST SUITE FOR VERSION CHECK & FOLDER STRUCTURE MIGRATION
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "======================================================================"
echo "   🧪 RUNNING E2E TEST SUITE: VERSION CHECK & MIGRATION ENGINE"
echo "======================================================================"
echo -e "${NC}"

FAILURES=0

assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    if [ "$expected" == "$actual" ]; then
        echo -e "${GREEN}  ✔ PASS: $test_name${NC}"
    else
        echo -e "${RED}  ✖ FAIL: $test_name (Expected '$expected', got '$actual')${NC}"
        FAILURES=$((FAILURES + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}  ✔ PASS: $test_name${NC}"
    else
        echo -e "${RED}  ✖ FAIL: $test_name (String does not contain '$needle')${NC}"
        FAILURES=$((FAILURES + 1))
    fi
}

# ------------------------------------------------------------------------------
# Test 1: Live License Server Version-Check API
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}▶ Test 1: Live License Server Version Check API${NC}"
SERVER_URL="${TEST_LICENSE_SERVER_URL:-http://localhost:5055}"

# 1.1 Outdated client v2.1
RESP_V21=$(curl -s --max-time 5 "$SERVER_URL/api/v1/license/version-check?currentVersion=v2.1")
HAS_UPDATE_V21=$(echo "$RESP_V21" | jq -r '.hasUpdate')
LATEST_VER=$(echo "$RESP_V21" | jq -r '.latestStableVersion // ""')
MIGRATE_FOLDER_FLAG=$(echo "$RESP_V21" | jq -r '.requiresFolderStructureMigration')

assert_equal "true" "$HAS_UPDATE_V21" "API reports hasUpdate: true for legacy client v2.1"
assert_equal "v2.3.0" "$LATEST_VER" "API reports latestStableVersion: v2.3.0"
assert_equal "true" "$MIGRATE_FOLDER_FLAG" "API flags requiresFolderStructureMigration: true"

# 1.2 Up-to-date client v2.3.0
RESP_V23=$(curl -s --max-time 5 "$SERVER_URL/api/v1/license/version-check?currentVersion=v2.3.0")
HAS_UPDATE_V23=$(echo "$RESP_V23" | jq -r '.hasUpdate')
assert_equal "false" "$HAS_UPDATE_V23" "API reports hasUpdate: false for current client v2.3.0"

# ------------------------------------------------------------------------------
# Test 2: CLI upgrade-client.sh --check Option
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}▶ Test 2: CLI upgrade-client.sh --check Option${NC}"
CLI_OUTPUT=$(LICENSE_SERVER_URL="$SERVER_URL" bash "$SCRIPT_DIR/scripts/upgrade-client.sh" --check)

assert_contains "$CLI_OUTPUT" "Current Client Version" "CLI prints current client version"
assert_contains "$CLI_OUTPUT" "Latest Stable Version" "CLI prints latest stable version"
assert_contains "$CLI_OUTPUT" "Component Releases:" "CLI prints component releases breakdown"

# ------------------------------------------------------------------------------
# Test 3: Sandbox Migration Engine (Idempotency & Zero Symlinks at Root)
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}▶ Test 3: Sandbox Migration Engine Verification${NC}"
SANDBOX_DIR=$(mktemp -d /tmp/vps-infra-migration-test-XXXXXX)

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# Setup mock legacy repository layout
mkdir -p "$SANDBOX_DIR/scripts"
mkdir -p "$SANDBOX_DIR/volumes/db/postgres/data"
mkdir -p "$SANDBOX_DIR/ci-server/cache"
mkdir -p "$SANDBOX_DIR/code/sample-api"
mkdir -p "$SANDBOX_DIR/apps/sample-app"

echo "dummy-pg-data" > "$SANDBOX_DIR/volumes/db/postgres/data/PG_VERSION"
echo "dummy-cache" > "$SANDBOX_DIR/ci-server/cache/build.bin"

cat <<'EOF' > "$SANDBOX_DIR/code/sample-api/docker-compose.yml"
services:
  sample-api:
    image: sample:latest
    volumes:
      - /var/www/vps-infra/volumes/apps/sample/data:/app/data
      - /var/www/vps-infra/code/sample-api:/app/src
EOF

cp "$SCRIPT_DIR/scripts/migrate-folder-structure.sh" "$SANDBOX_DIR/scripts/"
chmod +x "$SANDBOX_DIR/scripts/migrate-folder-structure.sh"

# Run migration script inside sandbox
(
    cd "$SANDBOX_DIR"
    bash "$SANDBOX_DIR/scripts/migrate-folder-structure.sh" >/dev/null 2>&1
)

# Assert physical relocations
assert_equal "dummy-pg-data" "$(cat "$SANDBOX_DIR/docker/volumes/db/postgres/data/PG_VERSION" 2>/dev/null || echo '')" \
    "volumes/db migrated physically to docker/volumes/db"

assert_equal "dummy-cache" "$(cat "$SANDBOX_DIR/docker/volumes/ci-cache/cache/build.bin" 2>/dev/null || echo '')" \
    "ci-server/ cache migrated physically to docker/volumes/ci-cache"

assert_equal "true" "$([ -d "$SANDBOX_DIR/src/sample-api" ] && echo "true" || echo "false")" \
    "code/ directory renamed physically to src/"

# Assert compose paths updated
COMPOSE_CONTENT=$(cat "$SANDBOX_DIR/src/sample-api/docker-compose.yml" 2>/dev/null || echo '')
assert_contains "$COMPOSE_CONTENT" "/var/www/vps-infra/docker/volumes/apps/sample/data" \
    "Compose volume paths rewritten to docker/volumes"
assert_contains "$COMPOSE_CONTENT" "/var/www/vps-infra/src/sample-api" \
    "Compose code paths rewritten to src"

# Assert no legacy symlinks at root
assert_equal "false" "$([ -e "$SANDBOX_DIR/volumes" ] && echo "true" || echo "false")" \
    "volumes symlink/directory does NOT exist at repository root"

assert_equal "false" "$([ -e "$SANDBOX_DIR/code" ] && echo "true" || echo "false")" \
    "code symlink/directory does NOT exist at repository root"

assert_equal "false" "$([ -e "$SANDBOX_DIR/ci-server" ] && echo "true" || echo "false")" \
    "ci-server symlink/directory does NOT exist at repository root"

# Assert idempotency on second execution
SECOND_RUN_OUTPUT=$(cd "$SANDBOX_DIR" && bash "$SANDBOX_DIR/scripts/migrate-folder-structure.sh" 2>&1)
assert_contains "$SECOND_RUN_OUTPUT" "already up-to-date" "Subsequent run detects canonical layout and exits idempotently"

# ------------------------------------------------------------------------------
# Final Test Summary
# ------------------------------------------------------------------------------
echo -e "\n======================================================================"
if [ "$FAILURES" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}   🎉 ALL E2E TESTS PASSED SUCCESSFULLY!${NC}"
    echo "======================================================================"
    exit 0
else
    echo -e "${RED}${BOLD}   ❌ $FAILURES TEST(S) FAILED!${NC}"
    echo "======================================================================"
    exit 1
fi
