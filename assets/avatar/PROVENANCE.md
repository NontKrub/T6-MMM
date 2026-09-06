# MMM Avatar Asset Provenance

These assets are generated entirely by the owned procedural Blender
pipeline in `tools/avatar/build_avatar.py`. No external character,
garment, texture, or unknown-license model is used.

- Creator: Mix Match Mood project
- Creation method: Blender 4.5.9 LTS Python procedural meshes
- License: project-owned source generated for MMM
- Version: avatar v1
- Generation script: tools/avatar/build_avatar.py
- Generation date: 2026-09-05T08:37:19+00:00
- Geometry: low-poly rounded primitives with a shared human armature
- Runtime representation: named material groups with metadata-applied color/material state

## Generated assets

### human_female_v1.glb
- Origin: procedural MMM Blender scene (female body proportions)
- File size: 651576 bytes
- SHA-256: 075eac1fea5e2e40c74535e676b68b36e1e978199db4cc7fc24154d6defa070d
- Validation: committed output passed `tools/avatar/validate_assets.sh` with zero glTF errors/warnings and required material/animation checks

### human_male_v1.glb
- Origin: procedural MMM Blender scene (male body proportions)
- File size: 651552 bytes
- SHA-256: c00df9f16d0dbcfb2447625c2d1a224f530ce4bf213d8aef8cf9ba3d5082dcc7
- Validation: committed output passed `tools/avatar/validate_assets.sh` with zero glTF errors/warnings and required material/animation checks

## Catalog scope

- Garment templates: hat, regular_tee, fitted_top, oversized_top, shirt_blouse, sweater_hoodie, jacket, blazer, coat, regular_pants, slim_pants, wide_leg_pants, shorts, skirt, straight_dress, a_line_dress, sneaker, dress_shoe, boot, bag, accessory
- Animations: idle, blink, wave, look, outfit_reveal
- Human models use the same bone names and template material namespaces.
- Wardrobe photographs are not embedded in these GLBs and are never treated as exact 3D reconstruction.
