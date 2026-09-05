#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
avatar_root="$repo_root/assets/avatar"
validator_root="$repo_root/tools/avatar"

if [[ ! -f "$validator_root/package-lock.json" ]]; then
  echo "Missing tools/avatar/package-lock.json" >&2
  exit 1
fi

npm ci --prefix "$validator_root" --ignore-scripts
node "$validator_root/validate_assets.mjs" \
  "$avatar_root/human_female_v1.glb" \
  "$avatar_root/human_male_v1.glb"

python3 - "$avatar_root/avatar_catalog.json" "$avatar_root/human_female_v1.glb" "$avatar_root/human_male_v1.glb" <<'PY'
import hashlib
import json
import struct
import sys
from pathlib import Path

catalog_path, *model_paths = map(Path, sys.argv[1:])
catalog = json.loads(catalog_path.read_text())

required_templates = set(catalog["templates"])
required_animations = set(catalog["animations"])
required_materials = {
    catalog["materials"]["body"],
    *(catalog["materials"]["hair"].format(style=style) for style in range(catalog["hairStyles"])),
    *(catalog["materials"]["garment"].format(template=template) for template in required_templates),
}

def glb_json(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise SystemExit(f"Invalid GLB header: {path}")
    offset = 12
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<I4s", data, offset)
        chunk = data[offset + 8 : offset + 8 + chunk_length]
        if chunk_type == b"JSON":
            return json.loads(chunk.decode("utf-8"))
        offset += 8 + chunk_length
    raise SystemExit(f"Missing JSON chunk: {path}")

for model in model_paths:
    expected = catalog["sha256"][model.stem.removeprefix("human_").removesuffix("_v1")]
    actual = hashlib.sha256(model.read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"SHA-256 mismatch: {model}")
    document = glb_json(model)
    materials = {entry.get("name") for entry in document.get("materials", [])}
    missing_materials = sorted(required_materials - materials)
    if missing_materials:
        raise SystemExit(f"Missing material groups in {model}: {missing_materials}")
    animations = {entry.get("name") for entry in document.get("animations", [])}
    missing_animations = sorted(required_animations - animations)
    if missing_animations:
        raise SystemExit(f"Missing animations in {model}: {missing_animations}")
    if len(document.get("skins", [])) != 1:
        raise SystemExit(f"Expected one shared skin in {model}")
print("catalog hashes/materials/animations: OK")
PY
