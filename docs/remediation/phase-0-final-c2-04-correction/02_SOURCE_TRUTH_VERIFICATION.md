# Source Truth Verification & Static Code Analysis

**Document ID**: `FINAL-C2-04-02-SOURCE-VERIFICATION`  
**Phase**: Phase 0 — Final C2-04 Evidence Correction  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — FULLY RECONCILED  

---

## 1. Scope of Investigation

Following the independent review (`REVIEW-R6-REPORT-C2-04`), this document provides an exhaustive, line-by-line static inspection of the relevant source files across the `vps-infra-server` and `vps-infra` repositories to establish objective, canonical source truth regarding:
1. What [`MonitoringService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs) actually executes at line 213;
2. What [`MonitoringService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs) executes in `CleanupDockerAsync` (lines 234–323);
3. What [`CiDiagnosticsAgentService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/CiDiagnosticsAgentService.cs) does at line 241;
4. What [`DockerCleanupBackgroundService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs) actually performs;
5. What exact Docker prune commands are executed automatically vs. on-demand.

---

## 2. Source Code Inspection Results

### 2.1 `MonitoringService.cs` (Lines 195–218)
Direct inspection of `devops-manager/api/Infrastructure/Services/MonitoringService.cs`:

```csharp
202:                 else
203:                 {
204:                     // Check if it exists but is stopped
205:                     var psStatus = await ExecuteCommandAsync("docker", "ps", "-a", "--filter", $"name=^/{service.ServiceName}$", "--format", "{{.Status}}");
206:                     statusDTO.Status = string.IsNullOrWhiteSpace(psStatus) ? "Not Found" : psStatus.Trim();
207:                     statusDTO.CpuUsage = "0%";
208:                     statusDTO.MemoryUsage = "0B";
209:                 }
210:             }
211:             catch (Exception ex)
212:             {
213:                 _logger.LogWarning("Failed to get docker status for {Container}: {Msg}", service.ServiceName, ex.Message);
214:                 statusDTO.Status = "Error";
215:             }
216: 
217:             return statusDTO;
218:         }
```

#### Authoritative Source Truth:
- **Function**: `GetProjectStatusAsync(Guid serviceId)`.
- **Line 213**: `_logger.LogWarning("Failed to get docker status for {Container}: {Msg}", service.ServiceName, ex.Message);`
- **Finding**: Line 213 is an error log inside a container status inquiry. It does **NOT** issue `docker system prune -a`, nor does it execute any cleanup command whatsoever. Line 213 was erroneously cited in earlier drafts as Docker cleanup implementation.

---

### 2.2 `MonitoringService.cs` (Lines 234–323: `CleanupDockerAsync`)
Inspection of the actual cleanup method in `MonitoringService.cs`:

```csharp
234:         public async Task<string> CleanupDockerAsync(DockerCleanupRequestDto request)
235:         {
236:             var outputBuilder = new System.Text.StringBuilder();
237:             
238:             try
239:             {
240:                 if (request.DryRun)
241:                 {
242:                     outputBuilder.AppendLine("=== Docker Cleanup Preview (Dry Run) ===");
243:                     outputBuilder.AppendLine("> Analyzing reclaimable space...\n");
244:                     var dfOutput = await ExecuteCommandAsync("docker", "system", "df");
245:                     outputBuilder.AppendLine(dfOutput);
246:                     outputBuilder.AppendLine("\n> (No data was deleted. Uncheck Dry Run to execute.)");
247:                     return outputBuilder.ToString();
248:                 }
249: 
250:                 outputBuilder.AppendLine("=== Docker Cleanup Started ===");
251: 
252:                 // 1. Prune Containers & Truncate Active Container Logs
253:                 if (request.CleanContainers)
254:                 {
255:                     outputBuilder.AppendLine("\n> Removing stopped containers...");
256:                     var containerOutput = await ExecuteCommandAsync("docker", "container", "prune", "-f");
257:                     outputBuilder.AppendLine(containerOutput);
258: 
259:                     outputBuilder.AppendLine("\n> Truncating active container json log files (>50MB)...");
260:                     try
261:                     {
262:                         var truncateOutput = await ExecuteCommandAsync("docker", "run", "--rm", "-v", "/var/lib/docker/containers:/containers", "alpine", "sh", "-c", "find /containers -name '*-json.log' -size +50000k -exec truncate -s 0 {} +");
263:                         outputBuilder.AppendLine(string.IsNullOrWhiteSpace(truncateOutput) ? "Active container logs (>50MB) successfully truncated." : truncateOutput);
264:                     }
265:                     catch (Exception logEx)
266:                     {
267:                         outputBuilder.AppendLine($"\n⚠️ Container log truncation failed: {logEx.Message}");
268:                     }
269:                 }
270: 
271:                 // 2. Prune Images
272:                 if (request.CleanImages)
273:                 {
274:                     outputBuilder.AppendLine($"\n> Removing unused images (RemoveAll: {request.RemoveAllUnusedImages})...");
275:                     var args = new List<string> { "image", "prune", "-f" };
276:                     if (request.RemoveAllUnusedImages) args.Add("-a");
277:                     var imageOutput = await ExecuteCommandAsync("docker", args.ToArray());
278:                     outputBuilder.AppendLine(imageOutput);
279:                 }
280: 
281:                 // 3. Prune Networks
282:                 if (request.CleanNetworks)
283:                 {
284:                     outputBuilder.AppendLine("\n> Removing unused networks...");
285:                     var networkOutput = await ExecuteCommandAsync("docker", "network", "prune", "-f");
286:                     outputBuilder.AppendLine(networkOutput);
287:                 }
288: 
289:                 // 4. System Prune
290:                 if (request.CleanSystem)
291:                 {
292:                     outputBuilder.AppendLine("\n> Running system prune...");
293:                     var args = new List<string> { "system", "prune", "-f" };
294:                     if (request.RemoveAllUnusedImages) args.Add("-a");
295:                     var systemOutput = await ExecuteCommandAsync("docker", args.ToArray());
296:                     outputBuilder.AppendLine(systemOutput);
297: 
298:                     outputBuilder.AppendLine("\n> Running builder cache prune...");
299:                     var builderOutput = await ExecuteCommandAsync("docker", "builder", "prune", "-a", "-f");
300:                     outputBuilder.AppendLine(builderOutput);
301: 
302:                     outputBuilder.AppendLine("\n> Running local registry garbage collection...");
303:                     try
304:                     {
305:                         var gcOutput = await ExecuteCommandAsync("docker", "exec", "docker-registry-backend", "registry", "garbage-collect", "-m", "/etc/docker/registry/config.yml");
306:                         outputBuilder.AppendLine(gcOutput);
307:                     }
308:                     catch (Exception registryEx)
309:                     {
310:                         outputBuilder.AppendLine($"\n⚠️ Registry GC failed: {registryEx.Message}");
311:                     }
312:                 }
313: 
314:                 outputBuilder.AppendLine("\n=== Docker Cleanup Completed Successfully ===");
315:             }
316:             catch (Exception ex)
317:             {
318:                 _logger.LogError(ex, "Docker cleanup failed");
319:                 outputBuilder.AppendLine($"\n❌ ERROR: {ex.Message}");
320:             }
321: 
322:             return outputBuilder.ToString();
323:         }
```

#### Authoritative Source Truth:
- **Function**: Core Docker cleanup execution method, invoked either by administrative HTTP requests via `MonitoringController` or automatically by `DockerCleanupBackgroundService`.
- **Process Spawning**: Commands are passed to `ExecuteCommandWithTimeoutAsync` (lines 672–724), which spawns `System.Diagnostics.Process` with `FileName = command`, redirecting stdout/stderr and awaiting exit with a 3-minute timeout. This is real OS-level process execution against the host Docker daemon.
- **Executed Commands**:
  - `docker system df` (when `DryRun == true`)
  - `docker container prune -f` (when `CleanContainers == true`)
  - `docker run --rm -v /var/lib/docker/containers:/containers alpine sh -c "find /containers -name '*-json.log' -size +50000k -exec truncate -s 0 {} +"` (when `CleanContainers == true`)
  - `docker image prune -f` (when `CleanImages == true` and `RemoveAllUnusedImages == false`)
  - `docker image prune -f -a` (when `CleanImages == true` and `RemoveAllUnusedImages == true`)
  - `docker network prune -f` (when `CleanNetworks == true`)
  - `docker system prune -f` (when `CleanSystem == true` and `RemoveAllUnusedImages == false`)
  - `docker system prune -f -a` (when `CleanSystem == true` and `RemoveAllUnusedImages == true`)
  - `docker builder prune -a -f` (when `CleanSystem == true`)
  - `docker exec docker-registry-backend registry garbage-collect -m /etc/docker/registry/config.yml` (when `CleanSystem == true`)
- **Absence of Volume Pruning**:
  - **No explicit `docker volume prune` command was identified in the inspected current C# source.**
  - Neither `docker volume prune` nor a `CleanVolumes` DTO property exists in `MonitoringService.cs` or `DockerCleanupRequestDto.cs`. Previous documentation citing a volume prune option or `docker volume prune -f` was a documentation error and has been completely retracted.

---

### 2.3 `CiDiagnosticsAgentService.cs` (Lines 230–243)
Inspection of `devops-manager/api/Infrastructure/Services/AI/CiDiagnosticsAgentService.cs`:

```csharp
230:             // 6. Docker Build OOM / JavaScript Heap Out of Memory
231:             if (Regex.IsMatch(logs, @"(JavaScript heap out of memory|exit code: 137|Killed|out of memory|fatal error: runtime: out of memory|OOMKilled)", RegexOptions.IgnoreCase))
232:             {
233:                 string fix = @"### ❌ Out of Memory (OOM) Build Failure
234: * **Identified Error**: Build container killed by Linux OOM killer (Exit Code 137).
235: * **Root Cause**: Build process exceeded available container RAM allocation.
236: * **Suggested Fix**: Increase container RAM limit, set `NODE_OPTIONS=--max-old-space-size=2048`, or scale host swap memory.";
237: 
238:                 return ("DockerBuildOOM", "Build process killed by host OOM killer (Exit 137).", fix, new List<string>
239:                 {
240:                     "export NODE_OPTIONS=--max-old-space-size=2048",
241:                     "docker system prune -f"
242:                 });
243:             }
```

#### Authoritative Source Truth:
- **Function**: Diagnostic pattern-matching service analyzing CI build failure logs.
- **Line 241**: `"docker system prune -f"` as a string literal in a `List<string>`.
- **Finding**: This occurrence is purely a **suggested remediation string** returned to the caller / UI to help an operator troubleshoot an OOM build failure. It is **NEVER executed** by `CiDiagnosticsAgentService` or any automated runner.
- **Distinction**: This diagnostic recommendation must not be confused with the actual execution path in `MonitoringService.CleanupDockerAsync`, which actively constructs and executes `docker system prune -f [-a]`.

---

### 2.4 `DockerCleanupBackgroundService.cs` (Lines 164–318)
Inspection of the background service `devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs`:

1. **Dependency Injection & Registration**:
   Registered unconditionally in `devops-manager/api/Program.cs:359`:
   ```csharp
   builder.Services.AddHostedService<DockerCleanupBackgroundService>();
   ```
   As an `IHostedService`, it is automatically instantiated and started by the ASP.NET Core generic host upon application startup.
2. **Scheduling**:
   Executes on a scheduled daily cron loop. Default cron is `"0 0 3 * * ?"` (3:00 AM daily IST), configurable via `/app/backups/docker_cleanup_cron_config.json`.
3. **Execution Call Path**:
   In `RunDockerCleanupAsync()` (lines 257–275):
   ```csharp
   using var scope = _serviceProvider.CreateScope();
   var monitoringService = scope.ServiceProvider.GetRequiredService<IMonitoringService>();
   var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

   var request = new DockerCleanupRequestDto
   {
       DryRun = false,
       CleanContainers = true,
       CleanImages = true,
       CleanNetworks = true,
       CleanSystem = true,
       RemoveAllUnusedImages = true
   };

   string output = await monitoringService.CleanupDockerAsync(request);
   ```

#### Authoritative Source Truth:
- **Function**: Scheduled background service executing automatically in production.
- **Executed Actions**:
  - Deletes database logs (`SystemLogs`, `DeploymentLogs`, `ci_build_logs`) older than 14 days;
  - Deletes local filesystem build artifacts and application log files;
  - Truncates oversized container JSON log files (>50MB);
  - Calls `monitoringService.CleanupDockerAsync(request)` with `RemoveAllUnusedImages = true`, executing real Docker CLI commands (`docker container prune -f`, `docker image prune -f -a`, `docker network prune -f`, `docker system prune -f -a`, `docker builder prune -a -f`, and registry GC).
- **Finding**: Automatic Docker storage cleanup **EXISTS** and runs on a daily schedule. However, because it passes `RemoveAllUnusedImages = true`, it executes `docker image prune -f -a` and `docker system prune -f -a`, indiscriminately purging all non-running container images and destroying local rollback caches. This is the defect tracked under **Codex F13**, **Antigravity DEF-16**, and **MR-17**.

---

## 3. Repository-Wide Static Grep Summary

A comprehensive search across both repositories confirms:
- **`scripts/cleanup-docker.sh`**: Does **NOT exist** anywhere on disk (0 files).
- **`docker volume prune`**: **No explicit command identified in C# source**.
- **`docker system prune`**: Occurs in `MonitoringService.cs:293-295` (dynamically executed) and `CiDiagnosticsAgentService.cs:241` (diagnostic suggestion string).
- **Automatic Docker cleanup execution**: **EXISTS** via `DockerCleanupBackgroundService` calling `MonitoringService.CleanupDockerAsync`.
- **Safe Rollback-Aware Retention**: **NOT IMPLEMENTED**.

---

## 4. Canonical Source Truth Table

| Capability | Current Source Evidence | Automatic? | Current Safety Status | Future Owner |
|---|---|:---:|---|---|
| **Container prune** | `MonitoringService.cs:256` (`CleanupDockerAsync`) | **Yes** | Basic / unsafe (removes stopped containers) | MR-17 |
| **Active container log truncation** | `MonitoringService.cs:262` (`find ... -exec truncate`) | **Yes** | Truncates JSON logs > 50MB | MR-17 |
| **Image prune (`-f`)** | `MonitoringService.cs:275` (when `RemoveAll=false`) | **No** (Background passes `RemoveAll=true`) | Operator on-demand only | MR-17 |
| **Image prune (`-f -a`)** | `MonitoringService.cs:275-277` (when `RemoveAll=true`) | **Yes** | Aggressive / Rollback risk (purges unused images) | MR-17 |
| **Network prune** | `MonitoringService.cs:285` (`CleanupDockerAsync`) | **Yes** | Basic (removes unattached networks) | MR-17 |
| **System prune (`-f -a`)** | `MonitoringService.cs:293-295` (when `CleanSystem` & `RemoveAll`) | **Yes** | Aggressive / Rollback risk | MR-17 |
| **Builder prune (`-a -f`)** | `MonitoringService.cs:299` (`CleanupDockerAsync`) | **Yes** | Basic / aggressive build cache purge | MR-17 |
| **Local registry GC** | `MonitoringService.cs:305` (`docker exec ... registry garbage-collect`) | **Yes** | Basic registry space reclaim | MR-17 |
| **Volume prune** | **No explicit command found in C# source** | **No explicit evidence** | N/A (`CleanVolumes` nonexistent) | — |
| **CI prune recommendation** | `CiDiagnosticsAgentService.cs:241` | **No** | Recommendation string only (never executed) | — |
| **Rollback-aware retention** | **No evidence in current source** | **No** | Missing (wipes rollback cache on schedule) | MR-17 |
