# Windows Server Developer Environment Readiness Audit & Phase W-0 ADR Dossier

**Audit & ADR Date**: 2026-10-06  
**Host Environment**: Microsoft Windows Server 2019 Standard (10.0.17763 Build 17763)  
**Author / Auditor**: Independent Windows Platform Architect  

---

## 1. Dossier Overview

This directory contains the independent, read-only readiness audit and the Phase W-0 Architecture Decision Record (ADR) for native Windows Server support in VPS-Infra:

1. [**01_WINDOWS_SERVER_READINESS_AUDIT.md**](./01_WINDOWS_SERVER_READINESS_AUDIT.md) — Comprehensive read-only readiness audit of the developer environment, repository status, six-wave Linux roadmap reconciliation, and Windows Server findings (blockers, risks, and unverified items).
2. [**02_PHASE_W0_ARCHITECTURE_DECISION_RECORD.md**](./02_PHASE_W0_ARCHITECTURE_DECISION_RECORD.md) — ADR-001 establishing the Remote Application Node Topology (Topology A), strict IIS coexistence non-interference contract, security architecture, service model (`TMK.Agent.Windows`), atomic blue/green folder swapping, and post-W-0 phase acceptance criteria (W-1 through W-4).

---

## 2. Executive Summary of Decisions

- **Topology Selected:** Topology A (Remote Application Node). The control plane remains on the Linux VPS appliance; Windows Server hosts native IIS applications and a compiled .NET worker service agent.
- **IIS Coexistence Invariant:** Zero interference with existing IIS sites (`voterapp panel`, `survey panel`) or ports 80/443. Stopping `W3SVC` is strictly prohibited.
- **OS Baseline:** Windows Server 2022 (Tier 1 Recommended) and Windows Server 2019 (Tier 2 Supported).
- **Phase 0.5 Status:** Completely decoupled from Windows Server support.
- **Mandatory Safety Rule:** All implementation testing for Phases W-1 through W-4 must occur on a dedicated disposable Windows VM with no customer workloads.
