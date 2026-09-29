# 07 LINUX PRODUCTION BASELINE INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-07`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Linux Baseline Evaluation Overview

The Reviewer independently inspected the Linux baseline across both repositories, focusing on **Ubuntu 24.04 LTS**, Docker Engine, Docker Compose, Traefik ingress, PostgreSQL, and operational safety.

---

## 2. Linux Component-by-Component Forensic Audit

### 2.1 OS Support & Provisioning (`setup.sh`)
- **Current State**: [`setup.sh`](file:///d:/company/products/vps-infra/vps-infra/setup.sh) installs Docker Engine, creates Docker networks (`traefik_net`), and writes `.env`.
- **Defects Identified**:
  - Automatically copies `.env.example` with known static passwords (`StrongPostgres@123`, `5b5fea8...` JWT secret) if `.env` is absent (F02, DEF-04, MR-02, MR-07).
  - Lacks DNS pre-flight verification before ACME Let's Encrypt certificate challenge (DEF-14, MR-20).

### 2.2 Ingress & Reverse Proxy (Traefik)
- **Current State**: [`docker-compose.yml`](file:///d:/company/products/vps-infra/vps-infra/docker-compose.yml) configures Traefik v2/v3 with Let's Encrypt ACME and HTTP-to-HTTPS redirection.
- **Defects Identified**:
  - Traefik configuration operates effectively for containerized applications, but lacks rate limiting and connection burst limits on ingress entrypoints.

### 2.3 Database Management (PostgreSQL 16)
- **Current State**: [`db/postgres/docker-compose.yml`](file:///d:/company/products/vps-infra/vps-infra/db/postgres/docker-compose.yml) provisions `postgres:16-alpine` and `dpage/pgadmin4`.
- **Defects Identified**:
  - Line 19 publishes port `5432:5432` to all host interfaces (`0.0.0.0`), bypassing standard UFW packet filtering via Docker iptables NAT (F07, DEF-03, MR-06).
  - Application templates provide shared superuser credentials rather than dedicated least-privilege roles (F06, MR-05).

### 2.4 Container Deployment & Rollback Engine (`DeployService.cs`)
- **Current State**: `DeployService.cs` executes deployment via `docker compose stop`, `pull`, and `up -d`.
- **Defects Identified**:
  - Line 602 returns deployment success immediately after starting containers without executing HTTP readiness probes (F08, DEF-01, MR-10).
  - Rollback target is the mutable branch `origin/main` rather than an immutable content-addressed image digest, causing re-pulls of broken images (F10, DEF-13, MR-11, MR-12).
  - Deployments run as unmanaged fire-and-forget background tasks (`_ = Task.Run`) lacking execution durability across API restarts (DEF-07, MR-09).

### 2.5 Storage, Cleanup & Rollback Cache Preservation
- **Current State**: Automated pruning script [`scripts/cleanup-docker.sh`](file:///d:/company/products/vps-infra/vps-infra/scripts/cleanup-docker.sh) and `MonitoringService.cs:213`.
- **Defects Identified**:
  - Cleanup issues `docker system prune -a`, which wipes all non-running container images, completely destroying the local image cache required for fast deployment rollback (F13, DEF-16, MR-17).

### 2.6 CI Runner Isolation & Resource Controls (`build-runner.js`)
- **Current State**: `ci-server/api/build-runner.js` executes build and test containers on the Linux host.
- **Defects Identified**:
  - Line 145 mounts the host `/var/run/docker.sock` and `/var/www` into untrusted build containers, granting arbitrary host root control (F01, DEF-08, MR-01).
  - Build processes lack cgroup memory and CPU limits, allowing unconstrained compilation jobs to starve PostgreSQL and trigger kernel OOM panics (F14, DEF-12, MR-16).

### 2.7 Platform Upgrade Subsystem (`upgrade-client.sh`)
- **Current State**: Decoupled supervisor container executes `scripts/upgrade-client.sh`.
- **Defects Identified**:
  - Script executes `git reset --hard origin/main`, takes zero pre-upgrade database backup, executes zero health checks while reporting success, and has zero automated rollback (F18, MR-19).

---

## 3. Linux Gate A Independence Assessment

- **Independent Qualification**: The Phase 0 plan establishes that Linux Gate A can be evaluated independently from Windows Server.
- **Pilot Readiness**: Linux cannot be certified today due to 6 active P0/P1 pilot blockers (`MR-01`, `MR-05`, `MR-06`, `MR-10`, `MR-16`, `MR-35`).
- **Remediation Feasibility**: Following Phase 1 (Security), Phase 2 (Release Safety), and Phase 3 (Linux Adapter), Linux can safely enter its controlled pilot (Phase 13) without waiting for Windows, provided Windows remediation continues concurrently.
