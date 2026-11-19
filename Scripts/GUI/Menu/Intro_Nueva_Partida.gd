extends CanvasLayer
## Intro estilo cómic ilustrado al empezar una nueva vida:
## Página de cómic con cámara de zoom dinámico ("Guided View") viñeta a viñeta
## y plano general final mostrando toda la página completa antes de entrar al juego.
## 1) Cumples 18 años -> 2) Regalo sorpresa -> 3) Orden de desahucio ->
## 4) ¡ZAS! Patada -> 5) Padres partiéndose de risa -> 6) Plano general -> 7) A jugar.
## Pulsar "Saltar" o Esc entra directo; "←" o Flecha Izquierda retrocede una viñeta.

signal terminada

const ANCHO_PAGINA := 720.0
const ALTO_PAGINA := 1280.0

const TINTA := Color("#111827")
const PAPEL := Color("#fbf5e6")
const PAPEL_BORDE := Color("#efe3c8")
const PAPEL_LINEA := Color("#dfd1b2")
const AMARILLO_COMIC := Color("#fde047")
const AMARILLO_OSCURO := Color("#eab308")
const NARANJA_COMIC := Color("#fb923c")

const FUENTE_SFX := preload("res://Fuentes/UI/TitanOne-400.ttf")
const FUENTE_TITULO_COMIC := preload("res://Fuentes/UI/Bricolage-800.ttf")
const FUENTE_TEXTO_COMIC := preload("res://Fuentes/UI/DMSans-700.ttf")

const RUTAS_VINETAS: Array[String] = [
	"res://Imagenes/UI/Comic/vineta_1_fondo.png",
	"res://Imagenes/UI/Comic/vineta_2.png",
	"res://Imagenes/UI/Comic/vineta_3_fondo.png",
	"res://Imagenes/UI/Comic/vineta_4_fondo.png",
	"res://Imagenes/UI/Comic/vineta_5.png",
]

const RUTAS_VINETAS_FALLBACK: Array[String] = [
	"res://Imagenes/UI/Comic/vineta_1.png",
	"res://Imagenes/UI/Comic/vineta_2.png",
	"res://Imagenes/UI/Comic/vineta_3.png",
	"res://Imagenes/UI/Comic/vineta_4.png",
	"res://Imagenes/UI/Comic/vineta_5.png",
]

const RECTS_VINETAS: Array[Rect2] = [
	Rect2(24, 92, 328, 304),
	Rect2(368, 92, 328, 304),
	Rect2(24, 412, 672, 322),
	Rect2(24, 750, 336, 306),
	Rect2(376, 750, 320, 306),
]

const ROTACIONES_VINETAS: Array[float] = [-0.8, 0.8, 0.0, -1.1, 0.9]

const TEXTOS_PIE: Array[String] = [
	"Toca para continuar (1/5)",
	"Toca para continuar (2/5)",
	"Toca para continuar (3/5)",
	"Toca para continuar (4/5)",
	"Toca para ver la página completa (5/5)",
]

var origen: Vector2 = Vector2(-1, -1)
var apariencia: Dictionary = {}

var _raiz: Control
var _escenario_camara: Control
var _camara_pagina: Control
var _fondo_pagina: FondoComic
var _hud: Control
var _btn_atras: Button
var _vinetas: Array[Control] = []
var _artes_wrap: Array[Control] = []
var _velos_foco: Array[ColorRect] = []
var _fx_vinetas: Array[EfectosVineta] = []
var _reveladores_vineta: Array[Callable] = []
var _vinetas_reveladas: Array[bool] = [false, false, false, false, false]
var _pips_progreso: Array[Panel] = []
var _caja_pie: Control
var _pill_continuar: PanelContainer
var _lbl_continuar: Label
var _banner_final: Control
var _flash_impacto: ColorRect
var _apertura_wipe: AperturaWipe
var _remate_overlay: RemateFinalOverlay
var _centro_final: CenterContainer
var _lbl_final_sub: Label
var _lbl_final: Label
var _pill_final: PanelContainer

var _tween_camara: Tween
var _tween_shake: Tween
var _tween_pulso_pie: Tween
var _tween_pulso_banner: Tween
var _tween_final: Tween

var _paso := 0
var _ultimo_toque_ms := 0
var _en_remate := false
var _acabado := false


func _ready() -> void:
	layer = 110
	if apariencia.is_empty():
		apariencia = Apariencia_Personaje.normalizar(Variables_Estaticas.Apariencia)
	else:
		apariencia = Apariencia_Personaje.normalizar(apariencia)
	_construir()
	_iniciar()


# ---------------------------------------------------------------- construcción

func _construir() -> void:
	var tam := _tam_pantalla()
	if origen.x < 0.0:
		origen = tam * 0.5

	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.gui_input.connect(_on_gui_input)
	add_child(_raiz)

	# Papel base fijo detrás de la cámara para cubrir márgenes al hacer zoom/pan
	var papel_base := FondoPapelBase.new()
	papel_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(papel_base)

	# Escenario con recorte que contiene la página de cómic con zoom dinámico
	_escenario_camara = Control.new()
	_escenario_camara.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escenario_camara.clip_contents = true
	_escenario_camara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_escenario_camara)

	_camara_pagina = Control.new()
	_camara_pagina.size = Vector2(ANCHO_PAGINA, ALTO_PAGINA)
	_camara_pagina.pivot_offset = Vector2.ZERO
	_camara_pagina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escenario_camara.add_child(_camara_pagina)

	_fondo_pagina = FondoComic.new(RECTS_VINETAS)
	_fondo_pagina.size = Vector2(ANCHO_PAGINA, ALTO_PAGINA)
	_camara_pagina.add_child(_fondo_pagina)

	var specs := [
		[RECTS_VINETAS[0], Color("#e0f2fe"), "1. ¡POR FIN 18 AÑOS!"],
		[RECTS_VINETAS[1], Color("#fdf2f8"), "2. REGALO SORPRESA"],
		[RECTS_VINETAS[2], Color("#fef08a"), "3. ABRES EL REGALO..."],
		[RECTS_VINETAS[3], Color("#ffedd5"), "4. SIN CONTEMPLACIONES"],
		[RECTS_VINETAS[4], Color("#dcfce7"), "5. EN CASA DE TUS PADRES"],
	]

	for i in range(specs.size()):
		var spec: Array = specs[i]
		var v := _crear_vineta(i, spec[0], spec[1], spec[2])
		_vinetas.append(v)

	_reveladores_vineta = [
		_poblar_vineta_1(_vinetas[0]),
		_poblar_vineta_2(_vinetas[1]),
		_poblar_vineta_3(_vinetas[2]),
		_poblar_vineta_4(_vinetas[3]),
		_poblar_vineta_5(_vinetas[4]),
	]

	for v in _vinetas:
		v.modulate.a = 0.0
		v.scale = Vector2(0.86, 0.86)

	_construir_banner_final()

	# HUD fijo encima de la cámara (cabecera y progreso nunca se pierden al hacer zoom)
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_hud)

	_construir_cabecera(tam)
	_construir_pie(tam)

	# Flash blanco breve de impacto cómic (Viñeta 4)
	_flash_impacto = ColorRect.new()
	_flash_impacto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_impacto.color = Color(1.0, 0.99, 0.92, 0.0)
	_flash_impacto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_flash_impacto)

	_construir_apertura_y_remate(tam)


func _construir_cabecera(tam: Vector2) -> void:
	var margen_x := maxf(24.0, (tam.x - ANCHO_PAGINA) * 0.5 + 24.0)
	var ancho_bar := minf(672.0, tam.x - margen_x * 2.0)

	var header := HBoxContainer.new()
	header.position = Vector2(margen_x, 18.0)
	header.size = Vector2(ancho_bar, 54.0)
	header.add_theme_constant_override("separation", 10)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(header)

	var badge := _crear_caja_con_sombra(Estilos_UI.ROJO_BIT, TINTA, 3, 10, Vector2(3, 4))
	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 14)
	bm.add_theme_constant_override("margin_right", 14)
	bm.add_theme_constant_override("margin_top", 7)
	bm.add_theme_constant_override("margin_bottom", 7)
	badge.add_child(bm)

	var row_badge := HBoxContainer.new()
	row_badge.add_theme_constant_override("separation", 8)
	bm.add_child(row_badge)

	var num_pill := _caja_comic(AMARILLO_COMIC, TINTA, 2, 6)
	var nm := MarginContainer.new()
	nm.add_theme_constant_override("margin_left", 7)
	nm.add_theme_constant_override("margin_right", 7)
	nm.add_theme_constant_override("margin_top", 1)
	nm.add_theme_constant_override("margin_bottom", 1)
	num_pill.add_child(nm)
	nm.add_child(_texto_comic("N.º 1", 12, TINTA, FUENTE_TITULO_COMIC))
	row_badge.add_child(num_pill)

	var lbl_cap := _texto_comic("MAYORÍA DE EDAD", 16, Color.WHITE, FUENTE_TITULO_COMIC)
	_aplicar_contorno(lbl_cap, TINTA, 3, Vector2(1, 2))
	row_badge.add_child(lbl_cap)
	header.add_child(badge)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)

	# Botón retroceder (oculto en la primera viñeta)
	_btn_atras = Button.new()
	_btn_atras.set_meta("_tema_aplicado", true)
	_btn_atras.set_meta("_estilo_propio", true)
	_btn_atras.custom_minimum_size = Vector2(44, 42)
	_btn_atras.icon = Estilos_UI.icono("arrow-left")
	_btn_atras.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn_atras.expand_icon = false
	_btn_atras.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_atras.tooltip_text = "Viñeta anterior"
	_btn_atras.add_theme_color_override("icon_normal_color", TINTA)
	_btn_atras.add_theme_color_override("icon_hover_color", TINTA)
	_btn_atras.add_theme_color_override("icon_pressed_color", TINTA)
	_aplicar_estilo_boton_comic(_btn_atras, 8, 8)
	_btn_atras.pressed.connect(_retroceder)
	_btn_atras.visible = false
	header.add_child(_btn_atras)

	var btn_saltar := Estilos_UI.boton("Saltar", "secundario", "chevron-right", TINTA, 42)
	btn_saltar.add_theme_font_override("font", FUENTE_TITULO_COMIC)
	btn_saltar.add_theme_font_size_override("font_size", 14)
	_aplicar_estilo_boton_comic(btn_saltar, 14, 12)
	btn_saltar.pressed.connect(_terminar)
	header.add_child(btn_saltar)


func _aplicar_estilo_boton_comic(btn: Button, pad_izq: int, pad_der: int) -> void:
	var st := Estilos_UI.caja(Color.WHITE, 10, TINTA, 3, 0)
	st.shadow_color = TINTA
	st.shadow_size = 0
	st.shadow_offset = Vector2(3, 3)
	st.content_margin_left = pad_izq
	st.content_margin_right = pad_der
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	var st_hov := st.duplicate() as StyleBoxFlat
	st_hov.bg_color = AMARILLO_COMIC
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hov)
	btn.add_theme_stylebox_override("pressed", st_hov)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _cargar_textura_vineta(idx: int) -> Texture2D:
	for ruta: String in [RUTAS_VINETAS[idx], RUTAS_VINETAS_FALLBACK[idx]]:
		if ResourceLoader.exists(ruta):
			var res: Resource = load(ruta)
			if res is Texture2D:
				return res
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(ruta))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _crear_vineta(idx: int, rect: Rect2, color_fondo: Color, titulo_cartela: String) -> Control:
	var cont := Control.new()
	cont.position = rect.position
	cont.size = rect.size
	cont.pivot_offset = rect.size * 0.5
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camara_pagina.add_child(cont)

	# Sombra dura redondeada estilo cómic impreso
	var sombra := Panel.new()
	sombra.position = Vector2(6, 7)
	sombra.size = rect.size
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_sombra := StyleBoxFlat.new()
	st_sombra.bg_color = TINTA
	st_sombra.set_corner_radius_all(12)
	st_sombra.anti_aliasing = true
	sombra.add_theme_stylebox_override("panel", st_sombra)
	cont.add_child(sombra)

	# Panel con recorte redondeado real
	var marco_clip := Panel.new()
	marco_clip.name = "MarcoClip"
	marco_clip.size = rect.size
	marco_clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	marco_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_clip := StyleBoxFlat.new()
	st_clip.bg_color = color_fondo
	st_clip.set_corner_radius_all(12)
	st_clip.anti_aliasing = true
	marco_clip.add_theme_stylebox_override("panel", st_clip)
	cont.add_child(marco_clip)

	# Contenedor del arte ilustrado (permite Ken Burns sutil y micro-vibración sin romper el recorte)
	var arte_wrap := Control.new()
	arte_wrap.name = "ArteWrap"
	arte_wrap.size = rect.size
	arte_wrap.pivot_offset = rect.size * 0.5
	arte_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco_clip.add_child(arte_wrap)
	_artes_wrap.append(arte_wrap)

	var arte := TextureRect.new()
	arte.name = "Arte"
	arte.set_anchors_preset(Control.PRESET_FULL_RECT)
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	arte.texture = _cargar_textura_vineta(idx)
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arte_wrap.add_child(arte)

	# Efectos sutiles animados sobre la ilustración (confeti, destellos, brillo)
	var fx := EfectosVineta.new(idx + 1)
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco_clip.add_child(fx)
	_fx_vinetas.append(fx)

	# Capa de bocadillos, tarjeta y SFX
	var interior := Control.new()
	interior.name = "Interior"
	interior.set_anchors_preset(Control.PRESET_FULL_RECT)
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco_clip.add_child(interior)

	# Velo suave que atenúa ligeramente las viñetas inactivas durante el zoom
	var velo := ColorRect.new()
	velo.name = "VeloFoco"
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.11, 0.09, 0.07, 0.0)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco_clip.add_child(velo)
	_velos_foco.append(velo)

	# Borde negro limpio dibujado siempre encima del contenido recortado
	var marco_borde := Panel.new()
	marco_borde.name = "MarcoBorde"
	marco_borde.size = rect.size
	marco_borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_borde := StyleBoxFlat.new()
	st_borde.bg_color = Color(0, 0, 0, 0)
	st_borde.border_color = TINTA
	st_borde.set_border_width_all(4)
	st_borde.set_corner_radius_all(12)
	st_borde.anti_aliasing = true
	marco_borde.add_theme_stylebox_override("panel", st_borde)
	cont.add_child(marco_borde)

	# Cartela amarilla superior de narrador con mini sombra cómic
	var cartela := _crear_caja_con_sombra(AMARILLO_COMIC, TINTA, 3, 6, Vector2(2, 3))
	cartela.position = Vector2(10, 10)
	cartela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 9)
	cm.add_theme_constant_override("margin_right", 9)
	cm.add_theme_constant_override("margin_top", 3)
	cm.add_theme_constant_override("margin_bottom", 3)
	cartela.add_child(cm)
	cm.add_child(_texto_comic(titulo_cartela, 12, TINTA, FUENTE_TITULO_COMIC))
	cont.add_child(cartela)

	return cont


func _poblar_vineta_1(v: Control) -> Callable:
	var arte_wrap := _artes_wrap[0]
	var prota := Personaje_Visual.new(apariencia, "busto")
	prota.position = Vector2(18, 44)
	prota.size = Vector2(288, 266)
	prota.pose = "celebrar"
	prota.expresion = "feliz"
	prota.accesorio_cabeza = "gorro_fiesta"
	prota.prop_mano = "tarta_18"
	prota.animar_idle = true
	arte_wrap.add_child(prota)

	var es_mujer := Apariencia_Personaje.es_mujer(apariencia)
	var texto_b1 := "¡Por fin soy\nadulta!" if es_mujer else "¡Por fin soy\nadulto!"
	var interior: Control = v.get_node("MarcoClip/Interior")
	var bocadillo := BocadilloComic.new(texto_b1, Vector2(198, 46), Vector2(166, 128), 13)
	interior.add_child(bocadillo)
	return func():
		bocadillo.revelar(0.24)


func _poblar_vineta_2(v: Control) -> Callable:
	var es_mujer := Apariencia_Personaje.es_mujer(apariencia)
	var texto_b2 := "¡Feliz 18, hija!\nÁbrelo ya..." if es_mujer else "¡Feliz 18, hijo!\nÁbrelo ya..."
	var interior: Control = v.get_node("MarcoClip/Interior")
	var bocadillo := BocadilloComic.new(texto_b2, Vector2(196, 46), Vector2(182, 108), 12)
	interior.add_child(bocadillo)
	return func():
		bocadillo.revelar(0.26)


func _poblar_vineta_3(v: Control) -> Callable:
	var interior: Control = v.get_node("MarcoClip/Interior")
	var arte_wrap := _artes_wrap[2]

	# Personaje personalizado en shock detrás de la caja de regalo abierta
	var prota := Personaje_Visual.new(apariencia, "busto")
	prota.position = Vector2(126, 46)
	prota.size = Vector2(214, 286)
	prota.pose = "sorpresa"
	prota.expresion = "sorpresa"
	prota.accesorio_cabeza = "gorro_volando"
	prota.animar_idle = true
	arte_wrap.add_child(prota)

	# Frente de la caja de regalo roja y dorada delante de la cintura del personaje
	var caja_frente := CajaRegaloFrente.new()
	caja_frente.position = Vector2(24, 212)
	caja_frente.size = Vector2(214, 118)
	arte_wrap.add_child(caja_frente)

	# Tarjeta oficial del vale de cumpleaños sobre la mitad derecha dorada
	var nota_wrap := Control.new()
	nota_wrap.position = Vector2(348, 36)
	nota_wrap.size = Vector2(308, 254)
	nota_wrap.pivot_offset = nota_wrap.size * 0.5
	nota_wrap.rotation = deg_to_rad(-1.4)
	nota_wrap.scale = Vector2(0.72, 0.72)
	nota_wrap.modulate.a = 0.0
	nota_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.add_child(nota_wrap)

	var nota_sombra := Panel.new()
	nota_sombra.position = Vector2(5, 6)
	nota_sombra.size = nota_wrap.size
	nota_sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_ns := StyleBoxFlat.new()
	st_ns.bg_color = TINTA
	st_ns.set_corner_radius_all(10)
	nota_sombra.add_theme_stylebox_override("panel", st_ns)
	nota_wrap.add_child(nota_sombra)

	var nota := Panel.new()
	nota.size = nota_wrap.size
	nota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_nota := StyleBoxFlat.new()
	st_nota.bg_color = Color("#fffdf7")
	st_nota.border_color = TINTA
	st_nota.set_border_width_all(3)
	st_nota.set_corner_radius_all(10)
	nota.add_theme_stylebox_override("panel", st_nota)
	nota_wrap.add_child(nota)

	# Banda superior decorativa roja tipo tarjeta oficial
	var cinta_top := ColorRect.new()
	cinta_top.color = Estilos_UI.ROJO_BIT
	cinta_top.position = Vector2(3, 3)
	cinta_top.size = Vector2(nota_wrap.size.x - 6, 8)
	cinta_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nota.add_child(cinta_top)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 50)
	nota.add_child(m)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	m.add_child(col)

	var sello := _caja_comic(Color("#fee2e2"), Estilos_UI.ROJO_BIT, 2, 999)
	sello.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 10)
	sm.add_theme_constant_override("margin_right", 10)
	sm.add_theme_constant_override("margin_top", 2)
	sm.add_theme_constant_override("margin_bottom", 2)
	sello.add_child(sm)
	sm.add_child(_texto_comic("VALE DE CUMPLEAÑOS", 11, Estilos_UI.ROJO_BIT, FUENTE_TITULO_COMIC))
	col.add_child(sello)

	var titulo_nota := _texto_comic("¡TE ECHAMOS DE CASA!", 20, Estilos_UI.ROJO_BIT, FUENTE_TITULO_COMIC)
	titulo_nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aplicar_contorno(titulo_nota, Color("#fff1f2"), 2, Vector2(1, 2), Color("#fecdd3"))
	col.add_child(titulo_nota)

	var sep := ColorRect.new()
	sep.color = Color("#e5dec9")
	sep.custom_minimum_size = Vector2(196, 2)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(sep)

	var es_mujer := Apariencia_Personaje.es_mujer(apariencia)
	var apodo := "campeona" if es_mujer else "campeón"
	var sub_nota := Estilos_UI.parrafo(
		"Tienes 5 minutos para hacer la maleta.\n¡Mucha suerte con el alquiler, %s!" % apodo,
		13, TINTA)
	sub_nota.add_theme_font_override("font", FUENTE_TEXTO_COMIC)
	sub_nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub_nota)

	# Sello de goma "¡DESAHUCIO!" en la zona inferior derecha
	var timbre := _caja_comic(Color(1, 1, 1, 0.95), Estilos_UI.ROJO_BIT, 3, 6)
	timbre.position = Vector2(168, 204)
	timbre.rotation = deg_to_rad(-8.0)
	timbre.scale = Vector2(2.4, 2.4)
	timbre.modulate.a = 0.0
	timbre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 10)
	tm.add_theme_constant_override("margin_right", 10)
	tm.add_theme_constant_override("margin_top", 3)
	tm.add_theme_constant_override("margin_bottom", 3)
	timbre.add_child(tm)
	tm.add_child(_texto_comic("¡DESAHUCIO!", 13, Estilos_UI.ROJO_BIT, FUENTE_TITULO_COMIC))
	nota_wrap.add_child(timbre)

	return func():
		var tw := create_tween().set_parallel(true)
		tw.tween_property(nota_wrap, "modulate:a", 1.0, 0.16).set_delay(0.18)
		tw.tween_property(nota_wrap, "scale", Vector2.ONE, 0.34).set_delay(0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		timbre.pivot_offset = Vector2(64, 15)
		var tw_sello := create_tween()
		tw_sello.tween_interval(0.50)
		tw_sello.set_parallel(true)
		tw_sello.tween_property(timbre, "modulate:a", 1.0, 0.08)
		tw_sello.tween_property(timbre, "scale", Vector2.ONE, 0.16) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw_sello.set_parallel(false)
		tw_sello.tween_callback(func():
			var base_nota := nota_wrap.position
			var base_arte := arte_wrap.position
			var seq_n := create_tween()
			for d in [Vector2(-5, 3), Vector2(5, -3), Vector2(-3, 2), Vector2.ZERO]:
				seq_n.tween_property(nota_wrap, "position", base_nota + d, 0.04)
			var seq_a := create_tween()
			for d in [Vector2(-4, 2), Vector2(4, -2), Vector2(-2, 1), Vector2.ZERO]:
				seq_a.tween_property(arte_wrap, "position", base_arte + d, 0.04))


func _poblar_vineta_4(v: Control) -> Callable:
	var arte_wrap := _artes_wrap[3]
	var prota := Personaje_Visual.new(apariencia, "cuerpo_completo")
	prota.position = Vector2(142, 8)
	prota.size = Vector2(195, 216)
	prota.pose = "volando"
	prota.expresion = "panico"
	prota.animar_idle = true
	arte_wrap.add_child(prota)

	var interior: Control = v.get_node("MarcoClip/Interior")

	var zas := EstallidoSFX.new("¡ZAS!", Vector2(88, 44), Vector2(128, 66), -6.0)
	interior.add_child(zas)

	# Bocadillo de los padres desde la puerta abierta (cola apuntando a la puerta)
	var bocadillo := BocadilloComic.new("¡A volar!", Vector2(22, 246), Vector2(26, 200), 13)
	interior.add_child(bocadillo)

	return func():
		zas.revelar(0.14)
		bocadillo.revelar(0.30)


func _poblar_vineta_5(v: Control) -> Callable:
	var interior: Control = v.get_node("MarcoClip/Interior")

	var risas := Control.new()
	risas.position = Vector2(180, 38)
	risas.size = Vector2(132, 50)
	risas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.add_child(risas)

	var silabas := [
		["¡JA", Vector2(0, 7), -9.0, 22],
		["JA", Vector2(40, 2), 4.0, 24],
		["JA!", Vector2(74, 6), -6.0, 25],
	]
	var nodos_risa: Array[Label] = []
	for item in silabas:
		var lbl := _texto_comic(item[0], item[3], Estilos_UI.ROJO_BIT, FUENTE_SFX)
		lbl.position = item[1]
		lbl.rotation = deg_to_rad(item[2])
		lbl.pivot_offset = Vector2(20, 14)
		lbl.scale = Vector2.ZERO
		lbl.modulate.a = 0.0
		_aplicar_contorno(lbl, Color.WHITE, 5, Vector2(2, 3), TINTA)
		risas.add_child(lbl)
		nodos_risa.append(lbl)

	var bocadillo := BocadilloComic.new("¡Por fin la casa\npara nosotros!", Vector2(104, 246), Vector2(160, 212), 12)
	interior.add_child(bocadillo)

	return func():
		for idx in range(nodos_risa.size()):
			var lbl := nodos_risa[idx]
			var retardo := 0.16 + float(idx) * 0.10
			var tw := create_tween().set_parallel(true)
			tw.tween_property(lbl, "modulate:a", 1.0, 0.12).set_delay(retardo)
			tw.tween_property(lbl, "scale", Vector2.ONE, 0.28).set_delay(retardo) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bocadillo.revelar(0.32)


func _construir_pie(tam: Vector2) -> void:
	var margen_x := maxf(24.0, (tam.x - ANCHO_PAGINA) * 0.5 + 24.0)
	var ancho_pie := minf(672.0, tam.x - margen_x * 2.0)

	_caja_pie = Control.new()
	_caja_pie.position = Vector2(margen_x, tam.y - 122.0)
	_caja_pie.size = Vector2(ancho_pie, 102.0)
	_caja_pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_caja_pie)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja_pie.add_child(col)

	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 10)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(pips)

	for i in range(5):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.pivot_offset = Vector2(7, 7)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
		_pips_progreso.append(pip)
	_actualizar_pips(0)

	_pill_continuar = _crear_caja_con_sombra(Color.WHITE, TINTA, 3, 999, Vector2(3, 4))
	_pill_continuar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pill_continuar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_pill_continuar)

	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 20)
	pm.add_theme_constant_override("margin_right", 20)
	pm.add_theme_constant_override("margin_top", 9)
	pm.add_theme_constant_override("margin_bottom", 9)
	_pill_continuar.add_child(pm)

	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 8)
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	pm.add_child(prow)

	var ic := Estilos_UI.icono_rect("sparkles", 18, Estilos_UI.ROJO_BIT)
	prow.add_child(ic)

	_lbl_continuar = _texto_comic(TEXTOS_PIE[0], 15, TINTA, FUENTE_TITULO_COMIC)
	prow.add_child(_lbl_continuar)

	_iniciar_pulso_pie()


func _iniciar_pulso_pie() -> void:
	if _tween_pulso_pie != null and _tween_pulso_pie.is_valid():
		_tween_pulso_pie.kill()
	_pill_continuar.pivot_offset = Vector2(140, 20)
	_tween_pulso_pie = create_tween().set_loops()
	_tween_pulso_pie.tween_property(_pill_continuar, "scale", Vector2(1.04, 1.04), 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_pulso_pie.tween_property(_pill_continuar, "scale", Vector2.ONE, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _construir_banner_final() -> void:
	_banner_final = Control.new()
	_banner_final.position = Vector2(24, 1076)
	_banner_final.size = Vector2(672, 132)
	_banner_final.pivot_offset = _banner_final.size * 0.5
	_banner_final.modulate.a = 0.0
	_banner_final.scale = Vector2(0.82, 0.82)
	_banner_final.visible = false
	_banner_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camara_pagina.add_child(_banner_final)

	var sombra := Panel.new()
	sombra.position = Vector2(6, 7)
	sombra.size = _banner_final.size
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_s := StyleBoxFlat.new()
	st_s.bg_color = TINTA
	st_s.set_corner_radius_all(16)
	sombra.add_theme_stylebox_override("panel", st_s)
	_banner_final.add_child(sombra)

	var marco := Panel.new()
	marco.size = _banner_final.size
	marco.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_m := StyleBoxFlat.new()
	st_m.bg_color = Estilos_UI.ROJO_BIT
	st_m.set_corner_radius_all(16)
	marco.add_theme_stylebox_override("panel", st_m)
	_banner_final.add_child(marco)

	var fondo_rayas := FondoBannerComic.new()
	fondo_rayas.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco.add_child(fondo_rayas)

	var marco_borde := Panel.new()
	marco_borde.size = _banner_final.size
	marco_borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_mb := StyleBoxFlat.new()
	st_mb.bg_color = Color(0, 0, 0, 0)
	st_mb.border_color = TINTA
	st_mb.set_border_width_all(4)
	st_mb.set_corner_radius_all(16)
	marco_borde.add_theme_stylebox_override("panel", st_mb)
	_banner_final.add_child(marco_borde)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	marco.add_child(m)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(row)

	var moneda := MonedaComic.new()
	moneda.custom_minimum_size = Vector2(70, 70)
	moneda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(moneda)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	var t1 := _texto_comic("¡TU NUEVA VIDA EMPIEZA AHORA!", 22, Color.WHITE, FUENTE_TITULO_COMIC)
	_aplicar_contorno(t1, TINTA, 4, Vector2(2, 3))
	col.add_child(t1)

	var t2 := _texto_comic("Con 1.000 € en el bolsillo · Toca para empezar", 15, AMARILLO_COMIC, FUENTE_TEXTO_COMIC)
	col.add_child(t2)

	var play_badge := _crear_caja_con_sombra(AMARILLO_COMIC, TINTA, 3, 999, Vector2(2, 3))
	play_badge.custom_minimum_size = Vector2(48, 48)
	play_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pc := CenterContainer.new()
	pc.add_child(Estilos_UI.icono_rect("play", 22, TINTA))
	play_badge.add_child(pc)
	row.add_child(play_badge)


func _construir_apertura_y_remate(tam: Vector2) -> void:
	_apertura_wipe = AperturaWipe.new(origen, tam)
	_apertura_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_apertura_wipe)

	var centro_banner := _pos_pagina_completa() + (_banner_final.position + _banner_final.size * 0.5) * _escala_pagina_completa()
	_remate_overlay = RemateFinalOverlay.new(centro_banner, tam)
	_remate_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_remate_overlay)

	_centro_final = CenterContainer.new()
	_centro_final.set_anchors_preset(Control.PRESET_FULL_RECT)
	_centro_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_centro_final)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_centro_final.add_child(vbox)

	_pill_final = _crear_caja_con_sombra(AMARILLO_COMIC, TINTA, 3, 999, Vector2(3, 4))
	_pill_final.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pill_final.modulate.a = 0.0
	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 16)
	pm.add_theme_constant_override("margin_right", 16)
	pm.add_theme_constant_override("margin_top", 6)
	pm.add_theme_constant_override("margin_bottom", 6)
	_pill_final.add_child(pm)
	pm.add_child(_texto_comic("18 AÑOS · 1.000 € EN EL BOLSILLO", 14, TINTA, FUENTE_TITULO_COMIC))
	vbox.add_child(_pill_final)

	_lbl_final = Label.new()
	_lbl_final.text = "Tu nueva vida\nempieza ahora"
	_lbl_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_final.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_final.add_theme_font_override("font", Estilos_UI.fuente_editorial(700))
	_lbl_final.add_theme_font_size_override("font_size", 56)
	_lbl_final.add_theme_color_override("font_color", Color.WHITE)
	_aplicar_contorno(_lbl_final, Estilos_UI.ROJO_BIT_OSCURO, 6, Vector2(0, 4), Color(0, 0, 0, 0.35))
	_lbl_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_final.modulate.a = 0.0
	vbox.add_child(_lbl_final)

	_lbl_final_sub = _texto_comic("¡Mucha suerte ahí fuera!", 20, Color("#fef3c7"), FUENTE_TITULO_COMIC)
	_lbl_final_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_final_sub.modulate.a = 0.0
	vbox.add_child(_lbl_final_sub)


# ---------------------------------------------------------------- cámara dinámica ("Guided View")

func _escala_pagina_completa() -> float:
	var tam := _tam_pantalla()
	return minf(1.0, minf(tam.x / ANCHO_PAGINA, tam.y / ALTO_PAGINA))


func _pos_pagina_completa() -> Vector2:
	var tam := _tam_pantalla()
	var esc := _escala_pagina_completa()
	return Vector2(
		(tam.x - ANCHO_PAGINA * esc) * 0.5,
		maxf(0.0, (tam.y - ALTO_PAGINA * esc) * 0.5)
	)


func _transform_para_vineta(idx: int) -> Dictionary:
	var tam := _tam_pantalla()
	var top_safe := 86.0
	var bottom_safe := 134.0
	var zona := Rect2(18.0, top_safe, maxf(240.0, tam.x - 36.0), maxf(240.0, tam.y - top_safe - bottom_safe))
	var r: Rect2 = RECTS_VINETAS[idx]
	var pad := 16.0 if idx == 2 else 22.0
	var zx := zona.size.x / (r.size.x + pad * 2.0)
	var zy := zona.size.y / (r.size.y + pad * 2.0)
	var zoom := clampf(minf(zx, zy), 0.96, 1.88)
	var pos := zona.get_center() - r.get_center() * zoom
	return {"pos": pos, "scale": Vector2(zoom, zoom)}


func _mover_camara(destino_pos: Vector2, destino_scale: Vector2, duracion: float, inmediato: bool = false) -> void:
	if _tween_camara != null and _tween_camara.is_valid():
		_tween_camara.kill()
	if inmediato:
		_camara_pagina.position = destino_pos
		_camara_pagina.scale = destino_scale
		return
	_tween_camara = create_tween().set_parallel(true)
	_tween_camara.tween_property(_camara_pagina, "position", destino_pos, duracion) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_tween_camara.tween_property(_camara_pagina, "scale", destino_scale, duracion) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)


func _actualizar_foco_vinetas(idx_activo: int) -> void:
	# idx_activo == -1 significa plano general (todas iluminadas al 100%)
	for i in range(_velos_foco.size()):
		var velo := _velos_foco[i]
		var objetivo_a := 0.0
		if idx_activo >= 0 and i != idx_activo and _vinetas_reveladas[i]:
			objetivo_a = 0.28
		var tw := create_tween()
		tw.tween_property(velo, "color:a", objetivo_a, 0.30)


func _sacudir_escenario(amplitud: float = 12.0) -> void:
	if _tween_shake != null and _tween_shake.is_valid():
		_tween_shake.kill()
	_escenario_camara.position = Vector2.ZERO
	_tween_shake = create_tween()
	var offsets := [
		Vector2(-amplitud, amplitud * 0.45),
		Vector2(amplitud, -amplitud * 0.55),
		Vector2(-amplitud * 0.7, -amplitud * 0.35),
		Vector2(amplitud * 0.55, amplitud * 0.3),
		Vector2(-amplitud * 0.25, amplitud * 0.15),
		Vector2.ZERO,
	]
	for off in offsets:
		_tween_shake.tween_property(_escenario_camara, "position", off, 0.042)


func _disparar_flash_impacto() -> void:
	_flash_impacto.color.a = 0.65
	var tw := create_tween()
	tw.tween_property(_flash_impacto, "color:a", 0.0, 0.24) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- flujo y animación

func _iniciar() -> void:
	# Arranca ligeramente alejado y entra con zoom suave a la Viñeta 1
	var esc_full := _escala_pagina_completa()
	_mover_camara(_pos_pagina_completa(), Vector2(esc_full, esc_full), 0.0, true)

	_camara_pagina.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_camara_pagina, "modulate:a", 1.0, 0.24)
	tw.tween_property(_apertura_wipe, "progreso", 1.0, 0.44) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _apertura_wipe.visible = false).set_delay(0.45)

	_paso = 0
	_ir_a_paso(0, true)


func _avanzar() -> void:
	if _acabado or _en_remate:
		return
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_toque_ms < 180:
		return
	_ultimo_toque_ms = ahora

	if _paso >= 5:
		_reproducir_remate_final()
		return

	_paso += 1
	_ir_a_paso(_paso, false)


func _retroceder() -> void:
	if _acabado or _en_remate or _paso <= 0:
		return
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_toque_ms < 160:
		return
	_ultimo_toque_ms = ahora

	_paso -= 1
	_ir_a_paso(_paso, false)


func _ir_a_paso(paso: int, es_inicio: bool) -> void:
	_btn_atras.visible = paso > 0

	if paso < 5:
		# Si volvemos desde el plano general, restauramos el pie y ocultamos el banner
		_ocultar_banner_y_mostrar_pie()

		var tr := _transform_para_vineta(paso)
		var dur := 0.56 if es_inicio else 0.48
		_mover_camara(tr["pos"], tr["scale"], dur)

		var primera_vez := not _vinetas_reveladas[paso]
		if primera_vez:
			_vinetas_reveladas[paso] = true
			_revelar_vineta(paso, ROTACIONES_VINETAS[paso], paso == 3)
		elif paso == 3:
			_sacudir_escenario(7.0)

		_actualizar_foco_vinetas(paso)
		_lbl_continuar.text = TEXTOS_PIE[paso]
		_actualizar_pips(paso)
	else:
		# Paso 5: Plano general revelando toda la página completa + banner final
		var esc := _escala_pagina_completa()
		_mover_camara(_pos_pagina_completa(), Vector2(esc, esc), 0.62)
		_actualizar_foco_vinetas(-1)
		_actualizar_pips(4)

		if _tween_pulso_pie != null and _tween_pulso_pie.is_valid():
			_tween_pulso_pie.kill()
		var tw_pie := create_tween()
		tw_pie.tween_property(_caja_pie, "modulate:a", 0.0, 0.20)
		tw_pie.tween_callback(func(): _caja_pie.visible = false)
		tw_pie.tween_interval(0.18)
		tw_pie.tween_callback(_mostrar_banner_final)


func _revelar_vineta(idx: int, rot_grados: float, impacto: bool) -> void:
	var v := _vinetas[idx]
	var arte_wrap := _artes_wrap[idx]
	var fx := _fx_vinetas[idx]

	v.rotation = deg_to_rad(rot_grados)
	arte_wrap.scale = Vector2(1.09, 1.09)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(v, "modulate:a", 1.0, 0.20)
	tw.tween_property(v, "scale", Vector2.ONE, 0.38) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Ken Burns suave sobre la ilustración recién revelada
	tw.tween_property(arte_wrap, "scale", Vector2.ONE, 1.10) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx, "intensidad", 1.0, 0.45)

	_reveladores_vineta[idx].call()

	if impacto:
		_disparar_flash_impacto()
		_sacudir_escenario(13.0)
		var pos_base := v.position
		var sh := create_tween()
		for off in [Vector2(-9, 4), Vector2(9, -5), Vector2(-6, -3), Vector2(5, 3), Vector2.ZERO]:
			sh.tween_property(v, "position", pos_base + off, 0.042)


func _actualizar_pips(activo: int) -> void:
	for i in range(_pips_progreso.size()):
		var pip := _pips_progreso[i]
		var st := StyleBoxFlat.new()
		st.set_corner_radius_all(999)
		st.border_color = TINTA
		st.set_border_width_all(2)
		if i == activo:
			st.bg_color = AMARILLO_COMIC
		elif i < activo or _vinetas_reveladas[i]:
			st.bg_color = Estilos_UI.ROJO_BIT
		else:
			st.bg_color = Color("#ede3cc")
		pip.add_theme_stylebox_override("panel", st)
		pip.scale = Vector2(1.28, 1.28) if i == activo else Vector2.ONE


func _mostrar_banner_final() -> void:
	if _paso < 5:
		return
	_banner_final.visible = true
	_banner_final.modulate.a = 0.0
	_banner_final.scale = Vector2(0.84, 0.84)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_banner_final, "modulate:a", 1.0, 0.22)
	tw.tween_property(_banner_final, "scale", Vector2.ONE, 0.42) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_callback(_iniciar_pulso_banner)


func _iniciar_pulso_banner() -> void:
	if _paso < 5 or _en_remate:
		return
	if _tween_pulso_banner != null and _tween_pulso_banner.is_valid():
		_tween_pulso_banner.kill()
	_tween_pulso_banner = create_tween().set_loops()
	_tween_pulso_banner.tween_property(_banner_final, "scale", Vector2(1.022, 1.022), 0.72) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_pulso_banner.tween_property(_banner_final, "scale", Vector2.ONE, 0.72) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _ocultar_banner_y_mostrar_pie() -> void:
	if _tween_pulso_banner != null and _tween_pulso_banner.is_valid():
		_tween_pulso_banner.kill()
	if _banner_final.visible:
		_banner_final.visible = false
		_banner_final.modulate.a = 0.0
		_banner_final.scale = Vector2(0.84, 0.84)
	if not _caja_pie.visible:
		_caja_pie.visible = true
		_caja_pie.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_caja_pie, "modulate:a", 1.0, 0.20)
		_iniciar_pulso_pie()


func _reproducir_remate_final() -> void:
	_en_remate = true
	_btn_atras.visible = false
	if _tween_pulso_banner != null and _tween_pulso_banner.is_valid():
		_tween_pulso_banner.kill()
	_remate_overlay.visible = true
	_tween_final = create_tween()
	_tween_final.tween_property(_remate_overlay, "progreso", 1.0, 0.48) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween_final.tween_callback(_mostrar_texto_y_destellos)
	_tween_final.tween_interval(1.25)
	_tween_final.tween_callback(_terminar)


func _mostrar_texto_y_destellos() -> void:
	for ctrl in [_pill_final, _lbl_final, _lbl_final_sub]:
		ctrl.pivot_offset = ctrl.size * 0.5
		ctrl.scale = Vector2(0.82, 0.82)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_pill_final, "modulate:a", 1.0, 0.25)
	tw.tween_property(_pill_final, "scale", Vector2.ONE, 0.36) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_lbl_final, "modulate:a", 1.0, 0.28).set_delay(0.06)
	tw.tween_property(_lbl_final, "scale", Vector2.ONE, 0.44).set_delay(0.06) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_lbl_final_sub, "modulate:a", 1.0, 0.26).set_delay(0.16)
	tw.tween_property(_lbl_final_sub, "scale", Vector2.ONE, 0.34).set_delay(0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lanzar_destellos()


func _lanzar_destellos() -> void:
	var centro := _tam_pantalla() * 0.5
	var iconos := ["sparkles", "star", "euro"]
	var cantidad := 18
	for i in range(cantidad):
		var nombre: String = iconos[i % iconos.size()]
		var color := Color.WHITE if i % 3 == 0 else AMARILLO_COMIC
		var tam := randi_range(22, 38)
		var p := Estilos_UI.icono_rect(nombre, tam, color)
		p.size = Vector2(tam, tam)
		p.pivot_offset = p.size * 0.5
		var angulo := TAU * float(i) / float(cantidad) + randf_range(-0.18, 0.18)
		var dir := Vector2(cos(angulo), sin(angulo))
		var origen_p := centro - p.size * 0.5 + dir * randf_range(95.0, 140.0)
		p.position = origen_p
		p.scale = Vector2(0.3, 0.3)
		_raiz.add_child(p)

		var distancia := randf_range(135.0, 225.0)
		var destino := origen_p + dir * distancia
		var tw := create_tween().set_parallel(true)
		tw.tween_property(p, "position", destino, 0.80) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector2.ONE, 0.34) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "rotation", randf_range(-PI, PI), 0.80)
		tw.tween_property(p, "modulate:a", 0.0, 0.45).set_delay(0.55)
	_raiz.move_child(_centro_final, -1)


# ---------------------------------------------------------------- helpers UI

func _caja_comic(fondo: Color, borde: Color, grosor: int, radio: int) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(grosor)
	st.set_corner_radius_all(radio)
	st.anti_aliasing = true
	p.add_theme_stylebox_override("panel", st)
	return p


func _crear_caja_con_sombra(fondo: Color, borde: Color, grosor: int, radio: int, sombra_off: Vector2) -> PanelContainer:
	var p := _caja_comic(fondo, borde, grosor, radio)
	var st := p.get_theme_stylebox("panel") as StyleBoxFlat
	st.shadow_color = TINTA
	st.shadow_size = 0
	st.shadow_offset = sombra_off
	return p


func _texto_comic(contenido: String, tam: int, color: Color, fuente: FontFile) -> Label:
	var lbl := Label.new()
	lbl.set_meta("_tema_aplicado", true)
	lbl.text = contenido
	lbl.add_theme_font_override("font", fuente)
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


func _aplicar_contorno(lbl: Label, color_borde: Color, grosor: int, sombra_off: Vector2, color_sombra: Color = TINTA) -> void:
	lbl.add_theme_constant_override("outline_size", grosor)
	lbl.add_theme_color_override("font_outline_color", color_borde)
	lbl.add_theme_color_override("font_shadow_color", color_sombra)
	lbl.add_theme_constant_override("shadow_offset_x", int(sombra_off.x))
	lbl.add_theme_constant_override("shadow_offset_y", int(sombra_off.y))


# ---------------------------------------------------------------- control

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_avanzar()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_terminar()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT]:
			get_viewport().set_input_as_handled()
			_avanzar()
		elif event.keycode in [KEY_LEFT, KEY_BACKSPACE]:
			get_viewport().set_input_as_handled()
			_retroceder()


func _terminar() -> void:
	if _acabado:
		return
	_acabado = true
	for tw in [_tween_camara, _tween_shake, _tween_pulso_pie, _tween_pulso_banner, _tween_final]:
		if tw != null and tw.is_valid():
			tw.kill()
	terminada.emit()


func _tam_pantalla() -> Vector2:
	return get_viewport().get_visible_rect().size


# ---------------------------------------------------------------- geometría cómic compartida

class ArteComic extends RefCounted:
	static func rect_redondeado(rect: Rect2, radio: float, segs: int = 6) -> PackedVector2Array:
		var r := minf(radio, minf(rect.size.x, rect.size.y) * 0.5)
		var pts := PackedVector2Array()
		var centros := [
			Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
			Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
			Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
			Vector2(rect.position.x + r, rect.position.y + r),
		]
		var angulos := [-PI * 0.5, 0.0, PI * 0.5, PI]
		for c_idx in range(4):
			var c: Vector2 = centros[c_idx]
			var a0: float = angulos[c_idx]
			for s in range(segs + 1):
				var a := a0 + (PI * 0.5) * (float(s) / float(segs))
				pts.append(c + Vector2(cos(a), sin(a)) * r)
		return pts

	static func poligono_ink(c: CanvasItem, pts: PackedVector2Array, relleno: Color, tinta: Color, grosor: float = 3.0, sombra_off: Vector2 = Vector2.ZERO) -> void:
		if sombra_off != Vector2.ZERO:
			var som := PackedVector2Array()
			for p in pts:
				som.append(p + sombra_off)
			c.draw_colored_polygon(som, tinta)
		c.draw_colored_polygon(pts, relleno)
		var cerrado := PackedVector2Array(pts)
		cerrado.append(pts[0])
		c.draw_polyline(cerrado, tinta, grosor, true)

	static func estrella(centro: Vector2, puntas: int, r_ext: float, r_int: float, rot: float = 0.0, estiramiento: Vector2 = Vector2.ONE) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var total := puntas * 2
		for i in range(total):
			var ang := rot + TAU * float(i) / float(total)
			var r := r_ext if i % 2 == 0 else r_int
			pts.append(centro + Vector2(cos(ang) * estiramiento.x, sin(ang) * estiramiento.y) * r)
		return pts

	static func halftone(c: CanvasItem, rect: Rect2, paso: float, radio: float, color: Color) -> void:
		var cols := int(rect.size.x / paso)
		var filas := int(rect.size.y / paso)
		for f in range(filas + 1):
			var off_x := (paso * 0.5) if (f % 2 == 1) else 0.0
			var y := rect.position.y + float(f) * paso
			for col in range(cols + 1):
				var x := rect.position.x + off_x + float(col) * paso
				if rect.has_point(Vector2(x, y)):
					c.draw_circle(Vector2(x, y), radio, color, true, -1.0, true)

	static func rayos(c: CanvasItem, centro: Vector2, r_max: float, cantidad: int, ancho_rad: float, rot_base: float, color: Color) -> void:
		for i in range(cantidad):
			var a := rot_base + TAU * float(i) / float(cantidad)
			var pts := PackedVector2Array([
				centro,
				centro + Vector2(cos(a - ancho_rad), sin(a - ancho_rad)) * r_max,
				centro + Vector2(cos(a + ancho_rad), sin(a + ancho_rad)) * r_max,
			])
			c.draw_colored_polygon(pts, color)

	static func destello(c: CanvasItem, centro: Vector2, r: float, color: Color) -> void:
		c.draw_colored_polygon(estrella(centro, 4, r, r * 0.28, 0.0), color)


# ---------------------------------------------------------------- papel base + fondo página cómic

class FondoPapelBase extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var tam := size
		draw_rect(Rect2(Vector2.ZERO, tam), PAPEL)
		draw_rect(Rect2(0, 0, tam.x, 108), PAPEL_BORDE)
		draw_rect(Rect2(0, tam.y - 148, tam.x, 148), PAPEL_BORDE)
		ArteComic.halftone(self, Rect2(14, 12, tam.x - 28, 68), 18.0, 2.2, Color(0.75, 0.65, 0.48, 0.22))
		ArteComic.halftone(self, Rect2(14, tam.y - 134, tam.x - 28, 118), 18.0, 2.2, Color(0.75, 0.65, 0.48, 0.20))


class FondoComic extends Control:
	var _rects: Array[Rect2] = []

	func _init(rects: Array[Rect2]) -> void:
		_rects = rects
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Marco de página impresa dentro de la cámara
		var marco_ext := ArteComic.rect_redondeado(Rect2(10, 80, ANCHO_PAGINA - 20, ALTO_PAGINA - 102), 14.0)
		marco_ext.append(marco_ext[0])
		draw_polyline(marco_ext, Color(0.15, 0.14, 0.12, 0.14), 2.0, true)

		# Siluetas suaves de las viñetas por revelar
		for r in _rects:
			var pts := ArteComic.rect_redondeado(r, 12.0)
			draw_colored_polygon(pts, Color(0.95, 0.90, 0.79, 0.65))
			pts.append(pts[0])
			draw_polyline(pts, PAPEL_LINEA, 2.0, true)


# ---------------------------------------------------------------- micro-efectos vivos sobre el arte PNG

class EfectosVineta extends Control:
	var _tipo: int = 1
	var _t: float = 0.0
	var intensidad: float = 0.0

	func _init(tipo: int) -> void:
		_tipo = tipo
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if intensidad <= 0.01:
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if intensidad <= 0.01:
			return
		var a := intensidad
		match _tipo:
			1:
				# Confeti sutil cayendo y destello cálido junto a la vela 18
				var col_conf := [Color("#ef4444"), Color("#fde047"), Color("#22c55e"), Color("#38bdf8")]
				for i in range(8):
					var x := 16.0 + float((i * 43) % 296) + sin(_t * 2.3 + float(i)) * 6.0
					var y := fmod(30.0 + float(i * 37) + _t * 32.0, size.y)
					var ang := _t * 3.0 + float(i)
					var dx := cos(ang) * 4.2
					var dy := sin(ang) * 2.2
					var c := Color(col_conf[i % col_conf.size()], 0.78 * a)
					draw_colored_polygon(PackedVector2Array([
						Vector2(x - dx, y - dy), Vector2(x + dy, y - dx),
						Vector2(x + dx, y + dy), Vector2(x - dy, y + dx),
					]), c)
				var pulso := 16.0 + sin(_t * 7.5) * 4.0
				draw_circle(Vector2(226, 174), pulso, Color(1.0, 0.95, 0.65, 0.16 * a), true, -1.0, true)
			2:
				# Destellos dorados parpadeantes alrededor del regalo sorpresa
				var puntos := [Vector2(216, 146), Vector2(288, 152), Vector2(304, 210), Vector2(188, 224)]
				for i in range(puntos.size()):
					var r := 4.0 + (sin(_t * 5.2 + float(i) * 1.6) * 0.5 + 0.5) * 4.5
					ArteComic.destello(self, puntos[i], r, Color(AMARILLO_COMIC, 0.85 * a))
			3:
				# Pequeñas chispas de sorpresa junto a la caja abierta
				var p3 := [Vector2(184, 54), Vector2(314, 110), Vector2(46, 184)]
				for i in range(p3.size()):
					var r := 3.5 + (sin(_t * 6.4 + float(i) * 2.1) * 0.5 + 0.5) * 3.5
					ArteComic.destello(self, p3[i], r, Color(Color.WHITE, 0.72 * a))
			4:
				# Líneas de velocidad sutiles reforzando el impulso de la patada
				for i in range(4):
					var y := 70.0 + float(i) * 58.0
					var x0 := fmod(float(i * 61) + _t * 150.0, size.x)
					draw_line(Vector2(x0, y), Vector2(x0 + 46.0, y - 8.0), Color(1.0, 1.0, 1.0, 0.28 * a), 2.5, true)
			5:
				# Destellos alegres flotando cerca de las risas
				var p5 := [Vector2(174, 72), Vector2(296, 86), Vector2(64, 108)]
				for i in range(p5.size()):
					var r := 3.5 + (sin(_t * 4.8 + float(i) * 1.9) * 0.5 + 0.5) * 3.5
					ArteComic.destello(self, p5[i], r, Color(AMARILLO_COMIC, 0.75 * a))


# ---------------------------------------------------------------- bocadillo cómic con cola

class BocadilloComic extends Control:
	var _punta_global: Vector2
	var _lbl: Label

	func _init(texto: String, pos: Vector2, punta_objetivo: Vector2, tam_fuente: int = 13) -> void:
		position = pos
		_punta_global = punta_objetivo
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		var pad_x := 13.0
		var pad_y := 8.0
		var tam_texto := FUENTE_TEXTO_COMIC.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_fuente)
		size = Vector2(ceilf(tam_texto.x) + pad_x * 2.0, ceilf(tam_texto.y) + pad_y * 2.0)
		pivot_offset = _clamp_punta_local()

		_lbl = Label.new()
		_lbl.set_meta("_tema_aplicado", true)
		_lbl.text = texto
		_lbl.add_theme_font_override("font", FUENTE_TEXTO_COMIC)
		_lbl.add_theme_font_size_override("font_size", tam_fuente)
		_lbl.add_theme_color_override("font_color", TINTA)
		_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_lbl)

		modulate.a = 0.0
		scale = Vector2(0.4, 0.4)

	func _clamp_punta_local() -> Vector2:
		var local := _punta_global - position
		return Vector2(clampf(local.x, -40.0, size.x + 40.0), clampf(local.y, -48.0, size.y + 48.0))

	func revelar(retardo: float) -> void:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "modulate:a", 1.0, 0.14).set_delay(retardo)
		tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_delay(retardo) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var radio := 13.0
		var centro := size * 0.5
		var punta := _punta_global - position

		var dir := (punta - centro).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var base_centro := centro + Vector2(
			clampf(dir.x * (size.x * 0.34), -size.x * 0.32, size.x * 0.32),
			clampf(dir.y * (size.y * 0.36), -size.y * 0.30, size.y * 0.30)
		)
		var base_a := base_centro + perp * 8.5
		var base_b := base_centro - perp * 8.5
		var cola := PackedVector2Array([base_a, punta, base_b])

		# 1) Sombra dura de cuerpo y cola
		var off := Vector2(3, 4)
		var cuerpo_som := ArteComic.rect_redondeado(Rect2(rect.position + off, rect.size), radio)
		var cola_som := PackedVector2Array([base_a + off, punta + off, base_b + off])
		draw_colored_polygon(cuerpo_som, TINTA)
		draw_colored_polygon(cola_som, TINTA)

		# 2) Silueta de tinta exterior unificada (cuerpo + cola sin línea interior)
		var grosor := 3.0
		var cuerpo_ext := ArteComic.rect_redondeado(rect.grow(grosor), radio + grosor)
		var cola_ext := PackedVector2Array([
			base_a + perp * grosor,
			punta + dir * (grosor * 1.4),
			base_b - perp * grosor,
		])
		draw_colored_polygon(cuerpo_ext, TINTA)
		draw_colored_polygon(cola_ext, TINTA)

		# 3) Relleno blanco limpio sobre cuerpo y cola
		var cuerpo_int := ArteComic.rect_redondeado(rect, radio)
		draw_colored_polygon(cuerpo_int, Color.WHITE)
		draw_colored_polygon(cola, Color.WHITE)


# ---------------------------------------------------------------- estallido SFX (¡ZAS!)

class EstallidoSFX extends Control:
	var _lbl: Label

	func _init(texto: String, pos: Vector2, tam: Vector2, rot_grados: float) -> void:
		position = pos
		size = tam
		pivot_offset = tam * 0.5
		rotation = deg_to_rad(rot_grados)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		_lbl = Label.new()
		_lbl.set_meta("_tema_aplicado", true)
		_lbl.text = texto
		_lbl.add_theme_font_override("font", FUENTE_SFX)
		_lbl.add_theme_font_size_override("font_size", 29)
		_lbl.add_theme_color_override("font_color", AMARILLO_COMIC)
		_lbl.add_theme_constant_override("outline_size", 6)
		_lbl.add_theme_color_override("font_outline_color", TINTA)
		_lbl.add_theme_color_override("font_shadow_color", TINTA)
		_lbl.add_theme_constant_override("shadow_offset_x", 2)
		_lbl.add_theme_constant_override("shadow_offset_y", 3)
		_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_lbl)

		modulate.a = 0.0
		scale = Vector2(2.0, 2.0)

	func revelar(retardo: float) -> void:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "modulate:a", 1.0, 0.09).set_delay(retardo)
		tw.tween_property(self, "scale", Vector2.ONE, 0.24).set_delay(retardo) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _draw() -> void:
		var centro := size * 0.5
		var ext := ArteComic.estrella(centro, 10, size.x * 0.49, size.x * 0.34, 0.15, Vector2(1.0, size.y / size.x))
		ArteComic.poligono_ink(self, ext, Estilos_UI.ROJO_BIT, TINTA, 3.2, Vector2(3, 4))
		var inn := ArteComic.estrella(centro, 10, size.x * 0.38, size.x * 0.26, 0.15, Vector2(1.0, size.y / size.x))
		draw_colored_polygon(inn, Color("#ef4444"))


# ---------------------------------------------------------------- detalles visuales banner final

class FondoBannerComic extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size
		var raya := Color(1.0, 1.0, 1.0, 0.08)
		for i in range(-2, 10):
			var x := float(i) * 92.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, s.y),
				Vector2(x + 36.0, s.y),
				Vector2(x + 116.0, 0.0),
				Vector2(x + 80.0, 0.0),
			]), raya)


class MonedaComic extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		draw_circle(c + Vector2(3, 4), r, TINTA, true, -1.0, true)
		draw_circle(c, r, AMARILLO_COMIC, true, -1.0, true)
		draw_arc(c, r, 0.0, TAU, 32, TINTA, 3.2, true)
		draw_arc(c, r * 0.78, 0.0, TAU, 28, AMARILLO_OSCURO, 2.2, true)
		draw_arc(c, r * 0.66, PI * 1.15, PI * 1.65, 12, Color("#fef9c3"), 3.0, true)
		var txt := "1K€"
		var f_size := 20
		var ts := FUENTE_TITULO_COMIC.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size)
		draw_string(FUENTE_TITULO_COMIC, c + Vector2(-ts.x * 0.5, ts.y * 0.26), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, TINTA)


# ---------------------------------------------------------------- transiciones de apertura y remate

class AperturaWipe extends Control:
	var progreso: float = 0.0:
		set(val):
			progreso = val
			queue_redraw()
	var _origen: Vector2
	var _max_r: float

	func _init(orig: Vector2, tam: Vector2) -> void:
		_origen = orig
		_max_r = tam.length() * 1.15
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if progreso >= 1.0:
			return
		var r := lerpf(16.0, _max_r, progreso)
		var alpha := clampf(1.0 - progreso * 1.1, 0.0, 1.0)
		draw_arc(_origen, r, 0.0, TAU, 48, Color(Estilos_UI.ROJO_BIT, alpha), 36.0 * (1.0 - progreso * 0.7), true)
		draw_arc(_origen, r * 0.85, 0.0, TAU, 48, Color(AMARILLO_COMIC, alpha * 0.8), 10.0, true)


class RemateFinalOverlay extends Control:
	var progreso: float = 0.0:
		set(val):
			progreso = val
			queue_redraw()
	var _origen: Vector2
	var _tam: Vector2
	var _t: float = 0.0

	func _init(orig: Vector2, tam: Vector2) -> void:
		_origen = orig
		_tam = tam
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if visible:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		if progreso <= 0.0:
			return
		var max_r := _tam.length() * 1.15
		var r := max_r * progreso
		draw_circle(_origen, r + 14.0, TINTA, true, -1.0, true)
		draw_circle(_origen, r + 8.0, AMARILLO_COMIC, true, -1.0, true)
		draw_circle(_origen, r, Estilos_UI.ROJO_BIT, true, -1.0, true)
		if progreso > 0.45:
			var centro := _tam * 0.5
			var fade := clampf((progreso - 0.45) / 0.55, 0.0, 1.0)
			ArteComic.rayos(self, centro, max_r, 14, 0.09, _t * 0.25, Color(1.0, 1.0, 1.0, 0.08 * fade))


class CajaRegaloFrente extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Interior oscuro de la caja abierta (en perspectiva estilo Viñeta 3)
		var interior := PackedVector2Array([
			Vector2(14, 24), Vector2(108, 12), Vector2(198, 28), Vector2(106, 46),
		])
		ArteComic.poligono_ink(self, interior, Color("#7f1d1d"), TINTA, 3.0)

		# Cara izquierda roja
		var cara_izq := PackedVector2Array([
			Vector2(14, 24), Vector2(106, 46), Vector2(106, 118), Vector2(18, 118),
		])
		ArteComic.poligono_ink(self, cara_izq, Color("#dc2626"), TINTA, 3.2)

		# Cara derecha roja sombreada
		var cara_der := PackedVector2Array([
			Vector2(106, 46), Vector2(198, 28), Vector2(192, 118), Vector2(106, 118),
		])
		ArteComic.poligono_ink(self, cara_der, Color("#b91c1c"), TINTA, 3.2)

		# Cintas doradas verticales en ambas caras
		var cinta_izq := PackedVector2Array([
			Vector2(50, 33), Vector2(70, 38), Vector2(72, 118), Vector2(52, 118),
		])
		ArteComic.poligono_ink(self, cinta_izq, AMARILLO_COMIC, TINTA, 2.4)

		var cinta_der := PackedVector2Array([
			Vector2(142, 39), Vector2(162, 35), Vector2(158, 118), Vector2(138, 118),
		])
		ArteComic.poligono_ink(self, cinta_der, AMARILLO_OSCURO, TINTA, 2.4)
