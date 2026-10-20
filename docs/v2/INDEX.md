# VPS Infrastructure Documentation V2 — Navigation Hub

> **Project:** Unified VPS-Infra Platform  
> **Repository:** `vps-infra`  
> **Platform Version:** `v2.3.1`  
> **Authoritative Baseline:** Commit [`6dedfa3`](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/SOURCE_BASELINE.md) (2026-10-20)  
> **Companion Repository:** [`vps-infra-server` (Control Plane & AI Runtime)](file:///d:/company/products/vps-infra/vps-infra-server/docs/v2/INDEX.md)

---

## 1. Welcome to VPS Infrastructure Documentation V2

The **`vps-infra`** repository provides the client-side host infrastructure, automated server installer (`setup.sh`), Docker Compose platform definitions, host orchestration CLI (`infra`), and customer application stack templates.

```mermaid
graph TD
    Start["New to vps-infra?"] --> StartHere["00-START-HERE.md"]
    StartHere --> PathChoice{"Your Goal:"}
    
    PathChoice -->|"Install on VPS"| Runbook["06-operations/OPERATOR_RUNBOOK.md"]
    PathChoice -->|"Understand Architecture"| HostArch["02-architecture/HOST_ARCHITECTURE.md"]
    PathChoice -->|"Manage Host CLI"| CLIMod["04-modules/CLI_AND_ORCHESTRATION.md"]
    PathChoice -->|"Inspect Quality & Gates"| Quality["08-quality/PILOT_RELEASE_GATES.md"]
```

---

## 2. Master V2 Navigation Structure

### `00` Orientation
- **[00-START-HERE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/00-START-HERE.md)**: Beginner guide to VPS infrastructure provisioning, CLI basics, and directory layouts.

### `01` Product Specifications
- **[01-product/INFRASTRUCTURE_OVERVIEW.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/01-product/INFRASTRUCTURE_OVERVIEW.md)**: Product purpose, target hardware environments, and single-VPS hosting feasibility.

### `02` Architecture
- **[02-architecture/HOST_ARCHITECTURE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/HOST_ARCHITECTURE.md)**: Directory hierarchy (`/opt/vps-infra`), Docker bridge networks, Nginx reverse proxy, and volume mounts.
- **[02-architecture/SERVER_INTEGRATION.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/02-architecture/SERVER_INTEGRATION.md)**: How `vps-infra` pulls, configures, and deploys containers built by `vps-infra-server`.

### `03` Development
- **[03-development/LOCAL_SETUP.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/03-development/LOCAL_SETUP.md)**: Local testing workflows, shell linting (ShellCheck), and script test runners.

### `04` Modules
- **[04-modules/CLI_AND_ORCHESTRATION.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/04-modules/CLI_AND_ORCHESTRATION.md)**: The `infra` and `infra.ps1` CLI scripts, lifecycle verbs, and environment flags.
- **[04-modules/STACK_TEMPLATES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/04-modules/STACK_TEMPLATES.md)**: Pre-configured stack templates for Node.js, .NET Core, PHP, Python, and Static Web.

### `05` Security
- **[05-security/HOST_SECURITY.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/05-security/HOST_SECURITY.md)**: Host firewall (UFW), SSH hardening, automated Let's Encrypt TLS, and license activation.

### `06` Operations
- **[06-operations/OPERATOR_RUNBOOK.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/OPERATOR_RUNBOOK.md)**: Step-by-step installation, routine operations, container upgrades, and log rotation.
- **[06-operations/DISASTER_RECOVERY.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/06-operations/DISASTER_RECOVERY.md)**: Database backups, volume restore drills, and automated deployment rollback.

### `07` Roadmap
- **[07-roadmap/INFRA_ROADMAP.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/07-roadmap/INFRA_ROADMAP.md)**: Infrastructure milestones, single-VPS pilot, and Windows Server qualification.

### `08` Quality & Truth Baseline
- **[08-quality/SOURCE_BASELINE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/SOURCE_BASELINE.md)**: Exact commit SHA, working tree status, and verified script baseline.
- **[08-quality/KNOWN_ISSUES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/KNOWN_ISSUES.md)**: Infrastructure-specific defects and compose configuration quirks.
- **[08-quality/PILOT_RELEASE_GATES.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/08-quality/PILOT_RELEASE_GATES.md)**: Single-VPS go-live feasibility and pilot release gate reports.

### `09` Decisions
- **[09-decisions/ADR_INDEX.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/09-decisions/ADR_INDEX.md)**: Host architecture decision records.

### `10` Reference
- **[10-reference/CLI_REFERENCE.md](file:///d:/company/products/vps-infra/vps-infra/docs/v2/10-reference/CLI_REFERENCE.md)**: Complete CLI command, flag, and environment variable reference.
