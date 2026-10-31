#!/usr/bin/env bash
# Detect a cua-driver installation on macOS/Linux and report machine state as JSON.
# Usage: bash detect.sh [explicit-path-to-cua-driver]
set -u

EXE=""
for c in "${1:-}" "$(command -v cua-driver 2>/dev/null || true)" "$HOME/.local/bin/cua-driver"; do
  if [ -n "${c:-}" ] && [ -x "$c" ]; then EXE="$c"; break; fi
done

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

VERSION=""; DAEMON=""; DOCTOR_FAIL=""; DOCTOR_OK=false
if [ -n "$EXE" ]; then
  VERSION="$("$EXE" --version 2>/dev/null | head -n1)"
  DAEMON="$("$EXE" status 2>/dev/null | head -n1)"
  DOCTOR_FAIL="$("$EXE" doctor 2>/dev/null | grep '\[fail\]' | head -n5)"
  [ -z "$DOCTOR_FAIL" ] && DOCTOR_OK=true
fi

FOUND=false
[ -n "$EXE" ] && FOUND=true

printf '{\n'
printf '  "platform": "%s",\n' "$(uname -s | tr '[:upper:]' '[:lower:]')"
printf '  "found": %s,\n' "$FOUND"
printf '  "exe": "%s",\n' "$(esc "$EXE")"
printf '  "version": "%s",\n' "$(esc "$VERSION")"
printf '  "doctor_ok": %s,\n' "$DOCTOR_OK"
printf '  "doctor_fail": "%s",\n' "$(esc "$DOCTOR_FAIL")"
printf '  "daemon": "%s",\n' "$(esc "$DAEMON")"
printf '  "autostart": "not-applicable-on-this-platform",\n'
printf '  "mcp_invocation": { "command": "%s", "args": ["mcp"] }\n' "$(esc "$EXE")"
printf '}\n'
