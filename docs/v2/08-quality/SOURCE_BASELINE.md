# Infrastructure Source Baseline & Verification Record

> **Document ID:** `V2-INFRA-QUAL-001`  
> **Repository:** `vps-infra`  
> **Audit Date:** 2026-10-20  
> **Auditor:** DevOps Architect & Documentation Quality Engineer  
> **Status:** Current Authoritative Baseline  
> **Related Documents:** [PILOT_RELEASE_GATES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/PILOT_RELEASE_GATES.md), [KNOWN_ISSUES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/KNOWN_ISSUES.md)

---

## 1. Executive Baseline Summary

| Attribute | Verified Value |
|---|---|
| **Repository Name** | `vps-infra` |
| **Remote URL** | `git@github.com:tmk-computers/vps-infra.git` |
| **Tracked Branch** | `main` |
| **Full HEAD SHA** | `6dedfa34c6a3279f608565966684c228db377776` |
| **Working Tree Status** | Clean (0 uncommitted changes) |
| **Release Version** | `v2.3.1` (tagged in `VERSION`) |
| **Verified Operating Systems** | Ubuntu 22.04 LTS, Ubuntu 24.04 LTS |
| **Docker Compose Engine** | Docker Compose v2.20+ |
| **Overall Pilot Gate Verdict** | **CONDITIONAL PASS** (2026-10-19) |

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
