# Phase scope and dependency gate

## Phase 0.5 — CORRECTION REQUIRED; sequencing justified

MR-34 is a legitimate database alignment prerequisite before Phase 1 integration validation. Product.cs adds eight persistent maintenance properties and ProjectService.cs adds five. The latest tracked migration is 20260831080000_AddDatabaseServerToProjectService; neither migrations/model snapshot nor seeder supplies those fields. The maintenance suites use EF InMemory.

Program.cs calls MigrateAsync then DataSeeder; it also suppresses PendingModelChangesWarning. Applying old migrations does not synthesize missing model columns. Entity queries that select those absent columns can receive PostgreSQL SQLSTATE 42703, propagating to application errors. This is a source-supported likely failure path, not a PostgreSQL daemon crash or a live test result. Other schema/startup errors can occur first; do not claim every endpoint necessarily fails identically.

Resolve C2-01: versioned migration and model snapshot should be authoritative. Any temporary seeder compatibility DDL must have explicit starting-schema assumptions, ordering, failure behavior and MR-13 removal criteria. Document 10 still labels MR-34 Phase 1. Do not roll the entire MR-13 schema consolidation into Phase 0.5 without an explicit dependency need.

Future prerequisite evidence: fresh PostgreSQL schema, representative upgrade schema, all 13 fields/defaults, preservation of existing rows, repeat application and failed-migration behavior. No such migration or live test was executed now.

## Phase 1 — CORRECTION REQUIRED; scope membership coherent

Retain exactly MR-02, MR-03, MR-04, MR-05, MR-06, MR-07, MR-08, MR-28 and MR-36.

MR-06 includes network hygiene only; its Redis wording cannot override the database support matrix. There is no reason to create Redis support to close this task. MR-28 defines a shared Windows security contract with minimal legacy containment; the replacement agent is Phase 4 work. No critical security task needs a cosmetic phase.

Correct the role/token/tenant contract and preserve historical obligations (C1-01/C1-04). MR-37 stays with truthfulness in Phase 9, with accurate disclosure before any pilot exposure.

## The five “non-technical-blocker” items before Phase 13

| MR | Required before controlled customer pilot | Later/full capability distinction |
|---|---|---|
| MR-17 | Bounded storage, monitoring, safe cleanup procedure or disabled unsafe pruning, protected proven rollback/recovery set | Full cleanup automation is scheduled Phase 6; assisted alternative needs explicit gate acceptance |
| MR-20 | Server-side unsupported-engine/feature enforcement and clear supported profile | Additional engine support can wait for separate qualification; enforcement cannot |
| MR-21 | Truthful scope, risks, downtime and recovery claims disclosed to participants | Broad documentation overhaul is Phase 9, which currently precedes Phase 13 |
| MR-30 | Reproducible prerequisite/diagnostic checks sufficient to admit the chosen OS profile | Full Infra Doctor is Phase 8 unless an approved assisted substitute is specified |
| MR-31 | Usable setup/recovery/escalation runbooks, support responsibility and safe collection/redaction procedures | One-click support-bundle automation may have an approved assisted substitute; current roadmap assigns it Phase 9 |

Thus “not one of 32 current technical blockers” does not mean optional forever, and several outcomes are mandatory before customer pilot. The detailed dependencies preserve these items; the misleading labels are C2-02, not an independent C0 failure.

## Roadmap assessment

| Phase | Assessment |
|---|---|
| 0 | Reconciliation/architecture baseline, not remediation completion |
| 0.5 | Required schema alignment with clarified authority |
| 1 | Shared security contract and enforcement |
| 2 | Shared release engine after C0-01 correction; MR-13 schema consolidation retained |
| 3 | Linux adapter and Gate-A feature/CI boundary; preserve DEF-08 control-plane distinction |
| 4 | Windows replacement agent; topology decision must precede dependent implementation |
| 5 | Complete provider-neutral backup/recovery contract, not upload-only evidence |
| 6 | Resource/storage safeguards and retention |
| 7 | Verified outbound alert receipt plus independent host-loss detection; local retry cannot report a dead host |
| 8 | Diagnostics for each target profile |
| 9 | Scope enforcement, truthful docs/AMS and supportability |
| 10 | Safe upgrades, export and license-independent recovery for each OS |
| 11 | Failure injection on each OS using its actual topology |
| 12 | Independent Linux and Windows Gate A verdicts |
| 13 | Controlled customer pilot only for the OS that has passed its applicable prerequisites/gate |
| 14 | Operational feedback and hardening |
| 15 | Commercial acceptance requires both OS tracks |

The serial Gantt should be annotated or revised to express the prose's staggered certification rule. Passing Linux Phase 1–3 alone is not sufficient to skip backup, monitoring, support, upgrade and failure-injection criteria; the older Reviewer Linux report's shortcut must not govern pilot admission.

No Kubernetes, service mesh, distributed tracing, multi-node HA or destructive autonomous AI is required by this gate.

## Return-to-Developer sequence

1. Correct release, security, recovery and topology contracts.
2. Preserve missing historical sub-obligations and explicit scope/phase dispositions.
3. Clarify Phase 0.5, pilot prerequisites and source-versus-runtime evidence.
4. Record the corrected candidate hashes and the actual independent re-review outcome.
5. Resubmit for Codex gate. Do not begin Phase 0.5 or Phase 1 on the basis of this FAIL.
