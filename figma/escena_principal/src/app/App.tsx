import React from "react";
import {
  HabilidadesIcon,
  ProgresoIcon,
  ActividadesIcon,
  SaludIcon,
  MonedaIcon,
  PerfilMiniIcon,
  TiendaMiniIcon,
  HorarioMiniIcon,
} from "./components/PixelIcons";

/*
  ═══════════════════════════════════════════════════════════════════
  GODOT 4 NODE MAPPING (GDScript reference)
  ═══════════════════════════════════════════════════════════════════
  Root               → Control (anchors full_rect)

  TopBar             → HBoxContainer
                         custom_minimum_size.y = 72
                         StyleBoxFlat bg = #2C2C2C
    btn_perfil       → Button → HBoxContainer
                           TextureRect (perfil_mini_icon.svg, 18×18)
                           Label ("Perfil", color=#EEEEEE, size=16)
                         StyleBoxFlat bg=#3A3A3A, border=#4A4A4A 1px, r=8
    btn_tienda       → Button → HBoxContainer
                           TextureRect (tienda_mini_icon.svg, 18×18)
                           Label ("Tienda")
    btn_horario      → Button → HBoxContainer
                           TextureRect (horario_mini_icon.svg, 18×18)
                           Label ("Horario")
    money_widget     → HBoxContainer (right-aligned via HSeparator spacer)
      lbl_money      → Label ("800", color=#FFD700, bold, size=20)
      icon_moneda    → TextureRect (moneda_icon.svg, 48×48)

  MainContent        → Control (anchor stretch, bg=#1A1A1A)

  BottomNav          → HBoxContainer
                         custom_minimum_size.y = 160
                         StyleBoxFlat bg = #2C2C2C
    btn_habilidades  → Button → VBoxContainer
                           TextureRect (habilidades_icon.svg, 80×80)
                           Label ("Habilidades", size=12)
                         StyleBoxFlat bg=#1565C0, border=#0D47A1 2px, r=16
    btn_progreso     → Button → VBoxContainer
                           TextureRect (progreso_icon.svg, 80×80)
                           Label ("Progreso", size=12)
    btn_actividades  → Button → VBoxContainer
                           TextureRect (actividades_icon.svg, 80×80)
                           Label ("Actividades", size=12)
    btn_salud        → Button → VBoxContainer
                           TextureRect (salud_icon.svg, 80×80)
                           Label ("Salud", size=12)

  ═══════════════════════════════════════════════════════════════════
  CSS → Godot StyleBoxFlat color mapping:
    --bg-base:     #1A1A1A  → bg_color of main Control
    --bg-surface:  #2C2C2C  → bg_color of HBoxContainer bars
    --bg-button:   #3A3A3A  → bg_color of top Button nodes
    --bg-navcard:  #1565C0  → bg_color of bottom nav Button nodes
    --bg-navcard-active: #1976D2 → active nav card
    --border-top:  #4A4A4A  → border_color of top buttons (1px)
    --border-nav:  #0D47A1  → border_color of nav cards (2px)
    --border-nav-active: #64B5F6
    --text-main:   #EEEEEE  → font_color Labels
    --color-green: #4CAF50  → good state / progreso bar 1
    --color-orange:#FF9800  → warning / progreso bar 2
    --color-red:   #F44336  → critical / progreso bar 3 / salud icon
    --color-money: #FFD700  → money label + coin base
    --color-star:  #FFD700  → habilidades stars
    --coin-border: #F59E00  → coin dark-gold border
    --coin-symbol: #7B4F00  → € symbol on coin
  ═══════════════════════════════════════════════════════════════════
*/

const NAV_CARDS: {
  id: string;
  label: string;
  Icon: React.FC<{ size?: number }>;
}[] = [
  { id: "habilidades", label: "Habilidades", Icon: HabilidadesIcon },
  { id: "progreso",    label: "Progreso",    Icon: ProgresoIcon },
  { id: "actividades", label: "Actividades", Icon: ActividadesIcon },
  { id: "salud",       label: "Salud",       Icon: SaludIcon },
];

// Top bar button definitions
// Godot: three Button nodes inside HBoxContainer, all share same StyleBoxFlat
const TOP_BUTTONS: {
  label: string;
  Icon?: React.FC<{ size?: number }>;
}[] = [
  { label: "Perfil",  Icon: PerfilMiniIcon },
  { label: "Tienda",  Icon: TiendaMiniIcon },
  { label: "Horario", Icon: HorarioMiniIcon },
];

export default function App() {
  const money = 800;

  return (
    /* Outer shell — constrains to mobile portrait 720×1280 */
    <div
      style={{ background: "#111" }}
      className="min-h-screen w-full flex items-center justify-center"
    >
      <div
        style={{
          width: "min(720px, 100vw)",
          height: "min(1280px, 100svh)",
          background: "#1A1A1A",
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
          position: "relative",
          fontFamily: "'Courier New', Courier, monospace",
        }}
      >
        {/* ── ZONE 1 · Top bar (HBoxContainer) ───────────────────────── */}
        {/* Godot: HBoxContainer, custom_minimum_size.y = 72, StyleBoxFlat bg=#2C2C2C */}
        <div
          style={{
            height: 72,
            minHeight: 72,
            background: "#2C2C2C",
            display: "flex",
            alignItems: "center",
            padding: "0 8px",
            gap: 8,
          }}
        >
          {/* Three equal top buttons — all identical bg/border */}
          {/* Godot: Button → HBoxContainer (TextureRect + Label) or Label only */}
          {TOP_BUTTONS.map(({ label, Icon }) => (
            <button
              key={label}
              style={{
                flex: 1,
                height: 48,
                background: "#3A3A3A",
                color: "#EEEEEE",
                border: "1px solid #4A4A4A",
                borderRadius: 8,
                fontSize: 16,
                fontFamily: "inherit",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 6,
              }}
            >
              {/* Godot: TextureRect (icon) + Label (text) inside HBoxContainer */}
              {Icon && (
                <span style={{ display: "flex", alignItems: "center", flexShrink: 0 }}>
                  <Icon size={18} />
                </span>
              )}
              <span>{label}</span>
            </button>
          ))}

          {/* Spacer pushes money widget to far right */}
          <div style={{ flex: 1 }} />

          {/* Money widget — HBoxContainer: Label + TextureRect */}
          {/* Godot: HBoxContainer → Label(lbl_money) + TextureRect(icon_moneda) */}
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <span
              style={{
                color: "#FFD700",
                fontSize: 20,
                fontWeight: "bold",
                fontFamily: "inherit",
                letterSpacing: 1,
              }}
            >
              {money}
            </span>
            {/* Godot: TextureRect, texture = moneda_icon.svg, size = 48×48 */}
            <div style={{ width: 48, height: 48 }}>
              <MonedaIcon size={48} />
            </div>
          </div>
        </div>

        {/* ── ZONE 2 · Main content area (Control, anchor stretch) ─────── */}
        {/* Godot: Control node, anchors = full_rect minus top/bottom bars, bg=#1A1A1A */}
        <div
          style={{
            flex: 1,
            background: "#1A1A1A",
            position: "relative",
            overflow: "hidden",
          }}
        >
          {/* Reference grid overlay — not part of final Godot scene */}
          <svg
            style={{
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              opacity: 0.04,
            }}
            xmlns="http://www.w3.org/2000/svg"
          >
            <defs>
              <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#EEE" strokeWidth="0.5"/>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)"/>
          </svg>
          <div
            style={{
              position: "absolute",
              inset: 0,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#2A2A2A",
              fontSize: 13,
              fontFamily: "inherit",
              letterSpacing: 2,
              textTransform: "uppercase",
              userSelect: "none",
            }}
          >
            [ game viewport ]
          </div>
        </div>

        {/* ── ZONE 3 · Bottom nav bar (HBoxContainer) ──────────────────── */}
        {/* Godot: HBoxContainer, custom_minimum_size.y = 160, StyleBoxFlat bg=#2C2C2C */}
        <div
          style={{
            height: 160,
            minHeight: 160,
            background: "#2C2C2C",
            display: "flex",
            alignItems: "center",
            padding: "0 8px",
            gap: 8,
          }}
        >
          {NAV_CARDS.map(({ id, label, Icon }) => (
            /* Godot: Button → VBoxContainer (TextureRect icon + Label text) */
            /* StyleBoxFlat bg=#1565C0, r=16, no border, no selected state */
            <button
              key={id}
              style={{
                flex: 1,
                height: 140,
                background: "#1565C0",
                border: "none",
                borderRadius: 16,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: 8,
                cursor: "pointer",
                padding: 0,
              }}
            >
              {/* Godot: TextureRect, custom_minimum_size = 80×80 */}
              <div style={{ width: 80, height: 80 }}>
                <Icon size={80} />
              </div>
              {/* Godot: Label, font_size=12, font_color=#EEEEEE */}
              <span
                style={{
                  color: "#EEEEEE",
                  fontSize: 12,
                  fontFamily: "inherit",
                  letterSpacing: 0.5,
                  lineHeight: 1,
                }}
              >
                {label}
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
