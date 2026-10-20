# Host Security, Firewall & TLS Architecture

> **Document ID:** `V2-INFRA-SEC-001`  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Status:** Current Authoritative Security Specification  
> **Audit Date:** 2026-10-20  
> **Related Documents:** [HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md), [OPERATOR_RUNBOOK.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md)

---

## 1. Host Hardening Principles

The `vps-infra` platform enforces defense-in-depth across the host OS:

1. **Firewall Strict Default Deny:** Only SSH (port 22) and Web Ingress (ports 80 and 443) are publicly accessible.
2. **Docker Network Isolation:** Backend services (PostgreSQL, Redis, Agent Runtime) are confined to `vps_backend_net` and unreachable from the internet.
3. **Automated ACME TLS:** Certificates are provisioned via Let's Encrypt with ZeroSSL failover; HTTP traffic is forcibly redirected to HTTPS.
4. **License Fingerprint Binding:** The platform license is cryptographically bound to the server's hardware UUID and MAC address (`extract-fingerprint.ps1` / `extract-fingerprint.sh`).

---

## 2. Dynamic Host Firewall Integration (Wave 3)

The CI Server dynamically coordinates with the host firewall (`scripts/host-firewall-manager.sh`):
- When customer apps start, internal dynamic ports are allowed on loopback only.
- If repeated failed SSH login attempts or suspicious brute-force requests occur, the firewall manager injects blocking rules directly into `iptables` / `fail2ban`.
- Automated test evidence in `vps-infra/docs/audits/dns-tls-evidence.json` proves TLS handshake validation and port boundary enforcement.
