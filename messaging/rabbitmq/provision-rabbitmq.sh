#!/usr/bin/env bash
# ==============================================================================
# 🐇 Idempotent RabbitMQ Provisioning & Credential Management Script
# Supports QA (/omr-qa) and Production (/omr-prod) Isolation
# Platform Root: /var/www/vps-infra
# ==============================================================================
set -euo pipefail

CONTAINER_NAME="shared_rabbitmq"
ENV_TARGET="${1:-qa}" # 'qa' or 'prod'

if [ "${ENV_TARGET}" = "prod" ] || [ "${ENV_TARGET}" = "production" ]; then
    VHOST="/omr-prod"
    ENV_SUFFIX="prod"
else
    VHOST="/omr-qa"
    ENV_SUFFIX="qa"
fi

SECRETS_DIR="/etc/vps-infra/secrets/rabbitmq"
CRED_FILE="${SECRETS_DIR}/omr_${ENV_SUFFIX}_credentials.env"

mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

API_USER="omr_api_${ENV_SUFFIX}_user"
WORKER_USER="omr_worker_${ENV_SUFFIX}_user"

# 1. Generate or load credentials
if [ ! -f "${CRED_FILE}" ]; then
    echo "▶ Generating new secure credentials for OMR API and Worker (${ENV_TARGET})..."
    python3 -c "
import secrets
api_pass = secrets.token_urlsafe(32)
worker_pass = secrets.token_urlsafe(32)
with open('${CRED_FILE}', 'w') as f:
    f.write(f'OMR_RABBITMQ_VHOST=${VHOST}\n')
    f.write(f'OMR_API_RABBITMQ_USER=${API_USER}\n')
    f.write(f'OMR_API_RABBITMQ_PASSWORD={api_pass}\n')
    f.write(f'OMR_WORKER_RABBITMQ_USER=${WORKER_USER}\n')
    f.write(f'OMR_WORKER_RABBITMQ_PASSWORD={worker_pass}\n')
"
    chmod 600 "${CRED_FILE}"
fi

# Load variables safely
source "${CRED_FILE}"

echo "▶ Ensuring RabbitMQ container '${CONTAINER_NAME}' is ready..."
docker exec "${CONTAINER_NAME}" rabbitmq-diagnostics -q check_running

# 2. Provision Virtual Host (idempotent)
echo "▶ Provisioning virtual host '${VHOST}'..."
if ! docker exec "${CONTAINER_NAME}" rabbitmqctl list_vhosts --silent | grep -qE "^${VHOST}$"; then
    docker exec "${CONTAINER_NAME}" rabbitmqctl add_vhost "${VHOST}"
    echo "✓ Virtual host '${VHOST}' created."
else
    echo "✓ Virtual host '${VHOST}' already exists."
fi

# 3. Provision or Update API User
echo "▶ Configuring user '${OMR_API_RABBITMQ_USER}'..."
if ! docker exec "${CONTAINER_NAME}" rabbitmqctl list_users --silent | grep -qE "^${OMR_API_RABBITMQ_USER}\s"; then
    docker exec "${CONTAINER_NAME}" rabbitmqctl add_user "${OMR_API_RABBITMQ_USER}" "${OMR_API_RABBITMQ_PASSWORD}"
    echo "✓ User '${OMR_API_RABBITMQ_USER}' created."
else
    docker exec "${CONTAINER_NAME}" rabbitmqctl change_password "${OMR_API_RABBITMQ_USER}" "${OMR_API_RABBITMQ_PASSWORD}"
    echo "✓ User '${OMR_API_RABBITMQ_USER}' password updated."
fi
docker exec "${CONTAINER_NAME}" rabbitmqctl set_permissions -p "${VHOST}" "${OMR_API_RABBITMQ_USER}" ".*" ".*" ".*"
docker exec "${CONTAINER_NAME}" rabbitmqctl clear_permissions -p / "${OMR_API_RABBITMQ_USER}" 2>/dev/null || true

# 4. Provision or Update Worker User
echo "▶ Configuring user '${OMR_WORKER_RABBITMQ_USER}'..."
if ! docker exec "${CONTAINER_NAME}" rabbitmqctl list_users --silent | grep -qE "^${OMR_WORKER_RABBITMQ_USER}\s"; then
    docker exec "${CONTAINER_NAME}" rabbitmqctl add_user "${OMR_WORKER_RABBITMQ_USER}" "${OMR_WORKER_RABBITMQ_PASSWORD}"
    echo "✓ User '${OMR_WORKER_RABBITMQ_USER}' created."
else
    docker exec "${CONTAINER_NAME}" rabbitmqctl change_password "${OMR_WORKER_RABBITMQ_USER}" "${OMR_WORKER_RABBITMQ_PASSWORD}"
    echo "✓ User '${OMR_WORKER_RABBITMQ_USER}' password updated."
fi
docker exec "${CONTAINER_NAME}" rabbitmqctl set_permissions -p "${VHOST}" "${OMR_WORKER_RABBITMQ_USER}" ".*" ".*" ".*"
docker exec "${CONTAINER_NAME}" rabbitmqctl clear_permissions -p / "${OMR_WORKER_RABBITMQ_USER}" 2>/dev/null || true

echo "✅ RabbitMQ infrastructure provisioning complete for environment '${ENV_TARGET}' (vhost '${VHOST}')."
