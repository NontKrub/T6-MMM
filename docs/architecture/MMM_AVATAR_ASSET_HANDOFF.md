# MMM Avatar Asset Handoff

Status: waiting for external production-quality source assets.

The local procedural V2 experiment was archived after failing the visual art
gate. Do not use it as a production substitute.

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
