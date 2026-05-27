
extends Node

# Called when the node enters the scene tree for the first time.



var mirar_semana

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
func _ready():
	Inicializar_Otros_Scripts()
	$Alquiler_Button.pressed.connect(Callable(self, "_on_alquiler_button_pressed"))
	Actualizar_Texto_Alquiler()
	if (Variables_Estaticas.First_Time):
		first_time_logica.First_Time_Function()
		mirar_semana=1
		Guardar_Variables_Estaticas.save_game()
		Guardar_Variables_Dinamicas.save_game()
		Actualizar_Texto_Alquiler()

	else:
		Gestionar_Visibilidad.Quitar_Todo(self)
		mirar_semana=Variables_Dinamicas.Minute_Day/7
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Variables_Estaticas.First_Time == false:
		var minutos_pendientes = _Minutos_Pendientes_Por_Procesar()
		if minutos_pendientes > 0:
			Actividades.Actualizar_Horario(minutos_pendientes)
			Guardar_Variables_Dinamicas.save_game()
		Actualizar_Progreso()
		Actualizar_Dinero()
		necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)
		if $Habilidades.visible:
			Actualizar_Habilidades()


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
	Actualizar_Texto_Alquiler()

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


const _NOMBRES_HABILIDADES: Array = ["DEPORTE", "INTELIGENCIA", "DESTREZA", "MEMORIA", "LIDERAZGO", "PACIENCIA"]
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
	mirar_semana+=1
	actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
	actividades_bloque_gui.Agregar_Bloques(mirar_semana,self)
	if mirar_semana==82:
		print("aa")
func _on_anterior_semana_pressed() -> void:
	if mirar_semana!=0:
		mirar_semana-=1
	actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
	actividades_bloque_gui.Agregar_Bloques(mirar_semana,self)


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
	actividades_bloque_gui.Agregar_Bloques(mirar_semana,self)
	Gestionar_Visibilidad.Visibilizar_Horario_Semanal(self)


func _on_calendario_boton_pressed() -> void:
	pass # Replace with function body.


func _on_temporales_pressed() -> void:
	Iniciar_Bloques_Actividad()


func Opciones_Actividades_Fijas() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Fijas", self)


func Opciones_Actividades_Trabajo() -> void:
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Trabajo", self)


func _on_comida_rapida_pressed() -> void:
	Trabajo.Trabajar_En_Comida_Rapida()
	Guardar_Variables_Dinamicas.save_game()
	Actividad_Terminada()



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


func Crear_Actividad(actividad):
	actividades_reloj_gui.horario.Crear_Actividad(mirar_semana,actividad)
	Actividad_Terminada()

func Actividad_Terminada():
	Detener_Blink()
	_on_boton_actividades_pressed()
	# Solo limpiar el calendario si el flujo pasó por él (Temporales). En el flujo
	# de Fijas (Trabajo → Comida Rápida) nunca se inicializó bloque_columna.
	if actividades_bloque_gui.bloque_columna != null:
		actividades_bloque_gui.bloque_columna.limpiar_horas_del_horario()


func Actualizar_Texto_Alquiler():
	if Variables_Dinamicas.En_La_Calle:
		$Alquiler_Button.text = "En la calle"
	else:
		$Alquiler_Button.text = "En alquiler"


func _on_alquiler_button_pressed():
	if Variables_Dinamicas.En_La_Calle:
		# Intenta volver a alquiler
		if Variables_Dinamicas.Dinero >= Variables_Estaticas.ALQUILER_SEMANAL:
			Actividades.Volver_A_Alquiler()
			Actualizar_Texto_Alquiler()
			Guardar_Variables_Dinamicas.save_game()
		# Si no tiene dinero, no hace nada (se queda en la calle)
	else:
		# Intenta ir a la calle (requiere confirmación)
		var dialogo = ConfirmationDialog.new()
		dialogo.dialog_text = "¿Estás seguro de que quieres irte a la calle?\n\nTus necesidades básicas se verán afectadas."
		add_child(dialogo)
		var resultado = await dialogo.confirmed
		if resultado:
			Actividades.Ir_A_La_Calle()
			Actualizar_Texto_Alquiler()
			Guardar_Variables_Dinamicas.save_game()
		dialogo.queue_free()
