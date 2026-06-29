#!/usr/bin/env bash
# =============================================================================
# modules/decrypt.sh — Decrypt (De-obfuscate) Script Module
# BogelShell Protect v2.1
# =============================================================================

# run_decrypt_cli: non-interactive decrypt for bot/API/CLI use
run_decrypt_cli() {
    _init_colors
    local input="${CLI_INPUT}"
    local output="${CLI_OUTPUT}"

    if [[ "${JSON_MODE:-0}" == "1" ]]; then
        {
            validate_input_file "${input}"             || exit 1
            validate_bogelshell_format "${input}"      || exit 1
            validate_output_file "${output}"           || exit 1
            build_decrypted "${input}" "${output}"
        } >/dev/null 2>/dev/null
        local _rc=$?
        if [[ $_rc -eq 0 ]]; then
            json_ok "decrypt" "${input}" "${output}" "Decrypt success"
        else
            json_err "decrypt" "${_BS_ERR_MSG:-Decryption failed}"
        fi
    else
        validate_input_file "${input}"          || return 1
        validate_bogelshell_format "${input}"   || return 1
        validate_output_file "${output}"        || return 1
        if build_decrypted "${input}" "${output}"; then
            echo ""; msg_ok "Decrypt success!"; msg_info "Output: ${output}"
        else
            return 1
        fi
    fi
    return 0
}

# run_decrypt_menu: interactive decrypt menu
run_decrypt_menu() {
    show_logo
    section_header "Decrypt Script"

    echo ""
    echo -e "  ${DIM}Recover the original script from a BogelShell protected file.${RESET}"
    echo -e "  ${YELLOW}Only files encrypted by BogelShell Protect can be decrypted.${RESET}"
    echo ""
    separator

    # Prompt for input file
    while true; do
        echo -ne "  ${CYAN}Encrypted file${RESET} : "
        read -r input_file

        if [[ -z "${input_file}" ]]; then
            msg_warn "Input file cannot be empty. Press Ctrl+C to cancel."
            continue
        fi

        input_file="${input_file/#\~/$HOME}"

        # Validate existence first
        validate_input_file "${input_file}" "decrypt" || { echo ""; continue; }

        # Validate format
        validate_bogelshell_format "${input_file}" "decrypt" && break

        echo ""
        echo -ne "  ${YELLOW}Try a different file? [Y/n]${RESET} : "
        read -r retry
        [[ "${retry,,}" == "n" ]] && return 0
    done

    # Prompt for output file
    local base="${input_file%.sh}"
    base="${base%-enc}"
    local default_output="${base}-dec.sh"
    echo -ne "  ${CYAN}Output file${RESET}    : [${DIM}${default_output}${RESET}] "
    read -r output_file
    output_file="${output_file:-${default_output}}"
    output_file="${output_file/#\~/$HOME}"

    # Check overwrite
    if [[ -e "${output_file}" ]]; then
        echo ""
        echo -ne "  ${YELLOW}File already exists. Overwrite? [y/N]${RESET} : "
        read -r confirm
        if [[ "${confirm,,}" != "y" ]]; then
            msg_warn "Cancelled."
            echo ""
            return 0
        fi
        FORCE_OVERWRITE="1"
    fi

    validate_output_file "${output_file}" "decrypt" || {
        echo ""
        read -rp "  Press Enter to return to menu..."
        return 1
    }

    echo ""
    separator
    msg_step "Starting de-obfuscation..."
    echo ""

    if build_decrypted "${input_file}" "${output_file}"; then
        echo ""
        separator
        msg_ok "Decrypt completed successfully!"
        echo ""
        echo -e "  ${DIM}Input  :${RESET} ${input_file}"
        echo -e "  ${DIM}Output :${RESET} ${GREEN}${output_file}${RESET}"
        echo -e "  ${DIM}Size   :${RESET} $(du -sh "${output_file}" 2>/dev/null | awk '{print $1}' || echo 'N/A')"
        echo ""
        separator
    else
        echo ""
        msg_err "Decryption failed!"
    fi

    echo ""
    read -rp "  Press Enter to return to menu..."
}

# Entry point: dispatch CLI or interactive
decrypt_main() {
    if is_cli_mode; then
        run_decrypt_cli
    else
        run_decrypt_menu
    fi
}
