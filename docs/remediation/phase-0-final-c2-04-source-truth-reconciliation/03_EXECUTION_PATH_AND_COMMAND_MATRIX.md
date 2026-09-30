# 03 Execution Path and Command Matrix

**Document ID**: `RECON-C2-04-03-COMMAND-MATRIX`  
**Phase**: Phase 0 — C2-04 Final Source-Truth Reconciliation  
**Author**: Antigravity Conversation 1 — Developer  
**Date**: 2026-09-30  
**Status**: COMPLETE — AUTHORITATIVE  

---

## 1. Canonical Capability Classification

In accordance with Section 9 of the reconciliation mandate, the platform's Docker cleanup capabilities are authoritatively classified as follows:

| Capability Domain | Status | Source Evidence |
|---|:---:|---|
| **Automated Docker cleanup** | **IMPLEMENTED / EXISTS** | `DockerCleanupBackgroundService.cs:257-275` (runs daily via cron) |
| **Scheduled execution** | **IMPLEMENTED / EXISTS** | `builder.Services.AddHostedService<DockerCleanupBackgroundService>()` (`Program.cs:359`) |
| **Docker CLI pruning** | **IMPLEMENTED / EXISTS** | `MonitoringService.cs:234-323` spawns real `System.Diagnostics.Process` |
| **Safe deployment-aware cleanup** | **NOT IMPLEMENTED** | Uncoordinated execution; no deployment awareness or mutex |
| **Rollback-aware image retention** | **NOT IMPLEMENTED** | Wipes unused images with `-a`; zero rollback digest preservation |
| **Known-good release preservation** | **NOT IMPLEMENTED** | No release manifest or digest check before pruning |
| **Deployment/cleanup concurrency protection** | **NOT IMPLEMENTED** | Cleanup and deploy can run concurrently without mutual exclusion |
| **Intelligent mark-and-sweep release retention** | **NOT IMPLEMENTED** | Unimplemented (remediation owned by MR-17) |

---

## 2. Canonical Single Source-Truth Table

The table below provides the authoritative, exhaustive mapping of every Docker cleanup operation in the platform:

| Capability | Current Source Evidence | Automatic? | Current Safety Status | Future Owner |
|---|---|:---:|---|---|
| **Container prune** | `MonitoringService.cs:256` (`CleanupDockerAsync`) | **Yes** (`DockerCleanupBackgroundService.cs:267,274`) | Basic / unsafe (removes stopped containers) | MR-17 |
| **Active container log truncation** | `MonitoringService.cs:262` (`find ... -exec truncate`) | **Yes** (`DockerCleanupBackgroundService.cs:267,274`) | Truncates JSON logs > 50MB via ephemeral Alpine container | MR-17 |
| **Image prune (`-f`)** | `MonitoringService.cs:275` (when `RemoveAll=false`) | **No** (Background service forces `RemoveAll=true`) | Operator on-demand only (prunes dangling images) | MR-17 |
| **Image prune (`-f -a`)** | `MonitoringService.cs:275-277` (when `RemoveAll=true`) | **Yes** (`DockerCleanupBackgroundService.cs:271,274`) | Aggressive / Rollback risk (purges all non-running images) | MR-17 |
| **Network prune** | `MonitoringService.cs:285` (`CleanupDockerAsync`) | **Yes** (`DockerCleanupBackgroundService.cs:269,274`) | Basic (removes unattached networks) | MR-17 |
| **System prune (`-f`)** | `MonitoringService.cs:293` (when `RemoveAll=false`) | **No** (Background service forces `RemoveAll=true`) | Operator on-demand only | MR-17 |
| **System prune (`-f -a`)** | `MonitoringService.cs:293-295` (when `CleanSystem` & `RemoveAll`) | **Yes** (`DockerCleanupBackgroundService.cs:270,271,274`) | Aggressive / Rollback risk (purges all non-running images) | MR-17 |
| **Builder prune (`-a -f`)** | `MonitoringService.cs:299` (`CleanupDockerAsync`) | **Yes** (`DockerCleanupBackgroundService.cs:270,274`) | Basic / aggressive build cache purge | MR-17 |
| **Local registry GC** | `MonitoringService.cs:305` (`docker exec ... registry garbage-collect`) | **Yes** (`DockerCleanupBackgroundService.cs:270,274`) | Basic registry space reclaim | MR-17 |
| **Volume prune** | **No explicit command found in current C# source** | **No explicit evidence** | N/A (`CleanVolumes` nonexistent in DTO/Service) | — |
| **CI prune recommendation** | `CiDiagnosticsAgentService.cs:241` | **No** | Recommendation only (never executed automatically) | — |
| **Rollback-aware retention** | **No evidence in current source** | **No** | Missing (wipes rollback cache on schedule) | MR-17 |

---

## 3. Command-by-Command Deep Dive

### 3.1 `docker container prune -f`
- **Source Location**: `MonitoringService.cs:256`.
- **Automatic Call Path**: `DockerCleanupBackgroundService.cs:267` sets `CleanContainers = true`.
- **Runtime Impact**: Removes all stopped containers. Running project containers are unaffected by standard Docker daemon semantics.

### 3.2 Active Container Log Truncation
- **Source Location**: `MonitoringService.cs:262` and `DockerCleanupBackgroundService.cs:233`.
- **Command**: `docker run --rm -v /var/lib/docker/containers:/containers alpine sh -c "find /containers -name '*-json.log' -size +50000k -exec truncate -s 0 {} +"`
- **Automatic Call Path**: Runs as part of `CleanContainers = true` in `CleanupDockerAsync` and standalone in `TruncateOversizedContainerLogs`.
- **Architectural Debt**: Directly modifies Docker container log files on the host filesystem, bypassing Docker daemon logging counters (tracked under `MR-24`).

### 3.3 `docker image prune -f -a`
- **Source Location**: `MonitoringService.cs:275-277`.
- **Automatic Call Path**: `DockerCleanupBackgroundService.cs:271` hardcodes `RemoveAllUnusedImages = true`.
- **Runtime Impact**: Destructive to rollback. The `-a` flag instructs Docker to delete all images that are not actively associated with a currently running container. Images belonging to prior successful deployments are immediately purged from the local cache.

### 3.4 `docker network prune -f`
- **Source Location**: `MonitoringService.cs:285`.
- **Automatic Call Path**: `DockerCleanupBackgroundService.cs:269` sets `CleanNetworks = true`.
- **Runtime Impact**: Removes user-defined networks not referenced by at least one container.

### 3.5 `docker system prune -f -a`
- **Source Location**: `MonitoringService.cs:293-295`.
- **Automatic Call Path**: `DockerCleanupBackgroundService.cs:270-271` sets `CleanSystem = true` and `RemoveAllUnusedImages = true`.
- **Runtime Impact**: Comprehensive prune of stopped containers, unused networks, and all unused images (`-a`).

### 3.6 `docker builder prune -a -f`
- **Source Location**: `MonitoringService.cs:299`.
- **Automatic Call Path**: `CleanSystem = true` in `DockerCleanupBackgroundService.cs:270`.
- **Runtime Impact**: Purges the entire Docker BuildKit build cache.

### 3.7 Local Registry Garbage Collection
- **Source Location**: `MonitoringService.cs:305`.
- **Automatic Call Path**: `CleanSystem = true` in `DockerCleanupBackgroundService.cs:270`.
- **Command**: `docker exec docker-registry-backend registry garbage-collect -m /etc/docker/registry/config.yml`
- **Runtime Impact**: Frees unreferenced blobs within the local distribution registry container.

---

## 4. Summary of Epistemic Distinctions

1. **Automation Truth**: The automated scheduled call path **DOES exist**. Falsely denying its existence contradicts source reality.
2. **Safety Truth**: The existing automated call path is **indiscriminate and unsafe for rollback**. It executes `-a` flags without release awareness.
3. **Volume Truth**: Persistent volumes are **NOT pruned**; no `docker volume prune` command exists in source.
4. **Diagnostic Truth**: `CiDiagnosticsAgentService.cs:241` contains an operator suggestion string and does not execute anything.
