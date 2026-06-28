#!/usr/bin/env bash
# =============================================================================
# lib/random.sh — Random key/token generators for obfuscation
# BogelShell Protect v2.1
# =============================================================================

# random_string: generate a random alphanumeric string of given length
# Usage: random_string <length>
random_string() {
    local length="${1:-16}"
    # Use /dev/urandom with tr, fallback to date+pid combo
    if [[ -r /dev/urandom ]]; then
        tr -dc 'a-zA-Z0-9' </dev/urandom 2>/dev/null | head -c "${length}"
    else
        # Fallback: combine date, pid, and RANDOM
        local seed="${RANDOM}${RANDOM}$(date +%s%N 2>/dev/null || date +%s)"
        echo -n "${seed}" | md5sum 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c "${length}" \
            || echo -n "${seed}" | head -c "${length}"
    fi
    echo  # newline
}

# random_hex: generate random hex string
# Usage: random_hex <length>
random_hex() {
    local length="${1:-8}"
    if [[ -r /dev/urandom ]]; then
        tr -dc 'a-f0-9' </dev/urandom 2>/dev/null | head -c "${length}"
    else
        printf '%x' "${RANDOM}${RANDOM}" | head -c "${length}"
    fi
    echo
}

# random_var_name: generate a valid random bash variable name
# Usage: random_var_name
random_var_name() {
    local prefix="v"
    local suffix
    suffix="$(random_string 8 | tr -dc 'a-zA-Z0-9')"
    echo "${prefix}${suffix}"
}

# random_func_name: generate a valid random bash function name
random_func_name() {
    local prefix="fn_"
    local suffix
    suffix="$(random_string 8 | tr -dc 'a-z0-9')"
    echo "${prefix}${suffix}"
}

# generate_timestamp: ISO-like timestamp for metadata
generate_timestamp() {
    date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date
}
