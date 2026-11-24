class_name Escenario_Actividad
extends PanelContainer
## Mini-escenario animado en tiempo real que muestra al personaje personalizado
## realizando su actividad actual (correr, dormir, comer, ducharse, estudiar, etc.)
## con bucles cortos y micro-acciones espontáneas cada pocos segundos para darle vida.
## La escenografía de todas las poses (salvo el salón de "idle") se dibuja en
## Escenografia_Inicio: degradados, ventanas con hora real, muebles, props y
## partículas. Este archivo conserva el salón de referencia, la mesa de comer y
## el mostrador de tiempo libre, además del bucle y el catálogo de variaciones.

const TINTA := Color("#111827")
const FUENTE_COMIC := preload("res://Fuentes/UI/Bricolage-800.ttf")

const DURACION_CICLO_COMER := 3.4

# Catálogo de micro-acciones espontáneas por pose:
# [id_variacion, etiqueta_pill, expresion, prop_mano, duracion_segundos]
const VARIACIONES: Dictionary = {
	"correr": [
		["sprint", "¡Sprint a tope!", "concentrado", "ninguno", 2.6],
		["secar_sudor", "Secándose el sudor", "feliz", "ninguno", 2.4],
		["beber_agua", "Bebiendo agua", "feliz_cerrado", "botella", 2.5],
		["salto", "¡Saltando un charco!", "feliz", "ninguno", 1.8],
		["senalar", "¡Mirad eso!", "feliz", "ninguno", 2.0],
	],
	"dormir": [
		["roncar", "Roncando fuerte...", "roncando", "ninguno", 2.8],
		["darse_vuelta", "Dándose la vuelta", "dormido", "ninguno", 2.2],
		["sonar", "Soñando...", "dormido", "ninguno", 3.2],
		["estirar_brazo", "Estirándose", "dormido", "ninguno", 2.4],
		["abrazar_almohada", "Abrazando la almohada", "dormido", "ninguno", 2.6],
	],
	"comer": [
		["beber", "Tomando un sorbo", "satisfecho", "vaso", 2.8],
		["delicioso", "¡Qué rico está!", "feliz_cerrado", "ninguno", 2.6],
		["soplar", "Soplando (¡quema!)", "soplando", "tenedor", 2.8],
		["limpiar_boca", "Limpiándose", "sonrisa", "ninguno", 2.4],
		["oler", "¡Qué bien huele!", "satisfecho", "ninguno", 2.5],
	],
	"duchar": [
		["cantar", "Cantando en la ducha", "cantando", "esponja", 3.0],
		["espuma_pelo", "Mucha espuma", "feliz_cerrado", "ninguno", 2.8],
		["agua_fria", "¡Uy, agua fría!", "asustado_frio", "ninguno", 2.0],
		["burbuja_gigante", "Pompa gigante", "feliz", "esponja", 2.8],
	],
	"estudiar": [
		["bombilla", "¡Buena idea!", "feliz", "lapiz", 2.6],
		["pasar_pagina", "Pasando página", "concentrado", "ninguno", 1.9],
		["pensar", "Pensando...", "neutral", "lapiz", 2.7],
		["bostezo", "Un poco de sueño...", "bostezo", "ninguno", 2.2],
		["subrayar", "Subrayando ideas", "concentrado", "lapiz", 2.4],
	],
	"tv": [
		["reir", "¡Partiéndose de risa!", "reir", "ninguno", 2.6],
		["palomitas", "Comiendo palomitas", "masticando", "ninguno", 2.6],
		["cambiar_canal", "Cambiando de canal", "concentrado", "mando", 2.0],
		["sorpresa_tv", "¡Giro de guion!", "sorpresa", "ninguno", 2.3],
		["bostezo_tv", "Vaya bostezo...", "bostezo", "ninguno", 2.2],
	],
	"manualidades": [
		["pincelada_rapida", "¡A toda velocidad!", "feliz", "pincel", 2.5],
		["admirar", "Admirando su obra", "sonrisa", "ninguno", 2.6],
		["soplar_pintura", "Soplando la pintura", "soplando", "pincel", 2.3],
	],
	"cocinar": [
		["saltear", "¡Salteando con estilo!", "feliz", "espatula", 2.5],
		["probar", "Probando el punto", "satisfecho", "espatula", 2.4],
		["oler_guiso", "Huele de maravilla", "satisfecho", "espatula", 2.4],
	],
	"fiesta": [
		["bailar", "¡Dándolo todo!", "feliz", "ninguno", 2.6],
		["brindar", "¡A disfrutar!", "feliz_cerrado", "vaso", 2.6],
		["saltar", "¡Saltando!", "feliz", "ninguno", 2.2],
	],
	"futbol": [
		["toques", "¡Haciendo toques!", "concentrado", "ninguno", 2.5],
		["celebrar_gol", "¡Golazo!", "feliz", "ninguno", 2.4],
		["regate", "¡Regate!", "concentrado", "ninguno", 2.2],
	],
	"trabajar": [
		["cafe", "Pausa para café", "feliz_cerrado", "taza", 2.6],
		["mirar_reloj", "Mirando la hora...", "neutral", "ninguno", 2.2],
		["ganar_dinero", "¡Productivo!", "feliz", "ninguno", 2.4],
		["estirar_cuello", "Estirando el cuello", "cansado", "ninguno", 2.4],
	],
	"idle": [
		["saludar", "¡Hola!", "feliz", "ninguno", 2.4],
		["mirar_movil", "Mirando el móvil", "sonrisa", "movil", 3.0],
		["estirarse", "Estirándose", "feliz_cerrado", "ninguno", 2.3],
		["silbar", "Silbando...", "soplando", "ninguno", 2.5],
		["flexionar", "¡A tope de energía!", "feliz", "ninguno", 2.4],
		["tomar_notas", "Apuntando ideas", "concentrado", "lapiz", 2.6],
	],
}

var _pose_actual: String = "idle"
var _personalidad: String = ""
var _en_la_calle: bool = false
var _apariencia: Dictionary = Apariencia_Personaje.por_defecto()
var _minuto_dia: int = 780
var _objeto_comer: String = "Mesa_Basica"
var _plato_actual: String = "almuerzo" # "desayuno", "almuerzo", "cena", "calle"
var _tiempo_ciclo_comer: float = 0.0
var _bocados_dados: int = 0
var _bocado_contado_en_ciclo: bool = false

var _t: float = 0.0
var _espera_siguiente: float = 3.2
var _variacion_activa: String = ""
var _tiempo_variacion: float = 0.0
var _duracion_variacion: float = 2.5
var _ultima_variacion: String = ""
var _color_canal_tv: Color = Color("#38bdf8")
var _icono_sueno: int = 0

var _rng := RandomNumberGenerator.new()

var _escena_clip: Control
var _capa_fondo: _CapaFondoActividad
var _personaje: Personaje_Visual
var _capa_mostrador: _CapaMostradorIdle
var _capa_mesa: _CapaMesaComer
var _personaje_brazos: Personaje_Visual
var _capa_frente: _CapaFrenteActividad
var _pill_accion: PanelContainer
var _lbl_accion: Label
var _tween_pill: Tween
var _tween_escena: Tween


func _init() -> void:
	_rng.randomize()
	custom_minimum_size = Vector2(0, 184)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Toca para ver otra acción"


func _ready() -> void:
	_construir()
	set_process(true)


func _construir() -> void:
	# PanelContainer actúa como marco exterior; el recorte se hace con clip_contents = true
	# (evita anidar CLIP_CHILDREN_AND_DRAW dentro de Card_Estado, que rompe el stencil en Mobile).
	var st_marco := StyleBoxFlat.new()
	st_marco.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	st_marco.border_color = Color("#cbd5e1")
	st_marco.set_border_width_all(2)
	st_marco.set_corner_radius_all(12)
	st_marco.content_margin_left = 2
	st_marco.content_margin_right = 2
	st_marco.content_margin_top = 2
	st_marco.content_margin_bottom = 2
	st_marco.anti_aliasing = true
	add_theme_stylebox_override("panel", st_marco)

	_escena_clip = Control.new()
	_escena_clip.name = "EscenaClip"
	_escena_clip.clip_contents = true
	_escena_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_escena_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_escena_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_escena_clip)

	_capa_fondo = _CapaFondoActividad.new(self)
	_capa_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escena_clip.add_child(_capa_fondo)

	_personaje = Personaje_Visual.new(_apariencia, "busto")
	_personaje.animar_idle = true
	_escena_clip.add_child(_personaje)

	# Mostrador de la zona de tiempo libre: tapa la parte baja del Sim, que queda
	# de pie detrás de la barra sin necesidad de dibujar piernas ni manos.
	_capa_mostrador = _CapaMostradorIdle.new(self)
	_capa_mostrador.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_mostrador.visible = false
	_escena_clip.add_child(_capa_mostrador)

	# Capas exclusivas de "comer": la mesa/plato queda delante del torso pero detrás de brazos y cubiertos
	_capa_mesa = _CapaMesaComer.new(self)
	_capa_mesa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_mesa.visible = false
	_escena_clip.add_child(_capa_mesa)

	_personaje_brazos = Personaje_Visual.new(_apariencia, "busto")
	_personaje_brazos.animar_idle = false
	_personaje_brazos.modo_capa = "solo_brazos_delanteros"
	_personaje_brazos.fuente_overlay = _personaje
	_personaje_brazos.visible = false
	_escena_clip.add_child(_personaje_brazos)

	_capa_frente = _CapaFrenteActividad.new(self)
	_capa_frente.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escena_clip.add_child(_capa_frente)

	# Pill sutil inferior izquierda que indica la micro-acción espontánea actual
	_pill_accion = PanelContainer.new()
	_pill_accion.set_meta("_tema_aplicado", true)
	_pill_accion.position = Vector2(10, 144)
	_pill_accion.modulate.a = 0.0
	_pill_accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_p := StyleBoxFlat.new()
	st_p.bg_color = Color(0.08, 0.11, 0.18, 0.80)
	st_p.set_corner_radius_all(999)
	st_p.content_margin_left = 11
	st_p.content_margin_right = 11
	st_p.content_margin_top = 4
	st_p.content_margin_bottom = 4
	st_p.anti_aliasing = true
	_pill_accion.add_theme_stylebox_override("panel", st_p)
	_escena_clip.add_child(_pill_accion)

	_lbl_accion = Estilos_UI.texto("", 11, Color.WHITE, 700)
	_lbl_accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill_accion.add_child(_lbl_accion)

	_aplicar_layout_personaje()


func actualizar_estado(nombre_actividad: String, esta_en_calle: bool, apariencia_actual: Dictionary, minuto_del_dia: int = -1, objeto_comer: String = "", personalidad: String = "") -> void:
	# Override de QA: Debug_Pose_Inicio permite fijar una pose sin programar la
	# actividad. Con POSE_FORZADA = "0" esto no hace nada.
	var actividad_forzada := Debug_Pose_Inicio.actividad_forzada()
	if actividad_forzada != "":
		nombre_actividad = actividad_forzada
		var calle_forzada := Debug_Pose_Inicio.calle_forzada()
		if calle_forzada >= 0:
			esta_en_calle = (calle_forzada == 1)

	var nueva_pose := Apariencia_Personaje.pose_para_actividad(nombre_actividad)
	var ap_norm := Apariencia_Personaje.normalizar(apariencia_actual)
	var calle_anterior: bool = _en_la_calle
	_en_la_calle = esta_en_calle
	if personalidad != "":
		_personalidad = personalidad
	elif str(ap_norm.get("personalidad", "")) != "":
		_personalidad = str(ap_norm.get("personalidad", ""))
	if minuto_del_dia >= 0:
		_minuto_dia = minuto_del_dia % 1440
	if objeto_comer != "":
		_objeto_comer = objeto_comer

	if _apariencia != ap_norm:
		_apariencia = ap_norm
		if _personaje != null:
			_personaje.apariencia = _apariencia

	_sincronizar_estilo_comida()

	if nueva_pose != _pose_actual:
		_pose_actual = nueva_pose
		_variacion_activa = ""
		_ultima_variacion = ""
		_tiempo_ciclo_comer = 0.0
		_bocados_dados = 0
		_bocado_contado_en_ciclo = false
		_espera_siguiente = _rng.randf_range(2.6, 4.4)
		_ocultar_pill()
		_restaurar_base_personaje()
		_aplicar_layout_personaje()
		_fundir_escena()
	elif calle_anterior != _en_la_calle:
		# La vivienda cambia el encuadre del tiempo libre (mostrador o calle),
		# aunque la actividad siga siendo la misma.
		_aplicar_layout_personaje()
		_fundir_escena()


func _sincronizar_estilo_comida() -> void:
	if _en_la_calle:
		_plato_actual = "calle"
	else:
		var hora := int(_minuto_dia / 60.0)
		if hora >= 5 and hora < 12:
			_plato_actual = "desayuno"
		elif hora >= 12 and hora < 18:
			_plato_actual = "almuerzo"
		else:
			_plato_actual = "cena"

	if _personaje == null:
		return

	if _en_la_calle:
		_personaje.estilo_vaso = "carton"
		_personaje.estilo_tenedor = "plastico"
		_personaje.color_bocado = Color("#f59e0b")
		_personaje.color_bebida = Color("#d97706")
	else:
		_personaje.estilo_vaso = "copa" if _objeto_comer == "Mesa_Premium" else "normal"
		_personaje.estilo_tenedor = "metal"
		match _plato_actual:
			"desayuno":
				_personaje.color_bocado = Color("#eab308")
				_personaje.color_bebida = Color("#fb923c")
			"almuerzo":
				_personaje.color_bocado = Color("#dc2626")
				_personaje.color_bebida = Color("#fde047")
			_:
				_personaje.color_bocado = Color("#92400e")
				_personaje.color_bebida = Color("#9f1239") if _objeto_comer == "Mesa_Premium" else Color("#38bdf8")


func _es_mesa_premium() -> bool:
	return (not _en_la_calle) and _objeto_comer == "Mesa_Premium"


func _franja_horaria() -> String:
	var hora := int(_minuto_dia / 60.0)
	if hora >= 6 and hora < 12:
		return "manana"
	if hora >= 12 and hora < 18:
		return "tarde"
	if hora >= 18 and hora < 21:
		return "atardecer"
	return "noche"


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		_disparar_variacion_aleatoria()
		accept_event()


func _process(delta: float) -> void:
	if not visible or _personaje == null:
		return
	_t += delta

	if _variacion_activa != "":
		_tiempo_variacion += delta
		var fase: float = clampf(_tiempo_variacion / maxf(0.1, _duracion_variacion), 0.0, 1.0)
		_personaje.fase_variacion = fase
		if _pose_actual == "comer":
			_personaje.mancha_salsa = (_variacion_activa == "limpiar_boca" and fase < 0.54)
		if _tiempo_variacion >= _duracion_variacion:
			_variacion_activa = ""
			_espera_siguiente = _rng.randf_range(3.6, 6.0)
			if _pose_actual == "comer":
				_tiempo_ciclo_comer = 0.0
				_bocado_contado_en_ciclo = false
				_personaje.ciclo_comer = 0.0
				_personaje.mancha_salsa = false
			_restaurar_base_personaje()
			_ocultar_pill()
	else:
		_espera_siguiente -= delta
		if _pose_actual == "comer":
			_tiempo_ciclo_comer += delta
			if _tiempo_ciclo_comer >= DURACION_CICLO_COMER:
				_tiempo_ciclo_comer = fmod(_tiempo_ciclo_comer, DURACION_CICLO_COMER)
				_bocado_contado_en_ciclo = false
			var c: float = clampf(_tiempo_ciclo_comer / DURACION_CICLO_COMER, 0.0, 1.0)
			_personaje.ciclo_comer = c
			if c >= 0.46 and not _bocado_contado_en_ciclo:
				_bocado_contado_en_ciclo = true
				_bocados_dados = (_bocados_dados + 1) % 4
			# Esperar al final natural de un bocado antes de disparar una micro-acción automática
			if _espera_siguiente <= 0.0 and (c >= 0.92 or c <= 0.06):
				_disparar_variacion_aleatoria()
		elif _espera_siguiente <= 0.0:
			_disparar_variacion_aleatoria()

	if _capa_fondo != null:
		_capa_fondo.queue_redraw()
	if _capa_mostrador != null and _capa_mostrador.visible:
		_capa_mostrador.queue_redraw()
	if _capa_mesa != null and _capa_mesa.visible:
		_capa_mesa.queue_redraw()
	if _personaje_brazos != null and _personaje_brazos.visible:
		_personaje_brazos.queue_redraw()
	if _capa_frente != null:
		_capa_frente.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_aplicar_layout_personaje()


func _aplicar_layout_personaje() -> void:
	if _personaje == null:
		return
	var w: float = maxf(320.0, size.x - 4.0)
	var h: float = maxf(160.0, size.y - 4.0)
	var es_comer := (_pose_actual == "comer")
	match _pose_actual:
		"correr", "futbol", "fiesta":
			_personaje.modo = "cuerpo_completo"
			_personaje.position = Vector2(w * 0.5 - 76.0, 4.0)
			_personaje.size = Vector2(152.0, h - 10.0)
		"idle":
			if _en_la_calle:
				_personaje.modo = "cuerpo_completo"
				_personaje.position = Vector2(w * 0.5 - 72.0, 6.0)
				_personaje.size = Vector2(144.0, h - 8.0)
			else:
				# En casa el Sim queda de pie detrás de la encimera: encuadre de
				# busto para que cabeza y torso asomen por encima de la barra.
				_personaje.modo = "busto"
				var alto_pj: float = h * 0.80
				var ancho_pj: float = alto_pj * (144.0 / 196.0)
				_personaje.position = Vector2(w * 0.5 - ancho_pj * 0.5, h * 0.72 - alto_pj + 4.0)
				_personaje.size = Vector2(ancho_pj, alto_pj)
		"dormir":
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, 10.0)
			_personaje.size = Vector2(164.0, h + 10.0)
		"comer":
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, 0.0)
			_personaje.size = Vector2(164.0, h + 14.0)
		"cocinar":
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, -2.0)
			_personaje.size = Vector2(164.0, h + 12.0)
		"duchar":
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, 4.0)
			_personaje.size = Vector2(164.0, h + 12.0)
		_:
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, 4.0)
			_personaje.size = Vector2(164.0, h + 12.0)

	var brazos_sobre_frente := (_pose_actual in ["estudiar", "cocinar"])
	var usar_overlay_brazos := es_comer or brazos_sobre_frente
	_personaje.modo_capa = "sin_brazos_delanteros" if usar_overlay_brazos else "completo"
	var es_tiempo_libre := (_pose_actual == "idle" and not _en_la_calle)
	if _capa_mostrador != null:
		_capa_mostrador.visible = es_tiempo_libre
	if _capa_mesa != null:
		_capa_mesa.visible = es_comer
	if _personaje_brazos != null:
		_personaje_brazos.visible = usar_overlay_brazos
		_personaje_brazos.position = _personaje.position
		_personaje_brazos.size = _personaje.size
		if _escena_clip != null and _capa_frente != null:
			if brazos_sobre_frente and _personaje_brazos.get_index() < _capa_frente.get_index():
				_escena_clip.move_child(_personaje_brazos, _capa_frente.get_index())
			elif not brazos_sobre_frente and _personaje_brazos.get_index() > _capa_frente.get_index():
				_escena_clip.move_child(_personaje_brazos, _capa_frente.get_index())
	if _pill_accion != null:
		_pill_accion.position = Vector2(10.0, maxf(8.0, h - 32.0))


func _fundir_escena() -> void:
	if _escena_clip == null:
		return
	if _tween_escena != null and _tween_escena.is_valid():
		_tween_escena.kill()
	_escena_clip.modulate.a = 0.45
	_tween_escena = create_tween()
	_tween_escena.tween_property(_escena_clip, "modulate:a", 1.0, 0.28)		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _restaurar_base_personaje() -> void:
	if _personaje == null:
		return
	_personaje.pose = _pose_actual
	_personaje.variacion = ""
	_personaje.fase_variacion = 0.0
	_personaje.en_ducha = (_pose_actual == "duchar")
	_personaje.prop_mano = "ninguno"
	_personaje.prop_mano_izq = "ninguno"
	_personaje.mancha_salsa = false
	match _pose_actual:
		"correr":
			_personaje.expresion = "concentrado"
		"dormir":
			_personaje.expresion = "dormido"
		"comer":
			_personaje.expresion = "masticando"
			_personaje.prop_mano = "tenedor"
			_personaje.prop_mano_izq = "cuchillo" if not _en_la_calle else "ninguno"
			_personaje.ciclo_comer = clampf(_tiempo_ciclo_comer / DURACION_CICLO_COMER, 0.0, 1.0)
		"duchar":
			_personaje.expresion = "feliz"
			_personaje.prop_mano = "esponja"
		"estudiar":
			_personaje.expresion = "concentrado"
			_personaje.prop_mano = "lapiz"
		"tv":
			_personaje.expresion = "sonrisa"
		"manualidades":
			_personaje.expresion = "concentrado"
			_personaje.prop_mano = "pincel"
		"cocinar":
			_personaje.expresion = "feliz"
			_personaje.prop_mano = "espatula"
		"fiesta":
			_personaje.expresion = "feliz"
		"futbol":
			_personaje.expresion = "concentrado"
		"trabajar":
			_personaje.expresion = "concentrado"
		_:
			_personaje.expresion = "feliz"


func _disparar_variacion_aleatoria() -> void:
	if _personaje == null or not VARIACIONES.has(_pose_actual):
		return
	var lista: Array = VARIACIONES[_pose_actual]
	if lista.is_empty():
		return

	var candidatas: Array = []
	for v: Array in lista:
		var vid: String = v[0]
		if _pose_actual == "idle":
			if vid == "flexionar" and _personalidad != "Deportista":
				continue
			if vid == "tomar_notas" and _personalidad != "Trabajador_Compulsivo":
				continue
		if vid != _ultima_variacion or lista.size() == 1:
			candidatas.append(v)
	if candidatas.is_empty():
		candidatas = lista.duplicate()

	var elegida: Array = candidatas[_rng.randi_range(0, candidatas.size() - 1)]
	_variacion_activa = str(elegida[0])
	_ultima_variacion = _variacion_activa
	_tiempo_variacion = 0.0
	_duracion_variacion = float(elegida[4])

	_personaje.pose = _pose_actual
	_personaje.variacion = _variacion_activa
	_personaje.fase_variacion = 0.0
	_personaje.expresion = str(elegida[2])
	_personaje.prop_mano = str(elegida[3])
	_personaje.prop_mano_izq = "ninguno"
	_personaje.mancha_salsa = (_variacion_activa == "limpiar_boca")

	if _variacion_activa == "cambiar_canal":
		var colores_tv := [Color("#38bdf8"), Color("#a855f7"), Color("#22c55e"), Color("#f97316"), Color("#ec4899")]
		_color_canal_tv = colores_tv[_rng.randi_range(0, colores_tv.size() - 1)]
	elif _variacion_activa == "sonar":
		_icono_sueno = _rng.randi_range(0, 2)

	_mostrar_pill(str(elegida[1]))


func _mostrar_pill(texto_pill: String) -> void:
	if _pill_accion == null or _lbl_accion == null:
		return
	_lbl_accion.text = texto_pill
	if _tween_pill != null and _tween_pill.is_valid():
		_tween_pill.kill()
	_tween_pill = create_tween()
	_tween_pill.tween_property(_pill_accion, "modulate:a", 1.0, 0.20)


func _ocultar_pill() -> void:
	if _pill_accion == null:
		return
	if _tween_pill != null and _tween_pill.is_valid():
		_tween_pill.kill()
	_tween_pill = create_tween()
	_tween_pill.tween_property(_pill_accion, "modulate:a", 0.0, 0.25)


# ---------------------------------------------------------------- capa de fondo por actividad

class _CapaFondoActividad extends Control:
	var _padre: Escenario_Actividad

	func _init(padre: Escenario_Actividad) -> void:
		_padre = padre
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if _padre == null or size.x <= 1.0 or size.y <= 1.0:
			return
		var w := size.x
		var h := size.y
		var t: float = _padre._t
		var pose: String = _padre._pose_actual

		if pose == "idle":
			_fondo_idle(w, h, t)
		else:
			Escenografia_Inicio.dibujar_fondo(self, _padre, w, h)

	func _fondo_idle(w: float, h: float, t: float) -> void:
		if _padre._en_la_calle:
			Escenografia_Inicio.dibujar_calle_idle(self, _padre, w, h)
			return

		# Salón cálido inspirado en la lámina de referencia: pared crema con
		# luz suave, ventana cuadrada a la izquierda y planta frondosa a la
		# derecha sobre una encimera de madera. Sin comida, platos ni cubertería.
		var y_encimera: float = h * 0.715
		var lado_ventana: float = clampf(h * 0.46, 58.0, 124.0)
		var ventana := Rect2(clampf(w * 0.035, 10.0, 34.0), h * 0.075, lado_ventana, lado_ventana)

		_dibujar_pared_idle(w, h, y_encimera)
		_dibujar_ventana_idle(ventana, t)
		_dibujar_haz_luz_idle(ventana, w, h)
		_dibujar_planta_idle(Vector2(w - maxf(54.0, h * 0.20), y_encimera), h, t)
		_dibujar_motas_idle(w, h, t)

	func _dibujar_pared_idle(w: float, h: float, _y_encimera: float) -> void:
		# Degradado vertical muy suave: crema claro arriba, beige cálido abajo.
		var bandas := 24
		for i in range(bandas):
			var u := float(i) / float(bandas - 1)
			var col := Color("#f9f1e3").lerp(Color("#eedcc4"), u)
			draw_rect(Rect2(0.0, h * float(i) / float(bandas), w, h / float(bandas) + 1.0), col)
		# Foco de luz central difuso.
		draw_circle(Vector2(w * 0.54, h * 0.42), h * 0.78, Color(1.0, 0.98, 0.91, 0.09), true, -1.0, true)
		draw_circle(Vector2(w * 0.54, h * 0.42), h * 0.48, Color(1.0, 0.99, 0.94, 0.12), true, -1.0, true)
		# Sombra suave justo bajo el alféizar de la ventana.
		draw_rect(Rect2(0.0, h * 0.68, w, h * 0.04), Color(0.45, 0.30, 0.14, 0.035))

	func _dibujar_ventana_idle(marco: Rect2, t: float) -> void:
		# Sombra proyectada sobre la pared.
		draw_rect(Rect2(marco.position + Vector2(5.0, 6.0), marco.size), Color(0.32, 0.22, 0.12, 0.10))
		# Marco exterior gris cálido y moldura clara.
		draw_rect(marco, Color("#c8ccd0"))
		draw_rect(marco.grow(-1.0), Color("#e6e8ea"), false, 2.0)
		var interior := marco.grow(-6.0)
		# Cielo con degradado.
		var bandas := 10
		for i in range(bandas):
			var u := float(i) / float(bandas - 1)
			draw_rect(
				Rect2(interior.position.x, interior.position.y + interior.size.y * float(i) / float(bandas),
					  interior.size.x, interior.size.y / float(bandas) + 1.0),
				Color("#9ed4f5").lerp(Color("#dcefFB"), u)
			)
		# Halo de sol.
		var sol := interior.position + Vector2(interior.size.x * 0.73, interior.size.y * 0.20)
		draw_circle(sol, interior.size.x * 0.25, Color(1.0, 0.98, 0.85, 0.22), true, -1.0, true)
		draw_circle(sol, interior.size.x * 0.13, Color(1.0, 0.99, 0.91, 0.34), true, -1.0, true)
		# Nubes suaves que se mecen lentamente dentro del cristal.
		var c1 := Vector2(
			interior.position.x + interior.size.x * (0.27 + sin(t * 0.32) * 0.045),
			interior.position.y + interior.size.y * 0.30
		)
		var c2 := Vector2(
			interior.position.x + interior.size.x * (0.66 + sin(t * 0.24 + 1.8) * 0.035),
			interior.position.y + interior.size.y * 0.62
		)
		_dibujar_nube_idle(c1, interior.size.x * 0.105, 0.86)
		_dibujar_nube_idle(c2, interior.size.x * 0.075, 0.72)
		# Cruceta del marco.
		var barra: float = maxf(3.0, marco.size.x * 0.045)
		draw_rect(Rect2(interior.position.x, marco.position.y + marco.size.y * 0.5 - barra * 0.5, marco.size.x, barra), Color("#d7dade"))
		draw_rect(Rect2(marco.position.x + marco.size.x * 0.5 - barra * 0.5, marco.position.y, barra, marco.size.y), Color("#d7dade"))
		draw_line(Vector2(interior.position.x, marco.position.y + marco.size.y * 0.5 - barra * 0.5),
			Vector2(interior.end.x, marco.position.y + marco.size.y * 0.5 - barra * 0.5), Color(1.0, 1.0, 1.0, 0.65), 1.0)
		# Bisel interior y contorno.
		draw_rect(interior, Color(1.0, 1.0, 1.0, 0.42), false, 1.4)
		draw_rect(marco, Color("#8f959a"), false, 1.2)
		# Alféizar con sombra inferior.
		var alto_alf: float = maxf(4.0, marco.size.y * 0.045)
		var alfeizar := Rect2(marco.position.x - 6.0, marco.end.y - 1.0, marco.size.x + 12.0, alto_alf)
		draw_rect(alfeizar, Color("#ded8cc"))
		draw_line(Vector2(alfeizar.position.x, alfeizar.position.y), Vector2(alfeizar.end.x, alfeizar.position.y), Color("#b7af9f"), 1.1)
		draw_rect(Rect2(alfeizar.position.x + 2.0, alfeizar.end.y, alfeizar.size.x - 4.0, 2.0), Color(0.3, 0.2, 0.1, 0.12))

	func _dibujar_nube_idle(centro: Vector2, r: float, alpha: float) -> void:
		var col := Color(1.0, 1.0, 1.0, alpha)
		draw_circle(centro + Vector2(-r * 0.9, r * 0.10), r * 0.60, col, true, -1.0, true)
		draw_circle(centro + Vector2(0.0, -r * 0.18), r * 0.86, col, true, -1.0, true)
		draw_circle(centro + Vector2(r * 0.9, r * 0.06), r * 0.64, col, true, -1.0, true)
		draw_rect(Rect2(centro.x - r * 1.2, centro.y + r * 0.06, r * 2.4, r * 0.52), col)

	func _dibujar_haz_luz_idle(ventana: Rect2, w: float, h: float) -> void:
		var y_salida := ventana.position.y + ventana.size.y * 0.52
		var haz := PackedVector2Array([
			Vector2(ventana.position.x + 7.0, y_salida),
			Vector2(ventana.end.x - 3.0, y_salida),
			Vector2(minf(w, ventana.end.x + w * 0.26), h * 0.80),
			Vector2(ventana.position.x + w * 0.02, h * 0.80),
		])
		draw_colored_polygon(haz, Color(1.0, 0.96, 0.82, 0.10))
		draw_colored_polygon(PackedVector2Array([
			Vector2(ventana.position.x + 12.0, y_salida + 4.0),
			Vector2(ventana.end.x - 10.0, y_salida + 4.0),
			Vector2(minf(w, ventana.end.x + w * 0.16), h * 0.78),
			Vector2(ventana.position.x + w * 0.07, h * 0.78),
		]), Color(1.0, 0.97, 0.86, 0.07))

	func _dibujar_planta_idle(base: Vector2, h: float, t: float) -> void:
		var alto_maceta: float = h * 0.105
		var ancho_maceta: float = h * 0.135
		var hoja_h: float = h * 1.18
		var cima_maceta := base.y - alto_maceta
		var borde_izq := base.x - ancho_maceta * 0.5
		# Sombra de contacto sobre la madera (la tapa el mostrador delantero).
		draw_circle(Vector2(base.x + 3.0, base.y + 1.0), ancho_maceta * 0.72, Color(0.18, 0.09, 0.03, 0.18), true, -1.0, true)
		# Tallos curvos.
		var tallos: Array = [
			[Vector2(base.x, cima_maceta), Vector2(base.x - hoja_h * 0.030, cima_maceta - hoja_h * 0.120), Vector2(base.x - hoja_h * 0.060, cima_maceta - hoja_h * 0.225)],
			[Vector2(base.x, cima_maceta), Vector2(base.x + hoja_h * 0.014, cima_maceta - hoja_h * 0.150), Vector2(base.x + hoja_h * 0.020, cima_maceta - hoja_h * 0.245)],
			[Vector2(base.x, cima_maceta), Vector2(base.x + hoja_h * 0.040, cima_maceta - hoja_h * 0.100), Vector2(base.x + hoja_h * 0.058, cima_maceta - hoja_h * 0.200)],
		]
		for tallo: Array in tallos:
			draw_polyline(PackedVector2Array(tallo), Color("#2f6b31"), maxf(1.4, hoja_h * 0.010), true)
		# Hojas traseras (tono más oscuro).
		_dibujar_hoja_idle(Vector2(base.x - hoja_h * 0.030, cima_maceta - hoja_h * 0.100), -1.30, hoja_h * 0.120, hoja_h * 0.070, Color("#3d853b"), Color("#2b632d"), Color("#68ad52"), t, 0.4)
		_dibujar_hoja_idle(Vector2(base.x + hoja_h * 0.035, cima_maceta - hoja_h * 0.120), 1.25, hoja_h * 0.120, hoja_h * 0.070, Color("#428b3f"), Color("#2b632d"), Color("#70b45a"), t, 1.1)
		_dibujar_hoja_idle(Vector2(base.x - hoja_h * 0.050, cima_maceta - hoja_h * 0.060), -1.55, hoja_h * 0.100, hoja_h * 0.062, Color("#367a36"), Color("#275b29"), Color("#5fa34b"), t, 2.2)
		_dibujar_hoja_idle(Vector2(base.x + hoja_h * 0.050, cima_maceta - hoja_h * 0.070), 1.52, hoja_h * 0.100, hoja_h * 0.062, Color("#3a8038"), Color("#275b29"), Color("#64a94f"), t, 2.8)
		# Hojas delanteras, más vivas y con brillo.
		_dibujar_hoja_idle(Vector2(base.x - hoja_h * 0.020, cima_maceta - hoja_h * 0.180), -0.68, hoja_h * 0.130, hoja_h * 0.076, Color("#54a447"), Color("#337636"), Color("#91cf70"), t, 0.8)
		_dibujar_hoja_idle(Vector2(base.x + hoja_h * 0.020, cima_maceta - hoja_h * 0.200), 0.62, hoja_h * 0.130, hoja_h * 0.076, Color("#5aab4c"), Color("#337636"), Color("#99d77a"), t, 1.5)
		_dibujar_hoja_idle(Vector2(base.x, cima_maceta - hoja_h * 0.245), 0.02, hoja_h * 0.140, hoja_h * 0.080, Color("#62b453"), Color("#3a7f3c"), Color("#a3de82"), t, 0.2)
		_dibujar_hoja_idle(Vector2(base.x - hoja_h * 0.045, cima_maceta - hoja_h * 0.140), -1.02, hoja_h * 0.120, hoja_h * 0.072, Color("#4b9a42"), Color("#2f7033"), Color("#86c969"), t, 1.9)
		_dibujar_hoja_idle(Vector2(base.x + hoja_h * 0.045, cima_maceta - hoja_h * 0.150), 0.98, hoja_h * 0.120, hoja_h * 0.072, Color("#4f9f45"), Color("#2f7033"), Color("#8bcd6d"), t, 2.5)
		_dibujar_hoja_idle(Vector2(base.x - hoja_h * 0.012, cima_maceta - hoja_h * 0.070), -0.32, hoja_h * 0.100, hoja_h * 0.062, Color("#59aa4b"), Color("#337636"), Color("#97d477"), t, 3.2)
		# Maceta de terracota con labio y tierra.
		var ancho_base := ancho_maceta * 0.78
		var maceta := PackedVector2Array([
			Vector2(borde_izq, cima_maceta),
			Vector2(borde_izq + ancho_maceta, cima_maceta),
			Vector2(base.x + ancho_base * 0.5, base.y),
			Vector2(base.x - ancho_base * 0.5, base.y),
		])
		draw_colored_polygon(maceta, Color("#b96a3d"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(base.x, cima_maceta),
			Vector2(borde_izq + ancho_maceta, cima_maceta),
			Vector2(base.x + ancho_base * 0.5, base.y),
			Vector2(base.x, base.y),
		]), Color("#9c4f2a"))
		var maceta_cerrada := PackedVector2Array(maceta)
		maceta_cerrada.append(maceta[0])
		draw_polyline(maceta_cerrada, Color("#743719"), 1.6, true)
		# Tierra.
		draw_rect(Rect2(base.x - ancho_maceta * 0.40, cima_maceta + 0.5, ancho_maceta * 0.80, maxf(2.0, h * 0.010)), Color("#4a2a16"))
		# Labio de la maceta.
		var labio := Rect2(borde_izq - 2.0, cima_maceta - maxf(3.0, h * 0.018), ancho_maceta + 4.0, maxf(3.0, h * 0.020))
		draw_rect(labio, Color("#c97d4d"))
		draw_rect(labio, Color("#743719"), false, 1.4)
		draw_line(Vector2(labio.position.x + 2.0, labio.position.y + 1.0), Vector2(labio.end.x - 2.0, labio.position.y + 1.0), Color(1.0, 0.85, 0.65, 0.45), 1.0)

	func _dibujar_hoja_idle(base: Vector2, angulo: float, largo: float, ancho: float,
			relleno: Color, borde: Color, brillo: Color, t: float, fase: float) -> void:
		var vaiven: float = sin(t * 0.85 + fase) * 0.035
		var a: float = angulo + vaiven
		var dir := Vector2(sin(a), -cos(a))
		var perp := Vector2(cos(a), sin(a))
		var curva: float = largo * 0.10
		var pts := PackedVector2Array()
		var segmentos := 8
		for i in range(segmentos + 1):
			var u := float(i) / float(segmentos)
			var semi: float = sin(u * PI) * ancho * 0.5 * (1.0 - 0.18 * u)
			pts.append(base + dir * (u * largo) + perp * (semi + sin(u * PI) * curva))
		for i in range(segmentos, -1, -1):
			var u := float(i) / float(segmentos)
			var semi: float = sin(u * PI) * ancho * 0.5 * (1.0 - 0.18 * u)
			pts.append(base + dir * (u * largo) - perp * (semi - sin(u * PI) * curva))
		draw_colored_polygon(pts, relleno)
		var cerrado := PackedVector2Array(pts)
		cerrado.append(pts[0])
		draw_polyline(cerrado, borde, 1.15, true)
		# Nervio central y vena lateral.
		var punta := base + dir * (largo * 0.90)
		draw_line(base + dir * (largo * 0.04), punta, Color(brillo, 0.72), 1.1, true)
		for lado: float in [-1.0, 1.0]:
			var u_v := 0.52
			var p_v := base + dir * (largo * u_v) + perp * (lado * ancho * 0.22)
			draw_line(base + dir * (largo * 0.24), p_v, Color(brillo, 0.35), 0.9, true)
		# Brillo en la mitad superior de la hoja.
		var h_base := base + dir * (largo * 0.12) + perp * (ancho * 0.16)
		var h_fin := base + dir * (largo * 0.66) + perp * (ancho * 0.10)
		draw_line(h_base, h_fin, Color(1.0, 1.0, 0.90, 0.22), maxf(1.0, ancho * 0.10), true)

	func _dibujar_motas_idle(w: float, h: float, t: float) -> void:
		# Diminutas partículas de polvo flotando en el haz de luz.
		for i in range(7):
			var px: float = w * 0.10 + fmod(t * (3.5 + float(i % 3) * 1.8) + float(i) * 71.0, w * 0.42)
			var py: float = h * 0.18 + fmod(float(i) * 43.0 + sin(t * 0.40 + float(i) * 1.7) * 16.0, h * 0.50)
			var r: float = 0.7 + float(i % 3) * 0.45
			draw_circle(Vector2(px, py), r, Color(1.0, 0.97, 0.84, 0.30), true, -1.0, true)

# ---------------------------------------------------------------- mostrador del tiempo libre (delante del torso)

class _CapaMostradorIdle extends Control:
	var _padre: Escenario_Actividad

	func _init(padre: Escenario_Actividad) -> void:
		_padre = padre
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if _padre == null or size.x <= 1.0 or size.y <= 1.0:
			return
		var w := size.x
		var h := size.y
		var y_atras := h * 0.715
		var y_borde := h * 0.795
		var y_frente := h * 0.865

		# 1. Tapa de la encimera: madera cálida con degradado y brillo superior.
		draw_rect(Rect2(0.0, y_atras, w, y_borde - y_atras), Color("#c97a35"))
		var bandas := 7
		for i in range(bandas):
			var u := float(i) / float(bandas - 1)
			var col := Color("#dd9147").lerp(Color("#b46325"), u)
			draw_rect(
				Rect2(0.0, y_atras + (y_borde - y_atras) * float(i) / float(bandas),
					  w, (y_borde - y_atras) / float(bandas) + 1.0),
				col
			)
		draw_rect(Rect2(0.0, y_atras + 1.0, w, maxf(1.5, h * 0.010)), Color(1.0, 0.82, 0.55, 0.38))
		for i in range(3):
			var gy: float = y_atras + (y_borde - y_atras) * (0.28 + float(i) * 0.22)
			draw_line(Vector2(w * 0.04, gy), Vector2(w * 0.96, gy), Color(0.45, 0.22, 0.07, 0.16), 1.0, true)
		# Reflejo suave de la ventana sobre la madera.
		draw_colored_polygon(PackedVector2Array([
			Vector2(w * 0.10, y_atras), Vector2(w * 0.27, y_atras),
			Vector2(w * 0.34, y_borde), Vector2(w * 0.16, y_borde),
		]), Color(1.0, 0.93, 0.75, 0.10))
		draw_line(Vector2(0.0, y_atras), Vector2(w, y_atras), Color("#8a4a18"), 1.4)

		# 2. Canto frontal grueso con brillo y sombra.
		draw_rect(Rect2(0.0, y_borde, w, y_frente - y_borde), Color("#8a451d"))
		draw_rect(Rect2(0.0, y_borde, w, maxf(2.0, h * 0.012)), Color("#d1813a"))
		draw_line(Vector2(0.0, y_borde), Vector2(w, y_borde), Color("#6f3414"), 1.6)
		draw_rect(Rect2(0.0, y_frente - maxf(1.5, h * 0.008), w, maxf(1.5, h * 0.008)), Color(0.25, 0.11, 0.03, 0.35))

		# 3. Mueble bajo con paneles rehundidos.
		draw_rect(Rect2(0.0, y_frente, w, h - y_frente), Color("#4a2411"))
		var paneles: int = maxi(2, int(round(w / 170.0)))
		var ancho_p: float = w / float(paneles)
		for i in range(paneles):
			var x0: float = ancho_p * float(i)
			var margen_x: float = maxf(5.0, ancho_p * 0.10)
			var margen_y: float = maxf(3.0, h * 0.014)
			var panel := Rect2(
				x0 + margen_x,
				y_frente + margen_y,
				ancho_p - margen_x * 2.0,
				maxf(6.0, h - y_frente - margen_y * 2.0)
			)
			draw_rect(panel, Color("#5c2d15"))
			draw_rect(panel, Color("#351808"), false, maxf(1.2, h * 0.008))
			draw_line(panel.position + Vector2(2.0, 2.0), Vector2(panel.end.x - 2.0, panel.position.y + 2.0),
				Color(0.55, 0.30, 0.14, 0.45), 1.2, true)
		for i in range(paneles + 1):
			var sx: float = ancho_p * float(i)
			draw_line(Vector2(sx, y_frente), Vector2(sx, h), Color(0.18, 0.08, 0.02, 0.55), 1.4)
		draw_rect(Rect2(0.0, y_frente, w, maxf(2.0, h * 0.012)), Color(0.15, 0.06, 0.01, 0.28))
		draw_rect(Rect2(0.0, h - maxf(3.0, h * 0.018), w, maxf(3.0, h * 0.018)), Color(0.12, 0.05, 0.01, 0.35))


# ---------------------------------------------------------------- capa intermedia de mesa (delante del torso, detrás de brazos y cubiertos)

class _CapaMesaComer extends Control:
	var _padre: Escenario_Actividad

	func _init(padre: Escenario_Actividad) -> void:
		_padre = padre
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if _padre == null or _padre._personaje == null or size.x <= 1.0 or size.y <= 1.0:
			return
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var t: float = _padre._t
		var y_mesa := h - 46.0
		var es_calle: bool = _padre._en_la_calle
		var es_premium: bool = _padre._es_mesa_premium()
		var plato: String = _padre._plato_actual
		var porcion: float = 1.0 - float(_padre._bocados_dados) * 0.13

		# 1. Superficie de mesa en perspectiva + borde frontal con grosor 3D
		_dibujar_superficie_mesa(w, h, cx, y_mesa, es_calle, es_premium, t)

		# 2. Servilleta doblada a la izquierda (desaparece de la mesa cuando la recoge la mano izquierda)
		if not _padre._personaje.esta_sosteniendo_servilleta():
			_dibujar_servilleta_en_mesa(Vector2(cx - 60.4, y_mesa + 13.5), es_calle, es_premium)

		# 3. Cuchillo apoyado junto a la servilleta cuando no está en la mano izquierda
		if not es_calle and not _padre._personaje.esta_sosteniendo_cuchillo():
			_dibujar_cuchillo_en_mesa(Vector2(cx - 48.0, y_mesa + 15.0))

		# 4. Plato / caja con comida detallada en perspectiva real
		var centro_plato := Vector2(cx, y_mesa + 16.5)
		if es_calle:
			_dibujar_caja_takeout(centro_plato, porcion)
		else:
			_dibujar_plato_y_comida(centro_plato, plato, es_premium, porcion)

		# 5. Tenedor apoyado en el borde derecho del plato cuando no se sostiene (beber, delicioso, limpiar, oler)
		if not _padre._personaje.esta_sosteniendo_tenedor():
			_dibujar_tenedor_en_plato(centro_plato + Vector2(28.0, 2.0), es_calle)

		# 6. Vaso / copa / vaso de cartón a la derecha (se oculta mientras lo levanta al beber)
		if not _padre._personaje.esta_sosteniendo_vaso():
			_dibujar_vaso_en_mesa(Vector2(cx + 62.4, y_mesa + 5.5), _padre._personaje.color_bebida, _padre._personaje.estilo_vaso)

		# 7. Cesta de pan y pequeño jarrón para dar vida a la mesa
		if not es_calle:
			_dibujar_cesta_pan(Vector2(cx - 122.0, y_mesa + 14.0), es_premium)
			_dibujar_jarron(Vector2(cx + 138.0, y_mesa + 9.0), es_premium)
		else:
			_dibujar_bote_salsa(Vector2(cx - 122.0, y_mesa + 13.0))
			_dibujar_lata(Vector2(cx + 130.0, y_mesa + 12.0))

		# 8. Cintas suaves de vapor cálido subiendo desde el plato
		var op_vapor: float = 0.62 if _padre._variacion_activa == "oler" else 0.42
		_dibujar_vapor_ondulado(centro_plato + Vector2(0.0, -8.0), t, op_vapor)

	func _dibujar_superficie_mesa(w: float, h: float, cx: float, y_mesa: float, es_calle: bool, es_premium: bool, t: float) -> void:
		var y_borde := h - 13.0
		if es_calle:
			# Mesa de picnic / madera desgastada exterior con mantel a cuadros.
			draw_rect(Rect2(0.0, y_mesa, w, y_borde - y_mesa), Color("#b45309"))
			draw_rect(Rect2(0.0, y_borde, w, h - y_borde), Color("#78350f"))
			draw_line(Vector2(0.0, y_mesa + 11.0), Vector2(w, y_mesa + 11.0), Color("#78350f", 0.55), 1.6)
			draw_line(Vector2(0.0, y_mesa + 23.0), Vector2(w, y_mesa + 23.0), Color("#78350f", 0.55), 1.6)
			draw_line(Vector2(0.0, y_mesa), Vector2(w, y_mesa), TINTA, 2.4)
			draw_line(Vector2(0.0, y_borde), Vector2(w, y_borde), TINTA, 2.0)
			# Mantel individual a cuadros rojos sobre el centro.
			var rx0 := cx - 108.0
			var rx1 := cx + 108.0
			var ancho_c := (rx1 - rx0) / 12.0
			var alto_c := (y_borde - y_mesa - 4.0) / 3.0
			for ix in range(12):
				for iy in range(3):
					var col_c := Color("#dc2626") if (ix + iy) % 2 == 0 else Color("#fff7ed")
					draw_rect(Rect2(rx0 + float(ix) * ancho_c, y_mesa + 2.0 + float(iy) * alto_c,
						ancho_c + 0.5, alto_c + 0.5), col_c)
			draw_rect(Rect2(rx0, y_mesa + 2.0, rx1 - rx0, y_borde - y_mesa - 4.0),
				Color(0.40, 0.12, 0.04, 0.40), false, 1.2)
			# Caída del mantel por el canto frontal.
			for ix in range(12):
				for iy in range(2):
					var col_f := Color("#dc2626") if (ix + iy) % 2 == 0 else Color("#fff7ed")
					draw_rect(Rect2(rx0 + float(ix) * ancho_c, y_borde + float(iy) * (h - y_borde) * 0.5,
						ancho_c + 0.5, (h - y_borde) * 0.5 + 0.5), col_f)
			for i in range(4):
				var fx := rx0 + 12.0 + float(i) * (rx1 - rx0 - 24.0) / 3.0
				draw_line(Vector2(fx, y_borde), Vector2(fx + 3.0, h), Color(0.40, 0.12, 0.04, 0.28), 1.2, true)
			draw_line(Vector2(rx0, h - 3.0), Vector2(rx1, h - 3.0), Color("#7f1d1d", 0.55), 1.4)
			return

		if es_premium:
			# Mesa de nogal oscuro + camino de mesa crema con ribete dorado + velita parpadeante
			draw_rect(Rect2(0.0, y_mesa, w, y_borde - y_mesa), Color("#5c2d16"))
			draw_rect(Rect2(0.0, y_borde, w, h - y_borde), Color("#3b1a0a"))
			# Brillo cálido sobre la madera.
			draw_colored_polygon(_elipse(Vector2(cx, y_mesa + 15.0), 140.0, 22.0, 30), Color(1.0, 0.88, 0.58, 0.07))
			draw_line(Vector2(0.0, y_mesa), Vector2(w, y_mesa), TINTA, 2.4)
			# Mantel de lino que cae por el borde frontal con pliegues.
			var cloth := PackedVector2Array([
				Vector2(cx - 126.0, y_borde - 2.0), Vector2(cx + 126.0, y_borde - 2.0),
				Vector2(cx + 142.0, h), Vector2(cx - 142.0, h),
			])
			draw_colored_polygon(cloth, Color("#f4ead5"))
			for i in range(5):
				var fx := cx - 100.0 + float(i) * 50.0
				draw_line(Vector2(fx, y_borde), Vector2(fx + 7.0, h), Color("#d6c3a5", 0.55), 1.6, true)
			draw_rect(Rect2(cx - 126.0, y_borde - 2.0, 252.0, 4.0), Color("#e8d9be"))
			draw_line(Vector2(cx - 142.0, h - 2.0), Vector2(cx + 142.0, h - 2.0), Color("#d6c3a5"), 1.6)
			draw_line(Vector2(cx - 142.0, h - 6.0), Vector2(cx + 142.0, h - 6.0), Color("#d97706", 0.40), 1.0)
			# Camino de mesa elegante en perspectiva
			var mantel := PackedVector2Array([
				Vector2(cx - 86.0, y_mesa), Vector2(cx + 86.0, y_mesa),
				Vector2(cx + 98.0, y_borde), Vector2(cx - 98.0, y_borde),
			])
			draw_colored_polygon(mantel, Color("#fef9e7"))
			draw_polyline(mantel, TINTA, 1.6, true)
			draw_line(Vector2(cx - 80.0, y_mesa + 2.0), Vector2(cx - 91.0, y_borde - 2.0), Color("#d97706"), 2.0, true)
			draw_line(Vector2(cx + 80.0, y_mesa + 2.0), Vector2(cx + 91.0, y_borde - 2.0), Color("#d97706"), 2.0, true)
			# Vela cálida en portavelas de latón a la derecha (deja libre el pill inferior izquierdo)
			var vx := cx + 104.0
			var vy := y_mesa + 10.0
			var halo := 18.0 + sin(t * 7.5) * 2.5
			draw_circle(Vector2(vx, vy - 22.0), halo, Color("#fde047", 0.22), true, -1.0, true)
			_poligono_elipse(Vector2(vx, vy + 2.0), 8.0, 2.6, Color("#b45309"), 1.6)
			draw_rect(Rect2(vx - 4.5, vy - 14.0, 9.0, 16.0), Color("#fffbeb"))
			draw_rect(Rect2(vx - 4.5, vy - 14.0, 9.0, 16.0), TINTA, false, 1.5)
			var dx_l := sin(t * 11.0) * 1.1
			var llama := PackedVector2Array([
				Vector2(vx + dx_l, vy - 25.0), Vector2(vx + 3.5, vy - 17.5),
				Vector2(vx, vy - 14.5), Vector2(vx - 3.5, vy - 17.5),
			])
			draw_colored_polygon(llama, Color("#f97316"))
			draw_circle(Vector2(vx + dx_l * 0.4, vy - 18.5), 1.8, Color("#fef08a"), true, -1.0, true)
		else:
			# Mesa de roble miel con vetas sutiles y salvamanteles acogedor
			draw_rect(Rect2(0.0, y_mesa, w, y_borde - y_mesa), Color("#d97706"))
			draw_rect(Rect2(0.0, y_borde, w, h - y_borde), Color("#9a3412"))
			# Brillo y vetas suaves de madera
			draw_rect(Rect2(0.0, y_mesa, w, 4.0), Color("#f59e0b", 0.55))
			for vy_off: float in [9.0, 20.0, 28.0]:
				draw_line(Vector2(18.0, y_mesa + vy_off), Vector2(w - 22.0, y_mesa + vy_off), Color("#b45309", 0.36), 1.4)
			draw_colored_polygon(_elipse(Vector2(cx, y_mesa + 15.0), 135.0, 21.0, 30), Color(1.0, 0.90, 0.62, 0.06))
			draw_line(Vector2(0.0, y_mesa), Vector2(w, y_mesa), TINTA, 2.4)
			# Tapete de algodón que cae por el borde frontal.
			var runner := PackedVector2Array([
				Vector2(cx - 86.0, y_borde - 1.0), Vector2(cx + 86.0, y_borde - 1.0),
				Vector2(cx + 96.0, h), Vector2(cx - 96.0, h),
			])
			draw_colored_polygon(runner, Color("#fff7ed"))
			for i in range(4):
				var fx := cx - 64.0 + float(i) * 43.0
				draw_line(Vector2(fx, y_borde), Vector2(fx + 5.0, h), Color("#fed7aa", 0.75), 1.4, true)
			draw_rect(Rect2(cx - 86.0, y_borde - 1.0, 172.0, 3.0), Color("#fde68a"))
			draw_line(Vector2(cx - 96.0, h - 3.0), Vector2(cx + 96.0, h - 3.0), Color("#fb923c", 0.55), 1.4)
			draw_line(Vector2(0.0, y_borde), Vector2(w, y_borde), TINTA, 2.0)
			# Vetas del canto frontal.
			for i in range(3):
				draw_line(Vector2(0.0, y_borde + 4.0 + float(i) * 4.0), Vector2(w, y_borde + 4.0 + float(i) * 4.0),
					Color(0.35, 0.12, 0.02, 0.14), 1.0, true)
			# Salvamantel individual tejido bajo el plato
			var mat := PackedVector2Array([
				Vector2(cx - 72.0, y_mesa + 3.0), Vector2(cx + 72.0, y_mesa + 3.0),
				Vector2(cx + 80.0, y_borde - 2.0), Vector2(cx - 80.0, y_borde - 2.0),
			])
			draw_colored_polygon(mat, Color("#fff7ed"))
			var mat_c := PackedVector2Array(mat)
			mat_c.append(mat[0])
			draw_polyline(mat_c, TINTA, 1.6, true)
			draw_line(Vector2(cx - 66.0, y_mesa + 6.0), Vector2(cx + 66.0, y_mesa + 6.0), Color("#fb923c", 0.55), 1.6)
			draw_line(Vector2(cx - 73.0, y_borde - 5.0), Vector2(cx + 73.0, y_borde - 5.0), Color("#fb923c", 0.55), 1.6)
			# Salero y pimentero a la derecha de la mesa
			var sp_x := cx + 100.0
			var sp_y := y_mesa + 11.0
			for idx_s in range(2):
				var sx_i := sp_x + float(idx_s) * 13.0
				var col_s := Color("#f8fafc") if idx_s == 0 else Color("#475569")
				draw_rect(Rect2(sx_i - 4.0, sp_y - 10.0, 8.0, 11.0), col_s)
				draw_rect(Rect2(sx_i - 4.0, sp_y - 10.0, 8.0, 11.0), TINTA, false, 1.4)
				draw_rect(Rect2(sx_i - 4.5, sp_y - 13.0, 9.0, 3.5), Color("#cbd5e1"))
				draw_rect(Rect2(sx_i - 4.5, sp_y - 13.0, 9.0, 3.5), TINTA, false, 1.2)

	func _dibujar_cesta_pan(centro: Vector2, es_premium: bool) -> void:
		var col_cesta := Color("#b45309") if es_premium else Color("#c98a4b")
		draw_colored_polygon(_elipse(centro + Vector2(2.0, 4.0), 24.0, 7.0, 20), Color(0.0, 0.0, 0.0, 0.14))
		_poligono_elipse(centro + Vector2(0.0, 2.0), 22.0, 8.0, col_cesta, 1.6)
		# Paño a cuadros asomando.
		var pano := PackedVector2Array([
			centro + Vector2(-20.0, 1.0), centro + Vector2(20.0, 1.0),
			centro + Vector2(16.0, -10.0), centro + Vector2(-16.0, -10.0),
		])
		draw_colored_polygon(pano, Color("#f8fafc"))
		for i in range(3):
			draw_line(centro + Vector2(-16.0 + float(i) * 13.0, 1.0),
				centro + Vector2(-13.0 + float(i) * 11.0, -10.0), Color("#dc2626", 0.45), 1.2)
		# Panecillos.
		for i in range(3):
			var bx: float = -12.0 + float(i) * 12.0
			draw_circle(centro + Vector2(bx, -12.0 - float(i % 2) * 2.0), 7.0, Color("#d97706"), true, -1.0, true)
			draw_arc(centro + Vector2(bx, -12.0 - float(i % 2) * 2.0), 7.0, 0.0, TAU, 14, Color("#92400e"), 1.2, true)
			draw_line(centro + Vector2(bx - 4.0, -14.0 - float(i % 2) * 2.0),
				centro + Vector2(bx + 2.0, -9.0 - float(i % 2) * 2.0), Color("#fbbf24", 0.75), 1.2, true)
		# Asa.
		draw_arc(centro + Vector2(0.0, 1.0), 22.0, PI * 1.1, PI * 1.9, 12, Color("#78350f"), 1.8, true)

	func _dibujar_jarron(centro: Vector2, es_premium: bool) -> void:
		var col := Color("#0ea5e9") if not es_premium else Color("#f8fafc")
		draw_colored_polygon(_elipse(centro + Vector2(2.0, 4.0), 10.0, 4.0, 16), Color(0.0, 0.0, 0.0, 0.14))
		var jarron := PackedVector2Array([
			centro + Vector2(-5.0, 2.0), centro + Vector2(5.0, 2.0),
			centro + Vector2(8.0, -8.0), centro + Vector2(-8.0, -8.0),
		])
		draw_colored_polygon(jarron, col)
		var jc := PackedVector2Array(jarron)
		jc.append(jarron[0])
		draw_polyline(jc, TINTA, 1.2, true)
		draw_rect(Rect2(centro.x - 8.0, centro.y - 15.0, 16.0, 4.0), col.darkened(0.15))
		draw_rect(Rect2(centro.x - 8.0, centro.y - 15.0, 16.0, 4.0), TINTA, false, 1.0)
		# Flores.
		for i in range(3):
			var ang := -0.5 - float(i) * 0.25
			var punta := centro + Vector2(sin(ang) * 9.0, -22.0 - float(i) * 2.0)
			draw_line(centro + Vector2(0.0, -14.0), punta, Color("#15803d"), 1.2, true)
			draw_circle(punta, 3.4, [Color("#f43f5e"), Color("#fde047"), Color("#e879f9")][i], true, -1.0, true)
			draw_circle(punta, 3.4, Color(0.0, 0.0, 0.0, 0.18), false, 0.8)
		draw_circle(centro + Vector2(0.0, -18.0), 2.0, Color("#22c55e"), true, -1.0, true)

	func _dibujar_lata(centro: Vector2) -> void:
		draw_rect(Rect2(centro.x - 5.0, centro.y - 12.0, 10.0, 14.0), Color("#3b82f6"))
		draw_rect(Rect2(centro.x - 5.0, centro.y - 12.0, 10.0, 14.0), TINTA, false, 1.0)
		draw_rect(Rect2(centro.x - 5.0, centro.y - 8.0, 10.0, 3.0), Color("#f8fafc"))
		draw_rect(Rect2(centro.x - 4.0, centro.y - 14.0, 8.0, 2.0), Color("#cbd5e1"))

	func _dibujar_bote_salsa(centro: Vector2) -> void:
		draw_rect(Rect2(centro.x - 5.0, centro.y - 16.0, 10.0, 18.0), Color("#dc2626"))
		draw_rect(Rect2(centro.x - 5.0, centro.y - 16.0, 10.0, 18.0), TINTA, false, 1.0)
		draw_rect(Rect2(centro.x - 3.0, centro.y - 22.0, 6.0, 6.0), Color("#ef4444"))
		draw_rect(Rect2(centro.x - 3.0, centro.y - 22.0, 6.0, 6.0), TINTA, false, 1.0)
		draw_rect(Rect2(centro.x - 4.0, centro.y - 12.0, 8.0, 6.0), Color("#f8fafc"))
		draw_line(Vector2(centro.x - 2.0, centro.y - 10.0), Vector2(centro.x + 2.0, centro.y - 10.0),
			Color("#dc2626"), 1.0)
		draw_line(Vector2(centro.x - 2.0, centro.y - 8.0), Vector2(centro.x + 2.0, centro.y - 8.0),
			Color("#dc2626"), 1.0)

	func _dibujar_plato_y_comida(centro: Vector2, plato: String, es_premium: bool, porcion: float) -> void:
		# Sombra elíptica del plato sobre el mantel
		draw_colored_polygon(_elipse(centro + Vector2(2.0, 3.8), 46.0, 14.0, 28), Color(0.0, 0.0, 0.0, 0.16))
		# Base cerámica inferior para dar volumen 3D
		_poligono_elipse(centro + Vector2(0.0, 2.2), 42.0, 12.6, Color("#cbd5e1"), 1.6)
		# Aro principal del plato en perspectiva real
		_poligono_elipse(centro, 45.0, 13.4, Color("#ffffff"), 2.1)
		# Hueco interior del plato
		var interior := _elipse(centro + Vector2(0.0, 0.6), 32.5, 8.8, 24)
		draw_colored_polygon(interior, Color("#f1f5f9"))
		if es_premium:
			var aro_oro := _elipse(centro, 37.5, 10.6, 26)
			aro_oro.append(aro_oro[0])
			draw_polyline(aro_oro, Color("#d97706"), 1.6, true)

		var s := clampf(porcion, 0.56, 1.0)
		match plato:
			"desayuno":
				# Torre de tortitas doradas con sirope de arce, mantequilla y frutos rojos
				var capas: int = 3 if s > 0.75 else 2
				for i in range(capas):
					var py := centro.y + 1.0 - float(i) * 4.5
					var rx := (22.0 - float(i) * 1.4) * (0.85 + 0.15 * s)
					_poligono_elipse(Vector2(centro.x, py + 1.8), rx, 6.4, Color("#b45309"), 1.5)
					_poligono_elipse(Vector2(centro.x, py), rx, 6.2, Color("#f59e0b"), 1.5)
					draw_colored_polygon(_elipse(Vector2(centro.x, py - 0.6), rx * 0.78, 4.2, 18), Color("#fbbf24"))
				var top_y := centro.y + 1.0 - float(capas - 1) * 4.5
				# Sirope brillante cayendo por el borde
				var sirope := PackedVector2Array([
					Vector2(centro.x - 12.0, top_y - 1.0), Vector2(centro.x + 12.0, top_y - 1.0),
					Vector2(centro.x + 15.0, top_y + 4.0), Vector2(centro.x + 9.0, top_y + 7.0),
					Vector2(centro.x + 2.0, top_y + 4.0), Vector2(centro.x - 5.0, top_y + 8.0),
					Vector2(centro.x - 13.0, top_y + 3.0),
				])
				draw_colored_polygon(sirope, Color("#92400e", 0.90))
				# Dado de mantequilla fundiéndose
				var mant := PackedVector2Array([
					Vector2(centro.x - 5.0, top_y - 4.5), Vector2(centro.x + 5.0, top_y - 4.5),
					Vector2(centro.x + 6.0, top_y - 0.5), Vector2(centro.x - 4.0, top_y - 0.5),
				])
				draw_colored_polygon(mant, Color("#fef08a"))
				var mant_c := PackedVector2Array(mant)
				mant_c.append(mant[0])
				draw_polyline(mant_c, TINTA, 1.3, true)
				# Frutos rojos al lado
				draw_circle(centro + Vector2(-21.0, 2.0), 3.6, Color("#e11d48"), true, -1.0, true)
				draw_arc(centro + Vector2(-21.0, 2.0), 3.6, 0.0, TAU, 12, TINTA, 1.2, true)
				draw_circle(centro + Vector2(21.0, 1.5), 3.2, Color("#2563eb"), true, -1.0, true)
				draw_arc(centro + Vector2(21.0, 1.5), 3.2, 0.0, TAU, 12, TINTA, 1.2, true)
			"almuerzo":
				# Espaguetis con salsa marinara brillante, albóndigas y hojas de albahaca
				var rx_p := 25.0 * (0.84 + 0.16 * s)
				var ry_p := 9.2 * (0.82 + 0.18 * s)
				_poligono_elipse(centro + Vector2(0.0, -2.5), rx_p, ry_p, Color("#facc15"), 1.7)
				# Trazos de fideos enrollados
				for k in range(-2, 3):
					var arc_c := centro + Vector2(float(k) * 5.2, -3.0 + absf(float(k)) * 0.8)
					draw_arc(arc_c, 6.2, PI * 1.1, TAU - 0.15, 10, Color("#ca8a04"), 1.5, true)
				# Salsa de tomate casera en el centro
				_poligono_elipse(centro + Vector2(0.0, -4.6), rx_p * 0.64, ry_p * 0.58, Color("#dc2626"), 1.4)
				draw_circle(centro + Vector2(-4.0, -6.5), 2.0, Color(1.0, 0.85, 0.85, 0.65), true, -1.0, true)
				# Albóndigas jugosas
				for mb: Vector2 in [Vector2(-9.5, -5.0), Vector2(8.5, -4.2), Vector2(0.5, -7.8)]:
					if s < 0.75 and mb.x > 5.0:
						continue
					draw_circle(centro + mb, 4.6, Color("#7c2d12"), true, -1.0, true)
					draw_arc(centro + mb, 4.6, 0.0, TAU, 14, TINTA, 1.4, true)
					draw_circle(centro + mb + Vector2(-1.4, -1.4), 1.3, Color("#b45309"), true, -1.0, true)
				# Hojas frescas de albahaca
				draw_colored_polygon(_elipse(centro + Vector2(-2.0, -9.8), 4.4, 2.2, 12, -0.35), Color("#22c55e"))
				draw_colored_polygon(_elipse(centro + Vector2(3.5, -9.2), 4.0, 2.0, 12, 0.40), Color("#16a34a"))
			_:
				# Cena completa: filete marcado a la plancha, puré cremoso, zanahorias y brócoli
				# Puré cremoso a la izquierda
				_poligono_elipse(centro + Vector2(-14.0, -2.5), 11.5 * (0.82 + 0.18 * s), 5.6, Color("#fef9c3"), 1.5)
				draw_circle(centro + Vector2(-15.0, -4.5), 1.4, Color("#16a34a"), true, -1.0, true)
				draw_circle(centro + Vector2(-11.0, -3.5), 1.2, Color("#16a34a"), true, -1.0, true)
				# Filete jugoso a la derecha
				var rx_st := 15.5 * (0.82 + 0.18 * s)
				_poligono_elipse(centro + Vector2(6.5, -3.0), rx_st, 6.8, Color("#92400e"), 1.7)
				draw_colored_polygon(_elipse(centro + Vector2(5.5, -4.2), rx_st * 0.72, 4.0, 16), Color("#b45309"))
				# Marcas de parrilla
				for gx_o: float in [-4.0, 2.0, 8.0]:
					draw_line(centro + Vector2(gx_o, -6.5), centro + Vector2(gx_o + 4.5, -0.8), Color("#451a03", 0.75), 1.6, true)
				# Brócoli y zanahorias glaseadas
				for vb: Vector2 in [Vector2(-4.0, 1.8), Vector2(1.5, 2.8)]:
					draw_circle(centro + vb, 4.2, Color("#16a34a"), true, -1.0, true)
					draw_arc(centro + vb, 4.2, 0.0, TAU, 12, TINTA, 1.3, true)
				draw_circle(centro + Vector2(-11.0, 3.0), 3.0, Color("#f97316"), true, -1.0, true)
				draw_arc(centro + Vector2(-11.0, 3.0), 3.0, 0.0, TAU, 10, TINTA, 1.2, true)

	func _dibujar_caja_takeout(centro: Vector2, porcion: float) -> void:
		draw_colored_polygon(_elipse(centro + Vector2(2.0, 4.5), 34.0, 10.0, 20), Color(0.0, 0.0, 0.0, 0.18))
		var caja := PackedVector2Array([
			centro + Vector2(-26.0, -8.0), centro + Vector2(26.0, -8.0),
			centro + Vector2(22.0, 8.5), centro + Vector2(-22.0, 8.5),
		])
		draw_colored_polygon(caja, Color("#f8fafc"))
		var caja_c := PackedVector2Array(caja)
		caja_c.append(caja[0])
		draw_polyline(caja_c, TINTA, 1.8, true)
		# Solapa abierta trasera
		var solapa := PackedVector2Array([
			centro + Vector2(-26.0, -8.0), centro + Vector2(-32.0, -15.0),
			centro + Vector2(32.0, -15.0), centro + Vector2(26.0, -8.0),
		])
		draw_colored_polygon(solapa, Color("#e2e8f0"))
		var sol_c := PackedVector2Array(solapa)
		sol_c.append(solapa[0])
		draw_polyline(sol_c, TINTA, 1.6, true)
		# Fideos y verduras dentro de la caja
		var s := clampf(porcion, 0.60, 1.0)
		_poligono_elipse(centro + Vector2(0.0, -8.5), 21.0 * s, 6.2, Color("#f59e0b"), 1.5)
		draw_circle(centro + Vector2(-6.0, -9.5), 3.2, Color("#22c55e"), true, -1.0, true)
		draw_circle(centro + Vector2(6.5, -8.8), 2.8, Color("#ef4444"), true, -1.0, true)

	func _dibujar_servilleta_en_mesa(pos: Vector2, es_calle: bool, es_premium: bool) -> void:
		var col_t := Color("#fef3c7") if es_premium else Color("#ffffff")
		var col_b := Color("#d97706") if es_premium else (Color("#94a3b8") if es_calle else Color("#ef4444"))
		var serv := PackedVector2Array([
			pos + Vector2(-14.0, -4.5), pos + Vector2(10.0, -6.0),
			pos + Vector2(15.0, 6.0), pos + Vector2(-11.0, 7.5),
		])
		draw_colored_polygon(serv, col_t)
		var sc := PackedVector2Array(serv)
		sc.append(serv[0])
		draw_polyline(sc, TINTA, 1.6, true)
		draw_line(pos + Vector2(-10.0, 1.0), pos + Vector2(12.0, 0.0), Color("#cbd5e1"), 1.4, true)
		draw_line(pos + Vector2(-9.0, 4.2), pos + Vector2(12.5, 3.2), Color(col_b, 0.68), 1.6, true)

	func _dibujar_cuchillo_en_mesa(pos: Vector2) -> void:
		draw_line(pos + Vector2(-2.0, 5.0), pos + Vector2(4.0, -10.0), TINTA, 4.2, true)
		draw_line(pos + Vector2(-2.0, 5.0), pos + Vector2(1.0, -2.5), Color("#64748b"), 2.2, true)
		draw_line(pos + Vector2(1.0, -2.5), pos + Vector2(4.0, -10.0), Color("#e2e8f0"), 2.2, true)

	func _dibujar_tenedor_en_plato(pos: Vector2, es_calle: bool) -> void:
		var col_m := Color("#f8fafc") if es_calle else Color("#cbd5e1")
		draw_line(pos + Vector2(15.0, 6.0), pos + Vector2(-8.0, -5.0), TINTA, 4.2, true)
		draw_line(pos + Vector2(15.0, 6.0), pos + Vector2(-8.0, -5.0), col_m, 2.0, true)
		for dy: float in [-2.6, 0.0, 2.6]:
			draw_line(pos + Vector2(-8.0, -5.0 + dy * 0.7), pos + Vector2(-15.0, -8.2 + dy * 0.7), TINTA, 1.5, true)

	func _dibujar_vaso_en_mesa(pos: Vector2, col_bebida: Color, estilo: String) -> void:
		draw_colored_polygon(_elipse(pos + Vector2(1.5, 11.8), 9.0, 3.0, 16), Color(0.0, 0.0, 0.0, 0.16))
		if estilo == "copa":
			_poligono_elipse(pos + Vector2(0.0, 11.0), 6.2, 2.0, Color("#e0f2fe"), 1.4)
			draw_line(pos + Vector2(0.0, 10.5), pos + Vector2(0.0, 1.5), TINTA, 3.0, true)
			draw_line(pos + Vector2(0.0, 10.5), pos + Vector2(0.0, 1.5), Color("#e0f2fe"), 1.4, true)
			var caliz := PackedVector2Array([
				pos + Vector2(-7.8, -12.5), pos + Vector2(7.8, -12.5),
				pos + Vector2(7.2, -2.0), pos + Vector2(3.4, 2.4),
				pos + Vector2(-3.4, 2.4), pos + Vector2(-7.2, -2.0),
			])
			draw_colored_polygon(caliz, Color(0.88, 0.96, 1.0, 0.78))
			var liq := PackedVector2Array([
				pos + Vector2(-6.4, -6.5), pos + Vector2(6.4, -6.5),
				pos + Vector2(5.8, -2.0), pos + Vector2(3.0, 1.6),
				pos + Vector2(-3.0, 1.6), pos + Vector2(-5.8, -2.0),
			])
			draw_colored_polygon(liq, col_bebida)
			var cc := PackedVector2Array(caliz)
			cc.append(caliz[0])
			draw_polyline(cc, TINTA, 1.6, true)
			_poligono_elipse(pos + Vector2(0.0, -12.5), 7.8, 2.1, Color(1.0, 1.0, 1.0, 0.45), 1.4)
			draw_line(pos + Vector2(-4.4, -9.5), pos + Vector2(-4.0, -2.0), Color(1.0, 1.0, 1.0, 0.8), 1.5, true)
			return

		if estilo == "carton":
			var cup := PackedVector2Array([
				pos + Vector2(-8.2, -12.5), pos + Vector2(8.2, -12.5),
				pos + Vector2(6.0, 10.5), pos + Vector2(-6.0, 10.5),
			])
			draw_colored_polygon(cup, Color("#f8fafc"))
			var banda := PackedVector2Array([
				pos + Vector2(-7.3, -4.5), pos + Vector2(7.3, -4.5),
				pos + Vector2(6.6, 3.5), pos + Vector2(-6.6, 3.5),
			])
			draw_colored_polygon(banda, Color("#d97706"))
			var cc2 := PackedVector2Array(cup)
			cc2.append(cup[0])
			draw_polyline(cc2, TINTA, 1.6, true)
			var tapa := PackedVector2Array([
				pos + Vector2(-9.2, -15.5), pos + Vector2(9.2, -15.5),
				pos + Vector2(8.6, -12.0), pos + Vector2(-8.6, -12.0),
			])
			draw_colored_polygon(tapa, Color("#e2e8f0"))
			var tc := PackedVector2Array(tapa)
			tc.append(tapa[0])
			draw_polyline(tc, TINTA, 1.5, true)
			return

		# Vaso de cristal normal
		var cuerpo := PackedVector2Array([
			pos + Vector2(-8.2, -13.0), pos + Vector2(8.2, -13.0),
			pos + Vector2(6.2, 10.5), pos + Vector2(-6.2, 10.5),
		])
		draw_colored_polygon(cuerpo, Color(0.84, 0.95, 1.0, 0.76))
		var zumo := PackedVector2Array([
			pos + Vector2(-7.0, -5.0), pos + Vector2(7.0, -5.0),
			pos + Vector2(5.4, 9.2), pos + Vector2(-5.4, 9.2),
		])
		draw_colored_polygon(zumo, col_bebida)
		draw_colored_polygon(_elipse(pos + Vector2(0.0, -5.0), 7.0, 1.8, 14), col_bebida.lightened(0.22))
		var vc := PackedVector2Array(cuerpo)
		vc.append(cuerpo[0])
		draw_polyline(vc, TINTA, 1.7, true)
		_poligono_elipse(pos + Vector2(0.0, -13.0), 8.2, 2.2, Color(1.0, 1.0, 1.0, 0.45), 1.5)
		draw_line(pos + Vector2(-4.8, -9.5), pos + Vector2(-3.8, 6.5), Color(1.0, 1.0, 1.0, 0.78), 1.7, true)

	func _dibujar_vapor_ondulado(origen: Vector2, t: float, opacidad: float) -> void:
		for i in range(3):
			var fase_l := fmod(t * 0.55 + float(i) * 0.33, 1.0)
			var base_x := origen.x - 14.0 + float(i) * 14.0
			var pts := PackedVector2Array()
			for s in range(7):
				var u := float(s) / 6.0
				var px := base_x + sin(u * PI * 2.2 + t * 3.4 + float(i) * 1.9) * (3.2 + u * 2.4)
				var py := origen.y - fase_l * 10.0 - u * 24.0
				pts.append(Vector2(px, py))
			var alpha := sin(fase_l * PI) * opacidad
			if alpha > 0.03:
				draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha), 2.2, true)

	func _elipse(centro: Vector2, rx: float, ry: float, segs: int, rot: float = 0.0) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var ca := cos(rot)
		var sa := sin(rot)
		for i in range(segs):
			var a := TAU * float(i) / float(segs)
			var lx := cos(a) * rx
			var ly := sin(a) * ry
			pts.append(centro + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
		return pts

	func _poligono_elipse(centro: Vector2, rx: float, ry: float, relleno: Color, grosor: float) -> void:
		var pts := _elipse(centro, rx, ry, 24)
		draw_colored_polygon(pts, relleno)
		var cerr := PackedVector2Array(pts)
		cerr.append(pts[0])
		draw_polyline(cerr, TINTA, grosor, true)


# ---------------------------------------------------------------- capa frontal (muebles, partículas y micro-efectos)

class _CapaFrenteActividad extends Control:
	var _padre: Escenario_Actividad

	func _init(padre: Escenario_Actividad) -> void:
		_padre = padre
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if _padre == null or size.x <= 1.0 or size.y <= 1.0:
			return
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var t: float = _padre._t
		var pose: String = _padre._pose_actual
		var variacion: String = _padre._variacion_activa

		if pose == "idle":
			_frente_idle(w, h, cx, t, variacion)
		else:
			Escenografia_Inicio.dibujar_frente(self, _padre, w, h)

	func _frente_idle(_w: float, _h: float, cx: float, t: float, variacion: String) -> void:
		if variacion == "silbar":
			var p: float = fmod(t * 0.8, 1.0)
			_dibujar_nota_musical(Vector2(cx + 44.0 + p * 34.0, 66.0 - p * 36.0), Color("#2563eb", 1.0 - p))
		elif variacion == "saludar":
			var p: float = fmod(t * 2.0, 1.0)
			draw_arc(Vector2(cx + 56.0, 44.0), 10.0 + p * 8.0, -0.7, 0.7, 10, Color("#f59e0b", 1.0 - p), 2.2, true)

	func _dibujar_estrella(centro: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(8):
			var ang: float = TAU * float(i) / 8.0
			var rad: float = r if i % 2 == 0 else r * 0.35
			pts.append(centro + Vector2(cos(ang), sin(ang)) * rad)
		draw_colored_polygon(pts, col)

	func _dibujar_corazon(centro: Vector2, r: float, col: Color) -> void:
		draw_circle(centro + Vector2(-r * 0.42, -r * 0.25), r * 0.50, col, true, -1.0, true)
		draw_circle(centro + Vector2(r * 0.42, -r * 0.25), r * 0.50, col, true, -1.0, true)
		draw_colored_polygon(PackedVector2Array([
			centro + Vector2(-r * 0.88, -r * 0.05),
			centro + Vector2(r * 0.88, -r * 0.05),
			centro + Vector2(0.0, r * 0.92),
		]), col)

	func _dibujar_nota_musical(pos: Vector2, col: Color) -> void:
		draw_circle(pos, 4.5, col, true, -1.0, true)
		draw_line(pos + Vector2(3.8, 0.0), pos + Vector2(3.8, -15.0), col, 2.4, true)
		draw_line(pos + Vector2(3.8, -15.0), pos + Vector2(10.5, -11.0), col, 2.6, true)
