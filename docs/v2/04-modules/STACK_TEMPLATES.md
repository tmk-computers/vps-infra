# Application Stack Templates Specification

> **Document ID:** `V2-INFRA-MOD-002`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Module Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md), [OPERATOR_RUNBOOK.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md)

---

## 1. Stack Templates Overview

The platform provides standardized application deployment recipes located in `vps-infra/templates/`. When a tenant creates an application project in the DevOps Manager UI, the CI Server uses these templates to build and deploy customer containers.

---

## 2. Supported Application Runtimes

| Stack Name | Template Directory | Base Docker Image | Default Port | Health Check Path |
|---|---|---|---|---|
| **Node.js** | `templates/node/` | `node:22-alpine` | `3000` | `/health` or `/` |
| **.NET Core** | `templates/dotnet/` | `mcr.microsoft.com/dotnet/aspnet:10.0` | `8080` | `/health` |
| **PHP / WordPress**| `templates/php/` | `php:8.3-fpm-alpine` + Nginx | `80` | `/index.php` |
| **Python** | `templates/python/` | `python:3.12-slim` + Uvicorn/FastAPI | `8000` | `/health` |
| **Static Web** | `templates/static/` | `nginx:alpine` | `80` | `/index.html` |

---

## 3. Automated Reverse Proxy Configuration

When a stack template is deployed:
1. The CI Server allocates an available internal dynamic port on `vps_backend_net`.
2. A virtual host entry is added to Nginx:
   ```nginx
   server {
       server_name app.tenant-domain.com;
       location / {
           proxy_pass http://customer-app-container:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
3. Certbot or Caddy automatically requests and installs an SSL/TLS certificate.
