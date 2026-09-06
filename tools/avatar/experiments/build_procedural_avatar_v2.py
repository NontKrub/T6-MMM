#!/usr/bin/env python3
"""EXPERIMENTAL ONLY. Failed MMM production art-direction gate.

MUST NOT generate shipping avatar assets.

Build a procedural V2 avatar experiment for review only.

Run with Blender's Python interpreter:

    blender -b --python tools/avatar/experiments/build_procedural_avatar_v2.py

The meshes use continuous ring/tube topology. They are intentionally simple
and owned, but do not use visible cube, cone, torus, or primitive-sphere
geometry as the production source.
"""

from __future__ import annotations

import hashlib
import json
import math
import shutil
from datetime import datetime, timezone
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = ROOT / "assets" / "avatar" / "experiments" / "procedural_v2"
POSTER_ROOT = ASSET_ROOT / "posters"
REVIEW_ROOT = ASSET_ROOT / "review"

TEMPLATES = [
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
]
ANIMATIONS = ["idle", "blink", "wave", "look", "outfit_reveal"]
HAIR_STYLES = list(range(6))
SKIN_TONES = ["#F5E6D3", "#E8C4A0", "#C89B6E", "#B07840", "#9A6235", "#8B5A2B", "#4A2F1A"]
HAIR_COLORS = ["#12090A", "#2C1810", "#6B3A2A", "#C9A96E", "#8B3A1C", "#D4CFC8"]


def _ensure_directories() -> None:
    for directory in (ASSET_ROOT, POSTER_ROOT, REVIEW_ROOT):
        directory.mkdir(parents=True, exist_ok=True)


def _clear_scene() -> None:
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
        bpy.data.armatures,
        bpy.data.actions,
        bpy.data.images,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def _color(value: str) -> tuple[float, float, float]:
    value = value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) / 255 for index in (0, 2, 4))


def _material(
    name: str,
    hex_value: str,
    *,
    alpha: float = 1.0,
    roughness: float = 0.62,
    metallic: float = 0.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.diffuse_color = (*_color(hex_value), alpha)
    if hasattr(material, "surface_render_method"):
        material.surface_render_method = "DITHERED"
    elif hasattr(material, "blend_method"):
        material.blend_method = "BLEND" if alpha < 1 else "HASHED"
    shader = material.node_tree.nodes.get("Principled BSDF")
    if shader is not None:
        shader.inputs["Base Color"].default_value = (*_color(hex_value), alpha)
        shader.inputs["Alpha"].default_value = alpha
        shader.inputs["Roughness"].default_value = roughness
        shader.inputs["Metallic"].default_value = metallic
    material["mmm_material_role"] = "runtime-avatar-material"
    return material


def _set_material_alpha(material: bpy.types.Material, alpha: float) -> None:
    color = tuple(material.diffuse_color[:3])
    material.diffuse_color = (*color, alpha)
    if hasattr(material, "blend_method"):
        material.blend_method = "BLEND" if alpha < 1 else "HASHED"
    shader = material.node_tree.nodes.get("Principled BSDF") if material.use_nodes else None
    if shader is not None:
        base = shader.inputs["Base Color"].default_value
        shader.inputs["Base Color"].default_value = (base[0], base[1], base[2], alpha)
        shader.inputs["Alpha"].default_value = alpha


def _weighted_mesh(
    name: str,
    vertices: list[tuple[float, float, float]],
    faces: list[tuple[int, ...]],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
    uvs: list[tuple[float, float]] | None = None,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.validate(verbose=False)
    mesh.update()
    if uvs is not None:
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for loop in mesh.loops:
            uv_layer.data[loop.index].uv = uvs[loop.vertex_index]
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    modifier = obj.modifiers.new(name="MMM_Armature", type="ARMATURE")
    modifier.object = armature
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(vertices))), 1.0, "REPLACE")
    obj["mmm_rig_bone"] = bone_name
    return obj


def _tube(
    name: str,
    points: list[tuple[float, float, float]],
    radii: list[tuple[float, float] | float],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
    *,
    segments: int = 24,
    cap_ends: bool = True,
    u_offset: float = 0.0,
) -> bpy.types.Object:
    vertices: list[tuple[float, float, float]] = []
    uvs: list[tuple[float, float]] = []
    ring_count = len(points)
    for index, point in enumerate(points):
        current = Vector(point)
        previous = Vector(points[max(0, index - 1)])
        following = Vector(points[min(ring_count - 1, index + 1)])
        tangent = (following - previous).normalized()
        reference = Vector((0, 1, 0))
        if abs(tangent.dot(reference)) > 0.92:
            reference = Vector((1, 0, 0))
        side = tangent.cross(reference).normalized()
        binormal = tangent.cross(side).normalized()
        radius = radii[index]
        rx, ry = (radius, radius) if isinstance(radius, float) else radius
        for segment in range(segments):
            angle = 2 * math.pi * segment / segments
            offset = side * (math.cos(angle) * rx) + binormal * (math.sin(angle) * ry)
            vertices.append(tuple(current + offset))
            uvs.append(((segment / segments + u_offset) % 1.0, index / max(1, ring_count - 1)))

    faces: list[tuple[int, ...]] = []
    for row in range(ring_count - 1):
        for segment in range(segments):
            next_segment = (segment + 1) % segments
            a = row * segments + segment
            b = row * segments + next_segment
            c = (row + 1) * segments + next_segment
            d = (row + 1) * segments + segment
            faces.append((a, b, c, d))
    if cap_ends:
        start = len(vertices)
        vertices.append(points[0])
        uvs.append((0.5, 0.0))
        end = len(vertices)
        vertices.append(points[-1])
        uvs.append((0.5, 1.0))
        for segment in range(segments):
            next_segment = (segment + 1) % segments
            faces.append((start, next_segment, segment))
            a = (ring_count - 1) * segments + segment
            b = (ring_count - 1) * segments + next_segment
            faces.append((end, b, a))
    return _weighted_mesh(name, vertices, faces, material, armature, bone_name, uvs)


def _surface_z(
    name: str,
    levels: list[tuple[float, float, float, float, float]],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
    *,
    segments: int = 28,
    cap_ends: bool = True,
) -> bpy.types.Object:
    points = [(x, y, z) for z, rx, ry, x, y in levels]
    radii = [(rx, ry) for z, rx, ry, x, y in levels]
    return _tube(
        name,
        points,
        radii,
        material,
        armature,
        bone_name,
        segments=segments,
        cap_ends=cap_ends,
        u_offset=0.25,
    )


def _ellipsoid(
    name: str,
    center: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
    *,
    segments: int = 28,
    rings: int = 18,
    cheek_volume: float = 0.0,
) -> bpy.types.Object:
    levels: list[tuple[float, float, float, float, float]] = []
    for index in range(rings + 1):
        latitude = -math.pi / 2 + math.pi * index / rings
        vertical = math.sin(latitude)
        radial = max(0.0, math.cos(latitude))
        cheek = 1 + cheek_volume * max(0.0, 1 - abs(vertical + 0.12) * 2.4)
        levels.append(
            (
                center[2] + scale[2] * vertical,
                scale[0] * radial * cheek,
                scale[1] * radial,
                center[0],
                center[1],
            )
        )
    return _surface_z(name, levels, material, armature, bone_name, segments=segments)


def _create_rig() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "MMM_HumanRig"
    armature.data.name = "MMM_HumanRig"
    armature.show_in_front = True
    edit_bones = armature.data.edit_bones
    edit_bones.remove(edit_bones[0])

    def bone(
        name: str,
        head: tuple[float, float, float],
        tail: tuple[float, float, float],
        parent: str | None = None,
    ) -> None:
        created = edit_bones.new(name)
        created.head = head
        created.tail = tail
        if parent:
            created.parent = edit_bones[parent]
            created.use_connect = False

    bone("root", (0, 0, 0), (0, 0, 0.2))
    bone("pelvis", (0, 0, 1.45), (0, 0, 1.78), "root")
    bone("spine_01", (0, 0, 1.75), (0, 0, 2.1), "pelvis")
    bone("spine_02", (0, 0, 2.08), (0, 0, 2.45), "spine_01")
    bone("chest", (0, 0, 2.4), (0, 0, 2.68), "spine_02")
    bone("neck", (0, 0, 2.65), (0, 0, 2.98), "chest")
    bone("head", (0, 0, 2.95), (0, 0, 3.25), "neck")
    for side, sign in (("L", 1), ("R", -1)):
        shoulder = (0.40 * sign, 0, 2.55)
        elbow = (0.60 * sign, 0, 2.15)
        wrist = (0.63 * sign, -0.01, 1.78)
        bone(f"clavicle_{side}", (0.12 * sign, 0, 2.57), shoulder, "chest")
        bone(f"upper_arm_{side}", shoulder, elbow, f"clavicle_{side}")
        bone(f"lower_arm_{side}", elbow, wrist, f"upper_arm_{side}")
        bone(f"hand_{side}", wrist, (0.63 * sign, -0.03, 1.56), f"lower_arm_{side}")
        hip = (0.20 * sign, 0, 1.52)
        knee = (0.20 * sign, 0, 0.92)
        ankle = (0.20 * sign, -0.01, 0.25)
        bone(f"upper_leg_{side}", hip, knee, "pelvis")
        bone(f"lower_leg_{side}", knee, ankle, f"upper_leg_{side}")
        bone(f"foot_{side}", ankle, (0.20 * sign, -0.22, 0.08), f"lower_leg_{side}")
        bone(f"toe_{side}", (0.20 * sign, -0.18, 0.08), (0.20 * sign, -0.38, 0.08), f"foot_{side}")
        bone(f"lid_{side}", (0.23 * sign, -0.54, 3.34), (0.23 * sign, -0.54, 3.40), "head")

    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    armature["mmm_rig_version"] = 2
    return armature


def _add_face(
    armature: bpy.types.Object,
    skin: bpy.types.Material,
    hair: bpy.types.Material,
) -> None:
    eye = _material("MMM_BODY__eye", "#20222B", roughness=0.32)
    nose = _material("MMM_BODY__nose", "#D79572", roughness=0.55)
    lip = _material("MMM_BODY__lip", "#B8666C", roughness=0.48)
    for sign, side in ((-1, "L"), (1, "R")):
        x = 0.22 * sign
        _ellipsoid(f"Eye_{side}", (x, -0.505, 3.37), (0.11, 0.035, 0.145), eye, armature, "head", segments=24, rings=14)
        _ellipsoid(f"Lid_{side}", (x, -0.55, 3.38), (0.115, 0.018, 0.022), skin, armature, f"lid_{side}", segments=20, rings=10)
        _tube(
            f"Brow_{side}",
            [(x - 0.12, -0.525, 3.60), (x, -0.55, 3.64), (x + 0.12, -0.525, 3.60)],
            [0.030, 0.036, 0.030],
            hair,
            armature,
            "head",
            segments=12,
        )
    _ellipsoid("Nose", (0, -0.565, 3.16), (0.085, 0.060, 0.065), nose, armature, "head", segments=20, rings=12)
    _tube(
        "Smile",
        [(-0.13, -0.56, 3.00), (0, -0.575, 2.97), (0.13, -0.56, 3.00)],
        [0.011, 0.013, 0.011],
        lip,
        armature,
        "head",
        segments=10,
    )


def _hair_cap(
    name: str,
    material: bpy.types.Material,
    armature: bpy.types.Object,
    *,
    scale: tuple[float, float, float] = (0.72, 0.57, 0.43),
    center: tuple[float, float, float] = (0, 0.02, 3.83),
) -> bpy.types.Object:
    return _ellipsoid(name, center, scale, material, armature, "head", segments=30, rings=18, cheek_volume=0.07)


def _add_hair_styles(armature: bpy.types.Object, materials: dict[int, bpy.types.Material]) -> None:
    for style, material in materials.items():
        _hair_cap(f"HairCap_{style}", material, armature)
        if style == 0:  # tousled: directional crown locks
            for index, x in enumerate((-0.46, -0.22, 0.04, 0.30, 0.50)):
                _tube(
                    f"HairTousled_{index}",
                    [(x, -0.02, 3.58), (x * 0.86, -0.08, 3.86), (x * 0.66, -0.12, 4.00)],
                    [0.16, 0.18, 0.10],
                    material,
                    armature,
                    "head",
                    segments=18,
                )
        elif style == 1:  # side swept fringe
            _tube(
                "HairSideSweep",
                [(-0.56, -0.12, 3.62), (-0.22, -0.34, 3.94), (0.28, -0.40, 3.77), (0.52, -0.26, 3.53)],
                [0.18, 0.20, 0.18, 0.10],
                material,
                armature,
                "head",
                segments=20,
            )
            _tube(
                "HairSideTail",
                [(0.54, 0.02, 3.60), (0.62, 0.08, 3.28), (0.56, 0.06, 3.06)],
                [0.15, 0.17, 0.10],
                material,
                armature,
                "head",
                segments=20,
            )
        elif style == 2:  # short undercut
            _hair_cap("HairUndercutTop", material, armature, scale=(0.64, 0.53, 0.28), center=(0, -0.01, 3.79))
            for sign in (-1, 1):
                _tube(
                    f"HairUndercutSide_{sign}",
                    [(0.54 * sign, 0.02, 3.64), (0.60 * sign, -0.02, 3.40), (0.53 * sign, -0.04, 3.24)],
                    [0.12, 0.14, 0.09],
                    material,
                    armature,
                    "head",
                    segments=18,
                )
        elif style == 3:  # long face-framing locks
            for sign in (-1, 1):
                _tube(
                    f"HairLong_{sign}",
                    [(0.53 * sign, 0.05, 3.60), (0.62 * sign, -0.02, 3.25), (0.59 * sign, 0.02, 2.82)],
                    [0.19, 0.20, 0.11],
                    material,
                    armature,
                    "head",
                    segments=20,
                )
            _tube(
                "HairLongFringe",
                [(-0.44, -0.26, 3.67), (-0.18, -0.46, 3.83), (0.18, -0.46, 3.80)],
                [0.16, 0.18, 0.13],
                material,
                armature,
                "head",
                segments=20,
            )
        elif style == 4:  # ponytail with connected root and tie
            _tube(
                "HairPonytail",
                [(0.42, 0.18, 3.56), (0.65, 0.26, 3.30), (0.61, 0.28, 2.94), (0.46, 0.25, 2.63)],
                [0.20, 0.22, 0.17, 0.07],
                material,
                armature,
                "head",
                segments=22,
            )
            tie = _material("MMM_HAIR__ponytail_tie", "#A06BEF", roughness=0.42)
            _tube(
                "HairPonytailTie",
                [(0.54, 0.24, 3.42), (0.62, 0.25, 3.36)],
                [0.07, 0.07],
                tie,
                armature,
                "head",
                segments=16,
            )
            _tube(
                "HairPonytailFringe",
                [(-0.48, -0.24, 3.68), (-0.20, -0.45, 3.84), (0.12, -0.46, 3.80)],
                [0.15, 0.18, 0.12],
                material,
                armature,
                "head",
                segments=20,
            )
        else:  # bob
            for sign in (-1, 1):
                _tube(
                    f"HairBob_{sign}",
                    [(0.52 * sign, 0.02, 3.58), (0.62 * sign, -0.02, 3.22), (0.52 * sign, -0.01, 2.94)],
                    [0.19, 0.22, 0.12],
                    material,
                    armature,
                    "head",
                    segments=20,
                )


def _neutral_texture() -> bpy.types.Image:
    image = bpy.data.images.get("MMM_GarmentNeutralTexture")
    if image is None:
        image = bpy.data.images.new("MMM_GarmentNeutralTexture", width=1, height=1, alpha=True)
        image.pixels = [1.0, 1.0, 1.0, 1.0]
        image.pack()
    return image


def _garment_materials() -> dict[str, bpy.types.Material]:
    neutral = _neutral_texture()
    materials: dict[str, bpy.types.Material] = {}
    for template in TEMPLATES:
        material = _material(
            f"MMM_GARMENT__{template}__base",
            "#D9DCE5",
            alpha=0.0,
            roughness=0.70,
        )
        material["mmm_template"] = template
        material["mmm_texture_size"] = 512
        material["mmm_front_decal_rect"] = [0.18, 0.15, 0.64, 0.55]
        material["mmm_supports_repeat_pattern"] = template not in {"shoes", "bag"}
        material["mmm_supports_front_decal"] = template in {
            "regular_tee",
            "fitted_top",
            "oversized_top",
            "shirt_blouse",
            "sweater_hoodie",
            "jacket",
            "blazer",
            "coat",
            "straight_dress",
            "a_line_dress",
        }
        texture = material.node_tree.nodes.new("ShaderNodeTexImage")
        texture.image = neutral
        texture.interpolation = "Linear"
        shader = material.node_tree.nodes.get("Principled BSDF")
        if shader is not None:
            material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
        materials[template] = material
    return materials


def _add_body(
    armature: bpy.types.Object,
    *,
    female: bool,
    skin: bpy.types.Material,
    hair: bpy.types.Material,
) -> None:
    torso_width = 0.47 if female else 0.52
    hip_width = 0.47 if female else 0.43
    _surface_z(
        "BodyTorso",
        [
            (1.78, torso_width * 0.78, 0.26, 0, 0),
            (1.94, torso_width * 0.93, 0.29, 0, 0),
            (2.18, torso_width, 0.31, 0, 0),
            (2.42, torso_width * 1.02, 0.30, 0, 0),
            (2.62, torso_width * 0.82, 0.26, 0, 0),
            (2.72, torso_width * 0.62, 0.21, 0, 0),
        ],
        skin,
        armature,
        "spine_02",
    )
    _surface_z(
        "BodyPelvis",
        [
            (1.38, hip_width * 0.74, 0.22, 0, 0),
            (1.52, hip_width, 0.27, 0, 0),
            (1.72, hip_width * 0.98, 0.28, 0, 0),
            (1.86, hip_width * 0.75, 0.24, 0, 0),
        ],
        skin,
        armature,
        "pelvis",
    )
    _tube("Neck", [(0, 0, 2.64), (0, 0, 2.84), (0, 0, 3.03)], [0.18, 0.17, 0.20], skin, armature, "neck", segments=24)
    _ellipsoid("Head", (0, 0, 3.42), (0.72, 0.53, 0.78), skin, armature, "head", segments=32, rings=22, cheek_volume=0.10)
    for sign, side in ((-1, "L"), (1, "R")):
        _ellipsoid(f"Ear_{side}", (0.60 * sign, -0.005, 3.37), (0.16, 0.11, 0.23), skin, armature, "head", segments=22, rings=14)
        _ellipsoid(f"Shoulder_{side}", (0.43 * sign, 0, 2.52), (0.19, 0.26, 0.20), skin, armature, f"upper_arm_{side}", segments=22, rings=14)
        _tube(
            f"UpperArm_{side}",
            [(0.40 * sign, 0, 2.55), (0.51 * sign, -0.01, 2.35), (0.60 * sign, 0, 2.12)],
            [0.145, 0.14, 0.115],
            skin,
            armature,
            f"upper_arm_{side}",
            segments=22,
        )
        _tube(
            f"LowerArm_{side}",
            [(0.60 * sign, 0, 2.12), (0.63 * sign, -0.01, 1.92), (0.63 * sign, -0.02, 1.74)],
            [0.115, 0.10, 0.085],
            skin,
            armature,
            f"lower_arm_{side}",
            segments=22,
        )
        _ellipsoid(f"Hand_{side}", (0.63 * sign, -0.03, 1.65), (0.14, 0.12, 0.17), skin, armature, f"hand_{side}", segments=22, rings=14)
        _tube(
            f"UpperLeg_{side}",
            [(0.20 * sign, 0, 1.56), (0.20 * sign, -0.01, 1.27), (0.20 * sign, 0, 0.94)],
            [0.18 if female else 0.19, 0.17 if female else 0.18, 0.145],
            skin,
            armature,
            f"upper_leg_{side}",
            segments=22,
        )
        _tube(
            f"LowerLeg_{side}",
            [(0.20 * sign, 0, 0.94), (0.20 * sign, -0.01, 0.58), (0.20 * sign, -0.02, 0.24)],
            [0.145, 0.13, 0.11],
            skin,
            armature,
            f"lower_leg_{side}",
            segments=22,
        )
        _ellipsoid(f"Foot_{side}", (0.20 * sign, -0.11, 0.12), (0.20, 0.30, 0.13), skin, armature, f"foot_{side}", segments=24, rings=14)
    _add_face(armature, skin, hair)


def _add_garments(
    armature: bpy.types.Object,
    garments: dict[str, bpy.types.Material],
    *,
    female: bool,
) -> None:
    body_width = 0.47 if female else 0.52
    top_specs = {
        "regular_tee": (body_width + 0.02, 0.38, 0.30),
        "fitted_top": (body_width - 0.05, 0.36, 0.31),
        "oversized_top": (body_width + 0.15, 0.43, 0.34),
        "shirt_blouse": (body_width + 0.04, 0.40, 0.34),
        "sweater_hoodie": (body_width + 0.11, 0.45, 0.38),
    }
    for template, (width, depth, drop) in top_specs.items():
        _surface_z(
            f"Garment_{template}",
            [
                (1.84, width * 0.82, depth * 0.84, 0, 0),
                (2.04, width, depth, 0, 0),
                (2.30, width * 1.02, depth, 0, 0),
                (2.58, width * 0.90, depth * 0.94, 0, 0),
                (2.68, width * 0.68, depth * 0.78, 0, 0),
            ],
            garments[template],
            armature,
            "spine_02",
        )
        if template == "sweater_hoodie":
            _surface_z(
                "Garment_sweater_hoodie_hood",
                [(2.58, width * 0.48, depth * 0.62, 0, 0.07), (2.78, width * 0.38, depth * 0.50, 0, 0.10)],
                garments[template],
                armature,
                "spine_02",
                segments=24,
            )

    outer_specs = {"jacket": 0.08, "blazer": 0.07, "coat": 0.14}
    for template, extra in outer_specs.items():
        length = 2.25 if template != "coat" else 1.95
        _surface_z(
            f"Garment_{template}",
            [
                (1.50 if template == "coat" else 1.78, body_width + extra, 0.37, 0, 0),
                (1.92, body_width + extra * 1.08, 0.38, 0, 0),
                (2.25, body_width + extra * 1.04, 0.38, 0, 0),
                (2.58, body_width + extra * 0.82, 0.32, 0, 0),
                (2.72, body_width + extra * 0.58, 0.25, 0, 0),
            ],
            garments[template],
            armature,
            "spine_02",
        )

    for template, width in (
        ("regular_pants", 0.21),
        ("slim_pants", 0.175),
        ("wide_leg_pants", 0.285),
        ("shorts", 0.23),
    ):
        bottom = 1.02 if template == "shorts" else 0.24
        top = 1.62
        for sign, bone_name in ((-1, "upper_leg_L"), (1, "upper_leg_R")):
            _tube(
                f"Garment_{template}_{sign}",
                [(0.20 * sign, 0, top), (0.20 * sign, -0.01, (top + bottom) / 2), (0.20 * sign, 0, bottom)],
                [(width, 0.25), (width * 0.95, 0.24), (width * 0.72, 0.20)],
                garments[template],
                armature,
                bone_name,
                segments=24,
            )

    _surface_z(
        "Garment_skirt",
        [(1.38, 0.47, 0.29, 0, 0), (1.58, 0.54, 0.31, 0, 0), (1.86, 0.66, 0.35, 0, 0), (1.98, 0.68, 0.34, 0, 0)],
        garments["skirt"],
        armature,
        "pelvis",
    )
    for template, bottom_width in (("straight_dress", 0.57), ("a_line_dress", 0.72)):
        _surface_z(
            f"Garment_{template}",
            [
                (1.35, bottom_width, 0.34, 0, 0),
                (1.70, bottom_width * 0.94, 0.34, 0, 0),
                (2.10, body_width + 0.07, 0.32, 0, 0),
                (2.50, body_width + 0.02, 0.29, 0, 0),
                (2.70, body_width * 0.72, 0.23, 0, 0),
            ],
            garments[template],
            armature,
            "pelvis",
        )

    for template, y, height in (("sneaker", -0.12, 0.13), ("dress_shoe", -0.10, 0.11), ("boot", -0.06, 0.30)):
        for sign, bone_name in ((-1, "foot_L"), (1, "foot_R")):
            _ellipsoid(
                f"Garment_{template}_{sign}",
                (0.20 * sign, y, 0.12 if template != "boot" else 0.22),
                (0.24, 0.34, height),
                garments[template],
                armature,
                bone_name,
                segments=24,
                rings=14,
            )

    _surface_z(
        "Garment_hat",
        [(3.70, 0.56, 0.48, 0, 0.02), (3.86, 0.48, 0.39, 0, 0.03), (3.94, 0.30, 0.26, 0, 0.03)],
        garments["hat"],
        armature,
        "head",
    )
    _ellipsoid("Garment_bag", (0.67, -0.12, 1.94), (0.19, 0.14, 0.27), garments["bag"], armature, "hand_R", segments=24, rings=14)
    _tube(
        "Garment_bag_strap",
        [(0.46, -0.02, 2.46), (0.62, -0.10, 2.22), (0.67, -0.12, 2.08)],
        [0.025, 0.028, 0.025],
        garments["bag"],
        armature,
        "hand_R",
        segments=12,
    )
    _tube(
        "Garment_accessory",
        [(-0.21, -0.32, 2.80), (-0.10, -0.39, 2.70), (0, -0.41, 2.67), (0.10, -0.39, 2.70), (0.21, -0.32, 2.80)],
        [0.022, 0.025, 0.028, 0.025, 0.022],
        garments["accessory"],
        armature,
        "neck",
        segments=12,
    )


def _make_action(
    armature: bpy.types.Object,
    name: str,
    keyframes: list[tuple[int, str, str, tuple[float, float, float]]],
) -> None:
    action = bpy.data.actions.new(name)
    armature.animation_data_create()
    armature.animation_data.action = action
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    for frame, bone_name, property_name, values in keyframes:
        pose_bone = armature.pose.bones.get(bone_name)
        if pose_bone is None:
            continue
        if property_name == "scale":
            pose_bone.scale = values
            pose_bone.keyframe_insert(data_path="scale", frame=frame)
        else:
            pose_bone.rotation_mode = "XYZ"
            pose_bone.rotation_euler = values
            pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")
    armature.animation_data.action = None


def _add_animations(armature: bpy.types.Object) -> None:
    _make_action(
        armature,
        "idle",
        [
            (1, "spine_01", "rotation", (0.0, 0.0, 0.0)),
            (20, "spine_01", "rotation", (0.018, 0.0, 0.0)),
            (40, "spine_01", "rotation", (0.0, 0.0, 0.0)),
        ],
    )
    _make_action(
        armature,
        "blink",
        [
            (1, "lid_L", "scale", (1.0, 1.0, 0.2)),
            (1, "lid_R", "scale", (1.0, 1.0, 0.2)),
            (4, "lid_L", "scale", (1.0, 1.0, 10.0)),
            (4, "lid_R", "scale", (1.0, 1.0, 10.0)),
            (8, "lid_L", "scale", (1.0, 1.0, 0.2)),
            (8, "lid_R", "scale", (1.0, 1.0, 0.2)),
        ],
    )
    _make_action(
        armature,
        "wave",
        [
            (1, "upper_arm_R", "rotation", (0.0, 0.0, 0.0)),
            (12, "upper_arm_R", "rotation", (-0.30, 0.0, -0.25)),
            (24, "lower_arm_R", "rotation", (0.0, 0.0, -0.55)),
            (36, "lower_arm_R", "rotation", (0.0, 0.0, 0.20)),
            (48, "upper_arm_R", "rotation", (0.0, 0.0, 0.0)),
        ],
    )
    _make_action(
        armature,
        "look",
        [
            (1, "head", "rotation", (0.0, 0.0, 0.0)),
            (18, "head", "rotation", (0.0, 0.20, 0.0)),
            (36, "head", "rotation", (0.0, 0.0, 0.0)),
        ],
    )
    _make_action(
        armature,
        "outfit_reveal",
        [
            (1, "root", "rotation", (0.0, 0.0, 0.0)),
            (10, "root", "rotation", (0.0, 0.0, 0.03)),
            (20, "root", "rotation", (0.0, 0.0, 0.0)),
        ],
    )


def _create_camera(location: tuple[float, float, float]) -> bpy.types.Object:
    bpy.ops.object.camera_add(location=location)
    camera = bpy.context.object
    camera.data.lens = 60
    camera.data.sensor_width = 36
    direction = Vector((0, 0, 2.1)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    return camera


def _setup_lighting() -> None:
    bpy.ops.object.light_add(type="AREA", location=(3.5, -4.5, 5.8))
    key = bpy.context.object
    key.data.energy = 520
    key.data.shape = "DISK"
    key.data.size = 4.5
    key.rotation_euler = (math.radians(25), 0, math.radians(35))
    bpy.ops.object.light_add(type="AREA", location=(-3.0, -1.0, 3.2))
    fill = bpy.context.object
    fill.data.energy = 240
    fill.data.size = 3.5
    direction = Vector((0, 0, 2.2)) - fill.location
    fill.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.light_add(type="AREA", location=(0, 1.8, 4.5))
    rim = bpy.context.object
    rim.data.energy = 150
    rim.data.size = 2.5
    direction = Vector((0, 0, 2.8)) - rim.location
    rim.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _set_variant(
    materials: dict[str, bpy.types.Material],
    *,
    hair_style: int = 3,
    outfit: str = "default",
) -> None:
    for template, material in materials.items():
        _set_material_alpha(material, 0.0)
    visible = {
        "default": ("regular_tee", "regular_pants", "sneaker"),
        "oversized": ("oversized_top", "wide_leg_pants", "sneaker"),
        "dress": ("a_line_dress", "dress_shoe"),
        "hoodie": ("sweater_hoodie", "regular_pants", "sneaker"),
        "wide_pants": ("regular_tee", "wide_leg_pants", "sneaker"),
    }[outfit]
    for template in visible:
        _set_material_alpha(materials[template], 1.0)
    for index, material in materials.items():
        if material.name.startswith("MMM_HAIR__style_"):
            _set_material_alpha(material, 1.0 if index == hair_style else 0.0)


def _render_views(gender: str, materials: dict[str, bpy.types.Material]) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {
        item.identifier for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    } else "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = True
    scene.world.color = (0.94, 0.93, 0.98)
    _setup_lighting()
    camera = _create_camera((0, -8.5, 2.2))
    scene.camera = camera
    locations = {
        "front": (0, -8.5, 2.2),
        "three_quarter": (4.8, -7.0, 2.25),
        "side": (8.5, 0, 2.2),
        "back": (0, 8.5, 2.2),
    }
    variants = [
        ("default", 0, ("front", "three_quarter", "side", "back")),
        ("ponytail", 4, ("front",)),
        ("oversized_tee", 0, ("front",)),
        ("dress", 1, ("front",)),
    ]
    if gender == "male":
        variants.extend((("hoodie", 2, ("front",)), ("wide_pants", 1, ("front",))))
    for variant, hair_style, views in variants:
        outfit = "default"
        if variant == "oversized_tee":
            outfit = "oversized"
        elif variant == "dress":
            outfit = "dress"
        elif variant == "hoodie":
            outfit = "hoodie"
        elif variant == "wide_pants":
            outfit = "wide_pants"
        _set_variant(materials, hair_style=hair_style, outfit=outfit)
        for view in views:
            camera.location = locations[view]
            direction = Vector((0, 0, 2.1)) - camera.location
            camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
            output = REVIEW_ROOT / f"{gender}_{variant}_{view}.png"
            scene.render.filepath = str(output)
            bpy.ops.render.render(write_still=True)
        if variant == "default":
            shutil.copyfile(REVIEW_ROOT / f"{gender}_default_front.png", POSTER_ROOT / f"human_{gender}_v2.png")
    bpy.data.objects.remove(camera, do_unlink=True)


def _export_glb(gender: str, armature: bpy.types.Object) -> Path:
    filepath = ASSET_ROOT / f"human_{gender}_v2.glb"
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"MESH", "ARMATURE"}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_skins=True,
        export_def_bones=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    return filepath


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _write_catalog(paths: dict[str, Path]) -> None:
    catalog = {
        "version": 2,
        "generator": "tools/avatar/experiments/build_procedural_avatar_v2.py",
        "models": {
            "female": "assets/avatar/experiments/procedural_v2/human_female_v2.glb",
            "male": "assets/avatar/experiments/procedural_v2/human_male_v2.glb",
        },
        "posters": {
            "female": "assets/avatar/experiments/procedural_v2/posters/human_female_v2.png",
            "male": "assets/avatar/experiments/procedural_v2/posters/human_male_v2.png",
        },
        "templates": TEMPLATES,
        "templateMetadata": {
            template: {
                "textureSize": 512,
                "frontDecalRect": [0.18, 0.15, 0.64, 0.55],
                "supportsRepeatPattern": template not in {"sneaker", "dress_shoe", "boot", "bag", "accessory"},
                "supportsFrontDecal": template in {
                    "regular_tee", "fitted_top", "oversized_top", "shirt_blouse",
                    "sweater_hoodie", "jacket", "blazer", "coat", "straight_dress", "a_line_dress",
                },
            }
            for template in TEMPLATES
        },
        "animations": ANIMATIONS,
        "hairStyles": 6,
        "skinTones": 7,
        "hairColors": 6,
        "materials": {
            "body": "MMM_BODY__skin",
            "hair": "MMM_HAIR__style_{style}__base",
            "garment": "MMM_GARMENT__{template}__base",
        },
        "sha256": {gender: _sha256(path) for gender, path in paths.items()},
    }
    # Keep the V1 catalog intact until the V2 art gate is accepted.
    (ASSET_ROOT / "avatar_catalog_v2.json").write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")


def _write_provenance(paths: dict[str, Path]) -> None:
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    lines = [
        "# MMM Avatar Asset Provenance",
        "",
        "These assets are generated by the owned MMM V2 Blender pipeline.",
        "No external character, garment, texture, or unknown-license model is used.",
        "",
        "- Creator: Mix Match Mood project",
        f"- Creation method: Blender {bpy.app.version_string} Python continuous ring/tube meshes",
        "- License: project-owned source generated for MMM",
        "- Version: avatar v2",
        "- Generation script: tools/avatar/production/build_avatar_v2.py",
        f"- Generation date: {generated_at}",
        "- Geometry: smooth authored-style surfaces with a shared human armature",
        "- Runtime representation: named garment materials with predictable UVs and local derived textures",
        "",
        "## Generated assets",
        "",
    ]
    for gender, path in paths.items():
        lines.extend(
            [
                f"### experiments/procedural_v2/human_{gender}_v2.glb",
                f"- Origin: project-owned MMM V2 continuous surface scene ({gender} body proportions)",
                f"- File size: {path.stat().st_size} bytes",
                f"- SHA-256: {_sha256(path)}",
                "- Validation: run `tools/avatar/validate_assets.sh` after generation",
                "",
            ]
        )
    lines.extend(
        [
            "## Catalog scope",
            "",
            f"- Garment templates: {', '.join(TEMPLATES)}",
            f"- Animations: {', '.join(ANIMATIONS)}",
            "- Human models share bone names, animation names, material namespaces, and UV metadata.",
            "- Wardrobe photographs are processed locally into derived texture files; they are not embedded in GLBs.",
            "",
        ]
    )
    # Keep the V1 provenance intact until the V2 art gate is accepted.
    (ASSET_ROOT / "PROVENANCE_V2.md").write_text("\n".join(lines), encoding="utf-8")


def build() -> None:
    _ensure_directories()
    paths: dict[str, Path] = {}
    for gender in ("female", "male"):
        _clear_scene()
        female = gender == "female"
        armature = _create_rig()
        skin = _material("MMM_BODY__skin", "#C9795E", roughness=0.52)
        hair_materials = {
            index: _material(f"MMM_HAIR__style_{index}__base", "#19171C", roughness=0.50)
            for index in HAIR_STYLES
        }
        _add_body(armature, female=female, skin=skin, hair=hair_materials[3])
        _add_hair_styles(armature, hair_materials)
        garments = _garment_materials()
        _add_garments(armature, garments, female=female)
        _add_animations(armature)
        _set_variant(garments, hair_style=0, outfit="default")
        _render_views(gender, {**garments, **hair_materials})
        paths[gender] = _export_glb(gender, armature)
    _write_catalog(paths)
    _write_provenance(paths)
    print(json.dumps({"models": {gender: str(path) for gender, path in paths.items()}, "catalog": str(ASSET_ROOT / "avatar_catalog_v2.json")}, indent=2))


if __name__ == "__main__":
    build()
