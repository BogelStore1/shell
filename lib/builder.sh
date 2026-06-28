#!/usr/bin/env bash
# =============================================================================
# lib/builder.sh — Core obfuscation/de-obfuscation engine
# BogelShell Protect v2.1
#
# IMPORTANT NOTICE:
#   This tool performs OBFUSCATION, not strong cryptographic encryption.
#   It is intended to deter casual reading of shell scripts.
#   A determined user with Bash knowledge can reverse it.
#   Do NOT use this to protect truly sensitive secrets.
# =============================================================================

# BogelShell Protect format version
readonly BS_FORMAT_VERSION="2"
readonly BS_FORMAT_HEADER="# BOGELSHELL_PROTECT_FORMAT=${BS_FORMAT_VERSION}"
readonly BS_FORMAT_MODE="# BOGELSHELL_PROTECT_MODE=OBFUSCATED"

# build_encrypted: obfuscate a shell script
# Usage: build_encrypted <input_file> <output_file>
# Returns 0 on success, 1 on failure
build_encrypted() {
    local input="${1}"
    local output="${2}"

    # ---- Step 1: Read raw source ----------------------------------------
    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        msg_step "Reading source file..."

    local source_content
    source_content="$(cat "${input}")" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "Failed to read input file: ${input}"
        msg_err "Failed to read input file: ${input}"
        return 1
    }

    # ---- Step 2: Generate random seed metadata -------------------------
    local ts build_id rev_key
    ts="$(generate_timestamp)"
    build_id="$(random_string 12)"
    rev_key="$(random_hex 4)"

    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 1 5 "Preparing"

    # ---- Step 3: gzip + base64 encode the source -----------------------
    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 2 5 "Compressing"

    local encoded
    # Use -w0 (no line wrap) so payload is single-line; rev requires a single-line string.
    # Fallback: pipe through tr -d '\n' for systems without -w0 (e.g. macOS).
    encoded="$(printf '%s' "${source_content}" | gzip -c -9 2>/dev/null | { base64 -w0 2>/dev/null || base64 2>/dev/null | tr -d '\n'; })" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "Compression/encoding failed"
        msg_err "Compression/encoding step failed"
        return 1
    }

    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 3 5 "Obfuscating"

    # ---- Step 4: Reverse the base64 string (simple obfuscation layer) --
    local reversed
    reversed="$(printf '%s' "${encoded}" | rev)" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "Obfuscation step failed"
        msg_err "Obfuscation step (rev) failed"
        return 1
    }

    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 4 5 "Writing output"

    # ---- Step 5: Write protected script --------------------------------
    # The output is a self-contained Bash script that decodes itself at runtime.
    {
        echo "${BS_FORMAT_HEADER}"
        echo "${BS_FORMAT_MODE}"
        echo "# BOGELSHELL_PROTECT_BUILD=${build_id}"
        echo "# BOGELSHELL_PROTECT_DATE=${ts}"
        echo "# BOGELSHELL_PROTECT_SRC=$(basename "${input}")"
        echo "# ------------------------------------------------------------"
        echo "# This file is protected by BogelShell Protect v${BS_VERSION}"
        echo "# Do not edit manually. Use: bogelshell dec --input <file>"
        echo "# DISCLAIMER: This is obfuscation, NOT strong encryption."
        echo "# ------------------------------------------------------------"
        echo "#!/usr/bin/env bash"
        echo "set -euo pipefail"
        echo ""
        echo "# BogelShell Protect self-extracting wrapper"
        echo "_bs_payload=\"${reversed}\""
        echo ""
        echo "# Decode: reverse → base64 decode → gunzip → eval"
        echo "eval \"\$(printf '%s' \"\${_bs_payload}\" | rev | base64 -d 2>/dev/null | gunzip -c 2>/dev/null)\""
    } > "${output}" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "Failed to write output file: ${output}"
        msg_err "Failed to write output file: ${output}"
        return 1
    }

    chmod +x "${output}" || true

    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 5 5 "Done"

    return 0
}

# build_decrypted: de-obfuscate a BogelShell protected script
# Usage: build_decrypted <input_file> <output_file>
# Returns 0 on success, 1 on failure
build_decrypted() {
    local input="${1}"
    local output="${2}"

    # ---- Step 1: Extract the payload variable --------------------------
    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        msg_step "Extracting payload..."

    # Extract the _bs_payload="..." variable (may span multiple lines due to base64 wrapping).
    # Strategy: grab everything between _bs_payload=" and the closing " on its own line.
    local reversed
    reversed="$(awk '
        /^_bs_payload="/ { found=1; sub(/^_bs_payload="/, ""); }
        found {
            if (/^"[[:space:]]*$/ || /"$/) {
                sub(/"[[:space:]]*$/, "")
                printf "%s", $0
                exit
            } else {
                printf "%s", $0
            }
        }
    ' "${input}" 2>/dev/null)" || true

    if [[ -z "${reversed}" ]]; then
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Could not extract payload from file: ${input}"
        msg_err "Could not extract payload. File may be corrupt or wrong format."
        return 1
    fi

    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 1 4 "Extracting payload"

    # ---- Step 2: Reverse the string to get base64 ----------------------
    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 2 4 "Reversing"

    local encoded
    encoded="$(printf '%s' "${reversed}" | rev)" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Reverse step failed"
        msg_err "Reverse step failed"
        return 1
    }

    # ---- Step 3: Base64 decode + gunzip --------------------------------
    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 3 4 "Decompressing"

    local source_content
    source_content="$(printf '%s' "${encoded}" | base64 -d 2>/dev/null | gunzip -c 2>/dev/null)" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Decode/decompress failed. File may be corrupt."
        msg_err "Decode/decompress step failed. File may be corrupt."
        return 1
    }

    if [[ -z "${source_content}" ]]; then
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Decoded content is empty. File may be corrupt."
        msg_err "Decoded content is empty."
        return 1
    fi

    # ---- Step 4: Write recovered source --------------------------------
    [[ "${QUIET_MODE:-0}" == "0" ]] && [[ "${JSON_MODE:-0}" == "0" ]] && \
        progress_bar 4 4 "Writing output"

    {
        echo "#!/usr/bin/env bash"
        echo "# Recovered by BogelShell Protect dec — $(generate_timestamp)"
        echo ""
        printf '%s\n' "${source_content}"
    } > "${output}" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Failed to write output file: ${output}"
        msg_err "Failed to write output file: ${output}"
        return 1
    }

    chmod +x "${output}" || true
    return 0
}
