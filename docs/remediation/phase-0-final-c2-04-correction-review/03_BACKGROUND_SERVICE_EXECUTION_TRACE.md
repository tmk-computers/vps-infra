# 03 Background Service Execution Trace: DockerCleanupBackgroundService.cs

**Document ID**: `REVIEW-R6-03-BACKGROUND-TRACE`  
**Role**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Target**: `devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs`  
**Date**: 2026-09-30  

---

## 1. Dependency Injection Registration & Startup Reachability

Inspection of [`devops-manager/api/Program.cs:356-361`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Program.cs#L356-L361):

```csharp
356: builder.Services.AddQuartzHostedService(opt => opt.WaitForJobsToComplete = true);
357: builder.Services.AddHostedService<DatabaseBackupBackgroundService>();
358: builder.Services.AddHostedService<DockerEventsBackgroundService>();
359: builder.Services.AddHostedService<DockerCleanupBackgroundService>();
360: builder.Services.AddHostedService<LicenseHeartbeatBackgroundService>();
```

### Analysis:
1. **Registered with DI**: **YES**. Line 359 explicitly calls `builder.Services.AddHostedService<DockerCleanupBackgroundService>()`.
2. **Automatically Started**: **YES**. In ASP.NET Core, all classes registered with `AddHostedService<T>()` are instantiated and their `StartAsync` / `ExecuteAsync` methods are executed by the generic host upon application startup.
3. **Feature Flags / Conditional Enclosure**: **NONE**. The registration is unconditional. There are no configuration gates, environment checks, or feature flags guarding line 359.

---

## 2. Scheduling Mechanism & Cadence

Inspection of [`DockerCleanupBackgroundService.cs:21-113`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs#L21-L113):

1. **Default Cadence**: Line 23:
   `public string CronExpression { get; set; } = "0 0 3 * * ?"; // Default: 3:00 AM daily`
2. **Cron Configuration**: Reads `/app/backups/docker_cleanup_cron_config.json` if present; falls back to `0 0 3 * * ?` (3:00 AM daily IST) if absent.
3. **Execution Loop**: In `ExecuteAsync(CancellationToken stoppingToken)` (lines 115–159):
   - Computes delay until next scheduled cron trigger;
   - Awaits `Task.Delay(delay, linkedCts.Token)`;
   - When the timer fires, unconditionally invokes `await RunDockerCleanupAsync();` (line 158).

---

## 3. The Execution Call Chain to Docker Prune

Inspection of lines 257–275 of `DockerCleanupBackgroundService.cs`:

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

### Analysis of Parameters Passed:
- `DryRun = false`: Executes real destructive deletion commands.
- `CleanContainers = true`: Instructs `MonitoringService` to prune stopped containers.
- `CleanImages = true`: Instructs `MonitoringService` to prune unused images.
- `CleanNetworks = true`: Instructs `MonitoringService` to prune unused networks.
- `CleanSystem = true`: Instructs `MonitoringService` to execute system and builder cache prunes.
- `RemoveAllUnusedImages = true`: Maps to the `-a` argument, instructing Docker to prune **ALL** unused images, not merely dangling ones!

---

## 4. End-to-End Execution Trace

```text
Trigger:
  Application Startup -> ASP.NET Core IHostedService Engine starts DockerCleanupBackgroundService
  Timer Loop -> Daily at 03:00 AM IST (Cron: "0 0 3 * * ?") triggers Task.Delay completion
    │
    ▼
Service:
  DockerCleanupBackgroundService.RunDockerCleanupAsync() (Lines 164–318)
    │
    ▼
Method:
  IMonitoringService.CleanupDockerAsync(DockerCleanupRequestDto request) (Lines 257–274)
    │
    ▼
Options:
  DryRun = false
  CleanContainers = true
  CleanImages = true
  CleanNetworks = true
  CleanSystem = true
  RemoveAllUnusedImages = true
    │
    ▼
Command Construction (MonitoringService.cs:234–315):
  1. ["container", "prune", "-f"]                                            (Line 256)
  2. ["run", "--rm", "-v", "/var/lib/docker/containers:/containers", ...]     (Line 262)
  3. ["image", "prune", "-f", "-a"]                                          (Lines 275–277)
  4. ["network", "prune", "-f"]                                              (Line 285)
  5. ["system", "prune", "-f", "-a"]                                         (Lines 293–295)
  6. ["builder", "prune", "-a", "-f"]                                        (Line 299)
  7. ["exec", "docker-registry-backend", "registry", "garbage-collect", ...]  (Line 305)
    │
    ▼
Process Execution (MonitoringService.cs:672–724):
  ExecuteCommandWithTimeoutAsync("docker", TimeSpan.FromMinutes(3), args)
  Spawns System.Diagnostics.Process targeting host Docker daemon socket
```

---

## 5. Resolution of the Contradiction

The Developer's report asserts:
> *"Automatic Docker pruning execution: NOT evidenced by inspected current source code."*

AND concurrently states:
> *"DockerCleanupBackgroundService calls MonitoringService.CleanupDockerAsync with RemoveAllUnusedImages = true."*

### Independent Reviewer Resolution:
These two statements are **factually incompatible**.
Because:
1. `DockerCleanupBackgroundService` is a registered hosted service that runs automatically in production;
2. It unconditionally invokes `MonitoringService.CleanupDockerAsync`;
3. It passes `DryRun = false`, `CleanContainers = true`, `CleanImages = true`, `CleanNetworks = true`, `CleanSystem = true`, and `RemoveAllUnusedImages = true`;
4. Those arguments cause `MonitoringService.ExecuteCommandWithTimeoutAsync` to execute real OS processes issuing `docker container prune -f`, `docker image prune -f -a`, `docker network prune -f`, `docker system prune -f -a`, and `docker builder prune -a -f`.

Therefore:
# Automatic Docker cleanup IS evidenced in source code.

The true defect is that this automatic cleanup is **indiscriminate, aggressive, and destroys rollback caches** by wiping all unused images (`-a`), leaving zero prior releases on disk.

Describing automatic Docker cleanup as "NOT evidenced" in active documentation is factually false and misrepresents the platform's actual implementation reality.
