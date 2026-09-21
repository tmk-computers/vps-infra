#!/bin/bash
# Filesystem diagnostics only: never log .env contents or setup arguments.

report_directory_failure() {
    local target="$1" status="$2" error="$3" ancestor existing_path
    printf '\nERROR: Persistent directory creation failed.\n'
    printf '  Time (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf '  Target: %s\n' "$target"
    printf '  Command: mkdir -p -- %q\n' "$target"
    printf '  Exit code: %s\n  Original error:\n%s\n' "$status" "$error"
    printf '  Running as: '
    id || true
    printf '  Working directory: %s\n' "$PWD"

    ancestor="$target"
    while [[ ! -e "$ancestor" && ! -L "$ancestor" && "$ancestor" != / ]]; do
        ancestor="$(dirname -- "$ancestor")"
    done
    printf '  Closest existing path: %s\n' "$ancestor"
    existing_path="$ancestor"
    ls -ldn -- "$ancestor" || true
    if [[ ! -d "$ancestor" ]]; then
        printf '  Diagnosis: the existing path is not a directory (or cannot be traversed).\n'
    elif [[ ! -x "$ancestor" ]]; then
        printf '  Diagnosis: the current user cannot traverse this directory; search (execute) permission is required.\n'
    elif [[ ! -w "$ancestor" ]]; then
        printf '  Diagnosis: the current user cannot write to this directory; creating children requires write and search permissions.\n'
    else
        printf '  Diagnosis: basic access checks passed; consult the original error and filesystem details below.\n'
    fi

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
    printf '%s\n' \
        '  Next step: have the host administrator check the reported parent ownership and permissions.' \
        '  If those permit access, inspect filesystem ACLs, read-only mounts, and security policy denials.' \
        '  Grant the setup user access only to the required paths, then rerun setup.' \
        '  Docker group membership and earlier sudo commands do not grant filesystem write access.' \
        '  Do not recursively change ownership of existing database/container data.'
}

create_setup_directories() {
    local target output status first_failure=0
    for target in "$@"; do
        printf '  Creating directory: %s\n' "$target"
        if output=$(mkdir -p -- "$target" 2>&1); then
            printf '  OK: %s\n' "$target"
        else
            status=$?
            if [[ "$first_failure" -eq 0 ]]; then
                first_failure="$status"
            fi
            report_directory_failure "$target" "$status" "$output" >&2
        fi
    done
    if [[ "$first_failure" -ne 0 ]]; then
        printf '\nERROR: Directory scaffolding failed; setup cannot continue.\n' >&2
    fi
    return "$first_failure"
}
