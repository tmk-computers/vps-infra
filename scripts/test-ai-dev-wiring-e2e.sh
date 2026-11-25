#!/usr/bin/env bash
# ==============================================================================
# VPS-INFRA Client - Unattended AI Dev Worker Profile & Security Wiring E2E Test
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TMP_ENV=$(mktemp)
cleanup() { rm -f "$TMP_ENV"; }
trap cleanup EXIT

cat <<'EOF' > "$TMP_ENV"
PRIMARY_DOMAIN=example.com
CI_SECRET=test_ci_secret_0123456789abcdef0123456789abcdef0123456789abcdef
JWT_SECRET_KEY=test_jwt_secret_0123456789abcdef0123456789abcdef0123456789abcdef
DOCKER_REGISTRY_USER=testuser
DOCKER_REGISTRY_PASSWORD=testpass
EOF

# 1. Existing profiles must NOT include tmk-dev-worker
for prof in all devops ci; do
  SERVICES=$(docker compose -f "${ROOT_DIR}/docker-compose.yml" --env-file "$TMP_ENV" --profile "$prof" config --services)
  if echo "$SERVICES" | grep -qx "dev-worker-prod"; then
    echo "FAIL: default profile '$prof' must not include dev-worker-prod" >&2
    exit 1
  fi
done
echo "PASS: Default Compose profiles (all/devops/ci) exclude opt-in dev-worker-prod."

# 2. Opt-in ai-dev profile includes dev-worker-prod with hardened isolation
AI_RENDER=$(docker compose -f "${ROOT_DIR}/docker-compose.yml" --env-file "$TMP_ENV" --profile all --profile ai-dev config)
AI_SERVICES=$(docker compose -f "${ROOT_DIR}/docker-compose.yml" --env-file "$TMP_ENV" --profile all --profile ai-dev config --services)
if ! echo "$AI_SERVICES" | grep -qx "dev-worker-prod"; then
  echo "FAIL: --profile ai-dev did not enable dev-worker-prod" >&2
  exit 1
fi

WORKER_BLOCK=$(echo "$AI_RENDER" | awk '/^  dev-worker-prod:/{in_block=1; next} /^  [a-zA-Z0-9_-]+:/{if(in_block) exit} in_block{print}')
if echo "$WORKER_BLOCK" | grep -qE "docker\.sock|/var/www|/root/\.ssh|/root/\.docker|/etc/vps-infra/secrets"; then
  echo "FAIL: dev-worker-prod must never mount docker.sock, /var/www, ssh, docker creds, or host secrets" >&2
  exit 1
fi
if ! echo "$WORKER_BLOCK" | grep -q "no-new-privileges:true"; then
  echo "FAIL: dev-worker-prod must set no-new-privileges:true" >&2
  exit 1
fi
if ! echo "$WORKER_BLOCK" | grep -q "ALL"; then
  echo "FAIL: dev-worker-prod must set cap_drop: ALL" >&2
  exit 1
fi
echo "PASS: Opt-in ai-dev profile enables isolated dev-worker-prod without privileged host mounts."

# 3. Validate setup.sh, upgrade-client.sh, and .env.example keys
bash -n "${ROOT_DIR}/setup.sh"
bash -n "${ROOT_DIR}/scripts/upgrade-client.sh"
for key in DEV_ORCHESTRATION_EXECUTOR_MODE DEV_WORKER_IMAGE DEV_WORKER_URL DEV_WORKER_SECRET ENABLE_AI_DEV_MIGRATION; do
  grep -q "^${key}=" "${ROOT_DIR}/.env.example"
done
echo "PASS: Shell syntax checks and .env.example unattended dev keys validated."
