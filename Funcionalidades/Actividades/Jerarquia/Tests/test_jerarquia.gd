extends GutTest

# Tests para el sistema de jerarquía de actividades (prioridades P1-P3)
# Cubre: bloqueo de P1 por P2/P3, sobreescritura de P2 sobre P1,
# salto de examen en Trabajo, borrado libre y examen escrito como objeto P3.


func before_each():
	if Variables_Dinamicas.Matriz_Jugador.size() != 1440:
		Variables_Dinamicas.Matriz_Jugador = []
		for i in range(1440):
			var fila: Array = []
			fila.resize(574)
			fila.fill("")
			Variables_Dinamicas.Matriz_Jugador.append(fila)
	# Limpiar solo las columnas que usan estos tests para no contaminar otros.
	for fila in range(1440):
		for columna in range(0, 3):
			Variables_Dinamicas.Matriz_Jugador[fila][columna] = ""
	Variables_Dinamicas.Carrera_Actual = null


func test_actividad_temporal_bloqueada_por_trabajo():
	# P1 no puede colocarse sobre una celda con P2 (Actividad_Fija_Trabajo)
	var actividad_trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	var actividad_dormir = Variables_Estaticas.Catalogo_Actividades["Dormir"]
	Variables_Dinamicas.Matriz_Jugador[480][0] = actividad_trabajo

	var resultado = Actividades.Crear_Actividad(0, 480, actividad_dormir)

	assert_false(resultado, "P1 no debería poder sobreescribir P2")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[480][0], actividad_trabajo, "La celda no debe haber cambiado")


func test_trabajo_sobreescribe_temporal():
	# P2 sí puede sobreescribir una celda con P1
	var actividad_trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	var actividad_correr = Variables_Estaticas.Catalogo_Actividades["Salir_A_Correr"]
	Variables_Dinamicas.Matriz_Jugador[480][0] = actividad_correr

	var resultado = Actividades.Crear_Actividad(0, 480, actividad_trabajo)

	assert_true(resultado, "P2 debería poder sobreescribir P1")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[480][0], actividad_trabajo)


func test_actividad_temporal_bloqueada_por_examen():
	# P1 no puede colocarse en una celda con prioridad de examen (P3).
	# En el juego real el examen se escribe en la matriz como Actividad_Examen.
	var carrera = Carrera.new()
	carrera.hora_examen_dia = 2   # Miércoles
	carrera.hora_examen_inicio = 900  # 15:00
	carrera.matriculado = true
	carrera.prematriculado = false
	Variables_Dinamicas.Carrera_Actual = carrera

	var actividad_dormir = Variables_Estaticas.Catalogo_Actividades["Dormir"]
	Variables_Dinamicas.Matriz_Jugador[900][2] = Actividad_Examen.new()

	var resultado = Actividades.Crear_Actividad(2, 900, actividad_dormir)

	assert_false(resultado, "P1 no debería poder colocarse durante el examen")
	Variables_Dinamicas.Carrera_Actual = null


func test_trabajo_salta_examen():
	# P2 no puede sobreescribir la celda de examen (P3), pero sí las demás.
	var carrera = Carrera.new()
	carrera.hora_examen_dia = 0   # Lunes
	carrera.hora_examen_inicio = 480  # 8:00 (primera hora del trabajo de comida rápida)
	carrera.matriculado = true
	carrera.prematriculado = false
	Variables_Dinamicas.Carrera_Actual = carrera

	var actividad_trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	var examen = Actividad_Examen.new()
	for j in range(480, 482):
		Variables_Dinamicas.Matriz_Jugador[j][0] = ""
	Variables_Dinamicas.Matriz_Jugador[480][0] = examen

	# Celda 480 es examen (debería saltarse); celda 481 no lo es (debería escribirse)
	Actividades.Crear_Actividad(0, 480, actividad_trabajo)
	Actividades.Crear_Actividad(0, 481, actividad_trabajo)

	assert_true(Variables_Dinamicas.Matriz_Jugador[480][0] is Actividad_Examen, "La celda de examen no debería haberse sobreescrito")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[481][0], actividad_trabajo, "La celda fuera del examen sí debería escribirse")
	Variables_Dinamicas.Carrera_Actual = null


func test_borrar_siempre_permitido():
	# Borrar ("") es libre independientemente de la prioridad de la celda
	var actividad_trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	Variables_Dinamicas.Matriz_Jugador[500][0] = actividad_trabajo

	var resultado = Actividades.Crear_Actividad(0, 500, "")

	assert_true(resultado, "El borrado siempre debe estar permitido")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[500][0], "")


func test_temporal_sobre_temporal_permitida():
	# P1 puede sobreescribir otra P1
	var actividad_correr = Variables_Estaticas.Catalogo_Actividades["Salir_A_Correr"]
	var actividad_comer = Variables_Estaticas.Catalogo_Actividades["Comer_Basura"]
	Variables_Dinamicas.Matriz_Jugador[600][0] = actividad_correr

	var resultado = Actividades.Crear_Actividad(0, 600, actividad_comer)

	assert_true(resultado, "P1 sobre P1 debería estar permitido")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[600][0], actividad_comer)


func test_sin_carrera_no_hay_examen():
	# Sin Carrera_Actual, ninguna celda tiene prioridad 3
	Variables_Dinamicas.Carrera_Actual = null
	var actividad_trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	Variables_Dinamicas.Matriz_Jugador[900][2] = ""

	# Trabajo debería escribirse en cualquier celda vacía si no hay carrera
	var resultado = Actividades.Crear_Actividad(2, 900, actividad_trabajo)

	assert_true(resultado, "Sin carrera activa no hay P3; el trabajo debe poder escribirse")


func test_prioridad_celda_vacia_es_cero():
	# Una celda vacía tiene prioridad 0; cualquier Actividad puede escribirse sobre ella
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Matriz_Jugador[700][1] = ""

	var prioridad = Actividades._Prioridad_Celda("", 1, 700)

	assert_eq(prioridad, 0, "Una celda vacía debe tener prioridad 0")
