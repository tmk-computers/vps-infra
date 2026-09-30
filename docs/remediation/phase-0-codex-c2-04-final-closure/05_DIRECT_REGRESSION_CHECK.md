# Direct regression checks

These checks were limited to regressions directly implicated by the source-truth correction.

- **CG-C1-01: PASS.** PostgreSQL revocation transaction commit remains the security-effective point; the post-commit rule denies revoked credentials and allows zero authorization grace.
- **FR-C2-01: PASS.** Remote PostgreSQL TLS remains SSL Mode=VerifyFull with trusted CA and hostname verification.
- **Redis: PASS.** Redis 7 remains a first-class production cache/acceleration/ephemeral coordination component; PostgreSQL remains durable authority for safety-critical state.
- **AI boundary: PASS.** AI remains outside the deterministic Gate-A safety-critical path.
- **Dual-OS: PASS.** Linux Phase 12A and Windows Phase 12B retain independent Gate-A certifications.

The above active contract files were unchanged in the candidate-to-candidate diff. No broader re-audit was performed.
