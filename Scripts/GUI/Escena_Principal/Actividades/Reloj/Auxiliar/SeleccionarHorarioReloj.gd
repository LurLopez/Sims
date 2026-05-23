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
	else: Hora_Int+=1
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

func Crear_Actividad(mirar_semana,actividad_seleccionada):
	Actividades.Crear_Actividad_Especifica(mirar_semana,dia_inicio_a_int(),dia_final_a_int(),hora_inicio_texto.text.to_int(),hora_final_texto.text.to_int(),minuto_inicio_texto.text.to_int(),minuto_final_texto.text.to_int(),actividad_seleccionada)

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
