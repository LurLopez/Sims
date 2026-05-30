extends Node

# Economía
const ALQUILER_SEMANAL: int = 200
# Bancarrota: cuando Dinero < 0, las necesidades básicas no pueden superar este valor.
const BANCARROTA_MAX_NECESIDAD: int = 20

var First_Time = true
var First_Time_Minute = 0
var Personalidad = ""
var Habilidades = []
var Actividades = []
var Catalogo_Actividades: Dictionary = {}
var Catalogo_Objetos: Dictionary = {}
var First_Time_Minute_Day = 0
var First_Time_Minute_Minute = 0
# Fecha local (año/mes/día) al crear el personaje. Se usan para calcular cuántos
# días LOCALES han pasado desde el inicio (insensible a DST y cambios de zona horaria).
var First_Time_Year = 0
var First_Time_Month = 0
var First_Time_Day_Of_Month = 0

func _ready():
	_Inicializar_Catalogo()
	_Inicializar_Catalogo_Objetos()

func _Inicializar_Catalogo():
	var dormir = Actividad_Temporal.new()
	dormir.nombre = "Dormir"
	dormir.efectos_necesidades_basicas = [1, 1, -1, 4, -1]
	Catalogo_Actividades["Dormir"] = dormir

	var comer = Actividad_Temporal.new()
	comer.nombre = "Comer"
	comer.efectos_necesidades_basicas = [-1, 2, 20, -1, -1]
	Catalogo_Actividades["Comer"] = comer

	var duchar = Actividad_Temporal.new()
	duchar.nombre = "Duchar"
	duchar.efectos_necesidades_basicas = [1, 1, -1, -1, 20]
	Catalogo_Actividades["Duchar"] = duchar

	var television = Actividad_Temporal.new()
	television.nombre = "Ver_La_Television"
	television.efectos_necesidades_basicas = [-1, 5, -1, 2, -1]
	Catalogo_Actividades["Ver_La_Television"] = television

	var estudiar = Actividad_Temporal.new()
	estudiar.nombre = "Estudiar"
	estudiar.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	estudiar.efectos_progreso = [0, 4, 0]
	Catalogo_Actividades["Estudiar"] = estudiar

	var correr = Actividad_Temporal.new()
	correr.nombre = "Salir_A_Correr"
	correr.efectos_necesidades_basicas = [4, 2, -3, -3, -4]
	correr.efectos_progreso = [4, 0, 0]
	Catalogo_Actividades["Salir_A_Correr"] = correr

	var manualidades = Actividad_Temporal.new()
	manualidades.nombre = "Practicar_Manualidades"
	manualidades.efectos_necesidades_basicas = [-2, -1, -1, -2, -1]
	manualidades.efectos_progreso = [0, 0, 4]
	Catalogo_Actividades["Practicar_Manualidades"] = manualidades

	var comida_rapida = Actividad_Fija_Trabajo.new()
	comida_rapida.nombre = "Trabajar_En_Comida_Rapida"
	comida_rapida.efectos_necesidades_basicas = [-1, -1, -1, -2, -1]
	comida_rapida.hora_inicio = 480
	comida_rapida.hora_final = 960
	comida_rapida.salario = 10.0
	comida_rapida.requisito_progreso = [0, 0, 0]
	comida_rapida.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_En_Comida_Rapida"] = comida_rapida

	# Actividad especial: estudiar la carrera universitaria activa. Suma progreso
	# probabilísticamente a Carrera_Actual.progreso_actual (no al Progreso académico general).
	var estudiar_carrera = Actividad_Carrera.new()
	estudiar_carrera.nombre = "Estudiar_Carrera"
	estudiar_carrera.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	estudiar_carrera.efectos_progreso = [0, 0, 0]
	estudiar_carrera.carrera_nombre = ""
	estudiar_carrera.año_referencia = 0
	Catalogo_Actividades["Estudiar_Carrera"] = estudiar_carrera

	Actividades = [
		Catalogo_Actividades["Estudiar"],
		Catalogo_Actividades["Salir_A_Correr"],
		Catalogo_Actividades["Practicar_Manualidades"],
		Catalogo_Actividades["Duchar"],
		Catalogo_Actividades["Dormir"],
		Catalogo_Actividades["Comer"],
		Catalogo_Actividades["Ver_La_Television"],
	]

func _Inicializar_Catalogo_Objetos():
	# Camas (afectan a Dormir)
	var cama_basica = Objeto_Dormir.new()
	cama_basica.nombre = "Cama_Basica"
	cama_basica.precio = 0.0
	cama_basica.multiplicador = 1.0
	cama_basica.afecta_a = "Dormir"
	cama_basica.es_basico = true
	Catalogo_Objetos["Cama_Basica"] = cama_basica

	var cama_premium = Objeto_Dormir.new()
	cama_premium.nombre = "Cama_Premium"
	cama_premium.precio = 200.0
	cama_premium.multiplicador = 1.05
	cama_premium.afecta_a = "Dormir"
	cama_premium.es_basico = false
	Catalogo_Objetos["Cama_Premium"] = cama_premium

	var cama_lujo = Objeto_Dormir.new()
	cama_lujo.nombre = "Cama_Lujo"
	cama_lujo.precio = 800.0
	cama_lujo.multiplicador = 1.10
	cama_lujo.afecta_a = "Dormir"
	cama_lujo.es_basico = false
	Catalogo_Objetos["Cama_Lujo"] = cama_lujo

	# Mesas (afectan a Comer)
	var mesa_basica = Objeto_Comer.new()
	mesa_basica.nombre = "Mesa_Basica"
	mesa_basica.precio = 0.0
	mesa_basica.multiplicador = 1.0
	mesa_basica.afecta_a = "Comer"
	mesa_basica.es_basico = true
	Catalogo_Objetos["Mesa_Basica"] = mesa_basica

	var mesa_premium = Objeto_Comer.new()
	mesa_premium.nombre = "Mesa_Premium"
	mesa_premium.precio = 200.0
	mesa_premium.multiplicador = 1.05
	mesa_premium.afecta_a = "Comer"
	mesa_premium.es_basico = false
	Catalogo_Objetos["Mesa_Premium"] = mesa_premium

	# Duchas (afectan a Duchar)
	var ducha_basica = Objeto_Duchar.new()
	ducha_basica.nombre = "Ducha_Basica"
	ducha_basica.precio = 0.0
	ducha_basica.multiplicador = 1.0
	ducha_basica.afecta_a = "Duchar"
	ducha_basica.es_basico = true
	Catalogo_Objetos["Ducha_Basica"] = ducha_basica

	var ducha_premium = Objeto_Duchar.new()
	ducha_premium.nombre = "Ducha_Premium"
	ducha_premium.precio = 200.0
	ducha_premium.multiplicador = 1.05
	ducha_premium.afecta_a = "Duchar"
	ducha_premium.es_basico = false
	Catalogo_Objetos["Ducha_Premium"] = ducha_premium
