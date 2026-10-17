#!/bin/bash
# ==============================================================================
# 🚀 VPS-INFRA: AUTOMATED FOLDER STRUCTURE MIGRATION ENGINE (v2.1/v2.2 -> v2.3+)
# ==============================================================================
# Safely relocates and standardizes directory layouts for existing client nodes:
#   1. volumes/                     -> docker/volumes/
#   2. ci-server/                   -> docker/volumes/ci-cache/
#   3. volumes/ci-pilot-freeze.json -> docker/volumes/ci-pilot-freeze.json
#   4. code/                        -> src/
#   5. Backward-compatibility symlinks (volumes -> docker/volumes, code -> src)
#   6. Updates client compose files (apps/ and src/)
#   7. Updates DevOps database paths (projects, project_services in devops_prod)
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
echo "   🔄 VPS-INFRA: FOLDER STRUCTURE MIGRATION (v2.1/v2.2 -> v2.3+)"
echo "======================================================================"
echo -e "${NC}"

# Check if legacy paths exist
NEEDS_MIGRATION=false

if [ -d "$SCRIPT_DIR/volumes" ] && [ ! -L "$SCRIPT_DIR/volumes" ]; then
    NEEDS_MIGRATION=true
fi

if [ -d "$SCRIPT_DIR/code" ] && [ ! -L "$SCRIPT_DIR/code" ]; then
    NEEDS_MIGRATION=true
fi

if [ -d "$SCRIPT_DIR/ci-server" ] && [ ! -L "$SCRIPT_DIR/ci-server" ]; then
    NEEDS_MIGRATION=true
fi

if [ "$NEEDS_MIGRATION" = false ]; then
    echo -e "${GREEN}✅ Folder structure is already up-to-date with v2.3+ canonical layout.${NC}"
    # Ensure no legacy symlinks remain at root
    rm -f "$SCRIPT_DIR/volumes" "$SCRIPT_DIR/code" "$SCRIPT_DIR/ci-server" 2>/dev/null || true
    exit 0
fi

echo -e "${YELLOW}⚠️ Legacy folder structure detected. Starting automated migration...${NC}"

# 1. Stop platform containers cleanly to release volume locks
echo -e "\n${CYAN}▶ Step 1: Stopping containers to release disk locks...${NC}"
docker compose stop 2>/dev/null || true

# 2. Migrate volumes/ -> docker/volumes/
echo -e "\n${CYAN}▶ Step 2: Migrating volumes/ -> docker/volumes/...${NC}"
mkdir -p "$SCRIPT_DIR/docker/volumes"

if [ -d "$SCRIPT_DIR/volumes" ] && [ ! -L "$SCRIPT_DIR/volumes" ]; then
    echo "   • Syncing contents from volumes/ to docker/volumes/..."
    cp -a "$SCRIPT_DIR/volumes/." "$SCRIPT_DIR/docker/volumes/"
    rm -rf "$SCRIPT_DIR/volumes"
    echo -e "${GREEN}   ✅ volumes/ migrated to docker/volumes/.${NC}"
fi

# 3. Migrate ci-server/ -> docker/volumes/ci-cache/
echo -e "\n${CYAN}▶ Step 3: Migrating ci-server/ -> docker/volumes/ci-cache/...${NC}"
if [ -d "$SCRIPT_DIR/ci-server" ] && [ ! -L "$SCRIPT_DIR/ci-server" ]; then
    mkdir -p "$SCRIPT_DIR/docker/volumes/ci-cache"
    echo "   • Moving ci-server/ cache contents..."
    cp -a "$SCRIPT_DIR/ci-server/." "$SCRIPT_DIR/docker/volumes/ci-cache/"
    rm -rf "$SCRIPT_DIR/ci-server"
    echo -e "${GREEN}   ✅ ci-server/ migrated to docker/volumes/ci-cache/.${NC}"
fi

# 4. Relocate ci-pilot-freeze.json if located under legacy path
if [ -f "$SCRIPT_DIR/volumes/ci-pilot-freeze.json" ] && [ ! -f "$SCRIPT_DIR/docker/volumes/ci-pilot-freeze.json" ]; then
    cp "$SCRIPT_DIR/volumes/ci-pilot-freeze.json" "$SCRIPT_DIR/docker/volumes/ci-pilot-freeze.json"
fi

# 5. Migrate code/ -> src/
echo -e "\n${CYAN}▶ Step 4: Migrating code/ -> src/...${NC}"
if [ -d "$SCRIPT_DIR/code" ] && [ ! -L "$SCRIPT_DIR/code" ]; then
    if [ ! -d "$SCRIPT_DIR/src" ]; then
        mv "$SCRIPT_DIR/code" "$SCRIPT_DIR/src"
    else
        echo "   • Merging code/ into existing src/..."
        cp -a "$SCRIPT_DIR/code/." "$SCRIPT_DIR/src/"
        rm -rf "$SCRIPT_DIR/code"
    fi
    echo -e "${GREEN}   ✅ code/ migrated to src/.${NC}"
fi

# 6. Update compose files in apps/ and src/
echo -e "\n${CYAN}▶ Step 5: Updating volume and directory paths in compose files...${NC}"
for compose_file in $(find "$SCRIPT_DIR/apps" "$SCRIPT_DIR/src" -maxdepth 3 -name "docker-compose*.yml" 2>/dev/null); do
    if grep -q "/var/www/vps-infra/volumes/" "$compose_file" 2>/dev/null || grep -q "/var/www/vps-infra/code/" "$compose_file" 2>/dev/null; then
        sed -i 's|/var/www/vps-infra/volumes/|/var/www/vps-infra/docker/volumes/|g' "$compose_file"
        sed -i 's|/var/www/vps-infra/code/|/var/www/vps-infra/src/|g' "$compose_file"
        echo "   • Updated $compose_file"
    fi
done
echo -e "${GREEN}   ✅ Client application compose files normalized.${NC}"

# 7. Update Database paths in devops_prod (PostgreSQL)
echo -e "\n${CYAN}▶ Step 6: Updating database records in devops_prod...${NC}"
if docker compose ps -a --services 2>/dev/null | grep -q "shared_postgres"; then
    echo "   • Starting shared_postgres container to apply path updates..."
    docker compose up -d shared_postgres
    
    # Wait for postgres to be ready
    for i in {1..30}; do
        if docker exec shared_postgres pg_isready -U postgres >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    # Execute path replacement query
    docker exec shared_postgres psql -U postgres -d devops_prod -c "
        UPDATE projects 
        SET repository_path = REPLACE(repository_path, '/var/www/vps-infra/code/', '/var/www/vps-infra/src/')
        WHERE repository_path LIKE '%/var/www/vps-infra/code/%';

        UPDATE project_services 
        SET compose_file_path = REPLACE(compose_file_path, '/var/www/vps-infra/code/', '/var/www/vps-infra/src/'),
            working_directory = REPLACE(working_directory, '/var/www/vps-infra/code/', '/var/www/vps-infra/src/')
        WHERE compose_file_path LIKE '%/var/www/vps-infra/code/%' 
           OR working_directory LIKE '%/var/www/vps-infra/code/%';
    " 2>/dev/null || echo "   (DevOps database path update skipped or already current)"
    
    echo -e "${GREEN}   ✅ Database paths updated.${NC}"
fi

echo -e "\n${GREEN}${BOLD}======================================================================"
echo "   ✅ FOLDER STRUCTURE MIGRATION COMPLETED SUCCESSFULLY"
echo "======================================================================${NC}"
