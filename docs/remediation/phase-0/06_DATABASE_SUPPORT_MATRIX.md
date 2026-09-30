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
| **Redis 7** | **YES** (Standard) | **TARGET STANDARD** | **N/A** (Non-authoritative cache) | **FIRST-CLASS PRODUCTION CACHE** | **IN-SCOPE (Standard)** | Internal bridge (`shared_redis`) / remote endpoint | **Standard Production Cache & Acceleration Layer**: Established as a first-class standard production infrastructure component for distributed caching, rate limiting, and Pub/Sub event distribution. Non-authoritative: PostgreSQL remains the sole durable source of truth. |

---

## 3. Pilot Gate A Approved Database & Caching Profile

### 3.1 Exclusively Supported Durable Relational Store: PostgreSQL 16
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

### 3.2 First-Class Standard Production Cache & Acceleration: Redis 7
- **Architecture Role**: Redis 7 is a first-class component of the standard production architecture, deployed alongside PostgreSQL 16.
- **Strict Invariant**: **Redis SHALL NOT be the sole authoritative durable store for safety-critical platform state.** PostgreSQL remains the sole durable source of truth for deployment state, release history, tenant configuration, users, authorization state, durable credential/token revocation, audit history, recovery metadata, licensing, critical configuration, and billing records.
- **Architectural Responsibilities**:
  - Distributed caching and short-lived session state;
  - API rate limiting and monotonic spend tracking caches;
  - Pub/Sub event fan-out and real-time status distribution (WebSockets / SSE);
  - Token and revocation caching acceleration (`Local Cache -> Redis 7 -> PostgreSQL`);
  - Lock pre-filtering and distributed worker coordination (complementing, not replacing, PostgreSQL advisory locks and epoch fencing);
  - LLM response caching and AI tool-result caching;
  - Future AI Workforce and agent coordination infrastructure.
- **Failure Model & Degraded Operation**:
  - Redis unavailability MUST NOT by itself cause loss of deployment truth, authorization truth, credential revocation truth, audit history, recovery metadata, or release history.
  - Where safe fallback is possible, the platform SHALL fall back to the durable PostgreSQL store.
  - Where safe fallback is not possible, the affected operation SHALL fail safely rather than proceed using stale or unverifiable state.
- **Revocation Pipeline & Invariant**:
  - PostgreSQL (`RevokedTokens` table) is the durable revocation authority.
  - Redis is the fast shared revocation cache; local process cache is lowest-latency cache (`Local Cache -> Redis 7 -> PostgreSQL`).
  - **Revocation Effective Point**: A credential/token revocation becomes security-effective when the authoritative PostgreSQL revocation transaction commits. For any authorization decision initiated after that effective point, stale cache state MUST NOT authorize the revoked credential; the request MUST be denied (`DENY` / HTTP 401).
  - Revocation writes must commit to PostgreSQL before being reported successful, followed by Redis cache update/invalidation. Cache misses or Redis outages fall back safely to PostgreSQL, never bypassing security truth.
  - Operational cache convergence SLOs (e.g. $\le 5$s) govern propagation timing only and NEVER constitute an authorization grace period.
- **Security & Topology Requirements**:
  - Authentication enabled (`requirepass` with dynamic high-entropy secret generated during setup);
  - Bound strictly to internal loopback (`127.0.0.1`) or private container network bridge (`traefik_net`); zero public WAN exposure;
  - TLS encryption where connections cross untrusted network boundaries;
  - Memory bounds configured (`maxmemory`, appropriate eviction policy e.g. `volatile-lru`);
  - Monitoring for memory usage, connection spikes, and latency degradation.
- **Gate-A Acceptance Testing Scenarios**:
  1. *Normal Operation*: Redis healthy and available.
  2. *Redis Unavailable*: Critical platform state remains safe; platform falls back to PostgreSQL or fails safe.
  3. *Redis Restart*: Cache and coordination state reconciles correctly.
  4. *Stale Cached Security Data*: Stale cache entries must not permit revoked credentials. For requests initiated post-PostgreSQL revocation commit, stale cache entries MUST NOT permit authorization; request receives HTTP 401 DENY. Acceptance criterion: exactly ZERO post-revocation authorizations allowed by stale cache state.
  5. *Redis Data Loss*: Flush/wipe of Redis data must not destroy or corrupt authoritative platform state.
  6. *Redis Latency/Degradation*: High latency or queue saturation must not silently convert safety checks into permissive behavior; platform falls back to PostgreSQL or fails closed.

### 3.3 Enforcement for Customer Application Database Engines
- During Pilot Gate A, selecting Oracle, MariaDB, SQL Server, or MongoDB for customer application database provisioning in DevOps Manager UI or API will return an explicit HTTP 400 Bad Request with:
  `"This database engine is not qualified under Pilot Gate A certification. Please select PostgreSQL 16."`
- *(Note: Redis 7 is managed directly by the platform runtime as a shared caching and acceleration layer, not provisioned as a general-purpose customer application database).*
