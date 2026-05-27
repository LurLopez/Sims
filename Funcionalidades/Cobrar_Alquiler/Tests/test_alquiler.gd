extends Node
# Tests para el sistema de alquiler timer-based

class TestAlquiler:
	var nombre: String
	var dinero_inicial: int
	var en_la_calle_inicial: bool
	var ultima_fecha_inicial: int
	var minutos_a_pasar: int
	var esperado_dinero: int
	var esperado_en_la_calle: bool
	var esperado_ultima_fecha: int
	var descripcion: String

	func _init(n: String, d: int, c: bool, f: int, m: int, ed: int, ec: bool, ef: int, desc: String):
		nombre = n
		dinero_inicial = d
		en_la_calle_inicial = c
		ultima_fecha_inicial = f
		minutos_a_pasar = m
		esperado_dinero = ed
		esperado_en_la_calle = ec
		esperado_ultima_fecha = ef
		descripcion = desc

func _ready():
	print("=== TESTS DE ALQUILER ===\n")

	var tests = [
		# Test 1: Primera vez - alquiler cobra después de 7 días
		TestAlquiler.new(
			"Test_1_Primer_Alquiler",
			1000, false, 0,  # Dinero=1000, en_alquiler, última_fecha=minuto 0
			7 * 1440,  # Pasar exactamente 7 días
			800, false, 7*1440,  # Esperado: 800€, sigue alquilando, actualiza última_fecha
			"Primer alquiler: 1000€ - 200€ = 800€ después de 7 días"
		),

		# Test 2: Ir a la calle voluntariamente
		TestAlquiler.new(
			"Test_2_Ir_A_La_Calle",
			1000, false, 0,
			0,  # Sin pasar tiempo
			1000, true, -1,  # Se queda con 1000€, en_la_calle=true, última_fecha=-1
			"Ir a la calle voluntariamente: se anula el timer"
		),

		# Test 3: Dinero insuficiente al cobrar (150€)
		TestAlquiler.new(
			"Test_3_Dinero_Insuficiente",
			150, false, 0,
			7 * 1440,  # Llega la hora de cobrar
			150, true, -1,  # Se va a la calle, se queda con 150€, última_fecha=-1
			"Dinero insuficiente: 150€ < 200€ → va a la calle sin perder dinero"
		),

		# Test 4: Volver a alquiler desde la calle (con 300€)
		TestAlquiler.new(
			"Test_4_Volver_A_Alquiler",
			300, true, -1,
			0,  # Sin pasar tiempo
			100, false, 0,  # Se queda con 100€ (300-200), en_alquiler=true, última_fecha=minuto actual
			"Volver a alquiler: 300€ - 200€ = 100€, inicia nuevo timer"
		),

		# Test 5: Intenta volver a alquiler sin dinero suficiente (150€)
		TestAlquiler.new(
			"Test_5_Sin_Dinero_Para_Volver",
			150, true, -1,
			0,  # Sin pasar tiempo
			150, true, -1,  # Se queda en la calle, dinero sin cambiar
			"Sin dinero para volver: 150€ < 200€ → permanece en la calle"
		),

		# Test 6: Segundo alquiler después de volver (7 días después de entrar)
		TestAlquiler.new(
			"Test_6_Segundo_Alquiler",
			500, false, 0,  # Acaba de volver (última_fecha=0)
			7 * 1440,  # Pasar 7 días
			300, false, 7*1440,  # 500€ - 200€ = 300€
			"Segundo alquiler: cobra después de 7 días de haber vuelto"
		),
	]

	var tests_pasados = 0
	var tests_fallidos = 0

	for test in tests:
		print("--- %s ---" % test.nombre)
		print("Descripción: %s" % test.descripcion)
		print("Inicial: Dinero=%d€, En_La_Calle=%s, Última_Fecha=%d" % [test.dinero_inicial, test.en_la_calle_inicial, test.ultima_fecha_inicial])

		# Simular el test
		var resultado = Simular_Test(test)

		if resultado:
			print("✓ PASADO\n")
			tests_pasados += 1
		else:
			print("✗ FALLIDO\n")
			tests_fallidos += 1

	print("=== RESULTADOS ===")
	print("Pasados: %d/%d" % [tests_pasados, tests.size()])
	print("Fallidos: %d/%d" % [tests_fallidos, tests.size()])

func Simular_Test(test: TestAlquiler) -> bool:
	# Configurar estado inicial
	Variables_Dinamicas.Dinero = test.dinero_inicial
	Variables_Dinamicas.En_La_Calle = test.en_la_calle_inicial
	Variables_Dinamicas.Ultima_Fecha_Alquiler = test.ultima_fecha_inicial
	Variables_Dinamicas.Minute = test.ultima_fecha_inicial
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0

	# Simular acciones según el test
	if test.nombre == "Test_2_Ir_A_La_Calle":
		Actividades.Ir_A_La_Calle()
	elif test.nombre == "Test_4_Volver_A_Alquiler":
		Actividades.Volver_A_Alquiler()
	elif test.nombre == "Test_5_Sin_Dinero_Para_Volver":
		Actividades.Volver_A_Alquiler()

	# Simular pasar minutos
	if test.minutos_a_pasar > 0:
		Variables_Dinamicas.Minute += test.minutos_a_pasar
		# Actualizar Minute_Day y Minute_Minute
		var total_minutos = Variables_Dinamicas.Minute
		Variables_Dinamicas.Minute_Day = total_minutos / 1440
		Variables_Dinamicas.Minute_Minute = total_minutos % 1440

		# Ejecutar lógica de cobro si aplica
		if not Variables_Dinamicas.En_La_Calle and Variables_Dinamicas.Ultima_Fecha_Alquiler >= 0:
			var minutos_desde_alquiler = Variables_Dinamicas.Minute - Variables_Dinamicas.Ultima_Fecha_Alquiler
			if minutos_desde_alquiler >= 7 * 1440:
				Actividades.Cobrar_Alquiler()

	# Verificar resultados
	var dinero_ok = Variables_Dinamicas.Dinero == test.esperado_dinero
	var calle_ok = Variables_Dinamicas.En_La_Calle == test.esperado_en_la_calle
	var fecha_ok = Variables_Dinamicas.Ultima_Fecha_Alquiler == test.esperado_ultima_fecha

	print("Esperado: Dinero=%d€, En_La_Calle=%s, Última_Fecha=%d" % [test.esperado_dinero, test.esperado_en_la_calle, test.esperado_ultima_fecha])
	print("Obtenido: Dinero=%d€, En_La_Calle=%s, Última_Fecha=%d" % [Variables_Dinamicas.Dinero, Variables_Dinamicas.En_La_Calle, Variables_Dinamicas.Ultima_Fecha_Alquiler])

	if not dinero_ok:
		print("  ✗ Dinero incorrecto")
	if not calle_ok:
		print("  ✗ Estado En_La_Calle incorrecto")
	if not fecha_ok:
		print("  ✗ Última_Fecha_Alquiler incorrecto")

	return dinero_ok and calle_ok and fecha_ok
