# Infrastructure Architecture Decision Records Index

> **Maintained by:** repository documentation owner (role; individual approval pending). **Reviewed source parents:** server c458c831711ba2e82a382719f76c98551d7d5a70; infra44a5d6a32bf59f50e7c13b663dbd22bac31eb53d. **Last verified:**2026-10-20. **Review trigger:** any source/DTO/config/schema/package/CLI/deployment change. [Maintenance and checks](../../../../vps-infra-server/docs/v2/08-quality/MAINTENANCE.md).

> **Document ID:** `V2-INFRA-DEC-001`  
> **Repository:** `vps-infra`  
> **Status:** Source-aligned reference candidate; independent approval pending
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md)

---

## 1. Re-Gated Architecture Decision Records

| ADR ID | Title | Date Checked | Scope | Status | Canonical Reference |
|---|---|---|---|---|---|
| **ADR-W0** | Phase W0 Dual-OS Architecture & Port Allocation | 2026-10-06 | Dual-OS Linux/Windows hosting, port allocations, IIS coexistence | **PROPOSED & RE-GATED FOR STAKEHOLDER SIGN-OFF** | [docs/PHASE_W0_ARCHITECTURE_DECISION_RECORD.md](../../PHASE_W0_ARCHITECTURE_DECISION_RECORD.md) |

---

## 2. Infrastructure Design Decisions

### Decision 1: Single-Node Compose vs Swarm for Initial Pilot
- **Observed implementation:** Source uses standard Docker Compose v2 for a single host. This index does not establish a separately approved release decision.
- **Rationale:** Minimal runtime complexity, zero cluster consensus overhead, and one-host operation. Multi-node Docker Swarm / k3s remains PROPOSED; no approved milestone or release dependency is established here.
