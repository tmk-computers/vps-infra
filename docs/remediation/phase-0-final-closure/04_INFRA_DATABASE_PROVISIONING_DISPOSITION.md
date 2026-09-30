# 04 INFRASTRUCTURE DATABASE PROVISIONING SCRIPT DISPOSITION

**Document ID**: `FINAL-CLOSURE-04-DB-PROVISIONING-DISPOSITION`  
**Phase**: Phase 0 — Final Codex Closure Corrections  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex FR-C1-01 (`06_FINAL_FINDINGS_REGISTER.md:53-64`)  
**Status**: COMPLETE — OPTION A FORMALLY ADOPTED  

---

## 1. Executive Summary

During the Codex Final Re-Gate, an unaccounted commit was identified on the `main` branch of the `vps-infra` repository:
- **Commit**: `10a2e77c068ef70941d55d14a5e2d560c3fcf6c0`
- **Author**: Avadhut Kore <amkore01@gmail.com>
- **Date**: Tue Sep 29 18:55:47 2026 +0000
- **Commit Message**: `feat(postgres): add create-readonly-analyst script for clever_farmer_uat`
- **Added Path**: `db/postgres/create-readonly-analyst.sh`

This document provides a comprehensive line-by-line technical, privilege, and security assessment of the script, evaluates candidate disposition options, and establishes the formal disposition under **Option A (Include in Phase 0 Candidate Baseline)**.

---

## 2. Line-by-Line Technical & Security Inspection

### 2.1 File Identity & Invocation
- **Path**: `vps-infra/db/postgres/create-readonly-analyst.sh`
- **Lines of Code**: 43 lines (Bash script).
- **Executable Shebang**: `#!/bin/bash` with `set -e` on line 6.
- **Invocation Model**: Standalone administrative shell script intended to be run on the Linux Docker host:
  ```bash
  ./create-readonly-analyst.sh [username] [password]
  ```
- **Execution Mechanism**: Invokes `docker exec -i "$CONTAINER_NAME" psql -U postgres` directly against the running `shared_postgres` container.

### 2.2 Credentials Handled & Privilege Model
- **Container Name**: Hardcoded to `shared_postgres` (line 8).
- **Target Database**: Hardcoded to `clever_farmer_uat` (line 9).
- **Username Default**: `ANALYST_USER="${1:-clever_farmer_analyst}"` (line 10).
- **Password Default (SECURITY RISK)**: 
  ```bash
  ANALYST_PASS="${2:-AM8xoChSNNgfcrhlLdc5Rnum}"
  ```
  Line 11 embeds a hardcoded 24-character plaintext fallback password. If an operator invokes `./create-readonly-analyst.sh` without a second argument, the predictable fallback credential is provisioned.
- **Privilege Model**: Runs as the PostgreSQL superuser `postgres` via `docker exec`.

### 2.3 PostgreSQL Roles & Database Permissions (Write Actions)
Although described as creating a "read-only user", executing this script performs significant **database write mutations** on PostgreSQL access controls:
1. **Role Creation/Alteration** (lines 17–25):
   - Queries `pg_catalog.pg_roles`.
   - Executes `CREATE ROLE $ANALYST_USER WITH LOGIN PASSWORD '$ANALYST_PASS';` or `ALTER ROLE $ANALYST_USER WITH LOGIN PASSWORD '$ANALYST_PASS';`.
2. **Database Permissions** (lines 27–28):
   - `GRANT CONNECT ON DATABASE clever_farmer_uat TO $ANALYST_USER;`
   - `REVOKE CREATE ON DATABASE clever_farmer_uat FROM $ANALYST_USER;`
3. **Schema & Table Access** (lines 33–36):
   - `GRANT USAGE ON SCHEMA public TO $ANALYST_USER;`
   - `REVOKE CREATE ON SCHEMA public FROM $ANALYST_USER;`
   - `GRANT SELECT ON ALL TABLES IN SCHEMA public TO $ANALYST_USER;`
   - `GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO $ANALYST_USER;`
4. **Default Privilege Mutations** (lines 38–39):
   - `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO $ANALYST_USER;`
   - `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON SEQUENCES TO $ANALYST_USER;`

### 2.4 Network & Security Surface Analysis
- **Exposure**: The script does not alter Docker port bindings or Traefik routes. However, if PostgreSQL port 5432 is exposed or forwarded, an attacker possessing knowledge of the hardcoded password can read all tenant tables and sequences in `clever_farmer_uat`.
- **Credential Safety Violation**: The hardcoded fallback credential violates **MR-02** (Encrypted Secret Storage) and **MR-07** (Dynamic Setup Secrets).

---

## 3. Engineering Assessment & Classification

| Evaluation Dimension | Analysis |
|---|---|
| **Belongs to Product Implementation?** | **No**. It is not part of the compiled .NET web API, frontend SPA, or CI server. |
| **Belongs to Operational Tooling?** | **Yes**. It is an administrative operational helper script for database maintenance and UAT data inspection. |
| **Affects Master Remediation Scope?** | **Yes**: Direct overlap with **MR-05** (Least-Privilege Database Roles) and **MR-02/MR-07** (Elimination of Static Passwords). |
| **Changes Phase 0 Architecture?** | **No**. Phase 0 target architecture already specifies PostgreSQL 16 role isolation, least privilege, and dynamic high-entropy credentials. |

---

## 4. Disposition Options & Final Selection

### Option A: Include in Phase 0 Candidate Baseline (SELECTED)
- **Rationale**:
  1. Commit `10a2e77` was authored on `main` by repo owner `Avadhut Kore`. It represents genuine operational tooling.
  2. Deleting legitimate repository work or pretending it does not exist merely to fabricate a zero-diff audit result is an unacceptable evasion of governance truth.
  3. By adopting Option A, the candidate baseline is updated to HEAD `17486949`, the delta is honestly classified as operational tooling drift, and its security defects are placed under binding remediation contracts.

### Option B: Revert / Exclude from Candidate Baseline (REJECTED)
- **Rationale for Rejection**:
  Reverting legitimate operational work from the main branch solely to satisfy an earlier frozen commit SHA would disrupt active developer workflows and constitute artificial compliance theater.

---

## 5. Phase 1 Mandatory Remediation Contract

Under Option A, the following binding remediation requirements are assigned to **Phase 1** (Shared Security Foundation):

1. **Mandatory Remediation Mapping**:
   - **MR-02 (Secret Storage)** & **MR-07 (Dynamic Setup Secrets)**: Eliminate the hardcoded fallback password `AM8xoChSNNgfcrhlLdc5Rnum` from line 11 of `create-readonly-analyst.sh`.
   - **MR-05 (Least-Privilege Role Provisioning)**: Require that password argument `$2` must be explicitly provided via high-entropy generation or interactive prompt; script MUST fail fast with exit code 1 if `$ANALYST_PASS` is empty or defaults.
2. **Access Control Hardening**:
   - Ensure the script enforces role isolation and cannot be invoked against production databases without explicit environment guards.
3. **Execution Verification**:
   - Live execution of this script remains unverified in Phase 0; it will be formally verified against live test infrastructure during Phase 1 acceptance testing.
