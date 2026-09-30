# 04 Independent Review: FR-C2-01 Remote Database TLS Consistency

**Document ID**: `REVIEW-R5-04-FR-C2-01-TLS`  
**Role**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Target**: Codex Finding `FR-C2-01` (`07_FINAL_FINDINGS_REGISTER.md:49-54`)  
**Status**: VERIFIED & RESOLVED (PASS)  

---

## 1. Finding Overview & Defect Scope

In the Codex Final Closure Gate, finding **`FR-C2-01`** was retained at severity C2:
> Canonical architecture correctly requires `VerifyFull`. However, active first-remediation `Windows:84` and re-gate consistency scan `09:91` still permit `Require/Trust Server Certificate=false` with a CA. The final closure scan includes both dossiers in its active scope.

Codex required:
> Reconcile these positive alternative instructions or explicitly supersede them with the canonical `VerifyFull` rule. Do not rewrite immutable historical review reports.

---

## 2. Technical Context: Npgsql TLS Mechanics

In Npgsql (the .NET PostgreSQL data provider):
1. **`SSL Mode=Require`**: Negotiates TLS encryption across the wire, but **does not validate the server certificate** against a trusted Certificate Authority or verify that the server hostname matches the certificate Subject Alternative Names (SAN).
2. **`Trust Server Certificate=false`**: Merely disables the insecure explicit trust bypass flag. In Npgsql, setting `Trust Server Certificate=false` does **not** elevate `Require` mode to full certificate verification; it remains opportunistic/unauthenticated channel encryption susceptible to man-in-the-middle (MITM) attacks.
3. **`SSL Mode=VerifyFull`**: Explicitly requires both full certificate chain verification against a trusted Root CA and server hostname verification against the certificate CN/SAN.

Consequently, allowing `SSL Mode=Require;Trust Server Certificate=false` as an acceptable alternative directly contradicted the platform's security boundary requirements for peer-authenticated database connectivity.

---

## 3. Independent Verification of Active Dossier Excision

The Developer's surgical correction addressed every surviving instance in the active remediation dossiers:

### 3.1 `05_WINDOWS_TOPOLOGY_CORRECTION.md:84`
- **Previous Text**:  
  `using authenticated TLS connections (SSL Mode=VerifyFull or SSL Mode=Require;Trust Server Certificate=false with validated CA; unauthenticated Trust Server Certificate=true is strictly prohibited).`
- **Updated Canonical Text**:  
  `using authenticated TLS connections (**SSL Mode=VerifyFull** with validated CA and hostname verification; unauthenticated Trust Server Certificate=true and unauthenticated SSL Mode=Require without peer authentication are strictly prohibited).`
- **Verification**: Verified in [`docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md:84`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-remediation/05_WINDOWS_TOPOLOGY_CORRECTION.md#L84). The misleading `Require` alternative is excised and prohibited.

### 3.2 `09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md:91,96`
- **Previous Text (Line 91)**:  
  `Authoritative Rule: Authenticated TLS (SSL Mode=VerifyFull or SSL Mode=Require;Trust Server Certificate=false with validated CA).`
- **Updated Canonical Text (Line 91)**:  
  `Authoritative Rule: Peer-authenticated TLS (**SSL Mode=VerifyFull** with validated CA and hostname verification). Trust Server Certificate=true and unauthenticated Require mode without peer authentication are strictly prohibited.`
- **Updated Disposition Text (Line 96)**:  
  `Excised Trust Server Certificate=true and Require mode alternative. Mandated canonical SSL Mode=VerifyFull with validated CA and hostname verification.`
- **Verification**: Verified in [`docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md:91,96`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0-codex-regate-remediation/09_REPOSITORY_WIDE_CONSISTENCY_SCAN.md#L91-L96).

---

## 4. Repository-Wide Active Guidance Audit

An independent ripgrep search was conducted across all active documentation directories (`phase-0/`, `phase-0-codex-remediation/`, `phase-0-codex-regate-remediation/`, `phase-0-final-closure/`, and `phase-0-final-codex-correction/`):

1. **Permissive `Trust Server Certificate=true`**: **0 occurrences** across all active dossiers.
2. **Acceptable `SSL Mode=Require`**: **0 positive recommendations** across all active dossiers. Where `Require` appears, it is explicitly cited as an insecure prohibited mode or in the record of what was excised.
3. **Mandatory Standard**: **100% of active documents** mandate **`SSL Mode=VerifyFull`** with trusted CA and hostname validation for all remote PostgreSQL endpoints.
4. **Historical Immutable Evidence**: Mentions in historical immutable review reports (`phase-0-review-r4/`, `phase-0-codex-regate/`) remain untouched as immutable historical records.

---

## 5. Reviewer Conclusion on FR-C2-01

All surviving supplementary examples and consistency scan rows permitting `SSL Mode=Require;Trust Server Certificate=false` have been excised. The entire active documentation baseline uniformly enforces peer-authenticated TLS via `SSL Mode=VerifyFull` with trusted CA and hostname verification.

**Verdict: FR-C2-01 RESOLVED (PASS)**
