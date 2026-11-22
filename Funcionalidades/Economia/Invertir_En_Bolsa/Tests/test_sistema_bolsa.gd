extends GutTest

# Tests del motor de inversión pasiva (Sistema_Bolsa), del historial y de la
# pantalla de bolsa. No dependen de la UI del juego más que para comprobar que
# la pantalla se construye sin errores.

var _dinero_previo: float
var _necesidades_previas: Array
var _mensajes_previos: Array
var _habilidades_previas: Array
var _minute_day_previo: int
var _minute_minute_previo: int
var _progreso_previo: int
var _save_path_previo: String


func before_each() -> void:
	_dinero_previo = Variables_Dinamicas.Dinero
	_necesidades_previas = Variables_Dinamicas.Necesidades_Basicas.duplicate(true)
	_mensajes_previos = Variables_Dinamicas.Mensajes.duplicate(true)
	_habilidades_previas = Variables_Estaticas.Habilidades.duplicate(true)
	_minute_day_previo = Variables_Dinamicas.Minute_Day
	_minute_minute_previo = Variables_Dinamicas.Minute_Minute
	_progreso_previo = Variables_Dinamicas.Progreso_Inversion
	_save_path_previo = Guardar_Variables_Dinamicas.save_path

	Sistema_Bolsa.Reiniciar_Estado()
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Dinero_Invertido = 0.0
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Salud_Mental_Al_Invertir = 50
	Variables_Dinamicas.Progreso_Inversion = 1
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Necesidades_Basicas = [50, 60, 50, 50, 50]
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]


func after_each() -> void:
	Variables_Dinamicas.Dinero = _dinero_previo
	Variables_Dinamicas.Necesidades_Basicas = _necesidades_previas
	Variables_Dinamicas.Mensajes = _mensajes_previos
	Variables_Estaticas.Habilidades = _habilidades_previas
	Variables_Dinamicas.Minute_Day = _minute_day_previo
	Variables_Dinamicas.Minute_Minute = _minute_minute_previo
	Variables_Dinamicas.Progreso_Inversion = _progreso_previo
	Guardar_Variables_Dinamicas.save_path = _save_path_previo
	Sistema_Bolsa.Reiniciar_Estado()
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Dinero_Invertido = 0.0
	Variables_Dinamicas.Valor_Inversion = 0.0


func test_invertir_descuenta_y_activa_posicion() -> void:
	var r := Sistema_Bolsa.Invertir(500.0, 0)

	assert_true(r["ok"])
	assert_almost_eq(Variables_Dinamicas.Dinero, 500.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 500.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Valor_Inversion, 500.0, 0.01)
	assert_true(Variables_Dinamicas.Esta_Invirtiendo)
	assert_eq(Variables_Dinamicas.Salud_Mental_Al_Invertir, 60)
	assert_eq(Variables_Dinamicas.Inversion_Num_Aportes, 1)
	assert_eq(Variables_Dinamicas.Inversion_Operaciones.size(), 1)
	assert_eq(Variables_Dinamicas.Inversion_Historial.size(), 1)


func test_aportar_suma_capital_a_la_posicion_actual() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	var r := Sistema_Bolsa.Invertir(200.0, 10)

	assert_true(r["ok"])
	assert_almost_eq(Variables_Dinamicas.Dinero, 300.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 700.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Valor_Inversion, 700.0, 0.01)
	assert_eq(Variables_Dinamicas.Inversion_Num_Aportes, 2)
	assert_eq(Variables_Dinamicas.Inversion_Aportado_Total, 700.0)


func test_retirada_parcial_reparte_el_coste_y_el_beneficio() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	Sistema_Bolsa.Invertir(200.0, 10)
	Sistema_Bolsa.Realizar_Evento(20, 0.10, "Subida de prueba", "normal")
	var r := Sistema_Bolsa.Retirar(385.0, "manual", 30)

	assert_true(r["ok"])
	assert_false(r["cerrado"])
	assert_almost_eq(float(r["beneficio"]), 35.0, 0.5)
	assert_almost_eq(Variables_Dinamicas.Dinero, 685.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 350.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Valor_Inversion, 385.0, 0.01)
	assert_true(Variables_Dinamicas.Esta_Invirtiendo)
	assert_almost_eq(Sistema_Bolsa.Beneficio_Acumulado(), 70.0, 0.5)


func test_retirada_total_cierra_y_registra_ganancia() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	Sistema_Bolsa.Realizar_Evento(10, 0.10, "Subida de prueba", "normal")
	var r := Sistema_Bolsa.Retirar_Todo("manual", 20)

	assert_true(r["ok"])
	assert_true(r["cerrado"])
	assert_false(Variables_Dinamicas.Esta_Invirtiendo)
	assert_almost_eq(Variables_Dinamicas.Dinero, 1050.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Valor_Inversion, 0.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 0.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Inversion_Beneficio_Realizado, 50.0, 0.5)
	assert_eq(Variables_Dinamicas.Inversion_Cierres_Ganadores, 1)
	assert_eq(Variables_Dinamicas.Inversion_Operaciones.size(), 2)


func test_retirada_total_con_perdida_registra_estadistica() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	Sistema_Bolsa.Realizar_Evento(10, -0.10, "Caída de prueba", "normal")
	Sistema_Bolsa.Retirar_Todo("manual", 20)

	var stats := Sistema_Bolsa.Obtener_Estadisticas()
	assert_almost_eq(float(stats["beneficio_total"]), -50.0, 0.5)
	assert_eq(int(stats["perdedoras"]), 1)
	assert_eq(int(stats["ganadoras"]), 0)
	assert_almost_eq(float(stats["peor_operacion"]), -50.0, 0.5)
	assert_false(bool(stats["activa"]))


func test_auto_venta_por_panico_cierra_la_posicion() -> void:
	Variables_Estaticas.Habilidades[6] = 10
	Sistema_Bolsa.Invertir(500.0, 0)
	Sistema_Bolsa.Realizar_Evento(10, -0.20, "Pánico de prueba", "shock")

	assert_false(Variables_Dinamicas.Esta_Invirtiendo)
	assert_almost_eq(Variables_Dinamicas.Dinero, 900.0, 0.5)
	assert_eq(Variables_Dinamicas.Inversion_Panicos, 1)
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)
	assert_eq(Variables_Dinamicas.Inversion_Cierres_Perdedores, 1)


func test_sangre_fria_alta_evita_auto_venta() -> void:
	Variables_Estaticas.Habilidades[6] = 80
	Sistema_Bolsa.Invertir(500.0, 0)
	Sistema_Bolsa.Realizar_Evento(10, -0.20, "Caída temporal", "shock")

	assert_true(Variables_Dinamicas.Esta_Invirtiendo)
	assert_eq(Variables_Dinamicas.Inversion_Panicos, 0)
	assert_eq(Variables_Dinamicas.Mensajes.size(), 0)


func test_cerrar_en_positivo_sube_un_punto_el_nivel() -> void:
	Variables_Dinamicas.Progreso_Inversion = 10
	Sistema_Bolsa.Invertir(100.0, 0)
	# Subimos el valor a mano para no depender del azar del evento.
	Variables_Dinamicas.Valor_Inversion = 150.0
	Sistema_Bolsa.Retirar_Todo("manual", 10)

	assert_eq(Variables_Dinamicas.Progreso_Inversion, 11)


func test_estadisticas_resumen_aportes_y_beneficio() -> void:
	Sistema_Bolsa.Invertir(200.0, 0)
	Sistema_Bolsa.Invertir(300.0, 10)
	Variables_Dinamicas.Valor_Inversion = 600.0
	var stats := Sistema_Bolsa.Obtener_Estadisticas()

	assert_almost_eq(float(stats["aportado_total"]), 500.0, 0.01)
	assert_almost_eq(float(stats["beneficio_no_realizado"]), 100.0, 0.01)
	assert_almost_eq(float(stats["beneficio_total"]), 100.0, 0.01)
	assert_almost_eq(float(stats["rentabilidad"]), 20.0, 0.01)
	assert_eq(int(stats["num_aportes"]), 2)
	assert_eq(int(stats["operaciones"]), 2)
	assert_true(bool(stats["activa"]))


func test_historial_filtra_por_minuto() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	for m in [1000, 2000, 3000]:
		Sistema_Bolsa.Realizar_Evento(m, 0.01, "Movimiento", "normal")

	var reciente := Sistema_Bolsa.Obtener_Historial(1500, 3000)
	assert_gt(reciente.size(), 1)
	assert_true(int(reciente[0]["minuto"]) <= 1500)
	assert_eq(int(reciente[-1]["minuto"]), 3000)


func test_historial_se_compacta_si_crece_demasiado() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	for m in range(1, 701):
		Sistema_Bolsa.Realizar_Evento(m, 0.0, "Movimiento plano", "normal")

	assert_true(Variables_Dinamicas.Inversion_Historial.size() <= 600,
		"El historial no debe superar el máximo")
	assert_true(Variables_Dinamicas.Inversion_Historial.size() > 300,
		"El historial debe conservar suficientes puntos")


func test_asegurar_estado_siembra_historial_en_saves_antiguos() -> void:
	Variables_Dinamicas.Esta_Invirtiendo = true
	Variables_Dinamicas.Dinero_Invertido = 500.0
	Variables_Dinamicas.Valor_Inversion = 550.0
	Variables_Dinamicas.Inversion_Historial = []
	Variables_Dinamicas.Inversion_Aportado_Total = 0.0
	Variables_Dinamicas.Inversion_Minuto_Inicio = -1

	Sistema_Bolsa.Asegurar_Estado()

	assert_false(Variables_Dinamicas.Inversion_Historial.is_empty())
	assert_almost_eq(Variables_Dinamicas.Inversion_Aportado_Total, 500.0, 0.01)
	assert_eq(Variables_Dinamicas.Inversion_Minuto_Inicio, Sistema_Bolsa.Minuto_Actual())


func test_asegurar_estado_limpia_posicion_invalida() -> void:
	Variables_Dinamicas.Esta_Invirtiendo = true
	Variables_Dinamicas.Dinero_Invertido = 100.0
	Variables_Dinamicas.Valor_Inversion = 0.0

	Sistema_Bolsa.Asegurar_Estado()

	assert_false(Variables_Dinamicas.Esta_Invirtiendo)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 0.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Valor_Inversion, 0.0, 0.01)


func test_partida_guardada_incluye_las_claves_de_bolsa() -> void:
	var data: Dictionary = Guardar_Variables_Dinamicas.game_data_func()
	for clave in [
		"Progreso_Inversion", "Inversion_Historial", "Inversion_Operaciones",
		"Inversion_Eventos", "Inversion_Beneficio_Realizado",
		"Inversion_Max_Caida", "Inversion_Panicos",
	]:
		assert_true(data.has(clave), "Falta la clave %s en el guardado" % clave)


func test_guardado_atomico_conserva_respaldo_y_no_deja_temporales() -> void:
	var ruta := "user://test_bolsa_atomica.dat"
	var ruta_bak := ruta + ".bak"
	var ruta_tmp := ruta + ".tmp"
	for r in [ruta, ruta_bak, ruta_tmp]:
		if FileAccess.file_exists(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	Guardar_Variables_Dinamicas.save_path = ruta
	Variables_Dinamicas.Dinero = 321.0
	Guardar_Variables_Dinamicas.save_game()
	assert_true(FileAccess.file_exists(ruta), "Debe existir el guardado principal")
	assert_false(FileAccess.file_exists(ruta_tmp), "No debe quedar el temporal")

	Variables_Dinamicas.Dinero = 654.0
	Guardar_Variables_Dinamicas.save_game()
	assert_true(FileAccess.file_exists(ruta_bak), "El segundo guardado debe crear .bak")

	for r in [ruta, ruta_bak, ruta_tmp]:
		if FileAccess.file_exists(r):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	Guardar_Variables_Dinamicas.save_path = _save_path_previo


func test_panel_bolsa_se_construye_y_cambia_de_pestana() -> void:
	var panel := Panel_Bolsa.new()
	add_child_autofree(panel)
	await wait_process_frames(1)

	assert_not_null(panel._hero_valor)
	assert_not_null(panel._evo_chart)
	assert_true(panel._contenidos["resumen"].visible)

	panel.Abrir("evolucion")
	await wait_process_frames(1)

	assert_true(panel.visible)
	assert_true(panel._contenidos["evolucion"].visible)
	assert_false(panel._contenidos["resumen"].visible)
	panel.cerrar()


func test_dialogo_de_inversion_compra_y_actualiza_la_cartera() -> void:
	var panel := Panel_Bolsa.new()
	add_child_autofree(panel)
	await wait_process_frames(1)

	panel._mostrar_dialogo("invertir")
	panel._poner_cantidad_rapida(0.5)
	panel._confirmar_dialogo()
	await wait_process_frames(1)

	assert_almost_eq(Variables_Dinamicas.Dinero, 500.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 500.0, 0.01)
	assert_true(Variables_Dinamicas.Esta_Invirtiendo)
	assert_eq(panel._hero_btn_aportar.visible, true)
	assert_eq(panel._hero_btn_invertir.visible, false)
	panel.cerrar()


func test_dialogo_de_retirada_parcial_actualiza_la_cartera() -> void:
	Sistema_Bolsa.Invertir(500.0, 0)
	var panel := Panel_Bolsa.new()
	add_child_autofree(panel)
	await wait_process_frames(1)

	panel._mostrar_dialogo("retirar")
	panel._dlg_input.text = "200"
	panel._confirmar_dialogo()
	await wait_process_frames(1)

	assert_almost_eq(Variables_Dinamicas.Dinero, 700.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Valor_Inversion, 300.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero_Invertido, 300.0, 0.01)
	assert_true(Variables_Dinamicas.Esta_Invirtiendo)
	panel.cerrar()


func test_grafico_bolsa_admite_historial_y_marcadores() -> void:
	var grafico := Grafico_Bolsa.new()
	add_child_autofree(grafico)
	grafico.size = Vector2(600, 240)
	await wait_process_frames(1)
	grafico.Configurar([
		{"minuto": 0, "beneficio": 0.0, "valor": 500.0, "invertido": 500.0},
		{"minuto": 1000, "beneficio": 50.0, "valor": 550.0, "invertido": 500.0},
		{"minuto": 2000, "beneficio": -20.0, "valor": 480.0, "invertido": 500.0},
	], [
		{"minuto": 0, "tipo": "aporte", "acumulado": 0.0},
		{"minuto": 2000, "tipo": "retirada", "acumulado": -20.0},
	])
	await wait_process_frames(1)
	assert_eq(grafico.puntos.size(), 3)
	assert_eq(grafico.marcadores.size(), 2)
