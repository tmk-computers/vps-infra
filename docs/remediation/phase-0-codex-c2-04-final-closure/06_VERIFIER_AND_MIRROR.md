# Verifier and mirror

Executed scripts/verify-baseline-integrity.ps1; the actual process exit code was **0**. Output confirms exact MR-01..MR-37 set, 33 OPEN + 3 PARTIALLY_IMPLEMENTED + 1 IMPLEMENTED_NOT_VERIFIED status arithmetic, F01..F22 and DEF-01..DEF-37 sets with valid MR targets, 95-file parity across eight directories, forbidden-pattern scan, and canonical revocation invariant/dossier check.

Independently compared Markdown files in both directions over all eight configured mirrored packages. Result: **95 server-side Markdown artifacts; zero missing files, zero reverse orphans, zero SHA-256 mismatches**.

Mechanical verifier PASS is not treated as runtime proof; the cleanup behavior was independently source-traced in 02_C2_04_SOURCE_TRACE.md.
