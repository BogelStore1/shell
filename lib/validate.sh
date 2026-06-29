#!/usr/bin/env bash
# =============================================================================
# lib/validate.sh — File & format validation helpers
# BogelShell Protect v2.1
# =============================================================================

readonly BS_HEADER_FORMAT="# BOGELSHELL_PROTECT_FORMAT=2"
readonly BS_HEADER_MODE="# BOGELSHELL_PROTECT_MODE=OBFUSCATED"

# Global error message for JSON callers
_BS_ERR_MSG=""

# _bs_valerr: set error msg + print if not JSON mode + return 1
_bs_valerr() {
    _BS_ERR_MSG="${1}"
    [[ "${JSON_MODE:-0}" != "1" ]] && msg_err "${1}"
    return 1
}

validate_input_file() {
    local file="${1}"

    [[ -z "${file}" ]]  && _bs_valerr "No input file specified (use --input <file>)"  && return 1
    [[ ! -e "${file}" ]] && _bs_valerr "Input file not found: ${file}"                 && return 1
    [[ ! -f "${file}" ]] && _bs_valerr "Not a regular file: ${file}"                   && return 1
    [[ ! -r "${file}" ]] && _bs_valerr "Permission denied (not readable): ${file}"     && return 1
    [[ ! -s "${file}" ]] && _bs_valerr "Input file is empty: ${file}"                  && return 1
    return 0
}

validate_output_file() {
    local file="${1}"
    local force="${FORCE_OVERWRITE:-0}"

    [[ -z "${file}" ]] && _bs_valerr "No output file specified (use --output <file>)" && return 1

    if [[ -e "${file}" ]] && [[ "${force}" != "1" ]]; then
        _bs_valerr "Output file already exists: ${file} — use --force to overwrite"
        return 1
    fi

    local dir; dir="$(dirname "${file}")"
    [[ ! -w "${dir}" ]] && _bs_valerr "Output directory not writable: ${dir}" && return 1

    return 0
}

validate_bogelshell_format() {
    local file="${1}"
    local l1 l2
    l1="$(sed -n '1p' "${file}" 2>/dev/null)"
    l2="$(sed -n '2p' "${file}" 2>/dev/null)"

    if [[ "${l1}" != "${BS_HEADER_FORMAT}" ]] || [[ "${l2}" != "${BS_HEADER_MODE}" ]]; then
        _bs_valerr "Not a valid BogelShell Protect file: ${file}"
        return 1
    fi
    return 0
}

validate_dependencies() {
    local missing=()
    for cmd in "$@"; do
        command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        msg_err "Missing dependencies: ${missing[*]}"
        return 1
    fi
    return 0
}
