
extends Node

# Called when the node enters the scene tree for the first time.



const TUTORIAL_INICIAL := preload("res://Scripts/GUI/Escena_Principal/Tutorial_Inicial.gd")
const _MODAL_TUPPERS_SCRIPT := preload("res://Scripts/GUI/Escena_Principal/Tuppers/Modal_Tuppers.gd")
const _PANEL_FUTBOL_ESCENA := preload("res://Escenas/Escena_Principal/Panel_Futbol.tscn")
const _PANEL_MANAGER_ESCENA := preload("res://Escenas/Escena_Principal/Panel_Manager.tscn")

var mirar_semana
var calendario_solo_lectura: bool = false

# Actividad elegida en el catálogo que se está programando en el selector de horario.
var actividad_seleccionada: String = ""

var horario_bloque

# Duración sugerida (en minutos) al abrir el selector de horario tras elegir
# una actividad. El jugador puede ajustar inicio y final libremente.
const DURACIONES_PREDETERMINADAS := {
	"Dormir": 480,
	"Cocinar": 30,
	"Comer_Tupper": 30,
	"Comer_Basura": 30,
	"Duchar": 30,
	"Ver_La_Television": 60,
	"Estudiar": 120,
	"Salir_A_Correr": 60,
	"Practicar_Manualidades": 120,
	"Salir_De_Fiesta": 180,
}

const NOMBRES_VISIBLES_ACTIVIDADES := {
	"Dormir": "Dormir",
	"Duchar": "Duchar",
	"Cocinar": "Cocinar",
	"Comer_Tupper": "Comida casera",
	"Comer_Basura": "Comida rápida",
	"Ver_La_Television": "Ver la televisión",
	"Estudiar": "Estudiar",
	"Salir_A_Correr": "Salir a correr",
	"Practicar_Manualidades": "Manualidades",
	"Salir_De_Fiesta": "Salir de fiesta",
}

# Hora de inicio propuesta al programar en una semana futura (minutos del día).
const HORA_INICIO_GENERICA := 540 # 09:00
const HORAS_INICIO_PREDETERMINADAS := {
	"Dormir": 1320, # 22:00
	"Salir_De_Fiesta": 1080, # 18:00
}

var actividades_reloj_gui
var actividades_bloque_gui
var necesidades_basicas_gui

var first_time_logica

var seleccionar_horario_activo: bool = false
# Flujo de dos pasos para Salir_De_Fiesta: el selector se reabre con preview.
var modo_fiesta: bool = false
# Flujo de dos pasos para Cocinar / Comer: el selector se reabre con preview.
var modo_alimentacion: bool = false
var drag_inicio_y: float = 0.0
var drag_threshold: float = 30.0
var rueda_activa: String = ""

var blink_timer: Timer = null
var blink_estado: bool = false
var mini_cal_preview = null
var _dialog_ir_a_la_calle: ConfirmationDialog = null

var _badge_perfil: Label = null
var _badge_tab_mensajes: Label = null
var _badge_minijuegos: Label = null
var _panel_ajustes: Panel_Ajustes = null
var _minijuegos_novedad_pendiente: bool = false

# Minijuegos y Ropa
var _pantalla_minijuegos: ColorRect = null
var _pantalla_vestuario: Pantalla_Vestuario = null
var _minijuegos_scroll: ScrollContainer = null
var _minijuegos_vbox: VBoxContainer = null
var _capa_minijuego_cocina: CanvasLayer = null
var _minijuego_cocina_activo: bool = false
var _transicion_minijuego_activa: bool = false
var _minijuego_cocina_packed: PackedScene = null
var _script_transicion_minijuego: Script = null
var _dialog_minijuego_bloqueado: AcceptDialog = null
var _capa_minijuego_correr: CanvasLayer = null
var _minijuego_correr_activo: bool = false
var _minijuego_correr_packed: PackedScene = null
var _script_banner_correr: Script = null

# Carrera de futbolista
var _panel_futbol: Control = null
var _capa_panel_futbol: CanvasLayer = null
var _dialogo_ascenso_futbol: ConfirmationDialog = null
var _dialogo_futbol_trabajo: ConfirmationDialog = null
var _trabajo_conflicto_futbol: Actividad_Fija_Trabajo = null
var _conflicto_ascenso_mostrado: bool = false

# «El Mánager» (Fase 2 — Modo Club)
var _panel_manager: Control = null
var _capa_panel_manager: CanvasLayer = null


func _Crear_Badge(parent: Control) -> Label:
	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.10, 0.10, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	lbl.add_theme_stylebox_override("normal", style)
	lbl.z_index = 10
	lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl.offset_left = -30
	lbl.offset_top = 2
	lbl.offset_right = -2
	lbl.offset_bottom = 22
	lbl.visible = false
	parent.add_child(lbl)
	return lbl

func _Contar_No_Leidos() -> int:
	var count = 0
	for m in Variables_Dinamicas.Mensajes:
		if not m.leido:
			count += 1
	return count

func _Actualizar_Badges():
	var count = _Contar_No_Leidos()
	var texto = str(min(count, 99))
	if _badge_perfil != null:
		_badge_perfil.text = texto
		_badge_perfil.visible = count > 0
	if _badge_tab_mensajes != null:
		_badge_tab_mensajes.text = texto
		_badge_tab_mensajes.visible = count > 0
	if _badge_minijuegos != null:
		_badge_minijuegos.text = "!"
		_badge_minijuegos.visible = _minijuegos_novedad_pendiente or Sistema_Manager.Hay_Novedad()

func _ready():
	Musica.Reproducir_General()
	Sistema_Manager.Asegurar_Desbloqueo_QA()
	Inicializar_Otros_Scripts()
	# Los diálogos se estilizan al añadirse, sin recorrer todo el árbol cada
	# medio segundo (en móvil eso generaba picos de CPU y basura).
	if not get_tree().node_added.is_connected(_on_nodo_anadido):
		get_tree().node_added.connect(_on_nodo_anadido)
	var btn_vestuario := get_node_or_null("Vestuario_Button") as Button
	if btn_vestuario != null and not btn_vestuario.pressed.is_connected(_on_vestuario_button_pressed):
		btn_vestuario.pressed.connect(_on_vestuario_button_pressed)
	_badge_perfil = _Crear_Badge($Boton_Perfil)
	_badge_tab_mensajes = _Crear_Badge($Pantalla_Mensajes/Tab_Bar/Tab_Mensajes)
	if has_node("Minijuegos_Button"):
		_badge_minijuegos = _Crear_Badge($Minijuegos_Button)
	$Pantalla_Mensajes/Boton_Cerrar.pressed.connect(_on_mensajes_boton_cerrar_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Mensajes.pressed.connect(_on_perfil_tab_mensajes_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Info.pressed.connect(_on_perfil_tab_info_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Apuntes.pressed.connect(_on_perfil_tab_apuntes_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Despensa.pressed.connect(_on_perfil_tab_despensa_pressed)
	$Pantalla_Mensajes/Contenido_Mensaje/Boton_Volver.pressed.connect(_on_mensajes_boton_volver_pressed)
	if not Sistema_Cocina.restaurante_desbloqueado.is_connected(_on_restaurante_cocina_desbloqueado):
		Sistema_Cocina.restaurante_desbloqueado.connect(_on_restaurante_cocina_desbloqueado)
	if (Variables_Estaticas.First_Time):
		first_time_logica.First_Time_Function()
		Gestionar_Visibilidad.Quitar_Todo(self)
		mirar_semana=1
		Guardar_Variables_Estaticas.save_game()
		Guardar_Variables_Dinamicas.save_game()

	else:
		if Variables_Dinamicas.Muerto:
			get_tree().change_scene_to_file.call_deferred("res://Escenas/Menu/Menu.tscn")
			return
		Gestionar_Visibilidad.Quitar_Todo(self)
		mirar_semana=Variables_Dinamicas.Minute_Day/7
	# Temporal para pruebas: desbloquear Burger & Street Food al entrar en la escena principal
	if not Sistema_Cocina.Esta_Desbloqueado_Restaurante(Sistema_Cocina.RESTAURANTE_BURGER):
		var estado_cocina: Dictionary = Sistema_Cocina.Obtener_Estado()
		var desbl_cocina: Array = estado_cocina.get("restaurantes_desbloqueados", [])
		desbl_cocina.append(Sistema_Cocina.RESTAURANTE_BURGER)
		estado_cocina["restaurantes_desbloqueados"] = desbl_cocina
	_Conectar_Tienda()
	_Conectar_Recompensas()
	Estilos_UI.aplicar_tema_global(self)
	_Aplicar_Rediseno()
	get_viewport().size_changed.connect(_Ajustar_Disposicion_Vertical)
	necesidades_basicas_gui.Inicializar(self)
	Actualizar_Progreso()
	Actualizar_Dinero()
	necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)
	_Actualizar_Badges()
	_Actualizar_Nav_Activa()
	if not Variables_Estaticas.Tutorial_Completado:
		_Iniciar_Tutorial()
	
func _exit_tree() -> void:
	if Sistema_Cocina != null and Sistema_Cocina.restaurante_desbloqueado.is_connected(_on_restaurante_cocina_desbloqueado):
		Sistema_Cocina.restaurante_desbloqueado.disconnect(_on_restaurante_cocina_desbloqueado)
	if Recompensas.recompensa_aplicada.is_connected(_On_Recompensa_Bienestar):
		Recompensas.recompensa_aplicada.disconnect(_On_Recompensa_Bienestar)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Variables_Estaticas.First_Time == false:
		var minutos_pendientes = _Minutos_Pendientes_Por_Procesar()
		if minutos_pendientes > 0:
			var murio = Actividades.Actualizar_Horario(minutos_pendientes)
			Guardar_Variables_Dinamicas.save_game()
			if murio:
				if _capa_minijuego_cocina != null and is_instance_valid(_capa_minijuego_cocina):
					_capa_minijuego_cocina.queue_free()
					_capa_minijuego_cocina = null
					_minijuego_cocina_activo = false
				if _capa_minijuego_correr != null and is_instance_valid(_capa_minijuego_correr):
					_capa_minijuego_correr.queue_free()
					_capa_minijuego_correr = null
					_minijuego_correr_activo = false
				get_tree().change_scene_to_file("res://Escenas/Menu/Menu.tscn")
				return
			Actualizar_Progreso()
			Actualizar_Dinero()
			necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)
			if $Habilidades.visible:
				Actualizar_Habilidades()
			_Actualizar_Badges()
			_Actualizar_Nav_Activa()
			_Actualizar_Pantalla_Minijuegos_Si_Visible()
		_home_refresh -= delta
		if _home_refresh <= 0.0:
			_home_refresh = 0.5
			_Actualizar_Reloj_Header()
			_Actualizar_Home()
			_Actualizar_Necesidades_Extra()
			_Actualizar_Tuppers_UI_Si_Visible()
			_Actualizar_Pantalla_Minijuegos_Si_Visible()
			_Comprobar_Conflicto_Ascenso_Futbol()


## Estiliza los diálogos en cuanto se añaden al árbol. Sustituye al recorrido
## completo de find_children() que se hacía cada 0,5 s.
func _on_nodo_anadido(nodo: Node) -> void:
	if nodo is AcceptDialog and not nodo.has_meta("_tema_dialogo"):
		nodo.set_meta("_tema_dialogo", true)
		_Estilizar_Nodo_Diferido.call_deferred(nodo)
	elif nodo is Window and not nodo.has_meta("_tema_ventana"):
		nodo.set_meta("_tema_ventana", true)
		_Estilizar_Nodo_Diferido.call_deferred(nodo)


func _Estilizar_Nodo_Diferido(nodo: Node) -> void:
	if not is_instance_valid(nodo):
		return
	if nodo is AcceptDialog:
		Estilos_UI.estilizar_dialogo(nodo)
	elif nodo is Window:
		Estilos_UI.estilizar_ventana(nodo)


const _DINERO_OFFSET_RIGHT_3_DIGITOS: int = 600
const _DINERO_DESPLAZAMIENTO_POR_DIGITO_EXTRA: int = 25
const _DINERO_ANCHO_LABEL: int = 220

var _ultimo_dinero_mostrado: int = -999999

func Actualizar_Dinero():
	var nuevo_dinero: int = int(Variables_Dinamicas.Dinero)
	$Dinero_Label.text = "%d €" % nuevo_dinero
	$Dinero_Label.add_theme_color_override("font_color",
		Estilos_UI.EXITO if Variables_Dinamicas.Dinero >= 0 else Estilos_UI.PELIGRO)
	if _ultimo_dinero_mostrado != -999999 and nuevo_dinero != _ultimo_dinero_mostrado:
		var chip := get_node_or_null("Moneda_Fondo") as Control
		if chip != null and chip.is_inside_tree():
			chip.pivot_offset = chip.size * 0.5
			var tw := chip.create_tween()
			tw.tween_property(chip, "scale", Vector2(1.07, 1.07), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(chip, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ultimo_dinero_mostrado = nuevo_dinero
	_Actualizar_Pantalla_Carrera_Si_Visible()
	_Actualizar_Pantalla_Economia_Si_Visible()
	_Actualizar_Pantalla_Minijuegos_Si_Visible()

# Calcula cuántos minutos LOCALES han pasado desde el último tick procesado.
# Se basa en la hora del dispositivo (no en Unix delta), así DST y cambios de zona
# horaria se reflejan automáticamente: el juego sigue siempre el reloj de pared local.
func _Minutos_Pendientes_Por_Procesar() -> int:
	var dict_fecha = Time.get_date_dict_from_system()
	var dict_hora = Time.get_time_dict_from_system()
	# "Unix ficticio" tratando la fecha local como si fuera UTC. La diferencia entre dos
	# de estos valores da el número correcto de días naturales locales transcurridos.
	var fake_now = Time.get_unix_time_from_datetime_dict({
		"year": dict_fecha["year"], "month": dict_fecha["month"], "day": dict_fecha["day"],
		"hour": 0, "minute": 0, "second": 0
	})
	var fake_inicio = Time.get_unix_time_from_datetime_dict({
		"year": Variables_Estaticas.First_Time_Year,
		"month": Variables_Estaticas.First_Time_Month,
		"day": Variables_Estaticas.First_Time_Day_Of_Month,
		"hour": 0, "minute": 0, "second": 0
	})
	var dias_desde_inicio = int(round((fake_now - fake_inicio) / 86400.0))
	var minuto_actual_local = dict_hora["hour"] * 60 + dict_hora["minute"]
	# Minutos acumulados desde el inicio según el reloj local
	var minutos_locales_acum = dias_desde_inicio * 1440 + (minuto_actual_local - Variables_Estaticas.First_Time_Minute_Minute)
	# Minutos acumulados que ya hemos procesado en la matriz
	var minutos_procesados = (Variables_Dinamicas.Minute_Day - Variables_Estaticas.First_Time_Minute_Day) * 1440 + (Variables_Dinamicas.Minute_Minute - Variables_Estaticas.First_Time_Minute_Minute)
	return minutos_locales_acum - minutos_procesados


func Cargar_Variables():
	Guardar_Variables_Estaticas.load_game()
	Guardar_Variables_Dinamicas.load_game()


#Interfaz

func _on_boton_habilidades_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Gestionar_Visibilidad.Recursivo_Visibilizar($Habilidades)
	Estilos_UI.animar_entrada($Habilidades)
	Actualizar_Habilidades()
	_Actualizar_Nav_Activa()


func _on_boton_progreso_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Gestionar_Visibilidad.Recursivo_Visibilizar($Progreso)
	Estilos_UI.animar_entrada($Progreso)
	for n in ["Manualidades2", "Manualidades3"]:
		var extra := $Progreso/Progreso_Barra.get_node_or_null(n)
		if extra != null:
			extra.visible = false
	Actualizar_Progreso()
	_Actualizar_Nav_Activa()


func _on_boton_necesidades_basicas_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Gestionar_Visibilidad.Recursivo_Visibilizar($Necesidades_Basicas)
	Estilos_UI.animar_entrada($Necesidades_Basicas)
	_Actualizar_Necesidades_Extra()
	_Actualizar_Nav_Activa()




const _COLORES_PROGRESO := [Color("#1ea34a"), Color("#1d7afc"), Color("#f59e0b")]

func Actualizar_Progreso():
	var nombres := ["Deporte", "Académico", "Manualidades"]
	var nodos := ["Deporte", "Academico", "Manualidades"]
	for i in range(3):
		var valor: int = Variables_Dinamicas.Progreso[i]
		var col: Color = _COLORES_PROGRESO[i]
		var bar := $Progreso/Progreso_Barra.get_node_or_null(nodos[i]) as ProgressBar
		if bar != null:
			bar.self_modulate = Color.WHITE
			Estilos_UI.animar_barra(bar, float(valor), col)
		var lbl := $Progreso/Progreso_Texto.get_child(i) as Label
		if lbl != null:
			lbl.text = nombres[i]
		var pct := $Progreso.get_node_or_null("Pct_%d" % i) as Label
		if pct != null:
			pct.text = "%d%%" % valor
			pct.add_theme_color_override("font_color", col)
	var bar_cocina := $Progreso/Progreso_Barra.get_node_or_null("Cocina") as ProgressBar
	var col_cocina := Color("#ea580c")
	if bar_cocina != null:
		bar_cocina.self_modulate = Color.WHITE
		Estilos_UI.animar_barra(bar_cocina, float(Variables_Dinamicas.Progreso_Cocina), col_cocina)
	var lbl_cocina := $Progreso/Progreso_Texto.get_node_or_null("Slot_Cocina") as Label
	if lbl_cocina != null:
		lbl_cocina.text = "Cocina"
	var pct_cocina := $Progreso.get_node_or_null("Pct_3") as Label
	if pct_cocina != null:
		pct_cocina.text = "%d%%" % Variables_Dinamicas.Progreso_Cocina
		pct_cocina.add_theme_color_override("font_color", col_cocina)
	if $Progreso.visible:
		_Actualizar_Progreso_Extra()


const _NOMBRES_HABILIDADES: Array = ["Deporte", "Inteligencia", "Destreza", "Memoria", "Liderazgo", "Paciencia", "Sangre fría"]
const _HABILIDADES_VISIBLES: int = 7
const _COLOR_HABILIDAD_DESCUBRIENDO: Color = Color(0.114, 0.478, 0.988, 1.0)
const _COLOR_HABILIDAD_TOPE: Color = Color(0.118, 0.639, 0.290, 1.0)

var habilidades_scroll_offset: int = 0

func Actualizar_Habilidades():
	for indice in range(_NOMBRES_HABILIDADES.size()):
		var bar := $Habilidades/Habilidades_Barra.get_node_or_null("Slot_" + str(indice)) as ProgressBar
		var lbl := $Habilidades/Habilidades_Texto.get_node_or_null("Slot_" + str(indice)) as Label
		if bar == null or lbl == null:
			continue
		var mostrado: int = Variables_Dinamicas.Habilidades_Mostradas[indice] if indice < Variables_Dinamicas.Habilidades_Mostradas.size() else 0
		var innato: int = Variables_Estaticas.Habilidades[indice] if indice < Variables_Estaticas.Habilidades.size() else 0
		var en_tope: bool = innato > 0 and mostrado >= innato
		var col: Color = _COLOR_HABILIDAD_TOPE if en_tope else _COLOR_HABILIDAD_DESCUBRIENDO
		lbl.text = _NOMBRES_HABILIDADES[indice]
		bar.self_modulate = Color.WHITE
		Estilos_UI.animar_barra(bar, float(mostrado), col)
		var pct := $Habilidades.get_node_or_null("Pct_%d" % indice) as Label
		if pct != null:
			pct.text = "%d%%" % mostrado if not en_tope else "%d%% (Máx)" % mostrado
			pct.add_theme_color_override("font_color", col)
	if $Habilidades.has_node("Flecha_Arriba"):
		$Habilidades/Flecha_Arriba.visible = false
	if $Habilidades.has_node("Flecha_Abajo"):
		$Habilidades/Flecha_Abajo.visible = false

func _on_habilidades_flecha_arriba_pressed():
	if habilidades_scroll_offset > 0:
		habilidades_scroll_offset -= 1
		Actualizar_Habilidades()

func _on_habilidades_flecha_abajo_pressed():
	var max_offset = _NOMBRES_HABILIDADES.size() - _HABILIDADES_VISIBLES
	if habilidades_scroll_offset < max_offset:
		habilidades_scroll_offset += 1
		Actualizar_Habilidades()


func _Ocultar_Home() -> void:
	if _home != null and is_instance_valid(_home):
		_home.visible = false


func Quitar_Todo():
	Detener_Blink()
	calendario_solo_lectura = false
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Actualizar_Home()
	_Actualizar_Nav_Activa()


func _on_boton_actividades_pressed():
	_Liberar_Bloque_Horario()
	_Mostrar_Catalogo_Actividades()


func _Mostrar_Catalogo_Actividades() -> void:
	actividad_seleccionada = ""
	Detener_Blink()
	calendario_solo_lectura = false
	# Si se estaba consultando una semana pasada, programar ahí no tendría efecto:
	# volvemos a la semana actual. Las semanas futuras se respetan.
	var sem_actual: int = int(Variables_Dinamicas.Minute_Day) / 7
	if mirar_semana == null:
		mirar_semana = sem_actual
	if int(mirar_semana) < sem_actual:
		mirar_semana = sem_actual
	Gestionar_Visibilidad.Visibilizar_Elegir_Actividad(self)
	_Mostrar_Titulo_Actividades()
	_Ocultar_Home()
	_Actualizar_Trabajos_UI()
	_Actualizar_Boton_Carrera_Deportiva()
	_Actualizar_Boton_Carrera_Futbol()
	_Actualizar_Nav_Activa()


func _Restaurar_Catalogo_Actividades() -> void:
	# Vuelve exactamente al submenú desde el que se eligió la actividad.
	actividad_seleccionada = ""
	Detener_Blink()
	Gestionar_Visibilidad.Restaurar_Elegir_Actividad(self)
	_Actualizar_Nav_Activa()


func _Liberar_Bloque_Horario() -> void:
	if actividades_reloj_gui != null and is_instance_valid(actividades_reloj_gui):
		actividades_reloj_gui.horariobloque = null
	if horario_bloque != null and is_instance_valid(horario_bloque):
		horario_bloque.free()
	horario_bloque = null


func _Nombre_Visible_Actividad(nombre: String) -> String:
	if NOMBRES_VISIBLES_ACTIVIDADES.has(nombre):
		return NOMBRES_VISIBLES_ACTIVIDADES[nombre]
	return nombre.replace("_", " ")


func _Duracion_Predeterminada(nombre: String) -> int:
	return int(DURACIONES_PREDETERMINADAS.get(nombre, 60))


func _Bloque_Desde_Minutos(inicio_abs: int, fin_abs: int) -> HorarioDesdeBloque:
	var bloque := HorarioDesdeBloque.new()
	var d_ini: int = clampi(int(inicio_abs / 1440), 0, 6)
	var rem_ini: int = clampi(inicio_abs - d_ini * 1440, 0, 1439)
	var d_fin: int = 6
	var hora_fin: int = 24
	var min_fin: int = 0
	if fin_abs < 10080:
		d_fin = clampi(int(fin_abs / 1440), 0, 6)
		var rem_fin: int = fin_abs - d_fin * 1440
		hora_fin = int(rem_fin / 60)
		min_fin = rem_fin % 60
	bloque.Inicializar(
		Funciones_Globales.Devolver_Dia(d_ini),
		int(rem_ini / 60), rem_ini % 60,
		Funciones_Globales.Devolver_Dia(d_fin),
		hora_fin, min_fin)
	return bloque


func _Crear_Bloque_Predeterminado(nombre: String) -> HorarioDesdeBloque:
	var sem_actual: int = int(Variables_Dinamicas.Minute_Day) / 7
	if mirar_semana == null:
		mirar_semana = sem_actual
	if int(mirar_semana) < sem_actual:
		mirar_semana = sem_actual
	var dia_ini: int = 0
	var min_ini: int = 0
	if int(mirar_semana) == sem_actual:
		dia_ini = int(Variables_Dinamicas.Minute_Day) % 7
		min_ini = int(ceil(float(Variables_Dinamicas.Minute_Minute) / 5.0)) * 5
		if min_ini >= 1440:
			min_ini = 0
			if dia_ini >= 6:
				# Domingo al borde del cierre: se propone el lunes siguiente.
				if int(mirar_semana) < 81:
					mirar_semana = int(mirar_semana) + 1
					dia_ini = 0
					min_ini = int(HORAS_INICIO_PREDETERMINADAS.get(nombre, HORA_INICIO_GENERICA))
			else:
				dia_ini += 1
	else:
		# Semana futura: hora de inicio razonable según la actividad.
		min_ini = int(HORAS_INICIO_PREDETERMINADAS.get(nombre, HORA_INICIO_GENERICA))

	var duracion: int = _Duracion_Predeterminada(nombre)
	if nombre == "Salir_De_Fiesta":
		# La fiesta solo es válida de 18:00 a 06:00. Se propone la próxima
		# ventana razonable y el jugador puede ajustarla en el selector.
		if min_ini < 360:
			# Madrugada: si queda al menos la duración mínima, se empieza ahora.
			if 360 - min_ini >= 120:
				duracion = mini(180, 360 - min_ini)
			else:
				min_ini = 1080
				duracion = 180
		elif min_ini < 1080:
			# Mañana/tarde: la siguiente fiesta empieza a las 18:00.
			min_ini = 1080
			duracion = 180
		else:
			# Noche: se empieza ahora y puede cruzar medianoche.
			duracion = 180

	var inicio_abs: int = dia_ini * 1440 + min_ini
	var fin_abs: int = inicio_abs + duracion
	if fin_abs > 10080:
		fin_abs = 10080
		inicio_abs = maxi(0, fin_abs - duracion)
		inicio_abs = (inicio_abs / 5) * 5
	if fin_abs <= inicio_abs:
		fin_abs = mini(10080, inicio_abs + 5)
	return _Bloque_Desde_Minutos(inicio_abs, fin_abs)


func _Abrir_Horario_Para_Actividad(nombre: String) -> void:
	if nombre == "":
		return
	if nombre == "Cocinar" and Variables_Dinamicas.En_La_Calle:
		_Mostrar_Error_Alimentacion("No puedes cocinar sin una vivienda.")
		return
	actividad_seleccionada = nombre
	modo_fiesta = (nombre == "Salir_De_Fiesta")
	modo_alimentacion = nombre in ["Cocinar", "Comer_Tupper", "Comer_Basura"]
	var rango_inicial = null
	if horario_bloque != null and is_instance_valid(horario_bloque):
		# El bloque marcado en el calendario actúa como franja inicial sugerida.
		rango_inicial = _Rango_A_Minutos(horario_bloque)
		if actividades_reloj_gui != null and is_instance_valid(actividades_reloj_gui):
			actividades_reloj_gui.horariobloque = null
		horario_bloque.free()
	else:
		var sugerido := _Crear_Bloque_Predeterminado(nombre)
		rango_inicial = _Rango_A_Minutos(sugerido)
		sugerido.free()
	# En ambos casos el selector permite ajustar cualquier franja de la semana.
	horario_bloque = _Crear_Bloque_Semana_Completa()
	Gestionar_Visibilidad.Visibilizar_Seleccionar_Horario(self)
	actividades_reloj_gui.Comprobar_Visibilidad(self, horario_bloque, rango_inicial)
	Iniciar_Blink()
	_Actualizar_Titulo_Selector(nombre)
	if nombre == "Comer_Tupper":
		call_deferred("_Abrir_Modal_Tuppers_Al_Entrar")


func _Crear_Bloque_Semana_Completa() -> HorarioDesdeBloque:
	return _Bloque_Desde_Minutos(0, 10080)


func _Rango_A_Minutos(bloque: HorarioDesdeBloque) -> Array:
	if bloque == null:
		return [0, 60]
	var inicio: int = bloque.dia_inicio_int() * 1440 + int(bloque.hora_inicio) * 60 + int(bloque.minuto_inicio)
	var fin: int = bloque.dia_final_int() * 1440 + int(bloque.hora_final) * 60 + int(bloque.minuto_final)
	return [inicio, fin]


func _Actualizar_Titulo_Selector(nombre: String) -> void:
	var titulo := get_node_or_null("Actividades/Seleccionar_Horario/Titulo") as Label
	if titulo == null:
		return
	titulo.text = "Horario · %s" % _Nombre_Visible_Actividad(nombre)



func _on_siguiente_semana_pressed() -> void:
	if mirar_semana < 81:
		mirar_semana += 1
		actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
		actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
		_Limpiar_Seleccion_Calendario_UI()
		_Actualizar_Visibilidad_Botones_Navegacion()
		_Actualizar_Titulo_Horario()

func _on_anterior_semana_pressed() -> void:
	if mirar_semana > 0:
		mirar_semana -= 1
		actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
		actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
		_Limpiar_Seleccion_Calendario_UI()
		_Actualizar_Visibilidad_Botones_Navegacion()
		_Actualizar_Titulo_Horario()

func _Ir_A_Semana_Actual() -> void:
	var sem_actual: int = clampi(int(Variables_Dinamicas.Minute_Day) / 7, 0, 81)
	if mirar_semana != sem_actual:
		mirar_semana = sem_actual
		actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
		actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
		_Limpiar_Seleccion_Calendario_UI()
		_Actualizar_Visibilidad_Botones_Navegacion()
		_Actualizar_Titulo_Horario()

func _Actualizar_Visibilidad_Botones_Navegacion() -> void:
	var boton_anterior = $Actividades/Horario_Semanal/OPCIONES_CALENDARIO.get_node("ANTERIOR SEMANA")
	var boton_siguiente = $Actividades/Horario_Semanal/OPCIONES_CALENDARIO.get_node("SIGUIENTE SEMANA")

	var sem_actual: int = int(Variables_Dinamicas.Minute_Day) / 7
	boton_anterior.visible = mirar_semana > 0
	boton_siguiente.visible = mirar_semana < 81
	var btn_hoy := get_node_or_null("Actividades/Horario_Semanal/Boton_Ir_Hoy") as Button
	if btn_hoy != null:
		btn_hoy.visible = (mirar_semana != sem_actual)
	var btn_sem_actual := get_node_or_null("Actividades/Horario_Semanal/Boton_Semana_Actual_Inferior") as Button
	if btn_sem_actual != null:
		var en_semana_actual: bool = (int(mirar_semana) == sem_actual)
		btn_sem_actual.visible = true
		btn_sem_actual.disabled = en_semana_actual
		btn_sem_actual.text = "Estás en la semana actual" if en_semana_actual else "Volver a la semana actual"


func _input(event: InputEvent) -> void:
	if _panel_ajustes != null or not seleccionar_horario_activo:
		return
	var pos := Vector2.ZERO
	var es_presion := false
	var es_movimiento := false
	var presionado := false
	if event is InputEventScreenTouch:
		pos = event.position; es_presion = true; presionado = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position; es_presion = true; presionado = event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position; es_movimiento = true
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pos = event.position; es_movimiento = true
	if es_presion:
		if presionado:
			drag_inicio_y = pos.y
			rueda_activa = _detectar_rueda(pos)
		else:
			rueda_activa = ""
	elif es_movimiento and rueda_activa != "":
		var delta := drag_inicio_y - pos.y
		if abs(delta) >= drag_threshold:
			_ejecutar_scroll_rueda(rueda_activa, delta > 0)
			drag_inicio_y = pos.y

func _detectar_rueda(pos: Vector2) -> String:
	var ruedas := {
		"inicio_dia":    get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Dia_Vbox"),
		"inicio_hora":   get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Hora_Vbox"),
		"inicio_minuto": get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Minuto_Vbox"),
		"final_dia":     get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Dia_Vbox"),
		"final_hora":    get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Hora_Vbox"),
		"final_minuto":  get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Minuto_Vbox"),
	}
	for nombre in ruedas:
		if ruedas[nombre].get_global_rect().has_point(pos):
			return nombre
	return ""

func _ejecutar_scroll_rueda(rueda, arriba):
	var h = actividades_reloj_gui.horario
	if h == null:
		return
	match rueda:
		"inicio_dia":
			if arriba and h.dia_inicio_arriba.visible and not h.dia_inicio_arriba.disabled: Inicio_Dia_Arriba()
			elif not arriba and h.dia_inicio_abajo.visible and not h.dia_inicio_abajo.disabled: Inicio_Dia_Abajo()
		"inicio_hora":
			if arriba and h.hora_inicio_arriba.visible and not h.hora_inicio_arriba.disabled: Inicio_Hora_Arriba()
			elif not arriba and h.hora_inicio_abajo.visible and not h.hora_inicio_abajo.disabled: Inicio_Hora_Abajo()
		"inicio_minuto":
			if arriba and h.minuto_inicio_arriba.visible and not h.minuto_inicio_arriba.disabled: Inicio_Minuto_Arriba()
			elif not arriba and h.minuto_inicio_abajo.visible and not h.minuto_inicio_abajo.disabled: Inicio_Minuto_Abajo()
		"final_dia":
			if arriba and h.dia_final_arriba.visible and not h.dia_final_arriba.disabled: Final_Dia_Arriba()
			elif not arriba and h.dia_final_abajo.visible and not h.dia_final_abajo.disabled: Final_Dia_Abajo()
		"final_hora":
			if arriba and h.hora_final_arriba.visible and not h.hora_final_arriba.disabled: Final_Hora_Arriba()
			elif not arriba and h.hora_final_abajo.visible and not h.hora_final_abajo.disabled: Final_Hora_Abajo()
		"final_minuto":
			if arriba and h.minuto_final_arriba.visible and not h.minuto_final_arriba.disabled: Final_Minuto_Arriba()
			elif not arriba and h.minuto_final_abajo.visible and not h.minuto_final_abajo.disabled: Final_Minuto_Abajo()

func Iniciar_Blink() -> void:
	seleccionar_horario_activo = true
	if blink_timer == null:
		blink_timer = Timer.new()
		blink_timer.wait_time = 0.5
		blink_timer.connect("timeout", Callable(self, "_on_blink_timeout"))
		add_child(blink_timer)
	blink_estado = false
	var btn_crear := get_node_or_null("Actividades/Seleccionar_Horario/Crear_Actividad") as Button
	if btn_crear != null:
		btn_crear.text = "Crear actividad"
	if modo_fiesta:
		_Mostrar_Preview_Fiesta()
	elif modo_alimentacion:
		_Ocultar_Preview_Fiesta()
		_Mostrar_Preview_Alimentacion()
	else:
		_Ocultar_Preview_Fiesta()
		_Ocultar_Preview_Alimentacion()
		if mini_cal_preview != null:
			mini_cal_preview.limpiar()
		mini_cal_preview = MiniCalendarioPreview.new()
		mini_cal_preview.crear(self, mirar_semana)
		_actualizar_mini_cal()
	blink_timer.start()

func _actualizar_mini_cal() -> void:
	if mini_cal_preview == null:
		return
	var h = actividades_reloj_gui.horario
	if h == null:
		return
	mini_cal_preview.actualizar_rango(
		h.dia_inicio_a_int(),
		h.hora_inicio_texto.text.to_int(),
		h.minuto_inicio_texto.text.to_int(),
		h.dia_final_a_int(),
		h.hora_final_texto.text.to_int(),
		h.minuto_final_texto.text.to_int()
	)
	mini_cal_preview.aplicar_blink(blink_estado)

func _actualizar_blink_si_activo():
	if seleccionar_horario_activo:
		if modo_fiesta:
			_Actualizar_Preview_Fiesta()
		elif modo_alimentacion:
			_Actualizar_Preview_Alimentacion()
		else:
			_actualizar_mini_cal()

func Detener_Blink() -> void:
	seleccionar_horario_activo = false
	rueda_activa = ""
	if blink_timer != null:
		blink_timer.stop()
	if mini_cal_preview != null:
		mini_cal_preview.limpiar()
		mini_cal_preview = null
	_Ocultar_Preview_Fiesta()
	_Ocultar_Preview_Alimentacion()
	modo_fiesta = false
	modo_alimentacion = false


func _Mostrar_Preview_Fiesta() -> void:
	if actividades_reloj_gui == null or actividades_reloj_gui.horario == null:
		return
	actividades_reloj_gui.horario.Actualizar_Preview_Fiesta(self)


func _Actualizar_Preview_Fiesta() -> void:
	if actividades_reloj_gui == null or actividades_reloj_gui.horario == null:
		return
	actividades_reloj_gui.horario.Actualizar_Preview_Fiesta(self)


func _Ocultar_Preview_Fiesta() -> void:
	var panel := get_node_or_null("Actividades/Seleccionar_Horario/Preview_Fiesta")
	if panel != null:
		panel.queue_free()

func _Mostrar_Preview_Alimentacion() -> void:
	if actividades_reloj_gui == null or actividades_reloj_gui.horario == null:
		return
	actividades_reloj_gui.horario.Actualizar_Preview_Alimentacion(self)

func _Actualizar_Preview_Alimentacion() -> void:
	if actividades_reloj_gui == null or actividades_reloj_gui.horario == null:
		return
	actividades_reloj_gui.horario.Actualizar_Preview_Alimentacion(self)

func _Ocultar_Preview_Alimentacion() -> void:
	var panel := get_node_or_null("Actividades/Seleccionar_Horario/Preview_Alimentacion")
	if panel != null:
		panel.queue_free()

func _Seleccionar_Modo_Comer(modo: String) -> void:
	if modo != "Comer_Tupper" and modo != "Comer_Basura":
		return
	actividad_seleccionada = modo
	_Actualizar_Titulo_Selector(modo)
	if modo == "Comer_Tupper" and not Variables_Dinamicas.Tuppers.is_empty():
		_Abrir_Modal_Tuppers()
	_Actualizar_Preview_Alimentacion()

var _modal_tuppers: AcceptDialog = null

func _Abrir_Modal_Tuppers() -> void:
	if _modal_tuppers != null and is_instance_valid(_modal_tuppers):
		_modal_tuppers.Refrescar()
		_modal_tuppers.popup_centered()
		return
	_modal_tuppers = _MODAL_TUPPERS_SCRIPT.new()
	add_child(_modal_tuppers)
	_modal_tuppers.tupper_elegido.connect(_on_tupper_elegido)
	_modal_tuppers.tuppers_cambiados.connect(_on_tuppers_cambiados)
	_modal_tuppers.popup_centered()

func _on_tupper_elegido(_indice: int) -> void:
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Preview_Alimentacion()
	_Actualizar_Tuppers_UI_Si_Visible()

func _on_tuppers_cambiados() -> void:
	_Actualizar_Preview_Alimentacion()
	_Actualizar_Tuppers_UI_Si_Visible()
	Guardar_Variables_Dinamicas.save_game()

func _on_blink_timeout() -> void:
	blink_estado = !blink_estado
	if mini_cal_preview != null:
		mini_cal_preview.aplicar_blink(blink_estado)

func _on_ocupar_actividad_pressed() -> void:
	modo_fiesta = false
	modo_alimentacion = false
	if not actividades_bloque_gui.comprobar_seleccionado():
		return
	# El bloque elegido se conserva como franja propuesta. Primero se elige la
	# actividad en el catálogo y después se ajusta el horario.
	_Liberar_Bloque_Horario()
	horario_bloque = actividades_bloque_gui.devolver_hora_desde_posiciones()
	_Mostrar_Catalogo_Actividades()


func _on_crear_actividad_pressed():
	if actividad_seleccionada == "":
		return
	Crear_Actividad(actividad_seleccionada)


func _on_cancelar_pressed():
	calendario_solo_lectura = false
	_Liberar_Bloque_Horario()
	_Restaurar_Catalogo_Actividades()


func _on_eliminar_actividad_pressed() -> void:
	if not actividades_bloque_gui.comprobar_seleccionado():
		return
	_Liberar_Bloque_Horario()
	horario_bloque = actividades_bloque_gui.devolver_hora_desde_posiciones()

	# Si la celda seleccionada es un trabajo fijo, eliminar UNA celda no tiene sentido
	# (el trabajo abarca semanas enteras). En su lugar pedimos confirmación al jugador:
	# si acepta, se borran todas las celdas futuras de esa actividad (= dejar el trabajo).
	var dia_index = mirar_semana * 7 + horario_bloque.dia_inicio_int()
	var minuto_inicio_cell = horario_bloque.hora_inicio * 60 + horario_bloque.minuto_inicio
	var celda_seleccionada = Variables_Dinamicas.Matriz_Jugador[minuto_inicio_cell][dia_index]
	if celda_seleccionada is Actividad_Fija_Trabajo:
		_Mostrar_Confirmacion_Dejar_Trabajo(celda_seleccionada)
		return
	if celda_seleccionada is Actividad_Examen:
		_Mostrar_Error_No_Eliminar_Examen()
		return
	if celda_seleccionada is Actividad and celda_seleccionada.nombre == "Carrera_Deportiva":
		_Mostrar_Error_Bloque_Fijo("Carrera bloqueada", "No puedes eliminar una carrera deportiva en la que ya te has inscrito.")
		return
	if celda_seleccionada is Actividad and celda_seleccionada.nombre in ["Entrenamiento_Futbol", "Partido_Futbol"]:
		_Mostrar_Error_Bloque_Fijo("Compromiso del club", "Los entrenamientos y partidos de fútbol se gestionan desde el panel de Carrera de futbolista.")
		return

	actividades_reloj_gui.Comprobar_Visibilidad(self, horario_bloque)
	actividades_reloj_gui.Restart()
	actividades_reloj_gui.horario.Crear_Actividad(mirar_semana, "")
	actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
	actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
	_Limpiar_Seleccion_Calendario_UI()


# Diálogo de confirmación para dejar un trabajo. Se crea perezosamente la primera vez
# que se necesita y se reutiliza en llamadas posteriores.
var _trabajo_a_dejar = null
var _dialog_dejar_trabajo: ConfirmationDialog = null

func _Mostrar_Confirmacion_Dejar_Trabajo(actividad):
	_trabajo_a_dejar = actividad
	if _dialog_dejar_trabajo == null:
		_dialog_dejar_trabajo = ConfirmationDialog.new()
		_dialog_dejar_trabajo.title = "Dejar trabajo"
		_dialog_dejar_trabajo.ok_button_text = "Sí, dejar"
		_dialog_dejar_trabajo.get_cancel_button().text = "Cancelar"
		_dialog_dejar_trabajo.confirmed.connect(_Confirmar_Dejar_Trabajo)
		_dialog_dejar_trabajo.canceled.connect(_Cancelar_Dejar_Trabajo)
		add_child(_dialog_dejar_trabajo)
	var nombre_legible = actividad.nombre.replace("_", " ")
	_dialog_dejar_trabajo.dialog_text = "¿Seguro que quieres dejar el trabajo \"%s\"?\nDejarás de ganar dinero." % nombre_legible
	_dialog_dejar_trabajo.popup_centered(Vector2i(500, 220))


func _Confirmar_Dejar_Trabajo():
	if _trabajo_a_dejar == null:
		return
	Trabajo.Dejar_Trabajo(_trabajo_a_dejar)
	Guardar_Variables_Dinamicas.save_game()
	actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
	actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
	_Limpiar_Seleccion_Calendario_UI()
	_trabajo_a_dejar = null


func _Cancelar_Dejar_Trabajo():
	_trabajo_a_dejar = null


var _dialog_no_eliminar_examen: AcceptDialog = null

func _Mostrar_Error_No_Eliminar_Examen():
	_Mostrar_Error_Bloque_Fijo("Examen bloqueado", "No puedes eliminar un examen programado.")


func _Mostrar_Error_Bloque_Fijo(titulo_err: String, texto_err: String) -> void:
	if _dialog_no_eliminar_examen == null:
		_dialog_no_eliminar_examen = AcceptDialog.new()
		_dialog_no_eliminar_examen.ok_button_text = "Entendido"
		add_child(_dialog_no_eliminar_examen)
	_dialog_no_eliminar_examen.title = titulo_err
	_dialog_no_eliminar_examen.dialog_text = texto_err
	_dialog_no_eliminar_examen.popup_centered(Vector2i(460, 180))


##INICIO
func Inicio_Minuto_Arriba() -> void:
	actividades_reloj_gui.horario.Inicio_Minuto_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Inicio_Minuto_Abajo() -> void:
	actividades_reloj_gui.horario.Inicio_Minuto_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Inicio_Hora_Arriba() -> void:
	actividades_reloj_gui.horario.Inicio_Hora_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Inicio_Hora_Abajo() -> void:
	actividades_reloj_gui.horario.Inicio_Hora_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Inicio_Dia_Arriba() -> void:
	actividades_reloj_gui.horario.Inicio_Dia_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Inicio_Dia_Abajo() -> void:
	actividades_reloj_gui.horario.Inicio_Dia_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
##FINAL
func Final_Minuto_Arriba() -> void:
	actividades_reloj_gui.horario.Final_Minuto_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Final_Minuto_Abajo() -> void:
	actividades_reloj_gui.horario.Final_Minuto_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Final_Hora_Arriba() -> void:
	actividades_reloj_gui.horario.Final_Hora_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Final_Hora_Abajo() -> void:
	actividades_reloj_gui.horario.Final_Hora_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Final_Dia_Arriba() -> void:
	actividades_reloj_gui.horario.Final_Dia_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()
func Final_Dia_Abajo() -> void:
	actividades_reloj_gui.horario.Final_Dia_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	_actualizar_blink_si_activo()

func Inicializar_Otros_Scripts():
	var ActividadesGUI = load("res://Scripts/GUI/Escena_Principal/Actividades/Reloj/ActividadesRelojGUI.gd")
	actividades_reloj_gui = ActividadesGUI.new()
	
	var ActividadesBloque=load("res://Scripts/GUI/Escena_Principal/Actividades/Bloque/ActividadesBloqueGUI.gd")
	actividades_bloque_gui=ActividadesBloque.new()
	
	var NecesidadesBasicas=load("res://Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd")
	necesidades_basicas_gui=NecesidadesBasicas.new()
	
	var FirstTime= load("res://Scripts/Logica/Escena_Principal/First_Time/First_Time.gd")
	first_time_logica=FirstTime.new()
	


func Iniciar_Bloques_Actividad():
	actividades_bloque_gui.Inicializar(self)
	actividades_bloque_gui.bloque_columna.limpiar_horas_del_horario()
	actividades_bloque_gui.Añadir_Horas_Al_Horario()
	actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
	actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
	Gestionar_Visibilidad.Visibilizar_Horario_Semanal(self)
	_Limpiar_Seleccion_Calendario_UI()
	_Actualizar_Visibilidad_Botones_Navegacion()
	_Actualizar_Titulo_Horario()
	var mover := get_node_or_null("Actividades/Horario_Semanal/Mover_Vertical") as ScrollContainer
	if mover != null:
		mover.set_deferred("scroll_vertical", 0)


func _on_calendario_boton_pressed() -> void:
	Detener_Blink()
	calendario_solo_lectura = true
	mirar_semana = Variables_Dinamicas.Minute_Day / 7
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Iniciar_Bloques_Actividad()
	_Actualizar_Nav_Activa()


func Opciones_Actividades_Temporales() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Temporales", self)


func _on_temporales_pressed() -> void:
	# Entrada directa al calendario semanal (accesos rápidos / compatibilidad).
	calendario_solo_lectura = false
	Iniciar_Bloques_Actividad()
	_Actualizar_Nav_Activa()


func Opciones_Actividades_Fijas() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Fijas", self)


func _on_especiales_pressed() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Especiales", self)
	_Actualizar_Boton_Carrera_Deportiva()


func Opciones_Actividades_Trabajo() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Trabajo", self)
	_Actualizar_Trabajos_UI()


func Opciones_Actividades_Cocinero() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Cocinero", self)
	_Actualizar_Trabajos_UI()


func _on_comida_rapida_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"])

func _on_carpintero_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Carpintero"])

func _on_cientifico_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Cientifico"])

func _on_abogado_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Abogado"])

func _on_medico_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Medico"])

func _on_artista_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Artista"])

func _on_ayudante_cocina_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Ayudante_Cocina"])

func _on_cocinero_partida_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Cocinero_Partida"])

func _on_chef_ejecutivo_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Chef_Ejecutivo"])


func _Intentar_Tomar_Trabajo(actividad: Actividad_Fija_Trabajo) -> void:
	if not _Cumple_Requisitos_Trabajo(actividad):
		return
	# Comprobar cooldown por despido
	var minutos_rest = get_node("/root/Eventos_Aleatorios").Minutos_Restantes_Cooldown(actividad.nombre)
	if minutos_rest > 0:
		var horas = minutos_rest / 60
		var mins = minutos_rest % 60
		var nombre = actividad.nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
		_Mostrar_Error_Requisito("No puedes trabajar de %s.\nFuiste despedido recientemente.\nTiempo restante: %d horas y %d minutos." % [nombre, horas, mins])
		return
	var actual = Variables_Dinamicas.Trabajo_Actual
	if actual != null and actual == actividad:
		var nombre = actividad.nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
		_Mostrar_Error_Requisito("Ya estás trabajando de %s." % nombre)
		return
	if actual != null:
		_trabajo_pendiente = actividad
		_Mostrar_Confirmacion_Cambiar_Trabajo(actual, actividad)
	else:
		_Tomar_Trabajo(actividad)

func _Tomar_Trabajo(actividad: Actividad_Fija_Trabajo) -> void:
	# El fútbol y un empleo con horario solapado son incompatibles: el jugador elige
	# antes de abandonar el empleo anterior, para no perderlo si cancela el diálogo.
	if Sistema_Futbol.Carrera_Activa() and Sistema_Futbol.Trabajo_Solapa_Con_Futbol(actividad):
		_Mostrar_Conflicto_Futbol_Trabajo(actividad)
		return
	if Variables_Dinamicas.Trabajo_Actual != null:
		Trabajo.Dejar_Trabajo(Variables_Dinamicas.Trabajo_Actual)
	Trabajo.Trabajar(actividad)
	Guardar_Variables_Dinamicas.save_game()
	Actividad_Terminada()


var _trabajo_pendiente: Actividad_Fija_Trabajo = null
var _dialog_cambiar_trabajo: ConfirmationDialog = null

func _Mostrar_Confirmacion_Cambiar_Trabajo(actual: Actividad_Fija_Trabajo, nuevo: Actividad_Fija_Trabajo) -> void:
	if _dialog_cambiar_trabajo == null:
		_dialog_cambiar_trabajo = ConfirmationDialog.new()
		_dialog_cambiar_trabajo.title = "Cambiar de trabajo"
		_dialog_cambiar_trabajo.ok_button_text = "Sí, cambiar"
		_dialog_cambiar_trabajo.get_cancel_button().text = "Cancelar"
		_dialog_cambiar_trabajo.confirmed.connect(_Confirmar_Cambiar_Trabajo)
		_dialog_cambiar_trabajo.canceled.connect(_Cancelar_Cambiar_Trabajo)
		add_child(_dialog_cambiar_trabajo)
	var nombre_actual = actual.nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
	var nombre_nuevo = nuevo.nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
	_dialog_cambiar_trabajo.dialog_text = "Actualmente trabajas de %s.\n¿Quieres dejarlo y empezar a trabajar de %s?" % [nombre_actual, nombre_nuevo]
	_dialog_cambiar_trabajo.popup_centered(Vector2i(520, 220))

func _Confirmar_Cambiar_Trabajo() -> void:
	if _trabajo_pendiente == null:
		return
	var nuevo: Actividad_Fija_Trabajo = _trabajo_pendiente
	_trabajo_pendiente = null
	_Tomar_Trabajo(nuevo)

func _Cancelar_Cambiar_Trabajo() -> void:
	_trabajo_pendiente = null


func _Cumple_Requisitos_Trabajo(actividad: Actividad_Fija_Trabajo) -> bool:
	var errores: Array = []
	var nombres_progreso = ["Deporte", "Académico", "Manualidades"]
	for i in range(3):
		if Variables_Dinamicas.Progreso[i] < actividad.requisito_progreso[i]:
			errores.append("• %s ≥ %d (tienes %d)" % [
				nombres_progreso[i],
				actividad.requisito_progreso[i],
				Variables_Dinamicas.Progreso[i]
			])
	if actividad.requisito_cocina > 0 and Variables_Dinamicas.Progreso_Cocina < actividad.requisito_cocina:
		errores.append("• Cocina ≥ %d (tienes %d)" % [
			actividad.requisito_cocina,
			Variables_Dinamicas.Progreso_Cocina
		])
	for nombre_carrera in actividad.requisito_carrera:
		var tiene = false
		for carrera in Variables_Dinamicas.Carreras_Completadas:
			if carrera.nombre == nombre_carrera:
				tiene = true
				break
		if not tiene:
			errores.append("• Carrera: %s" % nombre_carrera.replace("_", " "))
	if errores.size() > 0:
		_Mostrar_Error_Requisito("Requisitos no cumplidos:\n" + "\n".join(errores))
		return false
	return true


var _dialog_requisito: AcceptDialog = null

func _Mostrar_Error_Requisito(mensaje: String) -> void:
	if _dialog_requisito == null:
		_dialog_requisito = AcceptDialog.new()
		_dialog_requisito.title = "Requisitos no cumplidos"
		add_child(_dialog_requisito)
	_dialog_requisito.dialog_text = mensaje
	_dialog_requisito.popup_centered(Vector2i(500, 220))


func Pulsar_Flecha_Atras() -> void:
	Gestionar_Visibilidad.Pulsar_Flecha_Atras(self)


###OPCIONES ACTIVIDADES
func Opciones_Actividades_Progreso() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Progreso",self)

func Opciones_Actividades_Necesidades_Basicas() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Necesidades_Basicas",self)

###ACTIVIDADES TERMINADAS
# Nuevo flujo: la actividad se elige primero y después se abre el selector de
# horario con una franja propuesta (o la seleccionada previamente en el calendario).
func Actividad_Terminada_Estudiar() -> void:
	_Abrir_Horario_Para_Actividad("Estudiar")

func Actividad_Terminada_Salir_A_Correr() -> void:
	_Abrir_Horario_Para_Actividad("Salir_A_Correr")

func Actividad_Terminada_Manualidades() -> void:
	_Abrir_Horario_Para_Actividad("Practicar_Manualidades")

func Actividad_Terminada_Duchar() -> void:
	_Abrir_Horario_Para_Actividad("Duchar")

func Actividad_Terminada_Dormir() -> void:
	_Abrir_Horario_Para_Actividad("Dormir")

func Actividad_Terminada_Comer() -> void:
	var modo := "Comer_Tupper" if not Variables_Dinamicas.Tuppers.is_empty() else "Comer_Basura"
	_Abrir_Horario_Para_Actividad(modo)

func _Abrir_Modal_Tuppers_Al_Entrar() -> void:
	if not modo_alimentacion or actividad_seleccionada != "Comer_Tupper":
		return
	if Variables_Dinamicas.Tuppers.is_empty():
		return
	_Abrir_Modal_Tuppers()

func Actividad_Terminada_Cocinar() -> void:
	_Abrir_Horario_Para_Actividad("Cocinar")

func Actividad_Terminada_Ver_La_Television() -> void:
	_Abrir_Horario_Para_Actividad("Ver_La_Television")

func Actividad_Terminada_Salir_De_Fiesta() -> void:
	_Abrir_Horario_Para_Actividad("Salir_De_Fiesta")


var _dialog_prioridad: AcceptDialog = null

func _Mostrar_Error_Prioridad() -> void:
	if _dialog_prioridad == null:
		_dialog_prioridad = AcceptDialog.new()
		_dialog_prioridad.title = "Actividad bloqueada"
		add_child(_dialog_prioridad)
	_dialog_prioridad.dialog_text = "No puedes colocar esta actividad aquí:\nhay trabajo o examen programado en ese horario."
	_dialog_prioridad.popup_centered(Vector2i(500, 200))


var _dialog_fiesta: AcceptDialog = null

func _Mostrar_Error_Fiesta(motivo: String) -> void:
	if _dialog_fiesta == null:
		_dialog_fiesta = AcceptDialog.new()
		_dialog_fiesta.title = "Horario de fiesta no válido"
		add_child(_dialog_fiesta)
	_dialog_fiesta.dialog_text = motivo
	_dialog_fiesta.popup_centered(Vector2i(520, 190))


var _dialog_alimentacion: AcceptDialog = null

func _Mostrar_Error_Alimentacion(mensaje: String) -> void:
	if _dialog_alimentacion == null:
		_dialog_alimentacion = AcceptDialog.new()
		_dialog_alimentacion.title = "No se puede programar"
		add_child(_dialog_alimentacion)
	_dialog_alimentacion.dialog_text = mensaje
	_dialog_alimentacion.popup_centered(Vector2i(540, 190))


func Crear_Actividad(actividad):
	var horario = actividades_reloj_gui.horario
	if horario == null:
		return
	if actividad == "Salir_De_Fiesta":
		var validacion: Dictionary = Actividades.Validar_Horario_Fiesta(
			horario.dia_inicio_a_int(),
			horario.hora_inicio_texto.text.to_int(),
			horario.minuto_inicio_texto.text.to_int(),
			horario.dia_final_a_int(),
			horario.hora_final_texto.text.to_int(),
			horario.minuto_final_texto.text.to_int(),
			mirar_semana)
		if not bool(validacion.get("valido", false)):
			_Mostrar_Error_Fiesta(str(validacion.get("motivo", "")))
			return
	elif actividad == "Cocinar":
		var duracion: int = Actividades.Calcular_Duracion_Rango(
			horario.dia_inicio_a_int(),
			horario.hora_inicio_texto.text.to_int(),
			horario.minuto_inicio_texto.text.to_int(),
			horario.dia_final_a_int(),
			horario.hora_final_texto.text.to_int(),
			horario.minuto_final_texto.text.to_int())
		var validacion_cocina: Dictionary = Actividades.Validar_Horario_Cocinar(duracion)
		if not bool(validacion_cocina.get("valido", false)):
			_Mostrar_Error_Alimentacion(str(validacion_cocina.get("motivo", "")))
			return
	elif actividad == "Comer_Tupper":
		if Variables_Dinamicas.Tuppers.is_empty():
			# Sin tuppers, el bloque se programa directamente como comida rápida.
			actividad = "Comer_Basura"
	var ok = horario.Crear_Actividad(mirar_semana, actividad)
	if not ok:
		_Mostrar_Error_Prioridad()
		return
	Actividad_Terminada()

func Actividad_Terminada():
	actividad_seleccionada = ""
	Detener_Blink()
	_on_boton_actividades_pressed()
	# Solo limpiar el calendario si el flujo pasó por él (Temporales). En el flujo
	# de Fijas (Trabajo → Comida Rápida) nunca se inicializó bloque_columna.
	if actividades_bloque_gui.bloque_columna != null:
		actividades_bloque_gui.bloque_columna.limpiar_horas_del_horario()


func _Confirmar_Ir_A_La_Calle():
	Actividades.Ir_A_La_Calle()
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Economia()


# ---------------- Tienda ----------------

## La rejilla y las tarjetas viven en `Tienda_Objetos.gd`; aquí solo se
## orquesta la pantalla y se refresca el dinero tras comprar o vender.
func _Actualizar_Tienda_UI():
	var tienda := get_node_or_null("Tienda")
	if tienda != null and tienda.has_method("Refrescar"):
		tienda.call("Refrescar")
	_Actualizar_Nav_Activa()


func _on_perfil_button_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Visibilizar_Perfil(self)
	_Ocultar_Home()
	Estilos_UI.animar_entrada($Pantalla_Mensajes)
	_on_perfil_tab_mensajes_pressed()
	_Actualizar_Nav_Activa()

# ---------------- Pestañas del perfil ----------------

func _on_perfil_tab_info_pressed():
	_Marcar_Tab_Perfil("Tab_Info")
	$Pantalla_Mensajes/Panel_Info.visible = true
	$Pantalla_Mensajes/Lista_Mensajes.visible = false
	$Pantalla_Mensajes/Panel_Apuntes.visible = false
	$Pantalla_Mensajes/Panel_Despensa.visible = false
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Info()
	_Actualizar_Nav_Activa()

func _on_perfil_tab_mensajes_pressed():
	_Marcar_Tab_Perfil("Tab_Mensajes")
	$Pantalla_Mensajes/Panel_Info.visible = false
	$Pantalla_Mensajes/Lista_Mensajes.visible = true
	$Pantalla_Mensajes/Panel_Apuntes.visible = false
	$Pantalla_Mensajes/Panel_Despensa.visible = false
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Lista_Mensajes()
	_Actualizar_Nav_Activa()

func _on_perfil_tab_apuntes_pressed():
	_Marcar_Tab_Perfil("Tab_Apuntes")
	$Pantalla_Mensajes/Panel_Info.visible = false
	$Pantalla_Mensajes/Lista_Mensajes.visible = false
	$Pantalla_Mensajes/Panel_Apuntes.visible = true
	$Pantalla_Mensajes/Panel_Despensa.visible = false
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Apuntes()
	_Actualizar_Nav_Activa()


func _on_perfil_tab_despensa_pressed():
	_Marcar_Tab_Perfil("Tab_Despensa")
	$Pantalla_Mensajes/Panel_Info.visible = false
	$Pantalla_Mensajes/Lista_Mensajes.visible = false
	$Pantalla_Mensajes/Panel_Apuntes.visible = false
	$Pantalla_Mensajes/Panel_Despensa.visible = true
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Despensa()
	_Actualizar_Nav_Activa()

# ---------------- Tab Despensa (tuppers) ----------------

func _Renderizar_Despensa():
	var panel = get_node_or_null("Pantalla_Mensajes/Panel_Despensa")
	if panel == null:
		return
	var lista := panel.get_node_or_null("Scroll_Tuppers/VBox_Tuppers") as VBoxContainer
	var scroll := panel.get_node_or_null("Scroll_Tuppers") as ScrollContainer
	var sin_tuppers := panel.get_node_or_null("Sin_Tuppers_Label") as Label
	if lista == null or scroll == null or sin_tuppers == null:
		return
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()

	_firma_tuppers_ui = _Firma_Tuppers()
	var hay: bool = not Variables_Dinamicas.Tuppers.is_empty()
	sin_tuppers.visible = not hay
	scroll.visible = hay
	if not hay:
		return

	for i in range(Variables_Dinamicas.Tuppers.size()):
		var tupper = Variables_Dinamicas.Tuppers[i]
		if not (tupper is Dictionary):
			continue
		var seleccionado: bool = int(Variables_Dinamicas.Tupper_Seleccionado_Idx) == i
		var fila := Tupper_UI.crear_fila(i, tupper, seleccionado,
			_Elegir_Tupper_Desde_Perfil.bind(i), _Tirar_Tupper_Desde_Perfil.bind(i))
		lista.add_child(fila)


func _Elegir_Tupper_Desde_Perfil(indice: int) -> void:
	if indice < 0 or indice >= Variables_Dinamicas.Tuppers.size():
		return
	Variables_Dinamicas.Tupper_Seleccionado_Idx = indice
	Guardar_Variables_Dinamicas.save_game()
	_Renderizar_Despensa()
	_Actualizar_Preview_Alimentacion()


func _Tirar_Tupper_Desde_Perfil(indice: int) -> void:
	if indice < 0 or indice >= Variables_Dinamicas.Tuppers.size():
		return
	Variables_Dinamicas.Tuppers.remove_at(indice)
	var seleccionado: int = int(Variables_Dinamicas.Tupper_Seleccionado_Idx)
	if seleccionado == indice:
		Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	elif seleccionado > indice:
		Variables_Dinamicas.Tupper_Seleccionado_Idx = seleccionado - 1
	Guardar_Variables_Dinamicas.save_game()
	_Renderizar_Despensa()
	_Actualizar_Preview_Alimentacion()


func _Actualizar_Tuppers_UI_Si_Visible() -> void:
	var panel = get_node_or_null("Pantalla_Mensajes/Panel_Despensa")
	if panel != null and panel.visible:
		var firma: String = _Firma_Tuppers()
		if firma == _firma_tuppers_ui:
			return
		_firma_tuppers_ui = firma
		_Renderizar_Despensa()


var _firma_tuppers_ui: String = ""

func _Firma_Tuppers() -> String:
	var partes: Array[String] = [str(int(Variables_Dinamicas.Minute) / 60), str(int(Variables_Dinamicas.Tupper_Seleccionado_Idx))]
	for t in Variables_Dinamicas.Tuppers:
		if t is Dictionary:
			partes.append("%d:%s:%d" % [
				int(t.get("id", 0)),
				Alimentacion.Formatear_Porcentaje(float(t.get("porcentaje_restante", 0.0))),
				int(t.get("minuto_caducidad", 0))])
	return "|".join(partes)

# ---------------- Tab Info ----------------

func _Renderizar_Info():
	var vbox = $Pantalla_Mensajes/Panel_Info/Scroll_Info/VBox_Info
	for child in vbox.get_children():
		child.queue_free()

	var edad = Variables_Estaticas.Calcular_Edad()
	var personalidad = Variables_Estaticas.Personalidad.replace("_", " ").capitalize()
	var ap := Apariencia_Personaje.normalizar(Variables_Estaticas.Apariencia)
	var nombre_prota := str(ap.get("nombre", "")).strip_edges()
	var genero_txt := Apariencia_Personaje.etiqueta_genero(ap)

	# Tarjeta cabecera con retrato del personaje personalizado
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))
	vbox.add_child(hero)
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 16)
	hm.add_theme_constant_override("margin_right", 16)
	hm.add_theme_constant_override("margin_top", 14)
	hm.add_theme_constant_override("margin_bottom", 14)
	hero.add_child(hm)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 14)
	hm.add_child(hrow)
	hrow.add_child(Estilos_UI.avatar_personaje(68, Estilos_UI.ROJO_BIT, 3,
		Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(ap), true))
	var hcol := VBoxContainer.new()
	hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hcol.alignment = BoxContainer.ALIGNMENT_CENTER
	hcol.add_theme_constant_override("separation", 3)
	hrow.add_child(hcol)
	hcol.add_child(Estilos_UI.titulo(nombre_prota if nombre_prota != "" else "Tu personaje", 20, Estilos_UI.TINTA))
	hcol.add_child(Estilos_UI.texto("%s · %d años · %s" % [genero_txt, edad, personalidad], 13, Estilos_UI.TINTA_SUAVE, 600))

	var btn_vestuario := Estilos_UI.boton("Cambiar de atuendo", "suave", "shirt", Estilos_UI.AZUL, 44)
	btn_vestuario.name = "Boton_Vestuario_Perfil"
	btn_vestuario.pressed.connect(_on_vestuario_button_pressed)
	vbox.add_child(btn_vestuario)

	_Info_Seccion(vbox, "Personaje")
	var grupo_p := _Crear_Grupo_Info(vbox)
	if nombre_prota != "":
		_Info_Fila(grupo_p, "Nombre", nombre_prota)
	_Info_Fila(grupo_p, "Género", genero_txt)
	_Info_Fila(grupo_p, "Edad", str(edad) + " años")
	_Info_Fila(grupo_p, "Etapa de vida", Envejecimiento_Personaje.etapa(edad))
	_Info_Fila(grupo_p, "Personalidad", personalidad)
	_Info_Fila(grupo_p, "Dinero", str(int(Variables_Dinamicas.Dinero)) + " €")
	_Info_Fila(grupo_p, "Vivienda", "En la calle" if Variables_Dinamicas.En_La_Calle else "Con alquiler")
	var nombre_atuendo: String = Sistema_Cocina.Obtener_Nombre_Legible_Ropa(Sistema_Cocina.Obtener_Clave_Ropa_Equipada())
	_Info_Fila(grupo_p, "Atuendo", nombre_atuendo, false)

	_Info_Seccion(vbox, "Muebles equipados")
	var grupo_m := _Crear_Grupo_Info(vbox)
	var muebles_info := [
		["Dormir", "Dormir"],
		["Comer", "Comer"],
		["Duchar", "Duchar"],
		["Salon", "Salón"],
		["Estudio", "Estudio"],
		["Cocina", "Cocina"],
	]
	for i in range(muebles_info.size()):
		var cat: String = muebles_info[i][0]
		var objeto := Variables_Estaticas.Obtener_Objeto_Seleccionado(cat)
		var valor := "Sin asignar"
		if objeto != null:
			valor = objeto.nombre_para_mostrar()
			if objeto.etiqueta_efecto != "":
				valor += " · " + objeto.etiqueta_efecto
		_Info_Fila(grupo_m, muebles_info[i][1], valor, i < muebles_info.size() - 1)

	_Info_Seccion(vbox, "Progreso")
	var grupo_pr := _Crear_Grupo_Info(vbox)
	_Info_Fila(grupo_pr, "Deporte", str(Variables_Dinamicas.Progreso[0]) + " / 100")
	_Info_Fila(grupo_pr, "Académico", str(Variables_Dinamicas.Progreso[1]) + " / 100")
	_Info_Fila(grupo_pr, "Manualidades", str(Variables_Dinamicas.Progreso[2]) + " / 100")
	_Info_Fila(grupo_pr, "Cocina", str(Variables_Dinamicas.Progreso_Cocina) + " / 100")
	_Info_Fila(grupo_pr, "Maestría Culinaria", "Rango %d/9" % Sistema_Cocina.Obtener_Rango_Logro())
	_Info_Fila(grupo_pr, "Inversiones", str(Variables_Dinamicas.Progreso_Inversion) + " / 100", false)

	_Info_Seccion(vbox, "Habilidades innatas")
	var grupo_h := _Crear_Grupo_Info(vbox)
	var nombres_hab = ["Deporte", "Inteligencia", "Destreza manual", "Memoria", "Liderazgo", "Paciencia", "Sangre fría"]
	var total_h: int = min(nombres_hab.size(), Variables_Estaticas.Habilidades.size())
	for i in range(total_h):
		var innato: int = int(Variables_Estaticas.Habilidades[i])
		var mostrado: int = int(Variables_Dinamicas.Habilidades_Mostradas[i]) if i < Variables_Dinamicas.Habilidades_Mostradas.size() else 0
		# Solo se revela el valor exacto cuando se ha descubierto el límite natural.
		var valor_h: String = str(innato) if mostrado >= innato else "?"
		_Info_Fila(grupo_h, nombres_hab[i], valor_h + " / 100", i < total_h - 1)


func _Crear_Grupo_Info(parent: VBoxContainer) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 1))
	parent.add_child(card)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	card.add_child(list)
	return list


func _Info_Seccion(vbox: VBoxContainer, titulo: String):
	var label = Estilos_UI.texto(titulo.to_upper(), 11, Estilos_UI.TINTA_FANTASMA, 700)
	label.custom_minimum_size = Vector2(0, 28)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	vbox.add_child(label)


func _Info_Fila(grupo: VBoxContainer, clave: String, valor: String, con_divisor: bool = true):
	var margen := MarginContainer.new()
	margen.custom_minimum_size = Vector2(0, 48)
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)
	grupo.add_child(margen)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	margen.add_child(h)

	var lbl_clave := Estilos_UI.texto(clave, 14, Estilos_UI.TINTA_SUAVE, 500)
	lbl_clave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_clave.size_flags_stretch_ratio = 0.44
	h.add_child(lbl_clave)

	var lbl_valor := Estilos_UI.texto(valor, 14, Estilos_UI.TINTA, 700)
	lbl_valor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_valor.size_flags_stretch_ratio = 0.56
	h.add_child(lbl_valor)

	if con_divisor:
		grupo.add_child(Estilos_UI.divisor_horizontal())

# ---------------- Tab Mensajes ----------------

func _Renderizar_Lista_Mensajes():
	var vbox = $Pantalla_Mensajes/Lista_Mensajes/VBoxContainer
	for child in vbox.get_children():
		child.queue_free()

	var mensajes_ordenados = Variables_Dinamicas.Mensajes.duplicate()
	mensajes_ordenados.sort_custom(func(a, b): return a.minuto > b.minuto)

	if mensajes_ordenados.is_empty():
		var vacio := PanelContainer.new()
		vacio.custom_minimum_size = Vector2(0, 128)
		vacio.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 1))
		var mv := MarginContainer.new()
		mv.add_theme_constant_override("margin_left", 20)
		mv.add_theme_constant_override("margin_right", 20)
		mv.add_theme_constant_override("margin_top", 20)
		mv.add_theme_constant_override("margin_bottom", 20)
		vacio.add_child(mv)
		var vv := VBoxContainer.new()
		vv.alignment = BoxContainer.ALIGNMENT_CENTER
		vv.add_theme_constant_override("separation", 6)
		mv.add_child(vv)
		vv.add_child(Estilos_UI.icono_rect("message-circle", 24, Estilos_UI.TINTA_FANTASMA))
		vv.add_child(Estilos_UI.texto("Bandeja vacía", 15, Estilos_UI.TINTA, 700))
		vv.add_child(Estilos_UI.texto("Aquí recibirás avisos de trabajo, exámenes y eventos.", 13, Estilos_UI.TINTA_SUAVE))
		vbox.add_child(vacio)
		return

	for i in range(mensajes_ordenados.size()):
		var mensaje = mensajes_ordenados[i]
		var indice_original = Variables_Dinamicas.Mensajes.find(mensaje)
		var fecha_hora = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(mensaje.minuto)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 84)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = ""
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var es_nuevo: bool = not mensaje.leido
		var normal := Estilos_UI.caja(Color("#fff6f6") if es_nuevo else Estilos_UI.SUPERFICIE, 14,
			Color("#fecaca") if es_nuevo else Estilos_UI.BORDE, 1, 1)
		normal.border_width_bottom = 2
		if es_nuevo:
			normal.border_width_left = 4
			normal.border_color = Estilos_UI.ROJO_BIT
		var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#fee2e2") if es_nuevo else Estilos_UI.SUPERFICIE_2
		hover.border_color = Estilos_UI.ROJO_BIT if es_nuevo else Estilos_UI.BORDE_FUERTE
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(_Mostrar_Mensaje.bind(indice_original))
		Estilos_UI.animar_presion(btn)

		var margen := MarginContainer.new()
		margen.set_anchors_preset(Control.PRESET_FULL_RECT)
		margen.add_theme_constant_override("margin_left", 14)
		margen.add_theme_constant_override("margin_right", 14)
		margen.add_theme_constant_override("margin_top", 12)
		margen.add_theme_constant_override("margin_bottom", 12)
		margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(margen)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margen.add_child(h)

		var circulo := PanelContainer.new()
		circulo.custom_minimum_size = Vector2(40, 40)
		circulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		circulo.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Estilos_UI.PRIMARIO_SUAVE if not mensaje.leido else Estilos_UI.SUPERFICIE_2, 12, Color(0, 0, 0, 0), 0, 0))
		var ic := Estilos_UI.icono_rect("message-circle", 19,
			Estilos_UI.PRIMARIO if not mensaje.leido else Estilos_UI.TINTA_FANTASMA)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		circulo.add_child(ic)
		h.add_child(circulo)

		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)

		var titulo := Estilos_UI.texto(mensaje.titulo, 15,
			Estilos_UI.TINTA if not mensaje.leido else Estilos_UI.TINTA_SUAVE, 700 if not mensaje.leido else 500)
		titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(titulo)

		var fecha := Estilos_UI.texto(fecha_hora, 12, Estilos_UI.TINTA_FANTASMA, 400)
		fecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(fecha)

		var chevron := Estilos_UI.icono_rect("chevron-right", 18, Estilos_UI.TINTA_FANTASMA)
		chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(chevron)

		vbox.add_child(btn)

func _Mostrar_Mensaje(indice: int):
	var mensaje = Variables_Dinamicas.Mensajes[indice]
	var contenido = $Pantalla_Mensajes/Contenido_Mensaje
	contenido.get_node("Titulo_Mensaje_Label").text = mensaje.titulo
	contenido.get_node("Descripcion_Mensaje_Label").text = mensaje.descripcion
	contenido.get_node("Hora_Mensaje_Label").text = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(mensaje.minuto)
	contenido.visible = true
	if not mensaje.leido:
		mensaje.leido = true
		Guardar_Variables_Dinamicas.save_game()
		_Actualizar_Badges()

func _on_mensajes_boton_volver_pressed():
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_on_perfil_tab_mensajes_pressed()

func _on_mensajes_boton_cerrar_pressed():
	Quitar_Todo()

# ---------------- Tab Inventario (libros) ----------------

func _Renderizar_Apuntes():
	var panel = $Pantalla_Mensajes/Panel_Apuntes
	var grid = panel.get_node("Scroll_Inventario/Grid_Libros")
	var scroll = panel.get_node("Scroll_Inventario")
	var sin_libros = panel.get_node("Sin_Apuntes_Label")

	for hijo in grid.get_children():
		hijo.queue_free()

	var libros = []
	var carrera_actual = Variables_Dinamicas.Carrera_Actual
	if carrera_actual != null:
		for libro in carrera_actual.libros_desbloqueados:
			libros.append({"carrera": carrera_actual, "libro": libro})
	for c in Variables_Dinamicas.Carreras_Completadas:
		for libro in c.libros_desbloqueados:
			libros.append({"carrera": c, "libro": libro})

	if libros.is_empty():
		sin_libros.visible = true
		scroll.visible = false
		return

	sin_libros.visible = false
	scroll.visible = true

	for item in libros:
		var año: int = str(item.libro).replace("Año ", "").replace("Anio_", "").to_int()
		grid.add_child(_Crear_Miniatura_Libro(item.carrera, año))

	for c in Variables_Dinamicas.Carreras_Completadas:
		grid.add_child(_Crear_Miniatura_Diploma(c))


func _Crear_Miniatura_Libro(carrera: Carrera, año: int) -> Control:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 6)

	var paleta := [Color("#1e293b"), Color("#1d4ed8"), Color("#0f766e"), Color("#6d28d9"), Color("#b45309")]
	var color: Color = paleta[absi(carrera.nombre.hash()) % paleta.size()]

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 156)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn := Estilos_UI.caja(color, 14, color.darkened(0.18), 0, 2)
	var sh := Estilos_UI.caja(color.lightened(0.06), 14, color.darkened(0.10), 0, 3)
	btn.add_theme_stylebox_override("normal", sn)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_Abrir_Libro.bind(carrera, año))

	var lomo := ColorRect.new()
	lomo.color = color.darkened(0.24)
	lomo.position = Vector2(0, 0)
	lomo.size = Vector2(10, 156)
	lomo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lomo)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 20
	v.offset_right = -12
	v.offset_top = 14
	v.offset_bottom = -14
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(v)

	var ic := Estilos_UI.icono_rect("book-open", 30, Color.WHITE)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var anio_lbl := Estilos_UI.texto("Año %d" % año, 13, Color(1, 1, 1, 0.92), 700)
	anio_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anio_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(anio_lbl)
	var tipo_lbl := Estilos_UI.texto("APUNTES", 10, Color(1, 1, 1, 0.65), 600)
	tipo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tipo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(tipo_lbl)
	outer.add_child(btn)

	var lbl := Estilos_UI.texto(carrera.nombre.replace("_", " ").capitalize() + " · Año " + str(año),
		12, Estilos_UI.TINTA, 600)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(lbl)
	return outer


func _Crear_Miniatura_Diploma(carrera: Carrera) -> Control:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 6)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 156)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn := Estilos_UI.caja(Color("#fef3c7"), 14, Color("#d97706"), 1, 2)
	var sh := Estilos_UI.caja(Color("#fde68a"), 14, Color("#b45309"), 1, 3)
	btn.add_theme_stylebox_override("normal", sn)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_Abrir_Diploma.bind(carrera))

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 14
	v.offset_bottom = -14
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(v)
	var ic := Estilos_UI.icono_rect("graduation-cap", 32, Color("#b45309"))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var titulo := Estilos_UI.texto("TÍTULO OFICIAL", 11, Color("#92400e"), 700)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(titulo)
	outer.add_child(btn)

	var lbl := Estilos_UI.texto(carrera.nombre.replace("_", " ").capitalize(), 12, Estilos_UI.TINTA, 600)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(lbl)
	return outer


func _Abrir_Libro(carrera: Carrera, año: int):
	var paginas = _Parsear_Libro(carrera, año)
	var lector_script = load("res://Scripts/GUI/Escena_Principal/Lector_Libro.gd")
	var lector = CanvasLayer.new()
	lector.set_script(lector_script)
	add_child(lector)
	lector.configurar(paginas, carrera.nombre, año, carrera.emoji)


func _Abrir_Diploma(carrera: Carrera):
	var suma_notas = 0.0
	var num_aprobados = 0
	for entrada in carrera.historial_notas:
		if entrada.get("aprobado", false):
			suma_notas += entrada.get("nota_final", 0.0)
			num_aprobados += 1
	var nota_media = suma_notas / num_aprobados if num_aprobados > 0 else 0.0

	var paginas = [{
		"type": "diploma",
		"carrera_nombre": carrera.nombre,
		"nota_media": nota_media,
		"emoji": "🎓"
	}]
	var lector_script = load("res://Scripts/GUI/Escena_Principal/Lector_Libro.gd")
	var lector = CanvasLayer.new()
	lector.set_script(lector_script)
	add_child(lector)
	lector.configurar(paginas, carrera.nombre, 0, "🎓")


func _Parsear_Libro(carrera: Carrera, año: int) -> Array:
	var paginas = []
	var ruta = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_%s_anio%d.txt" % [carrera.slug_contenido, año]
	var libro_titulo = "Fundamentos de Programación"

	if not FileAccess.file_exists(ruta):
		paginas.append({"type": "cover", "title": libro_titulo})
		return paginas

	var texto = FileAccess.get_file_as_string(ruta)
	var lineas = texto.split("\n")

	if lineas.size() > 0:
		var idx = lineas[0].find(": ")
		if idx >= 0:
			libro_titulo = lineas[0].substr(idx + 2).capitalize()

	paginas.append({"type": "cover", "title": libro_titulo})

	var regex = RegEx.new()
	regex.compile("^(\\d+)\\.\\s+(.+)$")
	var sec_titulo = ""
	var sec_cuerpo = []

	for i in range(1, lineas.size()):
		var m = regex.search(lineas[i])
		if m:
			if sec_titulo != "":
				paginas.append({
					"type": "content",
					"chapter": "Año %d" % año,
					"title": sec_titulo,
					"body": "\n".join(sec_cuerpo).strip_edges()
				})
			sec_titulo = m.get_string(2)
			sec_cuerpo = []
		elif sec_titulo != "":
			sec_cuerpo.append(lineas[i])

	if sec_titulo != "":
		paginas.append({
			"type": "content",
			"chapter": "Año %d" % año,
			"title": sec_titulo,
			"body": "\n".join(sec_cuerpo).strip_edges()
		})

	return paginas


func _on_tienda_button_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Visibilizar_Tienda(self)
	_Ocultar_Home()
	Estilos_UI.animar_entrada($Tienda)
	if $Tienda.has_method("Abrir_Categoria"):
		$Tienda.call("Abrir_Categoria", "Dormir")
	_Actualizar_Tienda_UI()
	_Actualizar_Nav_Activa()


## Abre la tienda desde su acceso rápido de la cabecera (junto al dinero).
## La flecha de vuelta lleva al inicio.
func _on_tienda_tab_pressed():
	_tienda_origen = "home"
	_on_tienda_button_pressed()


func _on_tienda_flecha_atras_pressed():
	var origen := _tienda_origen
	_tienda_origen = "home"
	if origen == "necesidades":
		_on_boton_necesidades_basicas_pressed()
	else:
		Quitar_Todo()


func _Ir_A_Categoria_Tienda(categoria: String) -> void:
	Gestionar_Visibilidad.Mostrar_Categoria_Tienda(self, categoria)
	_Actualizar_Tienda_UI()


func _on_tab_dormir_pressed(): _Ir_A_Categoria_Tienda("Dormir")
func _on_tab_comer_pressed(): _Ir_A_Categoria_Tienda("Comer")
func _on_tab_duchar_pressed(): _Ir_A_Categoria_Tienda("Duchar")
func _on_tab_salon_pressed(): _Ir_A_Categoria_Tienda("Salon")
func _on_tab_estudio_pressed(): _Ir_A_Categoria_Tienda("Estudio")
func _on_tab_cocina_pressed(): _Ir_A_Categoria_Tienda("Cocina")
func _on_tab_ventajas_pressed(): _Ir_A_Categoria_Tienda("Ventajas")


func _Tienda_Comprar(clave: String):
	if Actividades.Comprar_Objeto(clave):
		_Actualizar_Tienda_UI()
		Actualizar_Dinero()


func _Tienda_Vender(clave: String):
	if Actividades.Vender_Objeto(clave):
		_Actualizar_Tienda_UI()
		Actualizar_Dinero()


func _Tienda_Elegir(categoria: String, clave: String):
	if Actividades.Seleccionar_Objeto(categoria, clave):
		_Actualizar_Tienda_UI()


# ---------------- Sistema de Carreras Universitarias ----------------

const _MODAL_EXAMEN_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Examen.gd")
const _MODAL_SELECCIONAR_EXAMEN_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Examen.gd")
const _MODAL_SELECCIONAR_CARRERA_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Carrera.gd")
const _MODAL_RESULTADO_EXAMEN_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Resultado_Examen.gd")
const _MODAL_CARRERA_DEPORTIVA_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/UI/Modal_Carrera_Deportiva.gd")
const _LECTOR_LIBROS_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Lector_Libros.gd")

const _DIAS_NOMBRES = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sab", "Dom"]

func _En_Ventana_Examen(carrera: Carrera) -> bool:
	if carrera.hora_examen_dia < 0 or not carrera.matriculado:
		return false
	var es_dia_examen: bool
	if Variables_Estaticas.Modo_Rapido:
		es_dia_examen = (Variables_Dinamicas.Minute_Day == carrera.hora_examen_dia)
	else:
		var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
		es_dia_examen = (dia_semana_actual == carrera.hora_examen_dia)
	if not es_dia_examen:
		return false
	var minuto_del_dia = Variables_Dinamicas.Minute_Minute
	var hora_inicio = carrera.hora_examen_inicio
	return minuto_del_dia >= hora_inicio and minuto_del_dia < hora_inicio + 60

func _on_carrera_accion_pressed():
	var carrera = Variables_Dinamicas.Carrera_Actual

	# Sin carrera: abrir selector de carrera
	if carrera == null:
		_Abrir_Modal_Seleccionar_Carrera()
		return

	# Ver resultado
	if carrera.fin_de_semana_procesado:
		_Mostrar_Resultado_Examen(carrera)
		return

	# Hacer examen (ventana activa)
	if carrera.matriculado and _En_Ventana_Examen(carrera) and not carrera.examen_realizado_esta_semana:
		_Abrir_Modal_Examen(carrera)
		return

	# Prematriculado: permitir cambiar
	if carrera.prematriculado:
		_Abrir_Modal_Horario(carrera, false)
		return

	# Matricularse (L-Ma) o Prematricularse (Mi-Do); en Modo Rápido se decide según Hoy/Mañana
	if not carrera.matriculado and not carrera.prematriculado:
		var es_matricula_directa: bool
		if Variables_Estaticas.Modo_Rapido:
			es_matricula_directa = true
		else:
			var dia_semana = Variables_Dinamicas.Minute_Day % 7
			es_matricula_directa = dia_semana <= 1
		_Abrir_Modal_Horario(carrera, es_matricula_directa)

func _Abrir_Modal_Seleccionar_Carrera():
	var modal = _MODAL_SELECCIONAR_CARRERA_SCRIPT.new()
	add_child(modal)
	modal.carrera_elegida.connect(_on_carrera_elegida)
	modal.popup_centered()

func _on_carrera_elegida(script_path: String):
	var carrera = load(script_path).new()
	# Defensa en profundidad: el selector ya filtra las completadas, pero
	# revalidamos por si la señal llega manipulada.
	for c in Variables_Dinamicas.Carreras_Completadas:
		if c.nombre == carrera.nombre:
			return
	Variables_Dinamicas.Carrera_Actual = carrera
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Carrera()

func _Abrir_Modal_Horario(carrera: Carrera, es_matricula_directa: bool):
	var modal = _MODAL_SELECCIONAR_EXAMEN_SCRIPT.new()
	add_child(modal)
	modal.Configurar(carrera, es_matricula_directa)
	modal.examen_programado.connect(_on_horario_elegido.bind(carrera, es_matricula_directa))
	modal.popup_centered()

func _on_horario_elegido(dia: int, hora_minutos: int, carrera: Carrera, es_matricula_directa: bool):
	carrera.hora_examen_dia = dia
	carrera.hora_examen_inicio = hora_minutos
	if Variables_Estaticas.Modo_Rapido:
		es_matricula_directa = (dia == Variables_Dinamicas.Minute_Day)

	if es_matricula_directa:
		var costo_mat = Variables_Estaticas.Obtener_Costo_Matricula(carrera)
		if Variables_Dinamicas.Dinero < costo_mat:
			_Actualizar_Pantalla_Carrera()
			return
		Variables_Dinamicas.Dinero -= costo_mat
		carrera.dinero_matricula_gastado += costo_mat
		carrera.matriculado = true
		carrera.prematriculado = false
		Actividades.Escribir_Examen_En_Matriz(carrera)
	else:
		# Prematriculación: gratis, flexible hasta el Lunes 00:00
		carrera.prematriculado = true
		carrera.matriculado = false
		Actividades.Escribir_Examen_En_Matriz(carrera)

	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Carrera()
	Actualizar_Dinero()

func _Abrir_Modal_Examen(carrera: Carrera):
	var modal = _MODAL_EXAMEN_SCRIPT.new()
	add_child(modal)
	modal.Configurar(carrera)
	modal.examen_enviado.connect(_on_examen_enviado)
	modal.popup_centered()

func _on_examen_enviado(_nota_real: int):
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Carrera()

func _Mostrar_Resultado_Examen(carrera: Carrera):
	var modal = _MODAL_RESULTADO_EXAMEN_SCRIPT.new()
	add_child(modal)
	modal.Configurar(carrera)
	modal.cerrado.connect(_on_resultado_confirmado)
	modal.popup_centered()

func _on_resultado_confirmado():
	var carrera = Variables_Dinamicas.Carrera_Actual
	if carrera == null:
		return
	carrera.fin_de_semana_procesado = false
	carrera.hora_examen_dia = -1
	if carrera.completada:
		Variables_Dinamicas.Carreras_Completadas.append(carrera)
		Variables_Dinamicas.Carrera_Actual = null
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Carrera()

func _on_libros_button_pressed():
	var carrera = Variables_Dinamicas.Carrera_Actual
	if carrera == null or carrera.libros_desbloqueados.size() == 0:
		if Variables_Dinamicas.Carreras_Completadas.size() == 0:
			return
		carrera = Variables_Dinamicas.Carreras_Completadas[-1]
	if carrera.libros_desbloqueados.size() == 0:
		return
	var modal = _LECTOR_LIBROS_SCRIPT.new()
	add_child(modal)
	modal.Configurar(carrera)
	modal.popup_centered()


# ---------------- Sistema de Inversiones en Bolsa ----------------

var _pantalla_bolsa: Panel_Bolsa = null

func _on_economia_bolsa_pressed():
	_Abrir_Pantalla_Bolsa()

func _Crear_Pantalla_Bolsa():
	if _pantalla_bolsa != null and is_instance_valid(_pantalla_bolsa):
		return
	_pantalla_bolsa = Panel_Bolsa.new()
	_pantalla_bolsa.name = "Pantalla_Bolsa"
	_pantalla_bolsa.visible = false
	_pantalla_bolsa.z_index = 6
	_pantalla_bolsa.cerrado.connect(_on_pantalla_bolsa_cerrada)
	_pantalla_bolsa.dinero_cambiado.connect(_on_bolsa_dinero_cambiado)
	add_child(_pantalla_bolsa)

func _Abrir_Pantalla_Bolsa():
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	# Se reconstruye al abrir: Quitar_Todo oculta recursivamente todos los
	# controles de la pantalla anterior, incluidos los hijos de la bolsa.
	if _pantalla_bolsa != null and is_instance_valid(_pantalla_bolsa):
		remove_child(_pantalla_bolsa)
		_pantalla_bolsa.queue_free()
		_pantalla_bolsa = null
	_Crear_Pantalla_Bolsa()
	_pantalla_bolsa.Abrir()
	Actualizar_Dinero()
	Estilos_UI.animar_entrada(_pantalla_bolsa)
	_Actualizar_Nav_Activa()

func _on_pantalla_bolsa_cerrada():
	_on_economia_button_pressed()

func _on_bolsa_dinero_cambiado():
	Actualizar_Dinero()
	_Actualizar_Pantalla_Economia()

# ================================================================
# Pantalla Carrera (tab)
# ================================================================

var _pantalla_carrera: Control = null
const _UI_CARRERAS = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Carrera_Base.gd")

var _carrera_eyebrow: Label = null
var _carrera_nombre_label: Label = null
var _carrera_icono_badge: PanelContainer = null
var _carrera_icono_tex: TextureRect = null
var _carrera_badge: PanelContainer = null
var _carrera_status_label: Label = null
var _carrera_progreso_header: HBoxContainer = null
var _carrera_progreso_titulo: Label = null
var _carrera_progreso_bar: ProgressBar = null
var _carrera_progreso_pct: Label = null
var _carrera_progreso_row: HBoxContainer = null
var _carrera_timeline: HBoxContainer = null
var _carrera_action_btn: Button = null
var _carrera_libros_btn: Button = null
var _carrera_apuntes_titulo: Label = null
var _carrera_apuntes_sub: Label = null
var _carrera_guia_card: PanelContainer = null
var _carrera_consejo_card: PanelContainer = null
var _carrera_completadas_box: VBoxContainer = null
var _carrera_completadas_card: PanelContainer = null


func _Crear_Pantalla_Carrera():
	if _pantalla_carrera != null and is_instance_valid(_pantalla_carrera):
		return
	_pantalla_carrera = ColorRect.new()
	_pantalla_carrera.name = "Pantalla_Carrera"
	_pantalla_carrera.color = Estilos_UI.FONDO
	_pantalla_carrera.position = Vector2.ZERO
	_pantalla_carrera.size = Vector2(720, _Alto_Pantalla())
	_pantalla_carrera.z_index = 5
	_pantalla_carrera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantalla_carrera.visible = false

	Estilos_UI.Crear_Label_Titulo_Panel("Carrera universitaria", _pantalla_carrera, Estilos_UI.TINTA)
	Estilos_UI.Crear_Boton_Volver_Panel(_pantalla_carrera, Callable(self, "Quitar_Todo"))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 190)
	scroll.size = Vector2(680, _Alto_Pantalla() - 310.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_pantalla_carrera.add_child(scroll)
	var vbar := scroll.get_v_scroll_bar()
	vbar.custom_minimum_size = Vector2(6, 0)
	vbar.add_theme_stylebox_override("scroll", Estilos_UI.caja(Color(0, 0, 0, 0), 999, Color(0, 0, 0, 0), 0, 0))
	vbar.add_theme_stylebox_override("grabber", Estilos_UI.caja(Color("#c4cdd9"), 999, Color(0, 0, 0, 0), 0, 0))
	vbar.add_theme_stylebox_override("grabber_highlight", Estilos_UI.caja(Color("#9ba8b9"), 999, Color(0, 0, 0, 0), 0, 0))
	vbar.add_theme_stylebox_override("grabber_pressed", Estilos_UI.caja(Color("#9ba8b9"), 999, Color(0, 0, 0, 0), 0, 0))

	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_right", 8)
	scroll.add_child(margen)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	margen.add_child(vbox)

	# --- Tarjeta principal de la carrera ---
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	vbox.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 20)
	cm.add_theme_constant_override("margin_right", 20)
	cm.add_theme_constant_override("margin_top", 18)
	cm.add_theme_constant_override("margin_bottom", 18)
	card.add_child(cm)

	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 13)
	cm.add_child(cv)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 14)
	cv.add_child(cab)

	_carrera_icono_badge = PanelContainer.new()
	_carrera_icono_badge.custom_minimum_size = Vector2(60, 60)
	_carrera_icono_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_carrera_icono_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carrera_icono_badge.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(Estilos_UI.ROJO_BIT, 0.14), 18,
			Color(Estilos_UI.ROJO_BIT, 0.20), 1, 0))
	_carrera_icono_tex = Estilos_UI.icono_rect("graduation-cap", 30, Estilos_UI.PRIMARIO)
	cab.add_child(_carrera_icono_badge)
	_carrera_icono_badge.add_child(_carrera_icono_tex)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	cab.add_child(textos)

	_carrera_eyebrow = Estilos_UI.texto("VIDA UNIVERSITARIA", 10, Estilos_UI.TINTA_FANTASMA, 700)
	textos.add_child(_carrera_eyebrow)

	_carrera_nombre_label = Estilos_UI.titulo("Da el salto a la universidad", 22, Estilos_UI.TINTA)
	_carrera_nombre_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_carrera_nombre_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(_carrera_nombre_label)

	_carrera_badge = Estilos_UI.pill_estado("Disponible", Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL)
	_carrera_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(_carrera_badge)

	_carrera_status_label = Estilos_UI.parrafo("", 14, Estilos_UI.TINTA_SUAVE)
	cv.add_child(_carrera_status_label)

	_carrera_progreso_header = HBoxContainer.new()
	_carrera_progreso_header.add_theme_constant_override("separation", 7)
	cv.add_child(_carrera_progreso_header)
	_carrera_progreso_header.add_child(Estilos_UI.icono_rect("trending-up", 15, Estilos_UI.TINTA_FANTASMA))
	_carrera_progreso_titulo = Estilos_UI.texto("Progreso del curso", 12, Estilos_UI.TINTA_SUAVE, 600)
	_carrera_progreso_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_carrera_progreso_header.add_child(_carrera_progreso_titulo)

	_carrera_progreso_row = HBoxContainer.new()
	_carrera_progreso_row.add_theme_constant_override("separation", 10)
	cv.add_child(_carrera_progreso_row)

	_carrera_progreso_bar = ProgressBar.new()
	_carrera_progreso_bar.custom_minimum_size = Vector2(0, 14)
	_carrera_progreso_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_carrera_progreso_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_carrera_progreso_bar.show_percentage = false
	_carrera_progreso_bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	_carrera_progreso_bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Estilos_UI.PRIMARIO))
	_carrera_progreso_row.add_child(_carrera_progreso_bar)

	_carrera_progreso_pct = Estilos_UI.texto("0%", 13, Estilos_UI.PRIMARIO, 700)
	_carrera_progreso_pct.custom_minimum_size = Vector2(42, 0)
	_carrera_progreso_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_carrera_progreso_row.add_child(_carrera_progreso_pct)

	_carrera_timeline = HBoxContainer.new()
	_carrera_timeline.add_theme_constant_override("separation", 6)
	cv.add_child(_carrera_timeline)

	_carrera_action_btn = Estilos_UI.boton("Elegir mi carrera", "exito", "graduation-cap",
		Estilos_UI.EXITO, 54)
	_carrera_action_btn.pressed.connect(_on_carrera_accion_pressed)
	cv.add_child(_carrera_action_btn)

	# --- Acceso a apuntes ---
	_carrera_libros_btn = Button.new()
	_carrera_libros_btn.custom_minimum_size = Vector2(0, 74)
	_carrera_libros_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_carrera_libros_btn.text = ""
	_carrera_libros_btn.set_meta("_estilo_propio", true)
	Estilos_UI.aplicar_estilo_boton(_carrera_libros_btn, "tarjeta", Estilos_UI.AZUL)
	_carrera_libros_btn.pressed.connect(_on_libros_button_pressed)
	_carrera_libros_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	vbox.add_child(_carrera_libros_btn)

	var fila_libros := HBoxContainer.new()
	fila_libros.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila_libros.offset_left = 14
	fila_libros.offset_right = -14
	fila_libros.offset_top = 10
	fila_libros.offset_bottom = -10
	fila_libros.add_theme_constant_override("separation", 12)
	fila_libros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carrera_libros_btn.add_child(fila_libros)
	fila_libros.add_child(Estilos_UI.badge_icono("library", 40, 20, Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL, 11))
	var textos_libros := VBoxContainer.new()
	textos_libros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos_libros.alignment = BoxContainer.ALIGNMENT_CENTER
	textos_libros.add_theme_constant_override("separation", 2)
	textos_libros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_libros.add_child(textos_libros)
	var lbl_libros := Estilos_UI.texto("Apuntes del curso", 15, Estilos_UI.TINTA, 700)
	lbl_libros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos_libros.add_child(lbl_libros)
	_carrera_apuntes_titulo = lbl_libros
	_carrera_apuntes_sub = Estilos_UI.texto("Consulta el temario desbloqueado", 12,
		Estilos_UI.TINTA_SUAVE, 500)
	_carrera_apuntes_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos_libros.add_child(_carrera_apuntes_sub)
	var chev_libros := Estilos_UI.icono_rect("chevron-right", 19, Estilos_UI.TINTA_FANTASMA)
	chev_libros.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_libros.add_child(chev_libros)

	# --- Cómo funciona (sin carrera) ---
	_carrera_guia_card = PanelContainer.new()
	_carrera_guia_card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 18, Estilos_UI.BORDE, 1, 1))
	vbox.add_child(_carrera_guia_card)
	var gm := MarginContainer.new()
	gm.add_theme_constant_override("margin_left", 18)
	gm.add_theme_constant_override("margin_right", 18)
	gm.add_theme_constant_override("margin_top", 16)
	gm.add_theme_constant_override("margin_bottom", 16)
	_carrera_guia_card.add_child(gm)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 12)
	gm.add_child(gv)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 8)
	gv.add_child(gh)
	gh.add_child(Estilos_UI.icono_rect("sparkles", 16, Estilos_UI.PRIMARIO))
	gh.add_child(Estilos_UI.texto("Cómo funciona", 15, Estilos_UI.TINTA, 700))
	gv.add_child(_Crear_Paso_Guia("graduation-cap", "Elige tu titulación",
		"Solo puedes cursar una carrera a la vez.", Estilos_UI.ROJO_BIT))
	gv.add_child(_Crear_Paso_Guia("book-open", "Estudia y prepárate",
		"La actividad Estudiar sube el progreso del curso.", Estilos_UI.AZUL))
	gv.add_child(_Crear_Paso_Guia("briefcase-business", "Aprueba y desbloquea empleos",
		"Cada título abre un trabajo cualificado.", Estilos_UI.EXITO))

	# --- Consejo de estudio (con carrera) ---
	_carrera_consejo_card = PanelContainer.new()
	_carrera_consejo_card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fbf7ee"), 16, Color("#eadfcb"), 1, 0))
	vbox.add_child(_carrera_consejo_card)
	var com := MarginContainer.new()
	com.add_theme_constant_override("margin_left", 15)
	com.add_theme_constant_override("margin_right", 15)
	com.add_theme_constant_override("margin_top", 13)
	com.add_theme_constant_override("margin_bottom", 13)
	_carrera_consejo_card.add_child(com)
	var coh := HBoxContainer.new()
	coh.add_theme_constant_override("separation", 11)
	com.add_child(coh)
	var consejo_badge := Estilos_UI.badge_icono("brain", 38, 19,
		Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL, 11)
	coh.add_child(consejo_badge)
	var consejo_txt := VBoxContainer.new()
	consejo_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consejo_txt.add_theme_constant_override("separation", 2)
	coh.add_child(consejo_txt)
	consejo_txt.add_child(Estilos_UI.texto("Consejo de estudio", 13, Estilos_UI.TINTA, 700))
	consejo_txt.add_child(Estilos_UI.parrafo(
		"Estudiar sube el progreso. Dormir bien y cuidar tu salud mental mejora la nota del examen.",
		12, Estilos_UI.TINTA_SUAVE))

	# --- Títulos completados ---
	_carrera_completadas_card = PanelContainer.new()
	_carrera_completadas_card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 18, Estilos_UI.BORDE, 1, 1))
	vbox.add_child(_carrera_completadas_card)

	var ccm := MarginContainer.new()
	ccm.add_theme_constant_override("margin_left", 18)
	ccm.add_theme_constant_override("margin_right", 18)
	ccm.add_theme_constant_override("margin_top", 16)
	ccm.add_theme_constant_override("margin_bottom", 16)
	_carrera_completadas_card.add_child(ccm)

	_carrera_completadas_box = VBoxContainer.new()
	_carrera_completadas_box.add_theme_constant_override("separation", 10)
	ccm.add_child(_carrera_completadas_box)

	vbox.add_child(Estilos_UI.separador(24))
	add_child(_pantalla_carrera)


func _Crear_Paso_Guia(icono: String, titulo: String, descripcion: String, color: Color) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 11)
	var badge := Estilos_UI.badge_icono(icono, 36, 18,
		Color(color, 0.12), color.darkened(0.15), 10)
	fila.add_child(badge)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 1)
	fila.add_child(textos)
	textos.add_child(Estilos_UI.texto(titulo, 13, Estilos_UI.TINTA, 700))
	var p := Estilos_UI.parrafo(descripcion, 11, Estilos_UI.TINTA_SUAVE)
	textos.add_child(p)
	return fila


func _Actualizar_Icono_Carrera(icono: String, accent: Color) -> void:
	if _carrera_icono_badge == null or _carrera_icono_tex == null:
		return
	_carrera_icono_tex.texture = Estilos_UI.icono(icono)
	_carrera_icono_tex.self_modulate = accent.darkened(0.16)
	_carrera_icono_badge.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(accent, 0.14), 18, Color(accent, 0.20), 1, 0))


func _Actualizar_Timeline_Carrera(carrera: Carrera, accent: Color) -> void:
	if _carrera_timeline == null:
		return
	for hijo in _carrera_timeline.get_children():
		_carrera_timeline.remove_child(hijo)
		hijo.queue_free()
	if carrera == null:
		_carrera_timeline.visible = false
		return
	_carrera_timeline.visible = true
	for año in range(1, carrera.años_totales + 1):
		var columna := VBoxContainer.new()
		columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columna.add_theme_constant_override("separation", 4)
		_carrera_timeline.add_child(columna)
		var hecho: bool = carrera.completada or año < carrera.año_actual
		var actual: bool = año == carrera.año_actual and not carrera.completada
		var color_barra := accent if hecho else Color(accent, 0.32) if actual else Color("#e1e6ee")
		var barra := PanelContainer.new()
		barra.custom_minimum_size = Vector2(0, 8)
		barra.add_theme_stylebox_override("panel",
			Estilos_UI.caja(color_barra, 999, Color(0, 0, 0, 0), 0, 0))
		columna.add_child(barra)
		var lbl := Estilos_UI.texto(str(año), 10,
			accent.darkened(0.12) if actual else Estilos_UI.TINTA_FANTASMA,
			700 if actual else 500)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		columna.add_child(lbl)


func _Actualizar_Tarjetas_Completadas() -> void:
	if _carrera_completadas_card == null or _carrera_completadas_box == null:
		return
	for hijo in _carrera_completadas_box.get_children():
		_carrera_completadas_box.remove_child(hijo)
		hijo.queue_free()
	if Variables_Dinamicas.Carreras_Completadas.is_empty():
		_carrera_completadas_card.visible = false
		return
	_carrera_completadas_card.visible = true

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 8)
	_carrera_completadas_box.add_child(cabecera)
	cabecera.add_child(Estilos_UI.icono_rect("trophy", 18, Estilos_UI.ORO))
	var titulo := Estilos_UI.texto("Títulos obtenidos", 15, Estilos_UI.TINTA, 700)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(titulo)
	cabecera.add_child(Estilos_UI.pill_estado(str(Variables_Dinamicas.Carreras_Completadas.size()),
		Estilos_UI.ORO_SUAVE, Estilos_UI.ORO))

	for c in Variables_Dinamicas.Carreras_Completadas:
		var accent := _UI_CARRERAS.color_carrera(c.nombre)
		var fila_panel := PanelContainer.new()
		fila_panel.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))
		_carrera_completadas_box.add_child(fila_panel)
		var fm := MarginContainer.new()
		fm.add_theme_constant_override("margin_left", 10)
		fm.add_theme_constant_override("margin_right", 10)
		fm.add_theme_constant_override("margin_top", 8)
		fm.add_theme_constant_override("margin_bottom", 8)
		fila_panel.add_child(fm)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		fm.add_child(fila)
		fila.add_child(Estilos_UI.badge_icono(_UI_CARRERAS.icono_carrera(c.nombre), 34, 17,
			Color(accent, 0.13), accent.darkened(0.16), 10))
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.add_theme_constant_override("separation", 1)
		fila.add_child(textos)
		textos.add_child(Estilos_UI.texto(_UI_CARRERAS.nombre_carrera(c.nombre), 13,
			Estilos_UI.TINTA, 600))
		var suma := 0.0
		var cuenta := 0
		for entrada in c.historial_notas:
			if entrada.get("aprobado", false):
				suma += float(entrada.get("nota_final", 0.0))
				cuenta += 1
		var sub := "Nota media %.1f · %d cursos" % [
			suma / cuenta if cuenta > 0 else 0.0, c.años_totales]
		textos.add_child(Estilos_UI.texto(sub, 10, Estilos_UI.TINTA_FANTASMA, 500))
		fila.add_child(Estilos_UI.pill_estado("Graduado", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO))



func _on_carrera_tab_pressed():
	if _pantalla_carrera == null or not is_instance_valid(_pantalla_carrera):
		_Crear_Pantalla_Carrera()
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Gestionar_Visibilidad.Recursivo_Visibilizar(_pantalla_carrera)
	Estilos_UI.animar_entrada(_pantalla_carrera)
	_Actualizar_Pantalla_Carrera()
	_Actualizar_Nav_Activa()


func _Actualizar_Badge_Pill(pill: PanelContainer, texto_p: String, fondo: Color, texto_col: Color) -> void:
	if pill == null:
		return
	var st := Estilos_UI.caja(fondo, 999, Color(texto_col, 0.18), 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", st)
	if pill.get_child_count() > 0 and pill.get_child(0) is Label:
		var l := pill.get_child(0) as Label
		l.text = texto_p
		l.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		l.add_theme_color_override("font_color", texto_col)


func _Actualizar_Pantalla_Carrera():
	if _carrera_action_btn == null:
		return
	var carrera = Variables_Dinamicas.Carrera_Actual
	_Actualizar_Tarjetas_Completadas()

	if carrera == null:
		var accent_vacio := Estilos_UI.ROJO_BIT
		_carrera_eyebrow.text = "VIDA UNIVERSITARIA"
		_carrera_eyebrow.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
		_carrera_nombre_label.text = "Da el salto a la universidad"
		_Actualizar_Icono_Carrera("graduation-cap", accent_vacio)
		_Actualizar_Badge_Pill(_carrera_badge, "Disponible", Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL)
		_carrera_status_label.text = "Elige una titulación, estudia cada semana y aprueba los exámenes para desbloquear empleos cualificados."
		_carrera_progreso_header.visible = false
		_carrera_progreso_row.visible = false
		_carrera_timeline.visible = false
		_carrera_action_btn.text = "Elegir mi carrera"
		_carrera_action_btn.disabled = false
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "exito", Estilos_UI.EXITO, "graduation-cap")
		_carrera_libros_btn.visible = not Variables_Dinamicas.Carreras_Completadas.is_empty()
		_carrera_apuntes_titulo.text = "Apuntes de tus carreras"
		_carrera_apuntes_sub.text = "Consulta el temario de tus titulaciones"
		_carrera_guia_card.visible = true
		_carrera_consejo_card.visible = false
		return

	var accent := _UI_CARRERAS.color_carrera(carrera.nombre)
	var accent_oscuro := accent.darkened(0.18)
	_Actualizar_Icono_Carrera(_UI_CARRERAS.icono_carrera(carrera.nombre), accent)
	_carrera_eyebrow.text = "CARRERA UNIVERSITARIA"
	_carrera_eyebrow.add_theme_color_override("font_color", accent_oscuro)
	_carrera_nombre_label.text = _UI_CARRERAS.nombre_carrera(carrera.nombre)
	_carrera_guia_card.visible = false
	_carrera_consejo_card.visible = true
	_carrera_progreso_header.visible = true
	_carrera_progreso_row.visible = true
	_carrera_timeline.visible = true
	_carrera_progreso_titulo.text = "Progreso de Año %d" % min(carrera.año_actual, carrera.años_totales)
	_carrera_progreso_bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(accent))
	Estilos_UI.animar_barra(_carrera_progreso_bar, carrera.progreso_actual, accent)
	_carrera_progreso_pct.text = "%d%%" % int(carrera.progreso_actual)
	_carrera_progreso_pct.add_theme_color_override("font_color", accent_oscuro)
	_Actualizar_Timeline_Carrera(carrera, accent)

	var anios_temario: int = carrera.libros_desbloqueados.size()
	_carrera_apuntes_titulo.text = "Apuntes del curso"
	_carrera_apuntes_sub.text = "%d años desbloqueados · repasa antes del examen" % anios_temario if anios_temario > 0 else "Aún no hay apuntes desbloqueados"
	_carrera_libros_btn.visible = (
		anios_temario > 0 or
		Variables_Dinamicas.Carreras_Completadas.size() > 0
	)

	if carrera.completada and not carrera.fin_de_semana_procesado:
		_Actualizar_Badge_Pill(_carrera_badge, "Completada", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
		_carrera_status_label.text = "Has superado todos los cursos de esta titulación. ¡Enhorabuena!"
		_carrera_progreso_header.visible = false
		_carrera_progreso_row.visible = false
		_carrera_action_btn.text = "Carrera completada"
		_carrera_action_btn.disabled = true
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "exito", Estilos_UI.EXITO, "graduation-cap")
		return

	if carrera.fin_de_semana_procesado:
		var estado = "Aprobado" if carrera.ultimo_resultado_aprobado else "Suspendido"
		_Actualizar_Badge_Pill(_carrera_badge, "Resultado listo", Estilos_UI.ORO_SUAVE, Estilos_UI.ORO)
		_carrera_status_label.text = "Ya está publicada la nota de tu último examen. Revísala para continuar."
		_carrera_progreso_header.visible = false
		_carrera_progreso_row.visible = false
		_carrera_action_btn.text = "Ver resultado: %s (%.0f/100)" % [estado, carrera.ultima_nota_final]
		_carrera_action_btn.disabled = false
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "primario", Estilos_UI.PRIMARIO, "badge-check")
		return

	if carrera.matriculado and _En_Ventana_Examen(carrera):
		if carrera.examen_realizado_esta_semana:
			_Actualizar_Badge_Pill(_carrera_badge, "Entregado", Estilos_UI.PRIMARIO_SUAVE, Estilos_UI.PRIMARIO)
			_carrera_status_label.text = "Examen enviado. El resultado llegará al terminar la hora."
			_carrera_action_btn.text = "Examen entregado"
			_carrera_action_btn.disabled = true
			Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "secundario", Estilos_UI.TINTA, "check")
		else:
			_Actualizar_Badge_Pill(_carrera_badge, "Examen abierto", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
			_carrera_status_label.text = "Estás dentro de la hora de examen. Haz el test para sumar hasta 10 puntos a tu nota."
			_carrera_action_btn.text = "Hacer examen ahora"
			_carrera_action_btn.disabled = false
			Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "exito", Estilos_UI.EXITO, "notebook-pen")
		return

	var costo_mat := int(Variables_Estaticas.Obtener_Costo_Matricula(carrera))
	var nombre_dia_ex := ""
	if carrera.hora_examen_dia >= 0:
		if Variables_Estaticas.Modo_Rapido:
			if carrera.hora_examen_dia == Variables_Dinamicas.Minute_Day:
				nombre_dia_ex = "Hoy"
			elif carrera.hora_examen_dia == Variables_Dinamicas.Minute_Day + 1:
				nombre_dia_ex = "Mañana"
			else:
				nombre_dia_ex = _DIAS_NOMBRES[carrera.hora_examen_dia % 7]
		else:
			nombre_dia_ex = _DIAS_NOMBRES[carrera.hora_examen_dia % 7]

	if carrera.matriculado:
		var hora = carrera.hora_examen_inicio / 60
		_Actualizar_Badge_Pill(_carrera_badge, "Año %d/%d" % [carrera.año_actual, carrera.años_totales],
			Color(accent, 0.13), accent_oscuro)
		_carrera_status_label.text = "Examen programado: %s a las %02d:00. Usa la actividad Estudiar para subir tu progreso." % [
			nombre_dia_ex, hora
		]
		_carrera_action_btn.text = "Esperando al examen (%s %02d:00)" % [nombre_dia_ex, hora]
		_carrera_action_btn.disabled = true
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "secundario", Estilos_UI.TINTA, "calendar-days")
		return

	if carrera.prematriculado:
		var hora = carrera.hora_examen_inicio / 60
		_Actualizar_Badge_Pill(_carrera_badge, "Prematrícula", Estilos_UI.ORO_SUAVE, Estilos_UI.ORO)
		var cuando_cobra := "mañana a las 00:00" if Variables_Estaticas.Modo_Rapido else "el lunes"
		_carrera_status_label.text = "Año %d de %d · Examen elegido: %s %02d:00. Se formalizará %s (%d €)." % [
			carrera.año_actual, carrera.años_totales, nombre_dia_ex, hora, cuando_cobra, costo_mat
		]
		_carrera_action_btn.text = "Cambiar horario de examen"
		_carrera_action_btn.disabled = false
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "primario", accent, "calendar-days")
		return

	if Variables_Estaticas.Modo_Rapido:
		_Actualizar_Badge_Pill(_carrera_badge, "Matrícula abierta", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
		_carrera_status_label.text = "Año %d de %d · Programa tu examen para hoy o mañana (%d €)." % [
			carrera.año_actual, carrera.años_totales, costo_mat]
		_carrera_action_btn.text = "Matricularse (%d €)" % costo_mat
		_carrera_action_btn.disabled = Variables_Dinamicas.Dinero < costo_mat
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "exito", Estilos_UI.EXITO, "graduation-cap")
		return

	var dia_semana = Variables_Dinamicas.Minute_Day % 7
	if dia_semana <= 1:
		_Actualizar_Badge_Pill(_carrera_badge, "Matrícula abierta", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
		_carrera_status_label.text = "Año %d de %d · Matrícula directa disponible lunes y martes (%d €)." % [
			carrera.año_actual, carrera.años_totales, costo_mat]
		_carrera_action_btn.text = "Matricularse (%d €)" % costo_mat
		_carrera_action_btn.disabled = Variables_Dinamicas.Dinero < costo_mat
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "exito", Estilos_UI.EXITO, "graduation-cap")
	else:
		_Actualizar_Badge_Pill(_carrera_badge, "Prematrícula", Color(accent, 0.13), accent_oscuro)
		_carrera_status_label.text = "Año %d de %d · Puedes reservar horario gratis; la matrícula se cobra el lunes (%d €)." % [
			carrera.año_actual, carrera.años_totales, costo_mat]
		_carrera_action_btn.text = "Prematricularse gratis"
		_carrera_action_btn.disabled = false
		Estilos_UI.aplicar_estilo_boton(_carrera_action_btn, "exito", Estilos_UI.EXITO, "calendar-days")


func _Actualizar_Pantalla_Carrera_Si_Visible():
	if _pantalla_carrera != null and _pantalla_carrera.is_visible_in_tree():
		_Actualizar_Pantalla_Carrera()

# ================================================================
# Pantalla Economía (tab)
# ================================================================

var _pantalla_economia: Control = null
var _economia_alquiler_titulo: Label = null
var _economia_alquiler_desc: Label = null
var _economia_alquiler_pill: PanelContainer = null
var _economia_alquiler_btn: Button = null
var _economia_bolsa_titulo: Label = null
var _economia_bolsa_desc: Label = null
var _economia_bolsa_pill: PanelContainer = null
var _economia_bolsa_btn: Button = null
var _economia_resumen_efectivo: Label = null
var _economia_resumen_bolsa: Label = null
var _economia_resumen_alquiler: Label = null
var _dialog_volver_a_casa: ConfirmationDialog = null
var _dialog_alquiler_info: AcceptDialog = null


func _Crear_Pantalla_Economia():
	if _pantalla_economia != null and is_instance_valid(_pantalla_economia):
		return
	_pantalla_economia = ColorRect.new()
	_pantalla_economia.name = "Pantalla_Economia"
	_pantalla_economia.color = Estilos_UI.FONDO
	_pantalla_economia.position = Vector2.ZERO
	_pantalla_economia.size = Vector2(720, _Alto_Pantalla())
	_pantalla_economia.z_index = 5
	_pantalla_economia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantalla_economia.visible = false

	Estilos_UI.Crear_Label_Titulo_Panel("Economía", _pantalla_economia, Estilos_UI.TINTA)
	Estilos_UI.Crear_Boton_Volver_Panel(_pantalla_economia, Callable(self, "Quitar_Todo"))

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll_Economia"
	scroll.position = Vector2(20, 186)
	scroll.size = Vector2(680, _Alto_Pantalla() - 304.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pantalla_economia.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox_Economia"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	# Banda resumen financiero estilo BitLife (Efectivo · En bolsa · Alquiler)
	var resumen_row := HBoxContainer.new()
	resumen_row.add_theme_constant_override("separation", 10)
	vbox.add_child(resumen_row)
	var tiles_eco := [
		["EFECTIVO", "banknote", Estilos_UI.EXITO, Estilos_UI.EXITO_SUAVE],
		["EN BOLSA", "trending-up", Estilos_UI.AZUL, Estilos_UI.AZUL_SUAVE],
		["ALQUILER", "house", Estilos_UI.ORO, Estilos_UI.ORO_SUAVE],
	]
	var refs_eco: Array[Label] = []
	for t_info in tiles_eco:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st_t := Estilos_UI.caja(t_info[3], 14, Color(t_info[2], 0.24), 1, 1)
		st_t.border_width_bottom = 2
		tile.add_theme_stylebox_override("panel", st_t)
		var tm := MarginContainer.new()
		tm.add_theme_constant_override("margin_left", 12)
		tm.add_theme_constant_override("margin_right", 12)
		tm.add_theme_constant_override("margin_top", 10)
		tm.add_theme_constant_override("margin_bottom", 10)
		tile.add_child(tm)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 4)
		tm.add_child(tv)
		var th := HBoxContainer.new()
		th.add_theme_constant_override("separation", 6)
		th.add_child(Estilos_UI.badge_icono(t_info[1], 22, 12, t_info[2], Color.WHITE, 6))
		th.add_child(Estilos_UI.texto(t_info[0], 10, t_info[2], 700))
		tv.add_child(th)
		var val_l := Estilos_UI.titulo("0 €", 18, Estilos_UI.TINTA)
		tv.add_child(val_l)
		refs_eco.append(val_l)
		resumen_row.add_child(tile)
	_economia_resumen_efectivo = refs_eco[0]
	_economia_resumen_bolsa = refs_eco[1]
	_economia_resumen_alquiler = refs_eco[2]

	# Tarjeta Alquiler / Vivienda
	var card_alq := _Crear_Card_Economia(vbox, "house", "Vivienda y alquiler", Estilos_UI.EXITO)
	_economia_alquiler_titulo = card_alq["titulo"]
	_economia_alquiler_desc = card_alq["desc"]
	_economia_alquiler_pill = card_alq["pill"]
	_economia_alquiler_btn = card_alq["btn"]
	_economia_alquiler_btn.pressed.connect(_on_economia_alquiler_pressed)

	# Tarjeta Bolsa
	var card_bolsa := _Crear_Card_Economia(vbox, "trending-up", "Bolsa e inversiones", Estilos_UI.AZUL)
	_economia_bolsa_titulo = card_bolsa["titulo"]
	_economia_bolsa_desc = card_bolsa["desc"]
	_economia_bolsa_pill = card_bolsa["pill"]
	_economia_bolsa_btn = card_bolsa["btn"]
	_economia_bolsa_btn.pressed.connect(_on_economia_bolsa_pressed)

	add_child(_pantalla_economia)
	_Actualizar_Pantalla_Economia()


func _Crear_Card_Economia(parent: VBoxContainer, icono_n: String, titulo_t: String, color_ic: Color) -> Dictionary:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	parent.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)

	top.add_child(Estilos_UI.badge_icono(icono_n, 40, 20, color_ic, Color.WHITE, 11))

	var lbl_t := Estilos_UI.titulo(titulo_t, 17, Estilos_UI.TINTA)
	lbl_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl_t)

	var pill := Estilos_UI.pill_estado("", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE)
	top.add_child(pill)

	var desc := Estilos_UI.parrafo("", 13, Estilos_UI.TINTA_SUAVE)
	v.add_child(desc)

	var btn := Estilos_UI.boton("Gestionar", "secundario", "", Estilos_UI.PRIMARIO, 46)
	v.add_child(btn)

	return {"titulo": lbl_t, "desc": desc, "pill": pill, "btn": btn}


func _on_economia_button_pressed():
	if _pantalla_economia == null or not is_instance_valid(_pantalla_economia):
		_Crear_Pantalla_Economia()
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Gestionar_Visibilidad.Recursivo_Visibilizar(_pantalla_economia)
	Estilos_UI.animar_entrada(_pantalla_economia)
	_Actualizar_Pantalla_Economia()
	_Actualizar_Nav_Activa()

func _on_economia_alquiler_pressed():
	var dinero   = Variables_Dinamicas.Dinero
	var alquiler = Variables_Estaticas.Obtener_Alquiler()

	# En la calle + tiene dinero → ofrecer volver a casa
	if Variables_Dinamicas.En_La_Calle and dinero >= alquiler:
		if _dialog_volver_a_casa == null:
			_dialog_volver_a_casa = ConfirmationDialog.new()
			_dialog_volver_a_casa.title = "Volver a casa"
			_dialog_volver_a_casa.ok_button_text = "Volver (%d€)" % alquiler
			_dialog_volver_a_casa.get_cancel_button().text = "Cancelar"
			_dialog_volver_a_casa.confirmed.connect(_Confirmar_Volver_A_Casa)
			add_child(_dialog_volver_a_casa)
		_dialog_volver_a_casa.dialog_text = (
			"Tienes %.0f€. Paga %d€ de alquiler y vuelve a casa.\nTus necesidades básicas dejarán de estar limitadas." % [dinero, alquiler]
		)
		_dialog_volver_a_casa.popup_centered(Vector2i(500, 220))
		return

	# En la calle sin dinero → solo informar
	if Variables_Dinamicas.En_La_Calle:
		if _dialog_alquiler_info == null:
			_dialog_alquiler_info = AcceptDialog.new()
			_dialog_alquiler_info.title = "Alquiler"
			add_child(_dialog_alquiler_info)
		_dialog_alquiler_info.ok_button_text = "Entendido"
		_dialog_alquiler_info.dialog_text = (
			"Estás en la calle. Necesitas %d€ para volver a casa.\nTienes %.0f€." % [alquiler, dinero]
		)
		_dialog_alquiler_info.popup_centered(Vector2i(500, 200))
		return

	# No en la calle, no llega al alquiler → ofrecer ir voluntariamente
	if dinero < alquiler:
		if _dialog_ir_a_la_calle == null:
			_dialog_ir_a_la_calle = ConfirmationDialog.new()
			_dialog_ir_a_la_calle.title = "Alquiler"
			_dialog_ir_a_la_calle.get_cancel_button().text = "Cancelar"
			_dialog_ir_a_la_calle.confirmed.connect(_Confirmar_Ir_A_La_Calle)
			add_child(_dialog_ir_a_la_calle)
		_dialog_ir_a_la_calle.ok_button_text = "Ir a la calle"
		_dialog_ir_a_la_calle.dialog_text = (
			"No tienes suficiente para el alquiler (%d€).\nTienes %.0f€.\n¿Ir a la calle voluntariamente?" % [alquiler, dinero]
		)
		_dialog_ir_a_la_calle.popup_centered(Vector2i(500, 220))
		return

	# Situación normal → info
	if _dialog_alquiler_info == null:
		_dialog_alquiler_info = AcceptDialog.new()
		_dialog_alquiler_info.title = "Alquiler"
		add_child(_dialog_alquiler_info)
	_dialog_alquiler_info.ok_button_text = "Cerrar"
	var unidad_alq := "día" if Variables_Estaticas.Modo_Rapido else "semana"
	_dialog_alquiler_info.dialog_text = (
		"Alquiler: %d€/%s\nDinero actual: %.0f€" % [alquiler, unidad_alq, dinero]
	)
	_dialog_alquiler_info.popup_centered(Vector2i(500, 180))

func _Confirmar_Volver_A_Casa():
	Actividades.Volver_A_Alquiler()
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Economia()
	Actualizar_Dinero()

func _Actualizar_Pantalla_Economia():
	if _economia_alquiler_btn == null:
		return
	var dinero: float = Variables_Dinamicas.Dinero
	var alquiler: int = Variables_Estaticas.Obtener_Alquiler()
	var unidad_alq_corta := "día" if Variables_Estaticas.Modo_Rapido else "sem"

	if _economia_resumen_efectivo != null:
		_economia_resumen_efectivo.text = "%d €" % int(dinero)
		_economia_resumen_efectivo.add_theme_color_override("font_color",
			Estilos_UI.EXITO if dinero >= 0 else Estilos_UI.PELIGRO)
	if _economia_resumen_bolsa != null:
		_economia_resumen_bolsa.text = "%d €" % int(Variables_Dinamicas.Valor_Inversion) if Variables_Dinamicas.Esta_Invirtiendo else "0 €"
	if _economia_resumen_alquiler != null:
		_economia_resumen_alquiler.text = "En calle" if Variables_Dinamicas.En_La_Calle else "%d €/%s" % [alquiler, unidad_alq_corta]
		_economia_resumen_alquiler.add_theme_color_override("font_color",
			Estilos_UI.PELIGRO if Variables_Dinamicas.En_La_Calle else Estilos_UI.TINTA)

	if Variables_Dinamicas.En_La_Calle:
		_Actualizar_Badge_Pill(_economia_alquiler_pill, "En la calle", Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO)
		if dinero >= alquiler:
			_economia_alquiler_desc.text = "Vives en la calle (necesidades limitadas al 20%%). Puedes pagar %d € para volver a casa." % alquiler
			_economia_alquiler_btn.text = "Volver a casa (%d €)" % alquiler
			Estilos_UI.aplicar_estilo_boton(_economia_alquiler_btn, "primario", Estilos_UI.PRIMARIO, "house")
		else:
			_economia_alquiler_desc.text = "Vives en la calle (necesidades limitadas al 20%%). Necesitas %d € para alquilar." % alquiler
			_economia_alquiler_btn.text = "Ver requisitos (%d €)" % alquiler
			Estilos_UI.aplicar_estilo_boton(_economia_alquiler_btn, "suave", Estilos_UI.PELIGRO, "house")
	else:
		_Actualizar_Badge_Pill(_economia_alquiler_pill, "Al día", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
		var dias_ciclo := Variables_Estaticas.Dias_Por_Anio()
		var dias_rest := dias_ciclo
		if Variables_Dinamicas.Ultima_Fecha_Alquiler >= 0:
			var trans: int = int(Variables_Dinamicas.Minute) - int(Variables_Dinamicas.Ultima_Fecha_Alquiler)
			dias_rest = maxi(0, ceili(float(dias_ciclo * 1440 - trans) / 1440.0))
		if Variables_Estaticas.Modo_Rapido:
			_economia_alquiler_desc.text = "Cuota diaria: %d € · Próximo cobro en ~%d día." % [alquiler, maxi(1, dias_rest)]
		else:
			_economia_alquiler_desc.text = "Cuota semanal: %d € · Próximo cobro en ~%d días." % [alquiler, dias_rest]
		_economia_alquiler_btn.text = "Gestionar alquiler"
		Estilos_UI.aplicar_estilo_boton(_economia_alquiler_btn, "secundario", Estilos_UI.PRIMARIO, "house")

	if Variables_Dinamicas.Esta_Invirtiendo:
		var valor: float = Variables_Dinamicas.Valor_Inversion
		var invertido: float = Variables_Dinamicas.Dinero_Invertido
		var pct: float = (valor - invertido) / invertido * 100.0 if invertido > 0 else 0.0
		var signo: String = "+" if pct >= 0 else ""
		var positivo := pct >= 0
		_Actualizar_Badge_Pill(_economia_bolsa_pill, "%s%.1f%%" % [signo, pct],
			Estilos_UI.EXITO_SUAVE if positivo else Estilos_UI.PELIGRO_SUAVE,
			Estilos_UI.EXITO if positivo else Estilos_UI.PELIGRO)
		_economia_bolsa_desc.text = "Cartera: %.0f € (invertido: %.0f €) · Beneficio total: %s%.0f € · Nivel %d/100" % [
			valor, invertido, "+" if Sistema_Bolsa.Beneficio_Acumulado() >= 0 else "-",
			absf(Sistema_Bolsa.Beneficio_Acumulado()), Variables_Dinamicas.Progreso_Inversion]
		_economia_bolsa_btn.text = "Gestionar inversión (%.0f €)" % valor
		Estilos_UI.aplicar_estilo_boton(_economia_bolsa_btn, "primario", Estilos_UI.AZUL, "chart-line")
	else:
		_Actualizar_Badge_Pill(_economia_bolsa_pill, "Sin inversión", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE)
		_economia_bolsa_desc.text = "Abre la bolsa para invertir, seguir la evolución de tu beneficio y consultar tus estadísticas. Nivel inversor: %d/100." % Variables_Dinamicas.Progreso_Inversion
		_economia_bolsa_btn.text = "Abrir bolsa"
		Estilos_UI.aplicar_estilo_boton(_economia_bolsa_btn, "primario", Estilos_UI.AZUL, "chart-line")

func _Actualizar_Pantalla_Economia_Si_Visible():
	if _pantalla_economia != null and _pantalla_economia.is_visible_in_tree():
		_Actualizar_Pantalla_Economia()


# ============================================================
# Apartado de Minijuegos + Minijuego de Cocina + Notificación Toast
# ============================================================

func _Crear_Pantalla_Minijuegos() -> void:
	if _pantalla_minijuegos != null and is_instance_valid(_pantalla_minijuegos):
		return
	_pantalla_minijuegos = ColorRect.new()
	_pantalla_minijuegos.name = "Pantalla_Minijuegos"
	_pantalla_minijuegos.color = Estilos_UI.FONDO
	_pantalla_minijuegos.position = Vector2.ZERO
	_pantalla_minijuegos.size = Vector2(720, _Alto_Pantalla())
	_pantalla_minijuegos.z_index = 5
	_pantalla_minijuegos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantalla_minijuegos.visible = false

	Estilos_UI.Crear_Label_Titulo_Panel("Minijuegos", _pantalla_minijuegos, Estilos_UI.TINTA)
	Estilos_UI.Crear_Boton_Volver_Panel(_pantalla_minijuegos, Callable(self, "Quitar_Todo"))

	_minijuegos_scroll = ScrollContainer.new()
	_minijuegos_scroll.name = "Scroll_Minijuegos"
	_minijuegos_scroll.position = Vector2(20, 186)
	_minijuegos_scroll.size = Vector2(680, _Alto_Pantalla() - 304.0)
	_minijuegos_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pantalla_minijuegos.add_child(_minijuegos_scroll)

	_minijuegos_vbox = VBoxContainer.new()
	_minijuegos_vbox.name = "VBox_Minijuegos"
	_minijuegos_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_minijuegos_vbox.add_theme_constant_override("separation", 14)
	_minijuegos_scroll.add_child(_minijuegos_vbox)

	add_child(_pantalla_minijuegos)
	_Actualizar_Pantalla_Minijuegos()


func _Crear_Pantalla_Vestuario() -> void:
	if _pantalla_vestuario != null and is_instance_valid(_pantalla_vestuario):
		return
	_pantalla_vestuario = Pantalla_Vestuario.new()
	_pantalla_vestuario.name = "Pantalla_Vestuario"
	_pantalla_vestuario.visible = false
	_pantalla_vestuario.z_index = 5
	_pantalla_vestuario.cerrado.connect(_on_vestuario_cerrado)
	_pantalla_vestuario.atuendo_equipado.connect(_on_atuendo_equipado)
	_pantalla_vestuario.atuendo_comprado.connect(_on_atuendo_comprado)
	add_child(_pantalla_vestuario)


func _on_vestuario_button_pressed() -> void:
	Detener_Blink()
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	if _pantalla_vestuario == null or not is_instance_valid(_pantalla_vestuario):
		_Crear_Pantalla_Vestuario()
	Gestionar_Visibilidad.Recursivo_Visibilizar(_pantalla_vestuario)
	_pantalla_vestuario.abrir()
	Estilos_UI.animar_entrada(_pantalla_vestuario)
	_Actualizar_Nav_Activa()


func _on_vestuario_cerrado() -> void:
	Quitar_Todo()


func _on_atuendo_equipado(_clave: String) -> void:
	_Actualizar_Apariencia_Vestuario()
	_Actualizar_Home()
	if has_node("Pantalla_Mensajes") and $Pantalla_Mensajes.visible \
			and $Pantalla_Mensajes/Panel_Info.visible:
		_Renderizar_Info()


func _on_atuendo_comprado(_clave: String) -> void:
	# La compra se paga desde el Vestuario; refresca el saldo de la cabecera.
	Actualizar_Dinero()


## Refresca los avatares y retratos que muestran al personaje con la ropa puesta.
func _Actualizar_Apariencia_Vestuario() -> void:
	var avatar_btn := get_node_or_null("Avatar_Header_Btn") as Button
	if avatar_btn != null:
		var retrato := avatar_btn.find_child("Retrato", true, false)
		if retrato is Personaje_Visual:
			retrato.apariencia = Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(
				Variables_Estaticas.Apariencia)
	if _home_escenario != null and is_instance_valid(_home_escenario):
		_home_escenario.actualizar_estado(
			_Obtener_Nombre_Actividad_Actual(),
			Variables_Dinamicas.En_La_Calle,
			Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(Variables_Estaticas.Apariencia),
			int(Variables_Dinamicas.Minute_Minute),
			str(Variables_Dinamicas.Objeto_Seleccionado.get("Comer", "Mesa_Basica")),
			str(Variables_Estaticas.Personalidad)
		)


func _on_minijuegos_button_pressed() -> void:
	if _pantalla_minijuegos == null or not is_instance_valid(_pantalla_minijuegos):
		_Crear_Pantalla_Minijuegos()
	Detener_Blink()
	_minijuegos_novedad_pendiente = false
	Gestionar_Visibilidad.Quitar_Todo(self)
	_Ocultar_Home()
	Gestionar_Visibilidad.Recursivo_Visibilizar(_pantalla_minijuegos)
	Estilos_UI.animar_entrada(_pantalla_minijuegos)
	_Actualizar_Pantalla_Minijuegos()
	_Actualizar_Badges()
	_Actualizar_Nav_Activa()


func _Actualizar_Pantalla_Minijuegos() -> void:
	if _minijuegos_vbox == null or not is_instance_valid(_minijuegos_vbox):
		return
	for hijo in _minijuegos_vbox.get_children():
		hijo.queue_free()

	# Tarjeta 1: Cocina
	var desbloqueado: bool = Sistema_Cocina.Esta_Desbloqueado_Minijuego()
	var en_turno: bool = Sistema_Cocina.Esta_En_Turno_Activo("")
	var rango: int = Sistema_Cocina.Obtener_Rango_Logro()
	var info_rango: Dictionary = Sistema_Cocina.Obtener_Info_Rango(rango)
	var estrellas_total: int = Sistema_Cocina.Contar_Estrellas_Totales()
	var fondos: int = Sistema_Cocina.Obtener_Caja_Restaurante()

	var card := PanelContainer.new()
	card.name = "Card_Minijuego_Cocina"
	var borde_c: Color = Estilos_UI.EXITO if (desbloqueado and en_turno) else (Color("#ea580c") if desbloqueado else Estilos_UI.BORDE)
	var st_c := Estilos_UI.caja_tarjeta(16, 3)
	st_c.border_color = borde_c
	card.add_theme_stylebox_override("panel", st_c)
	_minijuegos_vbox.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	# Banner visual con el arte del minijuego: fondo propio de mostrador (damero
	# poco contrastado + comedor desenfocado) y composición 3/4 con sombras de
	# contacto. El plato se usa en perspectiva para que no parezca un círculo.
	var banner := Control.new()
	banner.name = "Banner_Cocina"
	banner.custom_minimum_size = Vector2(0.0, 142.0)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.clip_contents = true
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(banner)

	var bg_banner := TextureRect.new()
	bg_banner.name = "Fondo_Banner"
	bg_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_banner.texture = Arte_Cocina.TEX_BANNER
	bg_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(bg_banner)

	# Sombras primero (de atrás a delante) y después los sprites.
	_Anadir_Sombra_Banner(banner, Vector2(158.0, 116.0), Vector2(118.0, 18.0))
	_Anadir_Sombra_Banner(banner, Vector2(274.0, 122.0), Vector2(132.0, 14.0))
	_Anadir_Sombra_Banner(banner, Vector2(375.0, 124.0), Vector2(96.0, 14.0))
	_Anadir_Sombra_Banner(banner, Vector2(445.0, 120.0), Vector2(64.0, 12.0))
	_Anadir_Sombra_Banner(banner, Vector2(549.0, 124.0), Vector2(152.0, 16.0))

	_Anadir_Item_Banner(banner, Arte_Cocina.textura_chef("pulgar"), Vector2(0.0, 0.0), Vector2(104.0, 142.0))
	_Anadir_Item_Banner(banner, Arte_Cocina.TEX_HAMBURGUESA, Vector2(106.0, 22.0), Vector2(104.0, 104.0))
	_Anadir_Item_Banner(banner, Arte_Cocina.TEX_PATATAS, Vector2(330.0, 32.0), Vector2(90.0, 96.0))
	_Anadir_Item_Banner(banner, Arte_Cocina.TEX_REFRESCO, Vector2(414.0, 16.0), Vector2(62.0, 112.0))
	_Anadir_Item_Banner(banner, Arte_Cocina.TEX_PLANCHA, Vector2(476.0, 24.0), Vector2(146.0, 100.0))
	# El plato va delante de las patatas: es el objeto más cercano de ese grupo.
	_Anadir_Item_Banner(banner, Arte_Cocina.TEX_PLATO_PERSPECTIVA, Vector2(212.0, 64.0), Vector2(124.0, 58.0))

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)

	cab.add_child(Estilos_UI.badge_icono("utensils" if desbloqueado else "lock", 46, 22,
		Color("#ea580c") if desbloqueado else Estilos_UI.TINTA_FANTASMA, Color.WHITE, 12))

	var tit_col := VBoxContainer.new()
	tit_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_col.add_theme_constant_override("separation", 2)
	cab.add_child(tit_col)
	tit_col.add_child(Estilos_UI.titulo("Cocina", 19, Estilos_UI.TINTA))
	tit_col.add_child(Estilos_UI.texto("Gestión de pedidos en tiempo real · 1280×720 Horizontal", 12, Estilos_UI.TINTA_SUAVE, 500))

	if not desbloqueado:
		cab.add_child(Estilos_UI.pill_estado("Bloqueado", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE))
	elif en_turno:
		cab.add_child(Estilos_UI.pill_estado("En Turno · Propinas x1.5", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
	else:
		cab.add_child(Estilos_UI.pill_estado("Disponible", Estilos_UI.ORO_SUAVE, Estilos_UI.ORO))

	if not desbloqueado:
		var lock_row := HBoxContainer.new()
		lock_row.add_theme_constant_override("separation", 8)
		lock_row.add_child(Estilos_UI.icono_rect("lock", 18, Estilos_UI.TINTA_SUAVE))
		var lbl_lock := Estilos_UI.parrafo(
			"Trabaja al menos 1 minuto en Comida Rápida u hostelería para desbloquearlo.",
			14, Estilos_UI.TINTA_SUAVE)
		lbl_lock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lock_row.add_child(lbl_lock)
		v.add_child(lock_row)

		var btn_bloq := Estilos_UI.boton("Bloqueado", "secundario", "lock", Estilos_UI.TINTA_FANTASMA, 48)
		btn_bloq.disabled = true
		v.add_child(btn_bloq)
	else:
		var chips := HBoxContainer.new()
		chips.add_theme_constant_override("separation", 8)
		chips.add_child(Estilos_UI.pill_estado("Maestría: Rango %d/9" % rango, Estilos_UI.ORO_SUAVE, Estilos_UI.ORO))
		chips.add_child(Estilos_UI.pill_estado("%d / %d ★" % [estrellas_total, Sistema_Cocina.ESTRELLAS_TOTALES_MAX], Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))
		chips.add_child(Estilos_UI.pill_estado("Caja %d €" % fondos, Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA))
		v.add_child(chips)

		var desc_txt: String = "Rango actual: %s. " % str(info_rango.get("nombre", ""))
		if en_turno:
			desc_txt += "Estás en turno activo: propinas ×1.5, paga completa ilimitada, Progreso ×2.0 y +10% extra en tu nómina."
		else:
			desc_txt += "Modo libre: %d/%d servicios con paga completa hoy. Después, modo práctica (25%% para ti; la Caja sigue al 100%%)." % [
				Sistema_Cocina.Obtener_Servicios_Completos_Restantes_Hoy(),
				Sistema_Cocina.LIMITE_SERVICIOS_COMPLETOS_DIA
			]
		v.add_child(Estilos_UI.parrafo(desc_txt, 13, Estilos_UI.TINTA_SUAVE))

		var btn_jugar := Estilos_UI.boton("Jugar", "exito", "play", Estilos_UI.EXITO, 50)
		btn_jugar.name = "Btn_Jugar_Cocina"
		btn_jugar.pressed.connect(_Abrir_Minijuego_Cocina)
		v.add_child(btn_jugar)

	_Anadir_Tarjeta_Correr()
	_Anadir_Tarjeta_Manager()

	# Contenedor modular preparado para añadir futuros minijuegos
	var sep_lbl := Estilos_UI.texto("PRÓXIMOS MINIJUEGOS", 11, Estilos_UI.TINTA_FANTASMA, 700)
	_minijuegos_vbox.add_child(sep_lbl)

	for futuro in [
		["Trading en Directo", "Opera en sesiones rápidas de bolsa con noticias en tiempo real.", "trending-up", Estilos_UI.AZUL]
	]:
		var fcard := PanelContainer.new()
		fcard.add_theme_stylebox_override("panel", Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 14, Estilos_UI.BORDE, 1, 0))
		var fm := MarginContainer.new()
		fm.add_theme_constant_override("margin_left", 16)
		fm.add_theme_constant_override("margin_right", 16)
		fm.add_theme_constant_override("margin_top", 12)
		fm.add_theme_constant_override("margin_bottom", 12)
		fcard.add_child(fm)
		var fh := HBoxContainer.new()
		fh.add_theme_constant_override("separation", 12)
		fm.add_child(fh)
		fh.add_child(Estilos_UI.badge_icono(futuro[2], 38, 18, Color(futuro[3], 0.35), futuro[3], 10))
		var fv := VBoxContainer.new()
		fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fv.add_theme_constant_override("separation", 2)
		fv.add_child(Estilos_UI.titulo(futuro[0], 15, Estilos_UI.TINTA_SUAVE))
		fv.add_child(Estilos_UI.parrafo(futuro[1], 12, Estilos_UI.TINTA_FANTASMA))
		fh.add_child(fv)
		fh.add_child(Estilos_UI.pill_estado("Próximamente", Estilos_UI.SUPERFICIE, Estilos_UI.TINTA_FANTASMA))
		_minijuegos_vbox.add_child(fcard)


# Tarjeta del runner "Salir a correr" dentro del hub de Minijuegos.
func _Anadir_Tarjeta_Correr() -> void:
	var record: int = Sistema_Correr.Obtener_Record_Distancia()
	var carreras: int = Sistema_Correr.Obtener_Carreras()
	var monedas: int = Sistema_Correr.Obtener_Monedas_Totales()

	var card := PanelContainer.new()
	card.name = "Card_Minijuego_Correr"
	var st := Estilos_UI.caja_tarjeta(16, 3)
	st.border_color = Color("#16a34a")
	card.add_theme_stylebox_override("panel", st)
	_minijuegos_vbox.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	var banner: Control = null
	if _script_banner_correr == null:
		_script_banner_correr = load("res://Scripts/GUI/Minijuego_Correr/Banner_Correr.gd") as Script
	if _script_banner_correr != null:
		banner = _script_banner_correr.new() as Control
	if banner != null:
		banner.name = "Banner_Correr"
		banner.custom_minimum_size = Vector2(0.0, 142.0)
		banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banner.clip_contents = true
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(banner)
	else:
		var fallback := ColorRect.new()
		fallback.custom_minimum_size = Vector2(0.0, 142.0)
		fallback.color = Color("#0f172a")
		v.add_child(fallback)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)

	cab.add_child(Estilos_UI.badge_icono("footprints", 46, 24,
		Color("#16a34a"), Color.WHITE, 12))

	var tit_col := VBoxContainer.new()
	tit_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_col.add_theme_constant_override("separation", 2)
	cab.add_child(tit_col)
	tit_col.add_child(Estilos_UI.titulo("Salir a correr", 19, Estilos_UI.TINTA))
	tit_col.add_child(Estilos_UI.texto("PARK RUSH 3D · Runner 3D infinito de 3 carriles · Tu Sim en 3D", 12, Estilos_UI.TINTA_SUAVE, 500))

	cab.add_child(Estilos_UI.pill_estado("Nuevo", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.add_child(Estilos_UI.pill_estado(
		("Récord %s" % Sistema_Correr.Formatear_Distancia(float(record))) if record > 0 else "Sin récord todavía",
		Estilos_UI.ORO_SUAVE, Estilos_UI.ORO))
	chips.add_child(Estilos_UI.pill_estado("%d %s" % [carreras, "carrera" if carreras == 1 else "carreras"],
		Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))
	chips.add_child(Estilos_UI.pill_estado("%d monedas" % monedas,
		Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA))
	v.add_child(chips)

	v.add_child(Estilos_UI.parrafo(
		"Corre en 3D por el parque con tu propio Sim: sube rampas a los techos, salta vallas, rueda bajo arcos y activa tu tabla urbana. " +
		"Recoge monedas, imán, súper zapatillas y x2 para ganar Progreso de Deporte y mejorar tus necesidades.",
		13, Estilos_UI.TINTA_SUAVE))

	var btn_jugar := Estilos_UI.boton("Jugar", "exito", "play", Estilos_UI.EXITO, 50)
	btn_jugar.name = "Btn_Jugar_Correr"
	btn_jugar.pressed.connect(_Abrir_Minijuego_Correr)
	v.add_child(btn_jugar)


# Tarjeta de «El Mánager» dentro del hub de Minijuegos.
func _Anadir_Tarjeta_Manager() -> void:
	var desbloqueado: bool = Sistema_Manager.Desbloqueado()
	var activo: bool = Sistema_Manager.Activo()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var card := PanelContainer.new()
	card.name = "Card_Minijuego_Manager"
	var st := Estilos_UI.caja_tarjeta(16, 3)
	st.border_color = Color("#0f766e") if desbloqueado else Estilos_UI.BORDE
	card.add_theme_stylebox_override("panel", st)
	_minijuegos_vbox.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	# Cabecera ilustrada procedural: estadio + escudo + mánager.
	var banner := Banner_Manager.new()
	banner.name = "Banner_Manager"
	banner.configurar(club)
	v.add_child(banner)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	cab.add_child(Estilos_UI.badge_icono("trophy" if desbloqueado else "lock", 46, 22,
		Color("#0f766e") if desbloqueado else Estilos_UI.TINTA_FANTASMA, Color.WHITE, 12))
	var tit_col := VBoxContainer.new()
	tit_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_col.add_theme_constant_override("separation", 2)
	cab.add_child(tit_col)
	tit_col.add_child(Estilos_UI.titulo("El Mánager", 19, Estilos_UI.TINTA))
	if activo:
		tit_col.add_child(Estilos_UI.texto("%s · %s" % [
			str(club.get("nombre", "")),
			Datos_Manager.Nombre_Division(int(club.get("division", 4)))],
			12, Estilos_UI.TINTA_SUAVE, 600))
	else:
		tit_col.add_child(Estilos_UI.texto("Funda tu club y dirígelo desde la 3ª Regional", 12,
			Estilos_UI.TINTA_SUAVE, 500))
	if activo:
		cab.add_child(Estilos_UI.pill_estado("%dº · Rep. %d" % [
			Sistema_Manager.Obtener_Posicion_Usuario(),
			Sistema_Manager.Obtener_Reputacion()],
			Color("#ccfbf1"), Color("#115e59")))
	elif desbloqueado:
		cab.add_child(Estilos_UI.pill_estado("Listo para fundar",
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
	else:
		cab.add_child(Estilos_UI.pill_estado("Bloqueado",
			Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE))

	if activo:
		var chips := HFlowContainer.new()
		chips.add_theme_constant_override("h_separation", 8)
		chips.add_theme_constant_override("v_separation", 6)
		chips.add_child(Estilos_UI.pill_estado("Caja %s" % _Formatear_Euros_Manager(
			int(club.get("presupuesto", 0))), Color("#ccfbf1"), Color("#115e59")))
		chips.add_child(Estilos_UI.pill_estado("Temporada %d · J%d/4" % [
			Sistema_Manager.Obtener_Temporada(), mini(4, Sistema_Manager.Obtener_Jornada() + 1)],
			Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))
		if Sistema_Manager.Puede_Jugar_Manual():
			chips.add_child(Estilos_UI.pill_estado("¡Partido oficial pendiente!",
				Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
		else:
			chips.add_child(Estilos_UI.pill_estado(Sistema_Manager.Obtener_Proximo_Partido_Texto(),
				Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA))
		v.add_child(chips)
		v.add_child(Estilos_UI.parrafo(
			"Gestiona vestuario, pizarra táctica, instalaciones, cantera y partidos de 90 minutos en directo.",
			13, Estilos_UI.TINTA_SUAVE))
	else:
		v.add_child(Estilos_UI.parrafo(
			"Retírate como futbolista o paga el título de entrenador para fundar tu club, fichar promesas y competir en directo.",
			13, Estilos_UI.TINTA_SUAVE))

	var texto_btn: String = "Gestionar club" if activo else ("Fundar club" if desbloqueado else "Desbloquear")
	if activo and Sistema_Manager.Puede_Jugar_Manual():
		texto_btn = "Entrar al club · Jugar partido"
	var btn := Estilo_Manager.boton(
		texto_btn,
		"exito" if (activo or desbloqueado) else "primario",
		"play" if activo else "key",
		Estilos_UI.EXITO if (activo or desbloqueado) else Estilo_Manager.COLOR_MANAGER,
		50)
	btn.name = "Btn_Abrir_Manager"
	btn.pressed.connect(_Abrir_Manager)
	v.add_child(btn)


func _Formatear_Euros_Manager(numero: int) -> String:
	var negativo: bool = numero < 0
	var texto: String = str(absi(numero))
	var salida: String = ""
	var contador: int = 0
	for i in range(texto.length() - 1, -1, -1):
		salida = texto.substr(i, 1) + salida
		contador += 1
		if contador % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if negativo else "") + salida + " €"


func _Abrir_Manager() -> void:
	if _capa_panel_manager != null and is_instance_valid(_capa_panel_manager):
		return
	if _transicion_minijuego_activa:
		return
	_transicion_minijuego_activa = true

	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var transicion = _Obtener_Transicion_Minijuego().new()
	transicion.name = "Transicion_Minijuego"
	transicion.configurar_tema("manager", club)
	add_child(transicion)
	var titulo_t: String = str(club.get("nombre", "El Mánager")) if not club.is_empty() else "El Mánager"
	var sub_t: String = "Preparando el vestuario y la pizarra…" if not club.is_empty() else "Accediendo a los despachos del club…"
	await transicion.Cubrir(titulo_t, sub_t)

	if not is_inside_tree() or not is_instance_valid(transicion):
		_transicion_minijuego_activa = false
		return

	_capa_panel_manager = CanvasLayer.new()
	_capa_panel_manager.name = "Capa_Panel_Manager"
	_capa_panel_manager.layer = 60
	add_child(_capa_panel_manager)
	_panel_manager = _PANEL_MANAGER_ESCENA.instantiate()
	_capa_panel_manager.add_child(_panel_manager)
	_panel_manager.cerrado.connect(_on_panel_manager_cerrado)
	await get_tree().create_timer(0.14).timeout

	if not is_inside_tree() or not is_instance_valid(transicion):
		_transicion_minijuego_activa = false
		return

	await transicion.Descubrir("¡Saltamos al campo!" if not club.is_empty() else "¡Bienvenido al banquillo!")
	_transicion_minijuego_activa = false


func _on_panel_manager_cerrado() -> void:
	if _transicion_minijuego_activa:
		return
	_transicion_minijuego_activa = true
	var transicion = _Obtener_Transicion_Minijuego().new()
	transicion.name = "Transicion_Minijuego"
	transicion.configurar_tema("manager", Sistema_Manager.Club_Usuario())
	add_child(transicion)
	await transicion.Cubrir("Volviendo al Sim", "Saliendo de las instalaciones…")

	if not is_inside_tree():
		_transicion_minijuego_activa = false
		return

	if _panel_manager != null and is_instance_valid(_panel_manager):
		_panel_manager.visible = false
		if _panel_manager.has_method("_Aplicar_Orientacion_Vertical"):
			_panel_manager._Aplicar_Orientacion_Vertical()
	if _capa_panel_manager != null and is_instance_valid(_capa_panel_manager):
		_capa_panel_manager.queue_free()
	_capa_panel_manager = null
	_panel_manager = null
	_Refrescar_Tras_Minijuego_Cocina()
	_Actualizar_Pantalla_Minijuegos_Si_Visible()
	await get_tree().process_frame
	await get_tree().process_frame

	if not is_inside_tree() or not is_instance_valid(transicion):
		_transicion_minijuego_activa = false
		return

	await transicion.Descubrir("¡De vuelta al día a día!")
	_transicion_minijuego_activa = false


# Añade un sprite al banner respetando su relación de aspecto dentro de la caja.
func _Anadir_Item_Banner(banner: Control, tex: Texture2D, pos: Vector2, tam: Vector2) -> void:
	if tex == null:
		return
	var nodo := TextureRect.new()
	nodo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nodo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	nodo.texture = tex
	nodo.position = pos
	nodo.size = tam
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(nodo)


# Sombra elíptica de contacto: un degradado radial estirado bajo el sprite.
func _Anadir_Sombra_Banner(banner: Control, centro: Vector2, tam: Vector2) -> void:
	var nodo := TextureRect.new()
	nodo.name = "Sombra_Banner"
	nodo.texture = Arte_Cocina.textura_sombra_contacto()
	nodo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nodo.stretch_mode = TextureRect.STRETCH_SCALE
	nodo.position = centro - tam * 0.5
	nodo.size = tam
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(nodo)


func _Actualizar_Pantalla_Minijuegos_Si_Visible() -> void:
	if _pantalla_minijuegos != null and is_instance_valid(_pantalla_minijuegos) and _pantalla_minijuegos.is_visible_in_tree():
		_Actualizar_Pantalla_Minijuegos()


func _Abrir_Minijuego_Cocina() -> void:
	var validacion: Dictionary = Sistema_Cocina.Puede_Entrar_Minijuego()
	if not bool(validacion.get("permitido", false)):
		if _dialog_minijuego_bloqueado == null:
			_dialog_minijuego_bloqueado = AcceptDialog.new()
			_dialog_minijuego_bloqueado.title = "No disponible ahora"
			add_child(_dialog_minijuego_bloqueado)
		_dialog_minijuego_bloqueado.dialog_text = str(validacion.get("mensaje", "No puedes entrar al minijuego ahora."))
		_dialog_minijuego_bloqueado.popup_centered(Vector2i(520, 200))
		return

	if _capa_minijuego_cocina != null and is_instance_valid(_capa_minijuego_cocina):
		return
	if _transicion_minijuego_activa:
		return

	# Transición de entrada: el telón de cocina cubre la pantalla, se prepara
	# el minijuego debajo y después el telón sigue subiendo para descubrirlo.
	_transicion_minijuego_activa = true
	var transicion = _Obtener_Transicion_Minijuego().new()
	transicion.name = "Transicion_Minijuego"
	add_child(transicion)
	await transicion.Cubrir("Cocina", "Preparando los fogones…")

	if not is_inside_tree() or not is_instance_valid(transicion):
		_transicion_minijuego_activa = false
		return

	_Instanciar_Minijuego_Cocina()
	await get_tree().create_timer(0.12).timeout

	if not is_inside_tree() or not is_instance_valid(transicion):
		_transicion_minijuego_activa = false
		return

	await transicion.Descubrir("¡A cocinar!")
	_transicion_minijuego_activa = false


## Carga la escena del minijuego solo la primera vez que se entra. Antes estaba
## en un preload del script principal, lo que obligaba a decodificar las ~150
## texturas de la cocina al arrancar el juego (coste alto en móviles modestos).
func _Obtener_Escena_Minijuego_Cocina() -> PackedScene:
	if _minijuego_cocina_packed == null:
		_minijuego_cocina_packed = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn") as PackedScene
	return _minijuego_cocina_packed


func _Obtener_Transicion_Minijuego() -> Script:
	if _script_transicion_minijuego == null:
		_script_transicion_minijuego = load("res://Scripts/GUI/Transiciones/Transicion_Minijuego.gd") as Script
	return _script_transicion_minijuego


func _Instanciar_Minijuego_Cocina() -> void:
	if _capa_minijuego_cocina != null and is_instance_valid(_capa_minijuego_cocina):
		return
	_minijuego_cocina_activo = true
	_capa_minijuego_cocina = CanvasLayer.new()
	_capa_minijuego_cocina.name = "Capa_Minijuego_Cocina"
	_capa_minijuego_cocina.layer = 60
	add_child(_capa_minijuego_cocina)

	var instancia := _Obtener_Escena_Minijuego_Cocina().instantiate()
	instancia.cerrado.connect(_on_minijuego_cocina_cerrado)
	_capa_minijuego_cocina.add_child(instancia)


func _on_minijuego_cocina_cerrado() -> void:
	if _transicion_minijuego_activa:
		return
	# Transición de salida: el telón sube sobre la cocina, se retira el
	# minijuego y se refresca la escena principal antes de descubrirla.
	_transicion_minijuego_activa = true
	var transicion = _Obtener_Transicion_Minijuego().new()
	transicion.name = "Transicion_Minijuego"
	add_child(transicion)
	await transicion.Cubrir("Volviendo al Sim", "Recogiendo la cocina…")

	if not is_inside_tree():
		_transicion_minijuego_activa = false
		return

	if _capa_minijuego_cocina != null and is_instance_valid(_capa_minijuego_cocina):
		_capa_minijuego_cocina.queue_free()
		_capa_minijuego_cocina = null
	_minijuego_cocina_activo = false
	_Refrescar_Tras_Minijuego_Cocina()
	await get_tree().process_frame
	await get_tree().process_frame

	if not is_inside_tree() or not is_instance_valid(transicion):
		_transicion_minijuego_activa = false
		return

	await transicion.Descubrir("¡De vuelta a casa!")
	_transicion_minijuego_activa = false


func _Refrescar_Tras_Minijuego_Cocina() -> void:
	_Ajustar_Disposicion_Vertical()
	_Redisenar_Superior()
	_Redisenar_Inferior()
	Actualizar_Dinero()
	Actualizar_Progreso()
	necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)
	_Actualizar_Badges()
	_Actualizar_Home()
	_Actualizar_Pantalla_Minijuegos_Si_Visible()
	_Actualizar_Nav_Activa()


# ----------------------------------------------------------------------------
# Minijuego "Salir a correr" (runner infinito)
# ----------------------------------------------------------------------------

func _Obtener_Escena_Minijuego_Correr() -> PackedScene:
	if _minijuego_correr_packed == null:
		_minijuego_correr_packed = load("res://Escenas/Minijuego_Correr/Minijuego_Correr.tscn") as PackedScene
	return _minijuego_correr_packed


func _Abrir_Minijuego_Correr() -> void:
	if _capa_minijuego_correr != null and is_instance_valid(_capa_minijuego_correr):
		return
	if _transicion_minijuego_activa:
		return

	_minijuego_correr_activo = true
	_capa_minijuego_correr = CanvasLayer.new()
	_capa_minijuego_correr.name = "Capa_Minijuego_Correr"
	_capa_minijuego_correr.layer = 60
	add_child(_capa_minijuego_correr)

	var instancia := _Obtener_Escena_Minijuego_Correr().instantiate()
	instancia.cerrado.connect(_on_minijuego_correr_cerrado)
	_capa_minijuego_correr.add_child(instancia)


func _on_minijuego_correr_cerrado() -> void:
	if _capa_minijuego_correr != null and is_instance_valid(_capa_minijuego_correr):
		_capa_minijuego_correr.queue_free()
		_capa_minijuego_correr = null
	_minijuego_correr_activo = false
	_Refrescar_Tras_Minijuego_Cocina()


func _on_restaurante_cocina_desbloqueado(restaurante_id: String, nombre_restaurante: String) -> void:
	_minijuegos_novedad_pendiente = true
	_Actualizar_Badges()
	_Actualizar_Pantalla_Minijuegos_Si_Visible()
	var rest_cfg: Dictionary = Sistema_Cocina.Obtener_Restaurante(restaurante_id)
	if bool(rest_cfg.get("implementado", false)):
		_Mostrar_Toast_Desbloqueo(
			"¡Nuevo minijuego desbloqueado: Cocina!",
			"Ya puedes jugar en %s desde el apartado Minijuegos." % nombre_restaurante)
	else:
		_Mostrar_Toast_Desbloqueo(
			"Restaurante desbloqueado: %s" % nombre_restaurante,
			"Su mundo de cocina llegará al apartado Minijuegos en la Fase 2.")


func _Mostrar_Toast_Desbloqueo(titulo_toast: String, subtitulo_toast: String) -> void:
	if not is_inside_tree():
		return
	var capa := CanvasLayer.new()
	capa.name = "Toast_Desbloqueo_Cocina"
	capa.layer = 90
	add_child(capa)

	var card := PanelContainer.new()
	card.position = Vector2(20, -110)
	card.size = Vector2(680, 82)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(Estilos_UI.NAVY, 16, Color("#f59e0b"), 2, 3)
	st.border_width_bottom = 3
	card.add_theme_stylebox_override("panel", st)
	capa.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)

	h.add_child(Estilos_UI.badge_icono("utensils", 42, 20, Color("#ea580c"), Color.WHITE, 11))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(col)

	var lt := Estilos_UI.titulo(titulo_toast, 15, Color("#fde68a"))
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(lt)
	var ls := Estilos_UI.texto(subtitulo_toast, 12, Color.WHITE, 500)
	ls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(ls)

	var tw := card.create_tween()
	tw.tween_property(card, "position:y", 16.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(4.2)
	tw.tween_property(card, "position:y", -120.0, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(capa.queue_free)
# ============================================================
# Diseño e interfaz principal
# ============================================================

var _home: Control = null
var _home_refresh: float = 0.0
var _reloj_header: Label = null
var _home_actividad: Label = null
var _home_escenario: Escenario_Actividad = null
var _home_estado_banda: ColorRect = null
var _home_estado_badge: PanelContainer = null
var _home_estado_icono: TextureRect = null
var _home_bienestar_pill: PanelContainer = null
var _home_fecha: Label = null
var _home_edad: Label = null
var _home_vivienda_pill: PanelContainer = null
var _home_trabajo_val: Label = null
var _home_carrera_val: Label = null
var _home_barras: Array = []
var _home_pcts: Array = []
var _home_resumen_necesidades: Label = null
# Carrusel horizontal de Acciones rápidas del Home.
var _home_acciones_scroll: ScrollContainer = null
var _home_accion_izq: Button = null
var _home_accion_der: Button = null
var _home_acciones_tween: Tween = null
var _necesidades_vivienda_pill: PanelContainer = null
var _necesidades_equipo_lbl: Label = null
var _progreso_inversion_bar: ProgressBar = null
var _progreso_inversion_pct: Label = null
var _progreso_metas_box: VBoxContainer = null
var _tienda_origen: String = "home"


# Alto visible del área de juego en coordenadas de diseño (720 x H).
# Con stretch "canvas_items" + "expand" el alto crece en pantallas más alargadas
# que 16:9, así que todo lo anclado abajo debe usar este valor y no 1280 fijo.
func _Alto_Pantalla() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1280.0
	var alto: float = vp.get_visible_rect().size.y
	return alto if alto >= 1280.0 else 1280.0


func _Aplicar_Rediseno() -> void:
	var alto := _Alto_Pantalla()
	var fondo := get_node_or_null("Fondo")
	if fondo is Sprite2D:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Estilos_UI.FONDO)
		fondo.texture = ImageTexture.create_from_image(img)
		fondo.position = Vector2(360.0, alto * 0.5)
		fondo.scale = Vector2(360.0, alto * 0.5)

	var top := get_node_or_null("Top_Bar_Panel")
	if top != null:
		top.visible = false

	_Redisenar_Superior()
	_Redisenar_Inferior()
	_Redisenar_Progreso()
	_Redisenar_Habilidades()
	_Redisenar_Necesidades()
	_Redisenar_Actividades()
	_Redisenar_Horario()
	_Redisenar_Seleccionar_Horario()
	_Redisenar_Perfil()
	_Redisenar_Tienda()
	_Estilizar_Badges()
	_Crear_Home()
	_Actualizar_Reloj_Header()
	_Actualizar_Home()
	_Actualizar_Nav_Activa()
	_Ajustar_Disposicion_Vertical()

	for ruta in [
		"Habilidades", "Progreso", "Necesidades_Basicas", "Actividades",
		"Actividades/Elegir_Actividad", "Actividades/Horario_Semanal",
		"Actividades/Seleccionar_Horario", "Pantalla_Mensajes",
		"Pantalla_Mensajes/Fondo_Mensajes", "Pantalla_Mensajes/Contenido_Mensaje", "Tienda",
		"Tienda/Objetos_Ventajas",
	]:
		var n := get_node_or_null(ruta) as Control
		if n != null:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_boton_ajustes_pressed() -> void:
	if _panel_ajustes != null and is_instance_valid(_panel_ajustes):
		return
	_panel_ajustes = Panel_Ajustes.new()
	_panel_ajustes.cerrado.connect(func(): _panel_ajustes = null)
	add_child(_panel_ajustes)


func _Redisenar_Superior() -> void:
	var header := get_node_or_null("Header_Superior") as Panel
	if header == null:
		header = Panel.new()
		header.name = "Header_Superior"
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(header)
	header.position = Vector2.ZERO
	header.size = Vector2(720, 68)
	header.z_index = 25
	header.clip_contents = true
	var hs := Estilos_UI.caja(Estilos_UI.ROJO_BIT, 0, Estilos_UI.ROJO_BIT_OSCURO, 0, 0)
	hs.border_width_bottom = 3
	hs.border_color = Estilos_UI.ROJO_BIT_OSCURO
	header.add_theme_stylebox_override("panel", hs)

	var rayas := header.get_node_or_null("Rayas_Header")
	if rayas == null:
		rayas = Estilos_UI.BannerRayasBitLife.new(Estilos_UI.ROJO_BIT, Estilos_UI.ROJO_BIT_OSCURO, 3.0, 0.065)
		rayas.name = "Rayas_Header"
		rayas.set_anchors_preset(Control.PRESET_FULL_RECT)
		header.add_child(rayas)

	var marca_old := get_node_or_null("Logo_Marca")
	if marca_old != null:
		marca_old.queue_free()

	var avatar_btn := get_node_or_null("Avatar_Header_Btn") as Button
	if avatar_btn == null:
		avatar_btn = Button.new()
		avatar_btn.name = "Avatar_Header_Btn"
		avatar_btn.flat = true
		avatar_btn.text = ""
		avatar_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		avatar_btn.tooltip_text = "Abrir perfil"
		for st_k in ["normal", "hover", "pressed", "focus"]:
			avatar_btn.add_theme_stylebox_override(st_k, StyleBoxEmpty.new())
		avatar_btn.pressed.connect(_on_perfil_button_pressed)
		Estilos_UI.animar_presion(avatar_btn)
		add_child(avatar_btn)
		var av := Estilos_UI.avatar_personaje(44, Color.WHITE, 2,
			Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(Variables_Estaticas.Apariencia), false)
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		avatar_btn.add_child(av)
	else:
		var retrato := avatar_btn.find_child("Retrato", true, false)
		if retrato is Personaje_Visual:
			retrato.apariencia = Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(
				Variables_Estaticas.Apariencia)
	avatar_btn.position = Vector2(16, 11)
	avatar_btn.size = Vector2(44, 44)
	avatar_btn.z_index = 30

	var logo := get_node_or_null("Logo_Titulo") as Label
	if logo == null:
		logo = Label.new()
		logo.name = "Logo_Titulo"
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(logo)
	logo.position = Vector2(70, 9)
	logo.size = Vector2(280, 27)
	logo.z_index = 30
	logo.text = "Sims Life"
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", Estilos_UI.fuente_logo())
	logo.add_theme_font_size_override("font_size", 21)
	logo.add_theme_color_override("font_color", Color.WHITE)
	logo.add_theme_color_override("font_shadow_color", Color(0.35, 0.04, 0.04, 0.50))
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 2)
	logo.add_theme_constant_override("outline_size", 0)

	_reloj_header = get_node_or_null("Reloj_Header") as Label
	if _reloj_header == null:
		_reloj_header = Label.new()
		_reloj_header.name = "Reloj_Header"
		_reloj_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_reloj_header)
	_reloj_header.position = Vector2(70, 36)
	_reloj_header.size = Vector2(420, 20)
	_reloj_header.z_index = 30
	_reloj_header.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	_reloj_header.add_theme_font_size_override("font_size", 12)
	_reloj_header.add_theme_color_override("font_color", Color("#fee2e2"))

	# Un único acceso de ajustes en la cabecera: desde su panel se gestionan
	# la música y los efectos de sonido.
	var btn_ajustes := get_node_or_null("Boton_Ajustes_Header") as Button
	if btn_ajustes == null:
		btn_ajustes = Estilos_UI.boton_icono("settings", Estilos_UI.ROJO_BIT, 38)
		btn_ajustes.name = "Boton_Ajustes_Header"
		btn_ajustes.tooltip_text = "Ajustes de sonido"
		btn_ajustes.pressed.connect(_on_boton_ajustes_pressed)
		add_child(btn_ajustes)
	btn_ajustes.icon = Estilos_UI.icono("settings")
	btn_ajustes.position = Vector2(414, 15)
	btn_ajustes.size = Vector2(38, 38)
	btn_ajustes.z_index = 30
	btn_ajustes.visible = true

	# Acceso rápido a la Tienda junto al dinero.
	var btn_tienda := get_node_or_null("Boton_Tienda_Header") as Button
	if btn_tienda == null:
		btn_tienda = Estilos_UI.boton_icono("store", Estilos_UI.ROJO_BIT, 38)
		btn_tienda.name = "Boton_Tienda_Header"
		btn_tienda.tooltip_text = "Tienda"
		btn_tienda.pressed.connect(_on_tienda_tab_pressed)
		add_child(btn_tienda)
	btn_tienda.position = Vector2(460, 15)
	btn_tienda.size = Vector2(38, 38)
	btn_tienda.z_index = 30

	var nav := get_node_or_null("Nav_Superior") as Panel
	if nav == null:
		nav = Panel.new()
		nav.name = "Nav_Superior"
		nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(nav)
	nav.position = Vector2(0, 68)
	nav.size = Vector2(720, 48)
	nav.z_index = 24
	var ns := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 0, Estilos_UI.BORDE, 0, 1)
	ns.border_width_bottom = 2
	ns.border_color = Estilos_UI.BORDE
	nav.add_theme_stylebox_override("panel", ns)

	var tabs := [
		["Boton_Perfil", "Perfil", "user-round"],
		["Economia_Button", "Economía", "wallet"],
		["Calendario_Button", "Horario", "calendar-days"],
		["Carrera_Button", "Carrera", "graduation-cap"],
		["Minijuegos_Button", "Minijuegos", "puzzle"],
		["Vestuario_Button", "Vestuario", "shirt"],
	]
	var ancho_tab := 112.0
	var hueco_tab := 4.0
	var x_inicial := 12.0
	for i in range(tabs.size()):
		var datos: Array = tabs[i]
		var b := get_node_or_null(datos[0]) as Button
		if b == null:
			continue
		b.z_index = 30
		b.visible = true
		b.text = datos[1]
		b.icon = Estilos_UI.icono(datos[2])
		b.expand_icon = false
		b.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_constant_override("icon_max_width", 15)
		b.add_theme_constant_override("h_separation", 4)
		# Posición y tamaño al final: al cambiar texto e icono Godot recalcula
		# el tamaño mínimo y la pestaña crecería dejando de estar alineada.
		b.position = Vector2(x_inicial + float(i) * (ancho_tab + hueco_tab), 73)
		b.custom_minimum_size = Vector2(ancho_tab, 38)
		b.size = Vector2(ancho_tab, 38)

	# La Tienda ya no ocupa pestaña: se entra por su icono junto al dinero.
	var btn_tienda_tab := get_node_or_null("Tienda_Button") as Button
	if btn_tienda_tab != null:
		btn_tienda_tab.visible = false

	var chip := get_node_or_null("Moneda_Fondo") as Panel
	if chip == null:
		chip = Panel.new()
		chip.name = "Moneda_Fondo"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(chip)
	chip.position = Vector2(510, 13)
	chip.size = Vector2(194, 40)
	chip.z_index = 29
	var st_chip := Estilos_UI.caja(Color(1, 1, 1, 0.98), 999, Estilos_UI.ROJO_BIT_OSCURO, 0, 2)
	st_chip.border_width_bottom = 3
	chip.add_theme_stylebox_override("panel", st_chip)

	var moneda := get_node_or_null("Moneda") as Sprite2D
	if moneda != null:
		moneda.texture = load("res://Imagenes/UI/Icono_Moneda.svg")
		moneda.position = Vector2(533, 33)
		moneda.scale = Vector2(0.64, 0.64)
		moneda.z_index = 30

	var dinero := get_node_or_null("Dinero_Label") as Label
	if dinero != null:
		dinero.position = Vector2(552, 13)
		dinero.size = Vector2(138, 40)
		dinero.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dinero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dinero.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
		dinero.add_theme_font_size_override("font_size", 17)
		dinero.add_theme_color_override("font_color", Estilos_UI.EXITO)
		dinero.z_index = 30


func _Actualizar_Reloj_Header() -> void:
	if _reloj_header == null or not is_instance_valid(_reloj_header):
		return
	var edad := Variables_Estaticas.Calcular_Edad()
	var fecha_txt := Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(
		Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute)
	_reloj_header.text = "%s · %d años" % [fecha_txt, max(18, edad)]


func _Actualizar_Nav_Activa() -> void:
	var barra_nav := get_node_or_null("Barra_Abajo")
	var top_activo := ""
	var bottom_activo := ""

	if has_node("Pantalla_Mensajes") and $Pantalla_Mensajes.visible:
		top_activo = "Boton_Perfil"
	elif _pantalla_bolsa != null and is_instance_valid(_pantalla_bolsa) and _pantalla_bolsa.visible:
		top_activo = "Economia_Button"
	elif _pantalla_economia != null and is_instance_valid(_pantalla_economia) and _pantalla_economia.visible:
		top_activo = "Economia_Button"
	elif _pantalla_carrera != null and is_instance_valid(_pantalla_carrera) and _pantalla_carrera.visible:
		top_activo = "Carrera_Button"
	elif _pantalla_minijuegos != null and is_instance_valid(_pantalla_minijuegos) and _pantalla_minijuegos.visible:
		top_activo = "Minijuegos_Button"
	elif _pantalla_vestuario != null and is_instance_valid(_pantalla_vestuario) and _pantalla_vestuario.visible:
		top_activo = "Vestuario_Button"
	elif $Actividades.visible and calendario_solo_lectura:
		top_activo = "Calendario_Button"
	elif $Habilidades.visible:
		bottom_activo = "Boton_Habilidades"
	elif $Progreso.visible:
		bottom_activo = "Boton_Progreso"
	elif $Necesidades_Basicas.visible:
		bottom_activo = "Boton_Necesidades_Basicas"
	elif $Actividades.visible:
		bottom_activo = "Boton_Actividades"
	elif _home != null and is_instance_valid(_home) and _home.visible:
		bottom_activo = "Boton_Inicio"

	if barra_nav != null:
		Estilos_UI.marcar_nav_activo(barra_nav, bottom_activo)

	for nombre_top in ["Boton_Perfil", "Economia_Button", "Calendario_Button", "Carrera_Button", "Minijuegos_Button", "Vestuario_Button"]:
		var b := get_node_or_null(nombre_top) as Button
		if b == null:
			continue
		var on: bool = (str(nombre_top) == top_activo)
		var bg := Estilos_UI.ROJO_BIT_SUAVE if on else Color(0, 0, 0, 0)
		var hv := Estilos_UI.ROJO_BIT_SUAVE if on else Estilos_UI.SUPERFICIE_2
		var st_n := Estilos_UI.caja(bg, 10, Estilos_UI.ROJO_BIT, 0, 0)
		if on:
			st_n.border_width_bottom = 3
		b.add_theme_stylebox_override("normal", st_n)
		b.add_theme_stylebox_override("hover", Estilos_UI.caja(hv, 10, Color(0, 0, 0, 0), 0, 0))
		b.add_theme_stylebox_override("pressed", Estilos_UI.caja(Estilos_UI.ROJO_BIT_SUAVE, 10, Color(0, 0, 0, 0), 0, 0))
		b.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if on else 600))
		var col := Estilos_UI.ROJO_BIT if on else Estilos_UI.TINTA_SUAVE
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
				"icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			b.add_theme_color_override(k, col)


func _Redisenar_Inferior() -> void:
	var alto := _Alto_Pantalla()
	var dock := get_node_or_null("Dock_Fondo") as Panel
	if dock == null:
		dock = Panel.new()
		dock.name = "Dock_Fondo"
		dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dock)
	dock.position = Vector2(0, alto - 96.0)
	dock.size = Vector2(720, 96)
	dock.z_index = 19
	var ds := Estilos_UI.caja(Estilos_UI.NAVY, 0, Color("#2d3a50"), 0, 0)
	ds.border_width_top = 2
	ds.border_color = Color("#2d3a50")
	dock.add_theme_stylebox_override("panel", ds)

	var barra := get_node_or_null("Barra_Abajo") as HBoxContainer
	if barra != null:
		var inicio := barra.get_node_or_null("Boton_Inicio") as Button
		if inicio == null:
			inicio = Button.new()
			inicio.name = "Boton_Inicio"
			barra.add_child(inicio)
			barra.move_child(inicio, 0)
			Estilos_UI.configurar_nav(inicio, "house", "Inicio")
			inicio.pressed.connect(Quitar_Todo)
		for b in barra.get_children():
			if b is Button:
				b.custom_minimum_size = Vector2(0, 72)
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				b.size_flags_stretch_ratio = 1.0
				b.expand_icon = false
				b.size = Vector2(137, 72)
		barra.custom_minimum_size = Vector2(704, 78)
		barra.position = Vector2(8, alto - 88.0)
		barra.size = Vector2(704, 78)
		barra.z_index = 20
		barra.add_theme_constant_override("separation", 4)


# Recoloca y redimensiona los elementos que dependen del alto real de la pantalla.
# Se llama al terminar el rediseño y cada vez que cambia el tamaño del viewport.
func _Ajustar_Disposicion_Vertical() -> void:
	if _minijuego_cocina_activo:
		return
	var alto := _Alto_Pantalla()

	var fondo := get_node_or_null("Fondo") as Sprite2D
	if fondo != null:
		fondo.position = Vector2(360.0, alto * 0.5)
		fondo.scale = Vector2(360.0, alto * 0.5)

	var dock := get_node_or_null("Dock_Fondo") as Control
	if dock != null:
		dock.position.y = alto - 96.0
	var barra := get_node_or_null("Barra_Abajo") as Control
	if barra != null:
		barra.position.y = alto - 88.0

	if _home != null and is_instance_valid(_home):
		_home.size.y = alto - 228.0

	for ruta in [
		"Progreso", "Habilidades", "Necesidades_Basicas", "Actividades",
		"Actividades/Horario_Semanal", "Actividades/Seleccionar_Horario",
		"Pantalla_Mensajes", "Tienda", "Pantalla_Carrera", "Pantalla_Economia",
		"Pantalla_Minijuegos",
	]:
		var seccion := get_node_or_null(ruta) as Control
		if seccion == null:
			continue
		seccion.size.y = alto
		for hijo in seccion.get_children():
			if hijo is Control and (hijo.name == "Fondo_Seccion" or hijo.name == "Fondo_Mensajes"):
				(hijo as Control).size.y = alto

	# Contenido del perfil: crece hasta dejar el mismo margen sobre el dock.
	var alto_contenido := alto - 358.0
	for ruta in [
		"Pantalla_Mensajes/Lista_Mensajes", "Pantalla_Mensajes/Panel_Info",
		"Pantalla_Mensajes/Panel_Apuntes", "Pantalla_Mensajes/Contenido_Mensaje",
		"Pantalla_Mensajes/Panel_Despensa",
		"Pantalla_Mensajes/Panel_Info/Scroll_Info",
		"Pantalla_Mensajes/Panel_Despensa/Scroll_Tuppers",
	]:
		var contenido := get_node_or_null(ruta) as Control
		if contenido != null:
			contenido.size.y = alto_contenido

	for ruta_sub in [
		"Pantalla_Mensajes/Panel_Apuntes/Scroll_Inventario",
	]:
		var sub_cont := get_node_or_null(ruta_sub) as Control
		if sub_cont != null:
			sub_cont.size.y = maxf(120.0, alto_contenido)

	if _minijuegos_scroll != null and is_instance_valid(_minijuegos_scroll):
		_minijuegos_scroll.size.y = alto - 304.0

	var card_mensaje := get_node_or_null("Pantalla_Mensajes/Contenido_Mensaje/Mensaje_Card") as Control
	if card_mensaje != null:
		card_mensaje.size.y = alto_contenido - 22.0
	var desc_mensaje := get_node_or_null("Pantalla_Mensajes/Contenido_Mensaje/Descripcion_Mensaje_Label") as Control
	if desc_mensaje != null:
		desc_mensaje.size.y = alto_contenido - 202.0

	var tienda_objetos := get_node_or_null("Tienda") as Control
	if tienda_objetos != null and tienda_objetos.has_method("Ajustar_Disposicion"):
		tienda_objetos.call("Ajustar_Disposicion", alto)

	var vbox_carrera := get_node_or_null("Pantalla_Carrera/VBoxContainer") as Control
	if vbox_carrera == null:
		var pantalla_carrera := get_node_or_null("Pantalla_Carrera")
		if pantalla_carrera != null:
			for hijo in pantalla_carrera.get_children():
				if hijo is VBoxContainer:
					vbox_carrera = hijo
					break
	if vbox_carrera != null:
		vbox_carrera.size.y = alto - 320.0

	var vbox_economia := get_node_or_null("Pantalla_Economia/VBoxContainer") as Control
	if vbox_economia == null:
		var pantalla_economia := get_node_or_null("Pantalla_Economia")
		if pantalla_economia != null:
			for hijo in pantalla_economia.get_children():
				if hijo is VBoxContainer:
					vbox_economia = hijo
					break
	if vbox_economia != null:
		vbox_economia.size.y = alto - 304.0


func _Preparar_Seccion(panel: Control, titulo_txt: String, icono_sec: String = "", color_sec: Color = Estilos_UI.ROJO_BIT) -> void:
	if panel == null:
		return
	var alto := _Alto_Pantalla()
	panel.position = Vector2.ZERO
	panel.size = Vector2(720, alto)

	var bg := panel.get_node_or_null("Fondo_Seccion") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "Fondo_Seccion"
		bg.color = Estilos_UI.FONDO
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bg)
		panel.move_child(bg, 0)
	bg.position = Vector2.ZERO
	bg.size = Vector2(720, alto)
	bg.z_index = -3

	var card := panel.get_node_or_null("Panel_BG") as Panel
	if card != null:
		card.queue_free()

	var badge_old := panel.get_node_or_null("Badge_Seccion")
	if badge_old != null:
		badge_old.queue_free()
	var offset_titulo := 20.0
	if icono_sec != "":
		var b_sec := Estilos_UI.badge_icono(icono_sec, 38, 20, color_sec, Color.WHITE, 11)
		b_sec.name = "Badge_Seccion"
		b_sec.position = Vector2(20, 128)
		b_sec.size = Vector2(38, 38)
		panel.add_child(b_sec)
		offset_titulo = 70.0

	var t := panel.get_node_or_null("Titulo") as Label
	if t != null:
		t.position = Vector2(offset_titulo, 128)
		t.size = Vector2(700 - offset_titulo, 38)
		t.text = titulo_txt
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
		t.add_theme_font_size_override("font_size", 24)
		t.add_theme_color_override("font_color", Estilos_UI.TINTA)
		t.add_theme_constant_override("outline_size", 0)

	var sub_old := panel.get_node_or_null("Subtitulo_Seccion")
	if sub_old != null:
		sub_old.queue_free()


func _Configurar_Filas(panel: Control, ruta_barras: String, ruta_textos: String,
		nombres: Array, etiquetas: Array, iconos: Array, colores: Array,
		y0: float, alto: float, sep: float, usar_color_valor: bool = false) -> void:
	var barras := panel.get_node_or_null(ruta_barras) as VBoxContainer
	var textos := panel.get_node_or_null(ruta_textos) as VBoxContainer
	if barras == null or textos == null:
		return

	var card_grupo := panel.get_node_or_null("Card_Grupo") as Panel
	if card_grupo == null:
		card_grupo = Panel.new()
		card_grupo.name = "Card_Grupo"
		card_grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(card_grupo)
	card_grupo.position = Vector2(20, y0 - 16)
	card_grupo.size = Vector2(680, nombres.size() * alto + max(0, nombres.size() - 1) * sep + 32)
	card_grupo.z_index = -1
	card_grupo.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))

	var bar_h := 18
	barras.position = Vector2(244, y0 + (alto - bar_h) * 0.5)
	textos.position = Vector2(78, y0)
	barras.size = Vector2(340, nombres.size() * (alto + sep))
	textos.size = Vector2(158, nombres.size() * (alto + sep))
	barras.add_theme_constant_override("separation", int(alto + sep - bar_h))
	textos.add_theme_constant_override("separation", int(sep))

	for i in range(nombres.size()):
		var bar := barras.get_node_or_null(nombres[i]) as ProgressBar
		var lbl: Label = null
		if i < textos.get_child_count():
			lbl = textos.get_child(i) as Label
		var col_ic: Color = colores[i] if i < colores.size() else Estilos_UI.AZUL
		var col_fill: Color = Estilos_UI.color_valor(bar.value) if (usar_color_valor and bar != null) else col_ic
		if bar != null:
			bar.custom_minimum_size = Vector2(0, bar_h)
			bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			bar.show_percentage = false
			bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
			bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(col_fill))
		if lbl != null:
			lbl.label_settings = null
			lbl.text = etiquetas[i]
			lbl.custom_minimum_size = Vector2(0, alto)
			lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Estilos_UI.TINTA)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var fila_old := panel.get_node_or_null("Fila_Fondo_%d" % i)
		if fila_old != null:
			fila_old.queue_free()
		var ic_old := panel.get_node_or_null("Fila_Icono_%d" % i)
		if ic_old != null:
			ic_old.queue_free()
		var div_old := panel.get_node_or_null("Fila_Div_%d" % i)
		if div_old != null:
			div_old.queue_free()

		if i < nombres.size() - 1:
			var div := ColorRect.new()
			div.name = "Fila_Div_%d" % i
			div.color = Color("#edf1f7")
			div.position = Vector2(36, y0 + (i + 1) * alto + i * sep + sep * 0.5)
			div.size = Vector2(648, 1)
			div.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(div)

		var ic_badge := panel.get_node_or_null("Fila_Badge_%d" % i) as PanelContainer
		if ic_badge == null:
			ic_badge = Estilos_UI.badge_icono(iconos[i], 32, 16, col_ic, Color.WHITE, 9)
			ic_badge.name = "Fila_Badge_%d" % i
			panel.add_child(ic_badge)
		ic_badge.position = Vector2(36, y0 + i * (alto + sep) + (alto - 32) * 0.5)
		ic_badge.size = Vector2(32, 32)
		ic_badge.z_index = 0

		var pct := panel.get_node_or_null("Pct_%d" % i) as Label
		if pct == null:
			pct = Label.new()
			pct.name = "Pct_%d" % i
			panel.add_child(pct)
		pct.position = Vector2(592, y0 + i * (alto + sep))
		pct.size = Vector2(88, alto)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pct.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		pct.add_theme_font_size_override("font_size", 13)
		pct.add_theme_color_override("font_color", col_fill)
		if bar != null:
			pct.text = "%d%%" % int(bar.value)


func _Redisenar_Progreso() -> void:
	var panel := get_node_or_null("Progreso") as Control
	if panel == null:
		return
	_Preparar_Seccion(panel, "Progreso", "chart-no-axes-column", Estilos_UI.AZUL)
	for n in ["Manualidades2", "Manualidades3"]:
		var extra := panel.get_node_or_null("Progreso_Barra/" + n)
		if extra != null:
			extra.queue_free()
	for n in ["Flecha_Arriba", "Flecha_Abajo"]:
		var flecha := panel.get_node_or_null(n)
		if flecha != null:
			flecha.queue_free()

	var barras := panel.get_node_or_null("Progreso_Barra") as VBoxContainer
	if barras != null and barras.get_node_or_null("Cocina") == null:
		var bar_cocina := ProgressBar.new()
		bar_cocina.name = "Cocina"
		barras.add_child(bar_cocina)
	var textos := panel.get_node_or_null("Progreso_Texto") as VBoxContainer
	if textos != null and textos.get_node_or_null("Slot_Cocina") == null:
		var lbl_cocina := Label.new()
		lbl_cocina.name = "Slot_Cocina"
		textos.add_child(lbl_cocina)

	_Configurar_Filas(panel, "Progreso_Barra", "Progreso_Texto",
		["Deporte", "Academico", "Manualidades", "Cocina"],
		["Deporte", "Académico", "Manualidades", "Cocina"],
		["dumbbell", "book-open", "palette", "utensils"],
		[_COLORES_PROGRESO[0], _COLORES_PROGRESO[1], _COLORES_PROGRESO[2], Color("#ea580c")],
		198, 38, 16, false)

	var extra_card := PanelContainer.new()
	extra_card.name = "Card_Metas_Progreso"
	extra_card.position = Vector2(20, 432)
	extra_card.size = Vector2(680, 0)
	extra_card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	panel.add_child(extra_card)

	var em := MarginContainer.new()
	em.add_theme_constant_override("margin_left", 18)
	em.add_theme_constant_override("margin_right", 18)
	em.add_theme_constant_override("margin_top", 16)
	em.add_theme_constant_override("margin_bottom", 16)
	extra_card.add_child(em)

	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 12)
	em.add_child(ev)

	ev.add_child(Estilos_UI.texto("Inversiones y requisitos", 15, Estilos_UI.TINTA, 700))

	var inv_row := HBoxContainer.new()
	inv_row.add_theme_constant_override("separation", 10)
	ev.add_child(inv_row)
	inv_row.add_child(Estilos_UI.badge_icono("trending-up", 30, 16, Estilos_UI.AZUL, Color.WHITE, 8))
	var inv_lbl := Estilos_UI.texto("Experiencia en bolsa", 14, Estilos_UI.TINTA, 600)
	inv_lbl.custom_minimum_size = Vector2(158, 22)
	inv_row.add_child(inv_lbl)
	_progreso_inversion_bar = ProgressBar.new()
	_progreso_inversion_bar.custom_minimum_size = Vector2(0, 16)
	_progreso_inversion_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progreso_inversion_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progreso_inversion_bar.show_percentage = false
	_progreso_inversion_bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	_progreso_inversion_bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Estilos_UI.AZUL))
	inv_row.add_child(_progreso_inversion_bar)
	_progreso_inversion_pct = Estilos_UI.texto("1%", 13, Estilos_UI.AZUL, 700)
	inv_row.add_child(_progreso_inversion_pct)

	ev.add_child(Estilos_UI.divisor_horizontal())
	_progreso_metas_box = VBoxContainer.new()
	_progreso_metas_box.add_theme_constant_override("separation", 8)
	ev.add_child(_progreso_metas_box)
	_Actualizar_Progreso_Extra()


func _Actualizar_Progreso_Extra() -> void:
	if _progreso_inversion_bar != null:
		_progreso_inversion_bar.value = Variables_Dinamicas.Progreso_Inversion
	if _progreso_inversion_pct != null:
		_progreso_inversion_pct.text = "%d%%" % Variables_Dinamicas.Progreso_Inversion
	if _progreso_metas_box == null:
		return
	for hijo in _progreso_metas_box.get_children():
		hijo.queue_free()
	var metas := [
		["Carpintero", "Manualidades ≥ 30", Variables_Dinamicas.Progreso[2] >= 30],
		["Artista", "Manualidades ≥ 50 + Bellas Artes", Variables_Dinamicas.Progreso[2] >= 50],
		["Abogado", "Académico ≥ 50 + Derecho", Variables_Dinamicas.Progreso[1] >= 50],
		["Médico", "Académico ≥ 60 + Medicina", Variables_Dinamicas.Progreso[1] >= 60],
		["Científico", "Académico ≥ 65 + Ing. Informática", Variables_Dinamicas.Progreso[1] >= 65],
		["Ayudante de cocina", "Cocina ≥ 30", Variables_Dinamicas.Progreso_Cocina >= 30],
		["Cocinero de partida", "Cocina ≥ 60", Variables_Dinamicas.Progreso_Cocina >= 60],
		["Chef ejecutivo", "Cocina ≥ 85", Variables_Dinamicas.Progreso_Cocina >= 85],
	]
	for m in metas:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var cumplido: bool = m[2]
		row.add_child(Estilos_UI.icono_rect("circle-check" if cumplido else "lock", 16,
			Estilos_UI.EXITO if cumplido else Estilos_UI.TINTA_FANTASMA))
		var lbl := Estilos_UI.texto(m[0], 13, Estilos_UI.TINTA if cumplido else Estilos_UI.TINTA_SUAVE, 600)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		row.add_child(Estilos_UI.texto(m[1], 12, Estilos_UI.EXITO if cumplido else Estilos_UI.TINTA_FANTASMA, 500))
		_progreso_metas_box.add_child(row)
	if not Variables_Dinamicas.Ultimas_Pistas_Progreso.is_empty():
		var sep := HSeparator.new()
		_progreso_metas_box.add_child(sep)
		var pista_row := HBoxContainer.new()
		pista_row.add_theme_constant_override("separation", 8)
		pista_row.add_child(Estilos_UI.icono_rect("sparkles", 16, Estilos_UI.MORADO))
		var pista_lbl := Estilos_UI.parrafo(str(Variables_Dinamicas.Ultimas_Pistas_Progreso[0]), 12, Estilos_UI.TINTA_SUAVE)
		pista_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pista_row.add_child(pista_lbl)
		_progreso_metas_box.add_child(pista_row)


func _Redisenar_Habilidades() -> void:
	var panel := get_node_or_null("Habilidades") as Control
	if panel == null:
		return
	_Preparar_Seccion(panel, "Habilidades innatas", "sparkles", Estilos_UI.MORADO)

	var barras := panel.get_node_or_null("Habilidades_Barra") as VBoxContainer
	var textos := panel.get_node_or_null("Habilidades_Texto") as VBoxContainer
	if barras != null and textos != null:
		for idx in [5, 6]:
			if barras.get_node_or_null("Slot_%d" % idx) == null:
				var nb := ProgressBar.new()
				nb.name = "Slot_%d" % idx
				barras.add_child(nb)
			if textos.get_node_or_null("Slot_%d" % idx) == null:
				var nl := Label.new()
				nl.name = "Slot_%d" % idx
				textos.add_child(nl)

	_Configurar_Filas(panel, "Habilidades_Barra", "Habilidades_Texto",
		["Slot_0", "Slot_1", "Slot_2", "Slot_3", "Slot_4", "Slot_5", "Slot_6"],
		["Deporte", "Inteligencia", "Destreza", "Memoria", "Liderazgo", "Paciencia", "Sangre fría"],
		["dumbbell", "brain", "hand", "puzzle", "users", "hourglass", "snowflake"],
		[Color("#1ea34a"), Color("#1d7afc"), Color("#ea580c"), Color("#7c3aed"),
		 Color("#d62828"), Color("#0d9488"), Color("#475569")],
		198, 38, 14, false)

	for nombre in ["Flecha_Arriba", "Flecha_Abajo"]:
		var flecha := panel.get_node_or_null(nombre) as Button
		if flecha != null:
			flecha.queue_free()

	var nota := Estilos_UI.texto("Potencial innato descubierto mediante tus actividades.", 13, Estilos_UI.TINTA_FANTASMA, 500)
	nota.position = Vector2(20, 582)
	nota.size = Vector2(680, 24)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(nota)


func _Redisenar_Necesidades() -> void:
	var panel := get_node_or_null("Necesidades_Basicas") as Control
	if panel == null:
		return
	_Preparar_Seccion(panel, "Necesidades", "heart-pulse", Estilos_UI.ROJO_BIT)
	_Configurar_Filas(panel, "Necesidades_Basicas_Barra", "Necesidades_Basicas_Texto",
		["Salud_Fisica", "Salud_Mental", "Hambre", "Descanso", "Higiene"],
		["Salud física", "Salud mental", "Hambre", "Descanso", "Higiene"],
		["heart-pulse", "brain", "utensils", "moon", "droplet"],
		[Color("#1ea34a"), Color("#1d7afc"), Color("#f59e0b"), Color("#6366f1"), Color("#0891b2")],
		198, 38, 14, true)
	_Crear_Resumen_Necesidades(panel, 476)


func _Crear_Resumen_Necesidades(panel: Control, y: float) -> void:
	var card := PanelContainer.new()
	card.name = "Resumen_Necesidades"
	card.position = Vector2(20, y)
	card.size = Vector2(680, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	panel.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)

	var estado_lbl := Estilos_UI.texto("", 14, Estilos_UI.EXITO, 700)
	estado_lbl.name = "Estado_Temporal_Label"
	estado_lbl.visible = false
	v.add_child(estado_lbl)

	var media_col := VBoxContainer.new()
	media_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	media_col.add_theme_constant_override("separation", 2)
	top.add_child(media_col)

	media_col.add_child(Estilos_UI.texto("Bienestar medio", 12, Estilos_UI.TINTA_FANTASMA, 600))
	_home_resumen_necesidades = Estilos_UI.titulo("0%", 28, Estilos_UI.TINTA)
	media_col.add_child(_home_resumen_necesidades)

	_necesidades_vivienda_pill = Estilos_UI.pill_estado("Con alquiler", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
	top.add_child(_necesidades_vivienda_pill)

	v.add_child(Estilos_UI.divisor_horizontal())

	_necesidades_equipo_lbl = Estilos_UI.parrafo("", 13, Estilos_UI.TINTA_SUAVE)
	v.add_child(_necesidades_equipo_lbl)

	var btn_tienda := Estilos_UI.boton("Mejorar objetos en tienda", "secundario", "store", Estilos_UI.PRIMARIO, 46)
	btn_tienda.pressed.connect(func():
		_tienda_origen = "necesidades"
		_on_tienda_button_pressed()
	)
	v.add_child(btn_tienda)
	_Actualizar_Necesidades_Extra()


func _Actualizar_Necesidades_Extra() -> void:
	if _home_resumen_necesidades != null:
		var suma := 0.0
		for n in Variables_Dinamicas.Necesidades_Basicas:
			suma += n
		var media: float = suma / float(max(1, Variables_Dinamicas.Necesidades_Basicas.size()))
		_home_resumen_necesidades.text = "%d%%" % int(round(media))
		_home_resumen_necesidades.add_theme_color_override("font_color", Estilos_UI.color_valor(media))

	if _necesidades_vivienda_pill != null:
		if Variables_Dinamicas.En_La_Calle:
			_Actualizar_Badge_Pill(_necesidades_vivienda_pill, "En la calle (máx 20%)", Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO)
		else:
			_Actualizar_Badge_Pill(_necesidades_vivienda_pill, "Con alquiler", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)

	if _necesidades_equipo_lbl != null:
		var partes: Array = []
		for cat in ["Dormir", "Comer", "Duchar", "Salon", "Estudio", "Cocina"]:
			var objeto := Variables_Estaticas.Obtener_Objeto_Seleccionado(cat)
			if objeto == null:
				continue
			var tiene_mejora: bool = objeto.multiplicador != 1.0 \
				or objeto.bonus_progreso_deporte > 0.0 \
				or objeto.bonus_progreso_academico > 0.0 \
				or objeto.bonus_progreso_manualidades > 0.0 \
				or objeto.bonus_progreso_cocina > 0.0 \
				or objeto.bonus_calidad_tupper > 0.0
			if tiene_mejora:
				partes.append("%s · %s" % [objeto.nombre_para_mostrar(), objeto.etiqueta_efecto])
		_necesidades_equipo_lbl.text = "Equipamiento: " + (" · ".join(partes) if not partes.is_empty() else "Básico")

	if necesidades_basicas_gui != null:
		necesidades_basicas_gui.Actualizar_Estado_Temporal(self)


const _SUBTITULOS_ACTIVIDADES := {
	"Temporales": ["clock", "Dormir, comer, estudiar y ocio por bloques", Color("#1d7afc")],
	"Fijas": ["briefcase-business", "Empleos con jornada y sueldo fijo", Color("#1ea34a")],
	"Especiales": ["sparkles", "Fiesta nocturna y carreras de fin de semana", Color("#d92673")],
	"Necesidades_Basicas": ["heart-pulse", "Descanso, comida, higiene y ocio", Color("#d62828")],
	"Progreso": ["trending-up", "Deporte, estudio y manualidades", Color("#1d7afc")],
	"Dormir": ["moon", "+4 Descanso · +1 Salud física/mental", Color("#4f46e5")],
	"Cocinar": ["utensils", "15 min/tupper · 2 €/ciclo · +Cocina", Color("#ea580c")],
	"Comer_Tupper": ["package", "Ración casera · 0 € · Calidad y caducidad", Color("#16a34a")],
	"Comer_Basura": ["utensils-crossed", "2 € cada 5 min · −Salud física", Color("#dc2626")],
	"Comer": ["utensils", "Elige tupper casero o comida rápida", Color("#f59e0b")],
	"Duchar": ["droplet", "+20 Higiene · +1 Salud física/mental", Color("#0ea5e9")],
	"Ver_La_Television": ["tv", "+5 Salud mental · +2 Descanso", Color("#8b5cf6")],
	"Salir_De_Fiesta": ["party-popper", "Noche · 2–12 h · Prob. según estado", Color("#d92673")],
	"Salir_A_Correr": ["footprints", "+4 Deporte · +4 Salud física", Color("#1ea34a")],
	"Carrera_Deportiva": ["trophy", "Fin de semana · Inscripción 50€", Color("#ea580c")],
	"Boton_Carrera_Futbol": ["trophy", "Entrenamientos y liga dominical", Color("#0ea5e9")],
	"Estudiar": ["book-open", "+4 Académico · Avanza carrera", Color("#1d7afc")],
	"Manualidades": ["palette", "+4 Manualidades", Color("#ea580c")],
	"Trabajo": ["briefcase-business", "Elige un empleo fijo semanal", Color("#1ea34a")],
	"Cocinero": ["chef-hat", "Comida rápida, ayudante, partida y chef ejecutivo", Color("#ea580c")],
	"Comida_Rapida": ["utensils-crossed", "10 €/h · L–V 08:00–16:00 · Sin requisitos", Color("#f59e0b")],
	"Carpintero": ["hammer", "18 €/h · L–V 07:00–15:00 · Req: Manualidades 30", Color("#ea580c")],
	"Cientifico": ["flask-conical", "28 €/h · L–V 09:00–17:00 · Ing. Informática", Color("#1d7afc")],
	"Abogado": ["scale", "30 €/h · L–V 09:00–17:00 · Derecho", Color("#7c3aed")],
	"Medico": ["stethoscope", "35 €/h · L–V 09:00–17:00 · Medicina", Color("#d62828")],
	"Artista": ["palette", "25 €/h · L–V 09:00–17:00 · Bellas Artes", Color("#ec4899")],
	"Ayudante_Cocina": ["utensils", "17 €/h · L–V 11:00–19:00 · Cocina 30", Color("#f59e0b")],
	"Cocinero_Partida": ["flame", "24 €/h · L–V 12:00–20:00 · Cocina 60", Color("#ea580c")],
	"Chef_Ejecutivo": ["star", "36 €/h · L–V 13:00–21:00 · Cocina 85", Color("#b91c1c")],
}

const _TRABAJO_A_BOTON := {
	"Trabajar_En_Comida_Rapida": "Comida_Rapida",
	"Trabajar_De_Carpintero": "Carpintero",
	"Trabajar_De_Cientifico": "Cientifico",
	"Trabajar_De_Abogado": "Abogado",
	"Trabajar_De_Medico": "Medico",
	"Trabajar_De_Artista": "Artista",
	"Trabajar_De_Ayudante_Cocina": "Ayudante_Cocina",
	"Trabajar_De_Cocinero_Partida": "Cocinero_Partida",
	"Trabajar_De_Chef_Ejecutivo": "Chef_Ejecutivo",
}


const _SALARIOS_BOTON := {
	"Comida_Rapida": "10 €/h",
	"Carpintero": "18 €/h",
	"Cientifico": "28 €/h",
	"Abogado": "30 €/h",
	"Medico": "35 €/h",
	"Artista": "25 €/h",
	"Ayudante_Cocina": "17 €/h",
	"Cocinero_Partida": "24 €/h",
	"Chef_Ejecutivo": "36 €/h",
}


func _Estilizar_Boton_Actividad(b: Button) -> void:
	var info: Array = Estilos_UI._icono_para(b.name)
	var titulo_txt: String = info[0] if info.size() > 0 and info[0] != "" else b.text
	var extra: Array = _SUBTITULOS_ACTIVIDADES.get(b.name, [info[1] if info.size() > 1 else "circle-check", "", Estilos_UI.ROJO_BIT])
	var ic_nombre: String = extra[0]
	var sub_txt: String = extra[1]
	var badge_col: Color = extra[2] if extra.size() > 2 else Estilos_UI.ROJO_BIT

	b.text = ""
	b.icon = null
	b.custom_minimum_size = Vector2(0, 78)
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	Estilos_UI.aplicar_estilo_boton(b, "tarjeta", badge_col)

	var old := b.get_node_or_null("Card_Contenido")
	if old != null:
		old.queue_free()

	var row := HBoxContainer.new()
	row.name = "Card_Contenido"
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var badge := Estilos_UI.badge_icono(ic_nombre, 44, 21, badge_col, Color.WHITE, 12)
	row.add_child(badge)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)

	var t_lbl := Estilos_UI.titulo(titulo_txt, 17, Estilos_UI.TINTA)
	t_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t_lbl)

	if sub_txt != "":
		var s_lbl := Estilos_UI.texto(sub_txt, 12, Estilos_UI.TINTA_SUAVE, 500)
		s_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s_lbl)

	if _SALARIOS_BOTON.has(b.name):
		var sal_pill := Estilos_UI.pill_estado(_SALARIOS_BOTON[b.name], Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
		sal_pill.name = "Pill_Salario"
		row.add_child(sal_pill)

	var estado_pill := Estilos_UI.pill_estado("Actual", Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL)
	estado_pill.name = "Pill_Actual"
	estado_pill.visible = false
	row.add_child(estado_pill)

	var chev := Estilos_UI.icono_rect("chevron-right", 18, Estilos_UI.TINTA_FANTASMA)
	chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chev)


func _Actualizar_Trabajos_UI() -> void:
	var cont := get_node_or_null("Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Trabajo_Opciones")
	if cont == null:
		return
	var activo_nombre := ""
	if Variables_Dinamicas.Trabajo_Actual != null:
		activo_nombre = _TRABAJO_A_BOTON.get(Variables_Dinamicas.Trabajo_Actual.nombre, "")
	# Recorre también los submenús anidados (Trabajo → Cocinero).
	for b in cont.find_children("*", "Button", true, false):
		var pill := b.get_node_or_null("Card_Contenido/Pill_Actual") as PanelContainer
		if pill != null:
			pill.visible = (b.name == activo_nombre)


func _Redisenar_Actividades() -> void:
	var activ := get_node_or_null("Actividades") as Control
	if activ == null:
		return
	var alto := _Alto_Pantalla()
	activ.position = Vector2.ZERO
	activ.size = Vector2(720, alto)

	var bg := activ.get_node_or_null("Fondo_Seccion") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "Fondo_Seccion"
		bg.color = Estilos_UI.FONDO
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		activ.add_child(bg)
		activ.move_child(bg, 0)
	bg.position = Vector2.ZERO
	bg.size = Vector2(720, alto)
	bg.z_index = -3

	var titulo := activ.get_node_or_null("Titulo_Actividades") as Label
	if titulo == null:
		titulo = Estilos_UI.titulo("Actividades", 24, Estilos_UI.TINTA)
		titulo.name = "Titulo_Actividades"
		activ.add_child(titulo)
	titulo.position = Vector2(20, 124)
	titulo.size = Vector2(560, 34)
	titulo.add_theme_font_override("font", Estilos_UI.fuente_titulo(600))
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Estilos_UI.TINTA)

	var sub := activ.get_node_or_null("Subtitulo_Actividades") as Label
	if sub == null:
		sub = Estilos_UI.texto("Tipo de actividad", 13, Estilos_UI.TINTA_SUAVE, 500)
		sub.name = "Subtitulo_Actividades"
		activ.add_child(sub)
	sub.position = Vector2(20, 158)
	sub.size = Vector2(560, 22)

	var tipos := activ.get_node_or_null("Elegir_Actividad/Tipos_De_Actividades") as VBoxContainer
	if tipos != null:
		var esp_opc := tipos.get_node_or_null("Especiales_Opciones")
		if esp_opc != null:
			var btn_cd := esp_opc.get_node_or_null("Carrera_Deportiva") as Button
			if btn_cd == null:
				btn_cd = Button.new()
				btn_cd.name = "Carrera_Deportiva"
				btn_cd.text = "Carrera deportiva"
				esp_opc.add_child(btn_cd)
			if not btn_cd.pressed.is_connected(_on_carrera_deportiva_pressed):
				btn_cd.pressed.connect(_on_carrera_deportiva_pressed)
		tipos.position = Vector2(20, 194)
		tipos.size = Vector2(680, 960)
		tipos.add_theme_constant_override("separation", 10)
		for cont_v in tipos.find_children("*", "VBoxContainer", true, false):
			cont_v.add_theme_constant_override("separation", 10)
		for b in tipos.find_children("*", "Button", true, false):
			_Estilizar_Boton_Actividad(b)

	var atras := activ.get_node_or_null("Elegir_Actividad/Flecha_Atras") as Button
	if atras != null:
		# La escena antigua definía el botón a 100×100: hay que soltar ese mínimo
		# para que quepa en la cabecera y no invada el subtítulo.
		atras.custom_minimum_size = Vector2(42, 42)
		atras.position = Vector2(20, 128)
		atras.size = Vector2(42, 42)
		atras.rotation = 0.0

	_Actualizar_Trabajos_UI()
	_Actualizar_Boton_Carrera_Deportiva()
	_Actualizar_Boton_Carrera_Futbol()


func _Actualizar_Boton_Carrera_Deportiva() -> void:
	var btn := get_node_or_null("Actividades/Elegir_Actividad/Tipos_De_Actividades/Especiales_Opciones/Carrera_Deportiva") as Button
	if btn == null:
		return
	var sys := Sistema_Carreras_Deportivas
	if sys == null:
		return
	var pendiente: Dictionary = Variables_Dinamicas.Carrera_Deportiva_Pendiente
	var inscrito: bool = pendiente.get("inscrito", false)
	var puede_hoy: bool = sys.Puede_Inscribirse_Hoy()
	var card_row := btn.get_node_or_null("Card_Contenido")
	var sub_lbl: Label = null
	if card_row != null and card_row.get_child_count() > 1:
		var vbox := card_row.get_child(1)
		if vbox.get_child_count() > 1:
			sub_lbl = vbox.get_child(1) as Label
	if inscrito:
		var dia_txt: String = "Sábado" if int(pendiente.get("dia", 5)) == 5 else "Domingo"
		var h_min: int = int(pendiente.get("hora_inicio", 540))
		var h_str: String = "%02d:%02d" % [h_min / 60, h_min % 60]
		btn.disabled = true
		if sub_lbl != null:
			sub_lbl.text = "Carrera inscrita: %s %s" % [dia_txt, h_str]
	elif not puede_hoy:
		btn.disabled = true
		if sub_lbl != null:
			sub_lbl.text = "Inscripción cerrada en fin de semana (L–V)"
	else:
		btn.disabled = false
		if sub_lbl != null:
			var costo: int = int(sys.Obtener_Costo_Inscripcion())
			var visibles: int = sys.Calcular_Inscritos_Visibles()
			sub_lbl.text = "Fin de semana · %d€ · %d inscritos" % [costo, visibles]


# ---------------- Carrera de futbolista ----------------

func _Actualizar_Boton_Carrera_Futbol() -> void:
	var btn := get_node_or_null(
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Boton_Carrera_Futbol") as Button
	if btn == null:
		return
	var sub_lbl: Label = null
	var card_row := btn.get_node_or_null("Card_Contenido")
	if card_row != null and card_row.get_child_count() > 1:
		var vbox := card_row.get_child(1)
		if vbox.get_child_count() > 1:
			sub_lbl = vbox.get_child(1) as Label
	if sub_lbl == null:
		return
	if Sistema_Futbol.Carrera_Activa():
		var salario_txt: String = "%d €/sem" % Sistema_Futbol.Obtener_Salario_Semanal()
		if Variables_Estaticas.Modo_Rapido:
			salario_txt = "%d €/día" % int(round(
				Sistema_Futbol.Obtener_Salario_Semanal() * Variables_Estaticas.Multiplicador_Precios()))
		sub_lbl.text = "%s · %s · %s" % [
			Sistema_Futbol.Obtener_Nombre_Division(),
			salario_txt,
			Sistema_Futbol.Obtener_Resumen_Entrenamiento()]
	else:
		var req: Dictionary = Sistema_Futbol.Cumple_Requisitos_Fichaje()
		if bool(req.get("cumple", false)):
			sub_lbl.text = "Sin club · Cumples los requisitos (Deporte %d)" % int(
				req.get("deporte", 0))
		else:
			sub_lbl.text = "Sin club · Necesitas Deporte %d y menos de %d años" % [
				int(req.get("requisito_deporte", 25)), int(req.get("requisito_edad", 30))]


func _on_carrera_futbol_pressed() -> void:
	_Cerrar_Panel_Futbol()
	# El panel debe colgar de un CanvasLayer: un Control anclado directamente a
	# un Node2D calcula su rect contra un padre de tamaño cero y queda en 0x0.
	_capa_panel_futbol = CanvasLayer.new()
	_capa_panel_futbol.name = "Capa_Panel_Futbol"
	_capa_panel_futbol.layer = 60
	add_child(_capa_panel_futbol)
	_panel_futbol = _PANEL_FUTBOL_ESCENA.instantiate()
	_capa_panel_futbol.add_child(_panel_futbol)
	_panel_futbol.cerrado.connect(_on_panel_futbol_cerrado)


func _Cerrar_Panel_Futbol() -> void:
	_panel_futbol = null
	if _capa_panel_futbol != null and is_instance_valid(_capa_panel_futbol):
		_capa_panel_futbol.queue_free()
		_capa_panel_futbol = null


func _on_panel_futbol_cerrado() -> void:
	_Cerrar_Panel_Futbol()
	_on_boton_actividades_pressed()
	Opciones_Actividades_Fijas()


func _Comprobar_Conflicto_Ascenso_Futbol() -> void:
	if not Sistema_Futbol.Hay_Conflicto_Ascenso_Pendiente():
		_conflicto_ascenso_mostrado = false
		if _dialogo_ascenso_futbol != null and _dialogo_ascenso_futbol.visible:
			_dialogo_ascenso_futbol.hide()
		return
	if _conflicto_ascenso_mostrado:
		return
	_conflicto_ascenso_mostrado = true
	var datos: Dictionary = Sistema_Futbol.Obtener_Datos_Conflicto_Ascenso()
	if _dialogo_ascenso_futbol == null:
		_dialogo_ascenso_futbol = ConfirmationDialog.new()
		_dialogo_ascenso_futbol.title = "Conflicto de horario"
		_dialogo_ascenso_futbol.ok_button_text = "Seguir con el fútbol"
		_dialogo_ascenso_futbol.get_cancel_button().text = "Mantener trabajo"
		_dialogo_ascenso_futbol.confirmed.connect(_on_ascenso_futbol_confirmado)
		_dialogo_ascenso_futbol.canceled.connect(_on_ascenso_futbol_cancelado)
		_dialogo_ascenso_futbol.close_requested.connect(_on_ascenso_futbol_cancelado)
		add_child(_dialogo_ascenso_futbol)
	_dialogo_ascenso_futbol.dialog_text = (
		"El ascenso a %s cambia los entrenamientos a un horario que solapa con tu trabajo de %s.\n\n" \
		+ "Puedes seguir con el fútbol (dejarás el empleo) o mantener el trabajo (rechazarás el ascenso).") % [
			str(datos.get("nombre_destino", "")), str(datos.get("trabajo", "tu empleo"))]
	_dialogo_ascenso_futbol.popup_centered(Vector2i(600, 300))


func _on_ascenso_futbol_confirmado() -> void:
	if not Sistema_Futbol.Hay_Conflicto_Ascenso_Pendiente():
		return
	_conflicto_ascenso_mostrado = false
	Sistema_Futbol.Resolver_Conflicto_Ascenso(true)
	_Actualizar_Trabajos_UI()
	_Actualizar_Boton_Carrera_Futbol()
	Actualizar_Dinero()
	_Refrescar_Panel_Futbol_Si_Abierto()


func _on_ascenso_futbol_cancelado() -> void:
	if not Sistema_Futbol.Hay_Conflicto_Ascenso_Pendiente():
		return
	_conflicto_ascenso_mostrado = false
	Sistema_Futbol.Resolver_Conflicto_Ascenso(false)
	_Actualizar_Boton_Carrera_Futbol()
	_Refrescar_Panel_Futbol_Si_Abierto()


func _Refrescar_Panel_Futbol_Si_Abierto() -> void:
	if _panel_futbol != null and is_instance_valid(_panel_futbol):
		_panel_futbol.Refrescar()


func _Mostrar_Conflicto_Futbol_Trabajo(actividad: Actividad_Fija_Trabajo) -> void:
	_trabajo_conflicto_futbol = actividad
	if _dialogo_futbol_trabajo == null:
		_dialogo_futbol_trabajo = ConfirmationDialog.new()
		_dialogo_futbol_trabajo.title = "Fútbol o trabajo"
		_dialogo_futbol_trabajo.ok_button_text = "Dejar el fútbol y trabajar"
		_dialogo_futbol_trabajo.get_cancel_button().text = "Seguir en el fútbol"
		_dialogo_futbol_trabajo.confirmed.connect(_on_conflicto_futbol_trabajo_confirmado)
		_dialogo_futbol_trabajo.canceled.connect(_on_conflicto_futbol_trabajo_cancelado)
		_dialogo_futbol_trabajo.close_requested.connect(_on_conflicto_futbol_trabajo_cancelado)
		add_child(_dialogo_futbol_trabajo)
	var nombre := actividad.nombre.replace("Trabajar_En_", "").replace(
		"Trabajar_De_", "").replace("_", " ")
	_dialogo_futbol_trabajo.dialog_text = (
		"El horario de %s solapa con tus compromisos de fútbol (entrenamientos o partidos).\n\n" \
		+ "Si aceptas el empleo, rescindirás tu contrato como futbolista.") % nombre
	_dialogo_futbol_trabajo.popup_centered(Vector2i(580, 280))


func _on_conflicto_futbol_trabajo_confirmado() -> void:
	if _trabajo_conflicto_futbol == null:
		return
	var actividad: Actividad_Fija_Trabajo = _trabajo_conflicto_futbol
	_trabajo_conflicto_futbol = null
	Sistema_Futbol.Rescindir_Por_Trabajo()
	if actividad != null:
		_Tomar_Trabajo(actividad)


func _on_conflicto_futbol_trabajo_cancelado() -> void:
	_trabajo_conflicto_futbol = null


func _on_carrera_deportiva_pressed() -> void:
	var sys := Sistema_Carreras_Deportivas
	if sys == null or not sys.Puede_Inscribirse_Hoy():
		return
	if Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("inscrito", false):
		return
	var modal := _MODAL_CARRERA_DEPORTIVA_SCRIPT.new()
	add_child(modal)
	modal.inscripcion_confirmada.connect(_on_inscripcion_carrera_deportiva_confirmada)
	modal.popup_centered()


func _on_inscripcion_carrera_deportiva_confirmada(dia: int, hora_inicio: int) -> void:
	var sys := Sistema_Carreras_Deportivas
	if sys != null and sys.Inscribirse_Carrera(dia, hora_inicio):
		Actualizar_Dinero()
		_Actualizar_Boton_Carrera_Deportiva()


func _Redisenar_Horario() -> void:
	var horario := get_node_or_null("Actividades/Horario_Semanal") as Control
	if horario == null:
		return
	horario.position = Vector2.ZERO
	horario.size = Vector2(720, _Alto_Pantalla())

	var btn_volver := horario.get_node_or_null("Boton_Volver_Horario") as Button
	if btn_volver == null:
		btn_volver = Estilos_UI.boton_icono("arrow-left", Estilos_UI.TINTA, 42)
		btn_volver.name = "Boton_Volver_Horario"
		btn_volver.position = Vector2(20, 126)
		btn_volver.size = Vector2(42, 42)
		btn_volver.tooltip_text = "Volver a actividades"
		btn_volver.pressed.connect(_on_boton_actividades_pressed)
		horario.add_child(btn_volver)

	var badge_hdr := horario.get_node_or_null("Badge_Horario_Header") as PanelContainer
	if badge_hdr == null:
		badge_hdr = Estilos_UI.badge_icono("calendar-days", 42, 21, Estilos_UI.AZUL, Color.WHITE, 12)
		badge_hdr.name = "Badge_Horario_Header"
		badge_hdr.position = Vector2(20, 126)
		badge_hdr.size = Vector2(42, 42)
		horario.add_child(badge_hdr)

	var btn_hoy := horario.get_node_or_null("Boton_Ir_Hoy") as Button
	if btn_hoy == null:
		btn_hoy = Estilos_UI.boton("Ir a hoy", "suave", "calendar-check-2", Estilos_UI.PRIMARIO, 38)
		btn_hoy.name = "Boton_Ir_Hoy"
		btn_hoy.set_meta("_estilo_propio", true)
		btn_hoy.add_theme_font_size_override("font_size", 13)
		btn_hoy.pressed.connect(_Ir_A_Semana_Actual)
		horario.add_child(btn_hoy)
	btn_hoy.position = Vector2(564, 128)
	btn_hoy.size = Vector2(136, 38)

	var fondo_cal := horario.get_node_or_null("Fondo_Calendario") as Panel
	if fondo_cal == null:
		fondo_cal = Panel.new()
		fondo_cal.name = "Fondo_Calendario"
		fondo_cal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(fondo_cal)
		horario.move_child(fondo_cal, 0)
	fondo_cal.position = Vector2(16, 186)
	fondo_cal.size = Vector2(688, 722)
	fondo_cal.z_index = -1
	fondo_cal.clip_contents = true
	fondo_cal.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE_FUERTE, 1, 2))

	var fondo_cab := horario.get_node_or_null("Fondo_Cabecera_Calendario") as Panel
	if fondo_cab == null:
		fondo_cab = Panel.new()
		fondo_cab.name = "Fondo_Cabecera_Calendario"
		fondo_cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(fondo_cab)
		horario.move_child(fondo_cab, 1)
	fondo_cab.position = Vector2(17, 187)
	fondo_cab.size = Vector2(686, 44)
	var st_cab := StyleBoxFlat.new()
	st_cab.bg_color = Estilos_UI.NAVY
	st_cab.corner_radius_top_left = 15
	st_cab.corner_radius_top_right = 15
	st_cab.border_width_bottom = 2
	st_cab.border_color = Color("#2d3a50")
	fondo_cab.add_theme_stylebox_override("panel", st_cab)

	var cabecera := horario.get_node_or_null("Cabezal_horario") as HBoxContainer
	if cabecera != null:
		cabecera.position = Vector2(22, 191)
		cabecera.size = Vector2(676, 36)
		cabecera.custom_minimum_size = Vector2(676, 36)
		cabecera.add_theme_constant_override("separation", 0)
		for b in cabecera.get_children():
			if b is Button:
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.focus_mode = Control.FOCUS_NONE
				if b.name == "Horario":
					b.custom_minimum_size = Vector2(68, 36)
					b.size_flags_horizontal = 0
				else:
					b.custom_minimum_size = Vector2(0, 36)
					b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var mover := horario.get_node_or_null("Mover_Vertical") as ScrollContainer
	if mover != null:
		mover.position = Vector2(22, 233)
		mover.size = Vector2(676, 634)
		mover.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var todo := horario.get_node_or_null("Mover_Vertical/Todo calendario") as HBoxContainer
	if todo != null:
		todo.add_theme_constant_override("separation", 0)
	var col_horas := horario.get_node_or_null("Mover_Vertical/Todo calendario/Horario") as VBoxContainer
	if col_horas != null:
		col_horas.custom_minimum_size = Vector2(68, 0)
		col_horas.add_theme_constant_override("separation", 0)
	var dias := horario.get_node_or_null("Mover_Vertical/Todo calendario/Dias") as HBoxContainer
	if dias != null:
		dias.add_theme_constant_override("separation", 0)
		for d in dias.get_children():
			if d is VBoxContainer:
				d.custom_minimum_size.x = 0
				d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				d.add_theme_constant_override("separation", 0)

	var sep_pie := horario.get_node_or_null("Separador_Pie_Calendario") as ColorRect
	if sep_pie == null:
		sep_pie = ColorRect.new()
		sep_pie.name = "Separador_Pie_Calendario"
		sep_pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(sep_pie)
	sep_pie.color = Color("#e2e8f0")
	sep_pie.position = Vector2(17, 870)
	sep_pie.size = Vector2(686, 1)

	# Leyenda dentro del pie del calendario
	var leyenda := horario.get_node_or_null("Leyenda_Horario") as HBoxContainer
	if leyenda == null:
		leyenda = HBoxContainer.new()
		leyenda.name = "Leyenda_Horario"
		leyenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(leyenda)
	leyenda.position = Vector2(28, 876)
	leyenda.size = Vector2(664, 24)
	leyenda.add_theme_constant_override("separation", 18)
	for hijo in leyenda.get_children():
		hijo.queue_free()
	for datos in [
		["Libre", Color("#dcfce7"), Color("#4ade80")],
		["Programado", Color("#dbeafe"), Color("#2563eb")],
		["Pasado", Color("#e2e8f0"), Color("#94a3b8")],
	]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var punto := Panel.new()
		punto.custom_minimum_size = Vector2(12, 12)
		punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		punto.add_theme_stylebox_override("panel",
			Estilos_UI.caja(datos[1], 4, datos[2], 1, 0))
		item.add_child(punto)
		item.add_child(Estilos_UI.texto(datos[0], 11, Estilos_UI.TINTA_SUAVE, 600))
		leyenda.add_child(item)

	var spacer_ley := Control.new()
	spacer_ley.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer_ley.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leyenda.add_child(spacer_ley)
	leyenda.add_child(Estilos_UI.texto("Toca un bloque para ver detalles", 11, Estilos_UI.TINTA_FANTASMA, 500))

	# Tarjeta de detalles y acción del bloque seleccionado
	var panel_sel := horario.get_node_or_null("Panel_Seleccion_Horario") as Panel
	if panel_sel == null:
		panel_sel = Panel.new()
		panel_sel.name = "Panel_Seleccion_Horario"
		panel_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(panel_sel)
	panel_sel.position = Vector2(16, 916)
	panel_sel.size = Vector2(688, 152)
	panel_sel.z_index = -1

	var pill_sel := horario.get_node_or_null("Pill_Estado_Seleccion") as PanelContainer
	if pill_sel == null:
		pill_sel = Estilos_UI.pill_estado("SIN SELECCIÓN", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_FANTASMA)
		pill_sel.name = "Pill_Estado_Seleccion"
		horario.add_child(pill_sel)
	pill_sel.position = Vector2(34, 928)

	var hint_sel := horario.get_node_or_null("Hint_Seleccion_Label") as Label
	if hint_sel == null:
		hint_sel = Estilos_UI.texto("", 12, Estilos_UI.TINTA_FANTASMA, 500)
		hint_sel.name = "Hint_Seleccion_Label"
		hint_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(hint_sel)
	hint_sel.position = Vector2(34, 1004)
	hint_sel.size = Vector2(652, 42)

	# Tarjeta central para etiqueta de semana en la barra de navegación semanal
	var panel_sem := horario.get_node_or_null("Panel_Semana_Nav") as Panel
	if panel_sem == null:
		panel_sem = Panel.new()
		panel_sem.name = "Panel_Semana_Nav"
		panel_sem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(panel_sem)
	panel_sem.position = Vector2(236, 1082)
	panel_sem.size = Vector2(248, 46)
	panel_sem.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 11, Estilos_UI.BORDE, 1, 1))

	var semana := horario.get_node_or_null("Semana_Label") as Label
	if semana == null:
		semana = Label.new()
		semana.name = "Semana_Label"
		semana.mouse_filter = Control.MOUSE_FILTER_IGNORE
		horario.add_child(semana)
	semana.position = Vector2(236, 1082)
	semana.size = Vector2(248, 46)
	semana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	semana.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	semana.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	semana.add_theme_font_size_override("font_size", 14)
	semana.add_theme_color_override("font_color", Estilos_UI.TINTA)
	semana.text = "Semana %d" % int(mirar_semana)

	var opciones := horario.get_node_or_null("OPCIONES_CALENDARIO") as Control
	if opciones != null:
		opciones.mouse_filter = Control.MOUSE_FILTER_IGNORE
		opciones.size = Vector2(720, 1140)
		var texto := opciones.get_node_or_null("Actividad_Texto") as Label
		if texto != null:
			texto.position = Vector2(34, 958)
			texto.size = Vector2(652, 30)
			texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			texto.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			texto.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
			texto.add_theme_font_size_override("font_size", 15)
			texto.add_theme_color_override("font_color", Estilos_UI.TINTA)
		var btn_ocupar := opciones.get_node_or_null("OCUPAR_ACTIVIDAD") as Button
		if btn_ocupar != null:
			btn_ocupar.position = Vector2(34, 998)
			btn_ocupar.size = Vector2(652, 52)
			btn_ocupar.text = "Elegir actividad"
			Estilos_UI.aplicar_estilo_boton(btn_ocupar, "exito", Estilos_UI.EXITO, "clipboard-list")
		var btn_elim := opciones.get_node_or_null("ELIMINAR_ACTIVIDAD") as Button
		if btn_elim != null:
			btn_elim.position = Vector2(34, 998)
			btn_elim.size = Vector2(652, 52)
			btn_elim.text = "Eliminar actividad"
			Estilos_UI.aplicar_estilo_boton(btn_elim, "peligro", Estilos_UI.PELIGRO, "x")
		var ant := opciones.get_node_or_null("ANTERIOR SEMANA") as Button
		if ant != null:
			ant.position = Vector2(16, 1082)
			ant.size = Vector2(210, 46)
			ant.text = "Anterior"
			ant.icon = Estilos_UI.icono("chevron-left")
			ant.add_theme_constant_override("icon_max_width", 18)
		var sig := opciones.get_node_or_null("SIGUIENTE SEMANA") as Button
		if sig != null:
			sig.position = Vector2(494, 1082)
			sig.size = Vector2(210, 46)
			sig.text = "Siguiente"
			sig.icon = Estilos_UI.icono("chevron-right")
			sig.add_theme_constant_override("icon_max_width", 18)

	# Atajo inferior para regresar a la semana en la que vive el Sim.
	var btn_sem_actual := horario.get_node_or_null("Boton_Semana_Actual_Inferior") as Button
	if btn_sem_actual == null:
		btn_sem_actual = Estilos_UI.boton("Volver a la semana actual", "suave", "calendar-check-2", Estilos_UI.AZUL, 38)
		btn_sem_actual.name = "Boton_Semana_Actual_Inferior"
		btn_sem_actual.set_meta("_estilo_propio", true)
		btn_sem_actual.add_theme_font_size_override("font_size", 13)
		btn_sem_actual.tooltip_text = "Vuelve a la semana en la que está viviendo tu Sim"
		btn_sem_actual.add_theme_stylebox_override("disabled",
			Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, Estilos_UI.RADIO_BOTON, Estilos_UI.BORDE, 1, 0))
		btn_sem_actual.add_theme_color_override("font_disabled_color", Estilos_UI.TINTA_FANTASMA)
		btn_sem_actual.add_theme_color_override("icon_disabled_color", Estilos_UI.TINTA_FANTASMA)
		btn_sem_actual.pressed.connect(_Ir_A_Semana_Actual)
		horario.add_child(btn_sem_actual)
	btn_sem_actual.position = Vector2(16, 1138)
	btn_sem_actual.size = Vector2(688, 38)

	_Limpiar_Seleccion_Calendario_UI()
	_Actualizar_Cabecera_Dias_Horario()


func _Actualizar_Cabecera_Dias_Horario() -> void:
	var cabecera := get_node_or_null("Actividades/Horario_Semanal/Cabezal_horario") as HBoxContainer
	if cabecera == null:
		return
	var nombres := ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"]
	var semana_actual: int = int(Variables_Dinamicas.Minute_Day) / 7
	var hoy: int = int(Variables_Dinamicas.Minute_Day) % 7
	var es_semana_actual: bool = (int(mirar_semana) == semana_actual)

	for b in cabecera.get_children():
		if b is Button:
			if b.name == "Horario":
				b.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
				b.add_theme_font_size_override("font_size", 11)
				b.add_theme_color_override("font_color", Color("#94a3b8"))
				var st_h := Estilos_UI.caja(Color(0, 0, 0, 0), 6, Color(0, 0, 0, 0), 0, 0)
				b.add_theme_stylebox_override("normal", st_h)
				b.add_theme_stylebox_override("hover", st_h)
			else:
				var idx_d: int = nombres.find(b.name)
				var es_hoy: bool = es_semana_actual and (idx_d == hoy)
				var es_finde: bool = idx_d >= 5
				b.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
				b.add_theme_font_size_override("font_size", 13 if es_hoy else 12)
				var col_txt := Color.WHITE if es_hoy else (Color("#cbd5e1") if es_finde else Color("#f8fafc"))
				b.add_theme_color_override("font_color", col_txt)
				var st_d := Estilos_UI.caja(
					Estilos_UI.ROJO_BIT if es_hoy else Color(0, 0, 0, 0),
					8,
					Estilos_UI.ROJO_BIT_OSCURO if es_hoy else Color(0, 0, 0, 0),
					1 if es_hoy else 0,
					0)
				b.add_theme_stylebox_override("normal", st_d)
				b.add_theme_stylebox_override("hover", st_d)


func _Limpiar_Seleccion_Calendario_UI() -> void:
	var btn_ocupar := get_node_or_null("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/OCUPAR_ACTIVIDAD") as Button
	if btn_ocupar != null:
		btn_ocupar.visible = false
	var btn_elim := get_node_or_null("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ELIMINAR_ACTIVIDAD") as Button
	if btn_elim != null:
		btn_elim.visible = false
	var texto := get_node_or_null("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/Actividad_Texto") as Label
	if texto != null:
		texto.text = "Ningún bloque seleccionado"
	_Actualizar_Panel_Seleccion_Horario("", "")


func _Actualizar_Panel_Seleccion_Horario(estado: String, _texto_sel: String) -> void:
	var horario := get_node_or_null("Actividades/Horario_Semanal") as Control
	if horario == null:
		return
	var panel_sel := horario.get_node_or_null("Panel_Seleccion_Horario") as Panel
	var pill_sel := horario.get_node_or_null("Pill_Estado_Seleccion") as PanelContainer
	var hint_sel := horario.get_node_or_null("Hint_Seleccion_Label") as Label
	var texto := horario.get_node_or_null("OPCIONES_CALENDARIO/Actividad_Texto") as Label

	var col_borde := Estilos_UI.BORDE
	var ancho_izq := 1
	var txt_pill := "SIN SELECCIÓN"
	var bg_pill := Color("#f1f5f9")
	var fg_pill := Estilos_UI.TINTA_FANTASMA
	var txt_hint := "Toca una franja verde (libre) o de color (ocupada) en el calendario."

	if estado == "libre":
		col_borde = Estilos_UI.EXITO
		ancho_izq = 4
		txt_pill = "FRANJA DISPONIBLE"
		bg_pill = Estilos_UI.EXITO_SUAVE
		fg_pill = Estilos_UI.EXITO_OSCURO
		txt_hint = "Modo consulta: programa desde Actividades o desde Inicio → Horario." if calendario_solo_lectura else "Pulsa «Elegir actividad» y después ajusta el horario."
	elif estado == "ocupado":
		col_borde = Estilos_UI.AZUL
		ancho_izq = 4
		txt_pill = "ACTIVIDAD PROGRAMADA"
		bg_pill = Estilos_UI.AZUL_SUAVE
		fg_pill = Estilos_UI.AZUL
		txt_hint = ""
	elif estado == "pasado":
		col_borde = Color("#64748b")
		ancho_izq = 4
		txt_pill = "BLOQUE PASADO"
		bg_pill = Color("#e2e8f0")
		fg_pill = Color("#475569")
		txt_hint = "Este periodo ya ha transcurrido y no se puede modificar."

	if panel_sel != null:
		var st_p := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 1)
		st_p.border_width_left = ancho_izq
		if ancho_izq > 1:
			st_p.border_color = col_borde.lerp(Estilos_UI.BORDE, 0.35)
		panel_sel.add_theme_stylebox_override("panel", st_p)

	if pill_sel != null:
		_Actualizar_Badge_Pill(pill_sel, txt_pill, bg_pill, fg_pill)

	if texto != null:
		texto.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE if estado == "" else Estilos_UI.TINTA)

	if hint_sel != null:
		hint_sel.text = txt_hint
		hint_sel.visible = (txt_hint != "")


func _Redisenar_Seleccionar_Horario() -> void:
	var sel := get_node_or_null("Actividades/Seleccionar_Horario") as Control
	if sel == null:
		return
	sel.position = Vector2.ZERO
	sel.size = Vector2(720, _Alto_Pantalla())

	var badge_sel := sel.get_node_or_null("Badge_Seleccionar_Header") as PanelContainer
	if badge_sel == null:
		badge_sel = Estilos_UI.badge_icono("clock", 42, 21, Estilos_UI.AZUL, Color.WHITE, 12)
		badge_sel.name = "Badge_Seleccionar_Header"
		sel.add_child(badge_sel)
	badge_sel.position = Vector2(16, 124)
	badge_sel.size = Vector2(42, 42)

	var titulo := sel.get_node_or_null("Titulo") as Label
	if titulo != null:
		titulo.position = Vector2(68, 120)
		titulo.size = Vector2(390, 28)
		titulo.text = "Elegir horario"
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		titulo.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
		titulo.add_theme_font_size_override("font_size", 22)
		titulo.add_theme_color_override("font_color", Estilos_UI.TINTA)

	var sub_disp := sel.get_node_or_null("Subtitulo_Disponible") as Label
	if sub_disp == null:
		sub_disp = Estilos_UI.texto("Ajusta el inicio y el final de tu actividad", 12, Estilos_UI.TINTA_SUAVE, 600)
		sub_disp.name = "Subtitulo_Disponible"
		sub_disp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sel.add_child(sub_disp)
	sub_disp.position = Vector2(68, 148)
	sub_disp.size = Vector2(400, 20)

	var pill_dur := sel.get_node_or_null("Pill_Duracion_Seleccion") as PanelContainer
	if pill_dur == null:
		pill_dur = PanelContainer.new()
		pill_dur.name = "Pill_Duracion_Seleccion"
		pill_dur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_pd := Estilos_UI.caja(Color("#dbeafe"), 999, Color("#93c5fd"), 1, 0)
		st_pd.content_margin_left = 14
		st_pd.content_margin_right = 14
		st_pd.content_margin_top = 6
		st_pd.content_margin_bottom = 6
		pill_dur.add_theme_stylebox_override("panel", st_pd)
		var lbl_pd := Estilos_UI.texto("⏱  Duración: --", 13, Color("#1d4ed8"), 700)
		lbl_pd.name = "Duracion_Label"
		lbl_pd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pill_dur.add_child(lbl_pd)
		sel.add_child(pill_dur)
	pill_dur.position = Vector2(484, 126)
	pill_dur.size = Vector2(220, 36)

	var bloques := [
		["Inicio", 772.0, "Inicio_Texto", "Inicio_Hbox", "DESDE · HORA DE INICIO", "Resumen_Inicio_Label",
		 Color("#2563eb"), Color("#eff6ff"), Color("#3b82f6"), Color("#1e3a8a"), Color("#dbeafe")],
		["Final", 904.0, "Final_Texto", "Final_Hbox", "HASTA · HORA FINAL", "Resumen_Final_Label",
		 Color("#4f46e5"), Color("#eef2ff"), Color("#6366f1"), Color("#312e81"), Color("#e0e7ff")],
	]
	for cfg in bloques:
		var panel := sel.get_node_or_null(cfg[0]) as Panel
		if panel == null:
			continue
		var col_acento: Color = cfg[6]
		var col_val_bg: Color = cfg[7]
		var col_val_borde: Color = cfg[8]
		var col_val_txt: Color = cfg[9]
		var col_press_bg: Color = cfg[10]

		panel.position = Vector2(16, cfg[1])
		panel.size = Vector2(688, 120)
		var st_card := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, col_val_borde.lerp(Estilos_UI.BORDE, 0.55), 1, 2)
		st_card.border_width_left = 5
		st_card.border_color = col_acento
		panel.add_theme_stylebox_override("panel", st_card)

		var lbl := panel.get_node_or_null(cfg[2]) as Label
		if lbl != null:
			lbl.position = Vector2(18, 7)
			lbl.size = Vector2(330, 20)
			lbl.text = cfg[4]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", col_acento)

		var lbl_res := panel.get_node_or_null(cfg[5]) as Label
		if lbl_res == null:
			lbl_res = Estilos_UI.texto("", 13, col_val_txt, 700)
			lbl_res.name = cfg[5]
			lbl_res.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(lbl_res)
		lbl_res.position = Vector2(360, 7)
		lbl_res.size = Vector2(310, 20)
		lbl_res.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var style_step_n := Estilos_UI.caja(Color("#f1f5f9"), 7, Color("#e2e8f0"), 1, 0)
		var style_step_h := Estilos_UI.caja(Color("#e2e8f0"), 7, col_val_borde, 1, 0)
		var style_step_p := Estilos_UI.caja(col_press_bg, 7, col_acento, 1, 0)
		var style_val := Estilos_UI.caja(col_val_bg, 9, col_val_borde, 2, 0)

		var hbox := panel.get_node_or_null(cfg[3]) as HBoxContainer
		if hbox != null:
			hbox.position = Vector2(18, 30)
			hbox.size = Vector2(652, 82)
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 14)
			for child in hbox.get_children():
				if child is Label:
					child.add_theme_color_override("font_color", col_acento)
					child.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
					child.add_theme_font_size_override("font_size", 20)
				elif child is VBoxContainer:
					child.custom_minimum_size = Vector2(164, 0)
					child.add_theme_constant_override("separation", 2)
					for btn_w in child.get_children():
						if btn_w is Button:
							btn_w.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
							if btn_w.name in ["Boton_Arriba", "Boton_Abajo"]:
								btn_w.custom_minimum_size = Vector2(0, 21)
								btn_w.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
								btn_w.add_theme_font_size_override("font_size", 11)
								btn_w.add_theme_color_override("font_color", Color("#475569"))
								btn_w.add_theme_color_override("font_hover_color", col_acento)
								btn_w.add_theme_color_override("font_pressed_color", col_val_txt)
								btn_w.add_theme_stylebox_override("normal", style_step_n)
								btn_w.add_theme_stylebox_override("hover", style_step_h)
								btn_w.add_theme_stylebox_override("pressed", style_step_p)
								btn_w.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
							else:
								btn_w.custom_minimum_size = Vector2(0, 34)
								btn_w.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
								btn_w.add_theme_font_size_override("font_size", 19)
								btn_w.add_theme_color_override("font_color", col_val_txt)
								btn_w.add_theme_color_override("font_hover_color", col_val_txt)
								btn_w.add_theme_color_override("font_pressed_color", col_val_txt)
								btn_w.add_theme_stylebox_override("normal", style_val)
								btn_w.add_theme_stylebox_override("hover", style_val)
								btn_w.add_theme_stylebox_override("pressed", style_val)

	var btn_cancel := sel.get_node_or_null("Cancelar") as Button
	if btn_cancel != null:
		btn_cancel.position = Vector2(16, 1044)
		btn_cancel.size = Vector2(334, 52)
		Estilos_UI.aplicar_estilo_boton(btn_cancel, "secundario", Estilos_UI.TINTA, "arrow-left")
	var btn_crear := sel.get_node_or_null("Crear_Actividad") as Button
	if btn_crear != null:
		btn_crear.position = Vector2(370, 1044)
		btn_crear.size = Vector2(334, 52)
		Estilos_UI.aplicar_estilo_boton(btn_crear, "exito", Estilos_UI.EXITO, "check")


func _Actualizar_Titulo_Horario() -> void:
	var titulo := get_node_or_null("Actividades/Titulo_Actividades") as Label
	var sub := get_node_or_null("Actividades/Subtitulo_Actividades") as Label
	var btn_volver := get_node_or_null("Actividades/Horario_Semanal/Boton_Volver_Horario") as Button
	var badge_hdr := get_node_or_null("Actividades/Horario_Semanal/Badge_Horario_Header") as PanelContainer
	if btn_volver != null:
		btn_volver.visible = not calendario_solo_lectura
	if badge_hdr != null:
		badge_hdr.visible = calendario_solo_lectura
	var edad_sem: int = Variables_Estaticas.Calcular_Edad(int(mirar_semana) * 7)
	var sem_actual: int = int(Variables_Dinamicas.Minute_Day) / 7
	var sufijo_sem: String = " · Semana actual" if int(mirar_semana) == sem_actual else ""
	if titulo != null:
		titulo.position.x = 74
		titulo.text = "Horario semanal"
	if sub != null:
		sub.position.x = 74
		sub.text = "Semana %d · %d años%s" % [int(mirar_semana), max(18, edad_sem), sufijo_sem]
	var semana := get_node_or_null("Actividades/Horario_Semanal/Semana_Label") as Label
	if semana != null:
		semana.text = "Semana %d · %d años" % [int(mirar_semana), max(18, edad_sem)]
	_Actualizar_Cabecera_Dias_Horario()


func _Mostrar_Titulo_Actividades() -> void:
	var titulo := get_node_or_null("Actividades/Titulo_Actividades") as Label
	var sub := get_node_or_null("Actividades/Subtitulo_Actividades") as Label
	if titulo != null:
		titulo.text = "Actividades"
	if sub != null:
		sub.text = "Tipo de actividad"


func _Redisenar_Perfil() -> void:
	var p := get_node_or_null("Pantalla_Mensajes") as Control
	if p == null:
		return
	var alto := _Alto_Pantalla()
	var alto_contenido := alto - 358.0
	p.position = Vector2.ZERO
	p.size = Vector2(720, alto)

	var fondo := p.get_node_or_null("Fondo_Mensajes") as ColorRect
	if fondo != null:
		fondo.color = Estilos_UI.FONDO
		fondo.position = Vector2.ZERO
		fondo.size = Vector2(720, alto)
		fondo.z_index = -3

	var header := p.get_node_or_null("Header_Bar")
	if header != null:
		header.queue_free()

	var titulo := p.get_node_or_null("Titulo") as Label
	if titulo != null:
		titulo.position = Vector2(74, 128)
		titulo.size = Vector2(560, 42)
		titulo.text = "Perfil"
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		titulo.add_theme_font_override("font", Estilos_UI.fuente_titulo(600))
		titulo.add_theme_font_size_override("font_size", 24)
		titulo.add_theme_color_override("font_color", Estilos_UI.TINTA)
		titulo.add_theme_constant_override("outline_size", 0)

	var sub_old := p.get_node_or_null("Subtitulo_Perfil")
	if sub_old != null:
		sub_old.queue_free()

	var back := p.get_node_or_null("Boton_Cerrar") as Button
	if back != null:
		back.position = Vector2(20, 128)
		back.size = Vector2(42, 42)
		back.text = ""
		back.icon = Estilos_UI.icono("arrow-left")

	var tabs_bg := p.get_node_or_null("Tab_Track") as Panel
	if tabs_bg == null:
		tabs_bg = Panel.new()
		tabs_bg.name = "Tab_Track"
		tabs_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tabs_bg)
		p.move_child(tabs_bg, 1)
	tabs_bg.position = Vector2(20, 184)
	tabs_bg.size = Vector2(680, 46)
	tabs_bg.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#e5e7eb"), 12, Color(0, 0, 0, 0), 0, 0))

	var tabs := p.get_node_or_null("Tab_Bar") as HBoxContainer
	if tabs != null:
		tabs.position = Vector2(24, 188)
		tabs.size = Vector2(672, 38)
		tabs.add_theme_constant_override("separation", 4)
		for tab in tabs.get_children():
			if tab is Button:
				tab.custom_minimum_size = Vector2(0, 38)
				tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				tab.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
				tab.add_theme_font_size_override("font_size", 14)
				tab.add_theme_constant_override("icon_max_width", 16)

	for n in ["Lista_Mensajes", "Panel_Info", "Panel_Apuntes", "Panel_Despensa"]:
		var c := p.get_node_or_null(n) as Control
		if c != null:
			c.position = Vector2(20, 246)
			c.size = Vector2(680, alto_contenido)

	var lista_vbox := p.get_node_or_null("Lista_Mensajes/VBoxContainer") as VBoxContainer
	if lista_vbox != null:
		lista_vbox.add_theme_constant_override("separation", 10)

	var scroll_info := p.get_node_or_null("Panel_Info/Scroll_Info") as ScrollContainer
	if scroll_info != null:
		scroll_info.position = Vector2.ZERO
		scroll_info.size = Vector2(680, alto_contenido)
		scroll_info.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox_info := p.get_node_or_null("Panel_Info/Scroll_Info/VBox_Info") as VBoxContainer
	if vbox_info != null:
		vbox_info.add_theme_constant_override("separation", 8)

	var scroll_inv := p.get_node_or_null("Panel_Apuntes/Scroll_Inventario") as ScrollContainer
	if scroll_inv != null:
		scroll_inv.position = Vector2.ZERO
		scroll_inv.size = Vector2(680, maxf(120.0, alto_contenido))
		scroll_inv.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := p.get_node_or_null("Panel_Apuntes/Scroll_Inventario/Grid_Libros") as GridContainer
	if grid != null:
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 16)

	var sin_libros := p.get_node_or_null("Panel_Apuntes/Sin_Apuntes_Label") as Label
	if sin_libros != null:
		sin_libros.position = Vector2(20, 100)
		sin_libros.size = Vector2(640, 120)
		sin_libros.add_theme_font_override("font", Estilos_UI.fuente_ui(400))
		sin_libros.add_theme_font_size_override("font_size", 15)
		sin_libros.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)

	var scroll_tuppers := p.get_node_or_null("Panel_Despensa/Scroll_Tuppers") as ScrollContainer
	if scroll_tuppers != null:
		scroll_tuppers.position = Vector2.ZERO
		scroll_tuppers.size = Vector2(680, alto_contenido)
		scroll_tuppers.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox_tuppers := p.get_node_or_null("Panel_Despensa/Scroll_Tuppers/VBox_Tuppers") as VBoxContainer
	if vbox_tuppers != null:
		vbox_tuppers.add_theme_constant_override("separation", 10)
	var sin_tuppers := p.get_node_or_null("Panel_Despensa/Sin_Tuppers_Label") as Label
	if sin_tuppers != null:
		sin_tuppers.position = Vector2(20, 60)
		sin_tuppers.size = Vector2(640, 120)
		sin_tuppers.add_theme_font_override("font", Estilos_UI.fuente_ui(400))
		sin_tuppers.add_theme_font_size_override("font_size", 15)
		sin_tuppers.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)

	var cont := p.get_node_or_null("Contenido_Mensaje") as ColorRect
	if cont != null:
		cont.position = Vector2(20, 246)
		cont.size = Vector2(680, alto_contenido)
		cont.color = Estilos_UI.FONDO
		var card := cont.get_node_or_null("Mensaje_Card") as Panel
		if card != null:
			card.position = Vector2.ZERO
			card.size = Vector2(680, alto_contenido - 22.0)
			card.add_theme_stylebox_override("panel",
				Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 1))
		var volver := cont.get_node_or_null("Boton_Volver") as Button
		if volver != null:
			volver.position = Vector2(18, 18)
			volver.size = Vector2(40, 40)
			volver.text = ""
			volver.icon = Estilos_UI.icono("arrow-left")
		var hora := cont.get_node_or_null("Hora_Mensaje_Label") as Label
		if hora != null:
			hora.position = Vector2(70, 26)
			hora.size = Vector2(580, 24)
			hora.add_theme_font_override("font", Estilos_UI.fuente_ui(500))
			hora.add_theme_font_size_override("font_size", 13)
			hora.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
		var tit := cont.get_node_or_null("Titulo_Mensaje_Label") as Label
		if tit != null:
			tit.position = Vector2(24, 78)
			tit.size = Vector2(632, 64)
			tit.add_theme_font_override("font", Estilos_UI.fuente_titulo(600))
			tit.add_theme_font_size_override("font_size", 22)
			tit.add_theme_color_override("font_color", Estilos_UI.TINTA)
			tit.add_theme_constant_override("outline_size", 0)
		var desc := cont.get_node_or_null("Descripcion_Mensaje_Label") as Label
		if desc != null:
			desc.position = Vector2(24, 152)
			desc.size = Vector2(632, alto_contenido - 202.0)
			desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			desc.add_theme_font_override("font", Estilos_UI.fuente_ui(400))
			desc.add_theme_font_size_override("font_size", 16)
			desc.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
			desc.add_theme_constant_override("line_spacing", 5)


func _Marcar_Tab_Perfil(activo: String) -> void:
	var tabs := get_node_or_null("Pantalla_Mensajes/Tab_Bar")
	if tabs == null:
		return
	for tab in tabs.get_children():
		if tab is Button:
			var on: bool = tab.name == activo
			var tab_fondo: Color = Estilos_UI.SUPERFICIE if on else Color(0, 0, 0, 0)
			var st := Estilos_UI.caja(tab_fondo, 9, Estilos_UI.ROJO_BIT if on else Color(0, 0, 0, 0), 0, 1 if on else 0)
			if on:
				st.border_width_bottom = 2
			tab.add_theme_stylebox_override("normal", st)
			tab.add_theme_stylebox_override("hover", st)
			tab.add_theme_stylebox_override("pressed", st)
			tab.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if on else 500))
			var col: Color = Estilos_UI.ROJO_BIT if on else Estilos_UI.TINTA_SUAVE
			for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
					"icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
				tab.add_theme_color_override(k, col)


func _Conectar_Recompensas() -> void:
	if not Recompensas.recompensa_aplicada.is_connected(_On_Recompensa_Bienestar):
		Recompensas.recompensa_aplicada.connect(_On_Recompensa_Bienestar)


func _On_Recompensa_Bienestar(_origen: String, _recompensas: Array) -> void:
	# La recompensa ya está aplicada en Variables_Dinamicas; aquí solo se
	# refresca lo que pinta la escena principal.
	Actualizar_Dinero()
	necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)
	_Actualizar_Home()
	_Actualizar_Tienda_UI()
	_Actualizar_Badges()


func _Conectar_Tienda() -> void:
	var tienda := get_node_or_null("Tienda")
	if tienda == null:
		return
	var flecha := tienda.get_node_or_null("Flecha_Atras")
	if flecha != null and not flecha.pressed.is_connected(_on_tienda_flecha_atras_pressed):
		flecha.pressed.connect(_on_tienda_flecha_atras_pressed)
	if tienda.has_signal("dinero_cambiado") \
			and not tienda.is_connected("dinero_cambiado", _On_Tienda_Dinero_Cambiado):
		tienda.connect("dinero_cambiado", _On_Tienda_Dinero_Cambiado)
	if tienda.has_signal("objetos_cambiados") \
			and not tienda.is_connected("objetos_cambiados", _On_Tienda_Objetos_Cambiados):
		tienda.connect("objetos_cambiados", _On_Tienda_Objetos_Cambiados)


func _On_Tienda_Dinero_Cambiado() -> void:
	Actualizar_Dinero()


func _On_Tienda_Objetos_Cambiados() -> void:
	_Actualizar_Necesidades_Extra()
	_Actualizar_Home()
	_Actualizar_Nav_Activa()


func _Redisenar_Tienda() -> void:
	var tienda := get_node_or_null("Tienda") as Control
	if tienda == null:
		return
	var alto := _Alto_Pantalla()
	tienda.position = Vector2.ZERO
	tienda.size = Vector2(720, alto)
	var bg := tienda.get_node_or_null("Fondo_Seccion") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "Fondo_Seccion"
		bg.color = Estilos_UI.FONDO
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tienda.add_child(bg)
		tienda.move_child(bg, 0)
	bg.position = Vector2.ZERO
	bg.size = Vector2(720, alto)
	bg.z_index = -3

	var titulo := tienda.get_node_or_null("Titulo") as Label
	if titulo != null:
		titulo.position = Vector2(74, 128)
		titulo.size = Vector2(560, 42)
		titulo.text = "Tienda"
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		titulo.add_theme_font_override("font", Estilos_UI.fuente_titulo(600))
		titulo.add_theme_font_size_override("font_size", 24)
		titulo.add_theme_color_override("font_color", Estilos_UI.TINTA)
		titulo.add_theme_constant_override("outline_size", 0)

	var flecha := tienda.get_node_or_null("Flecha_Atras") as Button
	if flecha != null:
		flecha.position = Vector2(20, 128)
		flecha.size = Vector2(42, 42)
		flecha.text = ""
		flecha.icon = Estilos_UI.icono("arrow-left")

	var ventajas := tienda.get_node_or_null("Objetos_Ventajas") as Control
	if ventajas != null:
		ventajas.position = Vector2(0, 248)
		ventajas.size = Vector2(720, alto - 248 - 92)
		ventajas.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if tienda.has_method("Ajustar_Disposicion"):
		tienda.call("Ajustar_Disposicion", alto)
	if tienda.has_method("Abrir_Categoria"):
		tienda.call("Abrir_Categoria", "Dormir")
	_Conectar_Tienda()


func _Marcar_Categoria_Tienda(activa: String) -> void:
	var tienda := get_node_or_null("Tienda")
	if tienda == null or not tienda.has_method("Abrir_Categoria"):
		return
	var id: String = {
		"Tab_Dormir": "Dormir",
		"Tab_Comer": "Comer",
		"Tab_Duchar": "Duchar",
		"Tab_Salon": "Salon",
		"Tab_Estudio": "Estudio",
		"Tab_Cocina": "Cocina",
		"Tab_Ventajas": "Ventajas",
	}.get(activa, activa)
	tienda.call("Abrir_Categoria", id)


func _Estilizar_Badges() -> void:
	for badge in [_badge_perfil, _badge_tab_mensajes, _badge_minijuegos]:
		if badge == null:
			continue
		badge.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_stylebox_override("normal",
			Estilos_UI.caja(Estilos_UI.PELIGRO, 999, Color.WHITE, 2, 1))
		if badge == _badge_perfil or badge == _badge_minijuegos:
			badge.offset_top = 2
			badge.offset_bottom = 18
			badge.offset_left = -22
			badge.offset_right = -4
		else:
			badge.offset_top = 4
			badge.offset_bottom = 20
			badge.offset_left = -26
			badge.offset_right = -4


var _dialog_acceso_rapido: AcceptDialog = null
var _acceso_rapido_desc: Label = null
var _acceso_rapido_opciones: HBoxContainer = null
var _acceso_rapido_clave: String = ""


func _Crear_Tarjeta_Resumen_Home(icono_nombre: String, titulo_sec: String, acento: Color, callback: Callable) -> Dictionary:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 96)
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := Estilos_UI.caja_tarjeta(16, 3)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#fafbfd")
	hover.border_color = Estilos_UI.BORDE_FUERTE
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Estilos_UI.PRIMARIO_SUAVE
	pressed.border_color = Estilos_UI.PRIMARIO
	pressed.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(callback)
	Estilos_UI.animar_presion(btn)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	btn.add_child(m)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 8)
	m.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 8)
	col.add_child(top)

	var ic := Estilos_UI.badge_icono(icono_nombre, 28, 15, acento, Color.WHITE, 8)
	top.add_child(ic)

	var lbl_k := Estilos_UI.texto(titulo_sec.to_upper(), 11, Estilos_UI.TINTA_FANTASMA, 700)
	lbl_k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl_k)

	var ch := Estilos_UI.icono_rect("chevron-right", 15, Estilos_UI.TINTA_FANTASMA)
	ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(ch)

	var lbl_v := Estilos_UI.titulo("", 16, Estilos_UI.TINTA)
	lbl_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_v.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(lbl_v)

	return {"boton": btn, "valor": lbl_v}


func _Crear_Home() -> void:
	if get_node_or_null("Home") != null:
		return
	_home_barras.clear()
	_home_pcts.clear()

	_home = Control.new()
	_home.name = "Home"
	_home.position = Vector2(20, 124)
	_home.size = Vector2(680, _Alto_Pantalla() - 228.0)
	_home.z_index = -1
	add_child(_home)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_home.add_child(scroll)

	var v := VBoxContainer.new()
	v.name = "Contenido"
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	scroll.add_child(v)

	# --- Estado actual (Hero Card estilo BitLife) ---
	var card_estado := PanelContainer.new()
	card_estado.name = "Card_Estado"
	card_estado.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	card_estado.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	v.add_child(card_estado)

	var estado_outer := VBoxContainer.new()
	estado_outer.add_theme_constant_override("separation", 0)
	card_estado.add_child(estado_outer)

	_home_estado_banda = ColorRect.new()
	_home_estado_banda.custom_minimum_size = Vector2(0, 5)
	_home_estado_banda.color = Estilos_UI.ROJO_BIT
	_home_estado_banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estado_outer.add_child(_home_estado_banda)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 14)
	estado_outer.add_child(margen)

	var estado_v := VBoxContainer.new()
	estado_v.add_theme_constant_override("separation", 12)
	margen.add_child(estado_v)

	var top_estado := HBoxContainer.new()
	top_estado.add_theme_constant_override("separation", 14)
	estado_v.add_child(top_estado)

	_home_estado_badge = Estilos_UI.badge_icono("sun", 48, 24, Estilos_UI.ROJO_BIT, Color.WHITE, 13)
	_home_estado_icono = _home_estado_badge.get_child(0).get_child(0) as TextureRect
	top_estado.add_child(_home_estado_badge)

	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 2)
	vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_estado.add_child(vv)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 6)
	vv.add_child(tag_row)

	var live_dot := Panel.new()
	live_dot.custom_minimum_size = Vector2(7, 7)
	live_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	live_dot.add_theme_stylebox_override("panel", Estilos_UI.caja(Estilos_UI.EXITO, 999, Color(0, 0, 0, 0), 0, 0))
	tag_row.add_child(live_dot)

	var tag := Estilos_UI.texto("AHORA MISMO", 11, Estilos_UI.TINTA_FANTASMA, 700)
	tag_row.add_child(tag)

	_home_actividad = Estilos_UI.titulo("Tiempo libre", 22, Estilos_UI.TINTA)
	vv.add_child(_home_actividad)

	_home_fecha = Estilos_UI.texto("", 13, Estilos_UI.TINTA_SUAVE, 500)
	vv.add_child(_home_fecha)

	_home_vivienda_pill = Estilos_UI.pill_estado("Con alquiler", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
	_home_vivienda_pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_estado.add_child(_home_vivienda_pill)

	# Escenario animado en vivo mostrando al personaje en su actividad actual
	_home_escenario = Escenario_Actividad.new()
	_home_escenario.name = "Escenario_Actividad"
	estado_v.add_child(_home_escenario)

	estado_v.add_child(Estilos_UI.divisor_horizontal())

	var pie_estado := HBoxContainer.new()
	pie_estado.add_theme_constant_override("separation", 8)
	estado_v.add_child(pie_estado)

	pie_estado.add_child(Estilos_UI.icono_rect("user-round", 15, Estilos_UI.TINTA_FANTASMA))
	_home_edad = Estilos_UI.texto("", 13, Estilos_UI.TINTA_SUAVE, 600)
	_home_edad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie_estado.add_child(_home_edad)

	var btn_vestuario := Estilos_UI.boton("Vestuario", "suave", "shirt", Estilos_UI.AZUL, 34)
	btn_vestuario.name = "Boton_Vestuario_Home"
	btn_vestuario.add_theme_font_size_override("font_size", 12)
	btn_vestuario.pressed.connect(_on_vestuario_button_pressed)
	pie_estado.add_child(btn_vestuario)

	var btn_horario := Estilos_UI.boton("Ver horario", "suave", "calendar-days", Estilos_UI.ROJO_BIT, 34)
	btn_horario.add_theme_font_size_override("font_size", 12)
	btn_horario.pressed.connect(_on_calendario_boton_pressed)
	pie_estado.add_child(btn_horario)

	# --- Resumen rápido: Trabajo y Carrera ---
	var fila_resumen := HBoxContainer.new()
	fila_resumen.add_theme_constant_override("separation", 12)
	v.add_child(fila_resumen)

	var card_trabajo := _Crear_Tarjeta_Resumen_Home("briefcase-business", "Trabajo", Estilos_UI.EXITO, Callable(self, "_Abrir_Trabajos_Desde_Home"))
	_home_trabajo_val = card_trabajo["valor"]
	fila_resumen.add_child(card_trabajo["boton"])

	var card_carrera := _Crear_Tarjeta_Resumen_Home("graduation-cap", "Carrera", Estilos_UI.AZUL, Callable(self, "_on_carrera_tab_pressed"))
	_home_carrera_val = card_carrera["valor"]
	fila_resumen.add_child(card_carrera["boton"])

	# --- Necesidades ---
	var card_necesidades := PanelContainer.new()
	card_necesidades.name = "Card_Necesidades"
	card_necesidades.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	v.add_child(card_necesidades)

	var m2 := MarginContainer.new()
	m2.add_theme_constant_override("margin_left", 20)
	m2.add_theme_constant_override("margin_right", 20)
	m2.add_theme_constant_override("margin_top", 16)
	m2.add_theme_constant_override("margin_bottom", 18)
	card_necesidades.add_child(m2)

	var v2 := VBoxContainer.new()
	v2.add_theme_constant_override("separation", 11)
	m2.add_child(v2)

	var enc_necesidades := Estilos_UI.encabezado_seccion("Necesidades", "Ver detalle")
	_home_bienestar_pill = Estilos_UI.pill_estado("Bien", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
	enc_necesidades.add_child(_home_bienestar_pill)
	enc_necesidades.move_child(_home_bienestar_pill, 1)
	v2.add_child(enc_necesidades)
	enc_necesidades.get_node("Accion").pressed.connect(_on_boton_necesidades_basicas_pressed)

	var datos_necesidades := [
		["Salud física", "heart-pulse", Estilos_UI.ROJO_BIT],
		["Salud mental", "brain", Estilos_UI.MORADO],
		["Hambre", "utensils", Estilos_UI.AVISO],
		["Descanso", "moon", Estilos_UI.AZUL],
		["Higiene", "droplet", Estilos_UI.CIAN],
	]
	for d in datos_necesidades:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		var ic := Estilos_UI.badge_icono(d[1], 26, 14, d[2], Color.WHITE, 7)
		fila.add_child(ic)
		var lbl := Estilos_UI.texto(d[0], 13, Estilos_UI.TINTA, 600)
		lbl.custom_minimum_size = Vector2(110, 26)
		fila.add_child(lbl)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
		bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Estilos_UI.color_valor(0)))
		fila.add_child(bar)
		var pct := Estilos_UI.texto("0%", 12, Estilos_UI.TINTA_SUAVE, 700)
		pct.custom_minimum_size = Vector2(40, 26)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(pct)
		v2.add_child(fila)
		_home_barras.append(bar)
		_home_pcts.append(pct)

	# --- Acciones rápidas ---
	var card_acciones := PanelContainer.new()
	card_acciones.name = "Card_Acciones"
	card_acciones.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	v.add_child(card_acciones)

	var m3 := MarginContainer.new()
	m3.add_theme_constant_override("margin_left", 20)
	m3.add_theme_constant_override("margin_right", 20)
	m3.add_theme_constant_override("margin_top", 16)
	m3.add_theme_constant_override("margin_bottom", 18)
	card_acciones.add_child(m3)

	var v3 := VBoxContainer.new()
	v3.add_theme_constant_override("separation", 12)
	m3.add_child(v3)
	var enc_acc := Estilos_UI.encabezado_seccion("Acciones rápidas", "Horario")
	v3.add_child(enc_acc)
	enc_acc.get_node("Accion").pressed.connect(_Abrir_Horario_Desde_Home)

	# Flechas para mover el carrusel (además del swipe táctil y la rueda del ratón).
	_home_accion_izq = _Crear_Boton_Scroll_Acciones("chevron-left", -1)
	_home_accion_der = _Crear_Boton_Scroll_Acciones("chevron-right", 1)
	enc_acc.add_child(_home_accion_izq)
	enc_acc.add_child(_home_accion_der)
	enc_acc.move_child(_home_accion_izq, 1)
	enc_acc.move_child(_home_accion_der, 2)

	_home_acciones_scroll = ScrollContainer.new()
	_home_acciones_scroll.name = "Acciones_Scroll"
	_home_acciones_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_home_acciones_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# La rueda mueve el carrusel en horizontal y el arrastre táctil queda suave.
	_home_acciones_scroll.scroll_horizontal_by_default = true
	_home_acciones_scroll.scroll_deadzone = 10
	_home_acciones_scroll.scroll_horizontal_custom_step = 116.0
	_home_acciones_scroll.custom_minimum_size = Vector2(0, 106)
	_home_acciones_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v3.add_child(_home_acciones_scroll)
	var hbar := _home_acciones_scroll.get_h_scroll_bar()
	hbar.value_changed.connect(func(_valor: float) -> void: _Actualizar_Flechas_Acciones_Home())
	hbar.changed.connect(_Actualizar_Flechas_Acciones_Home)

	var acciones := HBoxContainer.new()
	acciones.name = "Acciones"
	acciones.add_theme_constant_override("separation", 10)
	acciones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_acciones_scroll.add_child(acciones)

	var lista_acciones := [
		["Dormir", "Dormir", "moon", Estilos_UI.INDIGO, Estilos_UI.INDIGO_SUAVE, "+Descanso"],
		["Comer", "Comer", "utensils", Estilos_UI.AVISO, Estilos_UI.AVISO_SUAVE, "+Hambre"],
		["Duchar", "Duchar", "droplet", Estilos_UI.EXITO, Estilos_UI.EXITO_SUAVE, "+Higiene"],
		["Estudiar", "Estudiar", "book-open", Estilos_UI.AZUL, Estilos_UI.AZUL_SUAVE, "+Acad."],
		["Cocinar", "Cocinar", "flame", Color("#ea580c"), Color("#ffedd5"), "+Cocina"],
		["Ver_La_Television", "Ver tele", "tv", Estilos_UI.MORADO, Estilos_UI.MORADO_SUAVE, "+Mental"],
		["Salir_A_Correr", "Correr", "footprints", Estilos_UI.EXITO, Estilos_UI.EXITO_SUAVE, "+Deporte"],
		["Practicar_Manualidades", "Manualidades", "palette", Estilos_UI.CORAL, Estilos_UI.CORAL_SUAVE, "+Manual."],
	]
	for accion in lista_acciones:
		var col_ac: Color = accion[3]
		var col_bg: Color = accion[4]
		var b := Button.new()
		b.custom_minimum_size = Vector2(112, 106)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st_n := Estilos_UI.caja(col_bg, 14, Color(col_ac, 0.24), 1, 0)
		st_n.border_width_bottom = 3
		var st_h := Estilos_UI.caja(col_bg.darkened(0.04), 14, Color(col_ac, 0.45), 1, 1)
		st_h.border_width_bottom = 3
		var st_p := Estilos_UI.caja(col_bg.darkened(0.10), 14, col_ac, 1, 0)
		st_p.border_width_bottom = 1
		b.add_theme_stylebox_override("normal", st_n)
		b.add_theme_stylebox_override("hover", st_h)
		b.add_theme_stylebox_override("pressed", st_p)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.pressed.connect(_Abrir_Desde_Acceso_Rapido.bind(accion[0]))
		Estilos_UI.animar_presion(b)

		var vv2 := VBoxContainer.new()
		vv2.set_anchors_preset(Control.PRESET_FULL_RECT)
		vv2.offset_top = 10
		vv2.offset_bottom = -10
		vv2.alignment = BoxContainer.ALIGNMENT_CENTER
		vv2.add_theme_constant_override("separation", 5)
		vv2.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var pill_ic := Estilos_UI.badge_icono(accion[2], 42, 21, col_ac, Color.WHITE, 12)
		vv2.add_child(pill_ic)

		var lbl2 := Estilos_UI.texto(accion[1], 13, Estilos_UI.TINTA, 700)
		lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv2.add_child(lbl2)

		var sub_ac := Estilos_UI.texto(accion[5], 10, col_ac.darkened(0.12), 700)
		sub_ac.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_ac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_ac.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv2.add_child(sub_ac)

		b.add_child(vv2)
		acciones.add_child(b)

	_Actualizar_Flechas_Acciones_Home.call_deferred()


func _Estilo_Actividad_Actual(nombre_act: String) -> Array:
	var low := nombre_act.to_lower()
	if low.contains("dormir"):
		return ["moon", Estilos_UI.INDIGO]
	elif low.contains("cocinar"):
		return ["flame", Color("#ea580c")]
	elif low.contains("comer"):
		return ["utensils", Estilos_UI.AVISO]
	elif low.contains("duchar"):
		return ["droplet", Estilos_UI.CIAN]
	elif low.contains("estudiar") or low.contains("examen"):
		return ["book-open", Estilos_UI.AZUL]
	elif low.contains("correr"):
		return ["footprints", Estilos_UI.EXITO]
	elif low.contains("manualidades"):
		return ["palette", Color("#ea580c")]
	elif low.contains("television") or low.contains("televisión"):
		return ["tv", Estilos_UI.MORADO]
	elif low.contains("trabajar"):
		return ["briefcase-business", Estilos_UI.EXITO]
	return ["sun", Estilos_UI.ROJO_BIT]


func _Obtener_Nombre_Actividad_Actual() -> String:
	var dia: int = Variables_Dinamicas.Minute_Day
	var min_dia: int = Variables_Dinamicas.Minute_Minute
	if dia < 0 or dia >= 574 or min_dia < 0 or min_dia >= 1440:
		return ""
	var celda = Variables_Dinamicas.Matriz_Jugador[min_dia][dia]
	if celda is String:
		if celda == "" or celda == "Actividad_Aleatoria":
			return ""
		return str(celda)
	if celda is Actividad:
		return str(celda.nombre)
	return ""


func _Formatear_Actividad_Actual() -> String:
	var dia: int = Variables_Dinamicas.Minute_Day
	var min_dia: int = Variables_Dinamicas.Minute_Minute
	if dia < 0 or dia >= 574 or min_dia < 0 or min_dia >= 1440:
		return "Tiempo libre"
	var celda = Variables_Dinamicas.Matriz_Jugador[min_dia][dia]
	if celda is String:
		if celda == "":
			return "Tiempo libre"
		if celda == "Actividad_Aleatoria":
			return "Actividad espontánea"
		return str(celda).replace("_", " ")
	if celda is Actividad:
		return celda.nombre.replace("_", " ")
	return "Tiempo libre"


func _Actualizar_Home() -> void:
	if _home == null or not is_instance_valid(_home) or not _home.visible:
		return

	var act_txt := _Formatear_Actividad_Actual()
	if _home_actividad != null:
		_home_actividad.text = act_txt
	var act_est := _Estilo_Actividad_Actual(act_txt)
	if _home_estado_banda != null:
		_home_estado_banda.color = act_est[1]
	if _home_estado_badge != null:
		var st_eb := Estilos_UI.caja(act_est[1], 13, act_est[1].darkened(0.24), 0, 0)
		st_eb.border_width_bottom = 2
		_home_estado_badge.add_theme_stylebox_override("panel", st_eb)
	if _home_estado_icono != null:
		_home_estado_icono.texture = Estilos_UI.icono(act_est[0])
	if _home_escenario != null and is_instance_valid(_home_escenario):
		_home_escenario.actualizar_estado(
			_Obtener_Nombre_Actividad_Actual(),
			Variables_Dinamicas.En_La_Calle,
			Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(Variables_Estaticas.Apariencia),
			int(Variables_Dinamicas.Minute_Minute),
			str(Variables_Dinamicas.Objeto_Seleccionado.get("Comer", "Mesa_Basica")),
			str(Variables_Estaticas.Personalidad)
		)

	if _home_fecha != null:
		_home_fecha.text = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(
			Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute)

	if _home_edad != null:
		var edad := Variables_Estaticas.Calcular_Edad()
		var personalidad := Variables_Estaticas.Personalidad.replace("_", " ").capitalize()
		_home_edad.text = "%d años · %s" % [max(18, edad), personalidad]

	if _home_vivienda_pill != null:
		if Variables_Dinamicas.En_La_Calle:
			_Actualizar_Badge_Pill(_home_vivienda_pill, "Sin vivienda", Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO)
		else:
			_Actualizar_Badge_Pill(_home_vivienda_pill, "Con alquiler", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)

	if _home_trabajo_val != null:
		if Variables_Dinamicas.Trabajo_Actual == null:
			_home_trabajo_val.text = "Sin empleo"
			_home_trabajo_val.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
		else:
			var tr = Variables_Dinamicas.Trabajo_Actual
			var sal_h := int(round(Variables_Estaticas.Obtener_Salario_Hora(tr)))
			_home_trabajo_val.text = "%s · %d€/h" % [tr.nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " "), sal_h]
			_home_trabajo_val.add_theme_color_override("font_color", Estilos_UI.TINTA)

	if _home_carrera_val != null:
		if Variables_Dinamicas.Carrera_Actual == null:
			_home_carrera_val.text = "Sin matrícula"
			_home_carrera_val.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
		else:
			var c = Variables_Dinamicas.Carrera_Actual
			_home_carrera_val.text = "%s · %d%%" % [c.nombre.replace("_", " "), int(c.progreso_actual)]
			_home_carrera_val.add_theme_color_override("font_color", Estilos_UI.TINTA)

	var suma_n := 0.0
	var count_n: int = mini(_home_barras.size(), Variables_Dinamicas.Necesidades_Basicas.size())
	for i in range(count_n):
		var valor_n: int = Variables_Dinamicas.Necesidades_Basicas[i]
		suma_n += float(valor_n)
		Estilos_UI.animar_barra(_home_barras[i], float(valor_n), Estilos_UI.color_valor(valor_n))
		_home_pcts[i].text = "%d%%" % valor_n
		_home_pcts[i].add_theme_color_override("font_color", Estilos_UI.color_valor(valor_n))
	if _home_bienestar_pill != null and count_n > 0:
		var est_b := Estilos_UI.etiqueta_bienestar(suma_n / float(count_n))
		_Actualizar_Badge_Pill(_home_bienestar_pill, est_b[0], est_b[1], est_b[2])

	_Actualizar_Flechas_Acciones_Home()


func _Crear_Boton_Scroll_Acciones(icono: String, direccion: int) -> Button:
	var b := Button.new()
	b.name = "Accion_Scroll_Izq" if direccion < 0 else "Accion_Scroll_Der"
	b.custom_minimum_size = Vector2(28, 28)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.icon = Estilos_UI.icono(icono)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_constant_override("icon_max_width", 16)
	b.add_theme_stylebox_override("normal", Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 8, Estilos_UI.BORDE, 1, 0))
	b.add_theme_stylebox_override("hover", Estilos_UI.caja(Estilos_UI.FONDO_2, 8, Estilos_UI.BORDE_FUERTE, 1, 0))
	b.add_theme_stylebox_override("pressed", Estilos_UI.caja(Estilos_UI.FONDO_2, 8, Estilos_UI.BORDE_FUERTE, 1, 0))
	b.add_theme_stylebox_override("disabled", Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 8, Estilos_UI.BORDE, 1, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("icon_normal_color", Estilos_UI.TINTA_SUAVE)
	b.add_theme_color_override("icon_hover_color", Estilos_UI.TINTA)
	b.add_theme_color_override("icon_pressed_color", Estilos_UI.TINTA)
	b.add_theme_color_override("icon_disabled_color", Color(Estilos_UI.TINTA_FANTASMA, 0.35))
	b.pressed.connect(_Desplazar_Acciones_Home.bind(direccion))
	return b


func _Desplazar_Acciones_Home(direccion: int) -> void:
	if _home_acciones_scroll == null or not is_instance_valid(_home_acciones_scroll):
		return
	var bar := _home_acciones_scroll.get_h_scroll_bar()
	var tope := maxf(0.0, bar.max_value - bar.page)
	var destino := clampf(bar.value + float(direccion) * 3.0 * 122.0, 0.0, tope)
	if _home_acciones_tween != null and _home_acciones_tween.is_valid():
		_home_acciones_tween.kill()
	_home_acciones_tween = create_tween()
	_home_acciones_tween.tween_property(bar, "value", destino, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _Actualizar_Flechas_Acciones_Home() -> void:
	if _home_acciones_scroll == null or not is_instance_valid(_home_acciones_scroll):
		return
	var bar := _home_acciones_scroll.get_h_scroll_bar()
	var tope := maxf(0.0, bar.max_value - bar.page)
	if _home_accion_izq != null and is_instance_valid(_home_accion_izq):
		_home_accion_izq.disabled = bar.value <= 1.0
	if _home_accion_der != null and is_instance_valid(_home_accion_der):
		_home_accion_der.disabled = bar.value >= tope - 1.0


func _Abrir_Trabajos_Desde_Home() -> void:
	_on_boton_actividades_pressed()
	Opciones_Actividades_Fijas()
	Opciones_Actividades_Trabajo()


func _Abrir_Horario_Desde_Home() -> void:
	mirar_semana = Variables_Dinamicas.Minute_Day / 7
	_Ocultar_Home()
	_on_temporales_pressed()


func _Titulo_Acceso_Rapido(clave: String) -> String:
	match clave:
		"Comer_Tupper":
			return "Comida casera"
		"Comer_Basura":
			return "Comida rápida"
		"Ver_La_Television":
			return "Ver la televisión"
		"Salir_A_Correr":
			return "Salir a correr"
		"Practicar_Manualidades":
			return "Manualidades"
		_:
			return str(NOMBRES_VISIBLES_ACTIVIDADES.get(clave, clave.replace("_", " ")))


func _Abrir_Desde_Acceso_Rapido(clave: String) -> void:
	# La antigua acción "Comer" gratuita ahora elige tupper o comida rápida.
	if clave == "Comer":
		clave = "Comer_Tupper" if Alimentacion.Tiene_Tupper_Vigente() else "Comer_Basura"
	if clave == "Cocinar":
		var validacion_cocina: Dictionary = Alimentacion.Validar_Cocinar(
			Variables_Estaticas.MINUTOS_POR_TUPPER, Variables_Dinamicas.En_La_Calle)
		if not bool(validacion_cocina.get("valido", false)):
			_Mostrar_Error_Alimentacion(str(validacion_cocina.get("motivo", "")))
			return
	_acceso_rapido_clave = clave
	if _dialog_acceso_rapido == null:
		_dialog_acceso_rapido = AcceptDialog.new()
		_dialog_acceso_rapido.name = "Dialogo_Acceso_Rapido"
		add_child(_dialog_acceso_rapido)

		var margen := MarginContainer.new()
		margen.add_theme_constant_override("margin_left", 8)
		margen.add_theme_constant_override("margin_right", 8)
		margen.add_theme_constant_override("margin_top", 4)
		margen.add_theme_constant_override("margin_bottom", 8)
		_dialog_acceso_rapido.add_child(margen)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		margen.add_child(box)

		_acceso_rapido_desc = Estilos_UI.parrafo("", 13, Estilos_UI.TINTA_SUAVE)
		box.add_child(_acceso_rapido_desc)

		_acceso_rapido_opciones = HBoxContainer.new()
		_acceso_rapido_opciones.add_theme_constant_override("separation", 8)
		box.add_child(_acceso_rapido_opciones)

		var btn_horario := Estilos_UI.boton("Elegir otro tramo en el horario", "secundario", "calendar-days", Estilos_UI.PRIMARIO, 44)
		btn_horario.set_meta("_estilo_propio", true)
		btn_horario.pressed.connect(func():
			_dialog_acceso_rapido.hide()
			_Abrir_Horario_Desde_Home()
		)
		box.add_child(btn_horario)

	_dialog_acceso_rapido.title = _Titulo_Acceso_Rapido(clave)
	_acceso_rapido_desc.text = "Programa %s empezando ahora:" % _Titulo_Acceso_Rapido(clave).to_lower()
	_dialog_acceso_rapido.get_ok_button().text = "Cancelar"

	for hijo in _acceso_rapido_opciones.get_children():
		hijo.queue_free()

	var duraciones_por_actividad := {
		"Dormir": [60, 120, 360, 480],
		"Cocinar": [15, 30, 60, 120],
	}
	var duraciones: Array = duraciones_por_actividad.get(clave, [30, 60, 120, 240])
	for min_dur in duraciones:
		var etiqueta := "%d min" % min_dur if min_dur < 60 else "%d h" % int(float(min_dur) / 60.0)
		var b := Estilos_UI.boton(etiqueta, "exito", "", Estilos_UI.EXITO, 44)
		b.set_meta("_estilo_propio", true)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_Programar_Acceso_Rapido_Duracion.bind(clave, min_dur))
		_acceso_rapido_opciones.add_child(b)

	_dialog_acceso_rapido.set_meta("_tema_dialogo", true)
	Estilos_UI.estilizar_dialogo(_dialog_acceso_rapido)
	Estilos_UI.aplicar_estilo_boton(_dialog_acceso_rapido.get_ok_button(), "secundario")
	_dialog_acceso_rapido.popup_centered(Vector2i(540, 250))


func _Programar_Acceso_Rapido_Duracion(clave: String, duracion_min: int) -> void:
	if _dialog_acceso_rapido != null:
		_dialog_acceso_rapido.hide()
	if clave == "Cocinar":
		var validacion_cocina: Dictionary = Alimentacion.Validar_Cocinar(
			duracion_min, Variables_Dinamicas.En_La_Calle)
		if not bool(validacion_cocina.get("valido", false)):
			_Mostrar_Error_Alimentacion(str(validacion_cocina.get("motivo", "")))
			return
	var total_inicio: int = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	var total_fin: int = total_inicio + duracion_min
	var col_ultimo: int = int((total_fin - 1) / 1440)
	if total_inicio < 0 or col_ultimo >= 574:
		return

	var semana: int = int(total_inicio / (7 * 1440))
	var col_inicio: int = int(total_inicio / 1440)
	var dia_inicio: int = col_inicio % 7
	var min_dia_inicio: int = total_inicio % 1440
	var hora_inicio: int = min_dia_inicio / 60
	var minuto_inicio: int = min_dia_inicio % 60

	var col_fin: int = int(total_fin / 1440)
	var dia_final: int = col_fin - semana * 7
	var min_dia_fin: int = total_fin % 1440
	var hora_final: int = min_dia_fin / 60
	var minuto_final: int = min_dia_fin % 60

	var ok: bool = Actividades.Crear_Actividad_Especifica(
		semana, dia_inicio, dia_final, hora_inicio, hora_final, minuto_inicio, minuto_final, clave)
	if not ok:
		_Mostrar_Error_Prioridad()
		return
	_Actualizar_Reloj_Header()
	_Actualizar_Home()
	_Actualizar_Necesidades_Extra()


func _Iniciar_Tutorial() -> void:
	if get_node_or_null("Tutorial_Inicial") != null:
		return
	var tut := TUTORIAL_INICIAL.new()
	tut.name = "Tutorial_Inicial"
	tut.escena_principal = self
	tut.terminado.connect(func():
		Variables_Estaticas.Tutorial_Completado = true
		Guardar_Variables_Estaticas.save_game()
	)
	add_child(tut)
