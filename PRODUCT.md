# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

People choosing outfits from clothes they already own, including first-time users who need value before creating an online account.

## Product Purpose

Mix Match Mood (MMM) helps people catalogue a wardrobe, understand individual pieces, and choose outfits that suit their mood, style, context, and preferences.

## Positioning

MMM combines a personal wardrobe with outfit generation, quick/rush suggestions, gap recommendations, and a fashion assistant while retaining a usable local guest path.

## Operating Context

Native Flutter app for iOS and Android. People add garment photos, review suggested metadata, browse their wardrobe, generate outfits, manage preferences, and optionally sign in to use configured cloud features.

## Capabilities and Constraints

- Preserve Riverpod, GoRouter, Supabase, local guest persistence, existing routes, business logic, migrations, and security behavior.
- Add `/welcome`; preserve existing routes unless a UI requirement makes a change necessary.
- English and Thai, light and dark themes, Dynamic Type/text scaling, reduced motion, and accessible tap targets are release requirements.
- The approved MMM brand sheet is implemented as transparent raster mark/wordmark assets under `assets/branding/`; replace them with original vector exports when supplied.

## Brand Commitments

The approved visual principle is neutral canvas, expressive blue-violet-pink MMM gradient, soft geometry, strong readable typography, and fashion-first content. The visual redesign replaces the prior purple-and-gold/glass-forward identity.

## Evidence on Hand

- Flutter source, tests, production-readiness checks, and existing image assets are in this repository.
- User-supplied MMM brand sheet is visual reference.
- No original transparent/vector master export is included yet; the approved sheet-derived raster assets are the current implementation source.

## Product Principles

1. Let users create value from a local wardrobe before sign-in.
2. Keep automatic intelligence reviewable and recoverable with manual correction.
3. Make fashion content and garment imagery more prominent than interface decoration.
4. Keep destructive, permission, consent, and authentication actions explicit.
5. Use one coherent design system across every product state.

## Accessibility & Inclusion

Support VoiceOver/TalkBack semantics, iOS 44pt and Android 48dp target guidance, contrast, text scaling, keyboard-safe forms, reduced motion, English, and Thai.
