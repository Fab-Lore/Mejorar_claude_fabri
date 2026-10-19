#!/usr/bin/env bash
# session-band · usage statusline
#
# Claude Code pipes the session JSON to the status line command on stdin. On a
# Claude.ai subscription it carries `rate_limits.five_hour` (the 5-hour session
# limit) and `rate_limits.seven_day` (the weekly one), each with
# `used_percentage` and `resets_at` (Unix seconds).
#
# This script does two things with them:
#   1. prints a status line:  Sesión ▕██████░░░░▏ 68% · se restablece en 2 h 43 min · Semana 12%
#   2. saves them to ~/.claude/session-band-usage.json, which the session-band
#      mod reads to draw the same meter in its band above the prompt.
#
# Needs jq for the nicest parsing; without it a plain sed fallback is used.

input=$(cat)
out_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/session-band-usage.json"
now=$(date +%s)

num() { # num <section> <field>: a number from rate_limits.<section>.<field>, or empty
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r ".rate_limits.$1.$2 // empty" 2>/dev/null
  else
    printf '%s' "$input" | tr -d ' \n\r\t' \
      | grep -o "\"$1\":{[^}]*}" | grep -o "\"$2\":[0-9.]*" | head -1 | cut -d: -f2
  fi
}

five_pct=$(num five_hour used_percentage)
five_reset=$(num five_hour resets_at)
week_pct=$(num seven_day used_percentage)
week_reset=$(num seven_day resets_at)

# Hand the numbers to the band (written atomically so it never reads half a file).
if [ -n "$five_pct$week_pct" ]; then
  tmp="$out_file.$$"
  printf '{"updatedAt":%s,"five":%s,"week":%s}\n' "$now" \
    "$( [ -n "$five_pct" ] && printf '{"pct":%s,"resetsAt":%s}' "$five_pct" "${five_reset:-0}" || printf null )" \
    "$( [ -n "$week_pct" ] && printf '{"pct":%s,"resetsAt":%s}' "$week_pct" "${week_reset:-0}" || printf null )" \
    > "$tmp" 2>/dev/null && mv -f "$tmp" "$out_file" 2>/dev/null
fi

# Nothing to show (API key, no answer yet): print nothing.
[ -z "$five_pct" ] && [ -z "$week_pct" ] && exit 0

until_text() { # until_text <unix seconds>: "2 h 43 min"
  local left=$(( $1 - now ))
  [ "$left" -lt 0 ] && left=0
  local h=$(( left / 3600 )) m=$(( (left % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then printf '%d h %d min' "$h" "$m"; else printf '%d min' "$m"; fi
}

bar() { # bar <percent>: a 10-cell bar colored by how full it is
  local pct=${1%.*} width=10 color
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100
  local filled=$(( pct * width / 100 ))
  if [ "$pct" -ge 90 ]; then color='\033[38;5;203m'      # red
  elif [ "$pct" -ge 75 ]; then color='\033[38;5;214m'    # amber
  else color='\033[38;5;69m'; fi                          # blue
  local i out="$color"
  for (( i = 0; i < width; i++ )); do
    [ "$i" -eq "$filled" ] && out="$out\033[38;5;238m"
    out="$out█"
  done
  printf '%s\033[0m' "$out"
}

line=""
if [ -n "$five_pct" ]; then
  line="Sesión $(bar "$five_pct") $(printf '%.0f' "$five_pct")%"
  [ -n "$five_reset" ] && line="$line · se restablece en $(until_text "$five_reset")"
fi
if [ -n "$week_pct" ]; then
  [ -n "$line" ] && line="$line · "
  line="${line}Semana $(printf '%.0f' "$week_pct")%"
fi
printf '%b' "$line"
