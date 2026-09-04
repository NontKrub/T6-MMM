export const aiConsentType = "third_party_ai";
export const aiConsentPolicyVersion = "2026-09-04-v1";

export function isActiveAiConsent(row: unknown, userId: string): boolean {
  if (row === null || typeof row !== "object") return false;
  const value = row as Record<string, unknown>;
  return value.user_id === userId &&
    value.consent_type === aiConsentType &&
    value.policy_version === aiConsentPolicyVersion &&
    value.revoked_at == null;
}

export async function hasAiConsent(
  supabase: { from: (table: string) => any },
  userId: string,
): Promise<boolean> {
  const { data, error } = await supabase
    .from("user_consents")
    .select("user_id,consent_type,policy_version,revoked_at")
    .eq("user_id", userId)
    .eq("consent_type", aiConsentType)
    .eq("policy_version", aiConsentPolicyVersion)
    .is("revoked_at", null)
    .limit(1);
  if (error) throw error;
  return Array.isArray(data) &&
    data.some((row) => isActiveAiConsent(row, userId));
}
