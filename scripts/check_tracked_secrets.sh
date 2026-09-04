#!/usr/bin/env bash
set -euo pipefail

apple_private_key_name='APPLE_PRIVATE_KEY'
patterns="^[[:space:]]*-----BEGIN [A-Z ]*PRIVATE KEY-----|SUPABASE_SERVICE_ROLE_KEY=(sb_secret_|eyJ)|${apple_private_key_name}=-----BEGIN|OPENAI_API_KEY=(sk-|rk-)|OPENROUTER_API_KEY=(sk-or-|sk-)"
matches="$(git grep -I -l -E -e "$patterns" -- ':!pubspec.lock' ':!*.lock' || true)"

if [[ -n "$matches" ]]; then
  echo "Tracked files contain prohibited credential material:" >&2
  printf '%s\n' "$matches" >&2
  exit 1
fi

echo "Tracked-secret guard passed."
