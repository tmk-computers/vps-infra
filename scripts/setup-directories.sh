#!/bin/bash
# Filesystem diagnostics only: never log .env contents or setup arguments.

report_directory_failure() {
    local target="$1" status="$2" error="$3" ancestor existing_path
    local red='' yellow='' cyan='' reset=''
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then
        red=$'\033[1;31m'; yellow=$'\033[1;33m'; cyan=$'\033[1;36m'; reset=$'\033[0m'
    fi
    ancestor="$target"
    while [[ ! -e "$ancestor" && ! -L "$ancestor" && "$ancestor" != / ]]; do
        ancestor="$(dirname -- "$ancestor")"
    done
    existing_path="$ancestor"
    printf '\n%s✗ Cannot create: %s%s\n' "$red" "$target" "$reset"
    if [[ -d "$ancestor" && ( ! -w "$ancestor" || ! -x "$ancestor" ) ]]; then
        printf '%sReason: %s lacks write/search access to %s%s\n' "$yellow" "$(id -un)" "$ancestor" "$reset"
        # Only suggest ownership changes for setup-owned scaffolding roots,
        # never for database data directories or arbitrary system ancestors.
        if [[ -n "${SCRIPT_DIR:-}" && ! -L "$ancestor" &&
              ( "$ancestor" == "$SCRIPT_DIR/volumes" || "$ancestor" == "$SCRIPT_DIR" ) ]]; then
            printf '%sFix (this directory only), then rerun setup:%s\n  ' "$cyan" "$reset"
            printf 'sudo chown -- %q %q && sudo chmod u+wx -- %q\n' "$(id -u):$(id -g)" "$ancestor" "$ancestor"
        else
            printf '%sAction: ask the host administrator to grant your user write/search access to this parent, then rerun setup.%s\n' "$cyan" "$reset"
        fi
    elif [[ ! -d "$ancestor" ]]; then
        printf '%sReason: %s is not a directory or cannot be traversed.%s\n' "$yellow" "$ancestor" "$reset"
        printf 'Action: resolve this path conflict, then rerun setup.\n'
    else
        printf 'Action: check filesystem space, mount restrictions, and ACL/security policy for %s.\n' "$ancestor"
    fi
    printf 'System error (exit %s): %s\n' "$status" "$error"
    printf 'For detailed diagnostics, rerun with SETUP_DEBUG=1.\n\n'
    [[ "${SETUP_DEBUG:-0}" == 1 ]] || return 0

    printf '%s--- Filesystem diagnostics ---%s\n' "$cyan" "$reset"
    printf 'Time (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'Running as: '
    id || true
    printf 'Working directory: %s\n' "$PWD"
    ls -ldn -- "$ancestor" || true
    if command -v namei >/dev/null 2>&1; then
        printf '  Permissions and ownership along the target path:\n'
        namei -l -- "$target" || true
    else
        printf '  Ancestor permissions and numeric ownership:\n'
        while [[ "$ancestor" != / ]]; do
            ancestor="$(dirname -- "$ancestor")"
            ls -ldn -- "$ancestor" || true
        done
    fi
    if command -v findmnt >/dev/null 2>&1; then
        printf '  Filesystem mount details:\n'
        findmnt -T "$existing_path" -o TARGET,SOURCE,FSTYPE,OPTIONS || true
    fi

}

create_setup_directories() {
    local target output status
    for target in "$@"; do
        if output=$(mkdir -p -- "$target" 2>&1); then
            [[ "${SETUP_DEBUG:-0}" != 1 ]] || printf '  OK: %s\n' "$target"
        else
            status=$?
            report_directory_failure "$target" "$status" "$output" >&2
            return "$status"
        fi
    done
    return 0
}
