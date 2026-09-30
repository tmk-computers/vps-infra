# 04 Command-by-Command Execution Classification

**Document ID**: `REVIEW-R6-04-COMMAND-CLASSIFICATION`  
**Role**: Antigravity Conversation 2 — Independent Reviewer  
**Date**: 2026-09-30  

---

## 1. Exhaustive Docker Cleanup Command Classification

Every Docker prune/cleanup command referenced across the codebase or documentation was independently audited:

| Command | Exists in Source | Execution Path in Source | Automatic (Background) | Operator Invoked (API) | Diagnostic Suggestion Only |
|---|:---:|---|:---:|:---:|:---:|
| **`docker container prune -f`** | **YES** | `MonitoringService.cs:256` (`CleanupDockerAsync`) | **YES** (`DockerCleanupBackgroundService.cs:267,274`) | **YES** (`MonitoringController.cs:71,111`) | **NO** |
| **`docker image prune -f`** | **YES** | `MonitoringService.cs:275-277` (when `RemoveAllUnusedImages = false`) | **NO** (Background service forces `RemoveAllUnusedImages = true`) | **YES** (`MonitoringController.cs:71,111`) | **NO** |
| **`docker image prune -f -a`** | **YES** | `MonitoringService.cs:275-277` (when `RemoveAllUnusedImages = true`) | **YES** (`DockerCleanupBackgroundService.cs:271,274`) | **YES** (`MonitoringController.cs:71,111`) | **NO** |
| **`docker network prune -f`** | **YES** | `MonitoringService.cs:285` (`CleanupDockerAsync`) | **YES** (`DockerCleanupBackgroundService.cs:269,274`) | **YES** (`MonitoringController.cs:71,111`) | **NO** |
| **`docker volume prune -f`** | **NO** | **NONE** (Does not exist in C# source or DTO models) | **NO** | **NO** | **NO** |
| **`docker builder prune -a -f`** | **YES** | `MonitoringService.cs:299` (`CleanupDockerAsync`) | **YES** (`DockerCleanupBackgroundService.cs:270,274`) | **YES** (`MonitoringController.cs:71,111`) | **NO** |
| **`docker system prune -f`** | **YES** | 1. `MonitoringService.cs:293-295` (when `RemoveAllUnusedImages = false`)<br>2. `CiDiagnosticsAgentService.cs:241` (String in suggested fix list) | **NO** (Background service forces `-a` flag)| **YES** (`MonitoringController.cs:71,111` when `CleanSystem = true` and `RemoveAllUnusedImages = false`) | **YES** (Only in `CiDiagnosticsAgentService.cs:241`) |
| **`docker system prune -f -a`** | **YES** | `MonitoringService.cs:293-295` (when `CleanSystem = true` and `RemoveAllUnusedImages = true`) | **YES** (`DockerCleanupBackgroundService.cs:270,271,274`) | **YES** (`MonitoringController.cs:71,111` when `CleanSystem = true` and `RemoveAllUnusedImages = true`) | **NO** |

---

## 2. In-Depth Analysis: `CiDiagnosticsAgentService.cs:241`

Direct inspection of [`CiDiagnosticsAgentService.cs:230-243`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/CiDiagnosticsAgentService.cs#L230-L243):

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

### Downstream Trace:
1. **Controller Consumption**: The service is called by `AiCiDiagnosticsController.cs` in endpoints `DiagnoseService` (line 35) and `DiagnoseRaw` (line 51).
2. **Response Delivery**: `AiCiDiagnosticsController` serializes the returned tuple into a `CiDiagnosticResponseDTO` and returns `Ok(result)` over HTTP.
3. **Execution Check**: Zero controllers, background workers, or automated runners parse or execute the strings in `SuggestedFixCommands`.
4. **Conclusion**: `"docker system prune -f"` at line 241 is **purely a diagnostic suggestion string**. It is never executed automatically by the platform.

---

## 3. In-Depth Analysis: `MonitoringService.cs:293-295` System Prune

Direct inspection of [`MonitoringService.cs:289-296`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/MonitoringService.cs#L289-L296):

```csharp
289:                 // 4. System Prune
290:                 if (request.CleanSystem)
291:                 {
292:                     outputBuilder.AppendLine("\n> Running system prune...");
293:                     var args = new List<string> { "system", "prune", "-f" };
294:                     if (request.RemoveAllUnusedImages) args.Add("-a");
295:                     var systemOutput = await ExecuteCommandAsync("docker", args.ToArray());
296:                     outputBuilder.AppendLine(systemOutput);
```

### Analysis:
1. When `request.CleanSystem` is `true` and `request.RemoveAllUnusedImages` is `true`, the argument array constructed is:
   `["system", "prune", "-f", "-a"]`.
2. `ExecuteCommandAsync("docker", args.ToArray())` executes:
   `docker system prune -f -a`.
3. In [`DockerCleanupBackgroundService.cs:270-272`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/BackgroundServices/DockerCleanupBackgroundService.cs#L270-L272), both `CleanSystem = true` and `RemoveAllUnusedImages = true` are hardcoded!
4. **Conclusion**: `docker system prune -f -a` **IS actively executed** by the automated background cleanup service on its daily cron schedule!

The Developer's claim that `docker system prune -a` does not exist or is not executed in project code is disproven by the actual dynamic string list construction in `MonitoringService.cs:293-295`.
