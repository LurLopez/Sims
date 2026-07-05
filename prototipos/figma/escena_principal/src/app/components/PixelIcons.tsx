// Pixel-art SVG icons for the life simulator game UI
// All icons use shapeRendering="crispEdges" for authentic pixel-art look
// Godot export: each icon → SVG file → TextureRect node

// ─── TOP BAR MINI ICONS (18×18) ────────────────────────────────────────────

export function PerfilMiniIcon({ size = 18 }: { size?: number }) {
  // Pixel-art person bust: head + shoulders silhouette
  // Godot: TextureRect, texture = perfil_mini_icon.svg, size = 18×18
  return (
    <svg width={size} height={size} viewBox="0 0 9 9" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {/* Head */}
      <rect x="3" y="0" width="3" height="3" fill="white"/>
      {/* Neck */}
      <rect x="4" y="3" width="1" height="1" fill="white"/>
      {/* Shoulders */}
      <rect x="1" y="4" width="7" height="3" fill="white"/>
      {/* Collar indent */}
      <rect x="3" y="4" width="3" height="1" fill="none"/>
    </svg>
  );
}

export function TiendaMiniIcon({ size = 18 }: { size?: number }) {
  // Pixel-art shopping bag: U-shaped handle arch + rectangular body
  // Godot: TextureRect, texture = tienda_mini_icon.svg, size = 18×18
  return (
    <svg width={size} height={size} viewBox="0 0 9 9" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {/* Handle top bar */}
      <rect x="3" y="1" width="3" height="1" fill="white"/>
      {/* Handle left & right sides */}
      <rect x="2" y="2" width="1" height="1" fill="white"/>
      <rect x="6" y="2" width="1" height="1" fill="white"/>
      {/* Bag body — full rectangle rows 3–7 */}
      <rect x="0" y="3" width="9" height="5" fill="white"/>
    </svg>
  );
}

export function HorarioMiniIcon({ size = 18 }: { size?: number }) {
  // Pixel-art calendar grid: rectangle body + 2×3 day grid inside
  // Godot: TextureRect, texture = horario_mini_icon.svg, size = 18×18
  return (
    <svg width={size} height={size} viewBox="0 0 9 9" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {/* Calendar body outline */}
      <rect x="0" y="1" width="9" height="8" fill="none" stroke="white" strokeWidth="1"/>
      {/* Header bar */}
      <rect x="0" y="1" width="9" height="2" fill="white"/>
      {/* Ring hangers */}
      <rect x="2" y="0" width="1" height="2" fill="white"/>
      <rect x="6" y="0" width="1" height="2" fill="white"/>
      {/* Day grid — 3 columns × 2 rows */}
      <rect x="1" y="4" width="1" height="1" fill="white"/>
      <rect x="4" y="4" width="1" height="1" fill="white"/>
      <rect x="7" y="4" width="1" height="1" fill="white"/>
      <rect x="1" y="6" width="1" height="1" fill="white"/>
      <rect x="4" y="6" width="1" height="1" fill="white"/>
      <rect x="7" y="6" width="1" height="1" fill="white"/>
    </svg>
  );
}

// ─── BOTTOM NAV ICONS (80×80, viewBox 16×16) ───────────────────────────────

export function HabilidadesIcon({ size = 80 }: { size?: number }) {
  // Classic 5-pointed star using SVG polygon — mathematically precise geometry.
  // viewBox 0 0 16 16. Center (8, 8.5). Outer R=7, Inner r=2.8.
  // Points alternating outer/inner, starting from top tip, clockwise:
  //   Outer: top(8,1), upper-right(15,6), lower-right(12,14), lower-left(4,14), upper-left(1,6)
  //   Inner: (10,6), (11,9), (8,11), (5,9), (6,6)
  // Godot: TextureRect, texture = habilidades_icon.svg, size = 80×80
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
      {/* Outline pass — stroke gives 2px-equivalent dark gold border */}
      <polygon
        points="8,1 10,6 15,6 11,9 12,14 8,11 4,14 5,9 1,6 6,6"
        fill="#FFD700"
        stroke="#B8860B"
        strokeWidth="0.7"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function ProgresoIcon({ size = 80 }: { size?: number }) {
  // 3 vertical bars: green (tallest), orange (medium), red (shortest) + up arrow
  // Godot: TextureRect, texture = progreso_icon.svg, size = 80×80
  const baseY = 14;
  const bars = [
    { x: 2,  w: 3, h: 12, color: "#4CAF50" }, // Sport — green, tallest
    { x: 7,  w: 3, h: 8,  color: "#FF9800" }, // Academic — orange
    { x: 12, w: 3, h: 5,  color: "#F44336" }, // Crafts — red, shortest
  ];
  return (
    <svg width={size} height={size} viewBox="0 0 17 16" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {bars.map((b, i) => (
        <rect key={i} x={b.x} y={baseY - b.h} width={b.w} height={b.h} fill={b.color}/>
      ))}
      {/* Up arrow above tallest bar (bar 1, centred at x=3) */}
      {/* Arrow tip */}
      <rect x="3"  y="0" width="1" height="1" fill="white"/>
      {/* Arrow body widening */}
      <rect x="2"  y="1" width="3" height="1" fill="white"/>
      <rect x="1"  y="2" width="5" height="1" fill="white"/>
      {/* Arrow shaft */}
      <rect x="3"  y="1" width="1" height="3" fill="white"/>
    </svg>
  );
}

export function ActividadesIcon({ size = 80 }: { size?: number }) {
  // Pixel-art calendar with plus sign — UNCHANGED from v2
  // Godot: TextureRect, texture = actividades_icon.svg, size = 80×80
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {/* Calendar body outline */}
      <rect x="1" y="3" width="11" height="11" fill="none" stroke="white" strokeWidth="1"/>
      {/* Calendar header bar */}
      <rect x="1" y="3" width="11" height="3" fill="white"/>
      {/* Header text dots */}
      <rect x="3" y="4" width="1" height="1" fill="#1565C0"/>
      <rect x="5" y="4" width="1" height="1" fill="#1565C0"/>
      <rect x="7" y="4" width="1" height="1" fill="#1565C0"/>
      {/* Ring hangers */}
      <rect x="4" y="2" width="1" height="2" fill="white"/>
      <rect x="8" y="2" width="1" height="2" fill="white"/>
      {/* Calendar grid — 2×3 day squares */}
      <rect x="2"  y="7"  width="2" height="2" fill="white"/>
      <rect x="5"  y="7"  width="2" height="2" fill="white"/>
      <rect x="8"  y="7"  width="2" height="2" fill="white"/>
      <rect x="2"  y="10" width="2" height="2" fill="white"/>
      <rect x="5"  y="10" width="2" height="2" fill="white"/>
      {/* Plus badge — bottom-right, green */}
      <rect x="12" y="10" width="3" height="1" fill="#4CAF50"/>
      <rect x="13" y="9"  width="1" height="3" fill="#4CAF50"/>
    </svg>
  );
}

export function SaludIcon({ size = 80 }: { size?: number }) {
  // Classic pixel art heart matching the provided reference exactly.
  // viewBox 0 0 17 14 → each unit is a crisp pixel block.
  // Godot: TextureRect, texture = salud_icon.svg, size = 80×80
  const R = "#C21818"; // Deep red from the image
  const W = "white";   // L-shaped highlight (light reflection)

  return (
    <svg width={size} height={size} viewBox="0 0 17 14" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {/* Row 0 — Top bumps */}
      <rect x="3" y="0" width="3" height="1" fill={R}/>
      <rect x="11" y="0" width="3" height="1" fill={R}/>

      {/* Row 1 */}
      <rect x="2" y="1" width="1" height="1" fill={R}/>
      <rect x="3" y="1" width="2" height="1" fill={W}/>
      <rect x="5" y="1" width="2" height="1" fill={R}/>
      <rect x="10" y="1" width="5" height="1" fill={R}/>

      {/* Row 2 */}
      <rect x="1" y="2" width="2" height="1" fill={R}/>
      <rect x="3" y="2" width="1" height="1" fill={W}/>
      <rect x="4" y="2" width="4" height="1" fill={R}/>
      <rect x="9" y="2" width="7" height="1" fill={R}/>

      {/* Rows 3-5 — Straight vertical edges, full width */}
      <rect x="0" y="3" width="17" height="3" fill={R}/>

      {/* Row 6 — Start of bottom taper */}
      <rect x="1" y="6" width="15" height="1" fill={R}/>

      {/* Row 7 */}
      <rect x="2" y="7" width="13" height="1" fill={R}/>

      {/* Row 8 */}
      <rect x="3" y="8" width="11" height="1" fill={R}/>

      {/* Row 9 */}
      <rect x="4" y="9" width="9" height="1" fill={R}/>

      {/* Row 10 */}
      <rect x="5" y="10" width="7" height="1" fill={R}/>

      {/* Row 11 */}
      <rect x="6" y="11" width="5" height="1" fill={R}/>

      {/* Row 12 */}
      <rect x="7" y="12" width="3" height="1" fill={R}/>

      {/* Row 13 — Bottom point */}
      <rect x="8" y="13" width="1" height="1" fill={R}/>
    </svg>
  );
}

export function MonedaIcon({ size = 48 }: { size?: number }) {
  // Pixel-art coin: gold base, darker gold border, € centre, 3 white sparkles
  // Godot: TextureRect, texture = moneda_icon.svg, size = 48×48
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" shapeRendering="crispEdges">
      {/* Coin border (2px darker gold) */}
      <rect x="4"  y="0"  width="8"  height="2"  fill="#F59E00"/>
      <rect x="2"  y="1"  width="12" height="1"  fill="#F59E00"/>
      <rect x="0"  y="4"  width="2"  height="8"  fill="#F59E00"/>
      <rect x="1"  y="2"  width="1"  height="12" fill="#F59E00"/>
      <rect x="14" y="2"  width="1"  height="12" fill="#F59E00"/>
      <rect x="14" y="4"  width="2"  height="8"  fill="#F59E00"/>
      <rect x="2"  y="14" width="12" height="1"  fill="#F59E00"/>
      <rect x="4"  y="14" width="8"  height="2"  fill="#F59E00"/>

      {/* Coin face (gold fill) */}
      <rect x="2"  y="2"  width="12" height="12" fill="#FFD700"/>
      <rect x="1"  y="3"  width="14" height="10" fill="#FFD700"/>
      <rect x="3"  y="1"  width="10" height="14" fill="#FFD700"/>

      {/* € symbol in dark brown */}
      {/* Top curve */}
      <rect x="6"  y="4"  width="5"  height="1"  fill="#7B4F00"/>
      {/* Left stem */}
      <rect x="5"  y="5"  width="1"  height="6"  fill="#7B4F00"/>
      {/* Middle bar 1 */}
      <rect x="5"  y="7"  width="4"  height="1"  fill="#7B4F00"/>
      {/* Middle bar 2 */}
      <rect x="5"  y="9"  width="4"  height="1"  fill="#7B4F00"/>
      {/* Bottom curve */}
      <rect x="6"  y="11" width="5"  height="1"  fill="#7B4F00"/>

      {/* White sparkles (L-shaped, 3px each) — scattered around coin */}
      {/* Sparkle top-right */}
      <rect x="12" y="1"  width="2"  height="1"  fill="white"/>
      <rect x="13" y="1"  width="1"  height="2"  fill="white"/>
      {/* Sparkle bottom-left */}
      <rect x="1"  y="13" width="2"  height="1"  fill="white"/>
      <rect x="1"  y="12" width="1"  height="2"  fill="white"/>
      {/* Sparkle top-left */}
      <rect x="2"  y="2"  width="2"  height="1"  fill="white"/>
      <rect x="2"  y="2"  width="1"  height="2"  fill="white"/>
    </svg>
  );
}
