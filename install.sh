#!/usr/bin/env bash
# =============================================================================
# install.sh — BogelShell Protect v2.1 Installer
# Supports: Linux (Ubuntu/Debian/CentOS/AlmaLinux/Rocky), OpenWRT, Termux
# =============================================================================
set -euo pipefail

readonly BS_VERSION="2.1.0"
readonly BS_REPO_URL="https://github.com/BogelStore1/shell.git"

# =============================================================================
# Color setup (no external lib yet — inline)
# =============================================================================
RED="\033[0;31m";  GREEN="\033[0;32m";  YELLOW="\033[0;33m"
BLUE="\033[0;34m"; CYAN="\033[0;36m";   BOLD="\033[1m"
DIM="\033[2m";     RESET="\033[0m"

msg_ok()   { echo -e "${GREEN}[✔]${RESET} ${*}"; }
msg_err()  { echo -e "${RED}[✘]${RESET} ${*}" >&2; }
msg_warn() { echo -e "${YELLOW}[!]${RESET} ${*}"; }
msg_info() { echo -e "${CYAN}[i]${RESET} ${*}"; }
msg_step() { echo -e "${BLUE}[»]${RESET} ${BOLD}${*}${RESET}"; }
sep()      { echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"; }

# =============================================================================
# Platform detection
# =============================================================================
is_termux() {
    [[ -n "${PREFIX:-}" ]] && [[ "${PREFIX}" == *"com.termux"* ]]
}

is_openwrt() {
    [[ -f /etc/openwrt_release ]]
}

detect_platform() {
    if is_termux; then
        echo "termux"
    elif is_openwrt; then
        echo "openwrt"
    elif [[ -f /etc/os-release ]]; then
        local id
        id="$(. /etc/os-release && echo "${ID:-linux}")"
        echo "${id}"
    else
        echo "linux"
    fi
}

# Determine install paths based on platform
set_install_paths() {
    PLATFORM="$(detect_platform)"

    case "${PLATFORM}" in
        termux)
            INSTALL_DIR="${HOME}/.bogelshell-protect"
            BIN_PATH="${PREFIX}/bin/bogelshell"
            NEED_SUDO=0
            ;;
        openwrt)
            INSTALL_DIR="/root/bogelshell-protect"
            BIN_PATH="/usr/bin/bogelshell"
            NEED_SUDO=0
            ;;
        *)
            INSTALL_DIR="/opt/bogelshell-protect"
            BIN_PATH="/usr/local/bin/bogelshell"
            NEED_SUDO=1
            ;;
    esac
}

# =============================================================================
# Dependency check
# =============================================================================
check_dependencies() {
    msg_step "Checking dependencies..."
    local required=(bash git base64 gzip rev awk sed grep chmod)
    local missing=()

    for cmd in "${required[@]}"; do
        if command -v "${cmd}" &>/dev/null; then
            echo -e "  ${GREEN}✔${RESET} ${cmd}"
        else
            echo -e "  ${RED}✘${RESET} ${cmd} ${RED}(missing)${RESET}"
            missing+=("${cmd}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        msg_err "Missing dependencies: ${missing[*]}"
        echo ""
        # Platform-specific install hints
        case "${PLATFORM}" in
            termux)
                msg_info "Install via: pkg install ${missing[*]}"
                ;;
            openwrt)
                msg_info "Install via: opkg install coreutils-base64 gzip git"
                ;;
            ubuntu|debian)
                msg_info "Install via: sudo apt-get install -y ${missing[*]}"
                ;;
            centos|almalinux|rocky|rhel|fedora)
                msg_info "Install via: sudo yum install -y ${missing[*]}"
                ;;
            *)
                msg_info "Please install the missing packages using your package manager."
                ;;
        esac
        exit 1
    fi

    msg_ok "All dependencies satisfied"
}

# =============================================================================
# Clone / update repository
# =============================================================================
clone_repo() {
    msg_step "Cloning repository..."

    # Remove existing install if present
    if [[ -d "${INSTALL_DIR}" ]]; then
        msg_warn "Existing installation found at ${INSTALL_DIR}"
        echo -ne "  ${YELLOW}Overwrite? [y/N]${RESET} : "
        read -r confirm
        if [[ "${confirm,,}" != "y" ]]; then
            msg_warn "Install cancelled."
            exit 0
        fi
        msg_info "Removing old installation..."
        rm -rf "${INSTALL_DIR}"
    fi

    # Create parent directory if needed
    local parent
    parent="$(dirname "${INSTALL_DIR}")"
    if [[ "${NEED_SUDO}" == "1" ]] && [[ ! -w "${parent}" ]]; then
        msg_step "Creating ${parent} (requires sudo)..."
        sudo mkdir -p "${parent}" || {
            msg_err "Failed to create ${parent}. Try running as root."
            exit 1
        }
        sudo chown "$(whoami)" "${parent}" || true
    else
        mkdir -p "${parent}" || true
    fi

    # Clone
    if git clone "${BS_REPO_URL}" "${INSTALL_DIR}"; then
        msg_ok "Repository cloned successfully"
    else
        msg_err "git clone failed. Check your internet connection and the URL:"
        msg_info "${BS_REPO_URL}"
        exit 1
    fi
}

# =============================================================================
# Set permissions
# =============================================================================
set_permissions() {
    msg_step "Setting permissions..."

    # Make all .sh files executable
    find "${INSTALL_DIR}" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    chmod +x "${INSTALL_DIR}/main.sh" 2>/dev/null || true

    msg_ok "Permissions set"
}

# =============================================================================
# Create global command symlink/wrapper
# =============================================================================
create_command() {
    msg_step "Creating global command: bogelshell..."

    local bin_dir
    bin_dir="$(dirname "${BIN_PATH}")"

    # Create bin dir if it doesn't exist (Termux)
    mkdir -p "${bin_dir}" 2>/dev/null || true

    # Write wrapper script (more portable than symlink for env vars)
    local wrapper_content
    wrapper_content='#!/usr/bin/env bash
# BogelShell Protect — command wrapper
exec '"\"${INSTALL_DIR}/main.sh\""' "$@"'

    if [[ "${NEED_SUDO}" == "1" ]] && [[ ! -w "${bin_dir}" ]]; then
        echo "${wrapper_content}" | sudo tee "${BIN_PATH}" >/dev/null
        sudo chmod +x "${BIN_PATH}"
    else
        echo "${wrapper_content}" > "${BIN_PATH}"
        chmod +x "${BIN_PATH}"
    fi

    msg_ok "Command created: ${BIN_PATH}"
}

# =============================================================================
# Verify installation
# =============================================================================
verify_install() {
    msg_step "Verifying installation..."

    local ok=1

    if [[ ! -f "${INSTALL_DIR}/main.sh" ]]; then
        msg_err "main.sh not found in ${INSTALL_DIR}"
        ok=0
    fi

    if [[ ! -f "${BIN_PATH}" ]]; then
        msg_err "Command not found at ${BIN_PATH}"
        ok=0
    fi

    if [[ "${ok}" == "1" ]]; then
        msg_ok "Installation verified"
    else
        msg_err "Verification failed. Some files may be missing."
        exit 1
    fi
}

# =============================================================================
# Print success banner
# =============================================================================
print_success() {
    echo ""
    sep
    echo ""
    echo -e "${BOLD}${GREEN}  ✔  BogelShell Protect v${BS_VERSION} installed successfully!${RESET}"
    echo ""
    echo -e "  ${DIM}Install directory :${RESET} ${INSTALL_DIR}"
    echo -e "  ${DIM}Command           :${RESET} ${CYAN}bogelshell${RESET} → ${BIN_PATH}"
    echo -e "  ${DIM}Platform          :${RESET} ${PLATFORM}"
    echo ""
    sep
    echo ""
    echo -e "  ${BOLD}Quick start:${RESET}"
    echo ""
    echo -e "  ${CYAN}bogelshell${RESET}                              ${DIM}# open interactive menu${RESET}"
    echo -e "  ${CYAN}bogelshell enc --input script.sh --output script-enc.sh${RESET}"
    echo -e "  ${CYAN}bogelshell dec --input script-enc.sh --output script-dec.sh${RESET}"
    echo -e "  ${CYAN}bogelshell help${RESET}                         ${DIM}# show all commands${RESET}"
    echo ""

    # PATH reminder for Termux
    if is_termux; then
        echo -e "  ${YELLOW}Tip (Termux): If 'bogelshell' is not found, run:${RESET}"
        echo -e "  ${DIM}export PATH=\"\${PREFIX}/bin:\${PATH}\"${RESET}"
        echo ""
    fi

    sep
    echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║        BogelShell Protect v${BS_VERSION} — Installer            ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    set_install_paths

    echo -e "  ${DIM}Platform   :${RESET} ${PLATFORM}"
    echo -e "  ${DIM}Install to :${RESET} ${INSTALL_DIR}"
    echo -e "  ${DIM}Command    :${RESET} ${BIN_PATH}"
    echo ""
    sep
    echo ""

    check_dependencies
    echo ""
    clone_repo
    echo ""
    set_permissions
    echo ""
    create_command
    echo ""
    verify_install
    print_success
}

main "$@"
