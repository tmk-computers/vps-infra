# FR-C2-01 TLS closure

**Result: RESOLVED.**

Active remote PostgreSQL guidance consistently requires `SSL Mode=VerifyFull` with a trusted certificate chain and server hostname verification. Searches across the active Phase 0, prior remediation, final closure and correction documents found no positive recommendation for `SSL Mode=Require`; remaining references describe the prohibited mode or document the superseded text.

Npgsql’s official security documentation confirms the semantics: `Require` provides encryption but no man-in-the-middle protection; `VerifyFull` provides both encryption and MITM protection, and Npgsql requires the server CA in the trust store or configured root certificate. This validates that the selected mode provides chain trust and hostname identity verification. No trust-all recommendation was found.

Source: [Npgsql Security and Encryption](https://www.npgsql.org/doc/security.html), SSL Mode table and CA guidance.

No live TLS endpoint test is claimed or required by this static Phase 0 gate.
