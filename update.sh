#!/usr/bin/env bash
# =============================================================================
# update.sh — Auto-update BogelShell Protect from GitHub
# BogelShell Protect v2.1
# =============================================================================
set -euo pipefail

readonly BS_REPO_URL="https://github.com/BogelStore1/shell.git"

# ---- Detect install dir (same logic as main.sh) ----------------------------
_detect_install_dir() {
    if [[ -n "${PREFIX:-}" ]] && [[ "${PREFIX}" == *"com.termux"* ]]; then
        echo "${HOME}/.bogelshell-protect"
    elif [[ -f /etc/openwrt_release ]]; then
        echo "/root/bogelshell-protect"
    else
        echo "/opt/bogelshell-protect"
    fi
}

INSTALL_DIR="$(_detect_install_dir)"

# ---- Load color lib if available -------------------------------------------
if [[ -f "${INSTALL_DIR}/lib/color.sh" ]]; then
    # shellcheck source=/dev/null
    source "${INSTALL_DIR}/lib/color.sh"
else
    # Minimal stubs
    RED=""  GREEN=""  YELLOW=""  CYAN=""  BOLD=""  RESET=""
    msg_ok()   { echo "[OK] ${*}"; }
    msg_err()  { echo "[ERR] ${*}" >&2; }
    msg_info() { echo "[i] ${*}"; }
    msg_step() { echo "[>] ${*}"; }
    msg_warn() { echo "[!] ${*}"; }
    separator() { echo "------------------------------------------------------------"; }
fi

# ---- Main update logic -----------------------------------------------------
main() {
    echo ""
    echo -e "${BOLD}${CYAN}  BogelShell Protect — Auto Updater${RESET}"
    separator
    echo ""

    # Check git is available
    if ! command -v git &>/dev/null; then
        msg_err "git is not installed. Cannot update."
        exit 1
    fi

    # Check install dir exists
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        msg_err "Install directory not found: ${INSTALL_DIR}"
        msg_info "Run the installer first: bash install.sh"
        exit 1
    fi

    # Check if it's a git repo
    if [[ ! -d "${INSTALL_DIR}/.git" ]]; then
        msg_warn "Install directory is not a git repo. Re-installing..."
        msg_step "Backing up install dir..."
        local backup="${INSTALL_DIR}.bak.$(date +%s)"
        mv "${INSTALL_DIR}" "${backup}" || true
        msg_info "Backup saved to: ${backup}"

        msg_step "Cloning fresh copy from GitHub..."
        if git clone "${BS_REPO_URL}" "${INSTALL_DIR}"; then
            chmod +x "${INSTALL_DIR}"/*.sh "${INSTALL_DIR}/modules"/*.sh \
                     "${INSTALL_DIR}/lib"/*.sh 2>/dev/null || true
            msg_ok "Re-install complete!"
        else
            msg_err "Clone failed. Restoring backup..."
            mv "${backup}" "${INSTALL_DIR}" || true
            exit 1
        fi
        return 0
    fi

    # Check for upstream changes
    msg_step "Fetching latest from GitHub..."
    cd "${INSTALL_DIR}" || exit 1

    git fetch origin 2>/dev/null || {
        msg_err "Failed to fetch from GitHub. Check your internet connection."
        exit 1
    }

    local local_rev remote_rev
    local_rev="$(git rev-parse HEAD 2>/dev/null)"
    remote_rev="$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)"

    if [[ "${local_rev}" == "${remote_rev}" ]]; then
        msg_ok "Already up to date! (${local_rev:0:8})"
        echo ""
        exit 0
    fi

    msg_step "Updates found. Pulling..."
    if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
        chmod +x "${INSTALL_DIR}"/*.sh "${INSTALL_DIR}/modules"/*.sh \
                 "${INSTALL_DIR}/lib"/*.sh 2>/dev/null || true
        echo ""
        separator
        msg_ok "Update complete!"
        msg_info "Updated to: $(git rev-parse --short HEAD 2>/dev/null)"
        echo ""
    else
        msg_err "git pull failed. You may need to manually resolve conflicts."
        exit 1
    fi
}

main "$@"
