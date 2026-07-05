
extends Node

# Called when the node enters the scene tree for the first time.



var mirar_semana
var calendario_solo_lectura: bool = false

var actividad_seleccionada

var horario_bloque

var actividades_reloj_gui
var actividades_bloque_gui
var necesidades_basicas_gui
var consultar_y_eliminar_actividades_gui

var first_time_logica

var seleccionar_horario_activo: bool = false
var drag_inicio_y: float = 0.0
var drag_threshold: float = 30.0
var rueda_activa: String = ""

var blink_timer: Timer = null
var blink_estado: bool = false
var mini_cal_preview = null
var _dialog_ir_a_la_calle: ConfirmationDialog = null

var _badge_perfil: Label = null
var _badge_tab_mensajes: Label = null


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

func _ready():
	Inicializar_Otros_Scripts()
	_Crear_Pantalla_Carrera()
	_Crear_Pantalla_Economia()
	_badge_perfil = _Crear_Badge($Boton_Perfil)
	_badge_tab_mensajes = _Crear_Badge($Pantalla_Mensajes/Tab_Bar/Tab_Mensajes)
	$Pantalla_Mensajes/Boton_Cerrar.pressed.connect(_on_mensajes_boton_cerrar_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Mensajes.pressed.connect(_on_perfil_tab_mensajes_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Info.pressed.connect(_on_perfil_tab_info_pressed)
	$Pantalla_Mensajes/Tab_Bar/Tab_Apuntes.pressed.connect(_on_perfil_tab_apuntes_pressed)
	$Pantalla_Mensajes/Contenido_Mensaje/Boton_Volver.pressed.connect(_on_mensajes_boton_volver_pressed)
	# TEST: mensaje para verificar que el badge funciona — borrar cuando esté confirmado
	var _msg_test = Mensaje.new()
	_msg_test.titulo = "Test badge"
	_msg_test.descripcion = "Si ves esto, el badge funciona."
	_msg_test.leido = false
	_msg_test.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(_msg_test)
	if (Variables_Estaticas.First_Time):
		first_time_logica.First_Time_Function()
		mirar_semana=1
		Guardar_Variables_Estaticas.save_game()
		Guardar_Variables_Dinamicas.save_game()

	else:
		if Variables_Dinamicas.Muerto:
			get_tree().change_scene_to_file.call_deferred("res://Escenas/Menu/Menu.tscn")
			return
		Gestionar_Visibilidad.Quitar_Todo(self)
		mirar_semana=Variables_Dinamicas.Minute_Day/7
	_Actualizar_Badges()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Variables_Estaticas.First_Time == false:
		var minutos_pendientes = _Minutos_Pendientes_Por_Procesar()
		if minutos_pendientes > 0:
			var murio = Actividades.Actualizar_Horario(minutos_pendientes)
			Guardar_Variables_Dinamicas.save_game()
			if murio:
				get_tree().change_scene_to_file("res://Escenas/Menu/Menu.tscn")
				return
		Actualizar_Progreso()
		Actualizar_Dinero()
		necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)
		if $Habilidades.visible:
			Actualizar_Habilidades()
		_Actualizar_Badges()


const _DINERO_OFFSET_RIGHT_3_DIGITOS: int = 600
const _DINERO_DESPLAZAMIENTO_POR_DIGITO_EXTRA: int = 25
const _DINERO_ANCHO_LABEL: int = 220

func Actualizar_Dinero():
	var texto = str(int(Variables_Dinamicas.Dinero))
	$Dinero_Label.text = texto
	# Reposicionar a la izquierda según número de cifras para evitar solaparse
	# con el icono de Moneda (que está a la derecha en posición fija).
	var n = len(texto)
	var extra_digitos = max(0, n - 3)
	var offset_right_dinamico = _DINERO_OFFSET_RIGHT_3_DIGITOS - extra_digitos * _DINERO_DESPLAZAMIENTO_POR_DIGITO_EXTRA
	$Dinero_Label.offset_right = offset_right_dinamico
	$Dinero_Label.offset_left = offset_right_dinamico - _DINERO_ANCHO_LABEL
	_Actualizar_Pantalla_Carrera_Si_Visible()
	_Actualizar_Pantalla_Economia_Si_Visible()

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
	Gestionar_Visibilidad.Recursivo_Visibilizar($Habilidades)
	Actualizar_Habilidades()




func _on_boton_progreso_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Quitar_Todo(self)
	Gestionar_Visibilidad.Recursivo_Visibilizar($Progreso)


func _on_boton_necesidades_basicas_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Quitar_Todo(self)
	Gestionar_Visibilidad.Recursivo_Visibilizar($Necesidades_Basicas)




func Actualizar_Progreso():
	$Progreso/Progreso_Barra/Deporte.value=Variables_Dinamicas.Progreso[0]
	$Progreso/Progreso_Barra/Academico.value=Variables_Dinamicas.Progreso[1]
	$Progreso/Progreso_Barra/Manualidades.value=Variables_Dinamicas.Progreso[2]


const _NOMBRES_HABILIDADES: Array = ["DEPORTE", "INTELIGENCIA", "DESTREZA", "MEMORIA", "LIDERAZGO", "PACIENCIA", "SANGRE_FRIA"]
const _HABILIDADES_VISIBLES: int = 5
const _COLOR_HABILIDAD_DESCUBRIENDO: Color = Color(1.0, 0.85, 0.30, 1.0)  # amarillo: aún subiendo
const _COLOR_HABILIDAD_TOPE: Color = Color(0.30, 0.85, 0.45, 1.0)         # verde: has descubierto el límite

var habilidades_scroll_offset: int = 0

func Actualizar_Habilidades():
	var max_offset = _NOMBRES_HABILIDADES.size() - _HABILIDADES_VISIBLES
	for slot in range(_HABILIDADES_VISIBLES):
		var indice = slot + habilidades_scroll_offset
		var bar = $Habilidades/Habilidades_Barra.get_node("Slot_" + str(slot))
		var lbl = $Habilidades/Habilidades_Texto.get_node("Slot_" + str(slot))
		var mostrado = Variables_Dinamicas.Habilidades_Mostradas[indice]
		var innato = Variables_Estaticas.Habilidades[indice]
		bar.value = mostrado
		lbl.text = _NOMBRES_HABILIDADES[indice]
		if mostrado >= innato:
			bar.self_modulate = _COLOR_HABILIDAD_TOPE
		else:
			bar.self_modulate = _COLOR_HABILIDAD_DESCUBRIENDO
	$Habilidades/Flecha_Arriba.visible = habilidades_scroll_offset > 0
	$Habilidades/Flecha_Abajo.visible = habilidades_scroll_offset < max_offset

func _on_habilidades_flecha_arriba_pressed():
	if habilidades_scroll_offset > 0:
		habilidades_scroll_offset -= 1
		Actualizar_Habilidades()

func _on_habilidades_flecha_abajo_pressed():
	var max_offset = _NOMBRES_HABILIDADES.size() - _HABILIDADES_VISIBLES
	if habilidades_scroll_offset < max_offset:
		habilidades_scroll_offset += 1
		Actualizar_Habilidades()


func Quitar_Todo():
	Gestionar_Visibilidad.Quitar_Todo(self)











func _on_boton_actividades_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Visibilizar_Elegir_Actividad(self)



func _on_siguiente_semana_pressed() -> void:
	if mirar_semana < 81:
		mirar_semana += 1
		actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
		actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
		_Actualizar_Visibilidad_Botones_Navegacion()

func _on_anterior_semana_pressed() -> void:
	if mirar_semana > 0:
		mirar_semana -= 1
		actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
		actividades_bloque_gui.Agregar_Bloques(mirar_semana, self)
		_Actualizar_Visibilidad_Botones_Navegacion()

func _Actualizar_Visibilidad_Botones_Navegacion() -> void:
	var boton_anterior = $Actividades/Horario_Semanal/OPCIONES_CALENDARIO.get_node("ANTERIOR SEMANA")
	var boton_siguiente = $Actividades/Horario_Semanal/OPCIONES_CALENDARIO.get_node("SIGUIENTE SEMANA")

	boton_anterior.visible = mirar_semana > 0
	boton_siguiente.visible = mirar_semana < 81


func _input(event: InputEvent) -> void:
	if not seleccionar_horario_activo:
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
			if arriba and not h.dia_inicio_arriba.disabled: Inicio_Dia_Arriba()
			elif not arriba and not h.dia_inicio_abajo.disabled: Inicio_Dia_Abajo()
		"inicio_hora":
			if arriba and not h.hora_inicio_arriba.disabled: Inicio_Hora_Arriba()
			elif not arriba and not h.hora_inicio_abajo.disabled: Inicio_Hora_Abajo()
		"inicio_minuto":
			if arriba and not h.minuto_inicio_arriba.disabled: Inicio_Minuto_Arriba()
			elif not arriba and not h.minuto_inicio_abajo.disabled: Inicio_Minuto_Abajo()
		"final_dia":
			if arriba and not h.dia_final_arriba.disabled: Final_Dia_Arriba()
			elif not arriba and not h.dia_final_abajo.disabled: Final_Dia_Abajo()
		"final_hora":
			if arriba and not h.hora_final_arriba.disabled: Final_Hora_Arriba()
			elif not arriba and not h.hora_final_abajo.disabled: Final_Hora_Abajo()
		"final_minuto":
			if arriba and not h.minuto_final_arriba.disabled: Final_Minuto_Arriba()
			elif not arriba and not h.minuto_final_abajo.disabled: Final_Minuto_Abajo()

func Iniciar_Blink() -> void:
	seleccionar_horario_activo = true
	if blink_timer == null:
		blink_timer = Timer.new()
		blink_timer.wait_time = 0.5
		blink_timer.connect("timeout", Callable(self, "_on_blink_timeout"))
		add_child(blink_timer)
	blink_estado = false
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
		_actualizar_mini_cal()

func Detener_Blink() -> void:
	seleccionar_horario_activo = false
	rueda_activa = ""
	if blink_timer != null:
		blink_timer.stop()
	if mini_cal_preview != null:
		mini_cal_preview.limpiar()
		mini_cal_preview = null

func _on_blink_timeout() -> void:
	blink_estado = !blink_estado
	if mini_cal_preview != null:
		mini_cal_preview.aplicar_blink(blink_estado)

func _on_ocupar_actividad_pressed() -> void:
	if(actividades_bloque_gui.comprobar_seleccionado()):
		horario_bloque=(actividades_bloque_gui.devolver_hora_desde_posiciones())
		actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
		Gestionar_Visibilidad.Visibilizar_Seleccionar_Horario(self)
		Iniciar_Blink()
	

func _on_crear_actividad_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Recursivo_Desvisibilizar($Actividades/Seleccionar_Horario)
	$Actividades/Horario_Semanal.visible = false
	$Actividades/Elegir_Actividad.visible=true
	$Actividades/Elegir_Actividad/Tipos_De_Actividades.visible=true
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Temporales",self)


func _on_cancelar_pressed():
	calendario_solo_lectura = false
	Detener_Blink()
	Gestionar_Visibilidad.Recursivo_Desvisibilizar($Actividades/Seleccionar_Horario)
	Iniciar_Bloques_Actividad()


func _on_eliminar_actividad_pressed() -> void:
	if not actividades_bloque_gui.comprobar_seleccionado():
		return
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

	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
	#$Seleccionar_Horario.visible=true     Si se quiere seleccionar la hora exacta que se quiere eliminar, solamante hay que activar estas 3 lineas de codigo
	#$Actividades/Crear_Actividad.visible=true
	#$Horario_Semanal.visible=false
	actividades_reloj_gui.horario.Crear_Actividad(mirar_semana,"")


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
	_trabajo_a_dejar = null


func _Cancelar_Dejar_Trabajo():
	_trabajo_a_dejar = null


var _dialog_no_eliminar_examen: AcceptDialog = null

func _Mostrar_Error_No_Eliminar_Examen():
	if _dialog_no_eliminar_examen == null:
		_dialog_no_eliminar_examen = AcceptDialog.new()
		_dialog_no_eliminar_examen.title = "Examen bloqueado"
		_dialog_no_eliminar_examen.ok_button_text = "Entendido"
		add_child(_dialog_no_eliminar_examen)
	_dialog_no_eliminar_examen.dialog_text = "No puedes eliminar un examen programado."
	_dialog_no_eliminar_examen.popup_centered(Vector2i(420, 160))


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
	_Actualizar_Visibilidad_Botones_Navegacion()
	Gestionar_Visibilidad.Visibilizar_Horario_Semanal(self)


func _on_calendario_boton_pressed() -> void:
	calendario_solo_lectura = true
	mirar_semana = Variables_Dinamicas.Minute_Day / 7
	Gestionar_Visibilidad.Quitar_Todo(self)
	Iniciar_Bloques_Actividad()


func _on_temporales_pressed() -> void:
	calendario_solo_lectura = false
	Iniciar_Bloques_Actividad()


func Opciones_Actividades_Fijas() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Fijas", self)


func Opciones_Actividades_Trabajo() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Trabajo", self)


func _on_comida_rapida_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"])

func _on_carpintero_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Carpintero"])

func _on_cientifico_pressed() -> void:
	_Intentar_Tomar_Trabajo(Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Cientifico"])


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
	Trabajo.Dejar_Trabajo(Variables_Dinamicas.Trabajo_Actual)
	_Tomar_Trabajo(_trabajo_pendiente)
	_trabajo_pendiente = null

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
func Actividad_Terminada_Estudiar() -> void:
	Crear_Actividad("Estudiar")

func Actividad_Terminada_Salir_A_Correr() -> void:
	Crear_Actividad("Salir_A_Correr")

func Actividad_Terminada_Manualidades() -> void:
	Crear_Actividad("Practicar_Manualidades")

func Actividad_Terminada_Duchar() -> void:
	Crear_Actividad("Duchar")

func Actividad_Terminada_Dormir() -> void:
	Crear_Actividad("Dormir")

func Actividad_Terminada_Comer() -> void:
	Crear_Actividad("Comer")
func Actividad_Terminada_Ver_La_Television() -> void:
	Crear_Actividad("Ver_La_Television")


var _dialog_prioridad: AcceptDialog = null

func _Mostrar_Error_Prioridad() -> void:
	if _dialog_prioridad == null:
		_dialog_prioridad = AcceptDialog.new()
		_dialog_prioridad.title = "Actividad bloqueada"
		add_child(_dialog_prioridad)
	_dialog_prioridad.dialog_text = "No puedes colocar esta actividad aquí:\nhay trabajo o examen programado en ese horario."
	_dialog_prioridad.popup_centered(Vector2i(500, 200))

func Crear_Actividad(actividad):
	var ok = actividades_reloj_gui.horario.Crear_Actividad(mirar_semana, actividad)
	if not ok:
		_Mostrar_Error_Prioridad()
		return
	Actividad_Terminada()

func Actividad_Terminada():
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

const _TIENDA_CARDS = [
	{"categoria": "Dormir", "clave": "Cama_Basica"},
	{"categoria": "Dormir", "clave": "Cama_Premium"},
	{"categoria": "Comer", "clave": "Mesa_Basica"},
	{"categoria": "Comer", "clave": "Mesa_Premium"},
	{"categoria": "Duchar", "clave": "Ducha_Basica"},
	{"categoria": "Duchar", "clave": "Ducha_Premium"},
]

var _tienda_estilo_normal: StyleBoxFlat = null
var _tienda_estilo_owned: StyleBoxFlat = null
var _tienda_estilo_selected: StyleBoxFlat = null


func _Inicializar_Tienda_Estilos():
	if _tienda_estilo_normal != null:
		return
	_tienda_estilo_normal = StyleBoxFlat.new()
	_tienda_estilo_normal.bg_color = Color(1, 1, 1, 0.95)
	_tienda_estilo_normal.border_color = Color(0.7, 0.7, 0.72, 1)
	_tienda_estilo_normal.border_width_left = 3
	_tienda_estilo_normal.border_width_top = 3
	_tienda_estilo_normal.border_width_right = 3
	_tienda_estilo_normal.border_width_bottom = 3
	_tienda_estilo_normal.corner_radius_top_left = 16
	_tienda_estilo_normal.corner_radius_top_right = 16
	_tienda_estilo_normal.corner_radius_bottom_left = 16
	_tienda_estilo_normal.corner_radius_bottom_right = 16

	_tienda_estilo_owned = StyleBoxFlat.new()
	_tienda_estilo_owned.bg_color = Color(0.93, 0.97, 1, 0.95)
	_tienda_estilo_owned.border_color = Color(0.15, 0.55, 0.85, 1)
	_tienda_estilo_owned.border_width_left = 4
	_tienda_estilo_owned.border_width_top = 4
	_tienda_estilo_owned.border_width_right = 4
	_tienda_estilo_owned.border_width_bottom = 4
	_tienda_estilo_owned.corner_radius_top_left = 16
	_tienda_estilo_owned.corner_radius_top_right = 16
	_tienda_estilo_owned.corner_radius_bottom_left = 16
	_tienda_estilo_owned.corner_radius_bottom_right = 16

	_tienda_estilo_selected = StyleBoxFlat.new()
	_tienda_estilo_selected.bg_color = Color(0.9, 1, 0.92, 0.95)
	_tienda_estilo_selected.border_color = Color(0.18, 0.7, 0.25, 1)
	_tienda_estilo_selected.border_width_left = 5
	_tienda_estilo_selected.border_width_top = 5
	_tienda_estilo_selected.border_width_right = 5
	_tienda_estilo_selected.border_width_bottom = 5
	_tienda_estilo_selected.corner_radius_top_left = 16
	_tienda_estilo_selected.corner_radius_top_right = 16
	_tienda_estilo_selected.corner_radius_bottom_left = 16
	_tienda_estilo_selected.corner_radius_bottom_right = 16


func _Actualizar_Tienda_UI():
	_Inicializar_Tienda_Estilos()
	for entry in _TIENDA_CARDS:
		_Actualizar_Card_Tienda(entry["categoria"], entry["clave"])


func _Actualizar_Card_Tienda(categoria: String, clave: String):
	var card = get_node_or_null("Tienda/Objetos_" + categoria + "/" + clave)
	if card == null:
		return
	var poseido: bool = Variables_Dinamicas.Objetos_Poseidos.get(clave, false)
	var seleccionado: bool = Variables_Dinamicas.Objeto_Seleccionado.get(categoria, "") == clave

	var hay_otro_poseido_en_categoria := false
	for c in Variables_Dinamicas.Objetos_Poseidos.keys():
		if c == clave:
			continue
		if not Variables_Dinamicas.Objetos_Poseidos[c]:
			continue
		var obj = Variables_Estaticas.Catalogo_Objetos.get(c, null)
		if obj != null and obj.afecta_a == categoria:
			hay_otro_poseido_en_categoria = true
			break

	var estilo
	if seleccionado:
		estilo = _tienda_estilo_selected
	elif poseido:
		estilo = _tienda_estilo_owned
	else:
		estilo = _tienda_estilo_normal
	card.add_theme_stylebox_override("panel", estilo)

	card.get_node("Comprar").visible = not poseido
	card.get_node("Vender").visible = poseido and not seleccionado and hay_otro_poseido_en_categoria
	card.get_node("Elegir").visible = poseido and not seleccionado
	card.get_node("En_Uso").visible = seleccionado


func _on_perfil_button_pressed():
	Detener_Blink()
	Gestionar_Visibilidad.Visibilizar_Perfil(self)
	_on_perfil_tab_mensajes_pressed()

# ---------------- Pestañas del perfil ----------------

func _on_perfil_tab_info_pressed():
	$Pantalla_Mensajes/Panel_Info.visible = true
	$Pantalla_Mensajes/Lista_Mensajes.visible = false
	$Pantalla_Mensajes/Panel_Apuntes.visible = false
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Info()

func _on_perfil_tab_mensajes_pressed():
	$Pantalla_Mensajes/Panel_Info.visible = false
	$Pantalla_Mensajes/Lista_Mensajes.visible = true
	$Pantalla_Mensajes/Panel_Apuntes.visible = false
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Lista_Mensajes()

func _on_perfil_tab_apuntes_pressed():
	$Pantalla_Mensajes/Panel_Info.visible = false
	$Pantalla_Mensajes/Lista_Mensajes.visible = false
	$Pantalla_Mensajes/Panel_Apuntes.visible = true
	$Pantalla_Mensajes/Contenido_Mensaje.visible = false
	_Renderizar_Apuntes()

# ---------------- Tab Info ----------------

func _Renderizar_Info():
	var vbox = $Pantalla_Mensajes/Panel_Info/Scroll_Info/VBox_Info
	for child in vbox.get_children():
		child.queue_free()

	var edad = 18 + (Variables_Dinamicas.Minute_Day - Variables_Estaticas.First_Time_Minute_Day) / 7
	var personalidad = Variables_Estaticas.Personalidad.replace("_", " ")

	_Info_Seccion(vbox, "PERSONAJE")
	_Info_Fila(vbox, "Edad", str(edad) + " años")
	_Info_Fila(vbox, "Personalidad", personalidad)
	_Info_Fila(vbox, "Dinero", str(int(Variables_Dinamicas.Dinero)) + " €")

	_Info_Seccion(vbox, "PROGRESO")
	_Info_Fila(vbox, "Deporte", str(Variables_Dinamicas.Progreso[0]) + " / 100")
	_Info_Fila(vbox, "Académico", str(Variables_Dinamicas.Progreso[1]) + " / 100")
	_Info_Fila(vbox, "Manualidades", str(Variables_Dinamicas.Progreso[2]) + " / 100")
	_Info_Fila(vbox, "Inversiones", str(Variables_Dinamicas.Progreso_Inversion) + " / 100")

	_Info_Seccion(vbox, "HABILIDADES INNATAS")
	var nombres_hab = ["Deporte", "Inteligencia", "Destreza manual", "Memoria", "Liderazgo", "Paciencia"]
	for i in range(min(nombres_hab.size(), Variables_Estaticas.Habilidades.size())):
		_Info_Fila(vbox, nombres_hab[i], str(Variables_Estaticas.Habilidades[i]) + " / 100")

func _Info_Seccion(vbox: VBoxContainer, titulo: String):
	var label = Label.new()
	label.text = titulo
	label.custom_minimum_size = Vector2(0, 50)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.35, 1))
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	vbox.add_child(label)

func _Info_Fila(vbox: VBoxContainer, clave: String, valor: String):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 55)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.2, 0.25, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	hbox.add_theme_stylebox_override("panel", style)

	var lbl_clave = Label.new()
	lbl_clave.text = "  " + clave
	lbl_clave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_clave.add_theme_font_size_override("font_size", 24)
	lbl_clave.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 1))
	lbl_clave.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var lbl_valor = Label.new()
	lbl_valor.text = valor + "  "
	lbl_valor.add_theme_font_size_override("font_size", 24)
	lbl_valor.add_theme_color_override("font_color", Color(0.98, 0.98, 1, 1))
	lbl_valor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	hbox.add_child(lbl_clave)
	hbox.add_child(lbl_valor)
	vbox.add_child(hbox)

# ---------------- Tab Mensajes ----------------

func _Renderizar_Lista_Mensajes():
	var vbox = $Pantalla_Mensajes/Lista_Mensajes/VBoxContainer
	for child in vbox.get_children():
		child.queue_free()

	var mensajes_ordenados = Variables_Dinamicas.Mensajes.duplicate()
	mensajes_ordenados.sort_custom(func(a, b): return a.minuto > b.minuto)

	var style_leido = StyleBoxFlat.new()
	style_leido.bg_color = Color(0.18, 0.2, 0.25, 1)
	var style_no_leido = StyleBoxFlat.new()
	style_no_leido.bg_color = Color(0.28, 0.32, 0.4, 1)
	style_no_leido.border_width_left = 3
	style_no_leido.border_color = Color(0.98, 0.92, 0.35, 1)

	for i in range(mensajes_ordenados.size()):
		var mensaje = mensajes_ordenados[i]
		var indice_original = Variables_Dinamicas.Mensajes.find(mensaje)
		var btn = Button.new()
		var fecha_hora = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(mensaje.minuto)
		var indicador = "" if mensaje.leido else "● "
		btn.text = indicador + fecha_hora + "  —  " + mensaje.titulo
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(710, 65)
		btn.add_theme_font_size_override("font_size", 22)
		if mensaje.leido:
			btn.add_theme_stylebox_override("normal", style_leido)
			btn.add_theme_stylebox_override("hover", style_leido)
		else:
			btn.add_theme_stylebox_override("normal", style_no_leido)
			btn.add_theme_stylebox_override("hover", style_no_leido)
		btn.pressed.connect(_Mostrar_Mensaje.bind(indice_original))
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
	Gestionar_Visibilidad.Quitar_Todo(self)

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
		var año = int(String(item.libro).replace("Anio_", ""))
		grid.add_child(_Crear_Miniatura_Libro(item.carrera, año))


func _Crear_Miniatura_Libro(carrera: Carrera, año: int) -> Control:
	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 190)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = "💻"
	btn.add_theme_font_size_override("font_size", 58)
	btn.add_theme_color_override("font_color", Color(0.96, 0.84, 0.54))

	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.49, 0.12, 0.12)
	sn.corner_radius_top_left = 3
	sn.corner_radius_top_right = 7
	sn.corner_radius_bottom_right = 7
	sn.corner_radius_bottom_left = 3
	sn.border_width_left = 12
	sn.border_color = Color(0.10, 0.03, 0.03)
	btn.add_theme_stylebox_override("normal", sn)

	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.58, 0.16, 0.16)
	sh.corner_radius_top_left = 3
	sh.corner_radius_top_right = 7
	sh.corner_radius_bottom_right = 7
	sh.corner_radius_bottom_left = 3
	sh.border_width_left = 12
	sh.border_color = Color(0.10, 0.03, 0.03)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", sh)

	btn.pressed.connect(_Abrir_Libro.bind(carrera, año))
	outer.add_child(btn)

	var lbl = Label.new()
	lbl.text = carrera.nombre + " · Año " + str(año)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.84, 0.95))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(lbl)

	return outer


func _Abrir_Libro(carrera: Carrera, año: int):
	var paginas = _Parsear_Libro(año)
	var lector_script = load("res://Scripts/GUI/Escena_Principal/Lector_Libro.gd")
	var lector = CanvasLayer.new()
	lector.set_script(lector_script)
	add_child(lector)
	lector.configurar(paginas, carrera.nombre, año)


func _Parsear_Libro(año: int) -> Array:
	var paginas = []
	var ruta = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_ing_informatica_anio%d.txt" % año
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
	_Actualizar_Tienda_UI()


func _on_tienda_flecha_atras_pressed():
	Gestionar_Visibilidad.Quitar_Todo(self)


func _on_tab_dormir_pressed():
	Gestionar_Visibilidad.Mostrar_Categoria_Tienda(self, "Dormir")


func _on_tab_comer_pressed():
	Gestionar_Visibilidad.Mostrar_Categoria_Tienda(self, "Comer")


func _on_tab_duchar_pressed():
	Gestionar_Visibilidad.Mostrar_Categoria_Tienda(self, "Duchar")


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


func _on_comprar_cama_basica_pressed(): _Tienda_Comprar("Cama_Basica")
func _on_vender_cama_basica_pressed(): _Tienda_Vender("Cama_Basica")
func _on_elegir_cama_basica_pressed(): _Tienda_Elegir("Dormir", "Cama_Basica")
func _on_comprar_cama_premium_pressed(): _Tienda_Comprar("Cama_Premium")
func _on_vender_cama_premium_pressed(): _Tienda_Vender("Cama_Premium")
func _on_elegir_cama_premium_pressed(): _Tienda_Elegir("Dormir", "Cama_Premium")
func _on_comprar_mesa_basica_pressed(): _Tienda_Comprar("Mesa_Basica")
func _on_vender_mesa_basica_pressed(): _Tienda_Vender("Mesa_Basica")
func _on_elegir_mesa_basica_pressed(): _Tienda_Elegir("Comer", "Mesa_Basica")
func _on_comprar_mesa_premium_pressed(): _Tienda_Comprar("Mesa_Premium")
func _on_vender_mesa_premium_pressed(): _Tienda_Vender("Mesa_Premium")
func _on_elegir_mesa_premium_pressed(): _Tienda_Elegir("Comer", "Mesa_Premium")
func _on_comprar_ducha_basica_pressed(): _Tienda_Comprar("Ducha_Basica")
func _on_vender_ducha_basica_pressed(): _Tienda_Vender("Ducha_Basica")
func _on_elegir_ducha_basica_pressed(): _Tienda_Elegir("Duchar", "Ducha_Basica")
func _on_comprar_ducha_premium_pressed(): _Tienda_Comprar("Ducha_Premium")
func _on_vender_ducha_premium_pressed(): _Tienda_Vender("Ducha_Premium")
func _on_elegir_ducha_premium_pressed(): _Tienda_Elegir("Duchar", "Ducha_Premium")


# ---------------- Sistema de Carreras Universitarias ----------------

var _dialog_resultado_examen: AcceptDialog = null

const _MODAL_EXAMEN_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Examen.gd")
const _MODAL_SELECCIONAR_EXAMEN_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Examen.gd")
const _LECTOR_LIBROS_SCRIPT = preload("res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Lector_Libros.gd")

const _DIAS_NOMBRES = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sab", "Dom"]

func _En_Ventana_Examen(carrera: Carrera) -> bool:
	if carrera.hora_examen_dia < 0 or not carrera.matriculado:
		return false
	var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
	if dia_semana_actual != carrera.hora_examen_dia:
		return false
	var minuto_del_dia = Variables_Dinamicas.Minute_Minute
	var hora_inicio = carrera.hora_examen_inicio
	return minuto_del_dia >= hora_inicio and minuto_del_dia < hora_inicio + 60

func _on_carrera_accion_pressed():
	var carrera = Variables_Dinamicas.Carrera_Actual

	# Sin carrera: crear e iniciar ciclo
	if carrera == null:
		carrera = Carrera_Ingenieria_Informatica.new()
		Variables_Dinamicas.Carrera_Actual = carrera
		Guardar_Variables_Dinamicas.save_game()
		_Actualizar_Pantalla_Carrera()
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

	# Matricularse (L-Ma) o Prematricularse (Mi-Do)
	if not carrera.matriculado and not carrera.prematriculado:
		var dia_semana = Variables_Dinamicas.Minute_Day % 7
		var es_matricula_directa = dia_semana <= 1
		_Abrir_Modal_Horario(carrera, es_matricula_directa)

func _Abrir_Modal_Horario(carrera: Carrera, es_matricula_directa: bool):
	var modal = _MODAL_SELECCIONAR_EXAMEN_SCRIPT.new()
	add_child(modal)
	modal.examen_programado.connect(_on_horario_elegido.bind(carrera, es_matricula_directa))
	modal.popup_centered()

func _on_horario_elegido(dia: int, hora_minutos: int, carrera: Carrera, es_matricula_directa: bool):
	carrera.hora_examen_dia = dia
	carrera.hora_examen_inicio = hora_minutos

	if es_matricula_directa:
		# Matriculación: 500€ inmediatos, bloqueado
		Variables_Dinamicas.Dinero -= carrera.costo_matricula_anual
		carrera.dinero_matricula_gastado += carrera.costo_matricula_anual
		carrera.matriculado = true
		carrera.prematriculado = false
		Actividades.Escribir_Examen_En_Matriz(carrera)
	else:
		# Prematriculación: gratis, flexible hasta el Lunes 00:00
		carrera.prematriculado = true
		carrera.matriculado = false

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
	if _dialog_resultado_examen == null:
		_dialog_resultado_examen = AcceptDialog.new()
		_dialog_resultado_examen.ok_button_text = "Entendido"
		_dialog_resultado_examen.confirmed.connect(_on_resultado_confirmado)
		add_child(_dialog_resultado_examen)

	var aprobado = carrera.ultimo_resultado_aprobado
	var nota = carrera.ultima_nota_final
	var estado = "APROBADO" if aprobado else "SUSPENDIDO"
	if carrera.completada:
		_dialog_resultado_examen.title = "Carrera Completada"
		_dialog_resultado_examen.dialog_text = (
			"Nota final: %.1f/100\n\n%s\n\n🎓 Has completado la carrera.\nBonus: +%.0f€" % [
				nota, estado, Sistema_Examenes.BONUS_DINERO_CARRERA_COMPLETADA
			]
		)
	elif aprobado:
		_dialog_resultado_examen.title = "Resultado del Examen"
		_dialog_resultado_examen.dialog_text = (
			"Nota final: %.1f/100\n\n%s\nAvanças al Año %d." % [nota, estado, carrera.año_actual]
		)
	else:
		_dialog_resultado_examen.title = "Resultado del Examen"
		_dialog_resultado_examen.dialog_text = (
			"Nota final: %.1f/100\n\n%s\nPuedes volver a intentarlo (500€)." % [nota, estado]
		)
	_dialog_resultado_examen.popup_centered(Vector2i(500, 280))

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

var _ventana_invertir: Window = null
var _label_invertir: Label = null
var _input_cantidad_invertir: LineEdit = null
var _dialog_retirar: ConfirmationDialog = null

func _on_economia_bolsa_pressed():
	if Variables_Dinamicas.Esta_Invirtiendo:
		_Mostrar_Confirmacion_Retirar()
	else:
		_Mostrar_Ventana_Invertir()

func _Mostrar_Ventana_Invertir():
	if _ventana_invertir == null:
		_Crear_Ventana_Invertir()
	_label_invertir.text = "Tienes %d€. ¿Cuánto quieres invertir en bolsa?\n(Nota: la salud mental actual quedará registrada)" % int(Variables_Dinamicas.Dinero)
	_input_cantidad_invertir.text = ""
	_ventana_invertir.popup_centered()

func _Crear_Ventana_Invertir():
	_ventana_invertir = Window.new()
	_ventana_invertir.title = "Invertir en Bolsa"
	_ventana_invertir.exclusive = true
	_ventana_invertir.size = Vector2i(520, 260)
	_ventana_invertir.close_requested.connect(func(): _ventana_invertir.visible = false)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	vbox.offset_left = 15
	vbox.offset_right = -15
	vbox.offset_top = 15
	vbox.offset_bottom = -15

	_label_invertir = Label.new()
	_label_invertir.add_theme_font_size_override("font_size", 21)
	_label_invertir.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_label_invertir)

	_input_cantidad_invertir = LineEdit.new()
	_input_cantidad_invertir.custom_minimum_size = Vector2(0, 55)
	_input_cantidad_invertir.placeholder_text = "Cantidad en €"
	_input_cantidad_invertir.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_input_cantidad_invertir)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)

	var btn_ok = Button.new()
	btn_ok.text = "Invertir"
	btn_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ok.custom_minimum_size = Vector2(0, 55)
	btn_ok.add_theme_font_size_override("font_size", 22)
	btn_ok.pressed.connect(_Confirmar_Invertir)

	var btn_cancel = Button.new()
	btn_cancel.text = "Cancelar"
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancel.custom_minimum_size = Vector2(0, 55)
	btn_cancel.add_theme_font_size_override("font_size", 22)
	btn_cancel.pressed.connect(func(): _ventana_invertir.visible = false)

	hbox.add_child(btn_ok)
	hbox.add_child(btn_cancel)
	vbox.add_child(hbox)

	panel.add_child(vbox)
	_ventana_invertir.add_child(panel)
	add_child(_ventana_invertir)

func _Confirmar_Invertir():
	var texto = _input_cantidad_invertir.text.strip_edges()
	if not texto.is_valid_float() and not texto.is_valid_int():
		return
	var cantidad = float(texto)
	if cantidad <= 0 or cantidad > Variables_Dinamicas.Dinero:
		return
	Variables_Dinamicas.Dinero -= cantidad
	Variables_Dinamicas.Dinero_Invertido = cantidad
	Variables_Dinamicas.Valor_Inversion = cantidad
	Variables_Dinamicas.Esta_Invirtiendo = true
	Variables_Dinamicas.Salud_Mental_Al_Invertir = int(Variables_Dinamicas.Necesidades_Basicas[1])
	_ventana_invertir.visible = false
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Economia_Si_Visible()
	Actualizar_Dinero()

func _Mostrar_Confirmacion_Retirar():
	if _dialog_retirar == null:
		_dialog_retirar = ConfirmationDialog.new()
		_dialog_retirar.title = "Retirar inversión"
		_dialog_retirar.ok_button_text = "Retirar"
		_dialog_retirar.get_cancel_button().text = "Mantener"
		_dialog_retirar.confirmed.connect(_Confirmar_Retirar)
		add_child(_dialog_retirar)
	var valor = Variables_Dinamicas.Valor_Inversion
	var invertido = Variables_Dinamicas.Dinero_Invertido
	var pct = (valor - invertido) / invertido * 100.0 if invertido > 0 else 0.0
	var signo = "+" if pct >= 0 else ""
	_dialog_retirar.dialog_text = (
		"Inversión actual: %.0f€ (%s%.1f%% respecto a lo invertido).\n¿Quieres retirar el dinero?" % [valor, signo, pct]
	)
	_dialog_retirar.popup_centered(Vector2i(520, 220))

func _Confirmar_Retirar():
	Variables_Dinamicas.Dinero += Variables_Dinamicas.Valor_Inversion
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Dinero_Invertido = 0.0
	Guardar_Variables_Dinamicas.save_game()
	_Actualizar_Pantalla_Economia_Si_Visible()
	Actualizar_Dinero()

# ================================================================
# Helpers de estilo compartidos
# ================================================================

func _Crear_Tarjeta_Boton(texto: String, color_acento: Color) -> Button:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(0, 80)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	_Aplicar_Estilo_Tarjeta(btn, color_acento)
	return btn

func _Aplicar_Estilo_Tarjeta(btn: Button, color_acento: Color):
	var c_oscuro = Color(color_acento.r * 0.22, color_acento.g * 0.22, color_acento.b * 0.22, 1.0)
	var c_hover  = Color(color_acento.r * 0.38, color_acento.g * 0.38, color_acento.b * 0.38, 1.0)
	for nombre in ["normal", "hover", "pressed", "focus", "disabled"]:
		var s = StyleBoxFlat.new()
		match nombre:
			"normal":   s.bg_color = c_oscuro
			"hover":    s.bg_color = c_hover
			"pressed":  s.bg_color = color_acento
			_:          s.bg_color = c_oscuro
		s.border_color        = color_acento
		s.border_width_left   = 5
		s.border_width_right  = 0
		s.border_width_top    = 0
		s.border_width_bottom = 0
		s.set_corner_radius_all(8)
		s.content_margin_left   = 18
		s.content_margin_right  = 18
		s.content_margin_top    = 10
		s.content_margin_bottom = 10
		btn.add_theme_stylebox_override(nombre, s)

func _Crear_Boton_Volver_Panel(parent: Control, callback: Callable):
	var btn = Button.new()
	btn.text = "← Volver"
	btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn.offset_left   = 25
	btn.offset_right  = -25
	btn.offset_top    = -68
	btn.offset_bottom = -14
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90))
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.12, 0.16)
	s.border_color = Color(0.30, 0.32, 0.42)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 15
	s.content_margin_right = 15
	btn.add_theme_stylebox_override("normal", s)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _Crear_Label_Titulo_Panel(texto: String, parent: Control, color: Color):
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl.offset_top    = 68
	lbl.offset_bottom = 112
	parent.add_child(lbl)

# ================================================================
# Pantalla Carrera (tab)
# ================================================================

var _pantalla_carrera: Control = null
var _carrera_status_label: Label = null
var _carrera_action_btn: Button = null
var _carrera_libros_btn: Button = null

func _Crear_Pantalla_Carrera():
	_pantalla_carrera = ColorRect.new()
	_pantalla_carrera.name = "Pantalla_Carrera"
	_pantalla_carrera.color = Color(0.06, 0.07, 0.12, 0.97)
	_pantalla_carrera.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pantalla_carrera.z_index = 5
	_pantalla_carrera.visible = false

	_Crear_Label_Titulo_Panel("CARRERA UNIVERSITARIA", _pantalla_carrera, Color(0.45, 0.80, 1.0))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	vbox.add_theme_constant_override("separation", 14)
	vbox.offset_left   = 25
	vbox.offset_right  = -25
	vbox.offset_top    = 122
	vbox.offset_bottom = 450

	_carrera_status_label = Label.new()
	_carrera_status_label.add_theme_font_size_override("font_size", 20)
	_carrera_status_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
	_carrera_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_carrera_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_carrera_status_label)

	_carrera_action_btn = _Crear_Tarjeta_Boton("", Color(0.20, 0.55, 0.95))
	_carrera_action_btn.pressed.connect(_on_carrera_accion_pressed)
	vbox.add_child(_carrera_action_btn)

	_carrera_libros_btn = _Crear_Tarjeta_Boton("Leer Apuntes", Color(0.55, 0.35, 0.08))
	_carrera_libros_btn.pressed.connect(_on_libros_button_pressed)
	vbox.add_child(_carrera_libros_btn)

	_pantalla_carrera.add_child(vbox)
	_Crear_Boton_Volver_Panel(_pantalla_carrera, func(): Gestionar_Visibilidad.Quitar_Todo(self))
	add_child(_pantalla_carrera)

func _on_carrera_tab_pressed():
	Gestionar_Visibilidad.Quitar_Todo(self)
	Gestionar_Visibilidad.Recursivo_Visibilizar(_pantalla_carrera)
	_Actualizar_Pantalla_Carrera()

func _Actualizar_Pantalla_Carrera():
	if _carrera_action_btn == null:
		return
	var carrera = Variables_Dinamicas.Carrera_Actual

	if carrera == null:
		_carrera_status_label.text = "No tienes ninguna carrera activa."
		_carrera_action_btn.text = "Matricularse en Ingeniería Informática"
		_carrera_action_btn.disabled = false
		_carrera_libros_btn.visible = Variables_Dinamicas.Carreras_Completadas.size() > 0
		return

	_carrera_libros_btn.visible = (
		carrera.libros_desbloqueados.size() > 0 or
		Variables_Dinamicas.Carreras_Completadas.size() > 0
	)

	if carrera.completada and not carrera.fin_de_semana_procesado:
		_carrera_status_label.text = "Has completado la carrera."
		_carrera_action_btn.text = "Carrera completada"
		_carrera_action_btn.disabled = true
		return

	if carrera.fin_de_semana_procesado:
		var estado = "APROBADO" if carrera.ultimo_resultado_aprobado else "SUSPENDIDO"
		_carrera_status_label.text = "Hay un resultado pendiente de revisar."
		_carrera_action_btn.text = "Ver resultado: %s (%.0f)" % [estado, carrera.ultima_nota_final]
		_carrera_action_btn.disabled = false
		return

	if carrera.matriculado and _En_Ventana_Examen(carrera):
		if carrera.examen_realizado_esta_semana:
			_carrera_status_label.text = "Examen enviado. Esperando resultado del fin de semana..."
			_carrera_action_btn.text = "Examen entregado"
			_carrera_action_btn.disabled = true
		else:
			_carrera_status_label.text = "La ventana de examen está abierta ahora."
			_carrera_action_btn.text = "Hacer Examen AHORA"
			_carrera_action_btn.disabled = false
		return

	if carrera.matriculado:
		var hora = carrera.hora_examen_inicio / 60
		_carrera_status_label.text = "Año %d de %d · Progreso: %d%%\nExamen: %s a las %02d:00" % [
			carrera.año_actual, carrera.años_totales,
			int(carrera.progreso_actual),
			_DIAS_NOMBRES[carrera.hora_examen_dia], hora
		]
		_carrera_action_btn.text = "Esperando el examen..."
		_carrera_action_btn.disabled = true
		return

	if carrera.prematriculado:
		var hora = carrera.hora_examen_inicio / 60
		_carrera_status_label.text = "Prematrícula: %s %02d:00 (puedes cambiar el horario)" % [
			_DIAS_NOMBRES[carrera.hora_examen_dia], hora
		]
		_carrera_action_btn.text = "Cambiar horario de examen"
		_carrera_action_btn.disabled = false
		return

	var dia_semana = Variables_Dinamicas.Minute_Day % 7
	if dia_semana <= 1:
		_carrera_status_label.text = "Hoy es Lunes o Martes: puedes matricularte directamente."
		_carrera_action_btn.text = "Matricularse (500€)"
		_carrera_action_btn.disabled = Variables_Dinamicas.Dinero < 500
	else:
		_carrera_status_label.text = "Solo puedes prematricularte; la matrícula se formaliza el Lunes."
		_carrera_action_btn.text = "Prematricularse (gratis)"
		_carrera_action_btn.disabled = false

func _Actualizar_Pantalla_Carrera_Si_Visible():
	if _pantalla_carrera != null and _pantalla_carrera.is_visible_in_tree():
		_Actualizar_Pantalla_Carrera()

# ================================================================
# Pantalla Economía (tab)
# ================================================================

var _pantalla_economia: Control = null
var _economia_alquiler_btn: Button = null
var _economia_bolsa_btn: Button = null
var _dialog_volver_a_casa: ConfirmationDialog = null
var _dialog_alquiler_info: AcceptDialog = null

func _Crear_Pantalla_Economia():
	_pantalla_economia = ColorRect.new()
	_pantalla_economia.name = "Pantalla_Economia"
	_pantalla_economia.color = Color(0.06, 0.07, 0.12, 0.97)
	_pantalla_economia.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pantalla_economia.z_index = 5
	_pantalla_economia.visible = false

	_Crear_Label_Titulo_Panel("ECONOMÍA", _pantalla_economia, Color(1.0, 0.82, 0.22))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	vbox.add_theme_constant_override("separation", 14)
	vbox.offset_left   = 25
	vbox.offset_right  = -25
	vbox.offset_top    = 122
	vbox.offset_bottom = 500

	_economia_alquiler_btn = _Crear_Tarjeta_Boton("", Color(0.15, 0.55, 0.25))
	_economia_alquiler_btn.pressed.connect(_on_economia_alquiler_pressed)
	vbox.add_child(_economia_alquiler_btn)

	_economia_bolsa_btn = _Crear_Tarjeta_Boton("", Color(0.10, 0.40, 0.75))
	_economia_bolsa_btn.pressed.connect(_on_economia_bolsa_pressed)
	vbox.add_child(_economia_bolsa_btn)

	var tienda_btn = _Crear_Tarjeta_Boton("Tienda de objetos", Color(0.60, 0.28, 0.05))
	tienda_btn.pressed.connect(func():
		Gestionar_Visibilidad.Quitar_Todo(self)
		Gestionar_Visibilidad.Visibilizar_Tienda(self)
	)
	vbox.add_child(tienda_btn)

	_pantalla_economia.add_child(vbox)
	_Crear_Boton_Volver_Panel(_pantalla_economia, func(): Gestionar_Visibilidad.Quitar_Todo(self))
	add_child(_pantalla_economia)
	_Actualizar_Pantalla_Economia()

func _on_economia_button_pressed():
	Gestionar_Visibilidad.Quitar_Todo(self)
	Gestionar_Visibilidad.Recursivo_Visibilizar(_pantalla_economia)
	_Actualizar_Pantalla_Economia()

func _on_economia_alquiler_pressed():
	var dinero   = Variables_Dinamicas.Dinero
	var alquiler = Variables_Estaticas.ALQUILER_SEMANAL

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
	_dialog_alquiler_info.dialog_text = (
		"Alquiler: %d€/semana\nDinero actual: %.0f€" % [alquiler, dinero]
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
	if Variables_Dinamicas.En_La_Calle:
		var dinero = Variables_Dinamicas.Dinero
		var alquiler = Variables_Estaticas.ALQUILER_SEMANAL
		if dinero >= alquiler:
			_economia_alquiler_btn.text = "Alquiler: en la calle · Volver (tienes %.0f€)" % dinero
			_Aplicar_Estilo_Tarjeta(_economia_alquiler_btn, Color(0.85, 0.50, 0.05))
		else:
			_economia_alquiler_btn.text = "Alquiler: EN LA CALLE · Necesitas %d€ (tienes %.0f€)" % [alquiler, dinero]
			_Aplicar_Estilo_Tarjeta(_economia_alquiler_btn, Color(0.80, 0.12, 0.12))
	else:
		_economia_alquiler_btn.text = "Alquiler %d€/sem  ·  Tienes %.0f€" % [
			Variables_Estaticas.ALQUILER_SEMANAL, Variables_Dinamicas.Dinero
		]
		_Aplicar_Estilo_Tarjeta(_economia_alquiler_btn, Color(0.15, 0.55, 0.25))

	if Variables_Dinamicas.Esta_Invirtiendo:
		var valor    = Variables_Dinamicas.Valor_Inversion
		var invertido = Variables_Dinamicas.Dinero_Invertido
		var pct  = (valor - invertido) / invertido * 100.0 if invertido > 0 else 0.0
		var signo = "+" if pct >= 0 else ""
		_economia_bolsa_btn.text = "Bolsa: %.0f€  (%s%.1f%%)" % [valor, signo, pct]
		var color_bolsa = Color(0.10, 0.65, 0.30) if pct >= 0 else Color(0.75, 0.15, 0.15)
		_Aplicar_Estilo_Tarjeta(_economia_bolsa_btn, color_bolsa)
	else:
		_economia_bolsa_btn.text = "Invertir en Bolsa"
		_Aplicar_Estilo_Tarjeta(_economia_bolsa_btn, Color(0.10, 0.40, 0.75))

func _Actualizar_Pantalla_Economia_Si_Visible():
	if _pantalla_economia != null and _pantalla_economia.is_visible_in_tree():
		_Actualizar_Pantalla_Economia()
