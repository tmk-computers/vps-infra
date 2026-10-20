# Application Stack Templates Specification

> **Document ID:** `V2-INFRA-MOD-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Module Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [OPERATOR_RUNBOOK.md](../06-operations/OPERATOR_RUNBOOK.md)

---

## 1. Stack Templates Overview

The platform provides standardized application deployment recipes located in `vps-infra/templates/`. When a tenant creates an application project in the DevOps Manager UI, the CI Server uses these templates to build and deploy customer containers.

---

## 2. Supported Application Runtimes & Template Files

Templates in `templates/` are organized as Docker Compose template files and Dockerfiles:

| Stack / Runtime | Compose Template File | Supporting Dockerfile / Config | Target Internal Port |
|---|---|---|---|
| **Node.js Web** | `templates/docker-compose.node-web.template.yml` | `Dockerfile.express` | `3000` |
| **Express API** | `templates/docker-compose.express-api.template.yml` | `Dockerfile.express` | `3000` |
| **.NET API** | `templates/docker-compose.dotnet-api.template.yml` | `Dockerfile.dotnet` | `8080` |
| **Python FastAPI** | `templates/docker-compose.fastapi.template.yml` | `Dockerfile.fastapi` | `8000` |
| **Python AI** | `templates/docker-compose.python-ai.template.yml` | Python / vLLM / requirements | `8000` |
| **PHP / Laravel** | `templates/docker-compose.laravel.template.yml` | `Dockerfile.laravel`, `nginx.laravel.conf` | `80` |
| **React SPA** | `templates/docker-compose.react-web.template.yml` | `Dockerfile.react`, `nginx.spa.conf` | `80` |
| **Angular SPA** | `templates/docker-compose.angular-web.template.yml`| `Dockerfile.angular`, `nginx.spa.conf` | `80` |
| **Spring Boot** | `templates/docker-compose.spring-boot.template.yml`| `Dockerfile.spring-boot` | `8080` |
| **Static Web** | `templates/docker-compose.static-web.template.yml` | `nginx:alpine` | `80` |

---

## 3. Automated Reverse Proxy Configuration via Traefik

When an application stack is deployed by the CI Server:
1. The container is attached to the external bridge network `traefik_net`.
2. Dynamic routing labels are embedded directly in the generated `docker-compose.yml`:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.${APP_NAME}.rule=Host(`${APP_DOMAIN}`)"
     - "traefik.http.routers.${APP_NAME}.entrypoints=websecure"
     - "traefik.http.routers.${APP_NAME}.tls=true"
     - "traefik.http.routers.${APP_NAME}.tls.certresolver=myresolver"
     - "traefik.http.services.${APP_NAME}.loadbalancer.server.port=${INTERNAL_PORT}"
   ```
3. Traefik automatically discovers the container, configures the reverse proxy route, and provisions Let's Encrypt TLS certificates using the `myresolver` ACME challenge. (Static Nginx host virtual-hosts are not used for edge routing).
