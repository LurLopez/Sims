extends Node

class_name BloqueDiaColumna

var horario_columna
var lunes_columna
var martes_columna
var miercoles_columna
var jueves_columna
var viernes_columna
var sabado_columna
var domingo_columna

func Inicializar(raiz):
	horario_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Horario")
	lunes_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Lunes")
	martes_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Martes")
	miercoles_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Miercoles")
	jueves_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Jueves")
	viernes_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Viernes")
	sabado_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Sabado")
	domingo_columna=raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Domingo")

func desactivar_todos_los_botones():
	desactivar_boton_dia(lunes_columna)
	desactivar_boton_dia(martes_columna)
	desactivar_boton_dia(miercoles_columna)
	desactivar_boton_dia(jueves_columna)
	desactivar_boton_dia(viernes_columna)
	desactivar_boton_dia(sabado_columna)
	desactivar_boton_dia(domingo_columna)

func desactivar_boton_dia(dia):
	for i in dia.get_child_count():
		var boton=dia.get_child(i)
		boton.set_pressed(false)


### semana_pressed:
func limpiar_todos_los_vboxcontainer():
	limpiar_dia_vbox_container(lunes_columna)
	limpiar_dia_vbox_container(martes_columna)
	limpiar_dia_vbox_container(miercoles_columna)
	limpiar_dia_vbox_container(jueves_columna)
	limpiar_dia_vbox_container(viernes_columna)
	limpiar_dia_vbox_container(sabado_columna)
	limpiar_dia_vbox_container(domingo_columna)

func limpiar_dia_vbox_container(dia):
	for child in dia.get_children():
		if child is Button:
			dia.remove_child(child)
			child.queue_free()

func limpiar_horas_del_horario():
	limpiar_dia_vbox_container(horario_columna)
