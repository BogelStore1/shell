#!/usr/bin/env bash
# =============================================================================
# lib/progress.sh — Progress bar and spinner helpers
# BogelShell Protect v2.1
# =============================================================================

# Spinner frames
readonly SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
_SPINNER_PID=""

# progress_bar: draw a simple ASCII progress bar
# Usage: progress_bar <current> <total> [<label>]
progress_bar() {
    # Skip in JSON or quiet mode
    [[ "${JSON_MODE:-0}" == "1" ]]   && return
    [[ "${QUIET_MODE:-0}" == "1" ]]  && return

    local current="${1}"
    local total="${2}"
    local label="${3:-Processing}"
    local width=40
    local pct=$(( (current * 100) / (total > 0 ? total : 1) ))
    local filled=$(( (current * width) / (total > 0 ? total : 1) ))
    local empty=$(( width - filled ))

    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done

    printf "\r${CYAN}[${RESET}${GREEN}%s${RESET}${CYAN}]${RESET} ${BOLD}%s${RESET} %3d%%" \
        "${bar}" "${label}" "${pct}"

    if [[ "${current}" -ge "${total}" ]]; then
        printf "\n"
    fi
}

# spinner_start: start background spinner
# Usage: spinner_start [<label>]
spinner_start() {
    [[ "${JSON_MODE:-0}" == "1" ]]  && return
    [[ "${QUIET_MODE:-0}" == "1" ]] && return

    local label="${1:-Processing}"
    (
        local i=0
        while true; do
            printf "\r${CYAN}${SPINNER_FRAMES[i]}${RESET} ${label}..."
            i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))
            sleep 0.1
        done
    ) &
    _SPINNER_PID=$!
    disown "${_SPINNER_PID}" 2>/dev/null || true
}

# spinner_stop: stop the spinner and clear the line
spinner_stop() {
    [[ "${JSON_MODE:-0}" == "1" ]]  && return
    [[ "${QUIET_MODE:-0}" == "1" ]] && return

    if [[ -n "${_SPINNER_PID}" ]]; then
        kill "${_SPINNER_PID}" 2>/dev/null || true
        wait "${_SPINNER_PID}" 2>/dev/null || true
        _SPINNER_PID=""
    fi
    printf "\r%-60s\r" " "   # clear the spinner line
}

# separator: print a styled horizontal rule
separator() {
    [[ "${JSON_MODE:-0}" == "1" ]] && return
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
}

# section_header: print a styled section header
section_header() {
    [[ "${JSON_MODE:-0}" == "1" ]] && return
    local title="${1}"
    echo ""
    echo -e "${BOLD}${CYAN}┌─ ${title} ${RESET}"
    echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
}
