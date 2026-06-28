#!/usr/bin/env bash
# Encrypt menu module.

encrypt_menu() {
  local input output
  printf "\n%bInput Script :%b " "$YELLOW" "$RESET"
  IFS= read -r input

  validate_readable_file "$input" || return 1
  require_command gzip base64 rev grep sed awk chmod || return 1

  printf "%bNama output  :%b " "$YELLOW" "$RESET"
  IFS= read -r output
  validate_output_path "$output" || return 1

  build_encrypted_script "$input" "$output"
}
