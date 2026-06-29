#!/usr/bin/env bash
# =============================================================================
# main.sh — BogelShell Protect v2.1 Main Entry Point
# Shell Script Obfuscation Tool by BogelStore
#
# Usage:
#   bogelshell                       Interactive main menu
#   bogelshell enc [--input <f> --output <f> --json --force --quiet]
#   bogelshell dec [--input <f> --output <f> --json --force --quiet]
#   bogelshell about
#   bogelshell update
#   bogelshell uninstall
#   bogelshell version
#   bogelshell help
# =============================================================================
set -euo pipefail

# =============================================================================
# Constants
# =============================================================================
readonly BS_VERSION="2.1.0"
readonly BS_REPO="https://github.com/BogelStore1/shell"
export BS_VERSION BS_REPO

# =============================================================================
# Detect install directory and platform
# =============================================================================
_detect_install_dir() {
    # Termux detection
    if [[ -n "${PREFIX:-}" ]] && [[ "${PREFIX}" == *"com.termux"* ]]; then
        echo "${HOME}/.bogelshell-protect"
        return
    fi
    # OpenWRT detection
    if [[ -f /etc/openwrt_release ]]; then
        echo "/root/bogelshell-protect"
        return
    fi
    # Default Linux
    echo "/opt/bogelshell-protect"
}

_detect_bin_dir() {
    if [[ -n "${PREFIX:-}" ]] && [[ "${PREFIX}" == *"com.termux"* ]]; then
        echo "${PREFIX}/bin"
    elif [[ -f /etc/openwrt_release ]]; then
        echo "/usr/bin"
    else
        echo "/usr/local/bin"
    fi
}

# Allow overriding via environment (useful during development)
INSTALL_DIR="${BOGELSHELL_DIR:-$(_detect_install_dir)}"
export INSTALL_DIR

# =============================================================================
# Source all library modules
# =============================================================================
_source_lib() {
    local lib="${INSTALL_DIR}/lib/${1}"
    if [[ ! -f "${lib}" ]]; then
        echo "Error: Required library not found: ${lib}" >&2
        echo "       Is BogelShell Protect properly installed?" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${lib}"
}

_source_lib "color.sh"
_source_lib "json.sh"
_source_lib "validate.sh"
_source_lib "random.sh"
_source_lib "progress.sh"
_source_lib "loader.sh"
_source_lib "cli.sh"
_source_lib "builder.sh"

# Source all modules
_source_module() {
    local mod="${INSTALL_DIR}/modules/${1}"
    if [[ ! -f "${mod}" ]]; then
        echo "Error: Required module not found: ${mod}" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${mod}"
}

_source_module "encrypt.sh"
_source_module "decrypt.sh"
_source_module "about.sh"

# =============================================================================
# Show version
# =============================================================================
show_version() {
    if [[ "${JSON_MODE:-0}" == "1" ]]; then
        json_version "${BS_VERSION}"
    else
        echo -e "${BOLD}BogelShell Protect${RESET} version ${CYAN}${BS_VERSION}${RESET}"
        echo -e "${DIM}Shell Script Obfuscation Tool — ${BS_REPO}${RESET}"
    fi
}

# =============================================================================
# Interactive main menu
# =============================================================================
show_main_menu() {
    while true; do
        clear
        show_logo

        echo -e "  ${BOLD}${CYAN}Main Menu${RESET}"
        separator
        echo ""
        echo -e "  ${CYAN}[1]${RESET} ${BOLD}Encrypt Script${RESET}   ${DIM}— Obfuscate a Bash script${RESET}"
        echo -e "  ${CYAN}[2]${RESET} ${BOLD}Decrypt Script${RESET}   ${DIM}— Recover original from protected file${RESET}"
        echo -e "  ${CYAN}[3]${RESET} ${BOLD}About${RESET}            ${DIM}— About BogelShell Protect${RESET}"
        echo -e "  ${CYAN}[4]${RESET} ${BOLD}Update${RESET}           ${DIM}— Auto-update from GitHub${RESET}"
        echo -e "  ${RED}[5]${RESET} ${BOLD}Uninstall${RESET}        ${DIM}— Remove BogelShell Protect${RESET}"
        echo -e "  ${DIM}[0]${RESET} ${BOLD}Exit${RESET}"
        echo ""
        separator
        echo -ne "  ${CYAN}Choose${RESET} [0-5] : "
        read -r choice

        case "${choice}" in
            1|e|enc|encrypt)    encrypt_main    ;;
            2|d|dec|decrypt)    decrypt_main    ;;
            3|a|about)          show_about      ;;
            4|u|update)
                bash "${INSTALL_DIR}/update.sh"
                echo ""
                read -rp "  Press Enter to continue..."
                ;;
            5|uninstall)
                bash "${INSTALL_DIR}/uninstall.sh"
                # If uninstall succeeds, the binary is gone — just exit
                exit 0
                ;;
            0|q|quit|exit)
                echo ""
                echo -e "  ${DIM}Goodbye! — BogelShell Protect v${BS_VERSION}${RESET}"
                echo ""
                exit 0
                ;;
            *)
                msg_warn "Invalid choice: ${choice}"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# CLI Dispatcher — parse $1 (subcommand) + remaining args
# =============================================================================
_subcommand="${1:-}"
shift 2>/dev/null || true   # shift off subcommand; remaining are flags

case "${_subcommand}" in

    # ------------------------------------------------------------------
    enc|encrypt)
        parse_cli_args "$@"
        # Re-init colors after JSON_MODE is known
        _init_colors
        if is_cli_mode; then
            run_encrypt_cli
        else
            encrypt_main
        fi
        ;;

    # ------------------------------------------------------------------
    dec|decrypt)
        parse_cli_args "$@"
        _init_colors
        if is_cli_mode; then
            run_decrypt_cli
        else
            decrypt_main
        fi
        ;;

    # ------------------------------------------------------------------
    about)
        show_about
        ;;

    # ------------------------------------------------------------------
    update)
        bash "${INSTALL_DIR}/update.sh"
        ;;

    # ------------------------------------------------------------------
    uninstall)
        bash "${INSTALL_DIR}/uninstall.sh"
        ;;

    # ------------------------------------------------------------------
    version|-v|--version)
        parse_cli_args "$@"
        _init_colors
        show_version
        ;;

    # ------------------------------------------------------------------
    help|-h|--help)
        show_help
        ;;

    # ------------------------------------------------------------------
    "")
        # No subcommand → interactive main menu
        show_main_menu
        ;;

    # ------------------------------------------------------------------
    *)
        msg_err "Unknown command: ${_subcommand}"
        echo ""
        show_help
        exit 1
        ;;
esac
