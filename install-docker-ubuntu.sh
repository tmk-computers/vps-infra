#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '\n[INFO] %s\n' "$*"; }
fail() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
trap 'printf "[ERROR] Installation failed near line %s.\n" "$LINENO" >&2' ERR

[[ $EUID -eq 0 ]] || fail 'Run with sudo: sudo bash install-docker-ubuntu.sh'
[[ -r /etc/os-release ]] || fail 'Cannot detect operating system.'
. /etc/os-release
[[ "${ID:-}" == ubuntu ]] || fail 'This script supports Ubuntu only.'
case "${VERSION_ID:-}" in 22.04|24.04) ;; *) fail "Unsupported Ubuntu release: ${VERSION_ID:-unknown}. Supported: 22.04 and 24.04." ;; esac
command -v apt-get >/dev/null || fail 'apt-get is required.'
export DEBIAN_FRONTEND=noninteractive

# Avoid disrupting existing Docker deployments or silently removing packages.
conflicts=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker)
installed=()
for pkg in "${conflicts[@]}"; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed'; then
    installed+=("$pkg")
  fi
done
if (( ${#installed[@]} )); then
  fail "Conflicting packages installed: ${installed[*]}. Review existing Docker workloads and migrate manually before running this script."
fi
if command -v docker >/dev/null 2>&1 && ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -qx 'install ok installed'; then
  fail 'A non-Docker-CE Docker command exists. Review the existing installation first.'
fi

log 'Updating package indexes and installing prerequisites...'
apt-get update
apt-get install -y ca-certificates curl apache2-utils

log 'Configuring Docker official APT repository...'
install -m 0755 -d /etc/apt/keyrings
curl --fail --silent --show-error --location --retry 3 https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
[[ -n "$codename" ]] || fail 'Cannot determine Ubuntu codename.'
cat > /etc/apt/sources.list.d/docker.sources <<REPO
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
REPO
apt-get update

log 'Installing Docker Engine and Compose plugin...'
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# Only create daemon.json if absent; never overwrite existing production settings.
if [[ ! -e /etc/docker/daemon.json ]]; then
  log 'Creating default log rotation settings...'
  install -d -m 0755 /etc/docker
  cat > /etc/docker/daemon.json <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
JSON
  systemctl restart docker
else
  log 'Existing /etc/docker/daemon.json detected; leaving it unchanged.'
fi

log 'Verifying Docker...'
docker --version
docker compose version
systemctl is-active --quiet docker || fail 'Docker service is not running.'
if docker run --rm hello-world >/dev/null; then
  log 'Docker installation and hello-world verification successful.'
else
  fail 'Docker installed, but hello-world verification failed (check image pull/network access).'
fi

printf '\nDocker is ready. Use sudo docker ps (or root).\n'
printf 'No users were added to the privileged docker group.\n'
printf 'Note: Docker-published ports require Docker-aware firewall configuration.\n'
