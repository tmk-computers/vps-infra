#!/bin/bash
# ==============================================================================
# Helper Script: Create/Update Read-Only User for clever_farmer_uat
# ==============================================================================

set -e

CONTAINER_NAME="shared_postgres"
TARGET_DB="clever_farmer_uat"
ANALYST_USER="${1:-clever_farmer_analyst}"
ANALYST_PASS="${2:-AM8xoChSNNgfcrhlLdc5Rnum}"

echo "Configuring read-only user '$ANALYST_USER' for database '$TARGET_DB'..."

# Step 1: Create or update role
docker exec -i "$CONTAINER_NAME" psql -U postgres <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$ANALYST_USER') THEN
      CREATE ROLE $ANALYST_USER WITH LOGIN PASSWORD '$ANALYST_PASS';
   ELSE
      ALTER ROLE $ANALYST_USER WITH LOGIN PASSWORD '$ANALYST_PASS';
   END IF;
END
\$\$;

GRANT CONNECT ON DATABASE $TARGET_DB TO $ANALYST_USER;
REVOKE CREATE ON DATABASE $TARGET_DB FROM $ANALYST_USER;
EOF

# Step 2: Grant read-only access to public schema and tables in target DB
docker exec -i "$CONTAINER_NAME" psql -U postgres -d "$TARGET_DB" <<EOF
GRANT USAGE ON SCHEMA public TO $ANALYST_USER;
REVOKE CREATE ON SCHEMA public FROM $ANALYST_USER;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO $ANALYST_USER;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO $ANALYST_USER;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO $ANALYST_USER;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON SEQUENCES TO $ANALYST_USER;
EOF

echo "Done! Read-only user '$ANALYST_USER' configured successfully."
