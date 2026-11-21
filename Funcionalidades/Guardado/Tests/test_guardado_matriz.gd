extends GutTest

# Regresión del formato RLE de la matriz (guardado/carga) y de la creación
# rápida de la matriz inicial de 1440×574.

var _matriz_original: Array = []
var _sucia_original: bool = true


func before_each() -> void:
	_matriz_original = Variables_Dinamicas.Matriz_Jugador
	_sucia_original = Variables_Dinamicas.Matriz_Sucia


func after_each() -> void:
	Variables_Dinamicas.Matriz_Jugador = _matriz_original
	Variables_Dinamicas.Matriz_Sucia = _sucia_original
	Guardar_Variables_Dinamicas._rle_cache = {}


func test_rle_conserva_tramos_vacios_y_actividades() -> void:
	var actividad = Variables_Estaticas.Catalogo_Actividades["Estudiar"]
	var fila_vacia: Array = ["", "", "", ""]
	Variables_Dinamicas.Matriz_Jugador = [
		fila_vacia.duplicate(),
		fila_vacia.duplicate(),
		["", actividad, "", ""],
		["", "", "", ""],
		[actividad, "", "", actividad],
	]
	Variables_Dinamicas.Matriz_Sucia = true
	Guardar_Variables_Dinamicas._rle_cache = {}

	var rle: Dictionary = Guardar_Variables_Dinamicas._Matriz_A_RLE()
	assert_eq(rle["formato"], "rle")
	assert_eq(rle["filas"], 5)
	assert_eq(rle["columnas"], 4)
	# 2 filas vacías + 1 actividad + resto vacío; el tramo inicial debe cubrir
	# las dos filas completas sin escribir celda a celda.
	assert_eq(rle["datos"][0], "")
	assert_eq(rle["datos"][1], 9) # 2 filas vacías + la primera celda vacía de la fila 2

	var reconstruida: Array = Guardar_Variables_Dinamicas._RLE_A_Matriz(rle)
	assert_eq(reconstruida.size(), 5)
	assert_eq(reconstruida[0].size(), 4)
	assert_eq(reconstruida[0][0], "")
	assert_eq(reconstruida[2][1], actividad)
	assert_eq(reconstruida[4][0], actividad)
	assert_eq(reconstruida[4][3], actividad)
	assert_eq(reconstruida[3][2], "")


func test_rle_conserva_actividad_aleatoria() -> void:
	Variables_Dinamicas.Matriz_Jugador = [
		["Actividad_Aleatoria", ""],
		["", ""],
	]
	Variables_Dinamicas.Matriz_Sucia = true
	Guardar_Variables_Dinamicas._rle_cache = {}
	var rle: Dictionary = Guardar_Variables_Dinamicas._Matriz_A_RLE()
	var reconstruida: Array = Guardar_Variables_Dinamicas._RLE_A_Matriz(rle)
	assert_eq(reconstruida[0][0], "Actividad_Aleatoria")
	assert_eq(reconstruida[0][1], "")
	assert_eq(reconstruida[1][0], "")


func test_crear_matriz_rapida_es_independiente_por_filas() -> void:
	var first_time = load("res://Scripts/Logica/Escena_Principal/First_Time/First_Time.gd").new()
	first_time.Crear_Matriz()
	var matriz: Array = Variables_Dinamicas.Matriz_Jugador
	assert_eq(matriz.size(), 1440)
	assert_eq(matriz[0].size(), 574)
	assert_eq(matriz[1439].size(), 574)
	assert_eq(matriz[700][500], "")
	# Modificar una fila no debe afectar a las demás (no se comparten Arrays).
	matriz[700][500] = "prueba"
	assert_eq(matriz[701][500], "")
	first_time.free()
