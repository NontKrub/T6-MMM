# MMM avatar asset pipeline

`build_avatar.py` generates the owned human avatar runtime assets used by the
Phase 2 renderer. It is deliberately procedural: the app maps wardrobe
metadata to a named garment template and applies the real item color/material
at runtime. A wardrobe photograph is not treated as an exact 3D garment
reconstruction.

## Generate

From the repository root:

```bash
blender -b --python tools/avatar/build_avatar.py
```

The script emits:

- `assets/avatar/human_female_v1.glb`
- `assets/avatar/human_male_v1.glb`
- `assets/avatar/avatar_catalog.json`
- `assets/avatar/PROVENANCE.md`
- transparent poster and review renders under `assets/avatar/posters/` and
  `assets/avatar/review/`

The two GLBs share the same armature bone names, animation names, and garment
material namespace. The default outfit is visible before the Flutter bridge
applies the selected look. Other garment materials are exported with zero
opacity and are shown or hidden by the model-viewer scene-graph bridge.

## Validation

The repository pins the official Khronos validator package through
`tools/avatar/package-lock.json`:

```bash
tools/avatar/validate_assets.sh
```

The command checks zero validator errors/warnings, catalog hashes, required
material groups, required animation clips, and one shared skin per model. The
exact generated hashes are recorded in `PROVENANCE.md`.
