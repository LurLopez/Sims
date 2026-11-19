extends Node

class_name SeleccionarHorarioReloj

var dia_inicio_texto
var hora_inicio_texto
var minuto_inicio_texto

var dia_inicio_arriba
var dia_inicio_abajo
var hora_inicio_arriba
var hora_inicio_abajo
var minuto_inicio_arriba
var minuto_inicio_abajo 

var dia_final_texto
var hora_final_texto
var minuto_final_texto

var dia_final_arriba
var dia_final_abajo
var hora_final_arriba
var hora_final_abajo
var minuto_final_arriba
var minuto_final_abajo 

var semana
func inicializar(raiz):
	dia_inicio_texto=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Dia_Vbox/Dia_Inicio")
	hora_inicio_texto=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Hora_Vbox/Hora_Inicio")
	minuto_inicio_texto=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Minuto_Vbox/Minuto_Inicio")
	
	dia_inicio_arriba=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Dia_Vbox/Boton_Arriba")
	dia_inicio_abajo=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Dia_Vbox/Boton_Abajo")
	hora_inicio_arriba=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Hora_Vbox/Boton_Arriba")
	hora_inicio_abajo=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Hora_Vbox/Boton_Abajo")
	minuto_inicio_arriba=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Minuto_Vbox/Boton_Arriba")
	minuto_inicio_abajo=raiz.get_node("Actividades/Seleccionar_Horario/Inicio/Inicio_Hbox/Minuto_Vbox/Boton_Abajo")
	
	dia_final_texto=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Dia_Vbox/Dia_Final")
	hora_final_texto=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Hora_Vbox/Hora_Final")
	minuto_final_texto=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Minuto_Vbox/Minuto_Final")
	
	dia_final_arriba=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Dia_Vbox/Boton_Arriba")
	dia_final_abajo=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Dia_Vbox/Boton_Abajo")
	hora_final_arriba=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Hora_Vbox/Boton_Arriba")
	hora_final_abajo=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Hora_Vbox/Boton_Abajo")
	minuto_final_arriba=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Minuto_Vbox/Boton_Arriba")
	minuto_final_abajo=raiz.get_node("Actividades/Seleccionar_Horario/Final/Final_Hbox/Minuto_Vbox/Boton_Abajo")

func _init(s=0):
	pass

func dia_inicio_a_int():
	return Funciones_Globales.Dia_Reducido_A_Numero(dia_inicio_texto.text)

func dia_final_a_int():
	return Funciones_Globales.Dia_Reducido_A_Numero(dia_final_texto.text)


### CAMBIAR TEXTO DEL GUI CUANDO PULSAS EL BOTON
#INICIO
func Inicio_Minuto_Arriba():
	var Minuto_Int=minuto_inicio_texto.text.to_int()
	if Minuto_Int==55:
		Minuto_Int=00
	else: Minuto_Int+=5
	minuto_inicio_texto.text=str(Minuto_Int)
	
func Inicio_Minuto_Abajo() -> void:
	var Minuto_Int=minuto_inicio_texto.text.to_int()
	if Minuto_Int==0:
		Minuto_Int=55
	else: Minuto_Int-=5
	minuto_inicio_texto.text=str(Minuto_Int)

func Inicio_Hora_Arriba() -> void:
	var Hora_Int=hora_inicio_texto.text.to_int()
	if Hora_Int==23:
		Hora_Int=0
	else: Hora_Int+=1
	hora_inicio_texto.text=str(Hora_Int)

func Inicio_Hora_Abajo() -> void:
	var Hora_Int=hora_inicio_texto.text.to_int()
	if Hora_Int==00:
		Hora_Int=23
	else: Hora_Int-=1
	hora_inicio_texto.text=str(Hora_Int)

func Inicio_Dia_Arriba() -> void:
	var Dia_Int=Funciones_Globales.Dia_Reducido_A_Numero(dia_inicio_texto.text)
	if(Dia_Int==6):
		Dia_Int=0
	else: Dia_Int+=1
	dia_inicio_texto.text=Funciones_Globales.Devolver_Dia_Reducido(Dia_Int)

func Inicio_Dia_Abajo() -> void:
	var Dia_Int=Funciones_Globales.Dia_Reducido_A_Numero(dia_inicio_texto.text)
	if(Dia_Int==0):
		Dia_Int=6
	else: Dia_Int-=1
	dia_inicio_texto.text=Funciones_Globales.Devolver_Dia_Reducido(Dia_Int)


##FINAL

func Final_Minuto_Arriba():
	var Minuto_Int=minuto_final_texto.text.to_int()
	if Minuto_Int==55:
		Minuto_Int=00
	else: Minuto_Int+=5
	minuto_final_texto.text=str(Minuto_Int)

func Final_Minuto_Abajo():
	var Minuto_Int=minuto_final_texto.text.to_int()
	if Minuto_Int==0:
		Minuto_Int=55
	else: Minuto_Int-=5
	minuto_final_texto.text=str(Minuto_Int)

func Final_Hora_Arriba():
	var dia_seleccionado_int=Funciones_Globales.Dia_Reducido_A_Numero(dia_final_texto.text)
	var Hora_Int=hora_final_texto.text.to_int()
	if Hora_Int==23 and dia_seleccionado_int!=6:
		Hora_Int=0
	elif Hora_Int==23 and dia_seleccionado_int==6:
		Hora_Int=24
		minuto_final_texto.text="0"
	else:
		Hora_Int=mini(24, Hora_Int+1)
	hora_final_texto.text=str(Hora_Int)

func Final_Hora_Abajo():
	var Hora_Int=hora_final_texto.text.to_int()
	if Hora_Int==00:
		Hora_Int=23
	else: Hora_Int-=1
	hora_final_texto.text=str(Hora_Int)

func Final_Dia_Arriba() -> void:
	var Dia_Int=Funciones_Globales.Dia_Reducido_A_Numero(dia_final_texto.text)
	if(Dia_Int==6):
		Dia_Int=0
	else: Dia_Int+=1
	dia_final_texto.text=Funciones_Globales.Devolver_Dia_Reducido(Dia_Int)

func Final_Dia_Abajo() -> void:
	var hora_seleccionado=hora_final_texto.text
	var Dia_Int=Funciones_Globales.Dia_Reducido_A_Numero(dia_final_texto.text)
	if(Dia_Int==6 and hora_seleccionado==str(24)):
		hora_final_texto.text=str(23)
		minuto_final_texto.text=str(55)
	
	if(Dia_Int==0):
		Dia_Int=6
	else: Dia_Int-=1
	dia_final_texto.text=Funciones_Globales.Devolver_Dia_Reducido(Dia_Int)

func Crear_Actividad(mirar_semana,actividad_seleccionada) -> bool:
	var dia_inicio: int = dia_inicio_a_int()
	var dia_final: int = dia_final_a_int()
	if actividad_seleccionada == "Salir_De_Fiesta":
		# El selector trabaja con días 0..6; para un cruce de medianoche hay que
		# pasar el día siguiente absoluto a _Calcular_Rango (7 = lunes siguiente).
		dia_final = dia_inicio + 1 if _Es_Cruce_Fiesta() else dia_inicio
	elif dia_final == dia_inicio and _Hora_Final_Anterior():
		# Cocinar/Comer también pueden cruzar medianoche.
		dia_final = dia_inicio + 1
	return Actividades.Crear_Actividad_Especifica(mirar_semana,dia_inicio,dia_final,hora_inicio_texto.text.to_int(),hora_final_texto.text.to_int(),minuto_inicio_texto.text.to_int(),minuto_final_texto.text.to_int(),actividad_seleccionada)


func _Hora_Final_Anterior() -> bool:
	var min_ini: int = hora_inicio_texto.text.to_int() * 60 + minuto_inicio_texto.text.to_int()
	var min_fin: int = hora_final_texto.text.to_int() * 60 + minuto_final_texto.text.to_int()
	if min_fin == 1440:
		return false
	return min_fin < min_ini


func _Es_Cruce_Fiesta() -> bool:
	var m_ini: int = hora_inicio_texto.text.to_int() * 60 + minuto_inicio_texto.text.to_int()
	var m_fin: int = hora_final_texto.text.to_int() * 60 + minuto_final_texto.text.to_int()
	if m_fin == 1440:
		# 24:00 es el final del mismo día seleccionado; _Calcular_Rango ya lo trata.
		return false
	return m_ini >= 1080 and m_fin <= 360


func Actualizar_Preview_Fiesta(raiz) -> void:
	var selector = raiz.get_node_or_null("Actividades/Seleccionar_Horario")
	if selector == null:
		return
	var panel := selector.get_node_or_null("Preview_Fiesta") as Panel
	if panel == null:
		panel = _Crear_Panel_Preview(selector)
	if panel == null:
		return

	var dia_ini: int = dia_inicio_a_int()
	var hora_ini: int = hora_inicio_texto.text.to_int()
	var min_ini: int = minuto_inicio_texto.text.to_int()
	var dia_fin: int = dia_final_a_int()
	var hora_fin: int = hora_final_texto.text.to_int()
	var min_fin: int = minuto_final_texto.text.to_int()
	var semana: int = -1
	if raiz.get("mirar_semana") != null:
		semana = int(raiz.mirar_semana)

	var validacion: Dictionary = Actividades.Validar_Horario_Fiesta(
		dia_ini, hora_ini, min_ini, dia_fin, hora_fin, min_fin, semana)

	var lbl_dur := panel.find_child("Preview_Duracion", true, false) as Label
	var lbl_ligar := panel.find_child("Preview_Ligar_Min", true, false) as Label
	var lbl_resacon := panel.find_child("Preview_Resacon_Min", true, false) as Label
	var lbl_acum := panel.find_child("Preview_Acumuladas", true, false) as Label
	var lbl_aviso := panel.find_child("Preview_Aviso", true, false) as Label
	var lbl_motivo := panel.find_child("Preview_Motivo", true, false) as Label
	if lbl_dur == null or lbl_ligar == null or lbl_resacon == null or lbl_acum == null or lbl_aviso == null or lbl_motivo == null:
		return

	if not bool(validacion.get("valido", false)):
		lbl_dur.text = ""
		lbl_ligar.visible = false
		lbl_resacon.visible = false
		lbl_acum.visible = false
		lbl_aviso.visible = false
		lbl_motivo.visible = true
		lbl_motivo.text = str(validacion.get("motivo", ""))
		return

	var duracion: int = int(validacion.get("duracion_min", 0))
	var nb = Variables_Dinamicas.Necesidades_Basicas.duplicate()
	var progreso = Variables_Dinamicas.Progreso.duplicate()
	if nb.size() < 5 or progreso.size() < 3:
		lbl_dur.text = "Duración: %dh %02dm" % [duracion / 60, duracion % 60]
		lbl_ligar.visible = false
		lbl_resacon.visible = false
		lbl_acum.visible = false
		lbl_aviso.visible = false
		lbl_motivo.visible = true
		lbl_motivo.text = "No hay datos de necesidades para calcular la estimación."
		return

	var dia_abs: int = semana * 7 + dia_ini if semana >= 0 else dia_ini
	var edad: int = Variables_Estaticas.Calcular_Edad(dia_abs)
	var dia_noche: int = Actividades.Obtener_Dia_Semana_Noche(dia_abs, hora_ini)
	var sim: Dictionary = Actividades.Simular_Preview_Fiesta(
		nb, progreso, Variables_Estaticas.Personalidad, duracion, edad, dia_noche)

	lbl_dur.text = "Duración: %dh %02dm" % [duracion / 60, duracion % 60]
	lbl_ligar.text = "Por minuto: ligar %s %% al empezar · %s %% al terminar" % [
		_Formatear_Porcentaje(float(sim["pl_inicio"]) * 100.0, 3),
		_Formatear_Porcentaje(float(sim["pl_fin"]) * 100.0, 3)]
	lbl_resacon.text = "Por minuto: resacón %s %% al empezar · %s %% al terminar" % [
		_Formatear_Porcentaje(float(sim["pr_inicio"]) * 100.0, 3),
		_Formatear_Porcentaje(float(sim["pr_fin"]) * 100.0, 3)]
	lbl_acum.text = "Ligar: %s %% · Resacón: %s %% · Nada: %s %%" % [
		_Formatear_Porcentaje(float(sim["p_ligar"]) * 100.0, 1),
		_Formatear_Porcentaje(float(sim["p_resacon"]) * 100.0, 1),
		_Formatear_Porcentaje(float(sim["p_nada"]) * 100.0, 1)]
	lbl_aviso.text = "Estimación según tus necesidades actuales y el desgaste previsto."
	lbl_ligar.visible = true
	lbl_resacon.visible = true
	lbl_acum.visible = true
	lbl_aviso.visible = true
	lbl_motivo.visible = false


func _Formatear_Porcentaje(valor: float, decimales: int) -> String:
	return String.num(valor, decimales).replace(".", ",")


func _Crear_Panel_Preview(selector: Control) -> Panel:
	var panel := Panel.new()
	panel.name = "Preview_Fiesta"
	panel.position = Vector2(16, 174)
	panel.size = Vector2(688, 584)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 2))
	selector.add_child(panel)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 22)
	margen.add_theme_constant_override("margin_bottom", 22)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	v.add_child(cabecera)
	cabecera.add_child(Estilos_UI.badge_icono("party-popper", 44, 22, Color("#d92673"), Color.WHITE, 12))
	var titulo := Estilos_UI.titulo("Salir de fiesta", 22, Estilos_UI.TINTA)
	titulo.name = "Preview_Titulo"
	cabecera.add_child(titulo)

	var dur := Estilos_UI.texto("", 15, Estilos_UI.TINTA_SUAVE, 600)
	dur.name = "Preview_Duracion"
	v.add_child(dur)

	var ligar := Estilos_UI.parrafo("", 13, Estilos_UI.TINTA)
	ligar.name = "Preview_Ligar_Min"
	v.add_child(ligar)

	var resacon := Estilos_UI.parrafo("", 13, Estilos_UI.TINTA)
	resacon.name = "Preview_Resacon_Min"
	v.add_child(resacon)

	var acum := Estilos_UI.texto("", 16, Estilos_UI.TINTA, 700)
	acum.name = "Preview_Acumuladas"
	acum.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(acum)

	var aviso := Estilos_UI.parrafo("", 12, Estilos_UI.TINTA_FANTASMA)
	aviso.name = "Preview_Aviso"
	v.add_child(aviso)

	var motivo := Estilos_UI.parrafo("", 13, Estilos_UI.PELIGRO)
	motivo.name = "Preview_Motivo"
	v.add_child(motivo)

	return panel

func Actualizar_Todo_Contexto():
	Actualizar_Contexto_Inicio()
	Actualizar_Contexto_Final()

func Actualizar_Contexto_Inicio():
	var dia = Funciones_Globales.Dia_Reducido_A_Numero(dia_inicio_texto.text)
	dia_inicio_arriba.text = Funciones_Globales.Devolver_Dia_Reducido((dia + 1) % 7)
	dia_inicio_abajo.text  = Funciones_Globales.Devolver_Dia_Reducido((dia - 1 + 7) % 7)
	var hora = hora_inicio_texto.text.to_int()
	hora_inicio_arriba.text = str((hora + 1) % 24)
	hora_inicio_abajo.text  = str((hora - 1 + 24) % 24)
	var minuto = minuto_inicio_texto.text.to_int()
	minuto_inicio_arriba.text = str((minuto + 5) % 60)
	minuto_inicio_abajo.text  = str((minuto - 5 + 60) % 60)

func Actualizar_Contexto_Final():
	var dia = Funciones_Globales.Dia_Reducido_A_Numero(dia_final_texto.text)
	dia_final_arriba.text = Funciones_Globales.Devolver_Dia_Reducido((dia + 1) % 7)
	dia_final_abajo.text  = Funciones_Globales.Devolver_Dia_Reducido((dia - 1 + 7) % 7)
	var hora = hora_final_texto.text.to_int()
	hora_final_arriba.text = str(min(24, hora + 1))
	hora_final_abajo.text  = str(max(0, hora - 1))
	var minuto = minuto_final_texto.text.to_int()
	minuto_final_arriba.text = str((minuto + 5) % 60)
	minuto_final_abajo.text  = str((minuto - 5 + 60) % 60)


# ============================================================================
# Vista previa de Cocinar / Comer (flujo de dos pasos)
# ============================================================================

func _Duracion_Actual() -> int:
	return Actividades.Calcular_Duracion_Rango(
		dia_inicio_a_int(),
		hora_inicio_texto.text.to_int(),
		minuto_inicio_texto.text.to_int(),
		dia_final_a_int(),
		hora_final_texto.text.to_int(),
		minuto_final_texto.text.to_int())


func _Formatear_Duracion(minutos: int) -> String:
	if minutos >= 60:
		return "%dh %02dm" % [minutos / 60, minutos % 60]
	return "%d min" % minutos


func _Formatear_Euros(valor: float) -> String:
	return String.num(valor, 2).replace(".", ",") + " €"


func _Crear_Panel_Preview_Alimentacion(selector: Control, raiz) -> Panel:
	var panel := Panel.new()
	panel.name = "Preview_Alimentacion"
	panel.position = Vector2(16, 174)
	panel.size = Vector2(688, 584)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE, 1, 2))
	selector.add_child(panel)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 22)
	margen.add_theme_constant_override("margin_bottom", 22)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.name = "Contenido"
	v.add_theme_constant_override("separation", 12)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.name = "Cabecera"
	cabecera.add_theme_constant_override("separation", 12)
	v.add_child(cabecera)
	for cfg in [
		["Preview_Alim_Badge_Cocinar", "flame", Color("#ea580c")],
		["Preview_Alim_Badge_Tupper", "package", Estilos_UI.EXITO],
		["Preview_Alim_Badge_Basura", "utensils-crossed", Estilos_UI.PELIGRO],
	]:
		var b := Estilos_UI.badge_icono(cfg[1], 44, 22, cfg[2], Color.WHITE, 12)
		b.name = cfg[0]
		b.visible = false
		cabecera.add_child(b)
	var titulo := Estilos_UI.titulo("Comer", 22, Estilos_UI.TINTA)
	titulo.name = "Preview_Alim_Titulo"
	cabecera.add_child(titulo)

	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)

	var btn_tupper := Button.new()
	btn_tupper.name = "Tab_Tupper"
	btn_tupper.text = "📦  Comida casera"
	btn_tupper.custom_minimum_size = Vector2(0, 42)
	btn_tupper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tupper.pressed.connect(func(): raiz._Seleccionar_Modo_Comer("Comer_Tupper"))
	tabs.add_child(btn_tupper)

	var btn_basura := Button.new()
	btn_basura.name = "Tab_Basura"
	btn_basura.text = "🍔  Comida rápida"
	btn_basura.custom_minimum_size = Vector2(0, 42)
	btn_basura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_basura.pressed.connect(func(): raiz._Seleccionar_Modo_Comer("Comer_Basura"))
	tabs.add_child(btn_basura)

	var dur := Estilos_UI.texto("", 15, Estilos_UI.TINTA_SUAVE, 600)
	dur.name = "Preview_Alim_Duracion"
	v.add_child(dur)

	var detalle := Estilos_UI.parrafo("", 13, Estilos_UI.TINTA)
	detalle.name = "Preview_Alim_Detalle"
	v.add_child(detalle)

	var coste := Estilos_UI.texto("", 17, Estilos_UI.TINTA, 700)
	coste.name = "Preview_Alim_Coste"
	coste.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(coste)

	var aviso := Estilos_UI.parrafo("", 12, Estilos_UI.TINTA_FANTASMA)
	aviso.name = "Preview_Alim_Aviso"
	v.add_child(aviso)

	var motivo := Estilos_UI.parrafo("", 13, Estilos_UI.PELIGRO)
	motivo.name = "Preview_Alim_Motivo"
	v.add_child(motivo)

	var btn_elegir := Estilos_UI.boton("Elegir tupper", "primario", "package", Estilos_UI.EXITO, 44)
	btn_elegir.name = "Boton_Elegir_Tupper"
	btn_elegir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_elegir.set_meta("_estilo_propio", true)
	btn_elegir.pressed.connect(func(): raiz._Abrir_Modal_Tuppers())
	v.add_child(btn_elegir)

	return panel


func _Estilo_Tab_Comer(btn: Button, activo: bool, habilitado: bool) -> void:
	if btn == null:
		return
	btn.disabled = not habilitado
	btn.modulate = Color.WHITE if habilitado else Color(1, 1, 1, 0.5)
	if activo:
		Estilos_UI.aplicar_estilo_boton(btn, "primario", Estilos_UI.PRIMARIO)
	else:
		Estilos_UI.aplicar_estilo_boton(btn, "secundario", Estilos_UI.TINTA_SUAVE)
	btn.add_theme_font_size_override("font_size", 14)


func Actualizar_Preview_Alimentacion(raiz) -> void:
	var selector = raiz.get_node_or_null("Actividades/Seleccionar_Horario")
	if selector == null:
		return
	var panel := selector.get_node_or_null("Preview_Alimentacion") as Panel
	if panel == null:
		panel = _Crear_Panel_Preview_Alimentacion(selector, raiz)
	if panel == null:
		return

	var modo: String = str(raiz.get("actividad_seleccionada"))
	var tiene_tuppers: bool = not Variables_Dinamicas.Tuppers.is_empty()
	var duracion: int = _Duracion_Actual()

	var tabs := panel.get_node_or_null("Contenido/Tabs") as HBoxContainer
	var btn_tupper := panel.get_node_or_null("Contenido/Tabs/Tab_Tupper") as Button
	var btn_basura := panel.get_node_or_null("Contenido/Tabs/Tab_Basura") as Button
	var badge_cocinar := panel.get_node_or_null("Contenido/Cabecera/Preview_Alim_Badge_Cocinar") as PanelContainer
	var badge_tupper := panel.get_node_or_null("Contenido/Cabecera/Preview_Alim_Badge_Tupper") as PanelContainer
	var badge_basura := panel.get_node_or_null("Contenido/Cabecera/Preview_Alim_Badge_Basura") as PanelContainer
	var titulo := panel.get_node_or_null("Contenido/Cabecera/Preview_Alim_Titulo") as Label
	var lbl_dur := panel.find_child("Preview_Alim_Duracion", true, false) as Label
	var lbl_detalle := panel.find_child("Preview_Alim_Detalle", true, false) as Label
	var lbl_coste := panel.find_child("Preview_Alim_Coste", true, false) as Label
	var lbl_aviso := panel.find_child("Preview_Alim_Aviso", true, false) as Label
	var lbl_motivo := panel.find_child("Preview_Alim_Motivo", true, false) as Label
	var btn_elegir := panel.find_child("Boton_Elegir_Tupper", true, false) as Button
	if titulo == null or lbl_dur == null or lbl_detalle == null or lbl_coste == null \
			or lbl_aviso == null or lbl_motivo == null:
		return

	if tabs != null:
		tabs.visible = modo != "Cocinar"
	if btn_tupper != null:
		_Estilo_Tab_Comer(btn_tupper, modo == "Comer_Tupper", tiene_tuppers)
	if btn_basura != null:
		_Estilo_Tab_Comer(btn_basura, modo == "Comer_Basura", true)
	if btn_elegir != null:
		btn_elegir.visible = modo == "Comer_Tupper" and tiene_tuppers
	if badge_cocinar != null:
		badge_cocinar.visible = modo == "Cocinar"
	if badge_tupper != null:
		badge_tupper.visible = modo == "Comer_Tupper"
	if badge_basura != null:
		badge_basura.visible = modo == "Comer_Basura"

	lbl_motivo.visible = false
	lbl_aviso.visible = true
	lbl_coste.visible = true

	if modo == "Cocinar":
		titulo.text = "Cocinar"
		var validacion: Dictionary = Actividades.Validar_Horario_Cocinar(duracion)
		if not bool(validacion.get("valido", false)):
			lbl_dur.text = ""
			lbl_detalle.text = ""
			lbl_coste.text = ""
			lbl_aviso.text = ""
			lbl_motivo.text = str(validacion.get("motivo", ""))
			lbl_motivo.visible = true
			return
		var tuppers: int = duracion / Variables_Estaticas.MINUTOS_POR_TUPPER
		var coste_total: float = tuppers * Alimentacion.Coste_Cocinar()
		lbl_dur.text = "Duración: %s" % _Formatear_Duracion(duracion)
		lbl_detalle.text = "Producirás %d tupper%s al 100%% de calidad %d." % [
			tuppers, "" if tuppers == 1 else "s", Variables_Dinamicas.Progreso_Cocina]
		lbl_coste.text = "Coste: %s · %s por tupper" % [
			_Formatear_Euros(coste_total), _Formatear_Euros(Alimentacion.Coste_Cocinar())]
		lbl_aviso.text = "Cada tupper aporta 30 min de comida. Caduca en %d día%s." % [
			Variables_Estaticas.DIAS_CADUCIDAD_TUPPER if not Variables_Estaticas.Modo_Rapido else 1,
			"" if (Variables_Estaticas.DIAS_CADUCIDAD_TUPPER == 1 or Variables_Estaticas.Modo_Rapido) else "s"]
		var sobrante: int = duracion % Variables_Estaticas.MINUTOS_POR_TUPPER
		if sobrante > 0:
			lbl_aviso.text += " Los %d min sobrantes no producen tupper." % sobrante
		if Variables_Dinamicas.En_La_Calle:
			lbl_motivo.text = "No puedes cocinar sin una vivienda."
			lbl_motivo.visible = true
		elif Variables_Dinamicas.Dinero < Alimentacion.Coste_Cocinar():
			lbl_motivo.text = "Saldo insuficiente para el primer ciclo: la actividad se cancelará al ejecutarse."
			lbl_motivo.visible = true
		return

	if modo == "Comer_Tupper":
		titulo.text = "Comida casera"
		var idx: int = Alimentacion.Obtener_Indice_Tupper_Activo(false)
		if idx < 0:
			lbl_dur.text = "Duración: %s" % _Formatear_Duracion(duracion)
			lbl_detalle.text = "No te quedan tuppers en la nevera."
			lbl_coste.text = "Al empezar se usará comida rápida: %s cada 5 min." % _Formatear_Euros(Alimentacion.Coste_Comida_Basura())
			lbl_aviso.text = "Si no tienes saldo, el bloque se cancelará."
			return
		var tupper: Dictionary = Variables_Dinamicas.Tuppers[idx]
		var caducado: bool = Alimentacion.Es_Tupper_Caducado(tupper)
		lbl_dur.text = "Duración: %s" % _Formatear_Duracion(duracion)
		lbl_detalle.text = "Tupper #%d · Calidad %d · Restante %s\n%s" % [
			int(tupper.get("id", 0)),
			int(tupper.get("calidad", 1)),
			Alimentacion.Formatear_Porcentaje(float(tupper.get("porcentaje_restante", 100.0))),
			Alimentacion.Formatear_Caducidad(tupper)]
		lbl_coste.text = "Coste: 0,00 €"
		lbl_aviso.text = "Un tupper completo da 30 min de comida. Al agotarse pasa al siguiente; si no queda ninguno, continúa como comida rápida."
		if caducado:
			lbl_motivo.text = "¡Caducado! Comerlo puede provocar una intoxicación alimentaria."
			lbl_motivo.visible = true
		return

	# Comer_Basura
	titulo.text = "Comida rápida"
	var cobros: int = duracion / 5
	var coste_basura: float = cobros * Alimentacion.Coste_Comida_Basura()
	lbl_dur.text = "Duración: %s" % _Formatear_Duracion(duracion)
	lbl_detalle.text = "Cobro cada 5 min · %d cobro%s en este bloque." % [cobros, "" if cobros == 1 else "s"]
	lbl_coste.text = "Coste estimado: %s" % _Formatear_Euros(coste_basura)
	lbl_aviso.text = "Sube Hambre y Salud mental, pero penaliza la Salud física. Si te quedas sin saldo, el bloque se cancela."
	if Variables_Dinamicas.Dinero < Alimentacion.Coste_Comida_Basura():
		lbl_motivo.text = "No tienes saldo para el primer cobro: el bloque se cancelará al ejecutarse."
		lbl_motivo.visible = true
