# 🪟 Deploying Windows IIS Native Applications

This guide explains how to deploy and manage native Windows IIS applications in **VPS-Infra** with automated Let's Encrypt SSL via Traefik.

---

## 1. Overview

VPS-Infra supports native Windows Server IIS applications with the same level of automation as Docker containers:
- **Zero-Lock Atomic Deployments**: Uses `app_offline.htm` to drain requests, replace binaries, and recycle the Application Pool.
- **Automated SSL & Ingress**: Traefik terminates Let's Encrypt HTTPS on port 443 and routes to your IIS site on a local loopback port (`127.0.0.1:8081`).
- **Telemetry & Process Metrics**: Live CPU % and Memory monitoring for `w3wp.exe`.
- **Live Logs**: View console stdout and application rolling logs directly in DevOps Manager.

---

## 2. Prerequisites

1. **IIS Installed**: Ensure IIS and ASP.NET Core Hosting Bundle (or .NET Framework) are installed on Windows Server.
2. **TMK IIS Host Agent Running**:
   The host agent enables DevOps Manager to manage IIS securely.
   ```powershell
   # Start agent manually:
   cd C:\var\www\vps-infra\scripts
   .\tmk-iis-agent.ps1 -Port 5055

   # Or install as Windows Service:
   New-Service -Name "TMKIisAgent" `
       -BinaryPathName "powershell.exe -ExecutionPolicy Bypass -NoProfile -File C:\var\www\vps-infra\scripts\tmk-iis-agent.ps1" `
       -DisplayName "TMK DevOps Platform - IIS Host Agent" `
       -StartupType Automatic

   Start-Service TMKIisAgent
   ```
3. **Loopback Port Binding**:
   In IIS Manager, configure your site binding to listen on loopback (e.g., `127.0.0.1:8081`). Do not bind public port 80/443 directly in IIS—Traefik owns the public edge.

---

## 3. Registering the Service in DevOps Manager

1. Open DevOps Manager (`https://devops.yourdomain.com`).
2. Go to **Project Services** -> **Add Service**.
3. Under **Hosting Runtime Environment**, choose **🪟 IIS Native App (Host)**.
4. Fill in the fields:
   - **Service Name**: e.g., `crm-api-prod`
   - **URL**: `https://crm.yourdomain.com`
   - **IIS Site Name**: `Default Web Site` (or your site name)
   - **IIS AppPool Name**: `CrmAppPool`
   - **Physical Path**: `C:\inetpub\wwwroot\crm-api`
   - **Internal Loopback Port**: `8081`
   - **Health Check Path**: `/health` or `/`
5. Click **Save Service**.

DevOps Manager automatically writes a Traefik dynamic ingress file in `network/traefik/dynamic/iis-{id}.yml`. Traefik immediately requests a Let's Encrypt certificate and routes `https://crm.yourdomain.com` to your IIS app.

---

## 4. Deploying Updates

1. Package your published app into a `.zip` file (or use CI Server):
   ```powershell
   dotnet publish -c Release -o ./publish
   Compress-Archive -Path ./publish/* -DestinationPath C:\var\www\vps-infra\volumes\artifacts\crm-api-prod\prod.zip
   ```
2. In DevOps Manager, go to **Deploy**.
3. Select `🪟 [IIS] CRM System - crm-api-prod [Prod]`.
4. Click **Deploy**.
5. The live console displays:
   - Directory snapshot backup
   - Connection draining via `app_offline.htm`
   - Unzipping new binaries
   - AppPool recycling
   - Warm-up health probe confirmation!
