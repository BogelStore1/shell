#!/usr/bin/env bash
# =============================================================================
# modules/encrypt.sh — Encrypt (Obfuscate) Script Module
# BogelShell Protect v2.1
# =============================================================================

# run_encrypt_cli: non-interactive encrypt for bot/API/CLI use
# Called when --input and --output are provided
run_encrypt_cli() {
    local input="${CLI_INPUT}"
    local output="${CLI_OUTPUT}"

    # Validate input
    validate_input_file "${input}" "encrypt" || return 1

    # Validate output
    validate_output_file "${output}" "encrypt" || return 1

    # Run obfuscation engine
    if build_encrypted "${input}" "${output}"; then
        if [[ "${JSON_MODE:-0}" == "1" ]]; then
            json_ok "encrypt" "${input}" "${output}" "Encrypt success"
        else
            echo ""
            msg_ok "Encrypt success!"
            msg_info "Output: ${output}"
        fi
        return 0
    else
        # build_encrypted already printed/emitted the error
        return 1
    fi
}

# run_encrypt_menu: interactive encrypt menu
run_encrypt_menu() {
    show_logo
    section_header "Encrypt Script"

    echo ""
    echo -e "  ${DIM}Obfuscate a Bash script to protect against casual reading.${RESET}"
    echo -e "  ${YELLOW}Note: This is obfuscation, NOT strong encryption.${RESET}"
    echo ""
    separator

    # Prompt for input file
    while true; do
        echo -ne "  ${CYAN}Input file${RESET}  : "
        read -r input_file

        if [[ -z "${input_file}" ]]; then
            msg_warn "Input file cannot be empty. Press Ctrl+C to cancel."
            continue
        fi

        # Expand tilde
        input_file="${input_file/#\~/$HOME}"

        validate_input_file "${input_file}" "encrypt" && break
        echo ""
    done

    # Prompt for output file
    local default_output="${input_file%.sh}-enc.sh"
    echo -ne "  ${CYAN}Output file${RESET} : [${DIM}${default_output}${RESET}] "
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

    validate_output_file "${output_file}" "encrypt" || {
        echo ""
        read -rp "  Press Enter to return to menu..."
        return 1
    }

    echo ""
    separator
    msg_step "Starting obfuscation..."
    echo ""

    if build_encrypted "${input_file}" "${output_file}"; then
        echo ""
        separator
        msg_ok "Encrypt completed successfully!"
        echo ""
        echo -e "  ${DIM}Input  :${RESET} ${input_file}"
        echo -e "  ${DIM}Output :${RESET} ${GREEN}${output_file}${RESET}"
        echo -e "  ${DIM}Size   :${RESET} $(du -sh "${output_file}" 2>/dev/null | awk '{print $1}' || echo 'N/A')"
        echo ""
        separator
    else
        echo ""
        msg_err "Encryption failed!"
    fi

    echo ""
    read -rp "  Press Enter to return to menu..."
}

# Entry point: dispatch CLI or interactive
encrypt_main() {
    if is_cli_mode; then
        run_encrypt_cli
    else
        run_encrypt_menu
    fi
}
