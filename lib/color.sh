#!/usr/bin/env bash
# ANSI color library for BogelShell Protect

# Disable colors when NO_COLOR is set.
if [ -n "${NO_COLOR:-}" ]; then
  BLUE=""; GREEN=""; CYAN=""; YELLOW=""; RED=""; BOLD=""; RESET=""
else
  BLUE="\033[34m"
  GREEN="\033[32m"
  CYAN="\033[36m"
  YELLOW="\033[33m"
  RED="\033[31m"
  BOLD="\033[1m"
  RESET="\033[0m"
fi

info() { printf "%b[INFO]%b %s\n" "$CYAN" "$RESET" "$*"; }
success() { printf "%b[SUCCESS]%b %s\n" "$GREEN" "$RESET" "$*"; }
warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$RESET" "$*"; }
error() { printf "%b[ERROR]%b %s\n" "$RED" "$RESET" "$*" >&2; }
