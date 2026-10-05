#!/usr/bin/env python3
"""
Isolated Automated Test Harness for Docker Socket Filtering Proxy (Phase 1)
Tests proxy behavior strictly using temporary Unix sockets and a mock Docker API server.
Zero network or socket interaction with production Docker daemon (/var/run/docker.sock)
or production filter proxy (/var/run/docker-filtered/docker.sock).
"""

import asyncio
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time

class MockDockerServer:
    """Mock Docker daemon that handles standard API calls and logs forwarded requests."""
    def __init__(self, socket_path):
        self.socket_path = socket_path
        self.server = None
        self.received_requests = []

    async def handle_client(self, reader, writer):
        try:
            # Read request line and headers
            header_bytes = bytearray()
            while True:
                line = await reader.readline()
                if not line or line in (b"\r\n", b"\n"):
                    break
                header_bytes.extend(line)

            header_text = header_bytes.decode('latin1', errors='replace')
            first_line = header_text.splitlines()[0] if header_text else ""
            parts = first_line.split()
            method = parts[0] if len(parts) > 0 else "GET"
            path = parts[1] if len(parts) > 1 else "/"

            # Read content-length body if any
            content_length = 0
            for hline in header_text.splitlines():
                if hline.lower().startswith("content-length:"):
                    try:
                        content_length = int(hline.split(":", 1)[1].strip())
                    except ValueError:
                        content_length = 0

            body_bytes = b""
            if content_length > 0:
                body_bytes = await reader.readexactly(content_length)

            self.received_requests.append({
                "method": method,
                "path": path,
                "body": body_bytes
            })

            # Mock responses
            if "/_ping" in path:
                resp_body = b"OK"
                status_line = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
            elif "/version" in path:
                resp_data = {"Version": "28.5.1", "ApiVersion": "1.45"}
                resp_body = json.dumps(resp_data).encode('utf-8')
                status_line = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
            elif "/containers/create" in path:
                resp_data = {"Id": "mock-container-id-12345", "Warnings": []}
                resp_body = json.dumps(resp_data).encode('utf-8')
                status_line = "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\n"
            elif "/volumes/create" in path:
                resp_data = {"Name": "mock-vol-12345", "Driver": "local"}
                resp_body = json.dumps(resp_data).encode('utf-8')
                status_line = "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\n"
            else:
                resp_body = b'{"status":"ok"}'
                status_line = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"

            resp = (
                status_line.encode('ascii')
                + f"Content-Length: {len(resp_body)}\r\n".encode('ascii')
                + b"Connection: close\r\n\r\n"
                + resp_body
            )
            writer.write(resp)
            await writer.drain()
        except Exception as e:
            pass
        finally:
            try:
                writer.close()
                await writer.wait_closed()
            except Exception:
                pass

    async def start(self):
        if os.path.exists(self.socket_path):
            os.remove(self.socket_path)
        self.server = await asyncio.start_unix_server(self.handle_client, path=self.socket_path)
        os.chmod(self.socket_path, 0o600)

    async def stop(self):
        if self.server:
            self.server.close()
            await self.server.wait_closed()
        if os.path.exists(self.socket_path):
            try:
                os.remove(self.socket_path)
            except OSError:
                pass

async def send_raw_http_request(socket_path, method, path, body=b"", content_type="application/json", raw_bytes=None):
    """Send an HTTP request over a Unix domain socket and parse status code and body."""
    reader, writer = await asyncio.open_unix_connection(socket_path)
    try:
        if raw_bytes is not None:
            writer.write(raw_bytes)
        else:
            if isinstance(body, str):
                body = body.encode('utf-8')
            req = (
                f"{method} {path} HTTP/1.1\r\n"
                f"Host: localhost\r\n"
                f"Content-Type: {content_type}\r\n"
                f"Content-Length: {len(body)}\r\n"
                f"Connection: close\r\n\r\n"
            ).encode('ascii') + body
            writer.write(req)
        await writer.drain()

        # Read response
        resp_bytes = await reader.read(65536)
        if not resp_bytes:
            return 0, b"", {}

        # Parse status code
        header_part = resp_bytes.split(b"\r\n\r\n")[0]
        body_part = resp_bytes[len(header_part) + 4:] if b"\r\n\r\n" in resp_bytes else b""
        status_line = header_part.splitlines()[0].decode('latin1', errors='replace')
        status_code = int(status_line.split()[1]) if len(status_line.split()) > 1 else 0

        # Try to parse JSON body
        json_data = {}
        try:
            json_data = json.loads(body_part.decode('utf-8'))
        except Exception:
            pass

        return status_code, body_part, json_data
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass

async def run_test_suite():
    print("=" * 80)
    print("STARTING ISOLATED DOCKER FILTER PROXY TEST SUITE (PHASE 1)")
    print("=" * 80)

    test_dir = tempfile.mkdtemp(prefix="proxy_test_harness_")
    mock_sock = os.path.join(test_dir, "mock_docker.sock")
    filter_sock = os.path.join(test_dir, "test_filter.sock")
    script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "docker-filter-proxy.py"))

    print(f"📁 Isolated Test Workspace : {test_dir}")
    print(f"🔌 Mock Docker Target Sock : {mock_sock}")
    print(f"🔌 Filter Proxy Listen Sock: {filter_sock}")
    print(f"📜 Proxy Script Under Test : {script_path}")
    print("-" * 80)

    mock_server = MockDockerServer(mock_sock)
    await mock_server.start()

    # Launch proxy in subprocess pointing to mock sockets with non-0666 permissions (0600)
    env = os.environ.copy()
    env["FILTER_PROXY_TARGET_SOCK"] = mock_sock
    env["FILTER_PROXY_LISTEN_SOCK"] = filter_sock
    env["FILTER_PROXY_SOCKET_MODE"] = "0600"
    proxy_proc = subprocess.Popen(
        [sys.executable, script_path],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # Wait for proxy socket to become available
    socket_ready = False
    for _ in range(50):
        if os.path.exists(filter_sock):
            socket_ready = True
            break
        await asyncio.sleep(0.1)

    if not socket_ready:
        print("❌ Error: Filter proxy socket failed to initialize.")
        mock_server.server.close()
        proxy_proc.kill()
        shutil.rmtree(test_dir, ignore_errors=True)
        return False

    passed = 0
    failed = 0
    test_results = []
    rejection_cases = 0
    forwarded_rejection_requests = 0

    def record_test(name, success, detail=""):
        nonlocal passed, failed, rejection_cases, forwarded_rejection_requests
        expects_rejection = "returns 400 Bad Request" in name or "denied with 403" in name
        if expects_rejection:
            rejection_cases += 1
            forwarded = len(mock_server.received_requests)
            forwarded_rejection_requests += forwarded
            if forwarded:
                success = False
                detail = f"{detail}; rejected request(s) reached mock daemon: {forwarded}"
            # Keep each assertion independent even after a regression is detected.
            mock_server.received_requests.clear()
        if success:
            passed += 1
            print(f"  ✅ PASS: {name}")
        else:
            failed += 1
            print(f"  ❌ FAIL: {name} | {detail}")
        test_results.append((name, success, detail))

    try:
        # Test Case 0: Socket Permissions Verification (Least-Privilege != 0666)
        sock_mode = oct(stat.S_IMODE(os.stat(filter_sock).st_mode))
        record_test("Socket permissions are least-privilege (0600, not 0666)",
                    sock_mode == "0o600", f"Observed mode: {sock_mode}")

        # ======================================================================
        # Group 1: Malformed & Non-UTF-8 Fail-Closed (Explicit 400 Bad Request)
        # ======================================================================
        print("\n--- Group 1: Malformed & Non-UTF-8 Fail-Closed (Explicit 400) ---")

        # 1.1 Non-UTF-8 payload bytes on /containers/create
        req_non_utf8 = (
            b"POST /v1.45/containers/create HTTP/1.1\r\n"
            b"Host: localhost\r\n"
            b"Content-Type: application/json\r\n"
            b"Content-Length: 4\r\n"
            b"Connection: close\r\n\r\n"
            b"\xff\xfe\x00\x01"
        )
        status, _, jdata = await send_raw_http_request(filter_sock, "", "", raw_bytes=req_non_utf8)
        record_test("Non-UTF-8 bytes on POST /containers/create returns 400 Bad Request",
                    status == 400 and "400 Bad Request" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # 1.2 Malformed JSON syntax on /containers/create
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body='{"HostConfig": { "Binds": [ "unclosed'
        )
        record_test("Malformed JSON syntax on POST /containers/create returns 400 Bad Request",
                    status == 400 and "400 Bad Request" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # 1.3 Non-object JSON root on /containers/create
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body='["array", "not", "object"]'
        )
        record_test("Non-object JSON root on POST /containers/create returns 400 Bad Request",
                    status == 400 and "400 Bad Request" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # 1.4 Empty body on /containers/create
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=''
        )
        record_test("Empty body on POST /containers/create returns 400 Bad Request",
                    status == 400 and "400 Bad Request" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # 1.5 Malformed JSON on POST /volumes/create
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/volumes/create",
            body='{"Name": "test_vol", "DriverOpts": { unclosed'
        )
        record_test("Malformed JSON on POST /volumes/create returns 400 Bad Request",
                    status == 400 and "400 Bad Request" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # 1.6 Non-UTF-8 bytes on POST /volumes/create
        req_vol_non_utf8 = (
            b"POST /v1.45/volumes/create HTTP/1.1\r\n"
            b"Host: localhost\r\n"
            b"Content-Type: application/json\r\n"
            b"Content-Length: 4\r\n"
            b"Connection: close\r\n\r\n"
            b"\x80\x81\x82\x83"
        )
        status, _, jdata = await send_raw_http_request(filter_sock, "", "", raw_bytes=req_vol_non_utf8)
        record_test("Non-UTF-8 bytes on POST /volumes/create returns 400 Bad Request",
                    status == 400 and "400 Bad Request" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # ======================================================================
        # Group 2: Broad Mount Rejection & Forbidden Paths (403 Forbidden)
        # ======================================================================
        print("\n--- Group 2: Broad Mount Rejection & Forbidden Paths (403 Forbidden) ---")

        # 2.1 Broad /var/www/vps-infra/volumes (contains db, backups, license)
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes:/volumes:ro"]}})
        )
        record_test("Broad /var/www/vps-infra/volumes mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.2 /var/www/vps-infra/volumes/db (raw database clusters)
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes/db/postgres_data:/data:rw"]}})
        )
        record_test("/var/www/vps-infra/volumes/db mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.3 /var/www/vps-infra/volumes/infra (database backups)
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes/infra/backups:/backups:ro"]}})
        )
        record_test("/var/www/vps-infra/volumes/infra/backups mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.4 /var/www/vps-infra/volumes/license.key
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes/license.key:/app/license.key:ro"]}})
        )
        record_test("/var/www/vps-infra/volumes/license.key mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.5 Broad /tmp mount
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/tmp:/host_tmp:rw"]}})
        )
        record_test("Broad /tmp mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.6 /etc host mount
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/etc:/etc:ro"]}})
        )
        record_test("Host /etc mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.7 /root host mount
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/root:/root:ro"]}})
        )
        record_test("Host /root mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.8 /var/run host mount
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/run:/var/run:rw"]}})
        )
        record_test("Host /var/run mount denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 2.9 Path traversal escape (../../etc)
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/code/../../etc/passwd:/secret:ro"]}})
        )
        record_test("Path traversal escape (../../etc) denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # ======================================================================
        # Group 3: HostConfig.Mounts Types & Volume Driver Options (403 Forbidden)
        # ======================================================================
        print("\n--- Group 3: HostConfig.Mounts Types & Driver Options (403 Forbidden) ---")

        # 3.1 HostConfig.Mounts Type: "bind" pointing to /etc
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Mounts": [{"Type": "bind", "Source": "/etc", "Target": "/app/etc"}]}})
        )
        record_test("HostConfig.Mounts bind to /etc denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 3.2 HostConfig.Mounts Type: "volume" with driver device pointing to /etc
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({
                "HostConfig": {
                    "Mounts": [{
                        "Type": "volume",
                        "Target": "/host_etc",
                        "VolumeOptions": {
                            "DriverConfig": {
                                "Name": "local",
                                "Options": {"type": "none", "device": "/etc", "o": "bind"}
                            }
                        }
                    }]
                }
            })
        )
        record_test("HostConfig.Mounts volume driver device /etc denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 3.3 HostConfig.Mounts Type: "volume" with o=bind but no approved device
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({
                "HostConfig": {
                    "Mounts": [{
                        "Type": "volume",
                        "Target": "/app_vol",
                        "VolumeOptions": {
                            "DriverConfig": {
                                "Name": "local",
                                "Options": {"o": "bind"}
                            }
                        }
                    }]
                }
            })
        )
        record_test("HostConfig.Mounts volume driver o=bind without device denied with 403",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 3.4 HostConfig.Mounts Type: "npipe" (prohibited on Linux)
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({
                "HostConfig": {
                    "Mounts": [{"Type": "npipe", "Source": "\\\\.\\pipe\\docker_engine", "Target": "/pipe"}]
                }
            })
        )
        record_test("HostConfig.Mounts npipe denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # ======================================================================
        # Group 4: VolumesFrom & Host Privileges (403 Forbidden)
        # ======================================================================
        print("\n--- Group 4: VolumesFrom & Host Privileges (403 Forbidden) ---")

        # 4.1 VolumesFrom inheritance
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"VolumesFrom": ["devops-api-prod"]}})
        )
        record_test("HostConfig.VolumesFrom inheritance denied with 403 Forbidden",
                    status == 403 and "VolumesFrom" in jdata.get("message", ""),
                    f"Status: {status}, msg: {jdata.get('message')}")

        # 4.2 Privileged mode
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Privileged": True}})
        )
        record_test("Privileged mode denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 4.3 Host PidMode
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"PidMode": "host"}})
        )
        record_test("Host namespace sharing (PidMode=host) denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 4.4 Dangerous Capability (CAP_SYS_ADMIN)
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"CapAdd": ["SYS_ADMIN"]}})
        )
        record_test("Dangerous capability CAP_SYS_ADMIN denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 4.5 HostConfig.Devices non-empty
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Devices": [{"PathOnHost": "/dev/sda", "PathInContainer": "/dev/sda", "CgroupPermissions": "rwm"}]}})
        )
        record_test("HostConfig.Devices non-empty denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 4.6 HostConfig.DeviceRequests non-empty
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"DeviceRequests": [{"Driver": "cdi", "Count": -1, "DeviceIDs": ["gpu0"]}]}})
        )
        record_test("HostConfig.DeviceRequests non-empty denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 4.7 HostConfig.SecurityOpt unconfined profile
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"SecurityOpt": ["seccomp=unconfined"]}})
        )
        record_test("HostConfig.SecurityOpt unconfined profile denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 4.8 HostConfig.SecurityOpt disable profile
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"SecurityOpt": ["label=disable"]}})
        )
        record_test("HostConfig.SecurityOpt disable profile denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # ======================================================================
        # Group 5: Local Volume Driver Creation POST /volumes/create (403 Forbidden)
        # ======================================================================
        print("\n--- Group 5: Volume Creation Driver Checks (403 Forbidden) ---")

        # 5.1 POST /volumes/create with device="/" and o="bind"
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/volumes/create",
            body=json.dumps({"Name": "root_vol", "Driver": "local", "DriverOpts": {"type": "none", "device": "/", "o": "bind"}})
        )
        record_test("POST /volumes/create with device=/ denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 5.2 POST /volumes/create with device="/etc"
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/volumes/create",
            body=json.dumps({"Name": "etc_vol", "Driver": "local", "DriverOpts": {"type": "none", "device": "/etc", "o": "bind"}})
        )
        record_test("POST /volumes/create with device=/etc denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # 5.3 POST /volumes/create with device pointing to db volumes
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/volumes/create",
            body=json.dumps({"Name": "db_vol", "Driver": "local", "DriverOpts": {"type": "none", "device": "/var/www/vps-infra/volumes/db", "o": "bind"}})
        )
        record_test("POST /volumes/create with device=/volumes/db denied with 403 Forbidden",
                    status == 403, f"Status: {status}, msg: {jdata.get('message')}")

        # ======================================================================
        # Group 6: Legitimate CI / Compose Workflows (Forwarded 200/201 OK)
        # ======================================================================
        print("\n--- Group 6: Legitimate CI & Compose Workflows (Forwarded OK) ---")

        # 6.1 GET /_ping
        mock_server.received_requests.clear()
        status, body, _ = await send_raw_http_request(filter_sock, "GET", "/_ping")
        record_test("GET /_ping forwarded and returns 200 OK",
                    status == 200 and body == b"OK" and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.2 GET /v1.45/version
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(filter_sock, "GET", "/v1.45/version")
        record_test("GET /version forwarded and returns 200 OK",
                    status == 200 and jdata.get("Version") == "28.5.1" and len(mock_server.received_requests) == 1,
                    f"Status: {status}, Version: {jdata.get('Version')}")

        # 6.3 Legitimate code repo mount (/var/www/vps-infra/code/my-app)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/code/my-app:/app:rw"]}})
        )
        record_test("Legitimate code repo mount forwarded and returns 201 Created",
                    status == 201 and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.4 Legitimate artifacts volume mount (/var/www/vps-infra/volumes/artifacts)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes/artifacts/build-123:/artifacts:ro"]}})
        )
        record_test("Legitimate artifacts volume mount forwarded and returns 201 Created",
                    status == 201 and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.5 Legitimate APK volume mount (/var/www/vps-infra/volumes/apk)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes/apk/release:/apk:rw"]}})
        )
        record_test("Legitimate APK volume mount forwarded and returns 201 Created",
                    status == 201 and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.6 Legitimate apps persistent volume mount (/var/www/vps-infra/volumes/apps/omr-api)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/var/www/vps-infra/volumes/apps/omr-api:/data:rw"]}})
        )
        record_test("Legitimate app volume mount forwarded and returns 201 Created",
                    status == 201 and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.7 Legitimate ephemeral pin mount (/tmp/vps-infra-pins)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Binds": ["/tmp/vps-infra-pins/pin-01.yml:/pin.yml:ro"]}})
        )
        record_test("Legitimate ephemeral Compose pin mount forwarded and returns 201 Created",
                    status == 201 and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.8 Legitimate volume create (standard named volume without host driver options)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/volumes/create",
            body=json.dumps({"Name": "standard_named_vol", "Driver": "local"})
        )
        record_test("Legitimate volume create forwarded and returns 201 Created",
                    status == 201 and len(mock_server.received_requests) == 1,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

        # 6.9 Legitimate HostConfig.Mounts tmpfs mount (forwarded, memory-backed, no host filesystem access)
        mock_server.received_requests.clear()
        status, _, jdata = await send_raw_http_request(
            filter_sock, "POST", "/v1.45/containers/create",
            body=json.dumps({"HostConfig": {"Mounts": [{"Type": "tmpfs", "Target": "/app/cache", "TmpfsOptions": {"SizeBytes": 67108864}}]}})
        )
        forwarded_ok = len(mock_server.received_requests) == 1
        has_no_host_source = True
        if forwarded_ok:
            req_body = json.loads(mock_server.received_requests[0]["body"].decode('utf-8'))
            mounts = req_body.get("HostConfig", {}).get("Mounts", [])
            has_no_host_source = bool(mounts) and mounts[0].get("Type") == "tmpfs" and not mounts[0].get("Source")
        record_test("Legitimate HostConfig.Mounts tmpfs mount forwarded and returns 201 Created",
                    status == 201 and forwarded_ok and has_no_host_source,
                    f"Status: {status}, mock requests: {len(mock_server.received_requests)}")

    finally:
        # Cleanup isolated resources
        await mock_server.stop()
        proxy_proc.terminate()
        try:
            proxy_proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proxy_proc.kill()
        shutil.rmtree(test_dir, ignore_errors=True)

    print("\n" + "=" * 80)
    print(f"ISOLATED TEST HARNESS SUMMARY: {passed} PASSED, {failed} FAILED, 0 SKIPPED (Total: {passed + failed})")
    print(f"Rejected-request forwarding: {forwarded_rejection_requests} forwarded across {rejection_cases} rejection cases")
    print("=" * 80)
    return failed == 0

if __name__ == "__main__":
    success = asyncio.run(run_test_suite())
    sys.exit(0 if success else 1)
