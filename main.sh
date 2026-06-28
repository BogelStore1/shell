#!/usr/bin/env bash
# =========================================================
# BogelShell Protect v2.0
# Bash Script Encrypt & Decrypt Utility
# Author: Bogel Project
# =========================================================

set -u

APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Load libraries
# shellcheck source=/dev/null
. "$APP_DIR/lib/color.sh"
# shellcheck source=/dev/null
. "$APP_DIR/lib/progress.sh"
# shellcheck source=/dev/null
. "$APP_DIR/lib/random.sh"
# shellcheck source=/dev/null
. "$APP_DIR/lib/validate.sh"
# shellcheck source=/dev/null
. "$APP_DIR/lib/loader.sh"
# shellcheck source=/dev/null
. "$APP_DIR/lib/builder.sh"

# Load modules
# shellcheck source=/dev/null
. "$APP_DIR/modules/encrypt.sh"
# shellcheck source=/dev/null
. "$APP_DIR/modules/decrypt.sh"
# shellcheck source=/dev/null
. "$APP_DIR/modules/about.sh"

pause_screen() {
  printf "\n%bTekan ENTER untuk kembali ke menu...%b" "$YELLOW" "$RESET"
  IFS= read -r _dummy || true
}

clear_screen() {
  if [ -n "${TERM:-}" ] && command -v clear >/dev/null 2>&1; then clear; else printf "\033c"; fi
}

show_logo() {
  printf "%b" "$BLUE$BOLD"
  if [ -r "$APP_DIR/assets/logo.txt" ]; then
    cat "$APP_DIR/assets/logo.txt"
  else
    cat <<'LOGO'
=========================================================
                BOGELSHELL PROTECT
        Bash Script Encrypt & Decrypt Utility
=========================================================

Version : 2.0
Author  : Bogel Project
LOGO
  fi
  printf "%b\n" "$RESET"
}

show_menu() {
  printf "%b┌──────────────────────────────────────────────┐%b\n" "$CYAN" "$RESET"
  printf "%b│%b              %bMAIN MENU%b                       %b│%b\n" "$CYAN" "$RESET" "$BOLD$GREEN" "$RESET" "$CYAN" "$RESET"
  printf "%b├──────────────────────────────────────────────┤%b\n" "$CYAN" "$RESET"
  printf "%b│%b 1. Encrypt Bash Script                       %b│%b\n" "$CYAN" "$YELLOW" "$CYAN" "$RESET"
  printf "%b│%b 2. Decrypt Bash Script                       %b│%b\n" "$CYAN" "$YELLOW" "$CYAN" "$RESET"
  printf "%b│%b 3. About                                     %b│%b\n" "$CYAN" "$YELLOW" "$CYAN" "$RESET"
  printf "%b│%b 4. Exit                                      %b│%b\n" "$CYAN" "$YELLOW" "$CYAN" "$RESET"
  printf "%b└──────────────────────────────────────────────┘%b\n" "$CYAN" "$RESET"
}

exit_animation() {
  local msg="Thank you for using BogelShell Protect."
  local i char
  printf "\n%b" "$GREEN"
  i=0
  while [ "$i" -lt "${#msg}" ]; do
    char=${msg:$i:1}
    printf "%s" "$char"
    sleep 0.02 2>/dev/null || true
    i=$((i + 1))
  done
  printf "%b\n" "$RESET"
}

main_loop() {
  local choice
  while :; do
    clear_screen
    show_logo
    show_menu
    printf "%bPilih menu [1-4]:%b " "$BOLD$CYAN" "$RESET"
    IFS= read -r choice || exit 0
    case "$choice" in
      1) encrypt_menu; pause_screen ;;
      2) decrypt_menu; pause_screen ;;
      3) about_menu; pause_screen ;;
      4) exit_animation; exit 0 ;;
      *) error "Pilihan tidak valid."; pause_screen ;;
    esac
  done
}

main_loop "$@"
