# C2-04 source trace

**Result: RESOLVED.** Source establishes this execution path:

ASP.NET Core host -> AddHostedService<DockerCleanupBackgroundService>() -> BackgroundService.ExecuteAsync schedule -> RunDockerCleanupAsync() -> IMonitoringService.CleanupDockerAsync(request) -> ExecuteCommandAsync/ExecuteCommandWithTimeoutAsync -> System.Diagnostics.Process ("docker").

Program.cs:359 unconditionally registers the hosted service. Its ExecuteAsync loop obtains a cron expression from /app/backups/docker_cleanup_cron_config.json when present, with daily 0 0 3 * * ? (03:00 India time) default/fallback, waits until the next occurrence, and invokes RunDockerCleanupAsync. The request sets DryRun=false, all four cleanup toggles true, and RemoveAllUnusedImages=true.

MonitoringService.CleanupDockerAsync builds argument arrays and executes them through a real Process (UseShellExecute=false, FileName=command, each argument added via ArgumentList). On the scheduled request path it attempts:

- docker container prune -f;
- an Alpine docker run that truncates JSON logs larger than 50 MB;
- docker image prune -f -a;
- docker network prune -f;
- docker system prune -f -a;
- docker builder prune -a -f;
- docker exec docker-registry-backend registry garbage-collect -m /etc/docker/registry/config.yml.

Arguments are assembled as arrays; option order does not change the documented intent. The registry GC and log-truncation suboperations catch failures; this static source review establishes an attempted process invocation, not successful execution on a live host.

DockerCleanupRequestDto has no CleanVolumes property. No explicit docker volume prune command was found in the inspected C# source. The scheduled docker system prune command does not include --volumes; Docker documents that volumes are not removed by default. [Docker system prune reference](https://docs.docker.com/reference/cli/docker/system/prune/).

The prior MonitoringService.cs:213 attribution is corrected: that source location belongs to GetProjectStatusAsync error/status logging. Cleanup is implemented in CleanupDockerAsync (current lines 234–323).

CiDiagnosticsAgentService.cs:241 returns "docker system prune -f" inside the suggested-command list for an OOM diagnostic result. It is a diagnostic/operator recommendation. Separate automated pruning is performed by the background service through CleanupDockerAsync.
