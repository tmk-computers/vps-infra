# 🪟 Windows Server Quickstart Installation Guide

This guide walks you through bootstrapping and operating the **VPS-Infra** platform on **Windows Server 2019, 2022, or 2025** (Standard or Datacenter editions).

---

## 💻 Hardware & System Prerequisites

| Specification | Minimum | Recommended Production |
|---|---|---|
| **Operating System** | Windows Server 2019 / 2022 / 2025 (x64) | Windows Server 2022 / 2025 Datacenter |
| **vCPU** | 2 vCPUs | 4+ vCPUs |
| **RAM** | 8 GB | 16 GB – 32 GB |
| **Storage** | 60 GB NVMe / SSD | 150 GB+ NVMe SSD |
| **Docker Engine** | Docker Engine v24.0+ (with Compose v2 CLI plugin) | Docker v26.0+ / Mirantis / Docker Desktop |
| **Scripting Host** | Windows PowerShell 5.1 (Built-in) | PowerShell Core 7+ or PowerShell 5.1 |
| **Firewall Ports** | `80/tcp`, `443/tcp` (or custom `8080/8443`) | `80/tcp`, `443/tcp` |

---

## ⚠️ Windows Port 80/443 & IIS (W3SVC) Considerations

Windows Server hosts frequently have **IIS (Internet Information Services / W3SVC)** pre-installed and bound to Port 80 and 443. Traefik requires HTTP and HTTPS ports to route traffic and issue Let's Encrypt SSL certificates.

You have two supported deployment options:

### Option A: Dedicated Ingress (Recommended for New Servers)
If IIS is not actively serving live websites, disable or stop IIS so Traefik can bind directly to ports 80 and 443:
```powershell
Stop-Service W3SVC -Force
Set-Service W3SVC -StartupType Manual
```
*(The `setup.ps1` installer will automatically check for IIS and ask for confirmation before modifying services).*

### Option B: Coexist with Existing IIS Websites
If your Windows Server already hosts active production sites on IIS that cannot be stopped:
1. Keep IIS running on ports 80 and 443.
2. In `C:\var\www\vps-infra\.env`, configure Traefik to bind to alternative high ports:
   ```ini
   TRAEFIK_HTTP_PORT=8080
   TRAEFIK_HTTPS_PORT=8443
   ```
3. Or pass custom ports directly to the installer:
   ```powershell
   .\setup.ps1 -Domain yourdomain.com -HttpPort 8080 -HttpsPort 8443
   ```

---

## 🌐 1. DNS A-Record Configuration

Before running the installer, point the following **DNS A-Records** to your Windows Server's public IPv4 address with your DNS provider (Cloudflare, Route53, GoDaddy):

| Subdomain | Target Example | Description |
|---|---|---|
| `@` / `yourdomain.com` | `yourdomain.com` | Primary Gateway |
| `devops` | `devops.yourdomain.com` | DevOps Manager Web UI |
| `devops-api` | `devops-api.yourdomain.com` | DevOps Backend API |
| `ci` | `ci.yourdomain.com` | CI/CD Dashboard |
| `ci-api` | `ci-api.yourdomain.com` | CI/CD Pipeline Engine |
| `registry` | `registry.yourdomain.com` | Private Docker Registry |
| `traefik` | `traefik.yourdomain.com` | Traefik Router Dashboard |
| `pgadmin` | `pgadmin.yourdomain.com` | PostgreSQL Database UI *(Optional)* |

> **Cloudflare Tip**: If using Cloudflare DNS, set proxy status to **DNS Only (Grey Cloud)** during initial Let's Encrypt certificate issuance.

---

## 📥 2. Clone the Platform Runtime

Open **PowerShell as Administrator** and clone the repository to `C:\var\www\vps-infra`:

```powershell
# Create root directory if needed
if (-not (Test-Path "C:\var\www")) { New-Item -ItemType Directory -Path "C:\var\www" -Force }

# Clone repository
git clone https://github.com/tmk-computers/vps-infra.git C:\var\www\vps-infra
Set-Location -Path "C:\var\www\vps-infra"
```

---

## ⚙️ 3. Configure Environment Variables (`.env`)

Copy the template configuration file:

```powershell
Copy-Item .env.example .env
notepad .env
```

### Essential Windows Settings to Verify:
```ini
# ------------------------------------------------------------
# Host Path & Cross-Platform Settings
# ------------------------------------------------------------
INFRA_BASE_DIR=C:/var/www/vps-infra
WWW_ROOT=C:/var/www
POSTGRES_DATA_STORAGE=postgres_data

# ------------------------------------------------------------
# Primary Domain & Company Information
# ------------------------------------------------------------
PRIMARY_DOMAIN=yourdomain.com
ACME_SSL_EMAIL=admin@yourdomain.com
COMPANY_NAME="Your Company Name"

# ------------------------------------------------------------
# Initial SuperAdmin Credentials
# ------------------------------------------------------------
SUPERADMIN_EMAIL=admin@yourdomain.com
SUPERADMIN_PASSWORD=YourStrongPassword123!
SUPERADMIN_FULLNAME="Super Admin"

# ------------------------------------------------------------
# Shared Database Master Password
# ------------------------------------------------------------
POSTGRES_PASSWORD=YourSuperSecurePostgresPassword123!
```

---

## 🚀 4. Run 1-Click Bootstrap Installation

Run the native PowerShell bootstrapper `setup.ps1` from an elevated PowerShell window:

```powershell
Set-Location -Path "C:\var\www\vps-infra"
.\setup.ps1 -Domain "yourdomain.com"
```

### With Pre-Issued License Token:
If you already received your enterprise license token from TMK Computers, pass it via `-License`:
```powershell
.\setup.ps1 -Domain "yourdomain.com" -License "YOUR_SIGNED_TMK_LICENSE_KEY"
```

### Unattended / Non-Interactive Deployment:
```powershell
.\setup.ps1 -Domain "yourdomain.com" -License "YOUR_SIGNED_TMK_LICENSE_KEY" -Mode all-in-one -Yes
```

### Parameter Reference for `setup.ps1`:
| Parameter | Default | Description |
|---|---|---|
| `-Domain` | Value in `.env` | Primary domain name (e.g. `company.com`) |
| `-License` | Value in `.env` | TMK signed cryptographic license token |
| `-Mode` | `all-in-one` | Topology: `all-in-one`, `devops-only`, or `ci-only` |
| `-HttpPort` | `80` (or `TRAEFIK_HTTP_PORT`) | Host port for Traefik HTTP traffic |
| `-HttpsPort` | `443` (or `TRAEFIK_HTTPS_PORT`) | Host port for Traefik HTTPS traffic |
| `-Tag` | `latest` | Container image release tag (`latest`, `uat`, etc.) |
| `-Yes`, `-Force` | `$false` | Suppress interactive prompts and auto-approve |
| `-RegistryType`| `private` | Docker registry mode: `private` or `external` |
| `-SyncMode` | `api` | CI synchronization mode: `api` or `db` |
| `-CiSecret` | Auto-generated | Cross-server communication secret key |

---

## 🛠️ 5. Unified CLI Tool (`infra.cmd` / `infra.ps1`)

For everyday operations on Windows, the repository provides a native CLI management wrapper accessible via Command Prompt or PowerShell:

```cmd
:: Check live platform health and container status
infra status

:: View live container logs
infra logs devops-api-prod
infra logs ci-api-prod
infra logs traefik

:: Trigger an immediate PostgreSQL database backup
infra backup

:: Restart all platform services
infra restart

:: Stop all platform services
infra down
```

---

## 💾 6. Windows Data Persistence Architecture

On Windows Server hosts running Docker, container engines may experience filesystem permission locks if Linux database engines write directly to NTFS directory bind mounts. 

To ensure complete resilience on Windows Server:
1. **PostgreSQL Data Directory (`/var/lib/postgresql/data`)**: Managed via a high-performance Docker named volume (`postgres_data`). This avoids NTFS POSIX UID/GID mapping issues.
2. **Database Dumps & Backups (`/backups`)**: Written directly to the host filesystem at `C:\var\www\vps-infra\volumes\db\postgres\backups` for easy offsite archival.
3. **Application Volumes (`/app/uploads`, `/app/logs`)**: Mounted using `INFRA_BASE_DIR` paths (`C:/var/www/vps-infra/volumes/apps/...`), allowing standard backups and Windows Explorer accessibility.

---

## ✅ 7. Verification & Live Dashboard Access

Once `setup.ps1` completes:

1. Verify container status:
   ```cmd
   infra status
   ```
2. Navigate to your endpoints in a web browser:
   * **DevOps Manager UI**: `https://devops.yourdomain.com`
   * **CI/CD Dashboard**: `https://ci.yourdomain.com`
   * **Private Docker Registry**: `https://registry.yourdomain.com`
   * **Traefik Edge Routing**: `https://traefik.yourdomain.com`
3. Sign in using your `SUPERADMIN_EMAIL` and `SUPERADMIN_PASSWORD`.

---

## 📞 Support & Enterprise Operations
For license inquiries, enterprise support, or multi-node distributed configurations:
* **Email**: `support@tmkcomputers.in` / `licensing@tmkcomputers.in`
* **Website**: [https://tmkcomputers.in](https://tmkcomputers.in)
