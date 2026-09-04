# MMM visual world

<!-- impeccable:design-schema 1 -->

The durable visual authority is [MMM Design System v1](docs/design/MMM_DESIGN_SYSTEM_V1.md).

## Direction

An adaptive native wardrobe app: neutral off-white or near-black canvas, fashion imagery at center, and one expressive blue-violet-pink folded-ribbon gesture for MMM's primary moments. The experience operates like a calm personal styling tool, not a decorative fashion campaign.

## Composition

Screens use clear vertical task hierarchy, generous but purposeful negative space, 20–24pt gutters, soft rectangular surfaces, and a single strong primary CTA. Content cards are neutral. Forms and settings retain native Material affordances. The four-destination shell stays visibly labeled.

## Typography and icons

Plus Jakarta Sans carries hierarchy. Material icons provide a single accessible icon system. The supplied MMM ribbon mark and wordmark are assets in `assets/branding/`; they are not recreated as UI text or Material icons.

## Materials, color, and motion

Blue `#317DFD` to violet `#A06BEF` to pink `#F97CB0` is limited to identity, major actions, and small selected-state moments. Glass is contextual overlay material only. Motion is fast, state-led, and removed when reduced motion is requested.

## Constraints

Preserve working app behavior and use the complete design contract for accessibility, light/dark behavior, localization, semantics, and the supplied-brand-asset rule.

## Phase 1 implementation contract

Language, Welcome, and Auth share a safe-area, scrollable, max-width entry
layout that adapts to short heights and 100/135/200% text scale. The shell
owns its adaptive navigation inset; screens must not add magic bottom padding.
Auth uses typed contextual intent with `push`/`pop` semantics and validated
local return destinations. Apple remains the native platform control and
Google uses the official G asset. `MmmDialog` is the thin shared Material
confirmation-dialog primitive; rich rush results use matching surface
geometry. Legal links are external HTTPS URLs only when configured.
