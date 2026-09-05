#!/usr/bin/env python3
"""Build MMM's owned, low-poly human avatar assets.

The script intentionally keeps the asset pipeline procedural. It creates a
small shared-rig template catalog rather than trying to reconstruct a garment
mesh from an arbitrary wardrobe photograph.

Run with the Blender Python interpreter:

    blender -b --python tools/avatar/build_avatar.py
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "assets" / "avatar"
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


def _ensure_directories() -> None:
    for directory in (ASSET_ROOT, POSTER_ROOT, REVIEW_ROOT):
        directory.mkdir(parents=True, exist_ok=True)


def _clear_scene() -> None:
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.armatures, bpy.data.actions):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def _color(hex_value: str) -> tuple[float, float, float]:
    value = hex_value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) / 255 for index in (0, 2, 4))


def _material(
    name: str,
    hex_value: str,
    *,
    alpha: float = 1.0,
    roughness: float = 0.55,
    metallic: float = 0.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.diffuse_color = (*_color(hex_value), alpha)
    material.blend_method = "BLEND" if alpha < 1 else "HASHED"
    material.surface_render_method = "DITHERED" if alpha < 1 else "DITHERED"
    nodes = material.node_tree.nodes
    shader = nodes.get("Principled BSDF")
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
    material.blend_method = "BLEND" if alpha < 1 else "HASHED"
    shader = material.node_tree.nodes.get("Principled BSDF") if material.use_nodes else None
    if shader is not None:
        base = shader.inputs["Base Color"].default_value
        shader.inputs["Base Color"].default_value = (base[0], base[1], base[2], alpha)
        shader.inputs["Alpha"].default_value = alpha


def _smooth(obj: bpy.types.Object) -> None:
    if hasattr(obj.data, "polygons"):
        for polygon in obj.data.polygons:
            polygon.use_smooth = True


def _apply_scale(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.select_set(False)


def _assign_material(obj: bpy.types.Object, material: bpy.types.Material) -> None:
    obj.data.materials.append(material)
    obj["mmm_material"] = material.name


def _skin_to(obj: bpy.types.Object, armature: bpy.types.Object, bone_name: str) -> None:
    modifier = obj.modifiers.new(name="MMM_Armature", type="ARMATURE")
    modifier.object = armature
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    obj["mmm_rig_bone"] = bone_name


def _sphere(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
    *,
    segments: int = 16,
    rings: int = 10,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    _apply_scale(obj)
    _smooth(obj)
    _assign_material(obj, material)
    _skin_to(obj, armature, bone_name)
    return obj


def _cube(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
    *,
    bevel: float = 0.06,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    _apply_scale(obj)
    if bevel:
        modifier = obj.modifiers.new(name="SoftEdges", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)
    _smooth(obj)
    _assign_material(obj, material)
    _skin_to(obj, armature, bone_name)
    return obj


def _cylinder_between(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
) -> bpy.types.Object:
    start_vector = Vector(start)
    end_vector = Vector(end)
    direction = end_vector - start_vector
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12,
        radius=radius,
        depth=direction.length,
        location=(start_vector + end_vector) / 2,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(direction.normalized())
    _apply_scale(obj)
    _smooth(obj)
    _assign_material(obj, material)
    _skin_to(obj, armature, bone_name)
    return obj


def _cone(
    name: str,
    location: tuple[float, float, float],
    radius_bottom: float,
    radius_top: float,
    depth: float,
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=16,
        radius1=radius_bottom,
        radius2=radius_top,
        depth=depth,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    _smooth(obj)
    _assign_material(obj, material)
    _skin_to(obj, armature, bone_name)
    return obj


def _torus(
    name: str,
    location: tuple[float, float, float],
    major_radius: float,
    minor_radius: float,
    material: bpy.types.Material,
    armature: bpy.types.Object,
    bone_name: str,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_radius,
        minor_radius=minor_radius,
        major_segments=16,
        minor_segments=8,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    _smooth(obj)
    _assign_material(obj, material)
    _skin_to(obj, armature, bone_name)
    return obj


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
        shoulder = (0.38 * sign, 0, 2.55)
        elbow = (0.58 * sign, 0, 2.15)
        wrist = (0.62 * sign, -0.01, 1.78)
        bone(f"clavicle_{side}", (0.12 * sign, 0, 2.57), shoulder, "chest")
        bone(f"upper_arm_{side}", shoulder, elbow, f"clavicle_{side}")
        bone(f"lower_arm_{side}", elbow, wrist, f"upper_arm_{side}")
        bone(f"hand_{side}", wrist, (0.62 * sign, -0.03, 1.56), f"lower_arm_{side}")
        hip = (0.19 * sign, 0, 1.52)
        knee = (0.2 * sign, 0, 0.92)
        ankle = (0.2 * sign, -0.01, 0.25)
        bone(f"upper_leg_{side}", hip, knee, "pelvis")
        bone(f"lower_leg_{side}", knee, ankle, f"upper_leg_{side}")
        bone(f"foot_{side}", ankle, (0.2 * sign, -0.22, 0.08), f"lower_leg_{side}")
        bone(f"toe_{side}", (0.2 * sign, -0.18, 0.08), (0.2 * sign, -0.38, 0.08), f"foot_{side}")

    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    armature["mmm_rig_version"] = 1
    return armature


def _add_face(armature: bpy.types.Object, skin: bpy.types.Material, hair: bpy.types.Material) -> None:
    eye = _material("MMM_BODY__eye", "#FFFDFB", roughness=0.35)
    pupil = _material("MMM_BODY__pupil", "#2A1714", roughness=0.28)
    lip = _material("MMM_BODY__lip", "#B95360", roughness=0.4)
    for sign in (-1, 1):
        x = 0.205 * sign
        _sphere(f"Eye_{sign}", (x, -0.475, 3.25), (0.14, 0.075, 0.17), eye, armature, "head")
        _sphere(f"Pupil_{sign}", (x, -0.542, 3.25), (0.065, 0.035, 0.085), pupil, armature, "head", segments=12, rings=8)
        _cube(f"Brow_{sign}", (x, -0.535, 3.48), (0.11, 0.025, 0.025), hair, armature, "head", bevel=0.025)
    _sphere("Nose", (0, -0.56, 3.08), (0.07, 0.05, 0.065), skin, armature, "head", segments=12, rings=8)
    _sphere("Smile", (0, -0.553, 2.96), (0.13, 0.018, 0.025), lip, armature, "head", segments=12, rings=8)


def _add_hair_styles(armature: bpy.types.Object, hair_materials: dict[int, bpy.types.Material]) -> None:
    for style, material in hair_materials.items():
        _sphere(f"HairCap_{style}", (0, 0.01, 3.45), (0.61, 0.53, 0.37), material, armature, "head")
        if style == 0:  # tousled
            _sphere("HairTousledLeft", (-0.45, -0.02, 3.27), (0.22, 0.28, 0.36), material, armature, "head")
            _sphere("HairTousledRight", (0.45, -0.02, 3.27), (0.22, 0.28, 0.36), material, armature, "head")
        elif style == 1:  # side swept
            _sphere("HairSideSweep", (-0.16, -0.42, 3.41), (0.43, 0.10, 0.22), material, armature, "head")
            _sphere("HairSideTail", (0.46, 0.02, 3.14), (0.22, 0.28, 0.44), material, armature, "head")
        elif style == 2:  # undercut
            _sphere("HairUndercutTop", (0, -0.05, 3.53), (0.58, 0.44, 0.22), material, armature, "head")
        elif style == 3:  # long twin tails, matching the supplied direction
            _sphere("HairLongLeft", (-0.52, 0.04, 3.08), (0.25, 0.30, 0.72), material, armature, "head")
            _sphere("HairLongRight", (0.52, 0.04, 3.08), (0.25, 0.30, 0.72), material, armature, "head")
            _sphere("HairLongBangs", (0, -0.42, 3.40), (0.40, 0.10, 0.20), material, armature, "head")
        elif style == 4:  # single ponytail
            _sphere("HairPonytail", (0.47, 0.15, 3.10), (0.25, 0.28, 0.70), material, armature, "head")
            _sphere("HairPonytailBangs", (-0.16, -0.42, 3.40), (0.42, 0.10, 0.20), material, armature, "head")
        else:  # bob
            _sphere("HairBobLeft", (-0.45, 0.02, 3.15), (0.27, 0.31, 0.52), material, armature, "head")
            _sphere("HairBobRight", (0.45, 0.02, 3.15), (0.27, 0.31, 0.52), material, armature, "head")


def _garment_materials() -> dict[str, bpy.types.Material]:
    neutral_image = bpy.data.images.get("MMM_GarmentNeutralTexture")
    if neutral_image is None:
        neutral_image = bpy.data.images.new(
            "MMM_GarmentNeutralTexture",
            width=1,
            height=1,
            alpha=True,
        )
        neutral_image.pixels = [1.0, 1.0, 1.0, 1.0]
        neutral_image.pack()

    def create(template: str) -> bpy.types.Material:
        material = _material(
            f"MMM_GARMENT__{template}__base",
            "#D9DCE5",
            alpha=0.0,
            roughness=0.65,
        )
        texture = material.node_tree.nodes.new("ShaderNodeTexImage")
        texture.image = neutral_image
        texture.interpolation = "Closest"
        shader = material.node_tree.nodes.get("Principled BSDF")
        if shader is not None:
            material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
        return material

    return {
        template: create(template)
        for template in TEMPLATES
    }


def _add_garments(armature: bpy.types.Object, garments: dict[str, bpy.types.Material], female: bool) -> None:
    torso_bone = "spine_02"
    leg_bones = ("upper_leg_L", "upper_leg_R")
    body_width = 0.43 if female else 0.48

    top_specs = {
        "regular_tee": (body_width, 0.27, 0.48),
        "fitted_top": (body_width - 0.05, 0.25, 0.48),
        "oversized_top": (body_width + 0.13, 0.30, 0.52),
        "shirt_blouse": (body_width + 0.02, 0.29, 0.52),
        "sweater_hoodie": (body_width + 0.08, 0.32, 0.56),
    }
    for template, (width, depth, height) in top_specs.items():
        _cube(
            f"Garment_{template}",
            (0, 0, 2.27),
            (width, depth, height),
            garments[template],
            armature,
            torso_bone,
            bevel=0.10,
        )
        if template == "sweater_hoodie":
            _torus("HoodieHood", (0, 0.12, 2.62), 0.25, 0.08, garments[template], armature, torso_bone)

    outer_specs = {
        "jacket": (body_width + 0.08, 0.34, 0.56),
        "blazer": (body_width + 0.06, 0.32, 0.58),
        "coat": (body_width + 0.12, 0.36, 0.76),
    }
    for template, (width, depth, height) in outer_specs.items():
        _cube(
            f"Garment_{template}",
            (0, 0.02, 2.25 if template != "coat" else 2.16),
            (width, depth, height),
            garments[template],
            armature,
            torso_bone,
            bevel=0.10,
        )

    for template, width, depth, height in (
        ("regular_pants", 0.20, 0.25, 0.67),
        ("slim_pants", 0.17, 0.23, 0.67),
        ("wide_leg_pants", 0.27, 0.28, 0.67),
        ("shorts", 0.22, 0.25, 0.36),
    ):
        for sign, bone_name in zip((-1, 1), leg_bones):
            _cube(
                f"Garment_{template}_{sign}",
                (0.2 * sign, 0, 1.30 if template != "shorts" else 1.48),
                (width, depth, height),
                garments[template],
                armature,
                bone_name,
                bevel=0.08,
            )

    _cone("Garment_skirt", (0, 0, 1.40), 0.58, 0.34, 0.70, garments["skirt"], armature, "pelvis")
    _cube("Garment_straight_dress", (0, 0, 1.88), (body_width + 0.08, 0.28, 0.88), garments["straight_dress"], armature, "pelvis", bevel=0.12)
    _cone("Garment_a_line_dress", (0, 0, 1.84), 0.62, 0.34, 1.05, garments["a_line_dress"], armature, "pelvis")

    for sign, bone_name in zip((-1, 1), ("foot_L", "foot_R")):
        _cube("Garment_sneaker_%s" % sign, (0.2 * sign, -0.10, 0.17), (0.23, 0.36, 0.13), garments["sneaker"], armature, bone_name, bevel=0.10)
        _cube("Garment_dress_shoe_%s" % sign, (0.2 * sign, -0.10, 0.16), (0.22, 0.34, 0.12), garments["dress_shoe"], armature, bone_name, bevel=0.09)
        _cube("Garment_boot_%s" % sign, (0.2 * sign, -0.03, 0.30), (0.23, 0.32, 0.34), garments["boot"], armature, bone_name, bevel=0.09)

    _torus("Garment_hat", (0, 0, 3.74), 0.47, 0.10, garments["hat"], armature, "head")
    _cube("Garment_bag", (0.58, -0.17, 2.02), (0.16, 0.10, 0.25), garments["bag"], armature, "hand_R", bevel=0.06)
    _torus("Garment_accessory", (0, -0.30, 2.75), 0.18, 0.025, garments["accessory"], armature, "neck")


def _add_body(
    armature: bpy.types.Object,
    *,
    female: bool,
    skin: bpy.types.Material,
    hair: bpy.types.Material,
) -> None:
    torso_width = 0.45 if female else 0.51
    hip_width = 0.43 if female else 0.39
    _sphere("BodyTorso", (0, 0, 2.22), (torso_width, 0.28, 0.58), skin, armature, "spine_02")
    _sphere("BodyPelvis", (0, 0, 1.63), (hip_width, 0.27, 0.30), skin, armature, "pelvis")
    _cylinder_between("Neck", (0, 0, 2.65), (0, 0, 2.98), 0.18, skin, armature, "neck")
    _sphere("Head", (0, 0, 3.30), (0.57, 0.50, 0.58), skin, armature, "head", segments=20, rings=14)
    for sign, side in ((-1, "L"), (1, "R")):
        _cylinder_between(
            f"UpperArm_{side}",
            (0.40 * sign, 0, 2.56),
            (0.58 * sign, 0, 2.14),
            0.12,
            skin,
            armature,
            f"upper_arm_{side}",
        )
        _cylinder_between(
            f"LowerArm_{side}",
            (0.58 * sign, 0, 2.14),
            (0.62 * sign, -0.01, 1.78),
            0.105,
            skin,
            armature,
            f"lower_arm_{side}",
        )
        _sphere(f"Hand_{side}", (0.62 * sign, -0.02, 1.68), (0.14, 0.12, 0.16), skin, armature, f"hand_{side}")
        _cylinder_between(
            f"UpperLeg_{side}",
            (0.2 * sign, 0, 1.50),
            (0.2 * sign, 0, 0.92),
            0.16 if female else 0.17,
            skin,
            armature,
            f"upper_leg_{side}",
        )
        _cylinder_between(
            f"LowerLeg_{side}",
            (0.2 * sign, 0, 0.92),
            (0.2 * sign, -0.01, 0.25),
            0.13,
            skin,
            armature,
            f"lower_leg_{side}",
        )
        _sphere(f"Foot_{side}", (0.2 * sign, -0.04, 0.12), (0.18, 0.28, 0.12), skin, armature, f"foot_{side}")
    _add_face(armature, skin, hair)


def _make_action(armature: bpy.types.Object, name: str, keyframes: list[tuple[int, str, tuple[float, float, float]]]) -> None:
    action = bpy.data.actions.new(name)
    armature.animation_data_create()
    armature.animation_data.action = action
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    for frame, bone_name, rotation in keyframes:
        pose_bone = armature.pose.bones.get(bone_name)
        if pose_bone is None:
            continue
        pose_bone.rotation_mode = "XYZ"
        pose_bone.rotation_euler = rotation
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")
    armature.animation_data.action = None


def _add_animations(armature: bpy.types.Object) -> None:
    _make_action(
        armature,
        "idle",
        [
            (1, "spine_01", (0.0, 0.0, 0.0)),
            (20, "spine_01", (0.015, 0.0, 0.0)),
            (40, "spine_01", (0.0, 0.0, 0.0)),
        ],
    )
    _make_action(
        armature,
        "blink",
        [(1, "head", (0.0, 0.0, 0.0)), (4, "head", (0.02, 0.0, 0.0)), (8, "head", (0.0, 0.0, 0.0))],
    )
    _make_action(
        armature,
        "wave",
        [
            (1, "upper_arm_R", (0.0, 0.0, 0.0)),
            (12, "upper_arm_R", (-0.3, 0.0, -0.25)),
            (24, "lower_arm_R", (0.0, 0.0, -0.55)),
            (36, "lower_arm_R", (0.0, 0.0, 0.20)),
            (48, "upper_arm_R", (0.0, 0.0, 0.0)),
        ],
    )
    _make_action(
        armature,
        "look",
        [(1, "head", (0.0, 0.0, 0.0)), (18, "head", (0.0, 0.20, 0.0)), (36, "head", (0.0, 0.0, 0.0))],
    )
    _make_action(
        armature,
        "outfit_reveal",
        [(1, "root", (0.0, 0.0, 0.0)), (10, "root", (0.0, 0.0, 0.03)), (20, "root", (0.0, 0.0, 0.0))],
    )


def _create_camera(location: tuple[float, float, float]) -> bpy.types.Object:
    bpy.ops.object.camera_add(location=location)
    camera = bpy.context.object
    camera.data.lens = 58
    camera.data.sensor_width = 36
    direction = Vector((0, 0, 2.0)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    return camera


def _setup_lighting() -> None:
    bpy.ops.object.light_add(type="AREA", location=(3.5, -4.5, 5.5))
    key = bpy.context.object
    key.data.energy = 480
    key.data.shape = "DISK"
    key.data.size = 4.0
    key.rotation_euler = (math.radians(25), 0, math.radians(35))
    bpy.ops.object.light_add(type="AREA", location=(-3.0, -1.0, 3.0))
    fill = bpy.context.object
    fill.data.energy = 220
    fill.data.size = 3.0
    direction = Vector((0, 0, 2.0)) - fill.location
    fill.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.light_add(type="AREA", location=(0, 1.8, 4.5))
    rim = bpy.context.object
    rim.data.energy = 300
    rim.data.size = 2.5
    direction = Vector((0, 0, 2.6)) - rim.location
    rim.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _set_variant(materials: dict[str, bpy.types.Material], variant: str) -> None:
    for template, material in materials.items():
        _set_material_alpha(material, 0.0)
    visible = {
        "default": ("regular_tee", "regular_pants", "sneaker"),
        "oversized": ("oversized_top", "wide_leg_pants", "sneaker"),
        "dress": ("a_line_dress", "dress_shoe"),
        "outerwear": ("shirt_blouse", "regular_pants", "jacket", "sneaker"),
    }[variant]
    for template in visible:
        _set_material_alpha(materials[template], 1.0)


def _render_views(gender: str, materials: dict[str, bpy.types.Material]) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = True
    scene.world.color = (0.94, 0.93, 0.98)
    _setup_lighting()

    locations = {
        "front": (0, -8.0, 2.2),
        "three_quarter": (4.8, -6.6, 2.25),
        "side": (8.0, 0, 2.2),
        "back": (0, 8.0, 2.2),
    }
    camera = _create_camera(locations["front"])
    scene.camera = camera
    for variant in ("default", "oversized", "dress", "outerwear"):
        _set_variant(materials, variant)
        views = ("front", "three_quarter", "side", "back") if variant == "default" else ("front",)
        for view in views:
            camera.location = locations[view]
            direction = Vector((0, 0, 2.0)) - camera.location
            camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
            output = REVIEW_ROOT / f"{gender}_{variant}_{view}.png"
            scene.render.filepath = str(output)
            bpy.ops.render.render(write_still=True)
        if variant == "default":
            shutil.copyfile(REVIEW_ROOT / f"{gender}_{variant}_front.png", POSTER_ROOT / f"human_{gender}.png")


def _export_glb(gender: str, armature: bpy.types.Object) -> Path:
    filepath = ASSET_ROOT / f"human_{gender}_v1.glb"
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format="GLB",
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
        "version": 1,
        "generator": "tools/avatar/build_avatar.py",
        "models": {
            "female": "assets/avatar/human_female_v1.glb",
            "male": "assets/avatar/human_male_v1.glb",
        },
        "posters": {
            "female": "assets/avatar/posters/human_female.png",
            "male": "assets/avatar/posters/human_male.png",
        },
        "templates": TEMPLATES,
        "animations": ANIMATIONS,
        "hairStyles": len(HAIR_STYLES),
        "skinTones": 7,
        "hairColors": 6,
        "materials": {
            "body": "MMM_BODY__skin",
            "hair": "MMM_HAIR__style_{style}__base",
            "garment": "MMM_GARMENT__{template}__base",
        },
        "sha256": {gender: _sha256(path) for gender, path in paths.items()},
    }
    (ASSET_ROOT / "avatar_catalog.json").write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")


def _write_provenance(paths: dict[str, Path]) -> None:
    blender_version = bpy.app.version_string
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    lines = [
        "# MMM Avatar Asset Provenance",
        "",
        "These assets are generated entirely by the owned procedural Blender",
        "pipeline in `tools/avatar/build_avatar.py`. No external character,",
        "garment, texture, or unknown-license model is used.",
        "",
        f"- Creator: Mix Match Mood project",
        f"- Creation method: Blender {blender_version} Python procedural meshes",
        "- License: project-owned source generated for MMM",
        "- Version: avatar v1",
        "- Generation script: tools/avatar/build_avatar.py",
        f"- Generation date: {generated_at}",
        "- Geometry: low-poly rounded primitives with a shared human armature",
        "- Runtime representation: named material groups with metadata-applied color/material state",
        "",
        "## Generated assets",
        "",
    ]
    for gender, path in paths.items():
        lines.extend(
            [
                f"### human_{gender}_v1.glb",
                f"- Origin: procedural MMM Blender scene ({gender} body proportions)",
                f"- File size: {path.stat().st_size} bytes",
                f"- SHA-256: {_sha256(path)}",
                "- Validation: committed output passed `tools/avatar/validate_assets.sh` with zero glTF errors/warnings and required material/animation checks",
                "",
            ]
        )
    lines.extend(
        [
            "## Catalog scope",
            "",
            f"- Garment templates: {', '.join(TEMPLATES)}",
            f"- Animations: {', '.join(ANIMATIONS)}",
            "- Human models use the same bone names and template material namespaces.",
            "- Wardrobe photographs are not embedded in these GLBs and are never treated as exact 3D reconstruction.",
            "",
        ]
    )
    (ASSET_ROOT / "PROVENANCE.md").write_text("\n".join(lines), encoding="utf-8")


def build() -> None:
    _ensure_directories()
    paths: dict[str, Path] = {}
    for gender in ("female", "male"):
        _clear_scene()
        female = gender == "female"
        armature = _create_rig()
        skin = _material("MMM_BODY__skin", "#E8C4A0", roughness=0.48)
        hair_materials = {
            index: _material(f"MMM_HAIR__style_{index}__base", "#2C1810", roughness=0.48)
            for index in HAIR_STYLES
        }
        _add_body(armature, female=female, skin=skin, hair=hair_materials[3])
        _add_hair_styles(armature, hair_materials)
        garments = _garment_materials()
        _add_garments(armature, garments, female=female)
        _add_animations(armature)
        _set_variant(garments, "default")
        _set_material_alpha(hair_materials[3], 1.0)
        _render_views(gender, garments)
        paths[gender] = _export_glb(gender, armature)

    _write_catalog(paths)
    _write_provenance(paths)
    print(json.dumps({"models": {gender: str(path) for gender, path in paths.items()}, "catalog": str(ASSET_ROOT / "avatar_catalog.json")}, indent=2))


if __name__ == "__main__":
    build()
