# MMM Avatar Asset Handoff

Status: waiting for external production-quality source assets.

The local procedural V2 experiment was archived after failing the visual art
gate. Do not use it as a production substitute.

## V2 visual-reference intake

`docs/design/references/mmm_avatar_turnaround_v1.png` is the user-supplied
MMM original-avatar modeling reference. It resolves the previous absence of a
visual reference only; it is not a finished source asset or production-pack
approval. Use its front, side, back, A-pose, and three-quarter views according
to the accompanying reference note when authoring a new editable `.blend`.

Supply these files before V2 import:

- Female source: `.blend`, `.fbx`, or `.glb`
- Male source: `.blend`, `.fbx`, or `.glb`
- All referenced textures, decals, and normal/roughness maps
- License and provenance for geometry, textures, and any third-party source
- Optional unrigged source if MMM should perform rigging
- Review renders matching the V2 art direction contract, if available

Preferred handoff location is outside the shipping asset catalog until import
validation passes. The importer will produce normalized GLBs, posters, review
renders, hashes, and a staged V2 catalog. It will not activate V2 or overwrite
the V1 catalog.

Next action: provide the female and male source files plus provenance, then run
`tools/avatar/production/import_avatar_asset.py` and complete visual review.
