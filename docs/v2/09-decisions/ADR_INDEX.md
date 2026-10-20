# Infrastructure Architecture Decision Records Index

> **Document ID:** `V2-INFRA-DEC-001`  
> **Repository:** `vps-infra`  
> **Status:** Current Authoritative Decision Index  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md)

---

## 1. Approved Infrastructure ADRs

| ADR ID | Title | Date Approved | Scope | Status | Canonical Reference |
|---|---|---|---|---|---|
| **ADR-W0** | Phase W0 Dual-OS Architecture & Port Allocation | 2026-09-10 | Dual-OS Linux/Windows hosting, port allocations, IIS integration | **APPROVED (Pre-Qualification)** | [docs/PHASE_W0_ARCHITECTURE_DECISION_RECORD.md](file:///d:/company/products/vps-infra/vps-infra/docs/PHASE_W0_ARCHITECTURE_DECISION_RECORD.md) |

---

## 2. Infrastructure Design Decisions

### Decision 1: Single-Node Compose vs Swarm for Initial Pilot
- **Decision:** Use standard Docker Compose v2 for the initial single-VPS pilot release.
- **Rationale:** Minimal runtime complexity, zero cluster consensus overhead, and trivial operator onboarding. Multi-node Docker Swarm / k3s deferred to Milestone 4.
