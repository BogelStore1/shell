#!/usr/bin/env bash
# =============================================================================
# lib/color.sh — ANSI color constants & helpers
# BogelShell Protect v2.1
# =============================================================================

# Disable colors when running in JSON mode or when output is not a terminal
_init_colors() {
    if [[ "${JSON_MODE:-0}" == "1" ]] || [[ ! -t 1 && "${FORCE_COLOR:-0}" != "1" ]]; then
        # No color in JSON mode or non-interactive output
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        MAGENTA=""
        WHITE=""
        BOLD=""
        DIM=""
        RESET=""
        BG_BLUE=""
        BG_CYAN=""
        BG_GREEN=""
        BG_RED=""
        BG_MAGENTA=""
    else
        RED="\033[0;31m"
        GREEN="\033[0;32m"
        YELLOW="\033[0;33m"
        BLUE="\033[0;34m"
        MAGENTA="\033[0;35m"
        CYAN="\033[0;36m"
        WHITE="\033[0;37m"
        BOLD="\033[1m"
        DIM="\033[2m"
        RESET="\033[0m"
        BG_BLUE="\033[44m"
        BG_CYAN="\033[46m"
        BG_GREEN="\033[42m"
        BG_RED="\033[41m"
        BG_MAGENTA="\033[45m"
    fi
    export RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD DIM RESET
    export BG_BLUE BG_CYAN BG_GREEN BG_RED BG_MAGENTA
}

# Colored print helpers
color_red()     { echo -e "${RED}${*}${RESET}"; }
color_green()   { echo -e "${GREEN}${*}${RESET}"; }
color_yellow()  { echo -e "${YELLOW}${*}${RESET}"; }
color_blue()    { echo -e "${BLUE}${*}${RESET}"; }
color_cyan()    { echo -e "${CYAN}${*}${RESET}"; }
color_magenta() { echo -e "${MAGENTA}${*}${RESET}"; }
color_bold()    { echo -e "${BOLD}${*}${RESET}"; }
color_dim()     { echo -e "${DIM}${*}${RESET}"; }

# Semantic helpers
msg_ok()    { [[ "${JSON_MODE:-0}" == "1" ]] && return; echo -e "${GREEN}[✔]${RESET} ${*}"; }
msg_err()   { [[ "${JSON_MODE:-0}" == "1" ]] && return; echo -e "${RED}[✘]${RESET} ${*}" >&2; }
msg_warn()  { [[ "${JSON_MODE:-0}" == "1" ]] && return; echo -e "${YELLOW}[!]${RESET} ${*}"; }
msg_info()  { [[ "${JSON_MODE:-0}" == "1" ]] && return; echo -e "${CYAN}[i]${RESET} ${*}"; }
msg_step()  { [[ "${JSON_MODE:-0}" == "1" ]] && return; echo -e "${BLUE}[»]${RESET} ${BOLD}${*}${RESET}"; }

# Initialize on source
_init_colors
