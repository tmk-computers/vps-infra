# W-0 preservation validation on a disposable Windows Server VM

Status: harness prepared; Windows IIS execution **NOT VERIFIED**. This is a qualification utility, not a Windows worker or installer. W-0 approval and VM preservation evidence remain required. Never run the existing setup.ps1 on the reviewed server.

## Scope and prerequisites

Use a disposable Windows Server 2025 VM with no customer data, a recorded provider VM ID, exact hostname, OS edition/build, and recoverable VM snapshot. Capture refuses WIN-MANOJKARNE. The DisposableVm assertion is an operator assertion, not a reliable virtualization detector. Review the target before execution. Use 64-bit Windows PowerShell 5.1 and administrative read access to IIS configuration. Create the evidence directory separately with access limited to the qualification operator.

Provision IIS, representative existing sites and certificates through a separately reviewed fixture change plan on that VM only. Include distinct HTTP hosts, HTTPS SNI hosts, catch-all/default bindings, separate AppPools, and deterministic static response bodies. Resolve fixture names to the VM; HTTPS must validate its name and trust chain. Do not bypass certificate validation. Record certificate thumbprints. Freeze unrelated configuration changes during each capture/operation/capture sequence.

The capture script reads applicationHost.config and Microsoft.Web.Administration objects, services and HTTP(S) fixture responses. It stores configuration hashes rather than configuration/password contents. It does not call CommitChanges, change bindings/certificates/firewall/services, or restore snapshots. Requests can produce IIS access logs. Scope probes to static VM fixtures without credentials, query strings or customer endpoints. Hashes and site metadata are still restricted evidence.

## Probe manifest and invocation

Write a JSON array containing one entry for **every existing HTTP/HTTPS binding**, including aliases/IP-specific bindings; the automated coverage check only checks site/protocol coverage, so the reviewer must verify binding completeness. Use actual URI hostnames to exercise HTTP Host and HTTPS SNI. For every HTTPS entry supply ExpectedThumbprint. ExpectedBodyHash is SHA-256 over the UTF-8 decoded response text, not a file-byte hash. ExpectedStatus should be 200 for these static fixtures.

```json
[
  {
    "Site": "existing-a",
    "Uri": "https://existing-a.w0.test/",
    "ExpectedStatus": 200,
    "ExpectedBodyHash": "REPLACE_WITH_KNOWN_STATIC_BODY_SHA256",
    "ExpectedThumbprint": "REPLACE_WITH_FIXTURE_CERTIFICATE_THUMBPRINT"
  }
]
```

From the disposable VM repository root (replace W0-VM with its independently confirmed hostname):

```powershell
.\scripts\windows\Test-W0IisPreservation.ps1 -Mode Capture -DisposableVm -ExpectedVmName W0-VM -ProbeManifest C:\w0-evidence\probes.json -OutputPath C:\w0-evidence\before.json
# Execute only the separately reviewed VM fixture operation for this case.
.\scripts\windows\Test-W0IisPreservation.ps1 -Mode Capture -DisposableVm -ExpectedVmName W0-VM -ProbeManifest C:\w0-evidence\probes.json -BaselinePath C:\w0-evidence\before.json -OutputPath C:\w0-evidence\after.json
.\scripts\windows\Test-W0IisPreservation.ps1 -Mode Compare -BaselinePath C:\w0-evidence\before.json -CandidatePath C:\w0-evidence\after.json -OutputPath C:\w0-evidence\comparison.json
```

Output files must not exist; evidence is never overwritten. Exceptions fail the run; absent output or an incomplete capture is **NOT VERIFIED**, never PASS. Compare PASS means only that captured baseline objects remained equal. The after-capture BaselinePath keeps probe coverage scoped to protected original sites while inventory still includes added sites. New sites/pools are allowed but their collision safety, SNI bit, ownership and health need separate checks; this comparator does not validate an installer or grant W-0 approval. Global/default/location configuration drift fails conservatively, including new location overrides; investigate rather than ignore the finding.

Capture checks configuration stability over its read window. It does not lock IIS or prove absence of transient outages between probes. Compare requires matching host/OS, script and manifest hashes. HTTP.sys SSL associations outside IIS, NTFS ACLs, site-file hashes, DNS and transient traffic continuity need separately attached evidence. ApplicationHostHash is retained for review but whole-file hash equality is not required because additive site creation changes it.

## Required case evidence

| Case | Required observation |
| --- | --- |
| No operation | Exact baseline comparison PASS; same fixture body and certificate. |
| Add new managed fixture | Existing objects unchanged; new host uses SNI bit, valid certificate and correct unique body; no existing binding overlaps. |
| Same host / wildcard / IP-scope collision | Planned validation rejects before mutation; unchanged baseline. Until a candidate validator exists, rejection behavior is NOT VERIFIED. |
| Existing site/pool/certificate drift | Comparator FAIL; record which object changed. Revert only the fixture change and capture again. |
| Managed health failure | Separate operation driver detects wrong release/500/timeout; scoped rollback restores managed state within 30 seconds, and existing baseline remains intact. |
| Concurrent unrelated change | Driver detects ownership/version drift and halts; never restore the whole IIS backup. Comparator identifies changed baseline. |
| Rollback failure | Driver records failure and halts further mutations; no SUCCESS. This harness performs no rollback itself. |

The last four operation-driver behaviors require separately authorized validation work; no Windows worker is implemented here. A manually staged fixture demonstrates only the monitoring harness, not installer rejection or rollback correctness. Report those limits explicitly.

Attach exact command lines, timestamps, fixture/probe manifest hashes, script hashes, git HEAD plus working diff, VM identity/build, baseline/candidate/result JSON, case-driver logs and independent reviewer assessment. Record approval of the ADR separately with names/date/accepted revision hash. Re-gate the original W-0 criteria only after both approval and executable preservation evidence are present.

## Local verification boundary

Run `scripts/windows/Test-W0ComparatorFixtures.ps1` for synthetic comparator regression checks without IIS. It exercises unchanged/additive state, binding/certificate/site/service/pool/global drift, wrong host, empty/duplicate/incomplete evidence and overwrite rejection. These checks are not Windows Server IIS acceptance.

API references: [Microsoft.Web.Administration](https://learn.microsoft.com/en-us/iis/manage/scripting/how-to-use-microsoftwebadministration) and [Windows PowerShell web request behavior](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-5.1). Live execution was intentionally not performed on the reviewed production host.
