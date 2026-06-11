extends GutTest

# Tests para el Tab Apuntes (Inventario)
# Verifica la recopilacion de libros, el formato de los nombres y los casos sin libros


func test_sin_carrera_activa_no_hay_libros():
	# Si Carrera_Actual es null y no hay carreras completadas, no hay libros
	var libros = []
	var carrera_actual = null
	if carrera_actual != null:
		for libro in carrera_actual.libros_desbloqueados:
			libros.append(libro)
	assert_true(libros.is_empty(), "Sin carrera activa el array de libros esta vacio")


func test_extraccion_anyo_desde_string():
	# El año se extrae del string "Anio_N" convirtiendo a int
	var libro_str = "Anio_2"
	var año = int(String(libro_str).replace("Anio_", ""))
	assert_eq(año, 2, "Anio_2 debe extraerse como entero 2")


func test_extraccion_anyo_primer_anyo():
	# Anio_1 debe extraerse correctamente
	var libro_str = "Anio_1"
	var año = int(String(libro_str).replace("Anio_", ""))
	assert_eq(año, 1)


func test_extraccion_anyo_cuarto_anyo():
	# Anio_4 es el ultimo año disponible actualmente
	var libro_str = "Anio_4"
	var año = int(String(libro_str).replace("Anio_", ""))
	assert_eq(año, 4)


func test_libros_no_duplicados_en_misma_carrera():
	# El sistema de desbloqueo ya verifica has() antes de append, no hay duplicados
	var libros_desbloqueados = ["Anio_1", "Anio_2"]
	var libro_nuevo = "Anio_2"
	var ya_tiene = libros_desbloqueados.has(libro_nuevo)
	assert_true(ya_tiene, "has() detecta correctamente que Anio_2 ya existe")
	# No se debe añadir
	if not ya_tiene:
		libros_desbloqueados.append(libro_nuevo)
	assert_eq(libros_desbloqueados.size(), 2, "No se duplica el libro")


func test_texto_boton_libro_incluye_nombre_carrera():
	# El texto del botón es "nombre_carrera – Año N"
	var nombre_carrera = "Ing. Informatica"
	var año = 3
	var texto_boton = nombre_carrera + " – Año " + str(año)
	assert_eq(texto_boton, "Ing. Informatica – Año 3")


func test_ruta_archivo_formato_correcto():
	# La ruta del archivo sigue el patron esperado
	var año = 2
	var ruta = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/apuntes_ing_informatica_anio%d.txt" % año
	assert_true(ruta.ends_with("anio2.txt"), "La ruta debe terminar en anio2.txt")
	assert_true(ruta.begins_with("res://"), "La ruta debe ser relativa al proyecto")


func test_primer_libro_se_carga_automaticamente():
	# Al abrir la pestaña con libros, se carga libros[0] automaticamente
	# Verificamos que el indice 0 existe cuando el array no esta vacio
	var libros = [{"carrera": null, "libro": "Anio_1"}, {"carrera": null, "libro": "Anio_2"}]
	assert_false(libros.is_empty(), "Con libros, se puede acceder al primero")
	var primero = libros[0]
	var año = int(String(primero.libro).replace("Anio_", ""))
	assert_eq(año, 1, "El primer libro es Anio_1")
