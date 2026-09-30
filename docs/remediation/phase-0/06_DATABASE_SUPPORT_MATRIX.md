# 06 DATABASE ENGINE SUPPORT & QUALIFICATION MATRIX

**Document ID**: `REMED-P0-06`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Status**: Authoritative Database Matrix Frozen  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. Database Governance Policy

Database engines must never be claimed as supported in production unless their full operational lifecycle—including provisioning, least-privilege role creation, health checks, backup generation, remote offsite replication, and proven bare-metal restoration—has been demonstrated.

Lifecycle Classification Tiers:
- **ADVERTISED**: Mentioned in documentation, marketing, or UI dropdowns.
- **IMPLEMENTED**: Manifests, docker-compose files, or backup handlers exist in the repository.
- **CERTIFIED FOR PILOT (Gate A)**: Qualified with end-to-end backup, strict restore verification, and resource controls.
- **CERTIFIED FOR COMMERCIAL (Gate B)**: Multi-tenant, encryption-at-rest, point-in-time recovery (PITR) certified.

---

## 2. Explicit Database Engine Matrix

| Database Engine | Advertised in Docs? | Manifest Implemented? | Backup / Restore Handlers Implemented? | Gate A Certified (Pilot)? | Gate B Certified (Commercial)? | Deployment Topology | Operational & Security Assessment |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **PostgreSQL 16** | **YES** | **YES** (`db/postgres/docker-compose.yml`) | **YES** (`pg_dump` / `pg_restore`) | **PRIMARY PILOT (Gate A)** | **PENDING PHASE 12** | Containerized on internal `traefik_net` | **Approved for Pilot Gate A**. Requires least-privilege role provisioning (MR-05), binding to loopback/internal net (MR-06), and strict restore verification (MR-15). |
| **Microsoft SQL Server** | **YES** | **YES** (`db/sql-server/docker-compose.yml`) | **PARTIAL** (`sqlcmd` script) | **NOT IN GATE A** (Deferred) | PENDING EVAL | Linux Container or Native Windows | Manifest exists, but automated verification and licensing considerations require separate qualification. |
| **MariaDB / MySQL 11** | **YES** | **YES** (`db/mariadb/docker-compose.yml`) | **PARTIAL** (`mysqldump` script) | **NOT IN GATE A** (Deferred) | PENDING EVAL | Containerized | Compose exists; port 3306 exposed to `0.0.0.0` (MR-06); deferred to prevent pilot surface dilution. |
| **Oracle Database** | **YES** | **YES** (`db/oracle/docker-compose.yml`) | **DEFECTIVE** (`OracleBackupHandler.cs`) | **EXCLUDED** (Unsupported) | PENDING EVAL | Containerized | Critical defect F19: handler swallows expdp/impdp errors and returns false success; strictly excluded from Gate A. |
| **MongoDB** | **YES** | **YES** (`db/mongodb/docker-compose.yml`) | **NO** | **EXCLUDED** (Unsupported) | PENDING EVAL | Containerized | No automated backup or verification logic implemented. |
| **Redis 7** | **YES** (PRDs/Audit) | **NO** (0 manifests in repo) | **NO** | **EXCLUDED** (Unsupported) | PENDING EVAL | None (Ghost manifest) | **Audit Assertion Reconciled**: Claimed in Antigravity audit, but 0 manifests exist in `vps-infra`. Must be designed from scratch post-pilot for caching. |

---

## 3. Pilot Gate A Approved Database Profile

### 3.1 Exclusively Supported: PostgreSQL 16
- **Linux Deployment Topology**: Containerized on internal `traefik_net` bridge (`shared_postgres`), port 5432 bound strictly to `127.0.0.1` or internal bridge.
- **Windows Deployment Topology**: Remote PostgreSQL 16 endpoint (dedicated Linux VM or managed PostgreSQL service) accessed over authenticated TLS port 5432 (`SSL Mode=VerifyFull` with validated CA and hostname verification; unauthenticated trust bypass is strictly prohibited). (WSL2 and Docker Desktop on Windows Server are explicitly uncertified and prohibited for Gate A).
- **Role Isolation**:
  - `devops_admin`: Dedicated role for DevOps Manager platform schema.
  - Per-Application User: Unique least-privilege role per customer application (e.g. `kaksha_user`) with permissions restricted strictly to its own database.
  - Prohibition of shared superuser credentials in application compose files.
- **Backup & DR Standard**:
  - Automated daily consistent snapshot via `pg_dump -Fc` (custom format).
  - Format-aware local verification via `pg_restore --list` (validating custom archive header and Table of Contents (TOC) parseability; does not decompress data blocks; invalid `gzip -t` prohibited).
  - Client-side envelope encryption with AES-256-GCM using off-host escrowed key recovery kit.
  - Atomic offsite dispatch to verified cloud storage with remote SHA-256 digest check and authenticated `RecoveryPoint` manifest cataloging.
  - Periodic automated DR drill with real data restore verifying table row counts and integrity invariants.

### 3.2 Enforcement for Other Engines
- During Pilot Gate A, selecting Oracle, MariaDB, SQL Server, MongoDB, or Redis in DevOps Manager UI or API will return an explicit HTTP 400 Bad Request with:
  `"This database engine is not qualified under Pilot Gate A certification. Please select PostgreSQL 16."`
- Eliminates silent failures, unverified backups, and operational downtime.
