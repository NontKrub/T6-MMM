#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--self-test" ]]; then
  source_kind=json
  source_value='{"SUPABASE_URL":"https://example.supabase.co","SUPABASE_PUBLISHABLE_KEY":"sb_publishable_test","AUTH_REDIRECT_URL":"mmm://login-callback","PRIVACY_POLICY_URL":"https://privacy.example.test"}'
elif [[ $# -eq 1 ]]; then
  source_kind=file
  source_value=$1
else
  echo "Usage: $0 <runtime.json> | --self-test" >&2
  exit 64
fi

deno eval --allow-read '
const [kind, value] = Deno.args;
const raw = kind === "file" ? await Deno.readTextFile(value) : value;
let config;
try {
  config = JSON.parse(raw);
} catch (_) {
  throw new Error("Runtime config is not valid JSON.");
}
for (const key of [
  "SUPABASE_URL",
  "SUPABASE_PUBLISHABLE_KEY",
  "AUTH_REDIRECT_URL",
  "PRIVACY_POLICY_URL",
]) {
  if (typeof config[key] !== "string" || !config[key].trim()) {
    throw new Error(`Runtime config requires ${key}.`);
  }
}
for (const key of ["SUPABASE_URL", "PRIVACY_POLICY_URL"]) {
  let url;
  try {
    url = new URL(config[key]);
  } catch (_) {
    throw new Error(`${key} must be an HTTPS URL.`);
  }
  if (url.protocol !== "https:" || !url.hostname || url.hostname === "localhost") {
    throw new Error(`${key} must be a public HTTPS URL.`);
  }
}
const redirect = new URL(config.AUTH_REDIRECT_URL);
if (redirect.protocol !== "mmm:") {
  throw new Error("AUTH_REDIRECT_URL must use the mmm scheme.");
}
console.log("Release runtime preflight passed.");
' "$source_kind" "$source_value"
