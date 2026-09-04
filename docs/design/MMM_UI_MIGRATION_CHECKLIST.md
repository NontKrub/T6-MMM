# MMM UI Migration Checklist

Use this checklist as the delivery gate for MMM Design System v1. Check an item only with automated or Device Hub evidence.

Current branch evidence covers the checked implementation and automated gates. The remaining unchecked items require real light/dark and Thai visual crawl evidence, screenshots/goldens, and the production-readiness workflow.

## Foundation

- [x] `MmmBrandTheme`, colors, spacing, radii, typography, and motion tokens exist.
- [x] Shared buttons, cards, choice controls, approved brand mark assets, empty/error/loading states, sheets, and dialogs encode documented invariants.
- [x] `pubspec.yaml` declares `assets/branding/`.
- [x] `CLAUDE.md` and `AGENTS.md` link this design system and remove purple/gold as the active identity.
- [x] Every legacy literal found by the required searches has an intentional disposition.

## Entry and routing

- [x] Splash routes immediately after required state resolves: language, welcome, onboarding, or home.
- [x] `/welcome` provides local guest onboarding and sign-in paths.
- [x] Language uses full-width selection rows and returns to settings when opened there.
- [x] Auth preserves provider logic, migration, loading, disabled, error, and deep-link behavior.
- [x] Onboarding keeps its state layer and presents one coherent question per step.

## Product surfaces

- [x] Shell navigation keeps `nav-/home`, `nav-/wardrobe`, `nav-/missing`, and `nav-/chat` keys.
- [x] Home, wardrobe, item detail, outfit generator, rush, missing pieces, chat, profile, and settings follow design-system components.
- [x] Add Item keeps `add-item-image-picker`, `add-item-name`, and `add-item-save`; analysis failure supports manual completion.
- [x] Loading, empty, error, permission, consent, signed-out, and destructive states are intentional and actionable.

## Localization and accessibility

- [x] New visible copy is in English and Thai ARB files; generated localization files are regenerated, not hand-edited.
- [ ] Light/dark and English/Thai work for all migrated surfaces.
- [ ] Semantics, iOS/Android tap targets, contrast, and large-text checks pass.
- [ ] Reduce Motion, keyboard, safe-area, sheet, and back-navigation behavior are verified.

## Evidence gates

- [x] Focused widget/unit tests cover design system, welcome, auth, onboarding, navigation, accessibility, and dark mode.
- [x] Existing integration tests are preserved and updated for splash-to-welcome.
- [x] Guest path integration test covers language, welcome, guest onboarding, home, wardrobe, and Add Item.
- [x] `dart format lib test integration_test`, `flutter analyze`, `flutter test`, and `flutter build ios --simulator` pass.
- [ ] Production-readiness workflow checks pass without weakening checks.
- [ ] Device Hub crawl has PASS/FAIL/BLOCKED evidence by device, language, and theme.
- [ ] Screenshots exist for welcome, auth, onboarding, home, wardrobe, Add Item, generator, missing pieces, chat, profile, and settings.
