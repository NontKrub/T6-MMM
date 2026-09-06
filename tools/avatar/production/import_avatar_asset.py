#!/usr/bin/env python3
"""Validate and stage externally authored MMM Avatar V2 assets.

This tool never constructs a replacement character. It validates authored GLBs,
posters, review renders, and the bridge contract, then writes a staged catalog
only when the caller explicitly supplies --visual-approved.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import sys
from pathlib import Path


BONES = {
    "root",
    "pelvis",
    "spine_01",
    "spine_02",
    "chest",
    "neck",
    "head",
    "clavicle_L",
    "clavicle_R",
    "upper_arm_L",
    "upper_arm_R",
    "lower_arm_L",
    "lower_arm_R",
    "hand_L",
    "hand_R",
    "upper_leg_L",
    "upper_leg_R",
    "lower_leg_L",
    "lower_leg_R",
    "foot_L",
    "foot_R",
    "toe_L",
    "toe_R",
}
TEMPLATES = (
    "hat",
    "regular_tee",
    "fitted_top",
    "oversized_top",
    "shirt_blouse",
    "sweater_hoodie",
    "jacket",
    "blazer",
    "coat",
    "regular_pants",
    "slim_pants",
    "wide_leg_pants",
    "shorts",
    "skirt",
    "straight_dress",
    "a_line_dress",
    "sneaker",
    "dress_shoe",
    "boot",
    "bag",
    "accessory",
)
ANIMATIONS = ("idle", "blink", "wave", "look", "outfit_reveal")
TOP_TEMPLATES = {
    "regular_tee",
    "fitted_top",
    "oversized_top",
    "shirt_blouse",
    "sweater_hoodie",
}
REQUIRED_REVIEWS = (
    "female_front.png",
    "female_three_quarter.png",
    "female_side.png",
    "female_back.png",
    "female_ponytail_front.png",
    "female_oversized_tee_front.png",
    "female_dress_front.png",
    "male_front.png",
    "male_three_quarter.png",
    "male_side.png",
    "male_back.png",
    "male_hoodie_front.png",
    "male_wide_leg_pants_front.png",
)


def _glb_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"{path}: file is too small to be a GLB")
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError(f"{path}: invalid GLB header")
    offset = 12
    while offset + 8 <= len(data):
        chunk_length, chunk_type = struct.unpack_from("<I4s", data, offset)
        chunk = data[offset + 8 : offset + 8 + chunk_length]
        if chunk_type == b"JSON":
            return json.loads(chunk.decode("utf-8"))
        offset += 8 + chunk_length
    raise ValueError(f"{path}: missing JSON chunk")


def _required_materials() -> set[str]:
    return {
        "MMM_BODY__skin",
        *(f"MMM_HAIR__style_{style}__base" for style in range(6)),
        *(f"MMM_GARMENT__{template}__base" for template in TEMPLATES),
    }


def inspect_glb(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        document = _glb_json(path)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        return [str(error)]

    nodes = document.get("nodes", [])
    node_names = {node.get("name") for node in nodes}
    skins = document.get("skins", [])
    if len(skins) != 1:
        errors.append(f"{path}: expected exactly one skin, found {len(skins)}")
    elif not BONES <= {nodes[index].get("name") for index in skins[0].get("joints", [])}:
        missing = sorted(BONES - {nodes[index].get("name") for index in skins[0].get("joints", [])})
        errors.append(f"{path}: missing bones: {', '.join(missing)}")

    animations = {animation.get("name") for animation in document.get("animations", [])}
    missing_animations = sorted(set(ANIMATIONS) - animations)
    if missing_animations:
        errors.append(f"{path}: missing animations: {', '.join(missing_animations)}")

    materials = {material.get("name") for material in document.get("materials", [])}
    missing_materials = sorted(_required_materials() - materials)
    if missing_materials:
        errors.append(f"{path}: missing materials: {', '.join(missing_materials)}")

    mesh_nodes = [node for node in nodes if "mesh" in node]
    if not mesh_nodes or not any("skin" in node for node in mesh_nodes):
        errors.append(f"{path}: no skinned mesh nodes found")
    meshes = document.get("meshes", [])
    for mesh in meshes:
        for primitive in mesh.get("primitives", []):
            if "TEXCOORD_0" not in primitive.get("attributes", {}):
                errors.append(f"{path}: mesh {mesh.get('name', '<unnamed>')} lacks TEXCOORD_0")
                break
    return errors


def _check_png(path: Path) -> list[str]:
    if not path.is_file():
        return [f"missing poster: {path}"]
    try:
        data = path.read_bytes()
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            return [f"{path}: not a PNG"]
        width, height = struct.unpack_from(">II", data, 16)
        if width < 1 or height < 1:
            return [f"{path}: invalid dimensions"]
    except (OSError, struct.error) as error:
        return [f"{path}: {error}"]
    return []


def _validate_manifest(manifest: dict) -> list[str]:
    errors: list[str] = []
    if manifest.get("version") != 2:
        errors.append("manifest version must be 2")
    if manifest.get("normalization") != {"scale": 1.0, "origin": "floor_center"}:
        errors.append("manifest must record scale=1.0 and origin=floor_center")
    if set(manifest.get("templates", [])) != set(TEMPLATES):
        errors.append("manifest templates do not match the MMM garment contract")
    front_regions = manifest.get("frontDecalRect", {})
    for template in TOP_TEMPLATES:
        rect = front_regions.get(template)
        if not isinstance(rect, list) or len(rect) != 4 or not all(0 <= value <= 1 for value in rect):
            errors.append(f"manifest missing normalized frontDecalRect for {template}")
    return errors


def _run_khronos_validator(paths: list[Path]) -> list[str]:
    validator = Path(__file__).resolve().parents[1] / "validate_assets.mjs"
    node = shutil.which("node")
    if node is None or not validator.is_file():
        return ["Khronos validator unavailable; install Node and tools/avatar dependencies"]
    result = subprocess.run(
        [node, str(validator), *(str(path) for path in paths)],
        capture_output=True,
        text=True,
        check=False,
    )
    output = f"{result.stdout}\n{result.stderr}".strip()
    failures = [line for line in output.splitlines() if "errors=0 warnings=0" not in line and "errors=" in line]
    if result.returncode or failures:
        return [f"Khronos validation failed: {line}" for line in failures or output.splitlines()]
    return []


def _review_paths(review_dir: Path) -> list[Path]:
    return [review_dir / pattern for pattern in REQUIRED_REVIEWS]


def validate(args: argparse.Namespace) -> tuple[list[str], dict]:
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    errors = _validate_manifest(manifest)
    models = {"female": args.female, "male": args.male}
    for path in models.values():
        errors.extend(inspect_glb(path))
    errors.extend(_check_png(args.female_poster))
    errors.extend(_check_png(args.male_poster))
    for path in _review_paths(args.review_dir):
        if not path.is_file():
            errors.append(f"missing review render: {path}")
    errors.extend(_run_khronos_validator(list(models.values())))
    return errors, manifest


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def promote(args: argparse.Namespace, manifest: dict) -> None:
    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    poster_output = output / "posters"
    poster_output.mkdir(exist_ok=True)
    copied = {
        "female": output / "human_female_v2.glb",
        "male": output / "human_male_v2.glb",
    }
    for gender, source in (("female", args.female), ("male", args.male)):
        shutil.copy2(source, copied[gender])
    shutil.copy2(args.female_poster, poster_output / "human_female_v2.png")
    shutil.copy2(args.male_poster, poster_output / "human_male_v2.png")
    review_output = output / "review"
    review_output.mkdir(exist_ok=True)
    for path in _review_paths(args.review_dir):
        shutil.copy2(path, review_output / path.name)
    catalog = {
        "version": 2,
        "generator": "tools/avatar/production/import_avatar_asset.py",
        "models": {gender: f"{output}/human_{gender}_v2.glb" for gender in copied},
        "posters": {
            "female": f"{output}/posters/human_female_v2.png",
            "male": f"{output}/posters/human_male_v2.png",
        },
        "templates": list(TEMPLATES),
        "templateMetadata": manifest["frontDecalRect"],
        "animations": list(ANIMATIONS),
        "hairStyles": 6,
        "skinTones": 7,
        "hairColors": 6,
        "materials": {
            "body": "MMM_BODY__skin",
            "hair": "MMM_HAIR__style_{style}__base",
            "garment": "MMM_GARMENT__{template}__base",
        },
        "sha256": {gender: _sha256(path) for gender, path in copied.items()},
    }
    (output / "avatar_catalog_v2.json").write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--female", type=Path, required=True)
    parser.add_argument("--male", type=Path, required=True)
    parser.add_argument("--female-poster", type=Path, required=True)
    parser.add_argument("--male-poster", type=Path, required=True)
    parser.add_argument("--review-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--visual-approved", action="store_true")
    return parser


def main() -> int:
    args = _parser().parse_args()
    errors, manifest = validate(args)
    if errors:
        print("Asset import rejected:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    if not args.visual_approved:
        print("Asset validation passed. No files promoted; visual approval is required.")
        return 0
    if args.output_dir is None:
        print("--output-dir is required with --visual-approved", file=sys.stderr)
        return 2
    promote(args, manifest)
    print(f"Asset validation and staged promotion passed: {args.output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
