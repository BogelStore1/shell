#!/usr/bin/env bash
# =============================================================================
# uninstall.sh — Uninstall BogelShell Protect
# BogelShell Protect v2.1
# =============================================================================
set -euo pipefail

# ---- Detect environment ----------------------------------------------------
_is_termux() {
    [[ -n "${PREFIX:-}" ]] && [[ "${PREFIX}" == *"com.termux"* ]]
}

_is_openwrt() {
    [[ -f /etc/openwrt_release ]]
}

_detect_install_dir() {
    if _is_termux; then
        echo "${HOME}/.bogelshell-protect"
    elif _is_openwrt; then
        echo "/root/bogelshell-protect"
    else
        echo "/opt/bogelshell-protect"
    fi
}

_detect_bin_path() {
    if _is_termux; then
        echo "${PREFIX}/bin/bogelshell"
    elif _is_openwrt; then
        echo "/usr/bin/bogelshell"
    else
        echo "/usr/local/bin/bogelshell"
    fi
}

INSTALL_DIR="$(_detect_install_dir)"
BIN_PATH="$(_detect_bin_path)"

# ---- Color stubs (works even if lib not loaded) ----------------------------
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"
CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"
msg_ok()  { echo -e "${GREEN}[✔]${RESET} ${*}"; }
msg_err() { echo -e "${RED}[✘]${RESET} ${*}" >&2; }
msg_warn(){ echo -e "${YELLOW}[!]${RESET} ${*}"; }
msg_info(){ echo -e "${CYAN}[i]${RESET} ${*}"; }
sep()     { echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"; }

# ---- Main ------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BOLD}${CYAN}  BogelShell Protect — Uninstaller${RESET}"
    sep
    echo ""
    echo -e "  ${DIM}Install directory :${RESET} ${INSTALL_DIR}"
    echo -e "  ${DIM}Command path      :${RESET} ${BIN_PATH}"
    echo ""

    # Check if installed
    if [[ ! -d "${INSTALL_DIR}" ]] && [[ ! -f "${BIN_PATH}" ]]; then
        msg_warn "BogelShell Protect does not appear to be installed."
        exit 0
    fi

    # Confirmation
    echo -e "  ${YELLOW}${BOLD}⚠  This will remove BogelShell Protect from your system.${RESET}"
    echo -e "  ${DIM}Your personal files (encrypted/decrypted scripts) will NOT be deleted.${RESET}"
    echo ""
    echo -ne "  ${BOLD}Are you sure you want to uninstall? [y/N]${RESET} : "
    read -r confirm

    if [[ "${confirm,,}" != "y" ]]; then
        msg_warn "Uninstall cancelled."
        echo ""
        exit 0
    fi

    echo ""
    sep

    # Remove install directory
    if [[ -d "${INSTALL_DIR}" ]]; then
        echo -ne "  Removing install directory... "
        rm -rf "${INSTALL_DIR}"
        echo -e "${GREEN}done${RESET}"
    else
        msg_info "Install directory not found (already removed?)"
    fi

    # Remove global command
    if [[ -f "${BIN_PATH}" ]] || [[ -L "${BIN_PATH}" ]]; then
        echo -ne "  Removing command ${BIN_PATH}... "
        rm -f "${BIN_PATH}"
        echo -e "${GREEN}done${RESET}"
    else
        msg_info "Command not found at ${BIN_PATH} (already removed?)"
    fi

    echo ""
    sep
    msg_ok "BogelShell Protect has been successfully uninstalled."
    echo ""
    msg_info "Your encrypted/decrypted script files are untouched."
    echo ""
}

main "$@"
