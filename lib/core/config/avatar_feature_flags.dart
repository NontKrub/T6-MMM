abstract final class AvatarFeatureFlags {
  static const enableV2WearableTextures = bool.fromEnvironment(
    'MMM_ENABLE_AVATAR_V2_TEXTURES',
    defaultValue: false,
  );
}
