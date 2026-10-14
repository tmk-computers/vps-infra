# 🔧 Single VPS Setup & Operations Troubleshooting Guide

This runbook documents common operational issues, root causes, and verified solutions for **Single VPS (All-in-One)** deployments running DevOps Manager, CI Server, Docker Registry, and PostgreSQL on a single host.

---

## 📋 Quick Diagnostic Table

| Issue / Symptom | Root Cause | Permanent Resolution |
| :--- | :--- | :--- |
| **CI Dashboard: 401 Unauthorized ("Session expired. Please log in again")** | JWT secret mismatch between `devops-api` and `ci-api` | Ensure `CI_JWT_SECRET` matches `JWT_SECRET_KEY` in `.env` |
| **CI Build: 400 Bad Request ("path argument must be of type string")** | `SYNC_MODE="api"` caused camelCase serialization mismatch | Set `SYNC_MODE="db"` in `.env` for direct PostgreSQL sync |
| **pgAdmin: Connection Timed Out / ERR_TIMED_OUT** | Volume ownership not granted to pgAdmin non-root UID 5050 | `sudo chown -R 5050:5050 /var/www/vps-infra/volumes/db/pgadmin` |
| **DevOps / CI Web: 403 Forbidden (nginx/1.30.5)** | Host volume mounts masking pre-built container `/usr/share/nginx/html` | Remove dist volume overrides from `docker-compose.yml` |
| **Docker Registry: 401 Unauthorized on push** | Incompatible htpasswd hash or missing Docker daemon login | Use Apache bcrypt (`htpasswd -B`) and `docker login localhost:5000` |
| **App Compose Config Error: Missing env file** | Referenced secret file does not exist on disk | Scaffolding `/etc/vps-infra/secrets/<app>/<env>.env` with `chmod 0600` |
| **Deploy: DEPLOY_ERR_COMPOSE_PINNING_FAILED** | Base compose file not found at `/var/www/<project>/docker-compose.yml` | Create symlinks `/var/www/<app> -> /var/www/vps-infra/apps/<app>` |

---

## 1. CI Authentication: JWT Secret Synchronization (401 Unauthorized)

### Symptom
When navigating to `https://ci.yourdomain.com/`, the UI reports:
```text
Error: Session expired. Please log in again.
GET https://ci-api.yourdomain.com/api/ci/projects -> 401 Unauthorized
```
And container logs display:
```text
ci-api-prod | JWT verification failed: invalid signature
```

### Root Cause
`devops-api` signs user authentication tokens using `JWT_SECRET_KEY`. When the frontend sends this token to `ci-api`, the CI runner verifies the signature using `CI_JWT_SECRET`. If `CI_JWT_SECRET` is different from `JWT_SECRET_KEY`, verification fails with `invalid signature`.

### Resolution
1. Verify both variables in `/var/www/vps-infra/.env`:
   ```ini
   JWT_SECRET_KEY="<your-64-char-hex-secret>"
   CI_JWT_SECRET="<your-64-char-hex-secret>"  # MUST be identical to JWT_SECRET_KEY
   ```
2. Verify `docker-compose.yml` has the fallback:
   ```yaml
   ci-api-prod:
     environment:
       - JWT_SECRET=${CI_JWT_SECRET:-${JWT_SECRET_KEY}}
   ```
3. Restart `ci-api-prod`:
   ```bash
   docker compose up -d ci-api-prod
   ```

---

## 2. CI Build Triggering: Database Synchronization Mode (400 Bad Request)

### Symptom
Triggering a service build via `POST /api/ci/build` returns:
```json
{
  "error": "The \"path\" argument must be of type string. Received undefined"
}
```
Container logs show:
```text
TypeError [ERR_INVALID_ARG_TYPE]: The "path" argument must be of type string. Received undefined
    at Object.basename (node:path:1441:5)
    at startBuild (file:///app/build-runner.js:612:31)
```

### Root Cause
For Single VPS (All-in-One) setups, `SYNC_MODE` must be set to `db`. If set to `api`, `ci-api` attempts to query service definitions over REST from `devops-api`, which serializes JSON properties in camelCase (`serviceName`, `projectDirectory`). `build-runner.js` expects PascalCase (`service.ServiceName`, `service.ProjectDirectory`), resulting in `path.basename(undefined)`.

### Resolution
1. Update `/var/www/vps-infra/.env`:
   ```ini
   SYNC_MODE="db"
   ```
2. Restart `ci-api-prod`:
   ```bash
   docker compose up -d ci-api-prod
   ```
3. In `db` mode, `ci-api-prod` connects directly to PostgreSQL (`shared_postgres:5432`), auto-initializes build tables, and loads service records with correct casing.

---

## 3. pgAdmin Storage Permissions & Crash Loops

### Symptom
Visiting `https://pgadmin.yourdomain.com` results in a browser connection timeout (`ERR_TIMED_OUT`) or pgAdmin container restarts continuously.

### Root Cause
pgAdmin runs inside its official container as non-root user `pga` with **UID 5050 / GID 5050**. When the persistent host directory `/var/www/vps-infra/volumes/db/pgadmin` is owned by `root:root` with default `0755` permissions, pgAdmin cannot create `pgadmin4.db` (session state and saved connections) and halts.

### Resolution
Grant ownership to UID 5050:
```bash
sudo chown -R 5050:5050 /var/www/vps-infra/volumes/db/pgadmin
sudo chmod 700 /var/www/vps-infra/volumes/db/pgadmin
docker restart pgadmin
```

---

## 4. Web Frontend Assets Masked by Dev Mounts (403 Forbidden)

### Symptom
Visiting `https://devops.yourdomain.com` or `https://ci.yourdomain.com` returns:
```text
403 Forbidden
nginx/1.30.5
```

### Root Cause
If development volume overrides (e.g., `./devops-manager/web/dist:/usr/share/nginx/html`) are present in `docker-compose.yml` on a production VPS, Docker bind-mounts an empty or non-existent host folder over the pre-built web assets inside the container image.

### Resolution
Ensure production compose manifests do not mount local frontend source/build directories over `/usr/share/nginx/html`. Production container images (`ghcr.io/tmk-computers/tmk-devops-web` and `tmk-ci-web`) already package all compiled static assets internally.

---

## 5. Private Docker Registry Authentication (401 Unauthorized on Push)

### Symptom
When CI builds attempt to push newly built container images to `localhost:5000`, the process fails:
```text
Error response from daemon: Get "http://localhost:5000/v2/": unauthorized: authentication required
```

### Root Cause
1. Registry htpasswd format was generated using standard crypt or SHA instead of Apache-compatible **bcrypt** (`htpasswd -B`).
2. Docker CLI session did not complete authentication on `localhost:5000` or `127.0.0.1:5000`.

### Resolution
1. Generate the htpasswd file with Apache bcrypt format:
   ```bash
   mkdir -p /var/www/vps-infra/docker-registry/auth
   docker run --rm --entrypoint htpasswd httpd:2 -Bbn "$DOCKER_REGISTRY_USER" "$DOCKER_REGISTRY_PASSWORD" > /var/www/vps-infra/docker-registry/auth/htpasswd
   ```
2. Log in the local Docker daemon:
   ```bash
   echo "$DOCKER_REGISTRY_PASSWORD" | docker login localhost:5000 -u "$DOCKER_REGISTRY_USER" --password-stdin
   echo "$DOCKER_REGISTRY_PASSWORD" | docker login 127.0.0.1:5000 -u "$DOCKER_REGISTRY_USER" --password-stdin
   ```
3. Restart the registry backend container:
   ```bash
   docker restart docker-registry-backend
   ```

---

## 6. Client Application Secrets Architecture (`/etc/vps-infra/secrets/`)

### Symptom
Running `docker compose -f /var/www/vps-infra/apps/<app>/docker-compose.yml config` fails with:
```text
env file /etc/vps-infra/secrets/<app>/<env>.env not found: stat /etc/vps-infra/secrets/<app>/<env>.env: no such file or directory
```

### Architecture Rule
Docker Compose validates all `env_file:` paths during configuration parsing. Secret files must exist on the host filesystem before containers can be launched.

### Setup Checklist
1. Create the application secret directory and file:
   ```bash
   sudo mkdir -p /etc/vps-infra/secrets/<app>
   sudo touch /etc/vps-infra/secrets/<app>/<env>.env
   ```
2. Lock down permissions (readable and writable only by root):
   ```bash
   sudo chown -R root:root /etc/vps-infra/secrets
   sudo chmod 700 /etc/vps-infra/secrets
   sudo chmod 700 /etc/vps-infra/secrets/<app>
   sudo chmod 600 /etc/vps-infra/secrets/<app>/<env>.env
   ```
3. In `apps/<app>/docker-compose.yml`, mount secrets via `env_file:`:
   ```yaml
   services:
     my-app-prod:
       image: localhost:5000/my-app:${IMAGE_TAG:-prod}
       env_file:
         - /etc/vps-infra/secrets/my-app/prod.env
       networks:
         - traefik_net
   ```

---

## 7. DevOps Manager Deployment: Base Compose Pinning Failed

### Symptom
Triggering deployment from the DevOps Manager UI fails immediately with:
```text
System.InvalidOperationException: [DEPLOY_ERR_COMPOSE_PINNING_FAILED] Cannot safely pin service '<service>': base compose file not found at /var/www/<project>/docker-compose.yml. Deployment aborted before container service interruption.
   at DevopsPanel.Infrastructure.Services.DeployService.ExecuteDeploymentScriptAsync(...)
```

### Root Cause
When deploying an application, DevOps Manager pins the built image tag into the service's `docker-compose.yml`.
It constructs the path using:
`Path.Combine(WWW_ROOT, service.Directory ?? project.Directory, "docker-compose.yml")`
Where `WWW_ROOT` is `/var/www`. If the service's `Directory` is left blank, it falls back to the project name (e.g. `omr-api`), seeking `/var/www/omr-api/docker-compose.yml`.
However, deployment manifests in `vps-infra` reside under `/var/www/vps-infra/apps/<project>/docker-compose.yml`.

### Resolution
#### Option 1: Native Platform Discovery (Recommended)
On DevOps Manager platform versions with dynamic compose path resolution, the deployment engine automatically inspects:
1. Direct path (`/var/www/<project>`)
2. Appliance apps directory (`/var/www/vps-infra/apps/<project>`)
3. Code repository directory (`/var/www/vps-infra/code/<project>`)
4. Alternative compose manifest filenames (`docker-compose.yml`, `docker-compose.yaml`, `compose.yaml`, `compose.yml`)

No symlinks or path modifications are needed on modern installations.

#### Option 2: Explicit Target Directory in UI
In DevOps Manager UI under **Projects** > **Service Settings**, specify the **Target Directory** explicitly:
```text
vps-infra/apps/<app>
```
(e.g., `vps-infra/apps/omr-api` or `vps-infra/apps/omr-web`).

#### Option 3: Host Compatibility Symlinks (Legacy Fallback)
For legacy platform versions, `setup.sh` maintains non-destructive compatibility symlinks under `/var/www/`:
```bash
sudo ln -sfn /var/www/vps-infra/apps /var/www/apps
sudo ln -sfn /var/www/vps-infra/apps/<app> /var/www/<app>
```

