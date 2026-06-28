#!/usr/bin/env bash
# Validation helpers.

require_command() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      error "Command tidak ditemukan: $cmd"
      return 1
    fi
  done
}

validate_readable_file() {
  local file=$1
  if [ -z "$file" ]; then
    error "Nama file kosong."
    return 1
  fi
  if [ ! -e "$file" ]; then
    error "File tidak ditemukan."
    return 1
  fi
  if [ ! -f "$file" ]; then
    error "Bukan file biasa: $file"
    return 1
  fi
  if [ ! -s "$file" ]; then
    error "File kosong."
    return 1
  fi
  if [ ! -r "$file" ]; then
    error "Permission ditolak saat membaca file: $file"
    return 1
  fi
}

validate_output_path() {
  local file=$1
  local dir
  if [ -z "$file" ]; then
    error "Nama output kosong."
    return 1
  fi
  dir=$(dirname -- "$file")
  if [ ! -d "$dir" ]; then
    error "Folder output tidak ditemukan: $dir"
    return 1
  fi
  if [ ! -w "$dir" ]; then
    error "Permission ditolak saat menulis ke folder: $dir"
    return 1
  fi
}
