# 05 BACKUP RECOVERY AND WINDOWS ARCHITECTURE REVIEW

**Document ID**: `REMED-R4-05`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Review Cycle**: R4 (Final Independent Review of Codex Re-Gate Remediation)  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Status**: Authoritative Architectural Audit Complete  
**Date**: 2026-09-30  

---

## 1. Backup Verification & Integrity Claims (Codex C1-02)

### 1.1 Local Archive Verification Boundaries
In earlier documentation, local backup verification made overstated technical claims regarding `pg_restore --list`, suggesting that listing the archive validated underlying compressed data blocks.

**Authoritative Text Inspection**:
[`09_BACKUP_RECOVERY_CONTRACT.md:49-53`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md#L49-L53) explicitly refines the verification scope:
> `Stage 2: Format-Aware Local Verification`  
> `- Verification Engine: pg_restore --list "$LOCAL_BACKUP_PATH"`  
> `- Integrity Scope & Limits: pg_restore --list verifies the custom archive header and Table of Contents (TOC) parseability. It asserts that the archive structure can be read and listed, and validates non-zero table and schema counts. Crucial Precision: It does NOT decompress data blocks or prove full table data integrity. Full data and relational integrity is proven exclusively via real automated restore drills. Prohibits invalid gzip -t on custom -Fc archives.`

**Reviewer Assessment**: **PASS**. The claim is technically precise, honest, and explicitly reserves full data integrity validation for executable restore drills.

---

## 2. Backup Cryptography & Offsite Escrow Contract

### 2.1 Cryptographic Architecture
[`09_BACKUP_RECOVERY_CONTRACT.md:54-58,81-96`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md#L54-L58) defines the envelope encryption model:
1. **Authenticated Envelope Encryption**: AES-256-GCM. Plaintext database dumps are encrypted locally with a single-use 256-bit Data Encryption Key (DEK). Plaintext data never touches the network.
2. **Key Encryption Key (KEK)**: The DEK is encrypted using a KEK derived from an off-host recovery passphrase via Argon2id (or managed enterprise key vault).
3. **Recovery Derivation Metadata**: Each recovery point includes non-secret cryptographic metadata: Argon2id salt, KEK version, 96-bit GCM initialization vector (IV), and 128-bit authentication tag.
4. **Off-Host Recovery Self-Sufficiency**: If the primary host is completely destroyed, recovery on a clean machine requires **only**:
   - The offsite storage access credentials and endpoint;
   - The off-host master passphrase/key;
   - The offsite manifest catalog containing the salt, KEK version, and IVs;
   - A clean base operating system.
   Zero dependencies exist on local registries, files, or DPAPI keys from the destroyed host.
5. **Key Versioning & Rotation**: Historical backups encrypted under KEK Version 1 can be decrypted after KEK Version 2 is activated, as the manifest specifies the exact KEK version required.

### 2.2 Realistic RPO and RTO Targets
[`09_BACKUP_RECOVERY_CONTRACT.md:98-106`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/09_BACKUP_RECOVERY_CONTRACT.md#L98-L106) eliminates unrealistic claims of instantaneous zero-loss rollbacks:
- **Recovery Point Objective (RPO)**: **24 hours** (scheduled daily) / **1 hour** (pre-deployment snapshot).
- **Recovery Time Objective (RTO)**: **30 minutes** (disaster recovery target).
- **Governance Status**: Explicitly defined as **operational targets subject to Phase 5 validation**, NOT current certified guarantees.

---

## 3. Windows Server 2022 Native Topology (Codex C1-03)

### 3.1 Authoritative Topology Definition
[`05_SUPPORTED_OS_MATRIX.md:61-73`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md#L61-L73) and [`04_TARGET_ARCHITECTURE.md:48-62`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md#L48-L62) freeze the native Windows Gate-A architecture:

```mermaid
graph TD
    subgraph Windows Server 2022 Native Host
        HTTP_SYS[HTTP.sys Driver / Ports 80 & 443] --> IIS[IIS 10.0 Native Web Server]
        IIS --> ANCM[ASP.NET Core Module]
        ANCM --> AppPool[AppPools: 127.0.0.1:508x]
        
        Agent[TMK.Agent.Windows Service] --> |Dedicated Identity| SecCtx[NT SERVICE\TMKAgent]
        SecCtx --> |DACLs| Staging[C:\inetpub\staging]
        SecCtx --> |DACLs| Apps[C:\inetpub\wwwroot\apps\{tenant}]
        SecCtx --> |Manage| IIS
    end

    subgraph Linux Control Plane
        DVM[DevOps Manager API] --> |mTLS + Scoped Bearer: Port 5055| Agent
    end

    subgraph Remote Data Tier
        AppPool --> |TLS Port 5432: Validate CA / No Trust Bypass| Postgres[(Remote PostgreSQL 16)]
    end
```

### 3.2 Elimination of Legacy Contradictions
The Reviewer verified the total absence of contradictory legacy Windows architectures across all authoritative baseline files:
- **Traefik on Windows**: **EXCLUDED**. HTTP.sys and IIS 10 own ports 80 and 443. Traefik is not deployed on Windows hosts, eliminating port binding collisions.
- **Docker Desktop on Windows**: **EXCLUDED**. Prohibited for Gate A.
- **WSL2 PostgreSQL**: **EXCLUDED**. Applications connect to a remote PostgreSQL 16 instance. WSL2 is not a Gate-A certified dependency.

---

## 4. Windows Service Identity Architecture (Codex RG-C2-01)

### 4.1 Rejection of Bare LocalService
In the initial audit, the agent service was casually assigned to `LocalService`. However, `LocalService` lacks the necessary permissions to administer IIS, manage AppPools, or create virtual directories without dangerous privilege escalation.

### 4.2 Dedicated Least-Privilege Identity Contract
[`05_SUPPORTED_OS_MATRIX.md:66`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md#L66) and [`08_SECURITY_BOUNDARIES.md:105`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md#L105) establish the architectural invariant:
> `TMK.Agent.Windows runs as a compiled .NET Worker Windows Service under a dedicated least-privilege Windows service identity (e.g. NT SERVICE\TMKAgent) with explicitly granted required rights: IIS administration / AppPool control, deployment filesystem rights (C:\inetpub\staging\ and C:\inetpub\wwwroot\), and SCM inspection; explicitly restricted from unrelated OS directories and LocalSystem privileges.`

**Reviewer Assessment**: The governance contract correctly specifies the **least-privilege permissions model** rather than relying on default system accounts.

---

## 5. Windows Database TLS & Certificate Validation

### 5.1 TLS Security Invariant
Workloads running on Windows Server connect across the network to a remote PostgreSQL 16 cluster. [`05_SUPPORTED_OS_MATRIX.md:68`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md#L68) explicitly specifies:
> `Workloads connect to a Remote PostgreSQL 16 Endpoint over authenticated TLS port 5432 (SSL Mode=VerifyFull or SSL Mode=Require;Trust Server Certificate=false with validated CA/pinning; unauthenticated server certificate trust or validation bypass is strictly prohibited).`

### 5.2 Beyond Connection String Flags
The Reviewer confirms that the security contract mandates:
1. **Encrypted Transport**: TLS 1.2/1.3 encryption across the wire.
2. **CA Trust Chain Validation**: The PostgreSQL server certificate must chain to a trusted Root CA installed in the Windows Local Computer Trusted Root Certification Authorities store.
3. **Hostname Validation**: Server certificate Common Name (CN) or Subject Alternative Name (SAN) must match the configured connection host.
4. **Strict Prohibition of Insecure Flags**: `Trust Server Certificate=true` is banned from all configuration templates and production connection strings.

---

## 6. Windows Agent Authentication & Lifecycle

### 6.1 Defense-in-Depth Authentication
Management communication from the DevOps Manager to `TMK.Agent.Windows` on port 5055 implements two distinct layers:
1. **Transport Layer**: Mutual TLS (mTLS) with pinned client certificates, ensuring only the authorized DevOps Manager control plane can establish a TCP connection.
2. **Application Layer**: Scoped, short-lived JWT tokens (`aud: tmk-agent-windows`, `scope: agent:deploy:execute`) passed in the Authorization header.
3. **Static Fallback Elimination**: The hardcoded static secret `"SuperCiSecretKey123!"` has been completely eliminated from all architecture and code references.

### 6.2 Agent Self-Update & Rollback
Agent updates follow an atomic binary swap pattern:
1. The new agent executable is staged to `C:\Program Files\TMKAgent\staging\`.
2. The running service is stopped; existing binaries are renamed to `.bak`.
3. New binaries are placed into the active path and the service is started.
4. If `/health` fails to respond within 30 seconds or the service crashes on startup, the supervisor immediately restores the `.bak` binaries and restarts the service.
5. Incomplete updates or host crashes during upgrade reconcile deterministically on reboot.

---

## 7. Reviewer Domain Verdict

- **Backup Verification Precision**: **PASS** (TOC parseability acknowledged; restore drill required for data integrity).
- **Backup Envelope Cryptography**: **PASS** (DEK/KEK model, Argon2id salt, IV, self-sufficient offsite kit).
- **RPO / RTO Targets**: **PASS** (Correctly defined as operational targets, not false guarantees).
- **Windows Server 2022 Topology**: **PASS** (Native IIS 10, HTTP.sys 80/443, remote PostgreSQL 16 over TLS, no Traefik/WSL2/Docker Desktop).
- **Windows Service Identity**: **PASS** (Dedicated least-privilege service account with explicit rights).
- **Windows DB TLS & Agent Auth**: **PASS** (Authenticated TLS with CA validation; mTLS + scoped bearer tokens).
