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

# Prevent terminal interrupts from stopping the proxy
signal.signal(signal.SIGINT, signal.SIG_IGN)
signal.signal(signal.SIGHUP, signal.SIG_IGN)

TARGET_SOCK = "/var/run/docker.sock"
LISTEN_DIR = "/var/run/docker-filtered"
LISTEN_SOCK = os.path.join(LISTEN_DIR, "docker.sock")

# Approved path prefixes for host mounts
ALLOWED_MOUNT_PREFIXES = (
    "/var/www/vps-infra/code",
    "/var/www/vps-infra/apps",
    "/var/www/vps-infra/ci-server",
    "/var/www/vps-infra/volumes",
    "/tmp",
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
        resolved = os.path.realpath(path_str)
    except Exception:
        return False
    
    # Check if exact match with prohibited root/system dirs
    if resolved in DISALLOWED_HOST_PATHS:
        return False
    
    # Check if inside forbidden dirs
    for forbidden in ("/etc", "/var/run", "/root", "/sys", "/proc", "/dev", "/boot"):
        if resolved == forbidden or resolved.startswith(forbidden + "/"):
            return False
            
    # Check if inside allowed trees
    for allowed in ALLOWED_MOUNT_PREFIXES:
        if resolved == allowed or resolved.startswith(allowed + "/"):
            return True
            
    return False

def validate_container_create_payload(body_bytes):
    try:
        data = json.loads(body_bytes.decode('utf-8'))
    except Exception:
        return None

    host_config = data.get("HostConfig") or {}

    # 1. Privileged mode check
    if host_config.get("Privileged") is True:
        return "403 Forbidden: Privileged container mode is strictly prohibited."

    # 2. Host namespace checks
    for ns_field in ("PidMode", "IpcMode", "NetworkMode", "UsernsMode", "UtsMode"):
        val = host_config.get(ns_field)
        if isinstance(val, str) and val.strip().lower() == "host":
            return f"403 Forbidden: Host namespace sharing ({ns_field}=host) is strictly prohibited."

    # 3. Dangerous capabilities check
    cap_add = host_config.get("CapAdd") or []
    for cap in cap_add:
        if str(cap).upper() in DANGEROUS_CAPS:
            return f"403 Forbidden: Dangerous Linux capability ({cap}) is strictly prohibited."

    # 4. Host devices check
    if host_config.get("Devices"):
        return "403 Forbidden: Host device mounting is strictly prohibited."

    # 5. SecurityOpt unconfined check
    security_opt = host_config.get("SecurityOpt") or []
    for opt in security_opt:
        opt_str = str(opt).lower()
        if "unconfined" in opt_str or "disable" in opt_str:
            return f"403 Forbidden: Disabling container security profiles ({opt}) is prohibited."

    # 6. HostConfig.Binds inspection (Representation 1: list of strings)
    binds = host_config.get("Binds") or []
    for bind in binds:
        if not isinstance(bind, str):
            continue
        host_src = bind.split(":")[0]
        if not is_path_allowed(host_src):
            return f"403 Forbidden: Unauthorized host bind mount path '{host_src}'. Mounts outside approved workspaces are blocked."

    # 7. HostConfig.Mounts inspection (Representation 2: list of mount objects)
    mounts = host_config.get("Mounts") or []
    for mount in mounts:
        if not isinstance(mount, dict):
            continue
        if mount.get("Type") == "bind":
            source = mount.get("Source")
            if not is_path_allowed(source):
                return f"403 Forbidden: Unauthorized host mount Source '{source}'. Mounts outside approved workspaces are blocked."

    return None

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
        new_header_lines = []
        for idx, hline in enumerate(header_text.splitlines()):
            clean_line = hline.strip()
            if not clean_line:
                continue
            if idx == 0:
                new_header_lines.append(clean_line)
                continue
            lower_line = clean_line.lower()
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
            denial_reason = validate_container_create_payload(body_bytes)
            if denial_reason:
                err_response = {
                    "message": denial_reason
                }
                err_body = json.dumps(err_response).encode('utf-8')
                resp = (
                    b"HTTP/1.1 403 Forbidden\r\n"
                    b"Content-Type: application/json\r\n"
                    + f"Content-Length: {len(err_body)}\r\n".encode('ascii')
                    + b"Connection: close\r\n\r\n"
                    + err_body
                )
                client_writer.write(resp)
                await client_writer.drain()
                client_writer.close()
                await client_writer.wait_closed()
                return

        # Forward request to upstream target Docker daemon
        target_reader, target_writer = await asyncio.open_unix_connection(TARGET_SOCK)

        # If it was chunked and we de-chunked it, reconstruct headers with Content-Length
        if is_chunked:
            new_header_lines.append(f"Content-Length: {len(body_bytes)}")
            header_to_send = ("\r\n".join(new_header_lines) + "\r\n\r\n").encode('latin1')
        else:
            header_to_send = header_bytes

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
    os.chmod(LISTEN_DIR, 0o755)

    if os.path.exists(LISTEN_SOCK):
        try:
            os.remove(LISTEN_SOCK)
        except OSError:
            pass

    server = await asyncio.start_unix_server(handle_client, path=LISTEN_SOCK)
    os.chmod(LISTEN_SOCK, 0o666)
    print(f"Docker Payload Filter Proxy listening on {LISTEN_SOCK} -> {TARGET_SOCK}", flush=True)

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
