# MMM Avatar Asset Contract V2

Status: import contract only. V2 is not active in the Flutter catalog.

The production character must come from an externally authored, reviewable
source asset. The archived procedural experiment under
`assets/avatar/experiments/procedural_v2/` is not a valid source.

## Deliverables

Supply two source files:

- `female_source.blend`, `.fbx`, or `.glb`
- `male_source.blend`, `.fbx`, or `.glb`

Also supply all referenced textures, a license/provenance note, and an
optional unrigged source if MMM will perform rigging. Editable `.blend` files
may remain outside Git when repository size policy requires it; the imported
GLBs and review evidence belong in the controlled asset handoff.

## Character contract

- Original MMM stylized character; no intentionally copied proprietary character
- 3.7–4.2 heads tall with an oversized head
- Soft rounded face, oval eyes, simple brows, subtle nose and mouth
- Smooth sculpted hair, including six public styles and a real ponytail
- Female-compatible and male-compatible bases share MMM face language and rig
- No voxel, cube, rigid-block, primitive-sphere hair, cylindrical mannequin,
  photoreal, or uncanny-realism treatment

## Shared rig and clips

The armature contains these exact bones:

`root`, `pelvis`, `spine_01`, `spine_02`, `chest`, `neck`, `head`,
`clavicle_L`, `clavicle_R`, `upper_arm_L`, `upper_arm_R`, `lower_arm_L`,
`lower_arm_R`, `hand_L`, `hand_R`, `upper_leg_L`, `upper_leg_R`,
`lower_leg_L`, `lower_leg_R`, `foot_L`, `foot_R`, `toe_L`, `toe_R`.

The GLB contains exactly these animation names: `idle`, `blink`, `wave`,
`look`, and `outfit_reveal`.

## Garments and materials

The shared GLB contains named garment material groups for every existing
template: `hat`, `regular_tee`, `fitted_top`, `oversized_top`, `shirt_blouse`,
`sweater_hoodie`, `jacket`, `blazer`, `coat`, `regular_pants`, `slim_pants`,
`wide_leg_pants`, `shorts`, `skirt`, `straight_dress`, `a_line_dress`,
`sneaker`, `dress_shoe`, `boot`, `bag`, and `accessory`.

Material names preserve the bridge namespace:

- `MMM_BODY__skin`
- `MMM_HAIR__style_{0..5}__base`
- `MMM_GARMENT__{template}__base`

Every supported garment mesh has a stable `TEXCOORD_0`. Top templates include
an explicit `frontDecalRect` in normalized UV coordinates. The importer rejects
missing or guessed UV metadata.

## Import gates

`tools/avatar/production/import_avatar_asset.py` validates the source GLBs,
rig, skin, animations, material namespace, UVs, posters, and required review
renders. Khronos glTF validation must report zero errors and warnings.

The import output is staged outside the active catalog. Hashes and the staged
V2 catalog are written only with an explicit visual approval flag after review
renders pass the art direction contract. Activation remains a separate catalog
change after product review.

Required renders: female and male front, three-quarter, side, and back;
female ponytail, oversized tee, and dress; male hoodie and wide-leg pants.

## Runtime boundary

`AvatarAssetCatalog.activeVersion` remains `AvatarAssetVersion.v1` until the
external pack passes the visual gate. Switching to V2 must change the catalog
selection only; renderer, bridge, wardrobe, and accessibility contracts must
remain unchanged.
