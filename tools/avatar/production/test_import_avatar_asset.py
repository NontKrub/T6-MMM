import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("import_avatar_asset.py")
SPEC = importlib.util.spec_from_file_location("import_avatar_asset", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def _write_glb(path: Path, *, with_uv: bool = True) -> None:
    nodes = [{"name": bone} for bone in sorted(MODULE.BONES)]
    joints = list(range(len(nodes)))
    nodes.append({"name": "Body", "mesh": 0, "skin": 0})
    materials = [{"name": name} for name in sorted(MODULE._required_materials())]
    primitive = {"attributes": {"POSITION": 0}}
    if with_uv:
        primitive["attributes"]["TEXCOORD_0"] = 1
    document = {
        "asset": {"version": "2.0"},
        "nodes": nodes,
        "skins": [{"joints": joints}],
        "animations": [{"name": name} for name in MODULE.ANIMATIONS],
        "materials": materials,
        "meshes": [{"name": "Body", "primitives": [primitive]}],
    }
    encoded = json.dumps(document, separators=(",", ":")).encode()
    encoded += b" " * ((4 - len(encoded) % 4) % 4)
    path.write_bytes(
        struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(encoded))
        + struct.pack("<I4s", len(encoded), b"JSON")
        + encoded
    )


class ImportAvatarAssetTest(unittest.TestCase):
    def test_accepts_required_glb_contract(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "female.glb"
            _write_glb(path)
            self.assertEqual(MODULE.inspect_glb(path), [])

    def test_rejects_missing_uv(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "female.glb"
            _write_glb(path, with_uv=False)
            self.assertTrue(any("TEXCOORD_0" in error for error in MODULE.inspect_glb(path)))

    def test_manifest_requires_normalized_source_and_top_regions(self):
        manifest = json.loads(
            (MODULE_PATH.with_name("avatar_asset_manifest_v2.example.json")).read_text()
        )
        self.assertEqual(MODULE._validate_manifest(manifest), [])
        manifest["normalization"]["scale"] = 0.01
        self.assertTrue(MODULE._validate_manifest(manifest))


if __name__ == "__main__":
    unittest.main()
