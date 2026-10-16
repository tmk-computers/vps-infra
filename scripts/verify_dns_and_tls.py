#!/usr/bin/env python3
# ==============================================================================
# 🌐 OMR SaaS Production DNS & Trusted TLS Verification Script
# Validates actual domain resolution and TLS certificate chains for:
#   1. qa-omr-api.kakshaplus.com
#   2. qa-omr.kakshaplus.com
#   3. omr-api.kakshaplus.com
#   4. omr.kakshaplus.com
# ==============================================================================
import socket
import ssl
import json
import datetime
import sys
import os

DOMAINS = [
    "qa-omr-api.kakshaplus.com",
    "qa-omr.kakshaplus.com",
    "omr-api.kakshaplus.com",
    "omr.kakshaplus.com"
]

EVIDENCE_FILE = "/var/www/vps-infra/docs/audits/dns-tls-evidence.json"

def verify_domain(domain):
    result = {
        "domain": domain,
        "dnsResolved": False,
        "resolvedIps": [],
        "tlsHandshake": False,
        "trustedCert": False,
        "issuer": None,
        "subject": None,
        "san": [],
        "validFrom": None,
        "validTo": None,
        "daysRemaining": 0,
        "error": None
    }

    # 1. DNS Resolution
    try:
        addr_info = socket.getaddrinfo(domain, 443, socket.AF_INET, socket.SOCK_STREAM)
        ips = list(set([item[4][0] for item in addr_info]))
        result["dnsResolved"] = True
        result["resolvedIps"] = ips
    except Exception as e:
        result["error"] = f"DNS resolution failed: {str(e)}"
        return result

    # 2. TLS Connection & Certificate Inspection
    context = ssl.create_default_context()
    # Also support Let's Encrypt cert verification
    try:
        with socket.create_connection((domain, 443), timeout=10) as sock:
            with context.wrap_socket(sock, server_hostname=domain) as ssock:
                result["tlsHandshake"] = True
                cert = ssock.getpeercert()
                result["trustedCert"] = True

                # Extract details
                issuer_dict = dict(x[0] for x in cert.get("issuer", []))
                subject_dict = dict(x[0] for x in cert.get("subject", []))
                result["issuer"] = issuer_dict.get("organizationName") or issuer_dict.get("commonName")
                result["subject"] = subject_dict.get("commonName")

                san_list = [entry[1] for entry in cert.get("subjectAltName", []) if entry[0] == "DNS"]
                result["san"] = san_list

                not_before = datetime.datetime.strptime(cert["notBefore"], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=datetime.timezone.utc)
                not_after = datetime.datetime.strptime(cert["notAfter"], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=datetime.timezone.utc)
                now = datetime.datetime.now(datetime.timezone.utc)

                result["validFrom"] = not_before.isoformat()
                result["validTo"] = not_after.isoformat()
                result["daysRemaining"] = (not_after - now).days

    except ssl.SSLCertVerificationError as ssl_err:
        result["tlsHandshake"] = True
        result["trustedCert"] = False
        result["error"] = f"SSL Verification Error: {ssl_err.verify_message}"
    except Exception as conn_err:
        # Check if local Traefik acme.json has it
        result["error"] = f"TLS Connection Error: {str(conn_err)}"

    return result

def main():
    print("=" * 80)
    print(" 🌐 OMR SAAS PRODUCTION DNS & TRUSTED TLS VERIFICATION")
    print(f" Timestamp: {datetime.datetime.now(datetime.timezone.utc).isoformat()}")
    print("=" * 80)

    results = []
    for d in DOMAINS:
        print(f"▶ Auditing domain '{d}'...")
        res = verify_domain(d)
        results.append(res)
        status_symbol = "✓" if (res["dnsResolved"] and res["trustedCert"]) else "⚠️" if res["dnsResolved"] else "❌"
        print(f"  {status_symbol} DNS: {res['resolvedIps'] or 'Failed'} | TLS Trusted: {res['trustedCert']} | Issuer: {res['issuer']} | Days Left: {res['daysRemaining']}")
        if res["error"]:
            print(f"    Notice: {res['error']}")

    print("\n" + "=" * 80)
    print(" 📊 DNS & TLS AUDIT SUMMARY")
    print("=" * 80)
    print(f" {'Domain':<30} | {'IP Address':<16} | {'TLS Valid':<10} | {'Issuer':<15} | {'Expiry':<10}")
    print("-" * 80)
    for r in results:
        ips_str = r['resolvedIps'][0] if r['resolvedIps'] else 'NONE'
        tls_str = 'PASS' if r['trustedCert'] else ('UNTRUSTED' if r['tlsHandshake'] else 'FAIL')
        issuer_str = (r['issuer'] or 'N/A')[:15]
        days_str = f"{r['daysRemaining']}d" if r['trustedCert'] else 'N/A'
        print(f" {r['domain']:<30} | {ips_str:<16} | {tls_str:<10} | {issuer_str:<15} | {days_str:<10}")
    print("=" * 80)

    # Save evidence file
    os.makedirs(os.path.dirname(EVIDENCE_FILE), exist_ok=True)
    with open(EVIDENCE_FILE, "w") as f:
        json.dump({
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "domains": results
        }, f, indent=2)
    print(f"\n✓ Saved audit evidence to {EVIDENCE_FILE}")

if __name__ == "__main__":
    main()
