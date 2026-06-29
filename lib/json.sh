#!/usr/bin/env bash
# =============================================================================
# lib/json.sh — JSON output helpers for non-interactive/bot/API mode
# BogelShell Protect v2.1
# =============================================================================

# json_escape: escape a string for safe JSON embedding
json_escape() {
    local str="${1}"
    # Escape backslashes first, then double quotes, then control chars
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    printf '%s' "${str}"
}

# json_ok: output a success JSON object and exit 0
# Usage: json_ok <mode> <input> <output> <message>
json_ok() {
    local mode="${1}"
    local input="${2}"
    local output="${3}"
    local message="${4}"
    printf '{\n'
    printf '  "status": true,\n'
    printf '  "mode": "%s",\n'   "$(json_escape "${mode}")"
    printf '  "input": "%s",\n'  "$(json_escape "${input}")"
    printf '  "output": "%s",\n' "$(json_escape "${output}")"
    printf '  "message": "%s"\n' "$(json_escape "${message}")"
    printf '}\n'
    exit 0
}

# json_err: output an error JSON object and exit 1
# Usage: json_err <mode> <message>
json_err() {
    local mode="${1}"
    local message="${2}"
    printf '{\n'
    printf '  "status": false,\n'
    printf '  "mode": "%s",\n'    "$(json_escape "${mode}")"
    printf '  "message": "%s"\n'  "$(json_escape "${message}")"
    printf '}\n'
    exit 1
}

# json_version: output version JSON and exit 0
json_version() {
    local version="${1}"
    printf '{\n'
    printf '  "status": true,\n'
    printf '  "version": "%s"\n' "$(json_escape "${version}")"
    printf '}\n'
    exit 0
}
