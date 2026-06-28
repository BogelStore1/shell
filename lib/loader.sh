#!/usr/bin/env bash
# Runtime loader templates.

base64_decode_cmd() {
  if base64 --help 2>&1 | grep -q -- '--decode'; then
    printf "base64 --decode"
  else
    printf "base64 -d"
  fi
}
