#!/usr/bin/env bash
# =============================================================================
# lib/loader.sh — Logo, banner, and boot screen helpers
# BogelShell Protect v2.1
# =============================================================================

# INSTALL_DIR is set by main.sh based on detected environment
: "${INSTALL_DIR:=/opt/bogelshell-protect}"

# show_logo: print the ASCII logo (skipped in JSON/quiet mode)
show_logo() {
    [[ "${JSON_MODE:-0}" == "1" ]]  && return
    [[ "${QUIET_MODE:-0}" == "1" ]] && return

    local logo_file="${INSTALL_DIR}/assets/logo.txt"
    echo ""
    if [[ -f "${logo_file}" ]]; then
        echo -e "${CYAN}"
        cat "${logo_file}"
        echo -e "${RESET}"
    else
        # Fallback compact banner if logo.txt is missing
        echo -e "${BOLD}${CYAN}"
        echo "  ╔══════════════════════════════════════════╗"
        echo "  ║       BogelShell Protect v2.1            ║"
        echo "  ║   Shell Script Obfuscation Tool          ║"
        echo "  ╚══════════════════════════════════════════╝"
        echo -e "${RESET}"
    fi
}

# show_banner: compact one-line banner for sub-menus
show_banner() {
    [[ "${JSON_MODE:-0}" == "1" ]]  && return
    [[ "${QUIET_MODE:-0}" == "1" ]] && return

    echo -e "${BOLD}${CYAN}[ BogelShell Protect v${BS_VERSION} ]${RESET} ${DIM}Shell Script Obfuscation Tool${RESET}"
    separator
}

# show_version_line: one-liner version display (for menus)
show_version_line() {
    [[ "${JSON_MODE:-0}" == "1" ]] && return
    echo -e "  ${DIM}Version:${RESET} ${BOLD}${BS_VERSION}${RESET}  |  ${DIM}by${RESET} ${CYAN}BogelStore${RESET}"
}
