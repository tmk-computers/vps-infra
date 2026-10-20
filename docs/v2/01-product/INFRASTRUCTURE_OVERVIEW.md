# Infrastructure Product Overview & Feasibility

> **Document ID:** `V2-INFRA-PROD-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Product Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [INDEX.md](../INDEX.md), [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md)

---

## 1. Product Purpose & Target Audience

The **VPS Infrastructure Platform** (`vps-infra`) is engineered for developers, agencies, and enterprises who want the power and convenience of a Modern PaaS (Platform-as-a-Service) like Heroku or Render, but hosted entirely on their own low-cost, high-performance Virtual Private Servers (VPS).

### Target Audience:
- **DevOps Engineers & SREs:** Running multi-tenant container hosting with automated reverse proxying, Let's Encrypt TLS, and firewall hardening.
- **Software Agencies:** Delivering white-labeled hosting infrastructure to clients with predictable monthly compute costs.
- **Enterprise IT:** Maintaining absolute data sovereignty by running internal workloads on dedicated, self-hosted hardware.

---

## 2. Historical Staging Feasibility Baseline

A historical architecture and capacity audit conducted on 2026-10-16 (`docs/audits/2026-10-16-single-vps-go-live-feasibility.md`) evaluated an **OMR Enterprise SaaS platform workload** deployed on a **single 8-core / 32 GB RAM VPS** running Ubuntu 24.04 LTS:

### Scoped Historical Audit Findings:
1. **Audited Hardware & Workload:**
   - Host: 8 vCPUs (x86_64), 31.34 GiB RAM (32 GB), ~387 GB NVMe storage, Linux swap disabled.
   - Workload: Dedicated OMR SaaS container suite (`omr-api`, `omr-worker:qa`, `omr-web:qa`, PostgreSQL, RabbitMQ, and Traefik).
   - This evaluation did **NOT** audit or certify the merged Control Plane API, CI Server engine, or Agent Runtime platform on a 16 GB VPS.
2. **Operational Blockers Identified (CONDITIONAL HOLD / Production NO-GO):**
   - **Off-Host Disaster Replication Blocker:** Backups were written to `/var/www/vps-infra/volumes/offhost_backup_destination` on the primary local VPS disk; no remote S3/R2 bucket was configured.
   - **Origin TLS Certificate Blocker:** Traefik served a default self-signed certificate, blocking Cloudflare *Full (strict)* origin verification.
3. **Formal Verdict:** **CONDITIONAL HOLD / PRODUCTION NO-GO AS-IS**.
   - Any prior assertion that the platform was certified as "Production Ready" for 25 customer apps alongside AI agent reasoning on a 16 GB VPS was an unsupported extrapolation and is formally withdrawn. Sizing for multi-tenant AI workloads remains a proposed envelope requiring empirical benchmarking.
