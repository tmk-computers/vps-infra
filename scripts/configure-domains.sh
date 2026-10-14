#!/bin/bash
# Sourced by setup.sh after loading .env.
valid_domain() {
    local domain="$1" label
    [[ ${#domain} -le 253 && "$domain" == *.* && "$domain" != *yourdomain.com* && "$domain" != example.com && "$domain" != *.example.com ]] || return 1
    [[ "$domain" != *[!a-zA-Z0-9.-]* ]] || return 1
    local -a labels
    IFS=. read -r -a labels <<< "$domain"
    [[ "$domain" != *. ]] || return 1
    for label in "${labels[@]}"; do
        [[ ${#label} -ge 1 && ${#label} -le 63 && "$label" != -* && "$label" != *- ]] || return 1
    done
}

save_domain_value() {
    local key="$1" value="$2" temporary
    temporary=$(mktemp "${SCRIPT_DIR}/.env.domains.XXXXXX") || return 1
    awk -v key="$key" -v value="$value" '
        $0 ~ "^[[:space:]]*" key "=" { if (!found++) print key "=" value; next }
        { print }
        END { if (!found) print key "=" value }
    ' "$SCRIPT_DIR/.env" > "$temporary"
    cat "$temporary" > "$SCRIPT_DIR/.env"
    rm -f "$temporary"
    export "$key=$value"
}

is_ip_address() {
    local ip="$1"
    local -a octets
    IFS=. read -r -a octets <<< "$ip"
    [[ ${#octets[@]} -eq 4 ]] || return 1
    local octet
    for octet in "${octets[@]}"; do
        [[ "$octet" =~ ^[0-9]+$ ]] || return 1
        [[ "$octet" -ge 0 && "$octet" -le 255 ]] || return 1
    done
    return 0
}

configure_domains() {
    local domain="${TMK_ARG_DOMAIN:-${PRIMARY_DOMAIN:-}}" key prefix value

    if is_ip_address "$domain"; then
        echo "Detected IP address for PRIMARY_DOMAIN: $domain"
        mkdir -p "$SCRIPT_DIR/volumes/env-backups" || return 1
        cp -p "$SCRIPT_DIR/.env" "$SCRIPT_DIR/volumes/env-backups/.env.backup.$(date +%Y%m%d%H%M%S).$$" || return 1
        save_domain_value PRIMARY_DOMAIN "$domain"
        save_domain_value NETWORK_MODE "private"
        save_domain_value PRIVATE_IP "$domain"
        save_domain_value ENABLE_HTTPS_REDIRECT "false"
        save_domain_value DEVOPS_WEB_HOST "$domain"
        save_domain_value DEVOPS_API_HOST "$domain"
        save_domain_value CI_WEB_HOST "$domain"
        save_domain_value CI_API_HOST "$domain"
        save_domain_value REGISTRY_HOST "$domain"
        save_domain_value PGADMIN_HOST "$domain"
        save_domain_value PHPMYADMIN_HOST "$domain"
        save_domain_value TRAEFIK_DASHBOARD_HOST "$domain"
        save_domain_value MONGO_EXPRESS_HOST "$domain"
        echo "IP address configuration saved. Direct access enabled at http://$domain"
        return 0
    fi

    if ! valid_domain "$domain"; then
        if [[ -n "${TMK_ARG_DOMAIN:-}" || ! -t 0 ]]; then
            echo "A real primary domain is required. Run ./setup.sh --domain company.com (use your own domain)." >&2
            return 1
        fi
        read -r -p "Primary domain (for example, company.com): " domain
        if is_ip_address "$domain"; then
            TMK_ARG_DOMAIN="$domain" configure_domains
            return $?
        fi
        valid_domain "$domain" || { echo "Invalid primary domain: $domain" >&2; return 1; }
    fi

    # Validate every explicit override before writing any configuration.
    for key in DEVOPS_WEB_HOST DEVOPS_API_HOST CI_WEB_HOST CI_API_HOST REGISTRY_HOST PGADMIN_HOST PHPMYADMIN_HOST TRAEFIK_DASHBOARD_HOST MONGO_EXPRESS_HOST; do
        value="${!key}"
        case "$value" in
            ''|yourdomain.com|*.yourdomain.com|example.com|*.example.com) ;;
            *) is_ip_address "$value" || valid_domain "$value" || { echo "Invalid hostname in $key: $value" >&2; return 1; } ;;
        esac
    done

    mkdir -p "$SCRIPT_DIR/volumes/env-backups" || return 1
    cp -p "$SCRIPT_DIR/.env" "$SCRIPT_DIR/volumes/env-backups/.env.backup.$(date +%Y%m%d%H%M%S).$$" || return 1
    save_domain_value PRIMARY_DOMAIN "$domain"
    while read -r key prefix; do
        value="${!key}"
        case "$value" in
            ''|yourdomain.com|*.yourdomain.com|example.com|*.example.com)
                save_domain_value "$key" "$prefix.$domain" ;;
        esac
    done <<'HOSTS'
DEVOPS_WEB_HOST devops
DEVOPS_API_HOST devops-api
CI_WEB_HOST ci
CI_API_HOST ci-api
REGISTRY_HOST registry
PGADMIN_HOST pgadmin
PHPMYADMIN_HOST phpmyadmin
TRAEFIK_DASHBOARD_HOST traefik
MONGO_EXPRESS_HOST mongo
HOSTS
    case "${ACME_SSL_EMAIL:-}" in
        ''|*@yourdomain.com|*@example.com) save_domain_value ACME_SSL_EMAIL "admin@$domain" ;;
    esac
    case "${SUPERADMIN_EMAIL:-}" in
        ''|*@yourdomain.com|*@example.com) save_domain_value SUPERADMIN_EMAIL "admin@$domain" ;;
    esac
    echo "Domain configuration saved. Ensure these hostnames resolve to this VPS before certificate issuance:"
    for key in DEVOPS_WEB_HOST DEVOPS_API_HOST CI_WEB_HOST CI_API_HOST REGISTRY_HOST PGADMIN_HOST TRAEFIK_DASHBOARD_HOST; do
        echo "  $key=${!key}"
    done

}
