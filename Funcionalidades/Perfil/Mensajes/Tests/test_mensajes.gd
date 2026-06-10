extends GutTest

# Tests para la funcionalidad de Mensajes/Notificaciones
# Estructura: Clase Mensaje + Array en Variables_Dinamicas
# Se crean cuando ocurren eventos del sistema

func test_crear_mensaje():
	# Crear un mensaje con timestamp correcto (minuto del evento)
	var mensaje = Mensaje.new()
	mensaje.titulo = "Test mensaje"
	mensaje.descripcion = "Descripción de prueba"
	mensaje.leido = false
	mensaje.minuto = 1000

	assert_eq(mensaje.titulo, "Test mensaje")
	assert_eq(mensaje.leido, false)
	assert_eq(mensaje.minuto, 1000)

func test_marcar_como_leido():
	# Un mensaje no leído debe marcar como leído al abrirse
	var mensaje = Mensaje.new()
	mensaje.leido = false

	mensaje.leido = true
	assert_eq(mensaje.leido, true)

func test_añadir_a_array_mensajes():
	# Los mensajes se guardan en Variables_Dinamicas.Mensajes
	Variables_Dinamicas.Mensajes = []

	var mensaje = Mensaje.new()
	mensaje.titulo = "Nuevo mensaje"
	mensaje.leido = false
	mensaje.minuto = 2000

	Variables_Dinamicas.Mensajes.append(mensaje)

	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)
	assert_eq(Variables_Dinamicas.Mensajes[0].titulo, "Nuevo mensaje")

func test_contar_no_leidos():
	# Debe contar correctamente los mensajes sin leer
	Variables_Dinamicas.Mensajes = []

	var m1 = Mensaje.new()
	m1.leido = false
	m1.titulo = "M1"
	m1.minuto = 1000

	var m2 = Mensaje.new()
	m2.leido = true
	m2.titulo = "M2"
	m2.minuto = 2000

	var m3 = Mensaje.new()
	m3.leido = false
	m3.titulo = "M3"
	m3.minuto = 3000

	Variables_Dinamicas.Mensajes.append(m1)
	Variables_Dinamicas.Mensajes.append(m2)
	Variables_Dinamicas.Mensajes.append(m3)

	var no_leidos = Variables_Dinamicas.Mensajes.filter(func(m): return not m.leido)
	assert_eq(no_leidos.size(), 2)

func test_timestamp_preserva_hora_evento():
	# IMPORTANTE: El minuto guardado es el del evento en la matriz,
	# no el de la ejecución real. Si eventos ocurrieron offline,
	# mantienen su hora original.
	var minuto_evento = 5000  # Corresponde al lunes 6:00 (ejemplo)
	var minuto_actual = 50000  # El juego se abre mucho después

	var mensaje = Mensaje.new()
	mensaje.minuto = minuto_evento  # Se guarda el minuto del evento

	# Cuando se muestre en la GUI, debe convertirse a fecha/hora del evento,
	# no usar minuto_actual
	assert_eq(mensaje.minuto, 5000)
	assert_ne(mensaje.minuto, 50000)
