extends Node
# Tests para el sistema de Muerte.
# Para ejecutar: adjunta este script a un nodo en una escena vacía y lánzala.

const _BASE             := 1_875_000.0
const _TOLERANCIA_REL   := 0.02   # 2% tolerancia en comparaciones de max_valor


func _ready():
	print("=== TESTS DEL SISTEMA DE MUERTE ===\n")
	_Test_Muerte_Garantizada_99_Annos()
	_Test_Max_Valor_Edad18_Nec50()
	_Test_Max_Valor_Edad75_Nec50()
	_Test_Factor_Edad_Se_Dobla_Cada_10_Annos()
	_Test_Ratio_Necesidades_35x()
	_Test_Ratio_Vagabundo_vs_Cuidado()
	_Test_Joven_Buenas_Nec_No_Muere_En_10000()
	_Test_Prob_Supervivencia_Decrece_Con_Cada_Tick()
	_Test_Prob_Supervivencia_Cero_Con_Muerte_Garantizada()
	_Test_Edad_Muerte_Calculo()
	_Test_Esperanza_Vida_Matematica()
	print("\n=== FIN DE TESTS ===")


# ─────────────────────────────────────────────────────────────────────────────
# Helpers

func _OK(cond: bool, nombre: String, detalle: String = "") -> void:
	if cond:
		print("  ✅ %s" % nombre)
	else:
		print("  ❌ %s%s" % [nombre, (" — " + detalle) if detalle != "" else ""])


func _Guardar_Estado() -> Dictionary:
	return {
		"Minute_Day":   Variables_Dinamicas.Minute_Day,
		"Minute_Minute": Variables_Dinamicas.Minute_Minute,
		"Necesidades_Basicas": Variables_Dinamicas.Necesidades_Basicas.duplicate(),
		"Prob_Supervivencia_Acumulada": Variables_Dinamicas.Prob_Supervivencia_Acumulada,
		"Muerto":       Variables_Dinamicas.Muerto,
		"Edad_Muerte":  Variables_Dinamicas.Edad_Muerte,
	}


func _Restaurar_Estado(e: Dictionary) -> void:
	Variables_Dinamicas.Minute_Day    = e["Minute_Day"]
	Variables_Dinamicas.Minute_Minute = e["Minute_Minute"]
	Variables_Dinamicas.Necesidades_Basicas = e["Necesidades_Basicas"]
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = e["Prob_Supervivencia_Acumulada"]
	Variables_Dinamicas.Muerto      = e["Muerto"]
	Variables_Dinamicas.Edad_Muerte = e["Edad_Muerte"]


func _Max_Valor_Esperado(edad: int, media_nec: float) -> int:
	var factor_edad := pow(2.0, (edad - 18) / 10.0)
	var factor_nec  := pow(35.0, media_nec / 100.0)
	return max(1, int(_BASE * factor_nec / factor_edad))


# ─────────────────────────────────────────────────────────────────────────────
# TEST 1: Al llegar al último minuto de la matriz (Minute_Day=573, Minute_Minute=1439)
#         Comprobar_Muerte() siempre devuelve true sin importar las necesidades.
func _Test_Muerte_Garantizada_99_Annos() -> void:
	print("TEST 1 — Muerte garantizada al último minuto (99 años, domingo 23:59)")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 573
	Variables_Dinamicas.Minute_Minute = 1439
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = 1.0

	var todos_mueren := true
	for _i in range(20):
		if not Actividades.Comprobar_Muerte():
			todos_mueren = false
			break

	_OK(todos_mueren,
		"Siempre_True_Con_Necesidades_100",
		"Debería morir 20/20 veces aunque las necesidades sean perfectas")
	_OK(Actividades._ultima_prob_muerte_minuto == 1.0,
		"Prob_Minuto_Es_1_0",
		"_ultima_prob_muerte_minuto = %f" % Actividades._ultima_prob_muerte_minuto)
	_OK(Variables_Dinamicas.Prob_Supervivencia_Acumulada == 0.0,
		"Prob_Supervivencia_Pasa_A_Cero",
		"Valor = %f" % Variables_Dinamicas.Prob_Supervivencia_Acumulada)

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 2: A los 18 años con media=50, max_valor ≈ 5.928.750
#         factor_edad=1, factor_nec=√35≈5.916 → 1.875.000 × 5.916 / 1
func _Test_Max_Valor_Edad18_Nec50() -> void:
	print("TEST 2 — max_valor correcto a los 18 años (media=50)")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]

	Actividades.Comprobar_Muerte()

	var esperado  := _Max_Valor_Esperado(18, 50.0)
	var obtenido  := int(round(1.0 / Actividades._ultima_prob_muerte_minuto))
	var dif_rel   := abs(obtenido - esperado) / float(esperado)

	_OK(dif_rel < _TOLERANCIA_REL,
		"Max_Valor_Edad18_Nec50",
		"esperado %d, obtenido %d (dif %.2f%%)" % [esperado, obtenido, dif_rel * 100])

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 3: A los 75 años con media=50, max_valor ≈ 171.000
#         factor_edad=2^5.7≈52.0, factor_nec=5.916 → 1.875.000×5.916/52
func _Test_Max_Valor_Edad75_Nec50() -> void:
	print("TEST 3 — max_valor correcto a los 75 años (media=50)")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 57 * 7   # semana 57 → edad 18+57 = 75
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]

	Actividades.Comprobar_Muerte()

	var esperado  := _Max_Valor_Esperado(75, 50.0)
	var obtenido  := int(round(1.0 / Actividades._ultima_prob_muerte_minuto))
	var dif_rel   := abs(obtenido - esperado) / float(esperado)

	_OK(dif_rel < _TOLERANCIA_REL,
		"Max_Valor_Edad75_Nec50",
		"esperado %d, obtenido %d (dif %.2f%%)" % [esperado, obtenido, dif_rel * 100])

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 4: El riesgo se dobla exactamente cada 10 años (factor_edad = 2^((edad-18)/10))
func _Test_Factor_Edad_Se_Dobla_Cada_10_Annos() -> void:
	print("TEST 4 — factor_edad se dobla exactamente cada 10 años de vida")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]

	Variables_Dinamicas.Minute_Day = 0
	Actividades.Comprobar_Muerte()
	var prob_18 := Actividades._ultima_prob_muerte_minuto

	Variables_Dinamicas.Minute_Day = 10 * 7   # edad 28
	Actividades.Comprobar_Muerte()
	var prob_28 := Actividades._ultima_prob_muerte_minuto

	Variables_Dinamicas.Minute_Day = 20 * 7   # edad 38
	Actividades.Comprobar_Muerte()
	var prob_38 := Actividades._ultima_prob_muerte_minuto

	Variables_Dinamicas.Minute_Day = 42 * 7   # edad 60
	Actividades.Comprobar_Muerte()
	var prob_60 := Actividades._ultima_prob_muerte_minuto

	Variables_Dinamicas.Minute_Day = 52 * 7   # edad 70
	Actividades.Comprobar_Muerte()
	var prob_70 := Actividades._ultima_prob_muerte_minuto

	_OK(abs(prob_28 / prob_18 - 2.0) < 0.01,
		"Dobla_De_18_A_28",
		"ratio = %.4f (esperado 2.0)" % (prob_28 / prob_18))
	_OK(abs(prob_38 / prob_28 - 2.0) < 0.01,
		"Dobla_De_28_A_38",
		"ratio = %.4f (esperado 2.0)" % (prob_38 / prob_28))
	_OK(abs(prob_70 / prob_60 - 2.0) < 0.01,
		"Dobla_De_60_A_70",
		"ratio = %.4f (esperado 2.0)" % (prob_70 / prob_60))

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 5: Con misma edad, necesidades=100 da exactamente 35× más protección que nec=0
#         pow(35, 1.0) / pow(35, 0.0) = 35 / 1 = 35
func _Test_Ratio_Necesidades_35x() -> void:
	print("TEST 5 — nec=100 da 35× más protección que nec=0 (misma edad)")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 42 * 7   # edad 60
	Variables_Dinamicas.Minute_Minute = 0

	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	Actividades.Comprobar_Muerte()
	var prob_nec100 := Actividades._ultima_prob_muerte_minuto

	Variables_Dinamicas.Necesidades_Basicas = [0, 0, 0, 0, 0]
	Actividades.Comprobar_Muerte()
	var prob_nec0 := Actividades._ultima_prob_muerte_minuto

	var ratio := prob_nec0 / prob_nec100

	_OK(abs(ratio - 35.0) < 0.5,
		"Ratio_Nec0_vs_Nec100_Es_35x",
		"ratio = %.2f (esperado 35.0)" % ratio)

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 6: Ratio de peligrosidad entre vagabundo (nec≈20) y jugador cuidado (nec≈80)
#         pow(35, 0.8) / pow(35, 0.2) = 35^0.6 ≈ 8.44
func _Test_Ratio_Vagabundo_vs_Cuidado() -> void:
	print("TEST 6 — ratio peligrosidad vagabundo (nec=20) vs cuidado (nec=80) ≈ 8.44×")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 42 * 7   # edad 60
	Variables_Dinamicas.Minute_Minute = 0

	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Actividades.Comprobar_Muerte()
	var prob_80 := Actividades._ultima_prob_muerte_minuto

	Variables_Dinamicas.Necesidades_Basicas = [20, 20, 20, 20, 20]
	Actividades.Comprobar_Muerte()
	var prob_20 := Actividades._ultima_prob_muerte_minuto

	var ratio_obtenido  := prob_20 / prob_80
	var ratio_esperado  := pow(35.0, 0.6)   # 35^(0.8-0.2) ≈ 8.44

	_OK(abs(ratio_obtenido - ratio_esperado) < 0.2,
		"Ratio_Nec20_vs_Nec80",
		"ratio = %.2f (esperado 35^0.6 = %.2f)" % [ratio_obtenido, ratio_esperado])

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 7: Con 18 años y nec=90, 10.000 llamadas producen 0 muertes.
#         max_valor ≈ 45.900.000 → P(≥1 muerte en 10.000) ≈ 0.02%
func _Test_Joven_Buenas_Nec_No_Muere_En_10000() -> void:
	print("TEST 7 — 10.000 llamadas a los 18 años con nec=90 → 0 muertes esperadas")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Necesidades_Basicas = [90, 90, 90, 90, 90]

	var muertes := 0
	for _i in range(10000):
		if Actividades.Comprobar_Muerte():
			muertes += 1

	_OK(muertes == 0,
		"0_Muertes_En_10000_Intentos_Edad18_Nec90",
		"muertes obtenidas: %d (max_valor esperado ≈ %d)" % [muertes, _Max_Valor_Esperado(18, 90.0)])

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 8: Prob_Supervivencia_Acumulada decrece monótonamente con cada tick
func _Test_Prob_Supervivencia_Decrece_Con_Cada_Tick() -> void:
	print("TEST 8 — Prob_Supervivencia_Acumulada decrece en cada tick")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 63 * 7   # edad 81 (riesgo suficiente para observar cambios)
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = 1.0

	var siempre_decrece := true
	var anterior := 1.0
	for _i in range(200):
		Actividades.Comprobar_Muerte()
		var actual := Variables_Dinamicas.Prob_Supervivencia_Acumulada
		if actual >= anterior:
			siempre_decrece = false
			break
		anterior = actual

	var prob_final := Variables_Dinamicas.Prob_Supervivencia_Acumulada

	_OK(siempre_decrece,
		"Decrece_Monotonamente_En_200_Ticks")
	_OK(prob_final < 1.0 and prob_final > 0.0,
		"Prob_En_Rango_(0,1)_Tras_200_Ticks",
		"valor final = %.8f" % prob_final)

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 9: Con muerte garantizada, Prob_Supervivencia_Acumulada se fuerza a 0.0
func _Test_Prob_Supervivencia_Cero_Con_Muerte_Garantizada() -> void:
	print("TEST 9 — Prob_Supervivencia_Acumulada se fuerza a 0 con muerte garantizada")
	var e := _Guardar_Estado()

	Variables_Dinamicas.Minute_Day    = 573
	Variables_Dinamicas.Minute_Minute = 1439
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = 0.87

	Actividades.Comprobar_Muerte()

	_OK(Variables_Dinamicas.Prob_Supervivencia_Acumulada == 0.0,
		"Prob_Supervivencia_Es_Exactamente_Cero",
		"obtenido = %f" % Variables_Dinamicas.Prob_Supervivencia_Acumulada)

	_Restaurar_Estado(e)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 10: Edad_Muerte = 18 + floor(Minute_Day / 7) para valores clave
func _Test_Edad_Muerte_Calculo() -> void:
	print("TEST 10 — Edad_Muerte = 18 + floor(Minute_Day / 7)")

	# [Minute_Day, edad_esperada]
	var casos := [
		[0,   18],   # inicio de partida (semana 0)
		[6,   18],   # último día de la semana 0
		[7,   19],   # primera semana completa
		[70,  28],   # 10 semanas
		[350, 68],   # 50 semanas
		[399, 75],   # 57 semanas (esperanza media=50)
		[441, 81],   # 63 semanas
		[567, 99],   # semana 81, primer día
		[573, 99],   # último día de la matriz
	]

	for caso in casos:
		var minute_day    : int = caso[0]
		var edad_esperada : int = caso[1]
		var edad_calc     : int = 18 + int(minute_day / 7.0)
		_OK(edad_calc == edad_esperada,
			"Minute_Day_%d_→_Edad_%d" % [minute_day, edad_esperada],
			"calculada: %d" % edad_calc)
	print()


# ─────────────────────────────────────────────────────────────────────────────
# TEST 11: Verificación analítica de que esperanza_vida ≈ 50 + media/2
#          Calcula la mediana matemáticamente y comprueba que coincide (±2 años)
#          con los valores documentados. Sin aleatoriedad.
func _Test_Esperanza_Vida_Matematica() -> void:
	print("TEST 11 — Verificación analítica: esperanza_vida ≈ 50 + media/2")

	# Mediana satisface: SUM(k=0..m) = ln(2) × BASE_nec / 10080
	# SUM = (2^((m+1)/10) - 1) / (2^(1/10) - 1)
	# Despejando: m = log2(SUM × r + 1) × 10 - 1,  con r = 2^(1/10) - 1 ≈ 0.07177

	var r := pow(2.0, 0.1) - 1.0

	# [media, esperanza_documentada]
	var casos := [
		[1.0,   50],
		[20.0,  60],
		[50.0,  75],
		[80.0,  90],
		[100.0, 100],
	]

	for caso in casos:
		var media         : float = caso[0]
		var edad_esperada : int   = caso[1]

		var factor_nec    := pow(35.0, media / 100.0)
		var base_nec      := _BASE * factor_nec
		var sum_necesario := log(2.0) * base_nec / 10080.0
		var potencia      := sum_necesario * r + 1.0
		var m             := (log(potencia) / log(2.0)) * 10.0 - 1.0
		var edad_calc     := int(18.0 + m)

		_OK(abs(edad_calc - edad_esperada) <= 2,
			"Media_%d_→_Esperanza_%d" % [int(media), edad_esperada],
			"fórmula da %d (dif %d año/s)" % [edad_calc, abs(edad_calc - edad_esperada)])
	print()
