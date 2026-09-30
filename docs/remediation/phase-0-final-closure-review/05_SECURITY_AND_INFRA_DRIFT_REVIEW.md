# 05 SECURITY, INFRASTRUCTURE DRIFT & TLS CONTRACT REVIEW

**Document ID**: `FINAL-REVIEW-05-SECURITY-DRIFT`  
**Phase**: Phase 0 — Final Independent Closure Review  
**Review Cycle**: Final Independent Closure Review  
**Author**: Antigravity Conversation 2 — Independent Reviewer  
**Status**: Authoritative Security and Drift Audit Complete  
**Date**: 2026-09-30  

---

## 1. Infrastructure Database Provisioning Drift (Codex FR-C1-01)

### 1.1 Commit & File Origin
During the Codex Final Re-Gate, an operational commit was detected on the `main` branch of `vps-infra`:
- **Commit**: `10a2e77c068ef70941d55d14a5e2d560c3fcf6c0`
- **File**: `vps-infra/db/postgres/create-readonly-analyst.sh`
- **Purpose**: Creates or alters a read-only database role (`clever_farmer_analyst`) for `clever_farmer_uat`.

### 1.2 Inclusion in Candidate Baseline
The Developer adopted **Option A (Include in Phase 0 Candidate Baseline)**:
1. The script represents genuine operational database tooling authored by repository ownership.
2. The candidate baseline is formally updated to HEAD `dea86733d124877e50cea680e9f4c72ad0bc338c` in `vps-infra`.
3. The delta is explicitly classified as **operational database tooling drift** in [`02_FINAL_CANDIDATE_BASELINE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/02_FINAL_CANDIDATE_BASELINE.md), rejecting false claims of "zero runtime delta."

### 1.3 Technical & Security Analysis
Inspection of [`create-readonly-analyst.sh`](file:///d:/company/products/vps-infra/vps-infra/db/postgres/create-readonly-analyst.sh) reveals:
- **Write Actions**: Executes `CREATE ROLE` / `ALTER ROLE`, `GRANT CONNECT`, `GRANT USAGE`, `GRANT SELECT`, and `ALTER DEFAULT PRIVILEGES`. Although labeled "read-only", running the script performs significant database write mutations on access control structures.
- **Superuser Invocation**: Connects via `docker exec -i shared_postgres psql -U postgres`.
- **Security Flaw**: Line 11 contains a hardcoded plaintext fallback credential (`ANALYST_PASS="${2:-...}"`).

---

## 2. Compromised Database Credential Policy & Remediation Contract

The Reviewer audited the treatment of the exposed credential against security governance rules:

1. **Non-Reproduction**: The literal plaintext password is **NOT reproduced** in any remediation artifact.
2. **Compromised Classification**: The credential is officially classified as **compromised**.
3. **Mandatory Rotation & Revocation**: The credential MUST be rotated and revoked in any existing environment where the script was executed.
4. **Epistemic Honesty**: The Developer explicitly states that **credential rotation is NOT claimed to have already occurred** in Phase 0, but is mandated as an executable deliverable upon live environment access in Phase 1.
5. **Elimination of Fallbacks**: Future provisioning scripts MUST require dynamically supplied or generated credentials; hardcoded or fallback production credentials are strictly prohibited.
6. **Master Remediation Ownership**:
   - **MR-02 (Secret Storage) & MR-07 (Dynamic Setup Secrets)**: Eliminate line 11 fallback password; enforce dynamic high-entropy credential generation.
   - **MR-05 (Least-Privilege Role Provisioning)**: Enforce parameter validation (fail fast with exit 1 if `$ANALYST_PASS` is omitted).

*(Recorded as Reviewer guidance **R2-01** to ensure Phase 1 test suites explicitly assert dynamic credential generation and exit-1 failure on missing passwords for this script).*

**Reviewer Assessment**: **PASS**.

---

## 3. Windows Agent Fallback Secret: Source Reality vs Target Contract

### 3.1 Source Inspection
The Reviewer inspected the Windows agent code:
- [`vps-infra-server/scripts/tmk-iis-agent.ps1:21`](file:///d:/company/products/vps-infra/vps-infra-server/scripts/tmk-iis-agent.ps1#L21):
  ```powershell
  if ([string]::IsNullOrWhiteSpace($Secret)) {
      $Secret = "SuperCiSecretKey123!"
  }
  ```
- [`vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs:42`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/IisClientService.cs#L42):
  ```csharp
  _secret = _configuration["DeploySettings:CiSecret"] 
      ?? Environment.GetEnvironmentVariable("CI_SECRET") 
      ?? "SuperCiSecretKey123!";
  ```

### 3.2 Epistemic Reconciliation
The Developer corrected earlier audit overclaims in [`05_EVIDENCE_TRUTH_CORRECTIONS.md:30-40`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-final-closure/05_EVIDENCE_TRUTH_CORRECTIONS.md#L30-L40):
- **CURRENT IMPLEMENTATION**: The static fallback secret is **currently present** in the active source code.
- **TARGET ARCHITECTURE CONTRACT**: The static fallback secret **MUST be completely removed**.
- **OWNERSHIP**: Master Remediation **MR-28** (scheduled for implementation in **Phase 1: Shared Security Foundation**).
- **ACCEPTANCE CRITERION**: The Windows Agent and DevOps Manager API must fail startup immediately if default or static fallback credentials are detected; authentication must rely exclusively on dynamically generated mutual authentication tokens.

**Reviewer Assessment**: **PASS**. Target architecture is no longer falsely described as current implementation.

---

## 4. Peer-Authenticated TLS Contract (`SSL Mode=VerifyFull`) (Codex FR-C2-01)

### 4.1 Insecurity of `SSL Mode=Require` in Npgsql
Codex finding `FR-C2-01` highlighted that Npgsql documentation establishes:
- `SSL Mode=Require`: Encrypts network traffic, but **does not authenticate the server certificate** or validate hostnames. An attacker performing a man-in-the-middle attack with any certificate (or self-signed cert) can intercept connections.
- Setting `Trust Server Certificate=false` alone does not convert `Require` into `VerifyFull`.
- Installing a CA certificate into the Windows Certificate Store does not establish server authentication unless the client driver performs CA chain validation and hostname matching (`VerifyFull`).

### 4.2 Standardized Production TLS Contract
The Developer completely excised the misleading `Require + Trust Server Certificate=false` alternative from all active authoritative documents. The contract across [`04_TARGET_ARCHITECTURE.md:173`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md#L173), [`05_SUPPORTED_OS_MATRIX.md:68`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md#L68), [`06_DATABASE_SUPPORT_MATRIX.md:40`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md#L40), and [`16_PHASEWISE_REMEDIATION_PLAN.md:114`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md#L114) now uniformly mandates:
> **`SSL Mode=VerifyFull` with validated CA and hostname verification.**  
> Unauthenticated encryption or certificate validation bypass is strictly prohibited.

Ripgrep confirmed zero occurrences of `Trust Server Certificate=false` in the authoritative baseline.

**Reviewer Assessment**: **PASS**.

---

## 5. Reviewer Domain Verdict

- **Infrastructure Drift Disposition**: **PASS** (Honestly included in candidate; classified as operational tooling drift).
- **Compromised Credential Policy**: **PASS** (Classified as compromised, rotation mandated in Phase 1, no reproduction).
- **Windows Fallback Secret Honesty**: **PASS** (Current code reality clearly separated from Phase 1 target contract).
- **Peer-Authenticated TLS Contract**: **PASS** (`SSL Mode=VerifyFull` standardized; unauthenticated modes eradicated).
