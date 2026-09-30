# C2-04 evidence accuracy

**Result: UNRESOLVED (C2).**

The correction accurately fixes F02 (published signing defaults; MR-02/MR-36), F03 (committed Google service-account key; MR-03), F15 (HITL approval drift/replay; MR-08), and the 13-migration inventory. `DataSeeder.cs` contains raw DDL inside a `try` with a swallowed `catch { }`; no deployed migration-history claim is established by this static review. `Product.cs` redeclares `IsActive`; `ProjectService` inherits it from `BaseEntity`. The Redis status correction preserves Redis 7 as first-class and PostgreSQL as durable authority. The documented candidate lineage terminates at the exact frozen SHAs.

One expressly targeted correction is factually wrong and remains a closure defect:

- `docs/remediation/phase-0/15_DOCUMENTATION_TRUTH_MATRIX.md:38` claims active pruning resides at `MonitoringService.cs:213` and that this issues `docker system prune -a`.
- At the frozen candidate, `MonitoringService.cs:213` is `_logger.LogWarning("Failed to get docker status...")`; it is not a pruning call.
- Repository search finds the only `docker system prune` source occurrence at `devops-manager/api/Infrastructure/Services/AI/CiDiagnosticsAgentService.cs:241`, as a suggested fix string (`docker system prune -f`) for a diagnosed build OOM. That is not evidence of an actively executed cleanup implementation.
- The prior `scripts/cleanup-docker.sh` citation is correctly described as nonexistent, but the replacement source attribution still overstates implementation behavior.

The reviewer’s C2-04 pass repeats the same wrong line and command, so it does not resolve the defect. This is a C2 accuracy issue, not a new C1 architecture blocker. Update the truth matrix and related correction/review claims to describe the suggestion accurately (or state that no active pruning implementation was located), then independently re-review.
