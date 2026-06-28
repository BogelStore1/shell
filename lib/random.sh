#!/usr/bin/env bash
# Random helpers without external language dependencies.

_bsp_used_names=" "

random_name() {
  # Generate 3-10 character variable/function names using letters only.
  local name len
  while :; do
    len=$((3 + RANDOM % 8))
    name=$(LC_ALL=C tr -dc 'A-Za-z' </dev/urandom 2>/dev/null | head -c "$len")
    if [ -z "$name" ]; then
      name="v$RANDOM$RANDOM"
    fi
    case " $_bsp_used_names " in
      *" $name "*) continue ;;
      *) _bsp_used_names="$_bsp_used_names$name "; printf "%s" "$name"; return 0 ;;
    esac
  done
}

random_text() {
  local len=${1:-16}
  LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c "$len"
}
