#!/usr/bin/env python3
"""Build the editable Godot scene from the layout produced by componer_escenario.py."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LAYOUT_PATH = ROOT / "Imagenes" / "Minijuego_Cocina" / "escenario_layout.json"
OUT = ROOT / "Escenas" / "Minijuego_Cocina" / "Escenario_Maqueta_Cocina.tscn"
SCRIPT = "res://Scripts/GUI/Minijuego_Cocina/Escenario_Maqueta_Cocina.gd"
FONT_TIT = "res://Fuentes/UI/Bricolage-800.ttf"
FONT_UI = "res://Fuentes/UI/DMSans-700.ttf"


def q(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    layout = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
    tex_ids = {"Fondo_Restaurante.png": "tex_1"}
    ext = [("tex_1", "Texture2D", "res://Imagenes/Minijuego_Cocina/Fondo_Restaurante.png")]
    for item in layout:
        rel = item["ruta"]
        if rel not in tex_ids:
            tex_ids[rel] = f"tex_{len(tex_ids) + 1}"
            ext.append((tex_ids[rel], "Texture2D", "res://Imagenes/Minijuego_Cocina/" + rel))
    ext.append(("font_tit", "FontFile", FONT_TIT))
    ext.append(("font_ui", "FontFile", FONT_UI))
    ext.append(("script", "Script", SCRIPT))

    lines = [f'[gd_scene load_steps={len(ext) + 1} format=3]', ""]
    for eid, typ, path in ext:
        lines.append(f'[ext_resource type="{typ}" path="{path}" id="{eid}"]')
    lines.append("")

    lines += [
        '[node name="Escenario_Maqueta_Cocina" type="Control"]',
        "layout_mode = 3",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        f'script = ExtResource("script")',
        "",
        '[node name="Fondo_Ventana" type="ColorRect" parent="."]',
        "layout_mode = 1",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        "mouse_filter = 2",
        "color = Color(0.055, 0.078, 0.11, 1)",
        "z_index = -100",
        "",
        '[node name="Lienzo" type="Control" parent="."]',
        "layout_mode = 1",
        "anchors_preset = 8",
        "anchor_left = 0.5",
        "anchor_top = 0.5",
        "anchor_right = 0.5",
        "anchor_bottom = 0.5",
        "offset_left = -640.0",
        "offset_top = -360.0",
        "offset_right = 640.0",
        "offset_bottom = 360.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        "",
        '[node name="Fondo" type="TextureRect" parent="Lienzo"]',
        "layout_mode = 0",
        "offset_left = 0.0",
        "offset_top = 0.0",
        "offset_right = 1280.0",
        "offset_bottom = 720.0",
        "mouse_filter = 2",
        "texture = ExtResource(\"tex_1\")",
        "expand_mode = 1",
        "stretch_mode = 0",
        "z_index = 0",
        "",
        '[node name="HUD_Barra" type="ColorRect" parent="Lienzo"]',
        "layout_mode = 0",
        "offset_left = 0.0",
        "offset_top = 0.0",
        "offset_right = 1280.0",
        "offset_bottom = 58.0",
        "mouse_filter = 2",
        "color = Color(0.055, 0.098, 0.165, 1)",
        "",
        '[node name="HUD_Linea" type="ColorRect" parent="Lienzo"]',
        "layout_mode = 0",
        "offset_left = 0.0",
        "offset_top = 58.0",
        "offset_right = 1280.0",
        "offset_bottom = 62.0",
        "mouse_filter = 2",
        "color = Color(0.961, 0.62, 0.043, 1)",
        "",
    ]

    used_names = {}
    for i, item in enumerate(layout, start=1):
        rel = item["ruta"]
        stem = Path(rel).stem
        used_names[stem] = used_names.get(stem, 0) + 1
        name = stem if used_names[stem] == 1 else f"{stem}_{used_names[stem]}"
        z = 10 + i * 2
        groups = []
        if stem.startswith("Ticket_"):
            groups.append("ticket")
        elif stem.startswith("Chef_"):
            groups.append("chef")
        elif stem.startswith("Vapor"):
            groups.append("vapor")
        elif stem.startswith("Chispas"):
            groups.append("sparkle")
        group_line = f' groups={groups}'.replace("'", '"') if groups else ""
        lines += [
            f'[node name="{name}" type="TextureRect" parent="Lienzo"{group_line}]',
            "layout_mode = 0",
            f'offset_left = {float(item["x"])}',
            f'offset_top = {float(item["y"])}',
            f'offset_right = {float(item["x"] + item["w"])}',
            f'offset_bottom = {float(item["y"] + item["h"])}',
            "mouse_filter = 2",
            f'texture = ExtResource("{tex_ids[rel]}")',
            "expand_mode = 1",
            "stretch_mode = 0",
            f"z_index = {z}",
            "",
        ]
        if rel == "Mostrador/Frente_Mostrador.png":
            shelf_z = z + 1
            lines += [
                '[node name="Estante_Linea_A" type="ColorRect" parent="Lienzo"]',
                "layout_mode = 0",
                "offset_left = 0.0",
                "offset_top = 628.0",
                "offset_right = 1280.0",
                "offset_bottom = 636.0",
                "mouse_filter = 2",
                "color = Color(0.07, 0.086, 0.118, 1)",
                f"z_index = {shelf_z}",
                "",
                '[node name="Estante_Linea_B" type="ColorRect" parent="Lienzo"]',
                "layout_mode = 0",
                "offset_left = 0.0",
                "offset_top = 636.0",
                "offset_right = 1280.0",
                "offset_bottom = 642.0",
                "mouse_filter = 2",
                "color = Color(0.71, 0.745, 0.8, 1)",
                f"z_index = {shelf_z}",
                "",
                '[node name="Estante_Linea_C" type="ColorRect" parent="Lienzo"]',
                "layout_mode = 0",
                "offset_left = 0.0",
                "offset_top = 642.0",
                "offset_right = 1280.0",
                "offset_bottom = 648.0",
                "mouse_filter = 2",
                "color = Color(0.275, 0.306, 0.361, 0.7)",
                f"z_index = {shelf_z}",
                "",
            ]

    # Text labels (banner, HUD, ticket prices).
    lines += [
        '[node name="Texto_Burger" type="Label" parent="Lienzo"]',
        "layout_mode = 0",
        "offset_left = 28.0",
        "offset_top = 8.0",
        "offset_right = 328.0",
        "offset_bottom = 52.0",
        "mouse_filter = 2",
        'theme_override_colors/font_color = Color(1, 1, 1, 1)',
        'theme_override_colors/font_outline_color = Color(0.118, 0.275, 0.176, 1)',
        "theme_override_constants/outline_size = 6",
        'theme_override_fonts/font = ExtResource("font_tit")',
        "theme_override_font_sizes/font_size = 34",
        'text = "BURGER"',
        "z_index = 200",
        "",
        '[node name="Texto_Street" type="Label" parent="Lienzo"]',
        "layout_mode = 0",
        "offset_left = 28.0",
        "offset_top = 46.0",
        "offset_right = 328.0",
        "offset_bottom = 82.0",
        "mouse_filter = 2",
        'theme_override_colors/font_color = Color(1, 0.953, 0.667, 1)',
        'theme_override_colors/font_outline_color = Color(0.118, 0.275, 0.176, 1)',
        "theme_override_constants/outline_size = 5",
        'theme_override_fonts/font = ExtResource("font_tit")',
        "theme_override_font_sizes/font_size = 24",
        'text = "STREET"',
        "z_index = 200",
        "",
    ]

    hud = [("Texto_Monedas", 962, "1.250", (1.0, 0.925, 0.702, 1.0)),
           ("Texto_Gemas", 1088, "12", (0.745, 0.98, 1.0, 1.0)),
           ("Texto_Reloj", 1162, "00:45", (1.0, 1.0, 1.0, 1.0))]
    for name, x, value, col in hud:
        lines += [
            f'[node name="{name}" type="Label" parent="Lienzo"]',
            "layout_mode = 0",
            f"offset_left = {float(x)}",
            "offset_top = 14.0",
            f"offset_right = {float(x + 120)}",
            "offset_bottom = 44.0",
            "mouse_filter = 2",
            f'theme_override_colors/font_color = Color({col[0]}, {col[1]}, {col[2]}, {col[3]})',
            'theme_override_fonts/font = ExtResource("font_ui")',
            "theme_override_font_sizes/font_size = 19",
            'vertical_alignment = 1',
            f'text = "{value}"',
            "z_index = 200",
            "",
        ]

    prices = ["12", "10", "8", "6"]
    ticket_i = 0
    for item in layout:
        if not item["ruta"].startswith("UI/Ticket_"):
            continue
        price = prices[ticket_i] if ticket_i < len(prices) else ""
        ticket_i += 1
        cx = item["x"] + item["w"] / 2
        cy = item["y"] + item["h"] * 0.85
        lines += [
            f'[node name="Precio_Ticket_{ticket_i}" type="Label" parent="Lienzo" groups=["ticket"]]',
            "layout_mode = 0",
            f"offset_left = {cx - 40.0}",
            f"offset_top = {cy - 14.0}",
            f"offset_right = {cx + 40.0}",
            f"offset_bottom = {cy + 14.0}",
            "mouse_filter = 2",
            'theme_override_colors/font_color = Color(1, 0.98, 0.9, 1)',
            'theme_override_colors/font_outline_color = Color(0.118, 0.09, 0.04, 0.9)',
            "theme_override_constants/outline_size = 4",
            'theme_override_fonts/font = ExtResource("font_ui")',
            "theme_override_font_sizes/font_size = 19",
            "horizontal_alignment = 1",
            "vertical_alignment = 1",
            f'text = "{price}"',
            "z_index = 200",
            "",
        ]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(OUT, len(layout), "sprites")


if __name__ == "__main__":
    main()
