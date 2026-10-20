# Infrastructure Source Baseline & Verification Record

> **Document ID:** `V2-INFRA-QUAL-001`  
> **Repository:** `vps-infra`  
> **Audit Date:** 2026-10-20  
> **Auditor:** DevOps Architect & Documentation Quality Engineer  
> **Status:** Current Authoritative Baseline  
> **Related Documents:** [PILOT_RELEASE_GATES.md](./PILOT_RELEASE_GATES.md), [KNOWN_ISSUES.md](./KNOWN_ISSUES.md)

---

## 1. Executive Baseline Summary

| Attribute | Verified Value |
|---|---|
| **Repository Name** | `vps-infra` |
| **Remote URL** | `git@github.com:tmk-computers/vps-infra.git` |
| **Tracked Branch** | `main` |
| **Reviewed Doc Commit** | `2db2a64421ef1d9a19a64547730c80f4480f23e1` |
| **Source Parent Baseline** | `41fcb993e58d36df5951ee009a48609deb748e88` |
| **Working Tree Status** | Clean on `docs/v2-gate-remediation` |
| **Release Version** | `v2.3.1` (managed dynamically) |
| **Verified Operating Systems** | Ubuntu 22.04 LTS, Ubuntu 24.04 LTS |
| **Docker Compose Engine** | Docker Compose v2.20+ |
| **OMR Staging Pilot Verdict** | **CONDITIONAL HOLD / PRODUCTION NO-GO** (2026-10-04) |

---

## 2. Commit Ancestry & Verification History

```
* 6dedfa3 fix(compose): set Database__AutoMigrateOnStartup=false for devops-api-prod
* 834f934 fix(setup): avoid sudo invocation when running as root
* daedec4 chore(release): bump version to v2.3.1
* ba3b948 feat(ci): add configurable pilot exam window controls and documentation
* 1238ffc Merge remote-tracking branch 'origin/docs/windows-w0-reconciliation'
|\
| * 4e85916 test(windows): add disposable VM baseline preservation runner
| * d12adb4 docs(windows): reconcile W-0 gates and add preservation qualification harness
* | 912ad18 docs: clean up moved local OMR development guide
* | 86b9e59 docs: relocate local OMR development guide to omr-api repository
* | b970f81 docs: add comprehensive local OMR development setup guide for developers
* | 69fda3a chore(scripts): set executable permissions on drill and verify scripts
* | 67f3590 fix(migration): restart platform containers upon folder migration completion
* | 8aa6e48 test(e2e): add end-to-end verification for version-check and sandbox folder migration
* | 76ce216 feat(upgrade): add --check CLI option to query authoritative release updates from license server
* | 155c18b fix(migration): perform clean directory move and remove root symlinks
```
