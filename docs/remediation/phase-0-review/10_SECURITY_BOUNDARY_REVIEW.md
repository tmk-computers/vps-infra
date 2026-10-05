# 10 SECURITY BOUNDARY & TRUST MODEL INDEPENDENT REVIEW

**Document ID**: `REMED-P0-REV-10`  
**Phase**: Phase 0 — Independent Review & Acceptance  
**Reviewer**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-29  

---

## 1. Security Architecture & Threat Boundaries

The Reviewer independently verified the five core security boundaries defined in [`08_SECURITY_BOUNDARIES.md`](file:///d:/company/products/vps-infra/vps-infra-server/docs/remediation/phase-0/08_SECURITY_BOUNDARIES.md):

```
       [ Public Internet ]
               │
               ▼ (Port 80/443 ONLY)
      ┌─────────────────┐
      │  Traefik / UFW  │
      └────────┬────────┘
               │
      ┌────────┴────────┐
      ▼                 ▼
[ Web UI ]      [ DevOps API ] ──(Private Auth)──► [ Secret Vault ]
                        │
                        ▼ (Loopback / Internal Docker Network)
                 [ PostgreSQL 16 ] (Least-Privilege Roles)
```

---

## 2. Independent Audit of Critical Vulnerabilities

### 2.1 Leaked Google Cloud RSA Private Key (F03, DEF-05, MR-03 - P0)
- **Current Reality**: The file `devops-manager/api/google-drive-credentials.json` is actively tracked in git and contains a live Google Cloud Service Account RSA Private Key (`type: "service_account"`).
- **Reviewer Assessment**: **Critical P0 Security Finding**. Remediation must:
  1. Revoke the key in the Google Cloud Console IAM immediately.
  2. Permanently delete the file from git tracking (`git rm --cached`).
  3. Load credentials exclusively via environment variables or encrypted secrets vault in production.

### 2.2 Published Signing Keys & Default Secrets (F02, DEF-04, MR-02, MR-07 - P0)
- **Current Reality**:
  - `ci-server/api/auth.js:4` falls back to static secret `'5b5fea8f9a4b8f2c2e2c5b6f7d4c6b4c7b9d8e6e5e5f5c6b7d8e6e5b5f9c2e4'`.
  - `setup.sh:176` copies `.env.example` with default passwords (`StrongPostgres@123`).
  - `setup.ps1` and `tmk-iis-agent.ps1` default to `"[REDACTED_COMPROMISED_DEFAULT]"` (DEF-36, MR-28).
- **Reviewer Assessment**: **Critical P0 Security Finding**. Setup scripts must generate cryptographically random high-entropy strings during fresh installation, and the application must fail to boot if known static fallback strings are detected in production mode.

### 2.3 Network Exposure & Firewall Bypass (F07, DEF-03, MR-06 - P0)
- **Current Reality**:
  - `db/postgres/docker-compose.yml:19` publishes port `5432:5432` to `0.0.0.0`.
  - `db/postgres/docker-compose.yml:50` publishes port `5050:80` (pgAdmin) to `0.0.0.0`.
  - `db/mariadb/docker-compose.yml:16` publishes port `3306:3306` to `0.0.0.0`.
- **Reviewer Assessment**: **Critical P0 Security Finding**.
  - In standard Linux setups, Docker writes `iptables` DNAT rules in the `PREROUTING` chain, forwarding packets directly to containers. This bypasses standard UFW `INPUT` filtering unless specific Docker-UFW integration rules are applied.
  - Publishing database ports to `0.0.0.0` exposes PostgreSQL and pgAdmin directly to the public internet.
  - **Required Fix**: Remove public port publishing; bind strictly to `127.0.0.1:5432:5432` or keep entirely on the internal `traefik_net` Docker network.

### 2.4 Token Disclosure & Broken Object Level Authorization (F04, F05, F20, MR-04, MR-08 - P1)
- **Current Reality**:
  - `ProjectService.cs:GetAllAsync` returns `GitAccessToken` in plaintext DTOs.
  - `DeployController.cs:64` logs the expected webhook secret on authentication mismatch.
  - `ci-server/api/server.js:77` verifies the caller's role, but does not verify whether the tenant owns the specific `serviceId` being triggered (BOLA).
- **Reviewer Assessment**: **Mandatory P1 Pilot Blocker**. Must strip sensitive secrets from read models, encrypt database secret fields at rest, sanitize logs, and enforce tenant-scoped service ownership.

---

## 3. CI/CD Trust Model Review (ADR-03 & REMED-P0-13)

The Developer established an architectural bifurcation between two CI models:
1. **Gate-A Supported Model**: External Isolated CI (GitHub Actions / GitLab CI).
2. **Future Qualified Model**: TMK Integrated CI (`ci-server`).

### 3.1 Technical Coherence of Gate-A Trust Boundary
- **Threat Solved**: Codex finding `F01` identified that `build-runner.js:145` mounts `/var/run/docker.sock` and `/var/www` into untrusted build containers running developer test suites. Any malicious `dotnet test` or `npm test` can issue commands to the host Docker daemon, escaping to host root.
- **Gate-A Boundary**:
  - Code compilation and untrusted test execution execute on **external, disposable CI runners** (e.g. GitHub-hosted runners).
  - External CI builds container images and pushes immutable image digests to an authenticated registry (e.g. GHCR).
  - The single-VM production host receives only deployment trigger webhooks specifying the immutable digest, which it pulls and verifies.
  - Untrusted code **never executes directly on the production host VM**.
- **Assessment**: This trust boundary is **technically coherent, robust, and completely eliminates the single-VM host compromise vector**.

### 3.2 Preservation of Integrated CI Functionality
- The Developer's decision **does not silently delete or disable** existing code in `ci-server/`.
- Integrated CI is retained for local development and non-production environments.
- To achieve production Gate B qualification in the future, it must satisfy four explicit hardening requirements: rootless builds without `/var/run/docker.sock`, cgroup memory/CPU caps, tenant BOLA checks, and network egress isolation.
