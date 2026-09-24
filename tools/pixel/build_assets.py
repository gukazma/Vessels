"""Build the editable sunlit town, using separate environment and survivor art modules.

Run: python tools/pixel/build_assets.py (requires Pillow).
"""
from PIL import Image
from pixel_common import ROOT, ASSETS
from environment_art import build_environment
from survivor_art import survivor


def generate_level():
    """Emit ordinary editable scene nodes; no runtime procedural world building."""
    texture_names = ["street_ground", "clinic", "ranger", "tree_a", "tree_b", "wrecked_car",
                     "barrel", "crate", "barricade", "fence", "streetlamp",
                     "garden_bench", "flower_planter", "mailbox"]
    entries = []

    def prop(name, texture, x, y, collider):
        entries.append((name, texture, x, y, collider))

    prop("FieldClinic", "clinic", 306, 337, (142, 63, 0, -36))
    prop("RangerStation", "ranger", 660, 335, (142, 63, 0, -36))
    for index, (x, y) in enumerate([(382, 333), (373, 320), (746, 335), (602, 350), (596, 523)]):
        prop(f"Barrel{index}", "barrel", x, y, (17, 13, 0, -6))
    for index, (x, y) in enumerate([(220, 348), (249, 353), (735, 350), (711, 521), (741, 529)]):
        prop(f"Crate{index}", "crate", x, y, (27, 19, 0, -12))
    for index, (x, y) in enumerate([(443, 228), (526, 228), (519, 520)]):
        prop(f"Barricade{index}", "barricade", x, y, (60, 15, 0, -9))
    for index, (x, y) in enumerate([(265, 214), (369, 214), (595, 214), (699, 214), (285, 537), (663, 563)]):
        prop(f"Fence{index}", "fence", x, y, (102, 5, 0, -5))
    for index, (x, y) in enumerate([(617, 440), (352, 494), (483, 129)]):
        prop(f"Car{index}", "wrecked_car", x, y, (64, 25, 0, -16))
    for index, (x, y) in enumerate([(190, 330), (782, 349), (199, 520), (376, 570), (778, 532),
                                    (237, 195), (752, 197), (150, 244), (808, 252), (306, 594), (691, 625)]):
        prop(f"Tree{index}", "tree_a" if index % 2 else "tree_b", x, y, (13, 11, 0, -10))
    for index, (x, y) in enumerate([(393, 349), (568, 489), (555, 224)]):
        prop(f"Lamp{index}", "streetlamp", x, y, (8, 8, 6, -7))
    prop("GardenBench", "garden_bench", 277, 503, (48, 11, 0, -6))
    prop("ClinicFlowers", "flower_planter", 258, 354, (50, 13, 0, -9))
    prop("MarketFlowers", "flower_planter", 700, 354, (50, 13, 0, -9))
    prop("GardenFlowers", "flower_planter", 251, 534, (50, 13, 0, -9))
    prop("Mailbox", "mailbox", 364, 356, (11, 10, 1, -7))
    resource_count = 5 + len(texture_names) + len(entries) + 1
    lines = [f'[gd_scene load_steps={resource_count} format=3]', '',
             '[ext_resource type="PackedScene" path="res://features/player/player.tscn" id="player"]',
             '[ext_resource type="PackedScene" path="res://features/hud/movement_hud.tscn" id="hud"]',
             '[ext_resource type="Script" path="res://levels/quarantine_street.gd" id="level"]',
             '[ext_resource type="Script" path="res://features/environment/town_ambience.gd" id="ambience"]']
    for name in texture_names:
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/pixel/{name}.png" id="{name}"]')
    for name, _, _, _, (w, h, _, _) in entries:
        lines += ['', f'[sub_resource type="RectangleShape2D" id="{name}Shape"]', f'size = Vector2({w}, {h})']
    lines += ['', '[sub_resource type="WorldBoundaryShape2D" id="Boundary"]', '',
              '[node name="QuarantineStreet" type="Node2D"]', 'texture_filter = 1', 'script = ExtResource("level")', '',
              '[node name="Ground" type="Sprite2D" parent="."]', 'texture = ExtResource("street_ground")', 'centered = false', '',
              '[node name="Actors" type="Node2D" parent="."]', 'y_sort_enabled = true']
    for name, texture, x, y, (_, _, ox, oy) in entries:
        height = Image.open(ASSETS / f"{texture}.png").height
        lines += ['', f'[node name="{name}" type="StaticBody2D" parent="Actors"]',
                  f'position = Vector2({x}, {y})', 'collision_layer = 1', 'collision_mask = 2', '',
                  f'[node name="Sprite" type="Sprite2D" parent="Actors/{name}"]',
                  f'texture = ExtResource("{texture}")', f'offset = Vector2(0, {-height / 2})', '',
                  f'[node name="Collision" type="CollisionShape2D" parent="Actors/{name}"]',
                  f'position = Vector2({ox}, {oy})', f'shape = SubResource("{name}Shape")']
    lines += ['', '[node name="Player" parent="Actors" instance=ExtResource("player")]',
              'position = Vector2(480, 402)', '',
              '[node name="Bounds" type="StaticBody2D" parent="."]', 'collision_layer = 1', 'collision_mask = 2']
    for name, x, y, rotation in [('Top', 0, 16, 3.141593), ('Bottom', 0, 624, 0),
                               ('Left', 16, 0, 1.570796), ('Right', 944, 0, -1.570796)]:
        lines += ['', f'[node name="{name}" type="CollisionShape2D" parent="Bounds"]',
                  f'position = Vector2({x}, {y})', f'rotation = {rotation}', 'shape = SubResource("Boundary")']
    lines += ['', '[node name="TownAmbience" type="Node2D" parent="."]',
              'z_index = 2', 'script = ExtResource("ambience")', '',
              '[node name="MovementHUD" parent="." instance=ExtResource("hud")]',
              'player_path = NodePath("../Actors/Player")', '']
    destination = ROOT / 'levels' / 'quarantine_street.tscn'
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text('\n'.join(lines), encoding='utf-8')


def main():
    build_environment()
    survivor()
    generate_level()
    print("Built sunlit town art, survivor animation, and the editable level.")


if __name__ == "__main__":
    main()
