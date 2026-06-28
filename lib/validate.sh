#!/usr/bin/env bash
# =============================================================================
# lib/validate.sh — File & format validation helpers
# BogelShell Protect v2.1
# =============================================================================

# BogelShell Protect format header markers
readonly BS_HEADER_FORMAT="# BOGELSHELL_PROTECT_FORMAT=2"
readonly BS_HEADER_MODE="# BOGELSHELL_PROTECT_MODE=OBFUSCATED"

# validate_input_file: check input file exists, readable, non-empty
# Returns 0 on success, prints error and returns 1 on failure
validate_input_file() {
    local file="${1}"
    local mode="${2:-generic}"  # 'generic' or used for JSON mode label

    if [[ -z "${file}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "No input file specified"
        else
            msg_err "No input file specified. Use --input <file>"
        fi
        return 1
    fi

    if [[ ! -e "${file}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "Input file not found: ${file}"
        else
            msg_err "Input file not found: ${file}"
        fi
        return 1
    fi

    if [[ ! -f "${file}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "Input path is not a regular file: ${file}"
        else
            msg_err "Input path is not a regular file: ${file}"
        fi
        return 1
    fi

    if [[ ! -r "${file}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "Input file is not readable (permission denied): ${file}"
        else
            msg_err "Input file is not readable (permission denied): ${file}"
        fi
        return 1
    fi

    if [[ ! -s "${file}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "Input file is empty: ${file}"
        else
            msg_err "Input file is empty: ${file}"
        fi
        return 1
    fi

    return 0
}

# validate_output_file: check if output path is writable, handle --force
# Returns 0 on success
validate_output_file() {
    local file="${1}"
    local mode="${2:-generic}"
    local force="${FORCE_OVERWRITE:-0}"

    if [[ -z "${file}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "No output file specified"
        else
            msg_err "No output file specified. Use --output <file>"
        fi
        return 1
    fi

    if [[ -e "${file}" ]] && [[ "${force}" != "1" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "Output file already exists: ${file}. Use --force to overwrite"
        else
            msg_err "Output file already exists: ${file}"
            msg_info "Use --force to overwrite"
        fi
        return 1
    fi

    # Check parent directory is writable
    local outdir
    outdir="$(dirname "${file}")"
    if [[ ! -w "${outdir}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "Output directory is not writable: ${outdir}"
        else
            msg_err "Output directory is not writable: ${outdir}"
        fi
        return 1
    fi

    return 0
}

# validate_bogelshell_format: check if a file has BogelShell Protect headers
# Returns 0 if valid BogelShell format, 1 otherwise
validate_bogelshell_format() {
    local file="${1}"
    local mode="${2:-decrypt}"

    # Read first few lines and look for BogelShell markers
    local line1 line2
    line1="$(sed -n '1p' "${file}")"
    line2="$(sed -n '2p' "${file}")"

    if [[ "${line1}" != "${BS_HEADER_FORMAT}" ]] || \
       [[ "${line2}" != "${BS_HEADER_MODE}" ]]; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_err "${mode}" "File is not a valid BogelShell Protect encrypted file: ${file}"
        else
            msg_err "File is not a valid BogelShell Protect encrypted file"
            msg_info "Only files encrypted by BogelShell Protect can be decrypted"
        fi
        return 1
    fi

    return 0
}

# validate_dependencies: check all required commands exist
# Usage: validate_dependencies bash git base64 gzip ...
validate_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        msg_err "Missing required dependencies: ${missing[*]}"
        msg_info "Please install the missing tools and try again"
        return 1
    fi
    return 0
}
