# 02 Canonical Docker Cleanup Source Truth

**Document ID**: `RECON-C2-04-02-CANONICAL-SOURCE-TRUTH`  
**Phase**: Phase 0 — C2-04 Final Source-Truth Reconciliation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: AUTHORITATIVE — 100% STATIC CODE VERIFIED  

---

## 1. Primary Verdict

# Automatic Docker cleanup EXISTS.

It is actively executed by the current production platform on an automated daily schedule.

The execution chain is:

```text
ASP.NET Core Application Startup
  │
  ▼
Dependency Injection: AddHostedService<DockerCleanupBackgroundService>() (Program.cs:359)
  │
  ▼
DockerCleanupBackgroundService Starts (IHostedService generic host lifecycle)
  │
  ▼
Daily Scheduled Execution Loop (Default: 03:00 AM IST via Cron "0 0 3 * * ?")
  │
  ▼
RunDockerCleanupAsync() (Lines 164–318)
  │
  ▼
IMonitoringService.CleanupDockerAsync(request) (Lines 257–275)
  │
  ▼
Docker CLI Command Construction (MonitoringService.cs:234–323)
  │
  ▼
ExecuteCommandWithTimeoutAsync(...) (MonitoringService.cs:672–724)
  │
  ▼
System.Diagnostics.Process Spawning (FileName = "docker", ArgumentList)
  │
  ▼
Host Docker Daemon Socket (/var/run/docker.sock)
```

Automatic Docker cleanup is **NOT** absent, **NOT** merely diagnostic, **NOT** merely promotional, and **NOT** unevidenced. It is a fully registered, continuously running background workload in the existing codebase.

---

## 2. Background Service Truth (`DockerCleanupBackgroundService.cs`)

### 2.1 Dependency Injection Registration & Host Startup
In [`devops-manager/api/Program.cs:356-361`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Program.cs#L356-L361):

```csharp
356: builder.Services.AddQuartzHostedService(opt => opt.WaitForJobsToComplete = true);
357: builder.Services.AddHostedService<DatabaseBackupBackgroundService>();
358: builder.Services.AddHostedService<DockerEventsBackgroundService>();
359: builder.Services.AddHostedService<DockerCleanupBackgroundService>();
360: builder.Services.AddHostedService<LicenseHeartbeatBackgroundService>();
```

- **Registration**: Unconditionally registered via `builder.Services.AddHostedService<DockerCleanupBackgroundService>()`.
- **Startup**: In ASP.NET Core, all classes registered via `AddHostedService<T>` are automatically instantiated and their `ExecuteAsync` methods invoked during host bootstrapping.
- **Conditional Gates**: None. There are no configuration flags, environment checks, or feature gates preventing the service from launching.

### 2.2 Scheduling Cadence & Configuration
Inspection of [`DockerCleanupBackgroundService.cs:21-45, 115-159`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs#L21-L45):
- **Default Cadence**: Daily at 03:00 AM IST (Cron: `"0 0 3 * * ?"`).
- **Configuration Mechanism**: Configuration-driven with hardcoded default.
  - The service checks for an external configuration file at `/app/backups/docker_cleanup_cron_config.json`.
  - If present and valid, it reads the custom `CronExpression`.
  - If absent or unreadable, it falls back to the default `0 0 3 * * ?` (3:00 AM daily).
- **Timer Execution Loop**: Uses `CronExpression.GetNextOccurrence(DateTimeOffset.Now, tz)` to calculate the interval to 03:00 AM, awaits `Task.Delay(delay, stoppingToken)`, and unconditionally executes `await RunDockerCleanupAsync();`.

---

## 3. The Automatic Cleanup Request Contract

In `DockerCleanupBackgroundService.RunDockerCleanupAsync()` (lines 257–275):

```csharp
257:             // 4. Docker Engine & Local Registry Prune
258:             try
259:             {
260:                 using var scope = _serviceProvider.CreateScope();
261:                 var monitoringService = scope.ServiceProvider.GetRequiredService<IMonitoringService>();
262:                 var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
263: 
264:                 var request = new DockerCleanupRequestDto
265:                 {
266:                     DryRun = false,
267:                     CleanContainers = true,
268:                     CleanImages = true,
269:                     CleanNetworks = true,
270:                     CleanSystem = true,
271:                     RemoveAllUnusedImages = true
272:                 };
273: 
274:                 string output = await monitoringService.CleanupDockerAsync(request);
```

### Verified Option Contract:
1. `DryRun = false`: Executes real, destructive deletions; does not merely report reclaimable space.
2. `CleanContainers = true`: Instructs `MonitoringService` to prune stopped containers and truncate active container logs.
3. `CleanImages = true`: Instructs `MonitoringService` to prune images.
4. `CleanNetworks = true`: Instructs `MonitoringService` to prune unused networks.
5. `CleanSystem = true`: Instructs `MonitoringService` to run system prune, builder cache prune, and local registry GC.
6. `RemoveAllUnusedImages = true`: Appends the `-a` argument, instructing Docker to remove **ALL** unused images, not merely dangling (untagged) ones.

---

## 4. Actual Automatic Commands Executed

Inside [`MonitoringService.CleanupDockerAsync`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L234-L323), the following exact Docker CLI commands are dynamically constructed and executed via `ExecuteCommandWithTimeoutAsync`:

1. **Container Prune** (Line 256):
   ```bash
   docker container prune -f
   ```
2. **Active Container Log Truncation** (Line 262):
   ```bash
   docker run --rm -v /var/lib/docker/containers:/containers alpine sh -c "find /containers -name '*-json.log' -size +50000k -exec truncate -s 0 {} +"
   ```
3. **Image Prune (`-a`)** (Lines 275–277):
   ```bash
   docker image prune -f -a
   ```
   *(Because `request.RemoveAllUnusedImages == true`, `-a` is added to the argument list).*
4. **Network Prune** (Line 285):
   ```bash
   docker network prune -f
   ```
5. **System Prune (`-a`)** (Lines 293–295):
   ```bash
   docker system prune -f -a
   ```
   *(Because `request.CleanSystem == true` and `request.RemoveAllUnusedImages == true`, `-a` is added).*
6. **Builder Cache Prune** (Line 299):
   ```bash
   docker builder prune -a -f
   ```
7. **Local Registry Garbage Collection** (Line 305):
   ```bash
   docker exec docker-registry-backend registry garbage-collect -m /etc/docker/registry/config.yml
   ```

---

## 5. Volume Pruning Truth: R2-01 Correction

- **Finding**: **No explicit `docker volume prune` command was identified in the inspected current C# source.**
- **Code Reality**:
  - `DockerCleanupRequestDto.cs` defines: `DryRun`, `CleanContainers`, `CleanImages`, `CleanNetworks`, `CleanSystem`, `RemoveAllUnusedImages`. It has **no** `CleanVolumes` property.
  - `MonitoringService.cs:234-323` contains **no** volume pruning logic or command execution.
- **Developer Documentation Error**: Earlier developer analysis notes included a fabricated code block asserting a `CleanVolumes` option and `docker volume prune -f`. That snippet was fictitious and has been completely retracted.
- **Operational Reality**: Unattached persistent data volumes are **not** wiped by the Docker cleanup service. Ephemeral tenant sandbox databases are dropped via explicit SQL in `CleanupStaleSandboxDatabasesAsync()`.

---

## 6. Correct Component Boundary Disambiguation

### 6.1 `MonitoringService.cs:213`
- **Location**: [`MonitoringService.cs:213`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L213).
- **Enclosing Method**: `GetProjectStatusAsync(Guid serviceId)`.
- **Actual Content**:
  ```csharp
  catch (Exception ex)
  {
      _logger.LogWarning("Failed to get docker status for {Container}: {Msg}", service.ServiceName, ex.Message);
      statusDTO.Status = "Error";
  }
  ```
- **Behavior**: Catches an exception during container status queries (`docker ps`) and logs a warning.
- **Cleanup Commands**: **Zero**. Line 213 is status/error logging, **NOT** cleanup implementation.
- **Actual Cleanup Location**: `MonitoringService.CleanupDockerAsync` (lines 234–323).

### 6.2 `CiDiagnosticsAgentService.cs:241`
- **Location**: [`CiDiagnosticsAgentService.cs:241`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/CiDiagnosticsAgentService.cs#L241).
- **Actual Content**:
  ```csharp
  return ("DockerBuildOOM", "Build process killed by host OOM killer (Exit 137).", fix, new List<string>
  {
      "export NODE_OPTIONS=--max-old-space-size=2048",
      "docker system prune -f"
  });
  ```
- **Behavior**: Returns string `"docker system prune -f"` as part of a diagnostic suggestion tuple for operator troubleshooting when CI logs show an Out-Of-Memory error (exit code 137).
- **Execution**: **Never executed** by the service, any background worker, or the CI runner.
- **Distinction**: This diagnostic suggestion must be kept strictly distinct from `MonitoringService.CleanupDockerAsync`, which actively constructs and executes `docker system prune -f [-a]`.
