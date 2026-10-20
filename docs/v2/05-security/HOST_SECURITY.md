# Host Security, Firewall & TLS Architecture

> **Document ID:** `V2-INFRA-SEC-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Security Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](../02-architecture/HOST_ARCHITECTURE.md), [OPERATOR_RUNBOOK.md](../06-operations/OPERATOR_RUNBOOK.md)

---

## 1. Host Hardening Principles

The `vps-infra` platform enforces defense-in-depth across the host OS:

1. **Firewall Strict Default Deny:** Only SSH (port 22) and Web Ingress (ports 80 and 443 via Traefik) are publicly accessible.
2. **Docker Network & Loopback Isolation:** Core services communicate over `traefik_net`; administrative and database ports (`shared_postgres` 5432, `pgAdmin` 5050) are bound strictly to `127.0.0.1` and unreachable from the public internet.
3. **Automated ACME TLS:** Certificates are provisioned via Traefik ACME resolver `myresolver` (Let's Encrypt); HTTP traffic is redirected to HTTPS entrypoint `websecure`.
4. **License Fingerprint Binding:** The platform license is cryptographically bound to the server's hardware UUID and MAC address (`scripts/extract-fingerprint.sh`).

---

## 2. Host Firewall Management & Security Evidence

The platform host security rules are applied during setup (`setup.sh`):
- UFW / iptables rules restrict ingress to ports 22, 80, and 443.
- Database and internal container ports are bound strictly to `127.0.0.1`, ensuring loopback-only access from the host.
- Host firewall management logic is maintained in `vps-infra-server/ci-server/api/host-firewall-manager.js` for CI/CD dynamic isolation.
- *Evidence Scope:* Staging audit evidence in `docs/audits/dns-tls-evidence.json` verifies DNS resolution and TLS certificate handshake on the test domain. (It does not constitute automated penetration testing or brute-force proof).
