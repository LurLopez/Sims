extends Node

# Economía
const ALQUILER_SEMANAL: int = 200
# Bancarrota: cuando Dinero < 0, las necesidades básicas no pueden superar este valor.
const BANCARROTA_MAX_NECESIDAD: int = 20

# Cocina y alimentación
const COSTE_COCINAR_BASE: float = 2.0
const COSTE_COMIDA_BASURA_BASE: float = 2.0
const DIAS_CADUCIDAD_TUPPER: int = 3
const MINUTOS_POR_TUPPER: int = 15
const MINUTOS_COMIDOS_POR_TUPPER: int = 30

var First_Time = true
var Modo_Rapido: bool = false
var Tutorial_Completado = false
var First_Time_Minute = 0
var Personalidad = ""
var Apariencia: Dictionary = {}
var Habilidades = []
var Actividades = []
var Catalogo_Actividades: Dictionary = {}
var Catalogo_Objetos: Dictionary = {}

# Estados temporales persistentes (el valor en Variables_Dinamicas son minutos restantes).
# "Euforia" impone un suelo gradual a la salud mental; "Resacon" un techo gradual
# a la salud física y mental. Ambos duran 1440 min: 480 min de meseta + 960 de bajada.
var Estados_Temporales: Dictionary = {
	"Euforia": {
		"duracion": 1440,
		"meseta": 480,
		"tipo": "suelo_gradual",
		"indice": 1,
		"valor_inicial": 100,
		"valor_final": 50,
		"titulo_inicio": "Has ligado",
		"titulo_fin": "Fin de la euforia",
		"mensaje_inicio": "Has ligado. Euforia durante 24 h.",
		"mensaje_fin": "La euforia ha terminado."
	},
	"Resacon": {
		"duracion": 1440,
		"meseta": 480,
		"tipo": "cap_gradual",
		"indices": [0, 1],
		"cap_inicial": 30,
		"cap_final": 100,
		"titulo_inicio": "Resacón",
		"titulo_fin": "Fin del resacón",
		"mensaje_inicio": "Te has pasado con la bebida. Resacón durante 24 h.",
		"mensaje_fin": "El resacón ha terminado."
	},
	"Intoxicacion": {
		"duracion": 1440,
		"meseta": 480,
		"tipo": "cap_gradual",
		"indices": [0, 1],
		"cap_inicial": 30,
		"cap_final": 100,
		"titulo_inicio": "Intoxicación alimentaria",
		"titulo_fin": "Fin de la intoxicación",
		"mensaje_inicio": "Has comido un tupper en mal estado. Intoxicación alimentaria durante 24 h.",
		"mensaje_fin": "Te has recuperado de la intoxicación alimentaria."
	}
}
var First_Time_Minute_Day = 0
var First_Time_Minute_Minute = 0
# Fecha local (año/mes/día) al crear el personaje. Se usan para calcular cuántos
# días LOCALES han pasado desde el inicio (insensible a DST y cambios de zona horaria).
var First_Time_Year = 0
var First_Time_Month = 0
var First_Time_Day_Of_Month = 0

func Dias_Por_Anio() -> int:
	return 1 if Modo_Rapido else 7

func Calcular_Edad(dia_actual: int = -1) -> int:
	var dia: int = dia_actual if dia_actual >= 0 else Variables_Dinamicas.Minute_Day
	return 18 + int(maxi(0, dia - First_Time_Minute_Day) / float(Dias_Por_Anio()))

func Multiplicador_Precios() -> float:
	return 0.1 if Modo_Rapido else 1.0

func Obtener_Coste_Cocinar() -> float:
	return round(COSTE_COCINAR_BASE * Multiplicador_Precios() * 100.0) / 100.0

func Obtener_Coste_Comida_Basura() -> float:
	return round(COSTE_COMIDA_BASURA_BASE * Multiplicador_Precios() * 100.0) / 100.0

func Obtener_Minutos_Caducidad_Tupper() -> int:
	return (1 if Modo_Rapido else DIAS_CADUCIDAD_TUPPER) * 1440

func Multiplicador_Salario() -> float:
	# En modo rápido: lo que se gana en una semana (40h) / 7 * 2 por cada día (8h) => 10/7 por hora.
	return (10.0 / 7.0) if Modo_Rapido else 1.0

func Obtener_Alquiler() -> int:
	return int(round(ALQUILER_SEMANAL * Multiplicador_Precios()))

func Obtener_Capital_Inicial() -> int:
	return 100 if Modo_Rapido else 1000

func Obtener_Precio_Objeto(objeto: Objeto) -> float:
	return round(objeto.precio * Multiplicador_Precios())

func Obtener_Costo_Matricula(carrera: Carrera) -> float:
	return round(carrera.costo_matricula_anual * Multiplicador_Precios())

func Obtener_Bonus_Carrera(bonus_base: float) -> float:
	return round(bonus_base * Multiplicador_Precios())

func Obtener_Salario_Hora(actividad: Actividad_Fija_Trabajo) -> float:
	return actividad.salario * Multiplicador_Salario()

func _ready():
	Apariencia = Apariencia_Personaje.por_defecto()
	_Inicializar_Catalogo()
	_Inicializar_Catalogo_Objetos()

func _Inicializar_Catalogo():
	var dormir = Actividad_Temporal.new()
	dormir.nombre = "Dormir"
	dormir.color = Color(0.15, 0.30, 0.65)
	dormir.efectos_necesidades_basicas = [1, 1, -1, 4, -1]
	Catalogo_Actividades["Dormir"] = dormir

	var cocinar = Actividad_Temporal.new()
	cocinar.nombre = "Cocinar"
	cocinar.color = Color(0.95, 0.55, 0.20)
	cocinar.efectos_necesidades_basicas = [-1, 1, -2, -2, -2]
	cocinar.efectos_progreso = [0, 0, 0]
	Catalogo_Actividades["Cocinar"] = cocinar

	var comer_tupper = Actividad_Temporal.new()
	comer_tupper.nombre = "Comer_Tupper"
	comer_tupper.color = Color(0.25, 0.75, 0.45)
	comer_tupper.efectos_necesidades_basicas = [1, 2, 20, -1, -1]
	comer_tupper.efectos_progreso = [0, 0, 0]
	Catalogo_Actividades["Comer_Tupper"] = comer_tupper

	var comer_basura = Actividad_Temporal.new()
	comer_basura.nombre = "Comer_Basura"
	comer_basura.color = Color(0.85, 0.30, 0.25)
	comer_basura.efectos_necesidades_basicas = [-2, 2, 20, -1, -1]
	comer_basura.efectos_progreso = [0, 0, 0]
	Catalogo_Actividades["Comer_Basura"] = comer_basura

	var duchar = Actividad_Temporal.new()
	duchar.nombre = "Duchar"
	duchar.color = Color(0.10, 0.65, 0.80)
	duchar.efectos_necesidades_basicas = [1, 1, -1, -1, 20]
	Catalogo_Actividades["Duchar"] = duchar

	var television = Actividad_Temporal.new()
	television.nombre = "Ver_La_Television"
	television.color = Color(0.50, 0.20, 0.72)
	television.efectos_necesidades_basicas = [-1, 5, -1, 2, -1]
	Catalogo_Actividades["Ver_La_Television"] = television

	var estudiar = Actividad_Temporal.new()
	estudiar.nombre = "Estudiar"
	estudiar.color = Color(0.75, 0.65, 0.05)
	estudiar.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	estudiar.efectos_progreso = [0, 4, 0]
	Catalogo_Actividades["Estudiar"] = estudiar

	var correr = Actividad_Temporal.new()
	correr.nombre = "Salir_A_Correr"
	correr.color = Color(0.15, 0.70, 0.25)
	correr.efectos_necesidades_basicas = [4, 2, -3, -3, -4]
	correr.efectos_progreso = [4, 0, 0]
	Catalogo_Actividades["Salir_A_Correr"] = correr

	var manualidades = Actividad_Temporal.new()
	manualidades.nombre = "Practicar_Manualidades"
	manualidades.color = Color(0.65, 0.38, 0.10)
	manualidades.efectos_necesidades_basicas = [-2, -1, -1, -2, -1]
	manualidades.efectos_progreso = [0, 0, 4]
	Catalogo_Actividades["Practicar_Manualidades"] = manualidades

	var comida_rapida = Actividad_Fija_Trabajo.new()
	comida_rapida.nombre = "Trabajar_En_Comida_Rapida"
	comida_rapida.color = Color(0.80, 0.25, 0.08)
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
	estudiar_carrera.color = Color(0.60, 0.50, 0.00)
	estudiar_carrera.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	estudiar_carrera.efectos_progreso = [0, 0, 0]
	estudiar_carrera.carrera_nombre = ""
	estudiar_carrera.año_referencia = 0
	Catalogo_Actividades["Estudiar_Carrera"] = estudiar_carrera

	# Actividad examen: bloque de 60 min en la matriz con prioridad máxima (P3).
	var examen = Actividad_Examen.new()
	examen.nombre = "Examen_Carrera"
	examen.color = Color(0.85, 0.08, 0.08)
	examen.efectos_necesidades_basicas = [-1, -3, -1, -3, -1]
	examen.efectos_progreso = [0, 0, 0]
	Catalogo_Actividades["Examen_Carrera"] = examen

	# Actividad carrera deportiva: bloque de 60 min en fin de semana con prioridad P3.
	var carrera_deportiva = preload("res://Scripts/Logica/Escena_Principal/Actividades/Actividad_Carrera_Deportiva.gd").new()
	carrera_deportiva.nombre = "Carrera_Deportiva"
	carrera_deportiva.color = Color(0.92, 0.35, 0.05)
	carrera_deportiva.efectos_necesidades_basicas = [4, 2, -3, -3, -4]
	carrera_deportiva.efectos_progreso = [4, 0, 0]
	Catalogo_Actividades["Carrera_Deportiva"] = carrera_deportiva

	var carpintero = Actividad_Fija_Trabajo.new()
	carpintero.nombre = "Trabajar_De_Carpintero"
	carpintero.color = Color(0.45, 0.28, 0.05)
	carpintero.efectos_necesidades_basicas = [-1, -1, -1, -2, -2]
	carpintero.hora_inicio = 420
	carpintero.hora_final = 900
	carpintero.salario = 18.0
	carpintero.requisito_progreso = [0, 0, 30]
	carpintero.requisito_carrera = []
	carpintero.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Carpintero"] = carpintero

	var cientifico = Actividad_Fija_Trabajo.new()
	cientifico.nombre = "Trabajar_De_Cientifico"
	cientifico.color = Color(0.10, 0.55, 0.55)
	cientifico.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	cientifico.hora_inicio = 540
	cientifico.hora_final = 1020
	cientifico.salario = 28.0
	cientifico.requisito_progreso = [0, 65, 0]
	cientifico.requisito_carrera = ["Ingenieria_Informatica"]
	cientifico.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Cientifico"] = cientifico

	var abogado = Actividad_Fija_Trabajo.new()
	abogado.nombre = "Trabajar_De_Abogado"
	abogado.color = Color(0.30, 0.30, 0.35)
	abogado.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	abogado.hora_inicio = 540
	abogado.hora_final = 1020
	abogado.salario = 30.0
	abogado.requisito_progreso = [0, 50, 0]
	abogado.requisito_carrera = ["Derecho"]
	abogado.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Abogado"] = abogado

	var medico = Actividad_Fija_Trabajo.new()
	medico.nombre = "Trabajar_De_Medico"
	medico.color = Color(0.10, 0.60, 0.70)
	medico.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	medico.hora_inicio = 540
	medico.hora_final = 1020
	medico.salario = 35.0
	medico.requisito_progreso = [0, 60, 0]
	medico.requisito_carrera = ["Medicina"]
	medico.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Medico"] = medico

	var artista = Actividad_Fija_Trabajo.new()
	artista.nombre = "Trabajar_De_Artista"
	artista.color = Color(0.75, 0.20, 0.55)
	artista.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	artista.hora_inicio = 540
	artista.hora_final = 1020
	artista.salario = 25.0
	artista.requisito_progreso = [0, 0, 50]
	artista.requisito_carrera = ["Bellas_Artes"]
	artista.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Artista"] = artista

	# Hostelería: solo exige Progreso_Cocina (sin requisitos innatos ni carrera).
	var ayudante_cocina = Actividad_Fija_Trabajo.new()
	ayudante_cocina.nombre = "Trabajar_De_Ayudante_Cocina"
	ayudante_cocina.color = Color(0.90, 0.50, 0.15)
	ayudante_cocina.efectos_necesidades_basicas = [-1, -1, -1, -2, -1]
	ayudante_cocina.hora_inicio = 660
	ayudante_cocina.hora_final = 1140
	ayudante_cocina.salario = 17.0
	ayudante_cocina.requisito_progreso = [0, 0, 0]
	ayudante_cocina.requisito_cocina = 30
	ayudante_cocina.requisito_carrera = []
	ayudante_cocina.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Ayudante_Cocina"] = ayudante_cocina

	var cocinero_partida = Actividad_Fija_Trabajo.new()
	cocinero_partida.nombre = "Trabajar_De_Cocinero_Partida"
	cocinero_partida.color = Color(0.82, 0.35, 0.18)
	cocinero_partida.efectos_necesidades_basicas = [-1, -1, -1, -2, -1]
	cocinero_partida.hora_inicio = 720
	cocinero_partida.hora_final = 1200
	cocinero_partida.salario = 24.0
	cocinero_partida.requisito_progreso = [0, 0, 0]
	cocinero_partida.requisito_cocina = 60
	cocinero_partida.requisito_carrera = []
	cocinero_partida.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Cocinero_Partida"] = cocinero_partida

	var chef_ejecutivo = Actividad_Fija_Trabajo.new()
	chef_ejecutivo.nombre = "Trabajar_De_Chef_Ejecutivo"
	chef_ejecutivo.color = Color(0.65, 0.18, 0.12)
	chef_ejecutivo.efectos_necesidades_basicas = [-1, -2, -1, -2, -1]
	chef_ejecutivo.hora_inicio = 780
	chef_ejecutivo.hora_final = 1260
	chef_ejecutivo.salario = 36.0
	chef_ejecutivo.requisito_progreso = [0, 0, 0]
	chef_ejecutivo.requisito_cocina = 85
	chef_ejecutivo.requisito_carrera = []
	chef_ejecutivo.dias_laborales = [0, 1, 2, 3, 4]
	Catalogo_Actividades["Trabajar_De_Chef_Ejecutivo"] = chef_ejecutivo

	var salir_de_fiesta = Actividad_Temporal.new()
	salir_de_fiesta.nombre = "Salir_De_Fiesta"
	salir_de_fiesta.color = Color(0.85, 0.15, 0.45)
	salir_de_fiesta.efectos_necesidades_basicas = [0, 9, -3, -4, -2]
	salir_de_fiesta.efectos_progreso = [0, 0, 0]
	Catalogo_Actividades["Salir_De_Fiesta"] = salir_de_fiesta

	# Salir_De_Fiesta NO entra en el pool aleatorio: solo se ejecuta si el jugador
	# la programa dentro de su ventana horaria 18:00-06:00.
	Actividades = [
		Catalogo_Actividades["Estudiar"],
		Catalogo_Actividades["Salir_A_Correr"],
		Catalogo_Actividades["Practicar_Manualidades"],
		Catalogo_Actividades["Duchar"],
		Catalogo_Actividades["Dormir"],
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

	# Mesa básica (objeto inicial decorativo: comer ya no depende de mesas)
	var mesa_basica = Objeto_Comer.new()
	mesa_basica.nombre = "Mesa_Basica"
	mesa_basica.precio = 0.0
	mesa_basica.multiplicador = 1.0
	mesa_basica.afecta_a = "Comer"
	mesa_basica.es_basico = true
	Catalogo_Objetos["Mesa_Basica"] = mesa_basica

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
