# MMM Design System v1

## Status and scope

This is the source of truth for the MMM presentation layer. It applies to every Flutter screen, sheet, dialog, and state. Existing business logic, providers, persistence, Supabase contracts, guest accounts, and localization behavior remain outside this document's change scope.

**Brand assets.** The supplied ribbon sheet is the approved visual source for
this implementation. `assets/branding/` contains transparent raster crops of
the mark and wordmark, plus a square app-icon source. `MmmBrandMark` and
`MmmBrandWordmark` select the light or dark supplied variant from the active
theme. Native launcher variants use a white square in light appearance and the
near-black `#0B0C0F` square in dark appearance. Replace the raster files with original transparent/vector exports when
available, without changing their filenames. Do not trace or redraw the mark,
or use `checkroom_rounded` as MMM identity.

## Visual direction

Neutral canvas gives garment imagery and MMM's ribbon gradient room to lead. Geometry is soft but structured; typography is confident and readable. The memorable element is the restrained blue-to-violet-to-pink ribbon accent, never a page-wide gradient or a rainbow component kit.

## Tokens

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F8F8FA` | `#0B0C0F` |
| Surface | `#FFFFFF` | `#15161B` |
| Secondary surface | `#F1F1F5` | `#1C1D23` |
| Primary text | `#111114` | `#F8F8FA` |
| Secondary text | `#6E6E78` | `#A3A3AD` |
| Border | `#E5E5EB` | `#2B2C33` |

Brand gradient: `#317DFD` (blue), `#A06BEF` (violet), `#F97CB0` (pink). Supporting indigo: `#4851E8`.

Brand colors come from `MmmBrandTheme`, `ColorScheme`, or a shared component. Feature UI must not introduce literal brand colors. Domain garment colors and semantic success/warning/destructive colors remain permitted when meaningful.

Amber only communicates warning or pending state. It is not an MMM accent. Use one neutral icon tint for ordinary settings and navigation; reserve red, amber, and green for semantics.

## Layout and geometry

Spacing scale: `4, 8, 12, 16, 20, 24, 32, 40, 48`.

- Screen gutter: 20pt; onboarding and auth: 24pt.
- Compact controls: 12pt radius; inputs/buttons: 16pt; cards: 20pt; emphasized cards: 24pt; sheets: 28–32pt.
- Primary and secondary CTAs: 52pt high, never smaller than the platform target requirement.
- Use safe areas. Keep navigation, sticky CTAs, sheets, and keyboard-visible controls unobscured.

## Typography and icons

Use Plus Jakarta Sans through the app theme. Preserve its Thai fallback unless validation demonstrates a readability fault; then add an explicit Thai fallback without changing hierarchy.

| Style | Size / line height / weight |
| --- | --- |
| Hero | 32 / 38 / bold |
| Page title | 28 / 34 / bold |
| Large section | 22 / 28 / semibold |
| Section title | 18 / 24 / semibold |
| Body | 16 / 23 / regular |
| Small body | 14 / 20 / regular |
| Button | 16 / 20 / semibold |
| Caption | 12 / 16 / medium |
| Micro | 11 / 14 / medium |

Use Material icons with consistent 20–24pt visual size. Icons require a label where appearance alone does not convey the action. Brand marks are supplied assets, not text or a Material icon.

## Components

- `MmmGradientButton`: single primary action; white foreground; MMM gradient; disabled state stays visibly unavailable.
- `MmmSecondaryButton`: neutral tonal or outlined alternative; matches primary height and radius.
- `MmmSurfaceCard`: neutral surface, subtle border, no default heavy shadow.
- `MmmChoiceChip`: a calm selected tint/border/check, not a neon solid fill.
- `MmmBottomSheet` and `MmmDialog`: consistent top geometry, handle, safe-area padding, and explicit destructive treatment.
- `MmmEmptyState`, `MmmErrorState`, and `MmmLoadingIndicator`: action-oriented, calm, localizable, and reusable.

Prefer Material controls (`FilledButton`, `OutlinedButton`, `IconButton`, `InkWell`) for semantics, focus, disabled treatment, and press feedback. Avoid wrappers that encode no shared invariant.

## State, image, and motion rules

Garment images dominate wardrobe and outfit result cards. Keep surrounding surfaces neutral. Analysis suggestions state uncertainty and retain manual recovery on failure.

- 120–160ms: press/state feedback
- 180–220ms: selection changes
- 250–300ms: content, route, and sheet transitions
- Curve: `Curves.easeOutCubic`

No decorative elastic animation, long startup choreography, or cascading list stagger. Honor disabled/reduced-animation accessibility settings by removing decorative motion.

## Navigation, sheets, and glass

The shell has four named destinations with icon and localized label. Selection uses a restrained brand tint/background, never a rainbow item color. Glass is reserved for overlays above imagery, bottom navigation, and modal context—not ordinary forms, settings rows, or content cards.

## Accessibility contract

- Semantic label and meaningful state for every important control.
- Minimum 44×44pt iOS and 48×48dp Android target guidance.
- Support 100%, 135%, and practical 200% text scaling without hiding critical actions.
- Maintain contrast in both themes; do not place long reading text on a gradient.
- Preserve logical screen-reader order, keyboard-safe sticky actions, visible focus/pressed states, and reduced motion.

## Correct / incorrect use

Correct: a single gradient “Generate an outfit” CTA on a neutral home surface.

Incorrect: gradient card, gradient chip, gradient header, and gradient navigation item on the same screen.

Correct: red only for destructive account/item actions; amber only for warnings.

Incorrect: gold rush CTA, multicolor settings icons, or arbitrary category accents used as branding.

Correct: regular neutral cards for settings, form rows, wardrobe items, loading, error, and empty states.

Incorrect: default frosted glass for every card or a custom one-off radius/color to solve a local layout problem.
