# Security boundary

`SUPABASE_PUBLISHABLE_KEY` is client configuration. It is intentionally
embedded in Flutter builds and must be protected by database grants and row
level security, not by hiding it in a custom proxy.

Privileged values stay server-side. Never put a Supabase service-role key,
OpenRouter/OpenAI credential, Apple private key, Google secret, or Facebook
secret in Flutter code, `Info.plist`, Android resources, assets, screenshots,
test fixtures, logs, or Git. Configure Edge Function secrets with
`supabase secrets set`.

The Edge Function user-scoped client may use Supabase's managed
`SUPABASE_ANON_KEY` together with the caller's JWT. That server runtime name is
separate from the mobile `SUPABASE_PUBLISHABLE_KEY` name and must not be copied
into the app.
