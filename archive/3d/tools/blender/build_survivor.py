"""Build the original prototype survivor. Run with Blender --background --python."""

from pathlib import Path
import bpy


ROOT = Path(__file__).resolve().parents[2]


def material(name, color, metallic=0.0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1.0)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = 0.82
    shader.inputs["Metallic"].default_value = metallic
    return result


def pivot(name, position):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.location = position
    return obj


def box(name, position, size, surface, parent=None, bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(surface)
    if bevel:
        modifier = obj.modifiers.new("Soft manufactured edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.parent = parent
    obj.location = position
    return obj


def main():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    olive = material("Faded field jacket", (0.22, 0.29, 0.20))
    dark = material("Charcoal canvas", (0.075, 0.105, 0.12))
    skin = material("Skin", (0.64, 0.41, 0.28))
    leather = material("Boots and gloves", (0.065, 0.052, 0.043))
    pack = material("Weathered backpack", (0.29, 0.22, 0.13))
    tape = material("Rescue amber", (0.94, 0.52, 0.12))
    steel = material("Buckle", (0.35, 0.40, 0.39), 0.45)
    # Blender +Y becomes Godot -Z (forward); all coordinates are metres.
    box("Jacket", (0, 0, 1.22), (0.56, 0.34, 0.58), olive)
    box("Belt", (0, 0, 0.94), (0.53, 0.35, 0.09), leather)
    box("Buckle", (0, 0.185, 0.94), (0.1, 0.03, 0.07), steel, bevel=0.01)
    box("Head", (0, 0.005, 1.66), (0.32, 0.3, 0.34), skin, bevel=0.065)
    box("Hair", (0, -0.025, 1.79), (0.34, 0.29, 0.14), leather)
    box("Mask", (0, 0.16, 1.6), (0.29, 0.07, 0.13), dark)
    for x in (-0.083, 0.083):
        box("Eye", (x, 0.158, 1.715), (0.038, 0.016, 0.026), leather, bevel=0.003)
        box("PackStrap", (x * 2, 0.181, 1.24), (0.06, 0.03, 0.46), pack, bevel=0.008)
    box("Backpack", (0, -0.26, 1.24), (0.42, 0.24, 0.49), pack, bevel=0.06)
    box("PackPocket", (0, -0.4, 1.15), (0.29, 0.065, 0.22), dark)
    box("RescuePatchVertical", (0, -0.439, 1.17), (0.045, 0.013, 0.12), tape, bevel=0.002)
    box("RescuePatchHorizontal", (0, -0.44, 1.17), (0.12, 0.013, 0.045), tape, bevel=0.002)
    for side, x in (("Left", -1), ("Right", 1)):
        arm = pivot(f"Arm{side}Pivot", (x * 0.37, 0, 1.43))
        box(f"Sleeve{side}", (0, 0, -0.23), (0.19, 0.24, 0.46), olive, arm)
        box(f"Glove{side}", (0, 0.01, -0.5), (0.16, 0.21, 0.16), leather, arm)
        if side == "Left":
            box("Armband", (0, 0, -0.17), (0.2, 0.25, 0.085), tape, arm, bevel=0.012)
        leg = pivot(f"Leg{side}Pivot", (x * 0.145, 0, 0.89))
        box(f"Trousers{side}", (0, 0, -0.35), (0.225, 0.28, 0.7), dark, leg)
        box(f"Kneepad{side}", (0, 0.145, -0.4), (0.17, 0.07, 0.17), olive, leg)
        box(f"Boot{side}", (0, 0.06, -0.78), (0.24, 0.4, 0.22), leather, leg)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    source = ROOT / "art" / "blender" / "survivor.blend"
    output = ROOT / "assets" / "characters" / "survivor.glb"
    source.parent.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.export_scene.gltf(filepath=str(output), export_format="GLB", export_yup=True)
    print(f"Survivor source: {source}\nGame asset: {output}")


if __name__ == "__main__":
    main()
