# Infrastructure Product Overview & Feasibility

> **Document ID:** `V2-INFRA-PROD-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Product Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [INDEX.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/INDEX.md), [HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md)

---

## 1. Product Purpose & Target Audience

The **VPS Infrastructure Platform** (`vps-infra`) is engineered for developers, agencies, and enterprises who want the power and convenience of a Modern PaaS (Platform-as-a-Service) like Heroku or Render, but hosted entirely on their own low-cost, high-performance Virtual Private Servers (VPS).

### Target Audience:
- **DevOps Engineers & SREs:** Running multi-tenant container hosting with automated reverse proxying, Let's Encrypt TLS, and firewall hardening.
- **Software Agencies:** Delivering white-labeled hosting infrastructure to clients with predictable monthly compute costs.
- **Enterprise IT:** Maintaining absolute data sovereignty by running internal workloads on dedicated, self-hosted hardware.

---

## 2. Single-VPS Go-Live Feasibility

An authoritative technical assessment conducted on 2026-10-16 (`docs/audits/2026-10-16-single-vps-go-live-feasibility.md`) evaluated whether the entire Unified Platform (API, Web, CI Server, Agent Runtime, PostgreSQL, Redis, and customer apps) can run reliably on a **single 8-core / 16 GB RAM VPS**:

### Key Feasibility Findings:
1. **CPU & RAM Headroom:**
   - Base Platform Footprint (Idle): ~2.8 GB RAM across all system containers.
   - Active Agent Reasoning / Heavy CI Build: Peaks at ~6.2 GB RAM and 4–5 CPU cores.
   - Headroom: ~9.8 GB RAM remains available for customer applications and PostgreSQL buffer cache.
2. **Concurrency Throttling:**
   - To protect the host, the CI Server build queue is configured with a strict concurrency limit of **2 concurrent builds**.
   - Agent execution loops are capped at **5 concurrent reasoning streams**.
3. **Verdict:** **HIGHLY FEASIBLE** for small-to-medium agencies hosting up to 25 customer web applications alongside moderate AI workloads.
