#!/usr/bin/env bash
# Small progress animation, compatible with Termux/OpenWRT.

progress_step() {
  # Usage: progress_step "Text..."
  local text=${1:-Processing}
  local spin='|/-\\'
  local i=0
  printf "%b%s%b " "$CYAN" "$text" "$RESET"
  while [ "$i" -lt 8 ]; do
    printf "\b%s" "${spin:$((i % 4)):1}"
    sleep 0.04 2>/dev/null || sleep 1
    i=$((i + 1))
  done
  printf "\b%bDone%b\n" "$GREEN" "$RESET"
}
