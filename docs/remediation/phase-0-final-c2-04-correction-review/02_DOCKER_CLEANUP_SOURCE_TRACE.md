# 02 Independent Source Code Trace: MonitoringService.cs

**Document ID**: `REVIEW-R6-02-MONITORING-TRACE`  
**Role**: Antigravity Conversation 2 — Independent Reviewer  
**Audit Target**: `devops-manager/api/Infrastructure/Services/MonitoringService.cs`  
**Date**: 2026-09-30  

---

## 1. Line 213 Inspection (`GetProjectStatusAsync`)

Direct inspection of [`MonitoringService.cs:190-218`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L190-L218) shows:

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

### Empirical Source Truth:
- **Enclosing Method**: `public async Task<ProjectStatusDTO> GetProjectStatusAsync(Guid serviceId)`
- **Exact Line 213**: `_logger.LogWarning("Failed to get docker status for {Container}: {Msg}", service.ServiceName, ex.Message);`
- **Behavior**: It catches an exception when querying `docker ps` status for a project service and logs a warning.
- **Cleanup Commands**: **Zero**. Line 213 does NOT execute `docker system prune`, `docker system prune -a`, or any cleanup command whatsoever. Codex's determination that line 213 was a false attribution is confirmed.

---

## 2. `CleanupDockerAsync` Implementation (Lines 234–323)

Inspection of [`MonitoringService.cs:234-323`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L234-L323) reveals the actual cleanup logic:

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

---

## 3. Process Execution Helpers

Inspection of lines 667–724 in `MonitoringService.cs`:

```csharp
667:         private async Task<string> ExecuteCommandAsync(string command, params string[] arguments)
668:         {
669:             return await ExecuteCommandWithTimeoutAsync(command, TimeSpan.FromMinutes(3), arguments);
670:         }
671: 
672:         public async Task<string> ExecuteCommandWithTimeoutAsync(string command, TimeSpan timeout, params string[] arguments)
673:         {
674:             try
675:             {
676:                 var processStartInfo = new ProcessStartInfo
677:                 {
678:                     FileName = command,
679:                     RedirectStandardOutput = true,
680:                     RedirectStandardError = true,
681:                     UseShellExecute = false,
682:                     CreateNoWindow = true
683:                 };
684: 
685:                 foreach (var arg in arguments)
686:                 {
687:                     processStartInfo.ArgumentList.Add(arg);
688:                 }
689: 
690:                 using var process = new Process { StartInfo = processStartInfo };
691:                 process.Start();
...
```

### Analysis of Process Execution:
1. **Real OS Process Execution**: The execution helper spawns a real operating system process via `System.Diagnostics.Process`. Output and error streams are captured, and timeouts are enforced. This is **real, active execution**, NOT simulated or mock code.
2. **Commands Executed by `CleanupDockerAsync`**:
   - `docker system df` (when `DryRun == true`)
   - `docker container prune -f` (when `CleanContainers == true`)
   - `docker run --rm -v /var/lib/docker/containers:/containers alpine ... truncate ...` (when `CleanContainers == true`)
   - `docker image prune -f` (when `CleanImages == true` and `RemoveAllUnusedImages == false`)
   - `docker image prune -f -a` (when `CleanImages == true` and `RemoveAllUnusedImages == true`)
   - `docker network prune -f` (when `CleanNetworks == true`)
   - `docker system prune -f` (when `CleanSystem == true` and `RemoveAllUnusedImages == false`)
   - `docker system prune -f -a` (when `CleanSystem == true` and `RemoveAllUnusedImages == true`)
   - `docker builder prune -a -f` (when `CleanSystem == true`)
   - `docker exec docker-registry-backend registry garbage-collect -m /etc/docker/registry/config.yml` (when `CleanSystem == true`)
3. **Absence of Volume Pruning**:
   - `docker volume prune` does **NOT** exist in `CleanupDockerAsync`.
   - `request.CleanVolumes` does **NOT** exist in `DockerCleanupRequestDto`.
   - Developer documentation in `01_C2_04_ROOT_CAUSE.md`, `02_SOURCE_TRUTH_VERIFICATION.md`, and `04_CLEANUP_CAPABILITY_CLASSIFICATION.md` claiming volume pruning exists in this method is factually false.
