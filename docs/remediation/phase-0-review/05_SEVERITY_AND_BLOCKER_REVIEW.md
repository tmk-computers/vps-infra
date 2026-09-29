# 05 SEVERITY AND PILOT BLOCKER INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-05`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Investigation of Numerical Inconsistency in Blocker Counts (Finding R0-01)

### 1.1 The Inconsistency
In [`02_MASTER_REMEDIATION_REGISTER.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md) (line 89) and [`PHASE_0_FINAL_REPORT.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/PHASE_0_FINAL_REPORT.md) (line 81), the text heading explicitly states:
> `Shared Pilot Blockers (15 Items):`

However, the parenthesized inventory immediately underneath enumerates **17 items**:
`MR-02`, `MR-03`, `MR-04`, `MR-07`, `MR-08`, `MR-09`, `MR-11`, `MR-12`, `MR-13`, `MR-14`, `MR-15`, `MR-18`, `MR-19`, `MR-32`, `MR-34`, `MR-36`, `MR-37`.

Similarly, in [`02_MASTER_REMEDIATION_REGISTER.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md) line 90, the heading states:
> `Linux-Specific Pilot Blockers: 5 Items`

However, the parenthesized list enumerates **6 items**:
`MR-01`, `MR-05`, `MR-06`, `MR-10`, `MR-16`, `MR-35`. (Note: In `PHASE_0_FINAL_REPORT.md` line 100, Developer corrected this heading to "6 Items", but left the Shared heading at "15 Items").

### 1.2 Forensic Root Cause Analysis
The Reviewer traced the exact genesis of this counting discrepancy:
1. **Initial Baseline Count Before Delta Findings**:
   Prior to discovering the 4 post-audit current-main findings (`MR-34`, `MR-35`, `MR-36`, `MR-37`), the shared blocker inventory contained **14 items** (`MR-02`, `MR-03`, `MR-04`, `MR-07`, `MR-08`, `MR-09`, `MR-11`, `MR-12`, `MR-13`, `MR-14`, `MR-15`, `MR-18`, `MR-19`, `MR-32`), and the Linux blocker inventory contained **5 items** (`MR-01`, `MR-05`, `MR-06`, `MR-10`, `MR-16`).
2. **Failure to Recalculate Heading Tokens Upon Appending Delta Findings**:
   When Conversation 1 identified the 4 current-main findings:
   - `MR-35` was appended to the Linux blocker list (bringing the total from 5 to 6).
   - `MR-34`, `MR-36`, and `MR-37` were appended to the Shared blocker list (bringing the total to 17).
   - The Developer manually wrote "15 Items" (an off-by-two manual counting error) rather than updating the heading to "17 Items".
3. **Discrepancy Severity**: Classified as **R0-01**. This is an internal reporting and counting defect that must be corrected in the Phase 0 artifacts.

---

## 2. Table Column vs. Summary Inventory Discrepancy (Finding R0-02)

A deeper mathematical audit revealed a secondary blocker discrepancy:
- In [`02_MASTER_REMEDIATION_REGISTER.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/02_MASTER_REMEDIATION_REGISTER.md), the table column `Pilot Blocker?` has value `YES` for **34 items**. (Only `MR-20`, `MR-30`, and `MR-31` have `No`).
- However, the summary inventories list only **31 items** in total:
  - Shared: 17 items
  - Linux: 6 items
  - Windows: 8 items
  - Sum: $17 + 6 + 8 = 31$ items.
- **The Missing 3 Items**:
  - `MR-17` (Safe Cleanup & Retention, Linux, P1): Marked `YES` in table row 49, but omitted from Linux blockers summary.
  - `MR-21` (Honest Product Claims / Docs, Shared, P2): Marked `YES` in table row 53, but omitted from Shared blockers summary.
  - `MR-33` (Dual-OS Failure-Injection Certification, Shared, P1): Marked `YES` in table row 65, but omitted from Shared blockers summary.

**Resolution Required**: The Developer must synchronize the table column and summary lists. If `MR-21` is scheduled for Phase 9 polish, its table entry should indicate `No (Phase 9 Polish)`; if `MR-17` and `MR-33` are required for Gate A, they must be added to the blocker summary lists.

---

## 3. Independent Severity Review of MR-34, MR-35, MR-36, MR-37

The Reviewer evaluated the Developer's assigned severities against standard engineering definitions:
- **P0 (Catastrophic / Immediately Exploitable)**: Critical defect or vulnerability that compromises host root, discloses master credentials, exposes databases to WAN, causes data loss, or renders core deployment/rollback totally broken.
- **P1 (Mandatory Blocker)**: Mandatory pilot or commercial blocker that must be resolved prior to the relevant gate, but is not an immediate host/data catastrophe.
- **P2 (Hardening / Truthfulness / Polish)**: Important correctness, telemetry, or documentation issue that does not independently halt single-VM pilot deployment.

### 3.1 MR-34: Maintenance Schema Migration Safety
- **Developer Stated Severity**: `P0`
- **Reviewer Evaluated Severity**: **P0** (Warranted)
- **Justification**: Introducing 13 entity properties without an EF Core migration or seeding DDL causes immediate SQLSTATE 42703 column-missing exceptions on PostgreSQL whenever `Products` or `ProjectServices` are queried. While PostgreSQL daemon does not crash, the entire DevOps Manager application fails on product endpoints and deployment lookups. A broken database schema in production is a bona fide P0 data integrity defect.

### 3.2 MR-35: Maintenance State & Compose Service Isolation
- **Developer Stated Severity**: `P0`
- **Reviewer Evaluated Severity**: **P0** (Warranted)
- **Justification**: Global regex replacement across `docker-compose.yml` mutates all environment blocks, indiscriminately injecting maintenance variables into databases, caches, and sibling services. Contaminating unrelated services and corrupting compose YAML during normal maintenance operations constitutes an unacceptable operational safety defect.

### 3.3 MR-36: AMS Authorization & CI Auth Breakdown
- **Developer Stated Severity**: Table says `P0`, Summary says `P1` (Contradiction R0-03)
- **Reviewer Evaluated Severity**: **P1** (Mandatory Blocker, NOT P0)
- **Justification**:
  1. `optionalAuth` exposes read endpoints to the network, revealing architectural structure (filenames, framework versions, unit types). This is an information disclosure vulnerability, but does NOT allow arbitrary code execution, file mutation, or privilege escalation.
  2. The proxy call from `ProductController` fails with HTTP 401 Unauthorized because it lacks a Bearer token. This renders the "Recalculate Modernization Score" button non-functional. A broken recalculate button on an internal diagnostic metric is an operational defect, but not a catastrophic P0 infrastructure failure.
  3. **Conclusion**: MR-36 is a mandatory **P1 Pilot Blocker**. It should be classified as `P1` in both the table and summary metrics to prevent severity inflation.

### 3.4 MR-37: AMS Semantics & Commercial Truthfulness
- **Developer Stated Severity**: `P1`
- **Reviewer Evaluated Severity**: **P2** (Truthfulness / UI Polish; Gate A Blocker if commercialized)
- **Justification**: Labeling a static regex analyzer as "Application Modernization Score" is misleading marketing, but does not cause operational crashes or security breaches. However, as an architectural truthfulness requirement before selling to external customers, it functions as a Gate A blocker. Classifying it as P1 or P2 with Pilot Blocker status is acceptable.

---

## 4. Preservation of Codex Historical P0 Findings

The Developer preserved and appropriately retained the critical severity of all original Codex P0 findings:
- `F01` (Docker socket in test runner) → `MR-01` (**P0**)
- `F02` (Signing defaults & forged identities) → `MR-02` (**P0**)
- `F03` (Committed Google RSA private key) → `MR-03` (**P0**, upgraded from Codex P1)
- `F07` (Postgres & admin ports published to 0.0.0.0) → `MR-06` (**P0**, upgraded from Codex P1)
- `F08` (Deployment success without health verification) → `MR-10` (**P0**, upgraded from Codex P1)
- `F09` (IIS agent fatal AST syntax error) → `MR-22` (**P0**, upgraded from Codex P1)
- `F18` (Upgrade script hard reset without backup/health) → `MR-19` (**P0**, upgraded from Codex P1)

Upgrading these historical P1 findings to P0 is fully justified by runtime evidence: committed private keys, public database bindings, broken upgrade scripts, and non-functional deployment agents are genuine P0 blockers.
