# MMM Avatar Art Direction V2

Status: production contract for the V3 avatar pack.

The avatar is an original MMM mascot for a personal fashion app. It must feel
like a premium soft-toy/clay character: friendly, calm, expressive, and
fashion-aware. The attached user reference is the visual north star for face
scale, softness, and finish. It is reference material only; it is not copied
as a character, logo, or production asset.

## Character

- Overall height: approximately 3.7–4.2 head heights.
- Head: oversized, broad forehead, rounded cheeks, softly tapered jaw.
- Body: short torso, soft medium shoulders, gently tapered limbs, shortened
  legs, rounded hands and feet.
- Face: oval dark eyes, thick simple brows, tiny rounded nose, subtle small
  smile, slightly enlarged ears.
- Surface: smooth natural silhouettes; no pores, veins, detailed eyelashes,
  realistic teeth, or photoreal scan detail.

Female and male bases share the same face language, head scale, material
treatment, rig, and MMM identity. Body proportions vary subtly; they are not
separate character families.

## Hair

Six public styles remain stable: tousled, side swept, undercut/short, long,
ponytail, and bob. Each style uses a continuous scalp mass plus deliberate
directional locks. Hair is chunky, sculpted, smooth, and readable at phone
size. The ponytail has a visible tie, connected root, and tapered curved tail;
it is not a stretched sphere or an attached blob.

## Clothing

The authored pack exposes the existing template vocabulary:

`hat`, `regular_tee`, `fitted_top`, `oversized_top`, `shirt_blouse`,
`sweater_hoodie`, `jacket`, `blazer`, `coat`, `regular_pants`, `slim_pants`,
`wide_leg_pants`, `shorts`, `skirt`, `straight_dress`, `a_line_dress`,
`sneaker`, `dress_shoe`, `boot`, `bag`, and `accessory`.

Garments are body-relative surfaces with smooth shoulders, sleeves, waist,
hems, and transitions. Fitted garments follow the body with a small offset;
oversized garments widen the silhouette and drop the shoulder; dresses and
skirts use clean circular/elliptical topology. No garment is a visible box,
cone, or rigid block.

Every garment material has predictable UVs. `frontDecalRect` is declared in
the catalog and is measured in normalized UV coordinates. Dart never guesses
decal placement.

## Shading and lighting

- Soft PBR with high-ish roughness and restrained specular response.
- Skin reads soft and warm, never waxy.
- Hair reads matte-to-satin, never mirror-like.
- Metallic response is reserved for small accessories.
- Lighting uses a soft frontal key, gentle upper-side fill, neutral
  environment, and subtle grounding/contact shadow.
- No neon rim light, purple aura, sci-fi platform, or giant glow ring.

## Rig and animation contract

The shared armature keeps these bones:

`root`, `pelvis`, `spine_01`, `spine_02`, `chest`, `neck`, `head`,
`clavicle_L/R`, `upper_arm_L/R`, `lower_arm_L/R`, `hand_L/R`,
`upper_leg_L/R`, `lower_leg_L/R`, `foot_L/R`, and `toe_L/R`.

Required clips: `idle`, `blink`, `wave`, `look`, and `outfit_reveal`.

## Runtime framing

Home mode favors head-to-thigh framing so the avatar is a visual hero without
turning home into a 3D showcase. Horizontal orbit is constrained to about
±40°; vertical orbit is strongly constrained; zoom and pan are disabled.
Customization may offer a fuller view.

Interaction is state-led: subtle idle breathing, occasional blink/look, a
cooldown-limited tap response, controlled horizontal drag, and one
`outfit_reveal` only when the outfit fingerprint changes. Reduced Motion
removes idle, spontaneous look, float, reveal flourish, and camera easing but
keeps essential state updates and usable drag.

## Performance and review gate

- One optimized GLB per body base; no per-shirt GLB loads.
- Target: 12–15 MB maximum per pack, preferably smaller.
- Target: ≤120k triangles in the pack and preferably ≤50k for one visible body
  plus outfit.
- Derived wardrobe textures are 256×256 or 512×512, never 2K by default.
- Twenty outfit swaps must cause zero base-model reloads.

Required review renders: female and male front, three-quarter, side, and back;
female ponytail, oversized tee, dress; male hoodie and wide-leg pants.

Reject the pack if it has an obvious cube torso, cylindrical limbs,
floating facial parts, sphere-blob hair, broken shoulder transitions, rigid
clothing blocks, a small head, uncanny realism, or no clear improvement over
V1. If two serious authored iterations fail this gate, stop. Do not ship the
procedural mannequin.

## Reference brief

MMM 3D Avatar Reference: Create an original stylized 3D human mascot for a
modern mobile fashion application. Use a smooth toy-like/clay-like character
with an oversized head, roughly four-heads-tall overall proportions, rounded
cheeks, softly tapered jaw, simple black oval eyes, thick soft eyebrows, tiny
rounded nose, subtle smile, slightly exaggerated ears, rounded hands and feet,
and chunky sculpted hair. Hair must include a polished ponytail variant. Use
smooth natural silhouettes and soft PBR shading. The result should feel
friendly, premium, contemporary, and fashion-oriented. Avoid photorealism,
voxel geometry, blocky cubes, cylindrical mannequin limbs, primitive sphere
hair, sci-fi effects, exaggerated neon lighting, or direct resemblance to any
existing copyrighted character. Produce front, three-quarter, side, and back
views on a clean neutral background. Clothing should be smooth and designed to
support interchangeable wardrobe textures, including a dedicated front-chest
UV region for uploaded graphics.

For the feminine and masculine bases: Keep the same facial design language,
head scale, material treatment, rig conventions, and overall MMM identity.
Vary body proportions subtly rather than making them look like unrelated
character families.
