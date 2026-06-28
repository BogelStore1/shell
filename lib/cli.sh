#!/usr/bin/env bash
# =============================================================================
# lib/cli.sh — CLI argument parser for non-interactive / API mode
# BogelShell Protect v2.1
#
# Exported globals after parse_cli_args:
#   CLI_INPUT, CLI_OUTPUT, JSON_MODE, QUIET_MODE, FORCE_OVERWRITE
# =============================================================================

# Defaults
CLI_INPUT=""
CLI_OUTPUT=""
JSON_MODE="0"
QUIET_MODE="0"
FORCE_OVERWRITE="0"

# parse_cli_args: parse --input, --output, --json, --quiet, --force
# Usage: parse_cli_args "$@"
# Remaining positional args are left in CLI_EXTRA_ARGS array
parse_cli_args() {
    CLI_EXTRA_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --input|-i)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --input requires a file argument" >&2
                    exit 1
                fi
                CLI_INPUT="${2}"
                shift 2
                ;;
            --input=*)
                CLI_INPUT="${1#*=}"
                shift
                ;;
            --output|-o)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --output requires a file argument" >&2
                    exit 1
                fi
                CLI_OUTPUT="${2}"
                shift 2
                ;;
            --output=*)
                CLI_OUTPUT="${1#*=}"
                shift
                ;;
            --json|-j)
                JSON_MODE="1"
                shift
                ;;
            --quiet|-q)
                QUIET_MODE="1"
                shift
                ;;
            --force|-f)
                FORCE_OVERWRITE="1"
                shift
                ;;
            --)
                shift
                CLI_EXTRA_ARGS+=("$@")
                break
                ;;
            -*)
                echo "Error: Unknown option: ${1}" >&2
                exit 1
                ;;
            *)
                CLI_EXTRA_ARGS+=("${1}")
                shift
                ;;
        esac
    done

    export CLI_INPUT CLI_OUTPUT JSON_MODE QUIET_MODE FORCE_OVERWRITE
}

# is_cli_mode: returns 0 (true) if running with --input/--output args
is_cli_mode() {
    [[ -n "${CLI_INPUT}" || -n "${CLI_OUTPUT}" || "${JSON_MODE}" == "1" ]]
}

# show_help: display CLI usage help
show_help() {
    cat <<'HELPEOF'

Usage:
  bogelshell                           Launch interactive main menu
  bogelshell enc                       Open Encrypt Script menu
  bogelshell dec                       Open Decrypt Script menu
  bogelshell about                     Show About page
  bogelshell update                    Auto-update from GitHub
  bogelshell uninstall                 Uninstall BogelShell Protect
  bogelshell version                   Show version
  bogelshell help                      Show this help

Non-interactive / API mode:
  bogelshell enc --input <file> --output <file> [options]
  bogelshell dec --input <file> --output <file> [options]

Options:
  --input  <file>   Input script file path
  --output <file>   Output file path
  --json            Output result as JSON (for bots/APIs)
  --quiet           Suppress progress output
  --force           Overwrite output file if it exists

JSON mode examples:
  bogelshell enc --input script.sh --output script-enc.sh --json
  bogelshell dec --input script-enc.sh --output script-dec.sh --json --force

Exit codes:
  0   Success
  1   Error

HELPEOF
}
