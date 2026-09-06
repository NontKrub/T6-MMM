# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
# Run with backend (compile-time env vars required)
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=AUTH_REDIRECT_URL=mmm://login-callback

# Run in guest/mock mode (no backend)
flutter run

# Analyze
flutter analyze

# Test
flutter test
flutter test test/widget_test.dart  # single file
```

## Architecture

**Stack:** Flutter + Riverpod (state) + GoRouter (nav) + Supabase (backend) + Hive (local storage).

### Layers

```
lib/
  core/
    config/       # AppConfig — reads compile-time --dart-define values
    navigation/   # appRouter (GoRouter) — all routes defined here
    providers/    # Riverpod StateNotifierProviders (one per domain)
    services/     # Repository classes — all Supabase calls live here
    theme/        # AppColors, AppTheme, GlassContainer
  features/       # Screen-level UI, one folder per route
  shared/
    models/       # Plain Dart data classes (ClothingItem, Outfit, UserProfile, ChatMessage)
    services/     # MockData — seed data used when offline/unconfigured
    widgets/      # Reusable UI components
```

### Key patterns

- **Mock/guest mode**: `AppConfig.isSupabaseConfigured` is false when `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` are missing. Every provider catches repository errors and silently keeps mock data. Supabase is **never** initialized unless configured.
- **Provider → Repository**: providers (e.g. `wardrobeProvider`) hold state and call repositories (e.g. `WardrobeRepository`) for all persistence. Repositories talk to Supabase directly via `SupabaseService.client`.
- **Hive local storage**: manual adapters only — no code generation (`hive_generator` is not a dependency).
- **Glass UI**: use `GlassContainer` (`lib/core/theme/glass_container.dart`) only for overlays above imagery, bottom navigation, and modal context. Ordinary forms, settings, cards, and rows use neutral surfaces.
- **Models**: `ClothingItem.fromJson` maps Supabase column names; `toInsertJson` maps back for inserts. Other models follow the same pattern.

### Navigation

All routes are in `lib/core/navigation/router.dart`. The bottom-nav shell (`MainShell`) wraps `/home`, `/wardrobe`, `/missing`, and `/chat`. Full-screen routes (`/profile`, `/settings`, `/item/:id`) use `parentNavigatorKey: _rootNavigatorKey` to render above the shell.

### Backend (Supabase)

- DB schema: `supabase/migrations/202605270001_initial_backend.sql`
- Edge functions are the AI layer; they require secrets set via `supabase secrets set` (see `BACKEND_SETUP.md` for the full list).
- Outfit generation, image analysis, weather context, lucky colors, missing pieces, and fashion chat are all edge function calls — not client-side logic.

### Theme

MMM Design System v1 uses neutral canvas with a blue (`#317DFD`) to violet
(`#A06BEF`) to pink (`#F97CB0`) brand gradient. Brand values, specialized
surfaces, spacing, radii, motion, and typography are centralized in
`lib/core/theme/`; screens use theme/component tokens instead of feature-level
brand literals. Amber, green, and red are semantic-only. See
`docs/design/MMM_DESIGN_SYSTEM_V1.md`.
