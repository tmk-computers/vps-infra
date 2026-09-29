# Dual-OS and architecture gate

## Verdicts

**Dual-OS mandate: PASS.** Ubuntu 24.04 LTS and Windows Server 2022 remain equal first-class targets. Linux may enter controlled pilot after its own applicable prerequisites and Gate A pass while Windows work continues. Windows cannot inherit Linux certification; Phase 15 requires both.

**Architecture freeze: FAIL.** Separation into shared core and OS adapters is sound in direction, but the frozen contracts are not yet precise enough to govern safe implementation (C0-01, C1-01 through C1-04). This is not a declaration that either OS runtime passed.

## Shared release engine

| Required property | Assessment |
|---|---|
| Persistence | Durable states named; PRECHECK write and effect/commit ordering incomplete |
| Idempotency | Rollback called idempotent, but request deduplication and crash-safe effect replay unspecified |
| Immutable release identity | Content-addressed principle present; SemVer-only alternatives must resolve to recorded immutable identity |
| Provenance | Signature or checksum wording conflates trust with integrity; bind trusted producer/manifest to content |
| Health evidence | Liveness/readiness and timestamps present; cutover must precede terminal success and have post-cutover verification |
| Migration compatibility | General compatibility principle present; no safe decision table for failed or successful incompatible migrations |
| Rollback | Prior digest/package and probe present; unconditional snapshot restoration risks post-snapshot writes |
| Restart recovery | Present as intent; healthy-new-release shortcut is not sufficient for every recorded state |
| Reconciliation | Must reconcile release, configuration, schema, traffic state and ownership, not process health alone |
| Audit evidence | Logs/timestamps present; persist decisions, errors, identity, actor and transition/effect evidence per operation |

Do not impose Kubernetes, distributed consensus, service mesh, tracing infrastructure or HA to solve this. A durable single-host transaction/lock mechanism can satisfy the stated safety properties. The release contract must permit safe failure and human recovery where automatic compensation is unproven; zero downtime is not a universal single-host guarantee.

## Linux adapter

Phase 0 identifies the relevant Linux work: Docker/Compose lifecycle, service-specific YAML changes, Traefik/TLS/DNS preflight, Docker-aware firewalling, PostgreSQL 16 roles/networking, storage and rollback retention, telemetry, cgroup/resource admission, release/rollback and DR. These are sufficient categories for later Linux implementation once shared contracts are corrected.

Current source still has default credentials, public port publications, Docker-socket trust risk, unverified deployment success and unsafe upgrade/retention paths. No finding was closed here. Minimum CPU/RAM/disk figures in Phase 0 are proposed profiles, not capacity certification.

## Windows adapter and topology

Choosing compiled TMK.Agent.Windows is a reasonable program decision: one canonical service can integrate SCM lifecycle, concurrent requests, structured authenticated operations, constrained artifacts and testable recovery. A syntax error alone does not prove a rewrite necessary, and PowerShell is not inherently incapable of supervised service work. Keep PowerShell for bootstrap/setup where appropriate; do not treat the reviewer's categorical language as technical proof.

| Concern | Source-backed assessment and later evidence |
|---|---|
| AST parsing | Infra distribution fails at 345/346; server copy parses. Parse-only test reproduced. |
| SCM lifecycle | Raw powershell.exe service registration lacks the proposed compiled service integration. No live SCM1053 reproduction in this gate. Require start/stop/reboot tests. |
| Connectivity | Loopback-only listener is real; exact HTTP response depends on topology. Require authenticated reachability from the chosen control plane; avoid blind wildcard exposure. |
| Authentication | Default bearer fallback exists. Phase 1 defines trust contract; Phase 4 implements it in replacement agent. |
| Filesystem sandbox | PhysicalPath is used directly. Require per-service authorization, normalized root containment, archive-entry/reparse-point safeguards and least-privilege ACLs. |
| Health/rollback | Probe exception is swallowed before Success=true. Require immutable package identity and verified rollback. |
| Telemetry | Current fallback sums all w3wp processes; require AppPool/PID-specific evidence and honest unknown values. |
| Concurrency | Blocking listener serializes work. Concurrent telemetry is useful; same-service mutations still require serialization/idempotency. |
| Artifact pipeline | Gate A may use qualified external Windows/cross-target build pipelines. Do not require integrated CI just to produce IIS archives. |
| Reboot recovery | Agent and shared engine must recover durable operation state and verify actual serving release. |
| Ingress | setup.ps1 offers stopping W3SVC on conflict. Freeze supported IIS/TLS/Traefik coexistence for the chosen topology. |

The missing component placement is C1-03. Docker Desktop is not supported on Windows Server according to [Docker's Windows requirements](https://docs.docker.com/desktop/setup/install/windows-install/). Windows application hosting does not automatically qualify WSL2 PostgreSQL. Define a supported topology and its lifecycle, or require its decision before Phase 4 implementation; do not infer a topology from the current development bootstrap.

## Database support

PostgreSQL 16 is the sole intended Gate-A database, still pending qualification. Redis is absent/excluded; MariaDB/MySQL, SQL Server, Oracle and MongoDB remain outside that profile. Existing manifests/handlers do not imply tested or certified support. Phase 0 matrix headings sometimes conflate target and certified state; correct wording under C2-04.

Windows-hosted applications must reach the explicitly chosen PostgreSQL deployment through the same least-privilege, network, backup and recovery contract. Native SQL Server appears as a possible workload in the OS table but is not thereby a Gate-A supported database.

## Backup, recovery and upgrades

The provider-neutral offsite goal and source-host-loss test are correct. The four-stage contract is insufficient without encryption/key recovery, retention, recovery-point metadata and a complete recovery kit (C1-02). PostgreSQL custom archives need format-aware verification; an unwrapped custom archive is restored with pg_restore, not validated as a standalone gzip file. See [PostgreSQL 16 documentation](https://www.postgresql.org/docs/16/app-pgdump.html).

MR-19 correctly remains OPEN. The script backs up .env, resets origin/main, runs setup, then writes SUCCESS without a health command. Detached execution is neither immutable identity nor verified restart recovery. The upgrade contract must share the corrected release engine and have OS-specific application/recovery steps; the current Linux command list is not a Windows upgrade plan.

## Required future gates

Phase 3 Linux adapter; Phase 4 Windows agent/IIS adapter; Phase 11 failure injection for each OS; Phase 12 separate Gate A verdicts; Phase 15 both-OS commercial gate. Source-pattern AMS scores, historical tests without run records and success on another OS cannot satisfy these gates.
