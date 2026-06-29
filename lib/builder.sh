#!/usr/bin/env bash
# =============================================================================
# lib/builder.sh — Multi-Layer Obfuscation Engine
# BogelShell Protect v2.1
#
# ENCRYPT PIPELINE (4 layers):
#   source → gzip-9 → base64 → hex_encode → rev → base64 → chunked array + noise
#
# DECRYPT PIPELINE:
#   join chunks → base64-d → rev → hex_decode → base64-d → gunzip → source
#
# OUTPUT SIZE (via PROTECT_LEVEL=1..4):
#   1 → ~50KB    2 → ~200KB [default]    3 → ~500KB    4 → ~2MB
#
# OWNER  : BogelStore
# TG     : @BogelStore1
# EMAIL  : dev.bogelproject@gmail.com
# GITHUB : https://github.com/BogelStore1/shell
# =============================================================================

readonly BS_FORMAT_VERSION="2"
readonly BS_FORMAT_HEADER="# BOGELSHELL_PROTECT_FORMAT=${BS_FORMAT_VERSION}"
readonly BS_FORMAT_MODE="# BOGELSHELL_PROTECT_MODE=OBFUSCATED"
: "${PROTECT_LEVEL:=2}"

# --- Noise line count per level ---
_bs_noise_count() {
    case "${PROTECT_LEVEL}" in
        1) echo 600   ;;
        2) echo 2400  ;;
        3) echo 6000  ;;
        4) echo 24000 ;;
        *) echo 2400  ;;
    esac
}

# --- Hex encode stdin → lowercase hex string (no spaces/newlines) ---
_bs_hex_enc() {
    if command -v od &>/dev/null; then
        od -A n -t x1 | tr -d ' \n'
    elif command -v xxd &>/dev/null; then
        xxd -p | tr -d '\n'
    else
        # Pure bash fallback
        local byte hex
        while IFS= read -r -d '' -n1 byte 2>/dev/null; do
            printf -v hex '%02x' "'${byte}"
            printf '%s' "${hex}"
        done
    fi
}

# --- Batch-generate N noise variable lines (fast single urandom read) ---
_bs_noise_block() {
    local count="${1:-100}"
    # One large urandom read: 8 chars name + 64 chars value = 72 per line
    local need=$(( count * 72 + 64 ))
    local pool
    pool="$(tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c "${need}")"
    # Pad if urandom was insufficient
    while [[ ${#pool} -lt $need ]]; do
        pool+="${RANDOM}${RANDOM}${RANDOM}${RANDOM}${RANDOM}${RANDOM}"
    done
    local i=0 pos=0 n v
    while [[ $i -lt $count ]]; do
        n="${pool:${pos}:8}"; pos=$((pos+8))
        # lowercase the name portion
        n="${n,,}"
        v="${pool:${pos}:64}"; pos=$((pos+64))
        printf '  local _v%s="%s"\n' "${n}" "${v}"
        i=$((i+1))
    done
}

# --- Split string into quoted lines for bash array (chunk_size chars each) ---
_bs_chunk_array() {
    local s="${1}" csz="${2:-72}" i=0 len="${#1}"
    while [[ $i -lt $len ]]; do
        printf "  '%s'\n" "${s:$i:$csz}"
        i=$((i+csz))
    done
}

# =============================================================================
# build_encrypted <input> <output>
# =============================================================================
build_encrypted() {
    local input="${1}" output="${2}" STEPS=8

    # Step 1 — read source
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && msg_step "Reading source..."
    local src
    src="$(cat "${input}")" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "Cannot read input: ${input}"
        msg_err "Cannot read input file: ${input}"; return 1
    }

    # Metadata
    local ts bid fnm vnm
    ts="$(generate_timestamp)"
    bid="$(random_string 16)"
    fnm="_bs_$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c10 || printf '%x%x%x' "${RANDOM}" "${RANDOM}" "${RANDOM}")"
    vnm="_p$(tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c10 || printf '%x%x' "${RANDOM}" "${RANDOM}")"
    local hfn="${fnm}_h"
    local noise_n; noise_n="$(_bs_noise_count)"

    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 1 $STEPS "Preparing"

    # Step 2 — gzip + base64 (L1)
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 2 $STEPS "Compress + encode L1"
    local l1
    l1="$(printf '%s' "${src}" | gzip -c -9 2>/dev/null \
         | { base64 -w0 2>/dev/null || base64 2>/dev/null | tr -d '\n'; })" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "L1: gzip/base64 failed"
        msg_err "Layer 1 failed"; return 1
    }

    # Step 3 — hex encode (L2) — doubles the size, adds complexity
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 3 $STEPS "Hex encode L2"
    local l2
    l2="$(printf '%s' "${l1}" | _bs_hex_enc)" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "L2: hex encode failed"
        msg_err "Layer 2 failed"; return 1
    }

    # Step 4 — rev (L3)
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 4 $STEPS "Reverse L3"
    local l3
    l3="$(printf '%s' "${l2}" | rev)" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "L3: rev failed"
        msg_err "Layer 3 failed"; return 1
    }

    # Step 5 — base64 again (L4)
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 5 $STEPS "Re-encode L4"
    local l4
    l4="$(printf '%s' "${l3}" | { base64 -w0 2>/dev/null || base64 2>/dev/null | tr -d '\n'; })" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "L4: base64 failed"
        msg_err "Layer 4 failed"; return 1
    }

    # Step 6 — chunk split
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 6 $STEPS "Chunking payload"
    local chunks
    chunks="$(_bs_chunk_array "${l4}" 72)"

    # Step 7 — write output
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 7 $STEPS "Generating noise + writing"

    {
        # --- Format headers (MUST be lines 1-2) ---
        printf '%s\n' "${BS_FORMAT_HEADER}"
        printf '%s\n' "${BS_FORMAT_MODE}"
        cat << HDREOF
# BOGELSHELL_PROTECT_BUILD=${bid}
# BOGELSHELL_PROTECT_DATE=${ts}
# BOGELSHELL_PROTECT_SRC=$(basename "${input}")
# BOGELSHELL_PROTECT_LEVEL=${PROTECT_LEVEL}
# BOGELSHELL_PROTECT_LAYERS=4
# BOGELSHELL_PROTECT_NOISE=${noise_n}
# ================================================================
# Protected by BogelShell Protect v${BS_VERSION}
# Do NOT edit manually — use: bogelshell dec --input <file>
# DISCLAIMER: This is OBFUSCATION only, NOT strong encryption.
# ================================================================
# Owner   : BogelStore
# Telegram: @BogelStore1
# Email   : dev.bogelproject@gmail.com
# GitHub  : https://github.com/BogelStore1/shell
# ================================================================
#!/usr/bin/env bash

# hex decoder — pure bash, no external tools needed at runtime
${hfn}() {
  local _h="\${1}" _i=0
  while [[ \$_i -lt \${#_h} ]]; do
    printf "\\\\x\${_h:\${_i}:2}"
    _i=\$((_i+2))
  done
}

# main decoder + executor
${fnm}() {
HDREOF

        # noise block
        _bs_noise_block "${noise_n}"

        # payload array
        cat << PAYEOF

  # -- payload (base64 → rev → hex → base64 → source) --
  ${vnm}=(
${chunks}
  )
  local _j; _j="\$(printf '%s' "\${${vnm}[@]}")"
  local _a; _a="\$(printf '%s' "\${_j}" | base64 -d 2>/dev/null)"
  local _b; _b="\$(printf '%s' "\${_a}" | rev)"
  local _c; _c="\$(${hfn} "\${_b}")"
  eval "\$(printf '%s' "\${_c}" | base64 -d 2>/dev/null | gunzip -c 2>/dev/null)"
}

${fnm}
PAYEOF

    } > "${output}" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "encrypt" "Failed to write: ${output}"
        msg_err "Failed to write output: ${output}"; return 1
    }

    chmod +x "${output}" || true
    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 8 $STEPS "Done"
    return 0
}

# =============================================================================
# build_decrypted <input> <output>
# =============================================================================
build_decrypted() {
    local input="${1}" output="${2}" STEPS=6

    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && msg_step "Parsing protected file..."

    # --- Verify format version ---
    local fver
    fver="$(grep -m1 '^# BOGELSHELL_PROTECT_FORMAT=' "${input}" 2>/dev/null | cut -d= -f2)"
    if [[ "${fver}" != "2" ]]; then
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Unsupported format: ${fver:-unknown}"
        msg_err "Unsupported BogelShell format version: ${fver:-unknown}"; return 1
    fi

    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 1 $STEPS "Verified format"

    # --- Detect multi-layer vs legacy ---
    local layers is_multi=0
    layers="$(grep -m1 '^# BOGELSHELL_PROTECT_LAYERS=' "${input}" 2>/dev/null | cut -d= -f2)"
    [[ "${layers:-0}" -ge 2 ]] 2>/dev/null && is_multi=1

    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 2 $STEPS "Detecting layers"

    local src

    if [[ "${is_multi}" == "1" ]]; then
        # --- Extract array variable name (_bs_XXXXXXXX) ---
        local arrvar
        # Match any _bs_ or _p prefixed array variable
        arrvar="$(grep -m1 "^  _[a-z][a-z0-9]*=($" "${input}" 2>/dev/null \
                  | sed 's/^  \([_a-z][a-z0-9]*\)=($/\1/')"

        if [[ -z "${arrvar}" ]]; then
            [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Cannot find payload array"
            msg_err "Cannot find payload array in: ${input}"; return 1
        fi

        # --- Extract & join chunk lines (between array open/close) ---
        # Chunk lines look like:  'BASE64DATA'
        local l4
        l4="$(sed -n "/^  ${arrvar}=($/,/^  )$/{
            /^  ${arrvar}=($/d
            /^  )$/d
            s/^  '//
            s/'$//
            p
        }" "${input}" 2>/dev/null | tr -d '\n')"

        if [[ -z "${l4}" ]]; then
            [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Empty payload array"
            msg_err "Payload array is empty or corrupt"; return 1
        fi

        [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 3 $STEPS "Decoding L4→L3"

        # L4 → base64-d → L3
        local l3
        l3="$(printf '%s' "${l4}" | base64 -d 2>/dev/null)"
        if [[ -z "${l3}" ]]; then
            [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "L4 base64 decode failed"
            msg_err "Layer 4 base64 decode failed"; return 1
        fi

        [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 4 $STEPS "Reversing L3→L2"

        # L3 → rev → L2
        local l2
        l2="$(printf '%s' "${l3}" | rev)"

        [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 5 $STEPS "Hex decode + decompress"

        # L2 → hex_decode → temp → base64-d → gunzip → src
        local _tmp
        _tmp="$(mktemp /tmp/.bsdec_XXXXXX 2>/dev/null || printf '/tmp/.bsdec_%s' "$$")"
        local _hi=0 _hl="${#l2}"
        {
            while [[ $_hi -lt $_hl ]]; do
                printf "\\x${l2:${_hi}:2}"
                _hi=$((_hi+2))
            done
        } > "${_tmp}" 2>/dev/null

        src="$(base64 -d < "${_tmp}" 2>/dev/null | gunzip -c 2>/dev/null)"
        rm -f "${_tmp}"

    else
        # --- Legacy single-layer (rev + base64) ---
        local rev_payload
        rev_payload="$(awk '
            /^_bs_payload="/ { found=1; sub(/^_bs_payload="/, ""); }
            found {
                if (/"$/) { sub(/"$/, ""); printf "%s", $0; exit }
                printf "%s", $0
            }
        ' "${input}" 2>/dev/null)"

        if [[ -z "${rev_payload}" ]]; then
            [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Cannot extract legacy payload"
            msg_err "Cannot extract legacy payload"; return 1
        fi

        [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 3 $STEPS "Decoding (legacy)"
        [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 5 $STEPS "Decompressing"

        src="$(printf '%s' "${rev_payload}" | rev | base64 -d 2>/dev/null | gunzip -c 2>/dev/null)"
    fi

    if [[ -z "${src}" ]]; then
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Decoded content is empty — file may be corrupt"
        msg_err "Decoded content is empty. File may be corrupt."; return 1
    fi

    [[ "${QUIET_MODE:-0}" == "0" && "${JSON_MODE:-0}" == "0" ]] && progress_bar 6 $STEPS "Writing output"

    {
        printf '#!/usr/bin/env bash\n'
        printf '# ================================================================\n'
        printf '# Recovered by BogelShell Protect v%s\n' "${BS_VERSION}"
        printf '# Date    : %s\n' "$(generate_timestamp)"
        printf '# Source  : %s\n' "$(basename "${input}")"
        printf '# Owner   : BogelStore\n'
        printf '# Telegram: @BogelStore1\n'
        printf '# Email   : dev.bogelproject@gmail.com\n'
        printf '# ================================================================\n'
        printf '\n'
        printf '%s\n' "${src}"
    } > "${output}" || {
        [[ "${JSON_MODE:-0}" == "1" ]] && json_err "decrypt" "Failed to write: ${output}"
        msg_err "Failed to write output: ${output}"; return 1
    }

    chmod +x "${output}" || true
    return 0
}
