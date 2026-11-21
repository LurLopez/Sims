class_name Escenario_Actividad
extends PanelContainer
## Mini-escenario animado en tiempo real que muestra al personaje personalizado
## realizando su actividad actual (correr, dormir, comer, ducharse, estudiar, etc.)
## con bucles cortos y micro-acciones espontáneas cada pocos segundos para darle vida.

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
	],
	"dormir": [
		["roncar", "Roncando fuerte...", "roncando", "ninguno", 2.8],
		["darse_vuelta", "Dándose la vuelta", "dormido", "ninguno", 2.2],
		["sonar", "Soñando...", "dormido", "ninguno", 3.2],
		["estirar_brazo", "Estirándose", "dormido", "ninguno", 2.4],
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
	],
	"tv": [
		["reir", "¡Partiéndose de risa!", "reir", "ninguno", 2.6],
		["palomitas", "Comiendo palomitas", "masticando", "ninguno", 2.6],
		["cambiar_canal", "Cambiando de canal", "concentrado", "mando", 2.0],
		["sorpresa_tv", "¡Giro de guion!", "sorpresa", "ninguno", 2.3],
	],
	"manualidades": [
		["pincelada_rapida", "¡A toda velocidad!", "feliz", "pincel", 2.5],
		["admirar", "Admirando su obra", "sonrisa", "pincel", 2.6],
	],
	"cocinar": [
		["saltear", "¡Salteando con estilo!", "feliz", "espatula", 2.5],
		["probar", "Probando el punto", "satisfecho", "espatula", 2.4],
	],
	"fiesta": [
		["bailar", "¡Dándolo todo!", "feliz", "ninguno", 2.6],
		["brindar", "¡A disfrutar!", "feliz_cerrado", "vaso", 2.6],
	],
	"futbol": [
		["toques", "¡Haciendo toques!", "concentrado", "ninguno", 2.5],
		["celebrar_gol", "¡Golazo!", "feliz", "ninguno", 2.4],
	],
	"trabajar": [
		["cafe", "Pausa para café", "feliz_cerrado", "taza", 2.6],
		["mirar_reloj", "Mirando la hora...", "neutral", "ninguno", 2.2],
		["ganar_dinero", "¡Productivo!", "feliz", "ninguno", 2.4],
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
	elif calle_anterior != _en_la_calle:
		# La vivienda cambia el encuadre del tiempo libre (mostrador o calle),
		# aunque la actividad siga siendo la misma.
		_aplicar_layout_personaje()


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
			_personaje.position = Vector2(w * 0.5 - 82.0, -4.0)
			_personaje.size = Vector2(164.0, h + 14.0)
		"cocinar":
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, -8.0)
			_personaje.size = Vector2(164.0, h + 12.0)
		"duchar":
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, 4.0)
			_personaje.size = Vector2(164.0, h + 12.0)
		_:
			_personaje.modo = "busto"
			_personaje.position = Vector2(w * 0.5 - 82.0, 4.0)
			_personaje.size = Vector2(164.0, h + 12.0)

	_personaje.modo_capa = "sin_brazos_delanteros" if es_comer else "completo"
	var es_tiempo_libre := (_pose_actual == "idle" and not _en_la_calle)
	if _capa_mostrador != null:
		_capa_mostrador.visible = es_tiempo_libre
	if _capa_mesa != null:
		_capa_mesa.visible = es_comer
	if _personaje_brazos != null:
		_personaje_brazos.visible = es_comer
		_personaje_brazos.position = _personaje.position
		_personaje_brazos.size = _personaje.size
	if _pill_accion != null:
		_pill_accion.position = Vector2(10.0, maxf(8.0, h - 32.0))


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
		var variacion: String = _padre._variacion_activa

		match pose:
			"correr":
				_fondo_correr(w, h, t, variacion)
			"dormir":
				_fondo_dormir(w, h, t)
			"comer":
				_fondo_comer(w, h, t)
			"duchar":
				_fondo_duchar(w, h, t)
			"estudiar":
				_fondo_estudiar(w, h)
			"tv":
				_fondo_tv(w, h, t)
			"manualidades":
				_fondo_manualidades(w, h)
			"cocinar":
				_fondo_cocinar(w, h, t)
			"fiesta":
				_fondo_fiesta(w, h, t)
			"futbol":
				_fondo_futbol(w, h, t)
			"trabajar":
				_fondo_trabajar(w, h)
			_:
				_fondo_idle(w, h, t)

	func _fondo_correr(w: float, h: float, t: float, variacion: String) -> void:
		# Cielo azul vibrante + sol
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#bae6fd"))
		draw_circle(Vector2(w - 56.0, 34.0), 20.0, Color("#fde047"), true, -1.0, true)
		draw_arc(Vector2(w - 56.0, 34.0), 20.0, 0.0, TAU, 24, Color("#f59e0b"), 2.0, true)

		var vel: float = 165.0 if variacion == "sprint" else 88.0
		# Nubes moviéndose lentamente
		for i in range(3):
			var nx: float = fmod(w + 120.0 - fmod(t * (vel * 0.22) + float(i) * 230.0, w + 180.0), w + 180.0) - 60.0
			var ny: float = 28.0 + float(i % 2) * 22.0
			draw_circle(Vector2(nx, ny), 16.0, Color.WHITE, true, -1.0, true)
			draw_circle(Vector2(nx + 16.0, ny - 5.0), 19.0, Color.WHITE, true, -1.0, true)
			draw_circle(Vector2(nx + 34.0, ny), 15.0, Color.WHITE, true, -1.0, true)

		# Colinas verdes de parque
		draw_rect(Rect2(0.0, h - 68.0, w, 34.0), Color("#86efac"))
		for i in range(5):
			var tx: float = w + 60.0 - fmod(t * (vel * 0.65) + float(i) * 165.0, w + 140.0)
			# Árbol de parque desplazándose
			draw_rect(Rect2(tx - 5.0, h - 98.0, 10.0, 36.0), Color("#92400e"))
			draw_circle(Vector2(tx, h - 104.0), 22.0, Color("#22c55e"), true, -1.0, true)
			draw_arc(Vector2(tx, h - 104.0), 22.0, 0.0, TAU, 20, TINTA, 2.0, true)

		# Camino asfaltado con líneas discontinuas animadas
		draw_rect(Rect2(0.0, h - 42.0, w, 42.0), Color("#64748b"))
		draw_line(Vector2(0.0, h - 42.0), Vector2(w, h - 42.0), TINTA, 2.2, true)
		var off_raya: float = fmod(t * vel * 1.4, 56.0)
		var x: float = -off_raya
		while x < w + 40.0:
			draw_rect(Rect2(x, h - 22.0, 26.0, 4.0), Color("#e2e8f0"))
			x += 56.0

		# Charco cuando salta
		if variacion == "salto":
			var px: float = w * 0.5 + (0.5 - _padre._tiempo_variacion / maxf(0.1, _padre._duracion_variacion)) * 180.0
			draw_circle(Vector2(px, h - 22.0), 16.0, Color("#38bdf8", 0.7), true, -1.0, true)

	func _fondo_dormir(w: float, h: float, t: float) -> void:
		# Habitación nocturna azul índigo
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#1e1b4b"))
		# Ventana con cielo nocturno, luna y estrellas
		var win := Rect2(34.0, 18.0, 108.0, 82.0)
		draw_rect(win, Color("#0f172a"))
		draw_circle(Vector2(66.0, 46.0), 14.0, Color("#fef08a"), true, -1.0, true)
		draw_circle(Vector2(73.0, 42.0), 12.0, Color("#0f172a"), true, -1.0, true)
		for st_p: Vector2 in [Vector2(104.0, 34.0), Vector2(120.0, 58.0), Vector2(92.0, 72.0), Vector2(54.0, 76.0)]:
			var brillo := 0.55 + sin(t * 3.5 + st_p.x) * 0.45
			draw_circle(st_p, 2.0, Color(1.0, 0.98, 0.80, brillo), true, -1.0, true)
		draw_rect(win, Color("#6366f1"), false, 3.0)
		draw_line(Vector2(win.position.x + win.size.x * 0.5, win.position.y), Vector2(win.position.x + win.size.x * 0.5, win.end.y), Color("#6366f1"), 2.5)
		draw_line(Vector2(win.position.x, win.position.y + win.size.y * 0.5), Vector2(win.end.x, win.position.y + win.size.y * 0.5), Color("#6366f1"), 2.5)

		# Cabecero de cama y almohada mullida detrás del personaje
		var cx := w * 0.5
		draw_rect(Rect2(cx - 108.0, h - 108.0, 216.0, 108.0), Color("#78350f"))
		draw_rect(Rect2(cx - 108.0, h - 108.0, 216.0, 108.0), TINTA, false, 2.8)
		var alm := Rect2(cx - 66.0, h - 122.0, 132.0, 56.0)
		draw_rect(alm, Color("#f1f5f9"))
		draw_rect(alm, TINTA, false, 2.4)

	func _fondo_comer(w: float, h: float, t: float) -> void:
		var cx := w * 0.5
		var franja: String = _padre._franja_horaria()

		if _padre._en_la_calle:
			_fondo_comer_calle(w, h, cx, t, franja)
			return

		var es_premium: bool = _padre._es_mesa_premium()

		# 1. Pared y zócalo según mesa básica (cocina cálida) o mesa premium (comedor elegante)
		if es_premium:
			var pared_p := Color("#efe9dd") if franja != "noche" else Color("#2a2638")
			var franja_p := Color("#e5dccb") if franja != "noche" else Color("#221e2e")
			draw_rect(Rect2(0.0, 0.0, w, h), pared_p)
			var sx: float = 0.0
			while sx < w:
				draw_rect(Rect2(sx, 0.0, 22.0, h - 78.0), franja_p)
				sx += 44.0
			# Zócalo de madera nogal con moldura dorada
			draw_rect(Rect2(0.0, h - 82.0, w, 82.0), Color("#451a03"))
			draw_rect(Rect2(0.0, h - 84.0, w, 4.0), Color("#d97706"))
			draw_line(Vector2(0.0, h - 84.0), Vector2(w, h - 84.0), TINTA, 1.8)
		else:
			var pared_b := Color("#fef9e7") if franja != "noche" else Color("#3b344c")
			var azulejo_b := Color("#fde68a") if franja != "noche" else Color("#4b4059")
			draw_rect(Rect2(0.0, 0.0, w, h), pared_b)
			# Franja de azulejos cálidos de cocina
			var y_az := h - 86.0
			draw_rect(Rect2(0.0, y_az, w, 86.0), azulejo_b)
			var col_junta := Color("#f59e0b", 0.28) if franja != "noche" else Color("#cbd5e1", 0.16)
			var gx: float = 0.0
			while gx < w:
				draw_line(Vector2(gx, y_az), Vector2(gx, h), col_junta, 1.2)
				gx += 28.0
			draw_line(Vector2(0.0, y_az + 24.0), Vector2(w, y_az + 24.0), col_junta, 1.2)
			draw_rect(Rect2(0.0, y_az - 3.0, w, 5.0), Color("#d97706"))
			draw_line(Vector2(0.0, y_az - 3.0), Vector2(w, y_az - 3.0), TINTA, 1.6)

		# 2. Ventana dinámica según hora del día a la izquierda
		var win := Rect2(22.0, 14.0, 96.0, 68.0)
		match franja:
			"manana":
				draw_rect(win, Color("#bae6fd"))
				draw_circle(Vector2(win.position.x + 26.0, win.position.y + 44.0), 13.0, Color("#fde047"), true, -1.0, true)
				var nube_x := win.position.x + 56.0 + sin(t * 0.4) * 6.0
				draw_circle(Vector2(nube_x, win.position.y + 24.0), 9.0, Color.WHITE, true, -1.0, true)
				draw_circle(Vector2(nube_x + 11.0, win.position.y + 24.0), 7.5, Color.WHITE, true, -1.0, true)
			"tarde":
				draw_rect(win, Color("#7dd3fc"))
				draw_circle(Vector2(win.position.x + 72.0, win.position.y + 20.0), 11.0, Color("#fef08a"), true, -1.0, true)
				var nube_x2 := win.position.x + 34.0 + sin(t * 0.35) * 8.0
				draw_circle(Vector2(nube_x2, win.position.y + 34.0), 9.5, Color.WHITE, true, -1.0, true)
				draw_circle(Vector2(nube_x2 + 12.0, win.position.y + 32.0), 8.0, Color.WHITE, true, -1.0, true)
			"atardecer":
				draw_rect(win, Color("#fdba74"))
				draw_rect(Rect2(win.position.x, win.position.y, win.size.x, win.size.y * 0.52), Color("#fb923c"))
				draw_circle(Vector2(win.position.x + 52.0, win.position.y + 46.0), 13.0, Color("#fef08a"), true, -1.0, true)
			_:
				draw_rect(win, Color("#0f172a"))
				draw_circle(Vector2(win.position.x + 28.0, win.position.y + 26.0), 10.0, Color("#fef08a"), true, -1.0, true)
				draw_circle(Vector2(win.position.x + 33.0, win.position.y + 23.0), 8.5, Color("#0f172a"), true, -1.0, true)
				for sp: Vector2 in [Vector2(66.0, 22.0), Vector2(80.0, 40.0), Vector2(54.0, 48.0), Vector2(22.0, 52.0)]:
					var br := 0.5 + sin(t * 3.0 + sp.x) * 0.45
					draw_circle(win.position + sp, 1.8, Color(1.0, 0.98, 0.80, br), true, -1.0, true)

		var col_marco := Color("#78350f") if es_premium else Color("#d97706")
		draw_rect(win, col_marco, false, 3.2)
		draw_line(Vector2(win.position.x + win.size.x * 0.5, win.position.y), Vector2(win.position.x + win.size.x * 0.5, win.end.y), col_marco, 2.2)
		draw_line(Vector2(win.position.x, win.position.y + win.size.y * 0.5), Vector2(win.end.x, win.position.y + win.size.y * 0.5), col_marco, 2.0)
		draw_rect(win, TINTA, false, 1.6)
		# Alféizar + macetita de hierbas aromáticas
		draw_rect(Rect2(win.position.x - 4.0, win.end.y - 2.0, win.size.x + 8.0, 6.0), col_marco)
		draw_rect(Rect2(win.position.x - 4.0, win.end.y - 2.0, win.size.x + 8.0, 6.0), TINTA, false, 1.4)
		var mx := win.position.x + 18.0
		var my := win.end.y - 2.0
		draw_rect(Rect2(mx - 6.0, my - 10.0, 12.0, 10.0), Color("#ea580c"))
		draw_rect(Rect2(mx - 6.0, my - 10.0, 12.0, 10.0), TINTA, false, 1.4)
		draw_circle(Vector2(mx - 3.0, my - 14.0), 5.0, Color("#22c55e"), true, -1.0, true)
		draw_circle(Vector2(mx + 4.0, my - 15.0), 4.8, Color("#16a34a"), true, -1.0, true)

		# Rayo de luz cálido o lámpara colgante nocturna
		if franja in ["manana", "tarde"]:
			var rayo := PackedVector2Array([
				Vector2(win.position.x + 10.0, win.position.y),
				Vector2(win.end.x, win.position.y),
				Vector2(win.end.x + 76.0, h - 46.0),
				Vector2(win.position.x + 44.0, h - 46.0),
			])
			draw_colored_polygon(rayo, Color(1.0, 0.97, 0.80, 0.14))
		elif franja == "noche":
			draw_circle(Vector2(cx, 26.0), 118.0, Color("#fde68a", 0.08), true, -1.0, true)
			draw_circle(Vector2(cx, 26.0), 70.0, Color("#fde68a", 0.10), true, -1.0, true)
			draw_line(Vector2(cx, 0.0), Vector2(cx, 12.0), TINTA, 2.2)
			var lamp := PackedVector2Array([
				Vector2(cx - 16.0, 18.0), Vector2(cx - 6.0, 10.0),
				Vector2(cx + 6.0, 10.0), Vector2(cx + 16.0, 18.0),
			])
			draw_colored_polygon(lamp, Color("#f59e0b") if es_premium else Color("#e2e8f0"))
			draw_polyline(lamp, TINTA, 1.8, true)

		# 3. Decoración en pared derecha
		if es_premium:
			var cua := Rect2(w - 108.0, 18.0, 76.0, 56.0)
			draw_rect(cua, Color("#fef9c3"))
			draw_rect(Rect2(cua.position.x + 5.0, cua.position.y + 5.0, cua.size.x - 10.0, cua.size.y - 10.0), Color("#ecfccb"))
			draw_line(Vector2(cua.get_center().x, cua.end.y - 12.0), Vector2(cua.get_center().x, cua.position.y + 18.0), Color("#15803d"), 2.2, true)
			draw_circle(cua.get_center() + Vector2(-7.0, -4.0), 6.0, Color("#22c55e"), true, -1.0, true)
			draw_circle(cua.get_center() + Vector2(7.0, 2.0), 5.5, Color("#16a34a"), true, -1.0, true)
			draw_circle(cua.get_center() + Vector2(0.0, -11.0), 5.0, Color("#4ade80"), true, -1.0, true)
			draw_rect(cua, Color("#b45309"), false, 3.2)
			draw_rect(cua, TINTA, false, 1.5)
		else:
			# Estante flotante de cocina con taza y tarros de especias
			var ex := w - 114.0
			var ey := 66.0
			draw_rect(Rect2(ex, ey, 88.0, 7.0), Color("#b45309"))
			draw_rect(Rect2(ex, ey, 88.0, 7.0), TINTA, false, 1.6)
			# Tarro 1
			draw_rect(Rect2(ex + 10.0, ey - 18.0, 14.0, 18.0), Color("#fca5a5"))
			draw_rect(Rect2(ex + 9.0, ey - 21.0, 16.0, 4.0), Color("#78350f"))
			draw_rect(Rect2(ex + 10.0, ey - 18.0, 14.0, 18.0), TINTA, false, 1.4)
			# Tarro 2
			draw_rect(Rect2(ex + 30.0, ey - 22.0, 14.0, 22.0), Color("#86efac"))
			draw_rect(Rect2(ex + 29.0, ey - 25.0, 16.0, 4.0), Color("#78350f"))
			draw_rect(Rect2(ex + 30.0, ey - 22.0, 14.0, 22.0), TINTA, false, 1.4)
			# Taza blanca con asa
			draw_rect(Rect2(ex + 54.0, ey - 16.0, 16.0, 16.0), Color.WHITE)
			draw_rect(Rect2(ex + 54.0, ey - 16.0, 16.0, 16.0), TINTA, false, 1.5)
			draw_arc(Vector2(ex + 70.0, ey - 8.0), 4.5, -PI * 0.5, PI * 0.5, 10, TINTA, 1.8, true)

		# 4. Respaldo de silla detrás del personaje
		if es_premium:
			var silla := Rect2(cx - 48.0, h - 102.0, 96.0, 62.0)
			draw_rect(silla, Color("#881337"))
			draw_rect(Rect2(silla.position.x + 6.0, silla.position.y + 6.0, silla.size.x - 12.0, silla.size.y - 12.0), Color("#9f1239"))
			draw_rect(silla, Color("#451a03"), false, 4.5)
			draw_rect(silla, TINTA, false, 2.0)
		else:
			var silla_b := Rect2(cx - 45.0, h - 98.0, 90.0, 58.0)
			draw_rect(Rect2(silla_b.position.x, silla_b.position.y, silla_b.size.x, 12.0), Color("#b45309"))
			draw_rect(Rect2(silla_b.position.x, silla_b.position.y, silla_b.size.x, 12.0), TINTA, false, 2.0)
			for lx: float in [-38.0, -14.0, 14.0, 38.0]:
				var bar := Rect2(cx + lx - 4.0, silla_b.position.y + 11.0, 8.0, 44.0)
				draw_rect(bar, Color("#92400e"))
				draw_rect(bar, TINTA, false, 1.6)

	func _fondo_comer_calle(w: float, h: float, cx: float, t: float, franja: String) -> void:
		var cielo := Color("#bae6fd")
		if franja == "atardecer":
			cielo = Color("#fdba74")
		elif franja == "noche":
			cielo = Color("#1e1b4b")
		draw_rect(Rect2(0.0, 0.0, w, h), cielo)
		if franja == "noche":
			for sp: Vector2 in [Vector2(56.0, 26.0), Vector2(130.0, 40.0), Vector2(w - 92.0, 32.0), Vector2(w - 44.0, 52.0)]:
				var br := 0.5 + sin(t * 3.2 + sp.x) * 0.45
				draw_circle(sp, 2.0, Color(1.0, 0.98, 0.80, br), true, -1.0, true)
		# Seto de parque y farola
		draw_rect(Rect2(0.0, h - 78.0, w, 40.0), Color("#166534") if franja == "noche" else Color("#4ade80"))
		draw_line(Vector2(0.0, h - 78.0), Vector2(w, h - 78.0), TINTA, 1.8)
		draw_line(Vector2(58.0, h - 46.0), Vector2(58.0, 20.0), Color("#334155"), 5.0)
		if franja in ["atardecer", "noche"]:
			draw_circle(Vector2(58.0, 22.0), 28.0, Color("#fef08a", 0.25), true, -1.0, true)
		draw_circle(Vector2(58.0, 22.0), 8.5, Color("#fef08a"), true, -1.0, true)
		draw_arc(Vector2(58.0, 22.0), 8.5, 0.0, TAU, 16, TINTA, 1.8, true)
		# Respaldo de banco de parque detrás del personaje
		for by: float in [h - 94.0, h - 76.0]:
			draw_rect(Rect2(cx - 86.0, by, 172.0, 13.0), Color("#92400e"))
			draw_rect(Rect2(cx - 86.0, by, 172.0, 13.0), TINTA, false, 1.8)

	func _fondo_duchar(w: float, h: float, t: float) -> void:
		# Pared de azulejos aguamarina
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#cffafe"))
		var col_linea := Color("#67e8f9", 0.55)
		var gx: float = 0.0
		while gx < w:
			draw_line(Vector2(gx, 0.0), Vector2(gx, h), col_linea, 1.4)
			gx += 36.0
		var gy: float = 0.0
		while gy < h:
			draw_line(Vector2(0.0, gy), Vector2(w, gy), col_linea, 1.4)
			gy += 36.0

		# Alcachofa de ducha cromada arriba a la izquierda
		draw_line(Vector2(0.0, 24.0), Vector2(68.0, 24.0), Color("#64748b"), 6.0, true)
		draw_line(Vector2(68.0, 24.0), Vector2(82.0, 38.0), Color("#64748b"), 6.0, true)
		var cabezal := PackedVector2Array([
			Vector2(70.0, 44.0), Vector2(96.0, 32.0), Vector2(106.0, 44.0), Vector2(80.0, 56.0),
		])
		draw_colored_polygon(cabezal, Color("#94a3b8"))
		draw_polyline(cabezal, TINTA, 2.2, true)

		# Chorros de agua animados desde la ducha
		var col_agua := Color("#0ea5e9", 0.65)
		for i in range(7):
			var off: float = fmod(t * 210.0 + float(i) * 32.0, 140.0)
			var sx: float = 84.0 + float(i) * 5.0 + off * 1.15
			var sy: float = 50.0 + off * 0.95
			draw_line(Vector2(sx, sy), Vector2(sx + 14.0, sy + 11.0), col_agua, 2.4, true)

	func _fondo_estudiar(w: float, h: float) -> void:
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#eff6ff"))
		# Estantería con libros de colores a la izquierda
		draw_rect(Rect2(24.0, 74.0, 118.0, 8.0), Color("#92400e"))
		var colores_lib := [Color("#ef4444"), Color("#3b82f6"), Color("#22c55e"), Color("#f59e0b"), Color("#8b5cf6")]
		for i in range(5):
			var lx: float = 32.0 + float(i) * 18.0
			var lh: float = 34.0 + float((i * 7) % 12)
			draw_rect(Rect2(lx, 74.0 - lh, 14.0, lh), colores_lib[i])
			draw_rect(Rect2(lx, 74.0 - lh, 14.0, lh), TINTA, false, 1.6)
		# Halo cálido de lámpara a la derecha
		draw_circle(Vector2(w - 78.0, 82.0), 54.0, Color("#fef08a", 0.45), true, -1.0, true)
		draw_line(Vector2(w - 42.0, h), Vector2(w - 58.0, 56.0), Color("#475569"), 4.5, true)
		var pantalla := PackedVector2Array([
			Vector2(w - 94.0, 68.0), Vector2(w - 64.0, 44.0), Vector2(w - 46.0, 56.0), Vector2(w - 76.0, 80.0),
		])
		draw_colored_polygon(pantalla, Color("#1d4ed8"))
		draw_polyline(pantalla, TINTA, 2.0, true)

	func _fondo_tv(w: float, h: float, t: float) -> void:
		# Salón acogedor con luz parpadeante de la tele
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#1e293b"))
		var pulso := 0.16 + sin(t * 7.5) * 0.05
		draw_circle(Vector2(w - 60.0, h - 30.0), 210.0, Color(_padre._color_canal_tv, pulso), true, -1.0, true)
		# Respaldo del sofá detrás del personaje
		var cx := w * 0.5
		draw_rect(Rect2(cx - 128.0, h - 96.0, 256.0, 96.0), Color("#166534"))
		draw_rect(Rect2(cx - 128.0, h - 96.0, 256.0, 96.0), TINTA, false, 2.8)
		draw_line(Vector2(cx, h - 96.0), Vector2(cx, h), Color("#14532d"), 2.4)

	func _fondo_manualidades(w: float, h: float) -> void:
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#fff7ed"))
		# Tablero perforado de taller a la izquierda
		var tab := Rect2(26.0, 20.0, 110.0, 84.0)
		draw_rect(tab, Color("#fed7aa"))
		draw_rect(tab, Color("#c2410c"), false, 2.4)
		for rx in range(4):
			for ry in range(3):
				draw_circle(Vector2(42.0 + float(rx) * 24.0, 38.0 + float(ry) * 24.0), 2.5, Color("#9a3412"), true, -1.0, true)
		# Lienzo a la derecha
		var lienzo := Rect2(w - 122.0, 22.0, 90.0, 98.0)
		draw_rect(lienzo, Color.WHITE)
		draw_circle(Vector2(w - 92.0, 56.0), 14.0, Color("#f43f5e", 0.75), true, -1.0, true)
		draw_circle(Vector2(w - 68.0, 72.0), 16.0, Color("#38bdf8", 0.75), true, -1.0, true)
		draw_rect(lienzo, TINTA, false, 2.4)

	func _fondo_cocinar(w: float, h: float, _t: float) -> void:
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#fffbeb"))
		var y_az := h - 88.0
		draw_rect(Rect2(0.0, y_az, w, 88.0), Color("#fef3c7"))
		var gx: float = 0.0
		while gx < w:
			draw_line(Vector2(gx, y_az), Vector2(gx, h), Color("#f59e0b", 0.25), 1.2)
			gx += 28.0
		# Campana extractora arriba en el centro
		var cx := w * 0.5
		var camp := PackedVector2Array([
			Vector2(cx - 56.0, 26.0), Vector2(cx + 56.0, 26.0),
			Vector2(cx + 28.0, 0.0), Vector2(cx - 28.0, 0.0),
		])
		draw_colored_polygon(camp, Color("#cbd5e1"))
		draw_polyline(camp, TINTA, 2.0, true)
		# Estante con sartenes colgadas
		draw_rect(Rect2(24.0, 44.0, 94.0, 6.0), Color("#b45309"))
		draw_circle(Vector2(w - 62.0, 44.0), 18.0, Color("#475569"), true, -1.0, true)
		draw_arc(Vector2(w - 62.0, 44.0), 18.0, 0.0, TAU, 18, TINTA, 2.0, true)

	func _fondo_fiesta(w: float, h: float, t: float) -> void:
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#1e1b4b"))
		# Focos de colores animándose
		var cols_f := [Color("#ec4899", 0.24), Color("#38bdf8", 0.22), Color("#a855f7", 0.24)]
		for i in range(3):
			var lx := w * (0.2 + float(i) * 0.3) + sin(t * 2.4 + float(i) * 2.0) * 32.0
			var haz := PackedVector2Array([
				Vector2(w * (0.2 + float(i) * 0.3), 0.0),
				Vector2(lx - 48.0, h),
				Vector2(lx + 48.0, h),
			])
			draw_colored_polygon(haz, cols_f[i])
		# Bola de discoteca
		var cx := w * 0.5
		draw_line(Vector2(cx, 0.0), Vector2(cx, 18.0), Color("#cbd5e1"), 2.0)
		draw_circle(Vector2(cx, 28.0), 14.0, Color("#e2e8f0"), true, -1.0, true)
		draw_arc(Vector2(cx, 28.0), 14.0, 0.0, TAU, 18, TINTA, 2.0, true)
		# Pista de baile
		draw_rect(Rect2(0.0, h - 34.0, w, 34.0), Color("#312e81"))
		draw_line(Vector2(0.0, h - 34.0), Vector2(w, h - 34.0), TINTA, 2.2)

	func _fondo_futbol(w: float, h: float, t: float) -> void:
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#bae6fd"))
		# Gradas sutiles al fondo
		draw_rect(Rect2(0.0, h - 76.0, w, 34.0), Color("#475569"))
		# Césped del campo
		draw_rect(Rect2(0.0, h - 44.0, w, 44.0), Color("#22c55e"))
		var sx: float = 0.0
		while sx < w:
			draw_rect(Rect2(sx, h - 44.0, 36.0, 44.0), Color("#16a34a", 0.35))
			sx += 72.0
		draw_line(Vector2(0.0, h - 44.0), Vector2(w, h - 44.0), Color.WHITE, 2.4)
		# Portería a la derecha
		draw_rect(Rect2(w - 72.0, h - 104.0, 56.0, 60.0), Color(1.0, 1.0, 1.0, 0.25))
		draw_polyline(PackedVector2Array([
			Vector2(w - 72.0, h - 44.0), Vector2(w - 72.0, h - 104.0), Vector2(w - 16.0, h - 104.0), Vector2(w - 16.0, h - 44.0),
		]), Color.WHITE, 3.2, true)
		var nube_x: float = 54.0 + sin(t * 0.45) * 14.0
		draw_circle(Vector2(nube_x, 34.0), 14.0, Color.WHITE, true, -1.0, true)
		draw_circle(Vector2(nube_x + 16.0, 34.0), 11.0, Color.WHITE, true, -1.0, true)

	func _fondo_trabajar(w: float, h: float) -> void:
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#f1f5f9"))
		# Ventanal moderno de oficina/local
		var win := Rect2(28.0, 18.0, 136.0, 80.0)
		draw_rect(win, Color("#dbeafe"))
		draw_rect(Rect2(44.0, 58.0, 24.0, 40.0), Color("#93c5fd"))
		draw_rect(Rect2(78.0, 42.0, 30.0, 56.0), Color("#60a5fa"))
		draw_rect(Rect2(116.0, 64.0, 26.0, 34.0), Color("#93c5fd"))
		draw_rect(win, Color("#475569"), false, 2.6)
		# Reloj de pared a la derecha
		var rc := Vector2(w - 66.0, 50.0)
		draw_circle(rc, 22.0, Color.WHITE, true, -1.0, true)
		draw_arc(rc, 22.0, 0.0, TAU, 24, TINTA, 2.4, true)
		draw_line(rc, rc + Vector2(0.0, -13.0), TINTA, 2.2, true)
		draw_line(rc, rc + Vector2(10.0, 4.0), Color("#dc2626"), 2.0, true)

	func _fondo_idle(w: float, h: float, t: float) -> void:
		if _padre._en_la_calle:
			_fondo_idle_calle(w, h, t)
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

	func _fondo_idle_calle(w: float, h: float, t: float) -> void:
		var franja: String = _padre._franja_horaria()
		var cielo := Color("#b7dcf3")
		if franja == "atardecer":
			cielo = Color("#f6c08b")
		elif franja == "noche":
			cielo = Color("#242a4a")
		draw_rect(Rect2(0.0, 0.0, w, h), cielo)
		# Estrellas tenues de noche.
		if franja == "noche":
			for sp: Vector2 in [Vector2(w * 0.16, h * 0.16), Vector2(w * 0.32, h * 0.10), Vector2(w * 0.72, h * 0.18), Vector2(w * 0.88, h * 0.12)]:
				var br: float = 0.45 + sin(t * 2.6 + sp.x) * 0.35
				draw_circle(sp, 1.5, Color(1.0, 0.98, 0.82, br), true, -1.0, true)
		# Skyline lejano.
		var col_edif := Color("#8ea6ba") if franja != "noche" else Color("#333b5e")
		var x_edif: float = 0.0
		var idx := 0
		while x_edif < w:
			var ancho := 36.0 + float((idx * 29) % 54)
			var alto := h * (0.16 + float((idx * 17) % 18) * 0.010)
			draw_rect(Rect2(x_edif, h * 0.58 - alto, ancho, alto), col_edif)
			if franja == "noche":
				for vy in range(3):
					draw_rect(Rect2(x_edif + 8.0 + float(vy) * 10.0, h * 0.58 - alto + 8.0 + float(vy) * 12.0, 3.0, 4.0), Color("#fde68a", 0.55))
			x_edif += ancho + 9.0
			idx += 1
		# Acerado y bordillo.
		draw_rect(Rect2(0.0, h * 0.58, w, h * 0.42), Color("#cfd4d8"))
		draw_rect(Rect2(0.0, h * 0.58, w, maxf(2.0, h * 0.012)), Color("#aeb6bd"))
		draw_rect(Rect2(0.0, h * 0.78, w, h * 0.22), Color("#8f989f"))
		draw_line(Vector2(0.0, h * 0.78), Vector2(w, h * 0.78), Color("#727c84"), 1.6)
		# Farola.
		var lx: float = clampf(w * 0.12, 24.0, 90.0)
		draw_line(Vector2(lx, h * 0.78), Vector2(lx, h * 0.20), Color("#3f4b57"), maxf(3.0, h * 0.024))
		draw_line(Vector2(lx, h * 0.20), Vector2(lx + maxf(12.0, h * 0.070), h * 0.20), Color("#3f4b57"), maxf(2.0, h * 0.016))
		draw_circle(Vector2(lx + maxf(12.0, h * 0.070), h * 0.225), maxf(4.0, h * 0.024), Color("#fef08a"), true, -1.0, true)
		if franja in ["atardecer", "noche"]:
			draw_circle(Vector2(lx + maxf(12.0, h * 0.070), h * 0.225), maxf(12.0, h * 0.10), Color(1.0, 0.94, 0.65, 0.16), true, -1.0, true)
		# Banco público detrás del personaje, con patas y sombra de contacto.
		var y_banco: float = h * 0.63
		for i in range(2):
			draw_rect(Rect2(w * 0.30, y_banco + float(i) * h * 0.045, w * 0.40, maxf(4.0, h * 0.025)), Color("#8a5a32"))
			draw_line(Vector2(w * 0.30, y_banco + float(i) * h * 0.045), Vector2(w * 0.70, y_banco + float(i) * h * 0.045), Color("#5c3a1e"), 1.2)
		for lx_pata: float in [w * 0.33, w * 0.67]:
			draw_rect(Rect2(lx_pata, y_banco + h * 0.09, maxf(3.0, w * 0.010), h * 0.09), Color("#5c3a1e"))
		draw_rect(Rect2(w * 0.30, y_banco + h * 0.17, w * 0.40, maxf(2.0, h * 0.010)), Color(0.18, 0.12, 0.07, 0.16))
		# Seto y maceta urbana a la derecha.
		draw_rect(Rect2(w * 0.82, h * 0.58, w * 0.18, h * 0.20), Color("#4f8b45"))
		draw_circle(Vector2(w * 0.88, h * 0.58), h * 0.08, Color("#5a9a4f"), true, -1.0, true)
		draw_circle(Vector2(w * 0.95, h * 0.60), h * 0.07, Color("#4a8742"), true, -1.0, true)


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

		# 7. Cintas suaves de vapor cálido subiendo desde el plato
		var op_vapor: float = 0.62 if _padre._variacion_activa == "oler" else 0.42
		_dibujar_vapor_ondulado(centro_plato + Vector2(0.0, -8.0), t, op_vapor)

	func _dibujar_superficie_mesa(w: float, h: float, cx: float, y_mesa: float, es_calle: bool, es_premium: bool, t: float) -> void:
		var y_borde := h - 13.0
		if es_calle:
			# Mesa de picnic / madera desgastada exterior
			draw_rect(Rect2(0.0, y_mesa, w, y_borde - y_mesa), Color("#b45309"))
			draw_rect(Rect2(0.0, y_borde, w, h - y_borde), Color("#78350f"))
			draw_line(Vector2(0.0, y_mesa + 11.0), Vector2(w, y_mesa + 11.0), Color("#78350f", 0.55), 1.6)
			draw_line(Vector2(0.0, y_mesa + 23.0), Vector2(w, y_mesa + 23.0), Color("#78350f", 0.55), 1.6)
			draw_line(Vector2(0.0, y_mesa), Vector2(w, y_mesa), TINTA, 2.4)
			draw_line(Vector2(0.0, y_borde), Vector2(w, y_borde), TINTA, 2.0)
			return

		if es_premium:
			# Mesa de nogal oscuro + camino de mesa crema con ribete dorado + velita parpadeante
			draw_rect(Rect2(0.0, y_mesa, w, y_borde - y_mesa), Color("#5c2d16"))
			draw_rect(Rect2(0.0, y_borde, w, h - y_borde), Color("#3b1a0a"))
			draw_line(Vector2(0.0, y_mesa), Vector2(w, y_mesa), TINTA, 2.4)
			draw_line(Vector2(0.0, y_borde), Vector2(w, y_borde), TINTA, 2.0)
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
			draw_line(Vector2(0.0, y_mesa), Vector2(w, y_mesa), TINTA, 2.4)
			draw_line(Vector2(0.0, y_borde), Vector2(w, y_borde), TINTA, 2.0)
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

		match pose:
			"correr":
				_frente_correr(w, h, cx, t, variacion)
			"dormir":
				_frente_dormir(w, h, cx, t, variacion)
			"comer":
				_frente_comer(w, h, cx, t, variacion)
			"duchar":
				_frente_duchar(w, h, cx, t, variacion)
			"estudiar":
				_frente_estudiar(w, h, cx, t, variacion)
			"tv":
				_frente_tv(w, h, cx, t, variacion)
			"manualidades":
				_frente_manualidades(w, h, cx, t, variacion)
			"cocinar":
				_frente_cocinar(w, h, cx, t, variacion)
			"fiesta":
				_frente_fiesta(w, h, cx, t, variacion)
			"futbol":
				_frente_futbol(w, h, cx, t, variacion)
			"trabajar":
				_frente_trabajar(w, h, cx, t, variacion)
			_:
				_frente_idle(w, h, cx, t, variacion)

	func _frente_correr(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		# Nubes de polvo detrás de las zapatillas
		for i in range(3):
			var p: float = fmod(t * 2.4 + float(i) * 0.33, 1.0)
			var dx: float = cx - 22.0 - p * 68.0
			var dy: float = h - 22.0 - sin(p * PI) * 12.0
			var rad: float = (1.0 - p) * 9.0 + 2.0
			draw_circle(Vector2(dx, dy), rad, Color(0.95, 0.96, 0.98, (1.0 - p) * 0.72), true, -1.0, true)

		# Líneas cinéticas de velocidad en sprint
		if variacion == "sprint":
			for i in range(6):
				var lx: float = w - fmod(t * 480.0 + float(i) * 115.0, w + 90.0)
				var ly: float = 24.0 + float(i) * 26.0
				draw_line(Vector2(lx, ly), Vector2(lx + 52.0, ly), Color(1.0, 1.0, 1.0, 0.72), 2.6, true)

	func _frente_dormir(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		# Manta mullida cubriendo el pecho, subiendo y bajando suavemente con la respiración
		var resp: float = sin(t * (3.8 if variacion == "roncar" else 1.9)) * 2.5
		var y_manta: float = h - 54.0 + resp
		draw_rect(Rect2(cx - 114.0, y_manta, 228.0, h - y_manta + 4.0), Color("#3b82f6"))
		draw_rect(Rect2(cx - 114.0, y_manta, 228.0, 14.0), Color("#dbeafe"))
		draw_rect(Rect2(cx - 114.0, y_manta, 228.0, h - y_manta + 4.0), TINTA, false, 2.6)
		draw_line(Vector2(cx - 114.0, y_manta + 14.0), Vector2(cx + 114.0, y_manta + 14.0), TINTA, 2.0)

		# Letras Zzz flotantes (más grandes y temblorosas al roncar)
		var cant: int = 3
		for i in range(cant):
			var p: float = fmod(t * 0.55 + float(i) * 0.33, 1.0)
			var zx: float = cx + 44.0 + p * 34.0 + sin(t * 3.0 + float(i)) * 5.0
			var zy: float = h - 102.0 - p * 64.0
			var tam_z: int = int(14.0 + p * (14.0 if variacion == "roncar" else 8.0))
			var col_z := Color("#fde047" if variacion == "roncar" else "#e0e7ff", (1.0 - p) * 0.95)
			draw_string(FUENTE_COMIC, Vector2(zx, zy), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, tam_z, col_z)

		# Globo de sueño al soñar
		if variacion == "sonar":
			draw_circle(Vector2(cx + 52.0, 82.0), 4.5, Color.WHITE, true, -1.0, true)
			draw_circle(Vector2(cx + 64.0, 68.0), 7.0, Color.WHITE, true, -1.0, true)
			var nc := Vector2(cx + 96.0, 42.0)
			draw_circle(nc, 22.0, Color.WHITE, true, -1.0, true)
			draw_circle(nc + Vector2(-16.0, 4.0), 14.0, Color.WHITE, true, -1.0, true)
			draw_circle(nc + Vector2(16.0, 4.0), 14.0, Color.WHITE, true, -1.0, true)
			draw_arc(nc, 22.0, 0.0, TAU, 24, TINTA, 2.0, true)
			if _padre._icono_sueno == 0:
				draw_string(FUENTE_COMIC, nc + Vector2(-8.0, 8.0), "€", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#eab308"))
			elif _padre._icono_sueno == 1:
				_dibujar_estrella(nc, 11.0, Color("#f59e0b"))
			else:
				_dibujar_corazon(nc, 9.5, Color("#e11d48"))

	func _frente_comer(_w: float, h: float, cx: float, t: float, variacion: String) -> void:
		if _padre._personaje == null:
			return
		var fase: float = clampf(_padre._tiempo_variacion / maxf(0.1, _padre._duracion_variacion), 0.0, 1.0)
		var pos_boca := _padre._personaje.obtener_punto_local_a_escena(Vector2(1.0, 21.0))

		if variacion == "":
			# Pequeñas miguitas y destello sutil en el instante exacto del bocado
			var c: float = _padre._personaje.obtener_ciclo_comer(t)
			if c >= 0.45 and c <= 0.62:
				var p := (c - 0.45) / 0.17
				var col_m := _padre._personaje.color_bocado
				for k in range(3):
					var dir_x := -1.0 + float(k) * 1.15
					var mx := pos_boca.x + dir_x * (6.0 + p * 14.0)
					var my := pos_boca.y + 4.0 + p * p * 18.0 - (1.0 - p) * 3.0 * float(k % 2)
					draw_circle(Vector2(mx, my), (1.0 - p) * 2.4 + 0.6, Color(col_m, (1.0 - p) * 0.9), true, -1.0, true)
			return

		match variacion:
			"delicioso":
				# Destellos dorados + corazoncitos subiendo alrededor del rostro feliz
				var env := sin(fase * PI)
				var offs: Array[Vector2] = [Vector2(-62.0, -34.0), Vector2(62.0, -40.0), Vector2(-54.0, 4.0), Vector2(68.0, -6.0)]
				for idx in range(4):
					var p_est: Vector2 = Vector2(cx, h * 0.46) + offs[idx]
					var r_est: float = (4.5 + sin(t * 9.0 + float(idx) * 1.7) * 2.4) * env
					if r_est > 0.8:
						_dibujar_estrella(p_est, r_est, Color("#facc15", env))
				for i in range(2):
					var ph := fmod(fase * 1.4 + float(i) * 0.48, 1.0)
					var hx := cx + (-48.0 if i == 0 else 48.0) + sin(t * 4.5 + float(i) * 2.0) * 6.0
					var hy := 74.0 - ph * 42.0
					var ah := sin(ph * PI) * 0.92
					if ah > 0.05:
						_dibujar_corazon(Vector2(hx, hy), 5.5 + ph * 2.0, Color("#fb7185", ah))

			"soplar":
				# Vapor caliente saliendo directamente del bocado en la punta del tenedor
				var punta := _padre._personaje.obtener_punta_tenedor_escena()
				if fase < 0.78:
					var calor := 1.0 - clampf((fase - 0.16) / 0.58, 0.0, 0.92)
					# Halo cálido alrededor del bocado ardiente
					draw_circle(punta, 9.0 + sin(t * 14.0) * 1.5, Color("#fb923c", 0.24 * calor), true, -1.0, true)
					var empuje := 0.0
					if fase >= 0.18 and fase <= 0.70:
						var u := (fase - 0.18) / 0.52
						empuje = maxf(0.0, sin(u * PI * 2.0))
					for i in range(3):
						var pv := fmod(t * 1.6 + float(i) * 0.33, 1.0)
						var pts_v := PackedVector2Array()
						for s in range(5):
							var sv := float(s) / 4.0
							var vx := punta.x - 4.0 + float(i) * 4.0 + empuje * sv * 18.0 + sin(sv * PI * 2.0 + t * 8.0 + float(i)) * 2.5
							var vy := punta.y - 4.0 - pv * 6.0 - sv * (18.0 - empuje * 6.0)
							pts_v.append(Vector2(vx, vy))
						draw_polyline(pts_v, Color(1.0, 0.96, 0.90, (1.0 - pv) * 0.75 * calor), 2.0, true)

				# 2 ráfagas curvas de viento desde la boca directamente hacia el bocado
				if fase >= 0.18 and fase <= 0.68:
					var u := (fase - 0.18) / 0.50
					var ciclo_raf := fmod(u * 2.0, 1.0)
					var dir_v := (punta - pos_boca).normalized()
					var perp_v := Vector2(-dir_v.y, dir_v.x)
					var dist_tot := pos_boca.distance_to(punta)
					for i in range(-1, 2):
						var inicio := pos_boca + dir_v * (4.0 + ciclo_raf * (dist_tot * 0.45)) + perp_v * float(i) * 4.2
						var fin := inicio + dir_v * (12.0 + (1.0 - ciclo_raf) * 6.0) + perp_v * float(i) * 2.2
						var medio := (inicio + fin) * 0.5 + perp_v * (sin(ciclo_raf * PI) * 2.5 * float(i))
						var alpha_w := sin(ciclo_raf * PI) * 0.88
						if alpha_w > 0.05:
							draw_polyline(PackedVector2Array([inicio, medio, fin]), Color(1.0, 1.0, 1.0, alpha_w), 2.2, true)
							if i == 0 and ciclo_raf > 0.45:
								draw_arc(fin + Vector2(2.0, -2.0), 3.6, -PI * 0.6, PI * 0.9, 10, Color(1.0, 1.0, 1.0, alpha_w * 0.8), 1.8, true)

			"limpiar_boca":
				# Destello de limpieza justo al borrar la manchita de salsa
				if fase >= 0.52 and fase <= 0.82:
					var p := (fase - 0.52) / 0.30
					var r_br := sin(p * PI) * 7.5
					var p_br := pos_boca + Vector2(-13.0, 2.0)
					if r_br > 0.6:
						_dibujar_estrella(p_br, r_br, Color("#fef08a", sin(p * PI)))
						_dibujar_estrella(p_br + Vector2(-8.0, -7.0), r_br * 0.55, Color.WHITE)

			"oler":
				# Cintas aromáticas sinuosas subiendo desde el plato hasta la nariz
				var pos_nariz := _padre._personaje.obtener_punto_local_a_escena(Vector2(0.0, 10.0))
				var env_o := sin(fase * PI)
				for i in range(3):
					var p_a := fmod(t * 0.72 + float(i) * 0.33, 1.0)
					var origen_a := Vector2(cx - 14.0 + float(i) * 14.0, h - 38.0)
					var pts_a := PackedVector2Array()
					for s in range(9):
						var u := float(s) / 8.0
						var base_pt := origen_a.lerp(pos_nariz + Vector2(float(i - 1) * 9.0, 4.0), clampf(u * 0.75 + p_a * 0.25, 0.0, 1.0))
						var onda := sin(u * PI * 2.5 + t * 4.2 + float(i) * 2.1) * (5.5 * sin(u * PI))
						pts_a.append(base_pt + Vector2(onda, 0.0))
					var alpha_a := sin(p_a * PI) * env_o * 0.78
					if alpha_a > 0.04:
						draw_polyline(pts_a, Color("#fef3c7", alpha_a), 2.8, true)

			"beber":
				# Destellitos refrescantes al terminar el sorbo
				if fase >= 0.84:
					var p_ref := (fase - 0.84) / 0.16
					var r_ref := sin(p_ref * PI) * 6.0
					if r_ref > 0.5:
						_dibujar_estrella(Vector2(cx + 46.0, 62.0), r_ref, Color("#38bdf8", sin(p_ref * PI)))
						_dibujar_estrella(Vector2(cx + 58.0, 76.0), r_ref * 0.65, Color("#fde047", sin(p_ref * PI)))

	func _frente_duchar(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		# Cortina de espuma y vapor en la parte baja para cubrir el torso
		var y_esp := h - 32.0
		var bx: float = 0.0
		while bx <= w + 24.0:
			var r_b: float = 22.0 + sin(bx * 0.08 + t * 2.0) * 4.0
			draw_circle(Vector2(bx, y_esp + 12.0), r_b, Color("#f8fafc"), true, -1.0, true)
			draw_arc(Vector2(bx, y_esp + 12.0), r_b, PI, TAU, 14, Color("#94a3b8", 0.55), 1.6, true)
			bx += 28.0
		draw_rect(Rect2(0.0, y_esp + 12.0, w, 30.0), Color("#f8fafc"))

		# Pompas de jabón flotando
		for i in range(6):
			var p: float = fmod(t * 0.45 + float(i) * 0.17, 1.0)
			var px: float = cx - 95.0 + float(i) * 38.0 + sin(t * 2.8 + float(i)) * 10.0
			var py: float = h - 36.0 - p * (h - 24.0)
			var rad: float = 5.5 + float(i % 3) * 2.5
			draw_circle(Vector2(px, py), rad, Color(0.88, 0.97, 1.0, 0.42), true, -1.0, true)
			draw_arc(Vector2(px, py), rad, 0.0, TAU, 16, Color.WHITE, 1.6, true)

		# Notas musicales al cantar en la ducha
		if variacion == "cantar":
			var cols: Array[Color] = [Color("#ec4899"), Color("#8b5cf6"), Color("#0284c7")]
			for i in range(3):
				var p: float = fmod(t * 0.85 + float(i) * 0.33, 1.0)
				var nx: float = cx + 46.0 + p * 54.0 + sin(t * 5.0 + float(i)) * 8.0
				var ny: float = 94.0 - p * 66.0
				_dibujar_nota_musical(Vector2(nx, ny), Color(cols[i], 1.0 - p))
		elif variacion == "agua_fria":
			# Líneas de escalofrío
			for lado: float in [-1.0, 1.0]:
				var sx: float = cx + lado * 66.0 + sin(t * 32.0) * 3.0
				draw_line(Vector2(sx, 54.0), Vector2(sx + lado * 8.0, 68.0), Color("#0284c7"), 2.4, true)
				draw_line(Vector2(sx + lado * 8.0, 68.0), Vector2(sx, 82.0), Color("#0284c7"), 2.4, true)
		elif variacion == "burbuja_gigante":
			var fase: float = clampf(_padre._tiempo_variacion / maxf(0.1, _padre._duracion_variacion), 0.0, 1.0)
			var bc := Vector2(cx + 58.0 + fase * 50.0, 112.0 - fase * 62.0)
			if fase < 0.82:
				var r_g: float = 10.0 + fase * 20.0
				draw_circle(bc, r_g, Color(0.80, 0.96, 1.0, 0.38), true, -1.0, true)
				draw_arc(bc, r_g, 0.0, TAU, 24, Color.WHITE, 2.2, true)
				draw_circle(bc + Vector2(-r_g * 0.35, -r_g * 0.35), r_g * 0.22, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)
			else:
				for k in range(6):
					var ang: float = TAU * float(k) / 6.0
					var p0 := bc + Vector2(cos(ang), sin(ang)) * 16.0
					var p1 := bc + Vector2(cos(ang), sin(ang)) * 28.0
					draw_line(p0, p1, Color.WHITE, 2.2, true)

	func _frente_estudiar(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		# Escritorio y libro abierto
		var y_m := h - 42.0
		draw_rect(Rect2(0.0, y_m, w, 42.0), Color("#d6d3d1"))
		draw_line(Vector2(0.0, y_m), Vector2(w, y_m), TINTA, 2.4)
		# Libro abierto
		var izq := PackedVector2Array([Vector2(cx - 52.0, y_m + 6.0), Vector2(cx, y_m + 12.0), Vector2(cx, y_m + 34.0), Vector2(cx - 56.0, y_m + 28.0)])
		var der := PackedVector2Array([Vector2(cx, y_m + 12.0), Vector2(cx + 52.0, y_m + 6.0), Vector2(cx + 56.0, y_m + 28.0), Vector2(cx, y_m + 34.0)])
		draw_colored_polygon(izq, Color.WHITE)
		draw_colored_polygon(der, Color("#f8fafc"))
		draw_polyline(izq, TINTA, 2.0, true)
		draw_polyline(der, TINTA, 2.0, true)

		if variacion == "bombilla":
			var bc := Vector2(cx + 66.0, 44.0)
			var pulso := 20.0 + sin(t * 10.0) * 3.0
			draw_circle(bc, pulso, Color("#fde047", 0.38), true, -1.0, true)
			draw_circle(bc, 12.0, Color("#fde047"), true, -1.0, true)
			draw_arc(bc, 12.0, 0.0, TAU, 20, TINTA, 2.2, true)
			draw_rect(Rect2(bc.x - 5.0, bc.y + 11.0, 10.0, 7.0), Color("#94a3b8"))
			draw_rect(Rect2(bc.x - 5.0, bc.y + 11.0, 10.0, 7.0), TINTA, false, 1.8)
		elif variacion == "pensar":
			for i in range(3):
				var alpha_d := 0.35 + (sin(t * 5.0 - float(i) * 1.1) * 0.5 + 0.5) * 0.65
				draw_circle(Vector2(cx + 56.0 + float(i) * 12.0, 48.0), 4.0, Color(0.28, 0.34, 0.45, alpha_d), true, -1.0, true)

	func _frente_tv(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		# Cubo de palomitas a la izquierda
		var bx := cx - 96.0
		var by := h - 48.0
		var cubo := PackedVector2Array([Vector2(bx - 16.0, by), Vector2(bx + 16.0, by), Vector2(bx + 12.0, by + 38.0), Vector2(bx - 12.0, by + 38.0)])
		draw_colored_polygon(cubo, Color("#ef4444"))
		draw_rect(Rect2(bx - 5.0, by, 10.0, 38.0), Color.WHITE)
		draw_polyline(cubo, TINTA, 2.0, true)
		for dx: float in [-9.0, 0.0, 9.0]:
			draw_circle(Vector2(bx + dx, by - 3.0), 6.5, Color("#fef08a"), true, -1.0, true)

		# Esquina brillante de la pantalla de TV abajo a la derecha
		var tv_glow := Color(_padre._color_canal_tv, 0.25 + sin(t * 8.0) * 0.07)
		draw_colored_polygon(PackedVector2Array([Vector2(w - 78.0, h), Vector2(w, h - 56.0), Vector2(w, h)]), tv_glow)

		if variacion == "reir":
			var y_r: float = 52.0 - sin(t * 10.0) * 4.0
			draw_string(FUENTE_COMIC, Vector2(cx + 52.0, y_r), "¡JAJA!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fde047"))

	func _frente_manualidades(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		var y_m := h - 40.0
		draw_rect(Rect2(0.0, y_m, w, 40.0), Color("#d97706"))
		draw_line(Vector2(0.0, y_m), Vector2(w, y_m), TINTA, 2.4)
		# Botes de pintura
		var cols := [Color("#ef4444"), Color("#3b82f6"), Color("#facc15")]
		for i in range(3):
			var px: float = cx - 98.0 + float(i) * 26.0
			draw_rect(Rect2(px, y_m - 16.0, 18.0, 22.0), cols[i])
			draw_rect(Rect2(px, y_m - 16.0, 18.0, 22.0), TINTA, false, 1.8)
		if variacion in ["pincelada_rapida", "admirar"]:
			for i in range(3):
				var p: Vector2 = Vector2(cx + 54.0 + float(i) * 16.0, 54.0 + float(i % 2) * 24.0)
				_dibujar_estrella(p, 5.0 + sin(t * 9.0 + float(i)) * 2.0, cols[i])

	func _frente_cocinar(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		var y_m := h - 42.0
		draw_rect(Rect2(0.0, y_m, w, 42.0), Color("#d97706"))
		draw_line(Vector2(0.0, y_m), Vector2(w, y_m), TINTA, 2.4)
		# Sartén delante sobre fogón
		draw_rect(Rect2(cx - 38.0, y_m - 6.0, 76.0, 12.0), Color("#334155"))
		draw_rect(Rect2(cx - 38.0, y_m - 6.0, 76.0, 12.0), TINTA, false, 2.0)
		draw_line(Vector2(cx - 38.0, y_m), Vector2(cx - 64.0, y_m - 5.0), TINTA, 4.5, true)
		var pulso := 1.0 + sin(t * 10.0) * 0.25
		for i in range(3):
			var p: float = fmod(t * 0.9 + float(i) * 0.33, 1.0)
			draw_circle(Vector2(cx - 12.0 + float(i) * 12.0 + sin(t * 4.0 + float(i)) * 4.0, y_m - 12.0 - p * 34.0), 4.0 * pulso * (1.0 - p * 0.5), Color(1.0, 1.0, 1.0, (1.0 - p) * 0.7), true, -1.0, true)
		if variacion == "saltear":
			for k in range(3):
				var p_s := fmod(t * 2.2 + float(k) * 0.3, 1.0)
				draw_circle(Vector2(cx - 10.0 + float(k) * 10.0, y_m - 10.0 - sin(p_s * PI) * 28.0), 4.5, Color("#f59e0b"), true, -1.0, true)

	func _frente_fiesta(_w: float, _h: float, cx: float, t: float, _variacion: String) -> void:
		var cols := [Color("#f43f5e"), Color("#38bdf8"), Color("#fde047")]
		for i in range(3):
			var p: float = fmod(t * 0.75 + float(i) * 0.33, 1.0)
			var nx: float = cx + (-68.0 if i % 2 == 0 else 64.0) + sin(t * 4.0 + float(i)) * 8.0
			var ny: float = 96.0 - p * 56.0
			_dibujar_nota_musical(Vector2(nx, ny), Color(cols[i], 1.0 - p))

	func _frente_futbol(_w: float, h: float, cx: float, t: float, variacion: String) -> void:
		var bote := absf(sin(t * 6.5)) * 22.0
		var bx := cx + 38.0 + (sin(t * 3.0) * 16.0 if variacion == "toques" else 0.0)
		var by := h - 22.0 - bote
		draw_circle(Vector2(bx, by), 11.0, Color.WHITE, true, -1.0, true)
		draw_circle(Vector2(bx, by), 4.2, TINTA, true, -1.0, true)
		draw_arc(Vector2(bx, by), 11.0, 0.0, TAU, 18, TINTA, 2.0, true)
		if variacion == "celebrar_gol":
			_dibujar_estrella(Vector2(cx - 58.0, 44.0), 8.0 + sin(t * 10.0) * 2.0, Color("#facc15"))
			_dibujar_estrella(Vector2(cx + 62.0, 50.0), 7.0 + cos(t * 10.0) * 2.0, Color("#facc15"))

	func _frente_trabajar(w: float, h: float, cx: float, t: float, variacion: String) -> void:
		var y_m := h - 40.0
		draw_rect(Rect2(0.0, y_m, w, 40.0), Color("#cbd5e1"))
		draw_line(Vector2(0.0, y_m), Vector2(w, y_m), TINTA, 2.4)
		# Portátil visto desde atrás delante del personaje
		var lap := Rect2(cx - 42.0, y_m - 14.0, 84.0, 44.0)
		draw_rect(lap, Color("#475569"))
		draw_rect(lap, TINTA, false, 2.2)
		draw_circle(lap.get_center(), 5.5, Color("#e2e8f0"), true, -1.0, true)

		if variacion == "ganar_dinero":
			for i in range(3):
				var p: float = fmod(t * 0.9 + float(i) * 0.33, 1.0)
				var ex: float = cx + 48.0 + float(i) * 16.0
				var ey: float = 96.0 - p * 60.0
				draw_string(FUENTE_COMIC, Vector2(ex, ey), "€", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#16a34a", 1.0 - p))

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
