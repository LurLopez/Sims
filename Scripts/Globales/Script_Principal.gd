
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
func _ready():
	Inicializar_Otros_Scripts()
	if (Variables_Estaticas.First_Time):
		first_time_logica.First_Time_Function() 
		mirar_semana=1
		Guardar_Variables_Estaticas.save_game()
		Guardar_Variables_Dinamicas.save_game()
		
	else:
		Gestionar_Visibilidad.Quitar_Todo(self)
		mirar_semana=Variables_Dinamicas.Minute_Day/7
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var segundo_actual=Time.get_unix_time_from_system()
	var minuto_actual=floor(segundo_actual/60)
	if(minuto_actual-Variables_Dinamicas.Minute>-1):
		Actividades.Actualizar_Horario(minuto_actual)
		Guardar_Variables_Dinamicas.save_game()
	if(Variables_Estaticas.First_Time==false):
		Actualizar_Progreso()
		necesidades_basicas_gui.Actualizar_Necesidades_Basicas(self)


func Cargar_Variables():
	Guardar_Variables_Estaticas.load_game()
	Guardar_Variables_Dinamicas.load_game()


#Interfaz

func _on_boton_habilidades_pressed():
	Funciones_Globales.Mostrar_Habilidades()




func _on_boton_progreso_pressed():
	Gestionar_Visibilidad.Quitar_Todo(self)
	Gestionar_Visibilidad.Recursivo_Visibilizar($Progreso)


func _on_boton_necesidades_basicas_pressed():
	Gestionar_Visibilidad.Quitar_Todo(self)
	Gestionar_Visibilidad.Recursivo_Visibilizar($Necesidades_Basicas)




func Actualizar_Progreso():
	$Progreso/Progreso_Barra/Deporte.value=Variables_Dinamicas.Progreso[0]
	$Progreso/Progreso_Barra/Academico.value=Variables_Dinamicas.Progreso[1]
	$Progreso/Progreso_Barra/Manualidades.value=Variables_Dinamicas.Progreso[2]


func Quitar_Todo():
	Gestionar_Visibilidad.Quitar_Todo(self)











func _on_boton_actividades_pressed():
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


func _on_ocupar_actividad_pressed() -> void:
	if(actividades_bloque_gui.comprobar_seleccionado()):
		horario_bloque=(actividades_bloque_gui.devolver_hora_desde_posiciones())
		actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
		Gestionar_Visibilidad.Visibilizar_Seleccionar_Horario(self)
	

func _on_crear_actividad_pressed():
	Gestionar_Visibilidad.Recursivo_Desvisibilizar($Actividades/Seleccionar_Horario)
	$Actividades/Elegir_Actividad.visible=true
	$Actividades/Elegir_Actividad/Tipos_De_Actividades.visible=true
	Gestionar_Visibilidad.Pulsar_Boton_Opciones_Actividades("Temporales",self)


func _on_eliminar_actividad_pressed() -> void:
	if(actividades_bloque_gui.comprobar_seleccionado()):
		horario_bloque=(actividades_bloque_gui.devolver_hora_desde_posiciones())
		actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
		
		#$Seleccionar_Horario.visible=true     Si se quiere seleccionar la hora exacta que se quiere eliminar, solamante hay que activar estas 3 lineas de codigo
		#$Actividades/Crear_Actividad.visible=true
		#$Horario_Semanal.visible=false
		actividades_reloj_gui.horario.Crear_Actividad(mirar_semana,"")
		


##INICIO
func Inicio_Minuto_Arriba() -> void:
	actividades_reloj_gui.horario.Inicio_Minuto_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Inicio_Minuto_Abajo() -> void:
	actividades_reloj_gui.horario.Inicio_Minuto_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Inicio_Hora_Arriba() -> void:
	actividades_reloj_gui.horario.Inicio_Hora_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Inicio_Hora_Abajo() -> void:
	actividades_reloj_gui.horario.Inicio_Hora_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Inicio_Dia_Arriba() -> void:
	actividades_reloj_gui.horario.Inicio_Dia_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Inicio_Dia_Abajo() -> void:
	actividades_reloj_gui.horario.Inicio_Dia_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
##FINAL
func Final_Minuto_Arriba() -> void:
	actividades_reloj_gui.horario.Final_Minuto_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Final_Minuto_Abajo() -> void:
	actividades_reloj_gui.horario.Final_Minuto_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Final_Hora_Arriba() -> void:
	actividades_reloj_gui.horario.Final_Hora_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Final_Hora_Abajo() -> void:
	actividades_reloj_gui.horario.Final_Hora_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Final_Dia_Arriba() -> void:
	actividades_reloj_gui.horario.Final_Dia_Arriba()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)
func Final_Dia_Abajo() -> void:
	actividades_reloj_gui.horario.Final_Dia_Abajo()
	actividades_reloj_gui.Comprobar_Visibilidad(self,horario_bloque)

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
	actividades_bloque_gui.Añadir_Horas_Al_Horario()
	actividades_bloque_gui.bloque_columna.limpiar_todos_los_vboxcontainer()
	actividades_bloque_gui.Agregar_Bloques(mirar_semana,self)
	Gestionar_Visibilidad.Visibilizar_Horario_Semanal(self)


func _on_calendario_boton_pressed() -> void:
	pass # Replace with function body.


func _on_temporales_pressed() -> void:
	Iniciar_Bloques_Actividad()



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
	_on_boton_actividades_pressed()
	actividades_bloque_gui.bloque_columna.limpiar_horas_del_horario()
