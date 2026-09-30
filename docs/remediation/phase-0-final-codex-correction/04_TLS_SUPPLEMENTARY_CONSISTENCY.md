# 04 REMOTE DATABASE TLS SUPPLEMENTARY CONSISTENCY

**Document ID**: `FINAL-CORRECTION-04-TLS-CONSISTENCY`  
**Phase**: Phase 0 — Final Codex Closure Surgical Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Audit Reference**: Codex FR-C2-01 (`07_FINAL_FINDINGS_REGISTER.md:49-54`)  
**Status**: COMPLETE — ALL ACTIVE SUPPLEMENTARY ALTERNATIVES RECONCILED  

---

## 1. Executive Summary & Defect Scope

In the Codex Final Closure Gate, finding **`FR-C2-01`** was retained at severity C2 because while the canonical Phase 0 architecture documents ([`04_TARGET_ARCHITECTURE.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/04_TARGET_ARCHITECTURE.md), [`05_SUPPORTED_OS_MATRIX.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/05_SUPPORTED_OS_MATRIX.md), [`06_DATABASE_SUPPORT_MATRIX.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/06_DATABASE_SUPPORT_MATRIX.md), and [`16_PHASEWISE_REMEDIATION_PLAN.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/16_PHASEWISE_REMEDIATION_PLAN.md)) had standardized on `SSL Mode=VerifyFull`, active supplementary documents in historical remediation dossiers still contained positive recommendations permitting:
> `SSL Mode=Require;Trust Server Certificate=false with validated CA`

Codex correctly determined that:
1. In Npgsql, `SSL Mode=Require` encrypts the connection but **does not validate the server certificate against a trusted CA or verify the hostname** against certificate Subject Alternative Names (SAN).
2. Setting `Trust Server Certificate=false` in Npgsql does **not** elevate `Require` mode to peer-authenticated verification; it merely disables the insecure bypass flag while leaving `Require` mode's default behavior (channel encryption without certificate authentication) in effect.
3. Therefore, permitting `Require` as an alternative directly contradicted the canonical security posture requiring authenticated TLS.

This document records the complete excision and reconciliation of all surviving supplementary `Require` alternatives.

---

## 2. Definitive Canonical TLS Standard

The sole certified remote PostgreSQL 16 connection standard across all operating system targets is:

# `SSL Mode=VerifyFull`
**with trusted Certificate Authority (CA) validation and server hostname verification.**

### Prohibited Configurations:
1. `Trust Server Certificate=true`: **STRICTLY PROHIBITED** (disables all certificate trust validation).
2. `SSL Mode=Require`: **STRICTLY PROHIBITED** for remote production database endpoints (lacks peer certificate authentication and hostname verification).
3. `SSL Mode=Prefer` / `SSL Mode=Allow` / `SSL Mode=Disable`: **STRICTLY PROHIBITED**.

### Canonical Connection String Template:
```text
Host=postgres-host.internal;Port=5432;Database=clever_farmer_uat;Username=app_service;Password=***;SSL Mode=VerifyFull;SSL Root Certificate=C:\ProgramData\TMK\Certs\internal-ca.crt
```

---

## 3. Surgical Corrections Applied Across Active Dossiers

| File Path | Previous Text Context | Exact Surgical Correction Applied | Status |
|---|---|---|:---:|
| [`docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md#L84) | `using authenticated TLS connections (SSL Mode=VerifyFull or SSL Mode=Require;Trust Server Certificate=false with validated CA; unauthenticated Trust Server Certificate=true is strictly prohibited).` | Replaced with: `using authenticated TLS connections (**SSL Mode=VerifyFull** with validated CA and hostname verification; unauthenticated Trust Server Certificate=true and unauthenticated SSL Mode=Require without peer authentication are strictly prohibited).` | **RESOLVED** |
| [`docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md:91`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md#L91) | `Authoritative Rule: Authenticated TLS (SSL Mode=VerifyFull or SSL Mode=Require;Trust Server Certificate=false with validated CA).` | Replaced with: `Authoritative Rule: Peer-authenticated TLS (**SSL Mode=VerifyFull** with validated CA and hostname verification). Trust Server Certificate=true and unauthenticated Require mode without peer authentication are strictly prohibited.` | **RESOLVED** |
| [`docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md:96`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md#L96) | `Excised Trust Server Certificate=true. Required authenticated TLS with Trust Server Certificate=false.` | Replaced with: `Excised Trust Server Certificate=true and Require mode alternative. Mandated canonical SSL Mode=VerifyFull with validated CA and hostname verification.` | **RESOLVED** |

---

## 4. Active Baseline Consistency Audit

A repository-wide scan of all active baseline files (`docs/remediation/phase-0/`, `docs/remediation/phase-0-codex-remediation/`, `docs/remediation/phase-0-codex-regate-remediation/`, `docs/remediation/phase-0-final-closure/`, and `docs/remediation/phase-0-final-codex-correction/`) confirms:
- Positive statements recommending `Require` mode: **0 occurrences**.
- Permissive `Trust Server Certificate=true`: **0 occurrences**.
- Mandatory `SSL Mode=VerifyFull` adoption: **100% consistent across all active dossiers**.
