# Avatar renderer decision

Status: renderer-independent wardrobe integration landed; production 3D asset
activation is gated on a licensed/owned GLB and a native renderer validation
pass.

## Constraints

- The repository is pinned to Flutter 3.44.8 for the current Xcode 27 baseline.
- There are currently no GLB, GLTF, texture, rig, or animation assets in the
  repository.
- A wardrobe photograph is not treated as an exact 3D garment reconstruction.
  The first supported representation is a metadata-selected template with a
  detected color/material treatment.
- Guest wardrobe images stay local. No avatar renderer may require uploading a
  guest image.

## Candidate evidence

| Requirement | `model_viewer_plus` 1.10.0 | `flutter_scene` 0.23.0 |
| --- | --- | --- |
| iOS / Android support | Package advertises both; WebView runtime | Package advertises both; Flutter GPU / Impeller runtime |
| Local GLB | Supported by `src` | Supported by runtime import and build-time conversion |
| Orbit / drag | `cameraControls` | Scene camera/input layer |
| Skeletal animation | `animationName` / `autoPlay` | Skinned meshes and blended animation |
| Material variant | `variantName` | `KHR_materials_variants` / `SceneModel.variant` |
| Independent garment node swap | No first-class API; needs a prepared whole-model asset or custom WebView JavaScript | Scene graph supports the required architecture |
| Flutter integration | WebView platform view; gesture and lifecycle cost | Native Flutter scene view |
| Current Flutter pin | Compatible dependency already resolved | Current docs require Flutter 3.47+ and Flutter GPU |
| MMM prototype result | API inspected; no runtime asset benchmark possible | API inspected; package not added because the pin is incompatible |

These are API and package-document findings, not a runtime performance claim.
The two required renderer prototypes cannot be honestly marked green without a
real rigged GLB and an engine-compatible build. Downloading a random sample
model would violate MMM's asset-provenance requirement.

## Decision

`flutter_scene` is the preferred eventual renderer for MMM's native runtime
because it exposes a scene graph, skinned meshes, blended animation, material
variants, and Flutter semantics. It is not adopted on this branch because the
repository's pinned Flutter 3.44.8 predates its current Flutter 3.47+
requirement.

`model_viewer_plus` remains the compatibility adapter in
`GlbAvatarRenderer`. It is deliberately capability-gated: Home only receives
a model path when the asset catalog has a validated GLB. It provides a real
GLB path and a tested fallback seam, but it is not the final multi-garment
renderer because its public API does not independently swap garment nodes.

## Runtime contract

```text
ClothingItem (wardrobe truth)
  -> WearableTemplateResolver
  -> WearableAsset (template, slot, color, material, fit)
  -> AvatarOutfitResolver (real Outfit.itemIds, deterministic layers)
  -> GlbAvatarRenderer when a validated base model exists
  -> existing static fallback while the renderer is unavailable
```

The resolver handles dress/top/bottom conflicts, duplicate slots, missing
wardrobe IDs, and failed wearable processing without mutating the outfit or
wardrobe. The generated semantic label lists the selected garment names.

## Required follow-up before activation

1. Add an owned or licensed rigged base avatar GLB and record provenance,
   version, license, and validation output.
2. Add a small consistent template library sharing the base rig: regular tee,
   oversized top, shirt/blouse, sweater/hoodie, regular/slim/wide pants,
   shorts, skirt, straight/A-line dress, jacket/blazer/coat, sneaker,
   dress shoe/boot, bag, hat, and accessory.
3. Run iOS and Android prototypes covering idle animation, orbit, garment
   swap, material/color change, transparent light/dark backgrounds, reduced
   motion, and dispose/reload.
4. Revisit the Flutter pin and benchmark `flutter_scene` on a physical iOS and
   Android device before removing the legacy fallback.
