class_name Objeto_Granja
extends Node2D

# ============================================================================
# Objeto interactivo multi-celda del mundo isométrico 24×24 de «La Granja».
#
# Renderiza la huella real (2×2, 3×3, 4×3, 3×4, 4×4) con base 2.5D, vallas con
# profundidad delante/detrás, sprites mejorados y animaciones dedicadas por
# tipo (aspas giratorias del molino, fuego y humo vivo en panadería, burbujeo y
# vapor en quesería, comportamiento autónomo caminar/picotear/pastar en
# gallina y vaca, y crecimiento en 4 fases + vaivén del viento en cultivos).
# ============================================================================

const FUENTE_BOLD := preload("res://Fuentes/UI/DMSans-700.ttf")
const IconoProducto := preload("res://Scripts/GUI/Granja/Icono_Producto.gd")

const TILE_HW: float = 24.0
const TILE_HH: float = 12.0

const RUTAS_TEX := {
	"molino_torre": "res://Imagenes/Granja/Molino_Torre.png",
	"molino_aspas": "res://Imagenes/Granja/Molino_Aspas.png",
	"panaderia": "res://Imagenes/Granja/Panaderia.png",
	"queseria": "res://Imagenes/Granja/Queseria.png",
	"gallina_idle": "res://Imagenes/Granja/Gallina.png",
	"gallina_peck": "res://Imagenes/Granja/Gallina_Picoteando.png",
	"vaca_idle": "res://Imagenes/Granja/Vaca.png",
	"vaca_eat": "res://Imagenes/Granja/Vaca_Comiendo.png",
	"trigo": "res://Imagenes/Granja/Trigo.png",
	"zanahoria": "res://Imagenes/Granja/Zanahoria.png",
	"maiz": "res://Imagenes/Granja/Maiz.png",
}

static var _cache_tex: Dictionary = {}

var objeto_id: int = -1
var gx: int = 0
var gy: int = 0
var ancho: int = 2
var alto: int = 2
var rotado: bool = false
var volteado: bool = false

var categoria: String = ""
var tipo: String = ""
var cultivo: String = ""
var producto: String = ""
var nombre: String = ""
var listo: bool = false
var trabajando: bool = false
var alimentado: bool = false
var puede_accion: bool = false
var pista_falta: String = ""
var restante: int = 0
var progreso: float = 0.0
var reembolso: int = 0

var modo_vender: bool = false
var modo_mover: bool = false
var oculto_por_mover: bool = false
var seleccionado: bool = false
var hover: bool = false
var resaltar_siembra: bool = false

var _tiempo: float = 0.0
var _fase: float = 0.0
var _angulo_aspas: float = 0.0
var _vel_aspas: float = 0.45

# Estado de animación autónoma para animales (gallina / vaca).
var _anim_pos := Vector2(0.5, 0.5)       # UV dentro de la huella [0.22..0.78]
var _anim_objetivo := Vector2(0.5, 0.5)
var _anim_estado: String = "idle"        # "idle" | "caminar" | "accion"
var _anim_timer: float = 1.4
var _anim_mira_izq: bool = false

# Efectos locales (pulso elástico y partículas de celebración).
var _escala_pulso := Vector2.ONE
var _tween_pulso: Tween
var _chispas_burst: Array[Dictionary] = []


static func _tex(clave: String) -> Texture2D:
	if _cache_tex.has(clave):
		return _cache_tex[clave]
	var ruta: String = str(RUTAS_TEX.get(clave, ""))
	if ruta != "" and ResourceLoader.exists(ruta):
		var res := load(ruta)
		if res is Texture2D:
			_cache_tex[clave] = res
			return res
	_cache_tex[clave] = null
	return null


func _ready() -> void:
	set_process(true)


func configurar_datos(info: Dictionary, p_modo_vender: bool, p_modo_mover: bool,
		p_seleccionado: bool, p_oculto_mover: bool, p_resaltar_siembra: bool) -> void:
	objeto_id = int(info.get("id", -1))
	gx = int(info.get("x", 0))
	gy = int(info.get("y", 0))
	ancho = maxi(1, int(info.get("ancho", 2)))
	alto = maxi(1, int(info.get("alto", 2)))
	rotado = bool(info.get("rotado", false))
	volteado = bool(info.get("volteado", false))
	categoria = str(info.get("categoria", ""))
	tipo = str(info.get("tipo", ""))
	cultivo = str(info.get("cultivo", ""))
	producto = str(info.get("producto", ""))
	nombre = str(info.get("nombre", ""))
	listo = bool(info.get("listo", false))
	trabajando = bool(info.get("trabajando", false))
	alimentado = bool(info.get("alimentado", false))
	puede_accion = bool(info.get("puede_accion", false))
	pista_falta = str(info.get("pista_falta", ""))
	restante = int(info.get("restante", 0))
	progreso = clampf(float(info.get("progreso", 0.0)), 0.0, 1.0)
	reembolso = int(info.get("reembolso", 0))

	modo_vender = p_modo_vender
	modo_mover = p_modo_mover
	seleccionado = p_seleccionado
	oculto_por_mover = p_oculto_mover
	resaltar_siembra = p_resaltar_siembra and categoria == "tierra" and cultivo == ""

	_fase = float(objeto_id) * 1.37
	visible = not oculto_por_mover
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_tiempo += delta

	# Velocidad suave de las aspas del molino.
	if categoria == "maquina" and tipo == "molino":
		var objetivo_vel: float = 2.85 if trabajando else (0.75 if listo else 0.42 + 0.16 * sin(_tiempo * 0.6 + _fase))
		_vel_aspas = lerpf(_vel_aspas, objetivo_vel, minf(1.0, delta * 2.5))
		_angulo_aspas = fmod(_angulo_aspas + _vel_aspas * delta, TAU)

	# Comportamiento vivo de animales dentro de su corral.
	if categoria == "animal":
		_Actualizar_Animal_IA(delta)

	# Partículas de celebración temporales.
	if not _chispas_burst.is_empty():
		for i in range(_chispas_burst.size() - 1, -1, -1):
			var p: Dictionary = _chispas_burst[i]
			p["t"] = float(p["t"]) + delta
			p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
			p["vel"] = (p["vel"] as Vector2) + Vector2(0.0, 95.0) * delta
			if float(p["t"]) >= float(p["vida"]):
				_chispas_burst.remove_at(i)

	queue_redraw()


func _Actualizar_Animal_IA(delta: float) -> void:
	_anim_timer -= delta
	if _anim_estado == "caminar":
		var vel: float = 0.28 if tipo == "gallina" else 0.15
		var diff: Vector2 = _anim_objetivo - _anim_pos
		var dist: float = diff.length()
		if dist <= 0.02 or _anim_timer <= 0.0:
			_anim_pos = _anim_objetivo
			_anim_estado = "accion" if (alimentado or _Rand_Seudo(_tiempo * 3.1 + _fase) < 0.58) else "idle"
			_anim_timer = 1.6 + _Rand_Seudo(_tiempo * 1.7 + _fase) * 2.0
		else:
			var paso: Vector2 = diff.normalized() * minf(dist, vel * delta)
			_anim_pos += paso
			# Dirección visual en pantalla isométrica: dx - dy determina izquierda/derecha.
			var sx: float = paso.x - paso.y
			if absf(sx) > 0.001:
				_anim_mira_izq = sx < 0.0
	elif _anim_timer <= 0.0:
		var r: float = _Rand_Seudo(_tiempo * 2.3 + _fase)
		if r < 0.52:
			_anim_estado = "caminar"
			# Si está alimentado tiende a acercarse al comedero (esquina derecha-frontal).
			if alimentado and _Rand_Seudo(_tiempo * 5.3 + _fase) < 0.65:
				_anim_objetivo = Vector2(
					0.55 + _Rand_Seudo(_tiempo + _fase) * 0.20,
					0.36 + _Rand_Seudo(_tiempo * 1.3 + _fase) * 0.24)
			else:
				_anim_objetivo = Vector2(
					0.28 + _Rand_Seudo(_tiempo * 1.1 + _fase) * 0.44,
					0.28 + _Rand_Seudo(_tiempo * 1.9 + _fase) * 0.44)
			_anim_timer = 2.8
		elif r < 0.84:
			_anim_estado = "accion"
			_anim_timer = 1.8 + _Rand_Seudo(_tiempo * 0.9 + _fase) * 1.6
		else:
			_anim_estado = "idle"
			_anim_timer = 1.4 + _Rand_Seudo(_tiempo * 1.4 + _fase) * 1.4


func _Rand_Seudo(semilla: float) -> float:
	return fposmod(sin(semilla * 12.9898 + 78.233) * 43758.5453, 1.0)


func pulso_accion(color_burst: Color = Color("#fbbf24")) -> void:
	if _tween_pulso != null and _tween_pulso.is_valid():
		_tween_pulso.kill()
	_tween_pulso = create_tween()
	_tween_pulso.tween_property(self, "_escala_pulso", Vector2(1.09, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_pulso.tween_property(self, "_escala_pulso", Vector2(0.96, 1.06), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_pulso.tween_property(self, "_escala_pulso", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var origen := centro_local() + Vector2(0.0, -24.0)
	for i in range(10):
		var ang: float = TAU * float(i) / 10.0 + _Rand_Seudo(float(i) + _tiempo) * 0.35
		var spd: float = 42.0 + _Rand_Seudo(float(i) * 2.1 + _tiempo) * 45.0
		_chispas_burst.append({
			"pos": origen,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd * 0.65 - 48.0),
			"t": 0.0,
			"vida": 0.52 + _Rand_Seudo(float(i) * 3.7) * 0.25,
			"radio": 3.0 + float(i % 3) * 1.1,
			"color": color_burst if i % 2 == 0 else Color("#fef08a"),
		})


# ------------------------------------------------------------------
# Geometría isométrica local (anclada en la esquina superior (gx, gy))
# ------------------------------------------------------------------

func iso_local(u: float, v: float) -> Vector2:
	return Vector2((u - v) * TILE_HW, (u + v) * TILE_HH)


func centro_local() -> Vector2:
	return iso_local(float(ancho) * 0.5, float(alto) * 0.5)


func centro_mundo() -> Vector2:
	return position + centro_local()


func altura_visual() -> float:
	if categoria == "maquina":
		if tipo == "molino":
			return 175.0
		if tipo == "panaderia":
			return 132.0
		return 112.0
	if categoria == "animal":
		return 82.0 if tipo == "vaca" else 64.0
	return 52.0 if cultivo != "" else 24.0


func contiene_punto_mundo(pos_mundo: Vector2) -> bool:
	if not visible:
		return false
	var local: Vector2 = pos_mundo - position
	# 1. Comprobación exacta dentro del rombo/paralelogramo isométrico de la huella.
	var u: float = (local.x / TILE_HW + local.y / TILE_HH) * 0.5
	var v: float = (local.y / TILE_HH - local.x / TILE_HW) * 0.5
	if u >= -0.08 and u <= float(ancho) + 0.08 and v >= -0.08 and v <= float(alto) + 0.08:
		return true
	# 2. Comprobación en la silueta superior del edificio / animal / cultivo.
	var c := centro_local()
	var radio_x: float = float(ancho + alto) * TILE_HW * 0.34
	var h_vis: float = altura_visual()
	var rect_copa := Rect2(c.x - radio_x, c.y - h_vis, radio_x * 2.0, h_vis + 8.0)
	return rect_copa.has_point(local)


# ------------------------------------------------------------------
# Dibujado completo
# ------------------------------------------------------------------

func _draw() -> void:
	var c := centro_local()

	# Aplicar pulso elástico alrededor del centro del suelo.
	if _escala_pulso != Vector2.ONE:
		draw_set_transform(c - c * _escala_pulso, 0.0, _escala_pulso)

	match categoria:
		"tierra":
			_Dibujar_Parcela(c)
		"animal":
			_Dibujar_Animal(c)
		"maquina":
			_Dibujar_Maquina(c)

	# Partículas de celebración.
	for p in _chispas_burst:
		var frac: float = clampf(float(p["t"]) / maxf(0.01, float(p["vida"])), 0.0, 1.0)
		var col: Color = p["color"]
		col.a = (1.0 - frac) * 0.95
		draw_circle(p["pos"], float(p["radio"]) * (1.0 - frac * 0.45), col)

	if _escala_pulso != Vector2.ONE:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func dibujar_overlay_en(canvas: CanvasItem) -> void:
	if not visible:
		return
	var c := position + centro_local()
	_Dibujar_Overlays_En(canvas, c)


func _Poligono_Huella(margen: float = 0.0, offset_y: float = 0.0) -> PackedVector2Array:
	var m: float = margen
	var w: float = float(ancho)
	var h: float = float(alto)
	var off := Vector2(0.0, offset_y)
	return PackedVector2Array([
		iso_local(m, m) + off,
		iso_local(w - m, m) + off,
		iso_local(w - m, h - m) + off,
		iso_local(m, h - m) + off,
	])


func _Contorno_Huella(color: Color, grosor: float = 2.4, margen: float = 0.0, offset_y: float = 0.0) -> void:
	var pts := _Poligono_Huella(margen, offset_y)
	pts.append(pts[0])
	draw_polyline(pts, color, grosor, true)


# ------------------------------------------------------------------
# 1. Parcela de cultivo (2×2) + 4 fases de crecimiento + vaivén viento
# ------------------------------------------------------------------

func _Dibujar_Parcela(c: Vector2) -> void:
	var w: float = float(ancho)
	var h: float = float(alto)
	var p_top := iso_local(0.06, 0.06)
	var p_der := iso_local(w - 0.06, 0.06)
	var p_inf := iso_local(w - 0.06, h - 0.06)
	var p_izq := iso_local(0.06, h - 0.06)
	var canto: float = 5.5

	# Sombra suave en el césped.
	draw_colored_polygon(_Poligono_Huella(0.02, 5.5), Color(0.10, 0.25, 0.03, 0.26))

	# Cantos 3D de la parcela labrada.
	draw_colored_polygon(PackedVector2Array([
		p_izq, p_inf, p_inf + Vector2(0, canto), p_izq + Vector2(0, canto),
	]), Color("#47240e"))
	draw_colored_polygon(PackedVector2Array([
		p_inf, p_der, p_der + Vector2(0, canto), p_inf + Vector2(0, canto),
	]), Color("#5f3215"))

	# Tierra superior (más oscura y húmeda cuando tiene cultivo sembrado).
	var col_borde_t := Color("#532c13")
	var col_tierra := Color("#6d3e1e") if cultivo != "" else Color("#875129")
	draw_colored_polygon(PackedVector2Array([p_top, p_der, p_inf, p_izq]), col_borde_t)
	draw_colored_polygon(_Poligono_Huella(0.14, 0.0), col_tierra)

	# 5 surcos esculpidos en perspectiva isométrica.
	var col_surco_osc := Color("#3d1f0b") if cultivo != "" else Color("#4a2610")
	var col_surco_luz := Color("#8b532b") if cultivo != "" else Color("#a6683a")
	for i in range(5):
		var tv: float = 0.16 + (float(i) / 4.0) * 0.68
		var a := iso_local(0.18, tv * h)
		var b := iso_local(w - 0.18, tv * h)
		draw_line(a + Vector2(0, 1.6), b + Vector2(0, 1.6), col_surco_osc, 3.6, true)
		draw_line(a - Vector2(0, 0.9), b - Vector2(0, 0.9), col_surco_luz, 1.7, true)

	# Pequeñas estacas de madera en las 4 esquinas.
	for esquina in [p_top + Vector2(0, 2), p_der + Vector2(-2, 0), p_izq + Vector2(2, 0), p_inf + Vector2(0, -1)]:
		draw_line(esquina, esquina - Vector2(0, 5.5), Color("#6e3f1c"), 2.4, true)
		draw_circle(esquina - Vector2(0, 5.5), 1.5, Color("#b5763c"))

	# Contorno interactivo en el suelo (debajo del cultivo para que no tape la planta).
	_Dibujar_Contornos_Estado()

	# Contenido del cultivo según fase de crecimiento.
	if cultivo == "":
		# Brote sutil invitando a sembrar (pulsa más si está activo el modo siembra rápida).
		var bob: float = sin(_tiempo * 3.0 + _fase) * (2.2 if resaltar_siembra else 1.1)
		var bpos := c + Vector2(0, -3.0 + bob)
		_Elipse(c + Vector2(0, 1.5), 9.0, 4.2, Color(0.15, 0.08, 0.03, 0.24))
		var alpha_b: float = 0.98 if (hover or resaltar_siembra) else 0.72
		draw_line(bpos + Vector2(0, 4), bpos + Vector2(0, -6), Color(0.08, 0.50, 0.24, alpha_b), 2.1, true)
		_Elipse(bpos + Vector2(-4.5, -4), 4.5, 2.5, Color(0.29, 0.87, 0.50, alpha_b))
		_Elipse(bpos + Vector2(4.5, -6), 4.5, 2.5, Color(0.13, 0.77, 0.37, alpha_b))
		return

	if listo:
		_Dibujar_Cultivo_Sprite(c, 1.0, true)
		_Dibujar_Chispas(c + Vector2(0, -30.0), 28.0)
	elif progreso < 0.33:
		_Dibujar_Brotes_Fase1()
	elif progreso < 0.66:
		_Dibujar_Crecimiento_Fase2()
	else:
		var esc: float = lerpf(0.74, 0.94, (progreso - 0.66) / 0.34)
		_Dibujar_Cultivo_Sprite(c, esc, false)


func _Dibujar_Brotes_Fase1() -> void:
	var w: float = float(ancho)
	var h: float = float(alto)
	var crec: float = clampf(progreso / 0.33, 0.25, 1.0)
	for iv in range(3):
		for iu in range(3):
			var u: float = (0.24 + float(iu) * 0.26) * w
			var v: float = (0.24 + float(iv) * 0.26) * h
			var p := iso_local(u, v)
			var vaiven: float = sin(_tiempo * 2.7 + _fase + float(iu + iv) * 0.7) * 1.4
			var h_tallo: float = (5.0 + 4.5 * crec)
			draw_line(p, p + Vector2(vaiven, -h_tallo), Color("#166534"), 1.9, true)
			_Elipse(p + Vector2(vaiven - 3.6, -h_tallo + 1.0), 3.6 * crec + 1.2, 2.0, Color("#4ade80"))
			_Elipse(p + Vector2(vaiven + 3.6, -h_tallo - 0.6), 3.6 * crec + 1.2, 2.0, Color("#22c55e"))


func _Dibujar_Crecimiento_Fase2() -> void:
	var w: float = float(ancho)
	var h: float = float(alto)
	var f: float = clampf((progreso - 0.33) / 0.33, 0.0, 1.0)
	for iv in range(3):
		for iu in range(3):
			var u: float = (0.22 + float(iu) * 0.28) * w
			var v: float = (0.22 + float(iv) * 0.28) * h
			var p := iso_local(u, v)
			var vaiven: float = sin(_tiempo * 2.5 + _fase + float(iu) * 0.6 + float(iv) * 0.4) * 2.2
			if cultivo == "trigo":
				var alto_t: float = lerpf(11.0, 18.0, f)
				for dx in [-2.8, 0.0, 2.8]:
					draw_line(p + Vector2(dx, 0), p + Vector2(dx + vaiven, -alto_t), Color("#65a30d"), 2.0, true)
					draw_circle(p + Vector2(dx + vaiven, -alto_t), 2.1, Color("#ca8a04") if f > 0.5 else Color("#84cc16"))
			elif cultivo == "zanahoria":
				var rad: float = lerpf(4.2, 6.2, f)
				_Elipse(p + Vector2(0, 0.5), 3.6, 2.4, Color("#f97316") if f > 0.4 else Color("#ea580c"))
				draw_line(p, p + Vector2(vaiven - 4.0, -9.0 - 4.0 * f), Color("#15803d"), 2.0, true)
				draw_line(p, p + Vector2(vaiven, -11.0 - 5.0 * f), Color("#22c55e"), 2.2, true)
				draw_line(p, p + Vector2(vaiven + 4.0, -9.0 - 4.0 * f), Color("#16a34a"), 2.0, true)
				draw_circle(p + Vector2(vaiven, -11.0 - 4.5 * f), rad * 0.55, Color("#4ade80"))
			else:
				var alto_m: float = lerpf(13.0, 22.0, f)
				draw_line(p, p + Vector2(vaiven, -alto_m), Color("#15803d"), 2.6, true)
				draw_line(p + Vector2(0, -alto_m * 0.45), p + Vector2(vaiven - 6.5, -alto_m * 0.65), Color("#4ade80"), 2.2, true)
				draw_line(p + Vector2(0, -alto_m * 0.6), p + Vector2(vaiven + 6.5, -alto_m * 0.8), Color("#22c55e"), 2.2, true)
				if f > 0.5:
					_Elipse(p + Vector2(vaiven + 2.5, -alto_m * 0.55), 2.3, 4.0, Color("#facc15"))


func _Dibujar_Cultivo_Sprite(c: Vector2, escala: float, maduro: bool) -> void:
	var t := _tex(cultivo)
	if t == null:
		return
	var tam_base: float = 88.0 if cultivo == "maiz" else (82.0 if cultivo == "trigo" else 76.0)
	var lado: float = tam_base * escala
	var vaiven_ang: float = sin(_tiempo * 2.1 + _fase) * (0.040 if maduro else 0.028)
	var pivote := c + Vector2(0.0, 14.0)
	# Sombra de contacto bajo la mata.
	_Elipse(c + Vector2(0.0, 6.0), 28.0 * escala, 12.0 * escala, Color(0.18, 0.09, 0.03, 0.26))
	draw_set_transform(pivote, vaiven_ang, Vector2.ONE)
	var rect := Rect2(-lado * 0.5, -lado + 6.0, lado, lado)
	var tinte := Color.WHITE if maduro else Color(0.95, 1.0, 0.92, 0.96)
	draw_texture_rect(t, rect, false, tinte)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------
# 2. Corrales de animales (Gallina 2×2 · Vaca 3×3) con IA viva 2.5D
# ------------------------------------------------------------------

func _Dibujar_Animal(c: Vector2) -> void:
	var w: float = float(ancho)
	var h: float = float(alto)

	# Suelo de corral / prado cercado.
	var col_suelo := Color(0.56, 0.78, 0.22, 0.42) if tipo == "vaca" else Color(0.76, 0.67, 0.34, 0.36)
	draw_colored_polygon(_Poligono_Huella(0.08, 0.0), col_suelo)
	_Dibujar_Contornos_Estado()

	if tipo == "gallina":
		_Dibujar_Paja_Corral(c, 22.0)
	else:
		_Dibujar_Hierba_Prado(c)

	# Valla TRASERA (bordes superior-izquierdo y superior-derecho — detrás del animal).
	_Dibujar_Valla_Tramo(iso_local(0.08, 0.08), iso_local(w - 0.08, 0.08), 11.0 if tipo == "vaca" else 8.5, 4 if tipo == "vaca" else 3)
	_Dibujar_Valla_Tramo(iso_local(0.08, 0.08), iso_local(0.08, h - 0.08), 11.0 if tipo == "vaca" else 8.5, 4 if tipo == "vaca" else 3)

	# Comedero / pesebre interior.
	var pos_com := iso_local(w * 0.74, h * 0.30)
	_Dibujar_Comedero(pos_com, alimentado or listo, tipo == "vaca")

	# Si es gallina y está lista, nido con huevos relucientes en la esquina izquierda.
	if tipo == "gallina" and listo:
		var pos_nido := iso_local(w * 0.26, h * 0.70)
		_Dibujar_Nido_Huevos(pos_nido)

	# Dibujar el animal vivo con animación autónoma de caminar / picotear / pastar.
	var pos_animal := iso_local(_anim_pos.x * w, _anim_pos.y * h)
	var clave_tex := ""
	if tipo == "gallina":
		clave_tex = "gallina_peck" if _anim_estado == "accion" else "gallina_idle"
	else:
		clave_tex = "vaca_eat" if _anim_estado == "accion" else "vaca_idle"

	var t_anim := _tex(clave_tex)
	if t_anim != null:
		var tam_a: float = 98.0 if tipo == "vaca" else 64.0
		var salto_y: float = 0.0
		var sx: float = 1.0
		var sy: float = 1.0
		if _anim_estado == "caminar":
			var ciclo_paso: float = absf(sin(_tiempo * (9.5 if tipo == "gallina" else 5.2) + _fase))
			salto_y = -ciclo_paso * (5.0 if tipo == "gallina" else 2.8)
			sy = 1.0 + ciclo_paso * 0.04
			sx = 1.0 - ciclo_paso * 0.03
		elif _anim_estado == "accion":
			var pico: float = sin(_tiempo * (8.0 if tipo == "gallina" else 4.2) + _fase)
			sy = 1.0 - maxf(0.0, pico) * 0.055
			sx = 1.0 + maxf(0.0, pico) * 0.04
			salto_y = maxf(0.0, pico) * 2.2
		else:
			var resp: float = sin(_tiempo * 2.4 + _fase) * 0.024
			sy = 1.0 + resp
			sx = 1.0 - resp * 0.6

		if hover:
			salto_y -= 2.5

		# Sombra elíptica debajo de las patas.
		var rad_s: float = 28.0 if tipo == "vaca" else 16.0
		_Elipse(pos_animal + Vector2(0.0, 2.0), rad_s, rad_s * 0.44, Color(0.10, 0.22, 0.03, 0.32))

		var flip_final: bool = _anim_mira_izq != volteado
		var dir_x: float = -1.0 if flip_final else 1.0
		draw_set_transform(pos_animal + Vector2(0.0, salto_y), 0.0, Vector2(dir_x * sx, sy))
		var rect_a := Rect2(-tam_a * 0.5, -tam_a + 10.0, tam_a, tam_a)
		draw_texture_rect(t_anim, rect_a, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Partículas de comida / corazones felices cuando está produciendo.
		if alimentado and not listo:
			_Dibujar_Particulas_Animal(pos_animal + Vector2(0, -tam_a * 0.58))

	# Valla DELANTERA (bordes inferior-izquierdo e inferior-derecho — delante del animal para 2.5D real!).
	_Dibujar_Valla_Tramo(iso_local(0.08, h - 0.08), iso_local(w - 0.08, h - 0.08), 11.0 if tipo == "vaca" else 8.5, 4 if tipo == "vaca" else 3)
	_Dibujar_Valla_Tramo(iso_local(w - 0.08, 0.08), iso_local(w - 0.08, h - 0.08), 11.0 if tipo == "vaca" else 8.5, 4 if tipo == "vaca" else 3)

	# Si es vaca y está lista, lecheras brillantes junto a la puerta del corral.
	if tipo == "vaca" and listo:
		_Dibujar_Lecheras(iso_local(w - 0.35, h - 0.25))

	if listo and not modo_vender:
		_Dibujar_Chispas(c + Vector2(0, -44.0), 34.0)


func _Dibujar_Valla_Tramo(a: Vector2, b: Vector2, altura: float, postes: int) -> void:
	# Sombra
	draw_line(a + Vector2(0, 2.0), b + Vector2(0, 2.0), Color(0.10, 0.24, 0.03, 0.22), 3.0, true)
	# Travesaños
	draw_line(a - Vector2(0, altura * 0.72), b - Vector2(0, altura * 0.72), Color("#7a461e"), 2.8, true)
	draw_line(a - Vector2(0, altura * 0.78), b - Vector2(0, altura * 0.78), Color("#c08245"), 1.2, true)
	draw_line(a - Vector2(0, altura * 0.34), b - Vector2(0, altura * 0.34), Color("#7a461e"), 2.6, true)
	draw_line(a - Vector2(0, altura * 0.40), b - Vector2(0, altura * 0.40), Color("#b5763c"), 1.1, true)
	# Postes
	for i in range(postes):
		var t: float = float(i) / float(maxi(1, postes - 1))
		var p := a.lerp(b, t)
		draw_rect(Rect2(p.x - 2.2, p.y - altura - 1.5, 4.4, altura + 2.0), Color("#6b3c18"))
		draw_rect(Rect2(p.x - 1.5, p.y - altura - 1.5, 2.0, altura + 1.0), Color("#ba7c40"))
		draw_rect(Rect2(p.x - 2.6, p.y - altura - 2.6, 5.2, 2.2), Color("#d49654"))


func _Dibujar_Paja_Corral(c: Vector2, r: float) -> void:
	for b in [Vector2(-16, 4), Vector2(-6, 9), Vector2(8, 7), Vector2(14, 1), Vector2(-3, -5), Vector2(4, -2)]:
		var p: Vector2 = c + b * (r / 22.0)
		draw_line(p - Vector2(4.5, 1), p + Vector2(4.5, 1.5), Color("#eab308", 0.58), 1.6, true)
		draw_line(p - Vector2(2.5, -1.5), p + Vector2(3.5, -0.5), Color("#fde047", 0.46), 1.2, true)


func _Dibujar_Hierba_Prado(c: Vector2) -> void:
	for b in [Vector2(-24, 2), Vector2(-8, 12), Vector2(14, 8), Vector2(22, -4), Vector2(-12, -10), Vector2(6, -12)]:
		var p: Vector2 = c + b
		var v: float = sin(_tiempo * 2.2 + p.x * 0.1) * 1.2
		draw_line(p, p + Vector2(-2.0 + v, -4.5), Color("#4d7c0f", 0.65), 1.4, true)
		draw_line(p, p + Vector2(1.5 + v, -5.5), Color("#65a30d", 0.65), 1.4, true)


func _Dibujar_Comedero(pos: Vector2, lleno: bool, grande: bool) -> void:
	var rx: float = 15.0 if grande else 11.0
	var ry: float = 7.0 if grande else 5.2
	var h: float = 8.0 if grande else 6.0
	_Diamante(pos + Vector2(0, 2.8), rx + 1.5, ry + 0.8, Color(0.10, 0.24, 0.03, 0.25))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-rx, -h), pos + Vector2(0, ry - h),
		pos + Vector2(0, ry), pos + Vector2(-rx, 0),
	]), Color("#784118"))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, ry - h), pos + Vector2(rx, -h),
		pos + Vector2(rx, 0), pos + Vector2(0, ry),
	]), Color("#9b5825"))
	_Diamante(pos + Vector2(0, -h), rx, ry, Color("#b87336"))
	_Diamante(pos + Vector2(0, -h), rx - 2.6, ry - 1.5, Color("#facc15") if lleno else Color("#532e12"))
	if lleno:
		_Elipse(pos + Vector2(-1.5, -h - 1.0), rx * 0.45, ry * 0.42, Color("#fde047"))


func _Dibujar_Nido_Huevos(pos: Vector2) -> void:
	_Elipse(pos + Vector2(0, 2.0), 11.5, 5.5, Color(0.10, 0.22, 0.03, 0.28))
	_Elipse(pos, 10.5, 5.2, Color("#b45309"))
	_Elipse(pos + Vector2(0, -1.0), 9.0, 4.2, Color("#f59e0b"))
	for off in [Vector2(-3.2, -2.5), Vector2(3.0, -2.2), Vector2(0.0, -4.4)]:
		_Elipse(pos + off, 2.8, 3.6, Color("#fffbeb"))
		draw_circle(pos + off + Vector2(-0.8, -1.0), 0.9, Color.WHITE)


func _Dibujar_Lecheras(pos: Vector2) -> void:
	for dx in [-6.0, 4.0]:
		var p := pos + Vector2(dx, 0.0)
		_Elipse(p + Vector2(0, 2.0), 5.5, 2.6, Color(0.10, 0.22, 0.03, 0.30))
		draw_rect(Rect2(p.x - 4.0, p.y - 10.5, 8.0, 10.5), Color("#cbd5e1"))
		draw_rect(Rect2(p.x - 3.0, p.y - 13.5, 6.0, 3.5), Color("#e2e8f0"))
		draw_rect(Rect2(p.x - 2.2, p.y - 10.0, 2.0, 9.0), Color("#f8fafc"))
		draw_line(p + Vector2(-4.2, -10.5), p + Vector2(4.2, -10.5), Color("#64748b"), 1.3, true)


func _Dibujar_Particulas_Animal(base: Vector2) -> void:
	for i in range(2):
		var ciclo: float = fmod(_tiempo * 0.55 + float(i) * 0.5 + _fase, 1.0)
		var pos := base + Vector2(sin(ciclo * 5.0 + float(i) * 2.0) * 8.0, -ciclo * 22.0)
		var alpha: float = sin(ciclo * PI) * 0.85
		var r: float = 2.6 + (1.0 - ciclo) * 1.4
		draw_circle(pos + Vector2(-r * 0.55, 0), r * 0.65, Color(1.0, 0.45, 0.55, alpha))
		draw_circle(pos + Vector2(r * 0.55, 0), r * 0.65, Color(1.0, 0.45, 0.55, alpha))
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-r * 1.15, 0.3), pos + Vector2(r * 1.15, 0.3), pos + Vector2(0, r * 1.45),
		]), Color(1.0, 0.45, 0.55, alpha))


# ------------------------------------------------------------------
# 3. Máquinas (Molino 4×4 · Panadería 4×3 · Quesería 3×3) + Animaciones
# ------------------------------------------------------------------

func _Dibujar_Maquina(c: Vector2) -> void:
	# Plataforma empedrada con borde 3D adaptada a la huella real (4×4, 4×3, 3×3).
	var w: float = float(ancho)
	var h: float = float(alto)
	var canto: float = 5.5
	var p_izq := iso_local(0.10, h - 0.10)
	var p_inf := iso_local(w - 0.10, h - 0.10)
	var p_der := iso_local(w - 0.10, 0.10)

	draw_colored_polygon(_Poligono_Huella(0.04, 5.5), Color(0.10, 0.24, 0.03, 0.30))
	draw_colored_polygon(PackedVector2Array([
		p_izq, p_inf, p_inf + Vector2(0, canto), p_izq + Vector2(0, canto),
	]), Color("#7d6b52"))
	draw_colored_polygon(PackedVector2Array([
		p_inf, p_der, p_der + Vector2(0, canto), p_inf + Vector2(0, canto),
	]), Color("#9a8668"))
	draw_colored_polygon(_Poligono_Huella(0.10, 0.0), Color("#c9bc9f"))
	draw_colored_polygon(_Poligono_Huella(0.24, 0.0), Color("#dfd4bc"))

	# Detalles de losas sobre la plataforma.
	for i in range(1, ancho):
		draw_line(iso_local(float(i), 0.25), iso_local(float(i), h - 0.25), Color("#bfb294", 0.55), 1.1, true)
	for j in range(1, alto):
		draw_line(iso_local(0.25, float(j)), iso_local(w - 0.25, float(j)), Color("#bfb294", 0.55), 1.1, true)

	# Contorno interactivo abrazando la base empedrada (debajo de la torre/edificio!).
	_Dibujar_Contornos_Estado()

	if tipo == "molino":
		_Dibujar_Molino_Animado(c)
	elif tipo == "panaderia":
		_Dibujar_Panaderia_Animada(c)
	else:
		_Dibujar_Queseria_Animada(c)

	if listo and not modo_vender:
		_Dibujar_Chispas(c + Vector2(0, -altura_visual() * 0.55), 48.0)


func _Dibujar_Molino_Animado(c: Vector2) -> void:
	var tex_torre := _tex("molino_torre")
	var tex_aspas := _tex("molino_aspas")
	if tex_torre == null:
		return

	var tam: float = 178.0
	var vibr: Vector2 = Vector2.ZERO
	if trabajando:
		vibr = Vector2(sin(_tiempo * 28.0 + _fase) * 0.7, cos(_tiempo * 34.0 + _fase) * 0.5)
	var lift: float = -2.5 if hover else 0.0
	var base := c + Vector2(0.0, 22.0 + lift) + vibr

	# Sombra de la torre sobre la plataforma.
	_Elipse(c + Vector2(2.0, 8.0), 58.0, 26.0, Color(0.18, 0.16, 0.10, 0.30))

	var flip_x: float = -1.0 if volteado else 1.0
	var rect_t := Rect2(-tam * 0.5, -tam, tam, tam)

	draw_set_transform(base, 0.0, Vector2(flip_x, 1.0))
	draw_texture_rect(tex_torre, rect_t, false)

	# Ventana iluminada cálidamente cuando muele.
	if trabajando or listo:
		var win_pos := rect_t.position + Vector2(tam * 0.655, tam * 0.52)
		var pulso_l: float = 0.42 + 0.18 * sin(_tiempo * 5.5 + _fase)
		draw_circle(win_pos, 15.0, Color(1.0, 0.82, 0.25, pulso_l * 0.45))
		draw_circle(win_pos, 7.5, Color(1.0, 0.92, 0.45, pulso_l))

	# Polvo de harina saliendo junto al saco cuando trabaja.
	if trabajando:
		var saco_pos := rect_t.position + Vector2(tam * 0.45, tam * 0.85)
		for i in range(4):
			var ciclo: float = fmod(_tiempo * 0.95 + float(i) * 0.25 + _fase, 1.0)
			var p_polvo := saco_pos + Vector2(-ciclo * 14.0 + sin(ciclo * 6.0) * 3.0, -ciclo * 22.0)
			var alpha: float = sin(ciclo * PI) * 0.52
			draw_circle(p_polvo, 3.0 + ciclo * 4.5, Color(1.0, 0.98, 0.90, alpha))

	# Aspas giratorias ancladas exactamente en el buje UV (0.65, 0.265)!
	if tex_aspas != null:
		var hub := base + Vector2(flip_x * (tam * (0.65 - 0.5)), -tam * (1.0 - 0.265))
		var tam_aspas: float = 154.0
		# Sombra sutil de las aspas sobre la torre.
		draw_set_transform(hub + Vector2(-4.0 * flip_x, 6.0), _angulo_aspas * flip_x, Vector2(0.95, 0.95))
		draw_texture_rect(tex_aspas, Rect2(-tam_aspas * 0.5, -tam_aspas * 0.5, tam_aspas, tam_aspas), false, Color(0.18, 0.12, 0.06, 0.22))
		# Aspas reales rotando suavemente.
		draw_set_transform(hub, _angulo_aspas * flip_x, Vector2.ONE)
		draw_texture_rect(tex_aspas, Rect2(-tam_aspas * 0.5, -tam_aspas * 0.5, tam_aspas, tam_aspas), false)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _Dibujar_Panaderia_Animada(c: Vector2) -> void:
	var tex := _tex("panaderia")
	if tex == null:
		return

	var tam: float = 158.0
	var pulso_horno: float = (1.0 + sin(_tiempo * 6.0 + _fase) * 0.014) if trabajando else 1.0
	var lift: float = -2.5 if hover else 0.0
	var base := c + Vector2(0.0, 24.0 + lift)
	var flip_x: float = -1.0 if (volteado != rotado) else 1.0

	_Elipse(c + Vector2(0.0, 7.0), 62.0, 28.0, Color(0.18, 0.14, 0.08, 0.30))

	var rect_p := Rect2(-tam * 0.5, -tam, tam, tam)
	draw_set_transform(base, 0.0, Vector2(flip_x * (2.0 - pulso_horno), pulso_horno))
	draw_texture_rect(tex, rect_p, false)

	# Farolillo cálido balanceando suavemente su brillo.
	var farol := rect_p.position + Vector2(tam * 0.635, tam * 0.74)
	var brillo_f: float = 0.28 + 0.14 * sin(_tiempo * 3.8 + _fase)
	draw_circle(farol, 11.0, Color(1.0, 0.82, 0.25, brillo_f))

	# Fuego vivo + brasas + ventana cálida cuando hornea.
	if trabajando:
		var horno := rect_p.position + Vector2(tam * 0.83, tam * 0.74)
		var flama: float = 0.72 + 0.28 * sin(_tiempo * 14.0 + _fase)
		var flama2: float = 0.65 + 0.35 * cos(_tiempo * 19.0 + _fase)
		draw_circle(horno, 16.0 * flama, Color(1.0, 0.42, 0.05, 0.36))
		_Elipse(horno + Vector2(0, 1.5), 7.5 * flama, 6.0 * flama2, Color("#f97316", 0.92))
		_Elipse(horno + Vector2(0, 2.5), 4.5 * flama2, 4.2 * flama, Color("#fde047", 0.95))

		# Ventana superior iluminada.
		var vent := rect_p.position + Vector2(tam * 0.33, tam * 0.40)
		draw_circle(vent, 10.0, Color(1.0, 0.86, 0.35, 0.32 + 0.10 * sin(_tiempo * 5.0)))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Humo animado saliendo de las chimeneas en coordenadas sin volteo vertical.
	if trabajando:
		var chim_principal := base + Vector2(flip_x * tam * (0.755 - 0.5), -tam * (1.0 - 0.165))
		var chim_horno := base + Vector2(flip_x * tam * (0.76 - 0.5), -tam * (1.0 - 0.60))
		_Dibujar_Humo_Chimenea(chim_principal, 5, 42.0, 1.0)
		_Dibujar_Humo_Chimenea(chim_horno, 3, 24.0, 0.7)
	elif listo:
		# Aroma dorado suave sobre los panes recién hechos.
		var panes := base + Vector2(flip_x * tam * (0.24 - 0.5), -tam * (1.0 - 0.68))
		for i in range(3):
			var ciclo: float = fmod(_tiempo * 0.7 + float(i) * 0.33 + _fase, 1.0)
			var pos_a := panes + Vector2(sin(ciclo * 6.0 + float(i)) * 5.0, -ciclo * 24.0)
			var alpha: float = sin(ciclo * PI) * 0.45
			draw_circle(pos_a, 3.0 + ciclo * 3.0, Color(1.0, 0.92, 0.65, alpha))


func _Dibujar_Humo_Chimenea(origen: Vector2, cantidad: int, altura_max: float, escala: float) -> void:
	for i in range(cantidad):
		var ciclo: float = fmod(_tiempo * 0.62 + float(i) / float(cantidad) + _fase * 0.4, 1.0)
		var deriva_x: float = ciclo * 14.0 + sin(ciclo * 5.2 + float(i)) * 4.5
		var pos := origen + Vector2(deriva_x, -ciclo * altura_max)
		var alpha: float = sin(ciclo * PI) * 0.58
		var radio: float = (4.2 + ciclo * 8.5) * escala
		draw_circle(pos + Vector2(1.0, 1.5), radio, Color(0.82, 0.78, 0.72, alpha * 0.55))
		draw_circle(pos, radio * 0.88, Color(1.0, 0.99, 0.96, alpha))


func _Dibujar_Queseria_Animada(c: Vector2) -> void:
	var tex := _tex("queseria")
	if tex == null:
		return

	var tam: float = 132.0
	var pulso: float = (1.0 + sin(_tiempo * 7.2 + _fase) * 0.022) if trabajando else 1.0
	var lift: float = -2.5 if hover else 0.0
	var base := c + Vector2(0.0, 20.0 + lift)
	var flip_x: float = -1.0 if volteado else 1.0

	_Elipse(c + Vector2(0.0, 6.0), 50.0, 22.0, Color(0.18, 0.14, 0.08, 0.28))

	var rect_q := Rect2(-tam * 0.5, -tam, tam, tam)
	draw_set_transform(base, 0.0, Vector2(flip_x * (2.0 - pulso), pulso))
	draw_texture_rect(tex, rect_q, false)

	# Burbujeo de leche cremosa dentro de la cuba de cobre UV (0.43, 0.36).
	if trabajando:
		var cuba := rect_q.position + Vector2(tam * 0.43, tam * 0.36)
		for i in range(5):
			var ciclo: float = fmod(_tiempo * 1.35 + float(i) * 0.21 + _fase, 1.0)
			var ang: float = float(i) * 1.45 + _fase
			var bx: float = cos(ang) * tam * 0.10
			var by: float = sin(ang) * tam * 0.036 - ciclo * 3.0
			var r: float = sin(ciclo * PI) * 3.4
			if r > 0.4:
				draw_circle(cuba + Vector2(bx, by), r, Color(1.0, 0.98, 0.82, 0.85))
				draw_arc(cuba + Vector2(bx, by), r, 0, TAU, 10, Color("#f59e0b", 0.55), 1.0, true)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Vapor cálido saliendo de la cuba de cobre.
	if trabajando:
		var cuba_m := base + Vector2(flip_x * tam * (0.43 - 0.5), -tam * (1.0 - 0.33))
		_Dibujar_Humo_Chimenea(cuba_m, 4, 28.0, 0.65)


# ------------------------------------------------------------------
# Contornos de estado y overlays (burbuja de listo + pastilla progreso)
# ------------------------------------------------------------------

func _Dibujar_Contornos_Estado() -> void:
	if modo_vender:
		var pv: float = 0.65 + 0.30 * sin(_tiempo * 5.2 + _fase)
		_Contorno_Huella(Color(0.92, 0.16, 0.16, pv), 2.8, 0.02)
		return
	if modo_mover:
		var pm: float = 0.65 + 0.30 * sin(_tiempo * 4.5 + _fase)
		_Contorno_Huella(Color(0.06, 0.65, 0.96, pm), 2.8, 0.02)
		return
	if seleccionado:
		_Contorno_Huella(Color(1.0, 0.96, 0.55, 0.95), 2.8, 0.02)
	elif resaltar_siembra:
		var ps: float = 0.55 + 0.35 * sin(_tiempo * 4.2 + _fase)
		_Contorno_Huella(Color(0.28, 0.92, 0.42, ps), 2.6, 0.02)
	elif listo:
		var pl: float = 0.48 + 0.38 * sin(_tiempo * 4.0 + _fase)
		_Contorno_Huella(Color(1.0, 0.86, 0.24, pl), 2.6, 0.02)
	elif hover:
		_Contorno_Huella(Color(1.0, 0.99, 0.74, 0.90), 2.4, 0.02)


func _Dibujar_Overlays_En(canvas: CanvasItem, c: Vector2) -> void:
	# 1. Burbuja dorada de producto listo (flotando sobre la copa, siempre en primer plano).
	if listo and not modo_vender and not modo_mover:
		var rebote: float = sin(_tiempo * 4.4 + _fase) * 3.8
		var pos_b := c + Vector2(0.0, -altura_visual() * 0.86 - 10.0 + rebote)
		canvas.draw_circle(pos_b + Vector2(0, 3.0), 20.5, Color(0.12, 0.22, 0.04, 0.28))
		canvas.draw_circle(pos_b, 20.5, Color("#f59e0b"))
		canvas.draw_circle(pos_b, 17.5, Color("#fffbeb"))
		var clave_prod: String = cultivo if categoria == "tierra" else (producto if producto != "" else "mg")
		var tex_prod := IconoProducto.obtener_textura(clave_prod)
		if tex_prod != null:
			canvas.draw_texture_rect(tex_prod, Rect2(pos_b - Vector2(13.5, 13.5), Vector2(27, 27)), false)

	# 2. Pastilla compacta siempre legible sobre todos los sprites.
	var texto: String = ""
	var col_bg := Color(1.0, 0.99, 0.94, 0.96)
	var col_borde := Color("#b4833e")
	var col_txt := Color("#3b2511")
	var col_barra := Color("#22c55e")
	var mostrar_barra: bool = false

	if modo_vender:
		texto = "+%d MG" % reembolso
		col_bg = Color("#fee2e2")
		col_borde = Color("#dc2626")
		col_txt = Color("#991b1b")
	elif modo_mover:
		if hover:
			texto = "Mover %d×%d" % [ancho, alto]
			col_bg = Color("#e0f2fe")
			col_borde = Color("#0284c7")
			col_txt = Color("#0c4a6e")
	elif trabajando:
		texto = Sistema_Granja.Formatear_Tiempo(restante)
		col_bg = Color(1.0, 0.99, 0.95, 0.96)
		col_borde = Color("#65a30d") if categoria == "tierra" else Color("#ea580c")
		col_txt = Color("#14532d") if categoria == "tierra" else Color("#7c2d12")
		col_barra = Color("#84cc16") if categoria == "tierra" else Color("#fb923c")
		mostrar_barra = true
	elif listo:
		if hover:
			texto = "¡Recoger!"
			col_bg = Color("#fef3c7")
			col_borde = Color("#d97706")
			col_txt = Color("#92400e")
	elif categoria == "tierra":
		if hover or resaltar_siembra:
			texto = "Sembrar"
			col_bg = Color("#ecfccb")
			col_borde = Color("#65a30d")
			col_txt = Color("#365314")
	elif categoria == "animal":
		if puede_accion:
			texto = "Alimentar"
			col_bg = Color("#dcfce7")
			col_borde = Color("#16a34a")
			col_txt = Color("#14532d")
		elif hover or seleccionado:
			texto = pista_falta if pista_falta != "" else "Sin comida"
			col_bg = Color("#fffbeb")
			col_borde = Color("#d97706")
			col_txt = Color("#92400e")
	elif categoria == "maquina":
		if puede_accion:
			texto = "Cargar"
			col_bg = Color("#dcfce7")
			col_borde = Color("#0d9488")
			col_txt = Color("#115e59")
		elif hover or seleccionado:
			texto = pista_falta if pista_falta != "" else nombre
			col_bg = Color("#f8fafc")
			col_borde = Color("#64748b")
			col_txt = Color("#334155")

	if texto == "":
		return

	var ancho_pill: float = maxf(60.0, FUENTE_BOLD.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16.0)
	var alto_pill: float = 18.0
	var p_inf := position + iso_local(float(ancho), float(alto))
	var y_pill: float = (c.y + 4.0) if (ancho <= 2 and alto <= 2) else (p_inf.y - 16.0)
	var pill_pos := Vector2(c.x - ancho_pill * 0.5, y_pill)
	var rect_p := Rect2(pill_pos, Vector2(ancho_pill, alto_pill))

	_Rect_Redondeado_C(canvas, Rect2(pill_pos + Vector2(0, 2.0), Vector2(ancho_pill, alto_pill)), 9.0, Color(0.08, 0.16, 0.03, 0.24))
	_Rect_Redondeado_C(canvas, rect_p, 9.0, col_borde)
	_Rect_Redondeado_C(canvas, rect_p.grow(-1.6), 7.6, col_bg)

	if mostrar_barra:
		var inner := rect_p.grow(-2.2)
		var w_fill: float = maxf(4.0, inner.size.x * progreso)
		_Rect_Redondeado_C(canvas, Rect2(inner.position, Vector2(w_fill, inner.size.y)), 6.2, Color(col_barra.r, col_barra.g, col_barra.b, 0.56))

	var tw: float = FUENTE_BOLD.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	canvas.draw_string(FUENTE_BOLD, Vector2(c.x - tw * 0.5, pill_pos.y + 12.6), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_txt)


# ------------------------------------------------------------------
# Primitivas vectoriales limpias
# ------------------------------------------------------------------

func _Dibujar_Chispas(centro: Vector2, radio_orbita: float) -> void:
	for i in range(4):
		var a: float = _tiempo * 1.9 + float(i) * (TAU / 4.0) + _fase
		var p := centro + Vector2(cos(a) * radio_orbita, sin(a) * radio_orbita * 0.52)
		var brillo: float = 0.45 + 0.55 * sin(_tiempo * 5.2 + float(i) * 1.7)
		var r: float = 2.8 + brillo * 2.2
		var col := Color(1.0, 0.96, 0.56, brillo)
		draw_line(p - Vector2(r, 0), p + Vector2(r, 0), col, 1.6, true)
		draw_line(p - Vector2(0, r), p + Vector2(0, r), col, 1.6, true)


func _Elipse(centro: Vector2, rx: float, ry: float, color: Color, puntos: int = 18) -> void:
	var p := PackedVector2Array()
	for i in range(puntos):
		var a := TAU * float(i) / float(puntos)
		p.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(p, color)


func _Diamante(centro: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		centro + Vector2(0, -ry),
		centro + Vector2(rx, 0),
		centro + Vector2(0, ry),
		centro + Vector2(-rx, 0),
	]), color)


func _Rect_Redondeado_C(canvas: CanvasItem, rect: Rect2, radio: float, color: Color) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	var r: float = minf(radio, minf(rect.size.x * 0.46, rect.size.y * 0.46))
	if r < 1.0:
		canvas.draw_rect(rect, color)
		return
	var pts := PackedVector2Array()
	var esquinas := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI * 0.5, 0.0],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0, PI * 0.5],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5, PI],
		[Vector2(rect.position.x + r, rect.position.y + r), PI, PI * 1.5],
	]
	for e in esquinas:
		var cen: Vector2 = e[0]
		var a0: float = e[1]
		var a1: float = e[2]
		for k in range(5):
			var a: float = lerpf(a0, a1, float(k) / 4.0)
			var p: Vector2 = cen + Vector2(cos(a) * r, sin(a) * r)
			if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(p) > 0.25:
				pts.append(p)
	if pts.size() >= 3:
		if pts[0].distance_squared_to(pts[pts.size() - 1]) <= 0.25:
			pts.resize(pts.size() - 1)
		if pts.size() >= 3:
			canvas.draw_colored_polygon(pts, color)
