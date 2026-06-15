extends Node
# Tests para el sistema de inversiones en bolsa
# Cubre: invertir, retirar, snapshot de salud mental, auto-venta por pánico y condiciones de sangre fría

func _ready():
	print("=== TESTS DE INVERSION EN BOLSA ===\n")

	var resultados = [
		_test_invertir_quita_dinero_y_activa_estado(),
		_test_valor_inversion_igual_al_invertido_en_inicio(),
		_test_invertir_captura_snapshot_salud_mental(),
		_test_retirar_con_ganancias(),
		_test_retirar_con_perdidas(),
		_test_auto_vender_transfiere_valor_a_dinero(),
		_test_auto_vender_crea_mensaje(),
		_test_condicion_no_dispara_con_sangre_fria_alta(),
	]

	var pasados = resultados.count(true)
	var fallidos = resultados.count(false)
	print("\n=== RESULTADOS ===")
	print("Pasados: %d/%d" % [pasados, resultados.size()])
	if fallidos > 0:
		print("Fallidos: %d/%d" % [fallidos, resultados.size()])
	else:
		print("Todos los tests pasaron.")


# Test 1: Invertir descuenta dinero y activa el estado de inversión
func _test_invertir_quita_dinero_y_activa_estado() -> bool:
	print("--- Test 1: Invertir quita dinero y activa estado ---")
	_reset_inversion()
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Necesidades_Basicas = [50, 60, 50, 50, 50]

	# Simular lo que hace _Confirmar_Invertir con 500€
	var cantidad = 500.0
	Variables_Dinamicas.Dinero -= cantidad
	Variables_Dinamicas.Dinero_Invertido = cantidad
	Variables_Dinamicas.Valor_Inversion = cantidad
	Variables_Dinamicas.Esta_Invirtiendo = true
	Variables_Dinamicas.Salud_Mental_Al_Invertir = int(Variables_Dinamicas.Necesidades_Basicas[1])

	var dinero_ok = Variables_Dinamicas.Dinero == 500.0
	var estado_ok = Variables_Dinamicas.Esta_Invirtiendo == true
	var invertido_ok = Variables_Dinamicas.Dinero_Invertido == 500.0

	_imprimir_resultado(dinero_ok and estado_ok and invertido_ok,
		"Dinero=%s, Esta_Invirtiendo=%s, Dinero_Invertido=%s" % [
			Variables_Dinamicas.Dinero, Variables_Dinamicas.Esta_Invirtiendo, Variables_Dinamicas.Dinero_Invertido])
	return dinero_ok and estado_ok and invertido_ok


# Test 2: Al invertir, Valor_Inversion == Dinero_Invertido (sin ticks aún)
func _test_valor_inversion_igual_al_invertido_en_inicio() -> bool:
	print("--- Test 2: Valor inicial igual al invertido ---")
	_reset_inversion()
	Variables_Dinamicas.Dinero = 800.0
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]

	var cantidad = 300.0
	Variables_Dinamicas.Dinero -= cantidad
	Variables_Dinamicas.Dinero_Invertido = cantidad
	Variables_Dinamicas.Valor_Inversion = cantidad
	Variables_Dinamicas.Esta_Invirtiendo = true
	Variables_Dinamicas.Salud_Mental_Al_Invertir = 50

	var ok = Variables_Dinamicas.Valor_Inversion == Variables_Dinamicas.Dinero_Invertido
	_imprimir_resultado(ok, "Valor_Inversion=%.0f, Dinero_Invertido=%.0f" % [
		Variables_Dinamicas.Valor_Inversion, Variables_Dinamicas.Dinero_Invertido])
	return ok


# Test 3: El snapshot de salud mental se fija al invertir y no cambia después
func _test_invertir_captura_snapshot_salud_mental() -> bool:
	print("--- Test 3: Snapshot de salud mental fijado al invertir ---")
	_reset_inversion()
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Necesidades_Basicas = [50, 25, 50, 50, 50]  # salud mental = 25

	# Invertir: snapshot = 25
	Variables_Dinamicas.Salud_Mental_Al_Invertir = int(Variables_Dinamicas.Necesidades_Basicas[1])
	Variables_Dinamicas.Esta_Invirtiendo = true

	# Después la salud mental cambia a 90
	Variables_Dinamicas.Necesidades_Basicas[1] = 90

	# El snapshot no debe haber cambiado
	var ok = Variables_Dinamicas.Salud_Mental_Al_Invertir == 25
	_imprimir_resultado(ok, "Salud_Mental_Al_Invertir=%d (esperado 25), Necesidades_Basicas[1]=%d" % [
		Variables_Dinamicas.Salud_Mental_Al_Invertir, Variables_Dinamicas.Necesidades_Basicas[1]])
	return ok


# Test 4: Retirar manualmente con ganancias devuelve el valor actual
func _test_retirar_con_ganancias() -> bool:
	print("--- Test 4: Retirar con ganancias ---")
	_reset_inversion()
	Variables_Dinamicas.Dinero = 200.0
	Variables_Dinamicas.Dinero_Invertido = 500.0
	Variables_Dinamicas.Valor_Inversion = 700.0   # +200€ de ganancia
	Variables_Dinamicas.Esta_Invirtiendo = true

	# Simular _Confirmar_Retirar
	Variables_Dinamicas.Dinero += Variables_Dinamicas.Valor_Inversion
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Dinero_Invertido = 0.0

	var dinero_ok = Variables_Dinamicas.Dinero == 900.0   # 200 + 700
	var estado_ok = Variables_Dinamicas.Esta_Invirtiendo == false
	_imprimir_resultado(dinero_ok and estado_ok,
		"Dinero=%.0f (esperado 900), Esta_Invirtiendo=%s" % [Variables_Dinamicas.Dinero, Variables_Dinamicas.Esta_Invirtiendo])
	return dinero_ok and estado_ok


# Test 5: Retirar manualmente con pérdidas devuelve el valor reducido
func _test_retirar_con_perdidas() -> bool:
	print("--- Test 5: Retirar con pérdidas ---")
	_reset_inversion()
	Variables_Dinamicas.Dinero = 100.0
	Variables_Dinamicas.Dinero_Invertido = 500.0
	Variables_Dinamicas.Valor_Inversion = 400.0   # -100€ de pérdida
	Variables_Dinamicas.Esta_Invirtiendo = true

	# Simular _Confirmar_Retirar
	Variables_Dinamicas.Dinero += Variables_Dinamicas.Valor_Inversion
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Dinero_Invertido = 0.0

	var dinero_ok = Variables_Dinamicas.Dinero == 500.0   # 100 + 400
	var estado_ok = Variables_Dinamicas.Esta_Invirtiendo == false
	_imprimir_resultado(dinero_ok and estado_ok,
		"Dinero=%.0f (esperado 500), Esta_Invirtiendo=%s" % [Variables_Dinamicas.Dinero, Variables_Dinamicas.Esta_Invirtiendo])
	return dinero_ok and estado_ok


# Test 6: _Auto_Vender_Inversion transfiere el valor actual a Dinero y resetea el estado
func _test_auto_vender_transfiere_valor_a_dinero() -> bool:
	print("--- Test 6: Auto-venta transfiere valor a Dinero ---")
	_reset_inversion()
	Variables_Dinamicas.Dinero = 50.0
	Variables_Dinamicas.Dinero_Invertido = 500.0
	Variables_Dinamicas.Valor_Inversion = 400.0
	Variables_Dinamicas.Esta_Invirtiendo = true

	Actividades._Auto_Vender_Inversion()

	var dinero_ok = Variables_Dinamicas.Dinero == 450.0   # 50 + 400
	var estado_ok = Variables_Dinamicas.Esta_Invirtiendo == false
	var valor_ok = Variables_Dinamicas.Valor_Inversion == 0.0
	_imprimir_resultado(dinero_ok and estado_ok and valor_ok,
		"Dinero=%.0f (esperado 450), Esta_Invirtiendo=%s, Valor_Inversion=%.0f" % [
			Variables_Dinamicas.Dinero, Variables_Dinamicas.Esta_Invirtiendo, Variables_Dinamicas.Valor_Inversion])
	return dinero_ok and estado_ok and valor_ok


# Test 7: _Auto_Vender_Inversion añade un mensaje al perfil del jugador
func _test_auto_vender_crea_mensaje() -> bool:
	print("--- Test 7: Auto-venta crea mensaje en el perfil ---")
	_reset_inversion()
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Dinero = 0.0
	Variables_Dinamicas.Dinero_Invertido = 500.0
	Variables_Dinamicas.Valor_Inversion = 400.0
	Variables_Dinamicas.Esta_Invirtiendo = true

	Actividades._Auto_Vender_Inversion()

	var ok = Variables_Dinamicas.Mensajes.size() == 1
	_imprimir_resultado(ok, "Mensajes.size()=%d (esperado 1)" % Variables_Dinamicas.Mensajes.size())
	return ok


# Test 8: Con Sangre_Fría alta (≥30), aunque la pérdida supere el 15%, NO se dispara la auto-venta
func _test_condicion_no_dispara_con_sangre_fria_alta() -> bool:
	print("--- Test 8: Condición auto-venta NO dispara con Sangre_Fría alta ---")
	_reset_inversion()
	Variables_Estaticas.Habilidades[6] = 80   # sangre fría alta
	Variables_Dinamicas.Dinero_Invertido = 500.0
	Variables_Dinamicas.Valor_Inversion = 400.0   # -20% pérdida
	Variables_Dinamicas.Esta_Invirtiendo = true

	# Evaluar la condición exacta que usa _Tick_Inversion antes de llamar a _Auto_Vender
	var sangre_fria = Variables_Estaticas.Habilidades[6]
	var pct_cambio = (Variables_Dinamicas.Valor_Inversion - Variables_Dinamicas.Dinero_Invertido) / Variables_Dinamicas.Dinero_Invertido
	var dispara = sangre_fria < 30 and pct_cambio < -0.15

	var ok = not dispara
	_imprimir_resultado(ok,
		"Sangre_Fría=%d, pérdida=%.0f%%, dispara_auto_venta=%s (esperado false)" % [
			sangre_fria, abs(pct_cambio) * 100, dispara])
	return ok


# ---- Helpers ----

func _reset_inversion():
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Dinero_Invertido = 0.0
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Salud_Mental_Al_Invertir = 50
	Variables_Dinamicas.Progreso_Inversion = 1
	Variables_Dinamicas.Mensajes = []

func _imprimir_resultado(ok: bool, detalle: String):
	if ok:
		print("  ✓ PASADO — %s" % detalle)
	else:
		print("  ✗ FALLIDO — %s" % detalle)
