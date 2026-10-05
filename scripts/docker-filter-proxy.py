#!/usr/bin/env python3
"""
Hardened Payload-Inspecting Docker Socket Proxy
Intercepts Docker API calls and denies:
- Host bind mounts outside approved directories (inspecting BOTH HostConfig.Binds and HostConfig.Mounts)
- Privileged container flags
- Host namespace sharing (pid, ipc, network, userns, uts)
- Dangerous Linux capabilities (SYS_ADMIN, DAC_OVERRIDE, ALL, etc.)
- Host devices
"""

import asyncio
import json
import os
import re
import signal
import sys

# Prevent terminal interrupts from stopping the proxy when running as daemon
if "--daemon" in sys.argv:
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGHUP, signal.SIG_IGN)

TARGET_SOCK = os.getenv("FILTER_PROXY_TARGET_SOCK", "/var/run/docker.sock")
LISTEN_SOCK = os.getenv("FILTER_PROXY_LISTEN_SOCK", "/var/run/docker-filtered/docker.sock")
LISTEN_DIR = os.path.dirname(LISTEN_SOCK) or "."
SOCKET_MODE = int(os.getenv("FILTER_PROXY_SOCKET_MODE", "0660"), 8)

# Approved path prefixes for host mounts (strictly scoped, no raw /tmp or /volumes)
ALLOWED_MOUNT_PREFIXES = (
    "/var/www/vps-infra/code",
    "/var/www/vps-infra/apps",
    "/var/www/vps-infra/ci-server",
    "/var/www/vps-infra/volumes/artifacts",
    "/var/www/vps-infra/volumes/apk",
    "/var/www/vps-infra/volumes/apps",
    "/tmp/vps-infra-pins",
)

DISALLOWED_HOST_PATHS = (
    "/",
    "/etc",
    "/var/run",
    "/root",
    "/sys",
    "/proc",
    "/dev",
    "/boot",
    "/usr",
    "/bin",
    "/sbin",
    "/lib",
    "/lib64",
    "/home",
)

DISALLOWED_SUBPATHS = (
    "/var/www/vps-infra/volumes/db",
    "/var/www/vps-infra/volumes/infra",
    "/var/www/vps-infra/volumes/license.key",
)

DANGEROUS_CAPS = {
    "SYS_ADMIN", "CAP_SYS_ADMIN",
    "SYS_PTRACE", "CAP_SYS_PTRACE",
    "DAC_OVERRIDE", "CAP_DAC_OVERRIDE",
    "DAC_READ_SEARCH", "CAP_DAC_READ_SEARCH",
    "SYS_MODULE", "CAP_SYS_MODULE",
    "SYS_RAWIO", "CAP_SYS_RAWIO",
    "ALL",
}

def is_path_allowed(path_str):
    if not path_str or not isinstance(path_str, str):
        return False
    try:
        resolved = os.path.realpath(path_str.strip())
    except Exception:
        return False

    # Check if exact match with prohibited root/system dirs
    if resolved in DISALLOWED_HOST_PATHS:
        return False

    # Check if inside forbidden root/system dirs
    for forbidden in ("/etc", "/var/run", "/root", "/sys", "/proc", "/dev", "/boot", "/usr", "/bin", "/sbin", "/lib", "/lib64", "/home"):
        if resolved == forbidden or resolved.startswith(forbidden + "/"):
            return False

    # Check if inside forbidden sensitive subpaths
    for disallowed_sub in DISALLOWED_SUBPATHS:
        if resolved == disallowed_sub or resolved.startswith(disallowed_sub + "/"):
            return False

    # Block broad /tmp access
    if resolved == "/tmp" or resolved == "/tmp/":
        return False

    # Check if inside allowed trees
    for allowed in ALLOWED_MOUNT_PREFIXES:
        if resolved == allowed or resolved.startswith(allowed + "/"):
            return True

    return False

def validate_container_create_payload(body_bytes):
    if not body_bytes:
        return (400, "400 Bad Request: Empty container create request body.")

    try:
        body_str = body_bytes.decode('utf-8')
    except UnicodeDecodeError as ude:
        return (400, f"400 Bad Request: Non-UTF-8 payload encoding ({ude}).")

    try:
        data = json.loads(body_str)
    except Exception as je:
        return (400, f"400 Bad Request: Malformed JSON payload ({je}).")

    if not isinstance(data, dict):
        return (400, "400 Bad Request: Container configuration must be a JSON object.")

    host_config = data.get("HostConfig") or {}
    if not isinstance(host_config, dict):
        return (400, "400 Bad Request: HostConfig must be a JSON object.")

    # 1. Privileged mode check
    if host_config.get("Privileged") is True:
        return (403, "403 Forbidden: Privileged container mode is strictly prohibited.")

    # 2. Host namespace checks
    for ns_field in ("PidMode", "IpcMode", "NetworkMode", "UsernsMode", "UtsMode", "CgroupnsMode"):
        val = host_config.get(ns_field)
        if isinstance(val, str) and val.strip().lower() == "host":
            return (403, f"403 Forbidden: Host namespace sharing ({ns_field}=host) is strictly prohibited.")

    # 3. Dangerous capabilities check
    cap_add = host_config.get("CapAdd") or []
    if isinstance(cap_add, list):
        for cap in cap_add:
            if str(cap).upper() in DANGEROUS_CAPS:
                return (403, f"403 Forbidden: Dangerous Linux capability ({cap}) is strictly prohibited.")

    # 4. Host devices check
    if host_config.get("Devices"):
        return (403, "403 Forbidden: Host device mounting is strictly prohibited.")

    if host_config.get("DeviceRequests"):
        return (403, "403 Forbidden: Host device requests are prohibited.")

    # 5. SecurityOpt unconfined check
    security_opt = host_config.get("SecurityOpt") or []
    if isinstance(security_opt, list):
        for opt in security_opt:
            opt_str = str(opt).lower()
            if "unconfined" in opt_str or "disable" in opt_str:
                return (403, f"403 Forbidden: Disabling container security profiles ({opt}) is prohibited.")

    # 6. VolumesFrom check
    volumes_from = host_config.get("VolumesFrom") or []
    if volumes_from:
        return (403, "403 Forbidden: VolumesFrom mount inheritance is strictly prohibited.")

    # 7. HostConfig.Binds inspection (Representation 1: list of strings)
    binds = host_config.get("Binds") or []
    if not isinstance(binds, list):
        return (400, "400 Bad Request: HostConfig.Binds must be a list.")
    for bind in binds:
        if not isinstance(bind, str) or not bind.strip():
            return (400, "400 Bad Request: Invalid bind mount format.")
        parts = bind.split(":")
        if len(parts) < 2 or not parts[0].strip():
            return (400, f"400 Bad Request: Malformed bind specification '{bind}'.")
        host_src = parts[0].strip()
        if not is_path_allowed(host_src):
            return (403, f"403 Forbidden: Unauthorized host bind mount path '{host_src}'. Mounts outside approved workspaces are blocked.")

    # 8. HostConfig.Mounts inspection (Representation 2: list of mount objects)
    mounts = host_config.get("Mounts") or []
    if not isinstance(mounts, list):
        return (400, "400 Bad Request: HostConfig.Mounts must be a list.")
    for mount in mounts:
        if not isinstance(mount, dict):
            return (400, "400 Bad Request: HostConfig.Mounts elements must be objects.")
        m_type = mount.get("Type")
        if m_type == "bind":
            source = mount.get("Source")
            if not source or not isinstance(source, str) or not is_path_allowed(source):
                return (403, f"403 Forbidden: Unauthorized host mount Source '{source}'. Mounts outside approved workspaces are blocked.")
        elif m_type == "volume":
            vol_opts = mount.get("VolumeOptions") or {}
            driver_config = vol_opts.get("DriverConfig") or {}
            driver_opts = driver_config.get("Options") or {}
            device = driver_opts.get("device")
            opt_str = str(driver_opts.get("o") or "")
            if device:
                if not is_path_allowed(device):
                    return (403, f"403 Forbidden: Unauthorized volume driver host path '{device}'.")
            elif "bind" in opt_str or "rbind" in opt_str:
                return (403, "403 Forbidden: Volume driver bind option specified without approved host device.")
        elif m_type == "tmpfs":
            pass
        elif m_type == "npipe":
            return (403, "403 Forbidden: Named pipe mounts (npipe) are prohibited on Linux.")
        else:
            return (403, f"403 Forbidden: Unsupported mount type '{m_type}'.")

    return None

def validate_volume_create_payload(body_bytes):
    if not body_bytes:
        return None

    try:
        body_str = body_bytes.decode('utf-8')
    except UnicodeDecodeError as ude:
        return (400, f"400 Bad Request: Non-UTF-8 volume creation payload ({ude}).")

    try:
        data = json.loads(body_str)
    except Exception as je:
        return (400, f"400 Bad Request: Malformed JSON volume payload ({je}).")

    if not isinstance(data, dict):
        return (400, "400 Bad Request: Volume configuration must be a JSON object.")

    driver_opts = data.get("DriverOpts") or data.get("driver_opts") or {}
    if isinstance(driver_opts, dict):
        device = driver_opts.get("device")
        opt_str = str(driver_opts.get("o") or "")
        if device:
            if not is_path_allowed(device):
                return (403, f"403 Forbidden: Unauthorized volume driver host path '{device}'.")
        elif "bind" in opt_str or "rbind" in opt_str:
            return (403, "403 Forbidden: Volume driver bind option requires an authorized host device path.")

    return None

async def send_error_response(client_writer, status_code, message):
    reason_phrase = "Bad Request" if status_code == 400 else "Forbidden"
    err_body = json.dumps({"message": message}).encode('utf-8')
    resp = (
        f"HTTP/1.1 {status_code} {reason_phrase}\r\n".encode('ascii')
        + b"Content-Type: application/json\r\n"
        + f"Content-Length: {len(err_body)}\r\n".encode('ascii')
        + b"Connection: close\r\n\r\n"
        + err_body
    )
    client_writer.write(resp)
    await client_writer.drain()
    client_writer.close()
    await client_writer.wait_closed()

async def pipe(reader, writer):
    try:
        while not reader.at_eof():
            chunk = await reader.read(65536)
            if not chunk:
                break
            writer.write(chunk)
            await writer.drain()
    except Exception:
        pass
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass

async def handle_client(client_reader, client_writer):
    target_reader = None
    target_writer = None
    try:
        # Read the HTTP request line and headers
        header_bytes = bytearray()
        while True:
            line = await client_reader.readline()
            if not line:
                break
            header_bytes.extend(line)
            if line == b"\r\n" or line == b"\n":
                break

        if not header_bytes:
            client_writer.close()
            return

        header_text = header_bytes.decode('latin1', errors='replace')
        first_line = header_text.splitlines()[0] if header_text else ""
        parts = first_line.split()
        method = parts[0] if len(parts) > 0 else ""
        path = parts[1] if len(parts) > 1 else ""

        # Check Content-Length and Transfer-Encoding for reading request body
        content_length = 0
        is_chunked = False
        is_upgrade = False
        new_header_lines = []
        for idx, hline in enumerate(header_text.splitlines()):
            clean_line = hline.strip()
            if not clean_line:
                continue
            if idx == 0:
                new_header_lines.append(clean_line)
                continue
            lower_line = clean_line.lower()
            if lower_line.startswith("upgrade:") or "upgrade" in lower_line:
                is_upgrade = True
            if lower_line.startswith("connection:"):
                if "upgrade" in lower_line:
                    is_upgrade = True
                continue
            if lower_line.startswith("content-length:"):
                try:
                    content_length = int(lower_line.split(":", 1)[1].strip())
                except ValueError:
                    content_length = 0
                new_header_lines.append(clean_line)
            elif lower_line.startswith("transfer-encoding:") and "chunked" in lower_line:
                is_chunked = True
            else:
                new_header_lines.append(clean_line)

        if is_upgrade:
            new_header_lines.append("Connection: Upgrade")
        else:
            new_header_lines.append("Connection: close")

        body_bytes = b""
        if is_chunked:
            while True:
                chunk_size_line = await client_reader.readline()
                if not chunk_size_line:
                    break
                chunk_str = chunk_size_line.decode('latin1', errors='replace').strip()
                if not chunk_str:
                    continue
                try:
                    chunk_size = int(chunk_str.split(';')[0], 16)
                except ValueError:
                    break
                if chunk_size == 0:
                    await client_reader.readline() # trailing CRLF
                    break
                chunk_data = await client_reader.readexactly(chunk_size)
                body_bytes += chunk_data
                await client_reader.readline() # CRLF after chunk data
        elif content_length > 0:
            body_bytes = await client_reader.readexactly(content_length)

        # Inspect if POST /containers/create
        if method == "POST" and ("/containers/create" in path):
            denial = validate_container_create_payload(body_bytes)
            if denial:
                status_code, denial_reason = denial
                await send_error_response(client_writer, status_code, denial_reason)
                return

        # Inspect if POST /volumes/create
        if method == "POST" and ("/volumes/create" in path):
            denial = validate_volume_create_payload(body_bytes)
            if denial:
                status_code, denial_reason = denial
                await send_error_response(client_writer, status_code, denial_reason)
                return

        # Forward request to upstream target Docker daemon
        target_reader, target_writer = await asyncio.open_unix_connection(TARGET_SOCK)

        # If it was chunked and we de-chunked it, reconstruct headers with Content-Length
        if is_chunked:
            new_header_lines.append(f"Content-Length: {len(body_bytes)}")
        header_to_send = ("\r\n".join(new_header_lines) + "\r\n\r\n").encode('latin1')

        target_writer.write(header_to_send)
        if body_bytes:
            target_writer.write(body_bytes)
        await target_writer.drain()

        # Connect duplex pipes between client and docker daemon
        await asyncio.gather(
            pipe(client_reader, target_writer),
            pipe(target_reader, client_writer),
            return_exceptions=True
        )

    except Exception:
        try:
            client_writer.close()
        except Exception:
            pass
    finally:
        if target_writer:
            try:
                target_writer.close()
            except Exception:
                pass

async def main():
    os.makedirs(LISTEN_DIR, exist_ok=True)
    try:
        os.chmod(LISTEN_DIR, 0o750)
    except OSError:
        pass

    if os.path.exists(LISTEN_SOCK):
        try:
            os.remove(LISTEN_SOCK)
        except OSError:
            pass

    server = await asyncio.start_unix_server(handle_client, path=LISTEN_SOCK)
    try:
        os.chmod(LISTEN_SOCK, SOCKET_MODE)
    except OSError:
        pass
    print(f"Docker Payload Filter Proxy listening on {LISTEN_SOCK} -> {TARGET_SOCK} (mode {oct(SOCKET_MODE)})", flush=True)

    async with server:
        await server.serve_forever()

def daemonize():
    if os.fork() > 0:
        os._exit(0)
    os.setsid()
    if os.fork() > 0:
        os._exit(0)
    # Redirect standard file descriptors
    sys.stdout.flush()
    sys.stderr.flush()
    devnull = open('/dev/null', 'r')
    os.dup2(devnull.fileno(), sys.stdin.fileno())
    log_fd = open('/var/log/docker-filter-proxy.log', 'a+')
    os.dup2(log_fd.fileno(), sys.stdout.fileno())
    os.dup2(log_fd.fileno(), sys.stderr.fileno())

if __name__ == "__main__":
    if "--daemon" in sys.argv:
        daemonize()
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
