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
	var dia_final: int = dia_final_a_int()
	if actividad_seleccionada == "Salir_De_Fiesta":
		var dia_inicio: int = dia_inicio_a_int()
		# El selector trabaja con días 0..6; para un cruce de medianoche hay que
		# pasar el día siguiente absoluto a _Calcular_Rango (7 = lunes siguiente).
		dia_final = dia_inicio + 1 if _Es_Cruce_Fiesta() else dia_inicio
	return Actividades.Crear_Actividad_Especifica(mirar_semana,dia_inicio_a_int(),dia_final,hora_inicio_texto.text.to_int(),hora_final_texto.text.to_int(),minuto_inicio_texto.text.to_int(),minuto_final_texto.text.to_int(),actividad_seleccionada)


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
