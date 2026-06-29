#!/usr/bin/env bash
# =============================================================================
# modules/about.sh — About Page
# BogelShell Protect v2.1
# =============================================================================

show_about() {
    show_logo

    echo -e "${BOLD}${CYAN}  ┌────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${CYAN}  │           About BogelShell Protect             │${RESET}"
    echo -e "${BOLD}${CYAN}  └────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}Name      :${RESET} BogelShell Protect"
    echo -e "  ${BOLD}Version   :${RESET} ${CYAN}${BS_VERSION}${RESET}"
    echo -e "  ${BOLD}Author    :${RESET} BogelStore"
    echo -e "  ${BOLD}Website   :${RESET} https://github.com/BogelStore1/shell"
    echo -e "  ${BOLD}License   :${RESET} MIT"
    echo ""
    separator
    echo ""
    echo -e "  ${BOLD}${YELLOW}What is BogelShell Protect?${RESET}"
    echo ""
    echo -e "  BogelShell Protect is a Bash shell script ${CYAN}obfuscation tool${RESET}."
    echo -e "  It encodes your scripts to deter casual reading and protect"
    echo -e "  your logic from being easily copied or modified."
    echo ""
    separator
    echo ""
    echo -e "  ${BOLD}${RED}⚠  Disclaimer — Important${RESET}"
    echo ""
    echo -e "  ${DIM}• This tool provides OBFUSCATION, not strong encryption.${RESET}"
    echo -e "  ${DIM}• A skilled Bash user may be able to reverse it.${RESET}"
    echo -e "  ${DIM}• Do NOT use this to protect passwords, API keys, or${RESET}"
    echo -e "  ${DIM}  truly sensitive secrets.${RESET}"
    echo -e "  ${DIM}• For sensitive data, use proper secret management tools.${RESET}"
    echo ""
    separator
    echo ""
    echo -e "  ${BOLD}How it works:${RESET}"
    echo ""
    echo -e "  ${DIM}Encrypt:${RESET}  source → gzip → base64 → rev → self-extracting script"
    echo -e "  ${DIM}Decrypt:${RESET}  payload → rev → base64 decode → gunzip → source"
    echo ""
    echo -e "  ${BOLD}Supported platforms:${RESET}"
    echo -e "  ${DIM}Linux (Ubuntu, Debian, CentOS, AlmaLinux, Rocky), OpenWRT, Termux${RESET}"
    echo ""
    echo -e "  ${BOLD}Dependencies:${RESET}"
    echo -e "  ${DIM}bash, git, base64, gzip, rev, awk, sed, grep, chmod${RESET}"
    echo ""
    separator
    echo ""

    if [[ "${JSON_MODE:-0}" != "1" ]]; then
        read -rp "  Press Enter to return to menu..."
    fi
}
