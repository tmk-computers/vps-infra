#!/bin/bash

set -e

echo "=============================="
echo " PostgreSQL + pgAdmin Setup"
echo "=============================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$INFRA_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        trimmed_line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -z "$trimmed_line" || "$trimmed_line" =~ ^# ]] && continue
        if [[ "$trimmed_line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            val="${val%\"}"
            val="${val#\"}"
            val="${val%\'}"
            val="${val#\'}"
            export "$key=$val"
        fi
    done < "$ENV_FILE"
fi

# VARIABLES
BASE_DIR="${INFRA_BASE_DIR:-$INFRA_DIR}/volumes/db"
PG_DATA="${POSTGRES_DATA_STORAGE:-$BASE_DIR/postgres/data}"
PG_BACKUPS="$BASE_DIR/postgres/backups"
PGADMIN_DATA="$BASE_DIR/pgadmin"
PGADMIN_CONFIG="$BASE_DIR/pgadmin-config"

# Step 1: Create folders
echo "📁 Creating directories..."
mkdir -p "$PG_DATA"
mkdir -p "$PG_BACKUPS"
mkdir -p "$PGADMIN_DATA/pgadmin_sessions"
mkdir -p "$PGADMIN_CONFIG"

# Ensure .env symlink exists for direct docker compose usage in this directory
ln -sf ../../.env "$SCRIPT_DIR/.env"

# Step 2: Set permissions (CRITICAL)
echo "🔐 Setting permissions..."
chown -R 5050:5050 "$PGADMIN_DATA"
chmod -R 700 "$PGADMIN_DATA"

# Step 3: Create pgAdmin config override
echo "📝 Creating pgAdmin config..."
if [ -d "$PGADMIN_CONFIG/config_local.py" ]; then
    rm -rf "$PGADMIN_CONFIG/config_local.py"
fi
cat <<EOF > "$PGADMIN_CONFIG/config_local.py"
SESSION_DB_PATH = "/var/lib/pgadmin/pgadmin_sessions"
EOF

# Step 4: Start services using canonical docker-compose.yml
echo "🚀 Starting containers..."
if [ -f "$ENV_FILE" ]; then
    docker compose --env-file "$ENV_FILE" -f "$SCRIPT_DIR/docker-compose.yml" up -d
else
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d
fi

echo ""
echo "✅ Setup completed successfully!"
echo "--------------------------------"
echo "pgAdmin: https://${PGADMIN_HOST:-pgadmin.example.com}"
echo "Postgres Port: 5432"
echo "--------------------------------"