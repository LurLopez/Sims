extends GutTest

# Tests de Salir_De_Fiesta, Euforia y Resacón.
# Cubre AC-01 a AC-17 de Prompts/salir-de-fiesta/salir-de-fiesta.md (v1.0 + correcciones A).

const NOMBRE := "Salir_De_Fiesta"


func before_all():
	_Inicializar_Matriz()


func before_each():
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Dinamicas.Progreso = [50, 50, 50]
	Variables_Estaticas.Personalidad = ""
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Dinamicas.Habilidades_Mostradas = [0, 0, 0, 0, 0, 0, 0]
	Variables_Estaticas.First_Time_Minute_Day = 0
	Variables_Dinamicas.Minute_Day = 10
	Variables_Dinamicas.Minute_Minute = 1200
	Variables_Dinamicas.Minute = 10 * 1440 + 1200
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = false
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Dinero = 500
	Variables_Dinamicas.Muerto = false
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Ultima_Fecha_Alquiler = -1
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = 1.0
	Variables_Dinamicas.Cooldown_Trabajos = {}
	_Limpiar_Celdas()


func after_each():
	var ruta_prueba := "user://test_salir_de_fiesta.dat"
	if FileAccess.file_exists(ruta_prueba):
		DirAccess.remove_absolute(ruta_prueba)
	Guardar_Variables_Dinamicas.save_path = "user://guardado//variables//Guardar_Variables_Dinamicas.dat"


func _Inicializar_Matriz() -> void:
	if Variables_Dinamicas.Matriz_Jugador.size() == 1440:
		return
	Variables_Dinamicas.Matriz_Jugador = []
	for i in range(1440):
		var fila: Array = []
		fila.resize(574)
		fila.fill("")
		Variables_Dinamicas.Matriz_Jugador.append(fila)


func _Limpiar_Celdas() -> void:
	for fila in range(1440):
		for columna in range(8, 13):
			Variables_Dinamicas.Matriz_Jugador[fila][columna] = ""


func _NB(valor: int) -> Array:
	return [valor, valor, valor, valor, valor]


func _Simular(nb: Array, duracion: int, dia_noche: int = 3, edad: int = 36) -> Dictionary:
	return Actividades.Simular_Preview_Fiesta(nb, [50, 50, 50], "", duracion, edad, dia_noche)


# ---------------------------------------------------------------------------
# AC-01: catálogo, efectos, prioridad y pool aleatorio
# ---------------------------------------------------------------------------

func test_catalogo_fiesta_existe_como_temporal_p1():
	var act = Variables_Estaticas.Catalogo_Actividades.get(NOMBRE, null)
	assert_not_null(act, "Salir_De_Fiesta debe existir en el catálogo")
	assert_true(act is Actividad_Temporal, "Debe ser una Actividad_Temporal")
	assert_eq(act.nombre, NOMBRE)
	assert_eq(act.Obtener_Prioridad(), 1, "Debe ser prioridad P1")
	assert_eq(act.efectos_necesidades_basicas, [0, 9, -3, -4, -2])
	assert_eq(act.efectos_progreso, [0, 0, 0])
	assert_true(act.color.is_equal_approx(Color(0.85, 0.15, 0.45)))


func test_fiesta_no_entra_en_el_pool_aleatorio():
	for act in Variables_Estaticas.Actividades:
		assert_ne(act.nombre, NOMBRE, "Salir_De_Fiesta no debe estar en el pool aleatorio")
	assert_eq(Variables_Estaticas.Actividades.size(), 7, "El pool debe conservar sus 7 actividades")


func test_no_regresion_efectos_actividades_existentes():
	var esperados := {
		"Dormir": [1, 1, -1, 4, -1],
		"Comer": [-1, 2, 20, -1, -1],
		"Duchar": [1, 1, -1, -1, 20],
		"Ver_La_Television": [-1, 5, -1, 2, -1],
		"Estudiar": [-1, -2, -1, -2, -1],
		"Salir_A_Correr": [4, 2, -3, -3, -4],
		"Practicar_Manualidades": [-2, -1, -1, -2, -1],
	}
	for nombre in esperados:
		var act = Variables_Estaticas.Catalogo_Actividades[nombre]
		assert_eq(act.efectos_necesidades_basicas, esperados[nombre], "Efectos alterados en %s" % nombre)


# ---------------------------------------------------------------------------
# AC-02: botón, subtítulo, icono y conexión
# ---------------------------------------------------------------------------

func test_boton_fiesta_en_escena_y_conectado():
	var packed = load("res://Escenas/Escena_Principal/Escena principal.tscn")
	var raiz = packed.instantiate()
	var boton = raiz.get_node_or_null(
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones/Salir_De_Fiesta")
	assert_not_null(boton, "El botón Salir_De_Fiesta debe existir en la escena")
	assert_true(boton is Button)
	assert_true(boton.pressed.is_connected(Callable(raiz, "Actividad_Terminada_Salir_De_Fiesta")),
		"El botón debe estar conectado al handler")
	assert_true(str(boton.text).contains("SALIR DE FIESTA"))
	raiz.free()


func test_icono_subtitulo_y_asset():
	assert_true(Estilos_UI.ICONOS_BOTONES.has(NOMBRE))
	assert_eq(Estilos_UI.ICONOS_BOTONES[NOMBRE][1], "party-popper")
	var script = load("res://Scripts/Globales/Script_Principal.gd")
	var constantes = script.get_script_constant_map()
	var subtitulos: Dictionary = constantes.get("_SUBTITULOS_ACTIVIDADES", {})
	assert_true(subtitulos.has(NOMBRE), "Debe existir subtítulo para Salir_De_Fiesta")
	assert_eq(subtitulos[NOMBRE][0], "party-popper")
	assert_true(str(subtitulos[NOMBRE][1]).contains("2–12 h"))
	assert_true(ResourceLoader.exists("res://Imagenes/UI/Iconos/party-popper.svg"))


func test_contenedor_necesidades_tiene_cinco_botones():
	var packed = load("res://Escenas/Escena_Principal/Escena principal.tscn")
	var raiz = packed.instantiate()
	var contenedor = raiz.get_node(
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones")
	assert_eq(contenedor.get_child_count(), 5)
	raiz.free()


func test_layout_cinco_botones_cabe_sin_scroll():
	var packed = load("res://Escenas/Escena_Principal/Escena principal.tscn")
	var raiz = packed.instantiate()
	raiz._Redisenar_Actividades()
	var tipos = raiz.get_node("Actividades/Elegir_Actividad/Tipos_De_Actividades")
	var contenedor = raiz.get_node(
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones")
	assert_eq(tipos.size.y, 960.0)
	assert_eq(contenedor.get_theme_constant("separation"), 10)
	var alto_total: int = 5 * 78 + 4 * 10
	assert_lte(float(alto_total), tipos.size.y, "Los 5 botones deben caber en el contenedor")
	raiz.free()


# ---------------------------------------------------------------------------
# AC-03 a AC-06: ventana horaria y cruce de medianoche
# ---------------------------------------------------------------------------

func test_ventana_inicio_1759_rechazado():
	var r = Actividades.Validar_Horario_Fiesta(0, 17, 59, 1, 6, 0)
	assert_false(r["valido"])
	assert_true(str(r["motivo"]).contains("18:00"))


func test_ventana_18_06_aceptada_12h():
	var r = Actividades.Validar_Horario_Fiesta(0, 18, 0, 1, 6, 0)
	assert_true(r["valido"])
	assert_eq(r["duracion_min"], 720)


func test_ventana_18_1959_rechazada_por_duracion_minima():
	var r = Actividades.Validar_Horario_Fiesta(0, 18, 0, 0, 19, 59)
	assert_false(r["valido"])
	assert_true(str(r["motivo"]).contains("al menos 2 horas"))


func test_ventana_18_20_aceptada_2h():
	var r = Actividades.Validar_Horario_Fiesta(0, 18, 0, 0, 20, 0)
	assert_true(r["valido"])
	assert_eq(r["duracion_min"], 120)


func test_ventana_18_0601_rechazada_por_fin():
	var r = Actividades.Validar_Horario_Fiesta(0, 18, 0, 1, 6, 1)
	assert_false(r["valido"])
	assert_true(str(r["motivo"]).contains("06:00"))


func test_ventana_18_0559_aceptada():
	var r = Actividades.Validar_Horario_Fiesta(0, 18, 0, 1, 5, 59)
	assert_true(r["valido"])
	assert_eq(r["duracion_min"], 719)


func test_ventana_22_02_aceptada_cruce():
	var r = Actividades.Validar_Horario_Fiesta(0, 22, 0, 1, 2, 0)
	assert_true(r["valido"])
	assert_eq(r["duracion_min"], 240)


func test_ventana_22_02_mismo_dia_se_normaliza():
	var r = Actividades.Validar_Horario_Fiesta(0, 22, 0, 0, 2, 0)
	assert_true(r["valido"], "El mismo día con horas de cruce debe aceptarse y normalizarse")
	assert_eq(r["duracion_min"], 240)


func test_ventana_02_06_aceptada_madrugada():
	var r = Actividades.Validar_Horario_Fiesta(0, 2, 0, 0, 6, 0)
	assert_true(r["valido"])
	assert_eq(r["duracion_min"], 240)


func test_ventana_04_06_aceptada_y_0401_rechazada():
	var ok = Actividades.Validar_Horario_Fiesta(0, 4, 0, 0, 6, 0)
	assert_true(ok["valido"])
	assert_eq(ok["duracion_min"], 120)
	var mal = Actividades.Validar_Horario_Fiesta(0, 4, 1, 0, 6, 0)
	assert_false(mal["valido"])
	assert_true(str(mal["motivo"]).contains("18:00"))


func test_ventana_fin_anterior_al_inicio_rechazado():
	var r = Actividades.Validar_Horario_Fiesta(0, 2, 0, 1, 1, 0)
	assert_false(r["valido"])
	assert_true(str(r["motivo"]).contains("posterior"))


func test_ventana_dia_final_incoherente_rechazado():
	var r = Actividades.Validar_Horario_Fiesta(0, 18, 0, 3, 2, 0)
	assert_false(r["valido"])
	assert_true(str(r["motivo"]).contains("posterior"))


func test_ventana_24_00_mismo_dia_aceptada():
	var r = Actividades.Validar_Horario_Fiesta(6, 18, 0, 6, 24, 0)
	assert_true(r["valido"])
	assert_eq(r["duracion_min"], 360)


func test_ventana_24_00_dia_posterior_rechazada():
	var r = Actividades.Validar_Horario_Fiesta(5, 18, 0, 6, 24, 0)
	assert_false(r["valido"])


func test_ventana_limites_de_matriz():
	var ok = Actividades.Validar_Horario_Fiesta(5, 22, 0, 6, 2, 0, 81)
	assert_true(ok["valido"], "Sábado de la semana 81 termina dentro de la matriz")
	assert_eq(ok["duracion_min"], 240)
	var mal = Actividades.Validar_Horario_Fiesta(6, 22, 0, 7, 2, 0, 81)
	assert_false(mal["valido"], "Domingo de la semana 81 se saldría de la matriz")
	assert_true(str(mal["motivo"]).contains("calendario"))
	var semana_invalida = Actividades.Validar_Horario_Fiesta(0, 18, 0, 1, 2, 0, 82)
	assert_false(semana_invalida["valido"])


# ---------------------------------------------------------------------------
# AC-08/AC-09/AC-17: fórmulas independientes
# ---------------------------------------------------------------------------

func test_mod_edad_fiesta():
	assert_almost_eq(Actividades.Calcular_Mod_Edad_Fiesta(20), 10.0, 0.0001)
	assert_almost_eq(Actividades.Calcular_Mod_Edad_Fiesta(36), 0.0, 0.0001)
	assert_almost_eq(Actividades.Calcular_Mod_Edad_Fiesta(60), -15.0, 0.0001)
	assert_almost_eq(Actividades.Calcular_Mod_Edad_Fiesta(76), -25.0, 0.0001)


func test_dia_de_la_noche_incluye_las_0600_como_dia_anterior():
	assert_eq(Actividades.Obtener_Dia_Semana_Noche(6, 2), 5)
	assert_eq(Actividades.Obtener_Dia_Semana_Noche(6, 6), 5, "Las 06:00 del domingo cuentan como sábado")
	assert_eq(Actividades.Obtener_Dia_Semana_Noche(0, 2), 6)
	assert_eq(Actividades.Obtener_Dia_Semana_Noche(5, 23), 5)


func test_multiplicador_dia_fiesta():
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(0), 0.70, 0.0001)
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(1), 0.70, 0.0001)
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(2), 0.70, 0.0001)
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(3), 1.00, 0.0001)
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(4), 1.25, 0.0001)
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(5), 1.45, 0.0001)
	assert_almost_eq(Actividades.Obtener_Mult_Dia_Fiesta(6), 0.80, 0.0001)


func test_puntaje_ligar_y_aguante_resacon_nb80():
	var puntaje = Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "", 36)
	assert_almost_eq(puntaje, 69.5, 0.001)
	var aguante = Actividades.Calcular_Aguante_Resacon(_NB(80), [50, 50, 50], 36)
	assert_almost_eq(aguante, 77.0, 0.001)


func test_probabilidades_por_minuto_nb80_jueves():
	var pl = Actividades.Calcular_Prob_Ligar_Min(69.5, 3)
	assert_almost_eq(pl, 0.00069805, 0.0000001)
	var pr = Actividades.Calcular_Prob_Resacon_Min(77.0)
	assert_almost_eq(pr, 0.0002377, 0.0000001)


func test_personalidad_solo_afecta_a_ligar():
	var base = Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "", 36)
	var dep = Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "Deportista", 36)
	var sofa = Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "Culo_Del_Sofa", 36)
	var trab = Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "Trabajador_Compulsivo", 36)
	assert_almost_eq(dep, base + 10.0, 0.001)
	assert_almost_eq(sofa, base - 10.0, 0.001)
	assert_almost_eq(trab, base - 5.0, 0.001)
	assert_almost_eq(Actividades.Calcular_Aguante_Resacon(_NB(80), [50, 50, 50], 36), 77.0, 0.001,
		"La personalidad no debe afectar al aguante")


func test_edad_20_vs_60():
	var pl20 = Actividades.Calcular_Prob_Ligar_Min(Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "", 20), 3)
	var pl60 = Actividades.Calcular_Prob_Ligar_Min(Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "", 60), 3)
	var pr20 = Actividades.Calcular_Prob_Resacon_Min(Actividades.Calcular_Aguante_Resacon(_NB(80), [50, 50, 50], 20))
	var pr60 = Actividades.Calcular_Prob_Resacon_Min(Actividades.Calcular_Aguante_Resacon(_NB(80), [50, 50, 50], 60))
	assert_gt(pl20, pl60)
	assert_lt(pr20, pr60)


func test_dia_sabado_mas_ligar_que_lunes_y_resacon_igual():
	var pl_sabado = Actividades.Calcular_Prob_Ligar_Min(50.0, 5)
	var pl_lunes = Actividades.Calcular_Prob_Ligar_Min(50.0, 0)
	assert_gt(pl_sabado, pl_lunes)
	assert_almost_eq(Actividades.Calcular_Prob_Resacon_Min(50.0), 0.000505, 0.000001)


func test_subir_mental_higiene_o_academico_sube_ligar_y_no_resacon():
	var nb_base = _NB(80)
	var prog_base = [50, 50, 50]
	var aguante_base = Actividades.Calcular_Aguante_Resacon(nb_base, prog_base, 36)
	var pr_base = Actividades.Calcular_Prob_Resacon_Min(aguante_base)
	var pl_base = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(nb_base, prog_base, "", 36), 3)

	var nb_mental = nb_base.duplicate(); nb_mental[1] = 100
	var pl_mental = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(nb_mental, prog_base, "", 36), 3)
	assert_gt(pl_mental, pl_base)
	assert_almost_eq(Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb_mental, prog_base, 36)), pr_base, 0.000001)

	var nb_higiene = nb_base.duplicate(); nb_higiene[4] = 100
	var pl_higiene = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(nb_higiene, prog_base, "", 36), 3)
	assert_gt(pl_higiene, pl_base)
	assert_almost_eq(Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb_higiene, prog_base, 36)), pr_base, 0.000001)

	var prog_academico = [50, 100, 50]
	var pl_academico = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(nb_base, prog_academico, "", 36), 3)
	assert_gt(pl_academico, pl_base)
	assert_almost_eq(Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb_base, prog_academico, 36)), pr_base, 0.000001)


func test_bajar_hambre_o_fisica_sube_resacon():
	var nb_base = _NB(80)
	var pr_base = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb_base, [50, 50, 50], 36))

	var nb_hambre = nb_base.duplicate(); nb_hambre[2] = 20
	var pr_hambre = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb_hambre, [50, 50, 50], 36))
	assert_gt(pr_hambre, pr_base)

	var nb_fisica = nb_base.duplicate(); nb_fisica[0] = 20
	var pr_fisica = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb_fisica, [50, 50, 50], 36))
	assert_gt(pr_fisica, pr_base)


func test_subir_deporte_sube_ligar_y_baja_resacon():
	var nb = _NB(80)
	var prog_bajo = [20, 50, 50]
	var prog_alto = [100, 50, 50]
	var pl_bajo = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(nb, prog_bajo, "", 36), 3)
	var pl_alto = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(nb, prog_alto, "", 36), 3)
	var pr_bajo = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb, prog_bajo, 36))
	var pr_alto = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(nb, prog_alto, 36))
	assert_gt(pl_alto, pl_bajo)
	assert_lt(pr_alto, pr_bajo)


func test_necesidades_80_vs_40():
	var pl80 = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(_NB(80), [50, 50, 50], "", 36), 3)
	var pl40 = Actividades.Calcular_Prob_Ligar_Min(
		Actividades.Calcular_Puntaje_Ligar(_NB(40), [50, 50, 50], "", 36), 3)
	var pr80 = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(_NB(80), [50, 50, 50], 36))
	var pr40 = Actividades.Calcular_Prob_Resacon_Min(
		Actividades.Calcular_Aguante_Resacon(_NB(40), [50, 50, 50], 36))
	assert_gt(pl80, pl40)
	assert_lt(pr80, pr40)


# ---------------------------------------------------------------------------
# AC-07/AC-08: vista previa
# ---------------------------------------------------------------------------

func test_preview_suma_uno_y_refleja_desgaste():
	var sim = _Simular(_NB(80), 360, 3, 36)
	assert_almost_eq(float(sim["p_ligar"]) + float(sim["p_resacon"]) + float(sim["p_nada"]), 1.0, 0.000001)
	assert_almost_eq(float(sim["pl_inicio"]), 0.000698, 0.000002)
	assert_almost_eq(float(sim["pl_fin"]), 0.000590, 0.000002)
	assert_almost_eq(float(sim["pr_inicio"]), 0.000239, 0.000002)
	assert_almost_eq(float(sim["pr_fin"]), 0.000785, 0.000002)
	assert_lt(float(sim["pl_fin"]), float(sim["pl_inicio"]))
	assert_gt(float(sim["pr_fin"]), float(sim["pr_inicio"]))


func test_preview_tabla_6h():
	var esperados := {
		100: [0.223, 0.108, 0.669],
		80: [0.197, 0.157, 0.646],
		60: [0.170, 0.198, 0.632],
		50: [0.157, 0.216, 0.628],
		40: [0.143, 0.232, 0.626],
		20: [0.117, 0.257, 0.626],
	}
	for valor in esperados:
		var sim = _Simular(_NB(valor), 360, 3, 36)
		var e: Array = esperados[valor]
		assert_almost_eq(float(sim["p_ligar"]), e[0], 0.001, "p_ligar NB=%d" % valor)
		assert_almost_eq(float(sim["p_resacon"]), e[1], 0.001, "p_resacon NB=%d" % valor)
		assert_almost_eq(float(sim["p_nada"]), e[2], 0.001, "p_nada NB=%d" % valor)


func test_preview_duracion_cero_no_falla():
	var sim = _Simular(_NB(80), 0, 3, 36)
	assert_eq(sim["duracion_min"], 0)
	assert_almost_eq(float(sim["p_ligar"]) + float(sim["p_resacon"]) + float(sim["p_nada"]), 1.0, 0.000001)


# ---------------------------------------------------------------------------
# AC-10: primer minuto y máximo un evento por bloque
# ---------------------------------------------------------------------------

func test_primer_minuto_del_bloque():
	Variables_Dinamicas.Matriz_Jugador[1200][10] = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	Variables_Dinamicas.Matriz_Jugador[1199][10] = ""
	assert_true(Actividades.Es_Primer_Minuto_Del_Bloque(10, 1200))
	Variables_Dinamicas.Matriz_Jugador[1199][10] = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	assert_false(Actividades.Es_Primer_Minuto_Del_Bloque(10, 1200), "Dos bloques adyacentes son uno solo")


func test_primer_minuto_cambio_de_dia():
	Variables_Dinamicas.Matriz_Jugador[1439][9] = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	Variables_Dinamicas.Matriz_Jugador[0][10] = ""
	assert_false(Actividades.Es_Primer_Minuto_Del_Bloque(10, 0))
	Variables_Dinamicas.Matriz_Jugador[1439][9] = ""
	assert_true(Actividades.Es_Primer_Minuto_Del_Bloque(10, 0))


func test_resolver_evento_respeta_flag():
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
	Actividades.Resolver_Evento_Fiesta()
	assert_true(Variables_Dinamicas.Fiesta_Evento_Ocurrido)
	assert_true(Variables_Dinamicas.Estados_Temporales.is_empty())


func test_actualizar_horario_no_repite_evento_si_flag():
	Variables_Dinamicas.Matriz_Jugador[1199][10] = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	Variables_Dinamicas.Matriz_Jugador[1200][10] = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
	Actividades.Actualizar_Horario(1)
	assert_true(Variables_Dinamicas.Fiesta_Evento_Ocurrido)
	assert_true(Variables_Dinamicas.Estados_Temporales.is_empty())


# ---------------------------------------------------------------------------
# AC-11/AC-12: activación de estados y mensajes
# ---------------------------------------------------------------------------

func test_activar_euforia_sustituye_resacon_y_notifica():
	Variables_Dinamicas.Necesidades_Basicas = [50, 40, 50, 50, 50]
	Variables_Dinamicas.Estados_Temporales = {"Resacon": 600}
	Actividades.Activar_Estado("Euforia")
	assert_eq(int(Variables_Dinamicas.Estados_Temporales["Euforia"]), 1440)
	assert_false(Variables_Dinamicas.Estados_Temporales.has("Resacon"))
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 100)
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)
	assert_true(str(Variables_Dinamicas.Mensajes[0].descripcion).contains("Euforia"))
	assert_false(Variables_Dinamicas.Mensajes[0].leido, "La notificación debe quedar sin leer")


func test_activar_euforia_en_calle_clampa_a_20():
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Variables_Dinamicas.En_La_Calle = true
	Actividades.Activar_Estado("Euforia")
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 20)


func test_activar_resacon_sustituye_euforia_y_notifica():
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Dinamicas.Estados_Temporales = {"Euforia": 600}
	Actividades.Activar_Estado("Resacon")
	assert_eq(int(Variables_Dinamicas.Estados_Temporales["Resacon"]), 1440)
	assert_false(Variables_Dinamicas.Estados_Temporales.has("Euforia"))
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[0], 30)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 30)
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)
	assert_true(str(Variables_Dinamicas.Mensajes[0].descripcion).contains("Resacón"))


func test_activar_resacon_en_calle_clampa_a_20():
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Dinamicas.En_La_Calle = true
	Actividades.Activar_Estado("Resacon")
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[0], 20)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 20)


# ---------------------------------------------------------------------------
# AC-13: curvas de cap y suelo
# ---------------------------------------------------------------------------

func test_curva_cap_resacon():
	assert_eq(Actividades.Calcular_Cap_Resacon_Puro(1440, false, 500), 30)
	assert_eq(Actividades.Calcular_Cap_Resacon_Puro(960, false, 500), 30)
	assert_eq(Actividades.Calcular_Cap_Resacon_Puro(720, false, 500), 47)
	assert_eq(Actividades.Calcular_Cap_Resacon_Puro(480, false, 500), 65)
	assert_eq(Actividades.Calcular_Cap_Resacon_Puro(240, false, 500), 82)
	assert_eq(Actividades.Calcular_Cap_Resacon_Puro(0, false, 500), 100)


func test_curva_suelo_euforia():
	assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(1440, false, 500), 100)
	assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(960, false, 500), 100)
	assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(720, false, 500), 87)
	assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(480, false, 500), 75)
	assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(240, false, 500), 62)
	assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(0, false, 500), 50)


func test_curvas_en_calle_o_bancarrota():
	for minutos in [1440, 720, 480, 0]:
		assert_eq(Actividades.Calcular_Cap_Resacon_Puro(minutos, true, 500), 20)
		assert_eq(Actividades.Calcular_Cap_Resacon_Puro(minutos, false, -1), 20)
		assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(minutos, true, 500), 20)
		assert_eq(Actividades.Calcular_Suelo_Euforia_Puro(minutos, false, -1), 20)


func test_wrappers_cap_y_suelo():
	Variables_Dinamicas.Estados_Temporales = {"Resacon": 480}
	assert_eq(Actividades.Obtener_Cap_Resacon(), 65)
	Variables_Dinamicas.En_La_Calle = true
	assert_eq(Actividades.Obtener_Cap_Resacon(), 20)
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Estados_Temporales = {"Euforia": 480}
	assert_eq(Actividades.Obtener_Suelo_Euforia(), 75)
	Variables_Dinamicas.Estados_Temporales = {}
	assert_eq(Actividades.Obtener_Cap_Resacon(), 100)
	assert_eq(Actividades.Obtener_Suelo_Euforia(), 1)


func test_cap_resacon_en_cambiar_necesidades_basicas():
	Variables_Dinamicas.Estados_Temporales = {"Resacon": 480}
	Variables_Dinamicas.Necesidades_Basicas = [90, 90, 80, 80, 80]
	Actividades_Necesidades_Basicas.Cambiar_Necesidades_Basicas(1, 0)
	Actividades_Necesidades_Basicas.Cambiar_Necesidades_Basicas(1, 1)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[0], 65)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 65)
	# Las demás necesidades no se recortan.
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[2], 80)


# ---------------------------------------------------------------------------
# Tick de estados
# ---------------------------------------------------------------------------

func test_tick_euforia_descuenta_y_termina_con_mensaje():
	Variables_Dinamicas.Necesidades_Basicas = [50, 40, 50, 50, 50]
	Variables_Dinamicas.Estados_Temporales = {"Euforia": 2}
	Actividades.Tick_Estados()
	assert_eq(int(Variables_Dinamicas.Estados_Temporales["Euforia"]), 1)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 50)
	Actividades.Tick_Estados()
	assert_false(Variables_Dinamicas.Estados_Temporales.has("Euforia"))
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)
	assert_true(str(Variables_Dinamicas.Mensajes[0].descripcion).to_lower().contains("euforia"))


func test_tick_resacon_recorta_y_termina_con_mensaje():
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 50, 50, 50]
	Variables_Dinamicas.Estados_Temporales = {"Resacon": 2}
	Actividades.Tick_Estados()
	assert_eq(int(Variables_Dinamicas.Estados_Temporales["Resacon"]), 1)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[0], 99)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 99)
	Actividades.Tick_Estados()
	assert_false(Variables_Dinamicas.Estados_Temporales.has("Resacon"))
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)
	assert_true(str(Variables_Dinamicas.Mensajes[0].descripcion).to_lower().contains("resacón"))


func test_tick_sin_estados_no_hace_nada():
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Actividades.Tick_Estados()
	assert_eq(Variables_Dinamicas.Mensajes.size(), 0)
	assert_true(Variables_Dinamicas.Estados_Temporales.is_empty())


# ---------------------------------------------------------------------------
# AC-14: persistencia
# ---------------------------------------------------------------------------

func test_game_data_incluye_estados_y_flag():
	Variables_Dinamicas.Estados_Temporales = {"Euforia": 1234}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
	var data = Guardar_Variables_Dinamicas.game_data_func()
	assert_true(data.has("Estados_Temporales"))
	assert_true(data.has("Fiesta_Evento_Ocurrido"))
	assert_eq(data["Estados_Temporales"]["Euforia"], 1234)
	assert_true(data["Fiesta_Evento_Ocurrido"])


func test_guardar_y_cargar_estados_y_flag():
	Guardar_Variables_Dinamicas.save_path = "user://test_salir_de_fiesta.dat"
	Variables_Dinamicas.Estados_Temporales = {"Resacon": 777}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Guardar_Variables_Dinamicas.save_game()

	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = false
	Guardar_Variables_Dinamicas.load_game()
	assert_eq(int(Variables_Dinamicas.Estados_Temporales["Resacon"]), 777)
	assert_true(Variables_Dinamicas.Fiesta_Evento_Ocurrido)


func test_save_antiguo_sin_campos_carga_vacio_y_false():
	Guardar_Variables_Dinamicas.save_path = "user://test_salir_de_fiesta.dat"
	var data = Guardar_Variables_Dinamicas.game_data_func()
	data.erase("Estados_Temporales")
	data.erase("Fiesta_Evento_Ocurrido")
	var archivo = FileAccess.open(Guardar_Variables_Dinamicas.save_path, FileAccess.WRITE)
	archivo.store_var(data)
	archivo = null

	Variables_Dinamicas.Estados_Temporales = {"Euforia": 500}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
	Guardar_Variables_Dinamicas.load_game()
	assert_true(Variables_Dinamicas.Estados_Temporales.is_empty())
	assert_false(Variables_Dinamicas.Fiesta_Evento_Ocurrido)


func test_carga_filtra_claves_desconocidas_y_ambos_estados():
	Guardar_Variables_Dinamicas.save_path = "user://test_salir_de_fiesta.dat"
	var data = Guardar_Variables_Dinamicas.game_data_func()
	data["Estados_Temporales"] = {"Euforia": 100, "Resacon": 200, "Lesion": 50}
	data["Fiesta_Evento_Ocurrido"] = false
	var archivo = FileAccess.open(Guardar_Variables_Dinamicas.save_path, FileAccess.WRITE)
	archivo.store_var(data)
	archivo = null

	Guardar_Variables_Dinamicas.load_game()
	assert_false(Variables_Dinamicas.Estados_Temporales.has("Lesion"))
	assert_false(Variables_Dinamicas.Estados_Temporales.has("Euforia"))
	assert_eq(int(Variables_Dinamicas.Estados_Temporales["Resacon"]), 200)


# ---------------------------------------------------------------------------
# AC-15: label de estado
# ---------------------------------------------------------------------------

func test_construir_texto_estado():
	var gui = load("res://Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd").new()
	assert_eq(gui.Construir_Texto_Estado({"Euforia": 1439}, 100), "Euforia · 23h 59m")
	assert_eq(gui.Construir_Texto_Estado({"Resacon": 1100}, 45), "Resacón · 18h 20m · límite 45")
	assert_eq(gui.Construir_Texto_Estado({}, 100), "")
	gui.free()


func test_label_estado_se_muestra_y_oculta():
	var gui = load("res://Scripts/GUI/Escena_Principal/Necesidades_Basicas/Necesidades_Basicas_GUI.gd").new()
	var raiz = Node.new()
	var label = Label.new()
	label.name = "Estado_Temporal_Label"
	raiz.add_child(label)
	add_child_autofree(raiz)

	Variables_Dinamicas.Estados_Temporales = {}
	gui.Actualizar_Estado_Temporal(raiz)
	assert_false(label.visible)

	Variables_Dinamicas.Estados_Temporales = {"Euforia": 1439}
	gui.Actualizar_Estado_Temporal(raiz)
	assert_true(label.visible)
	assert_eq(label.text, "Euforia · 23h 59m")

	Variables_Dinamicas.Estados_Temporales = {"Resacon": 1100}
	gui.Actualizar_Estado_Temporal(raiz)
	assert_true(label.visible)
	assert_true(label.text.contains("límite"))
	gui.free()


# ---------------------------------------------------------------------------
# AC-07: vista previa en la UI
# ---------------------------------------------------------------------------

func test_preview_ui_valida_muestra_probabilidades():
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	raiz.mirar_semana = 10
	var sel = load("res://Scripts/GUI/Escena_Principal/Actividades/Reloj/Auxiliar/SeleccionarHorarioReloj.gd").new()
	sel.inicializar(raiz)
	sel.dia_inicio_texto.text = "L"
	sel.hora_inicio_texto.text = "22"
	sel.minuto_inicio_texto.text = "0"
	sel.dia_final_texto.text = "M"
	sel.hora_final_texto.text = "2"
	sel.minuto_final_texto.text = "0"
	sel.Actualizar_Preview_Fiesta(raiz)

	var panel = raiz.get_node_or_null("Actividades/Seleccionar_Horario/Preview_Fiesta")
	assert_not_null(panel, "El panel de preview debe crearse en el selector")
	assert_eq(panel.position, Vector2(16, 174))
	assert_eq(panel.size, Vector2(688, 584))
	assert_lte(panel.position.y + panel.size.y, 772.0, "La preview no debe invadir los relojes")
	var lbl_dur = panel.find_child("Preview_Duracion", true, false)
	var lbl_ligar = panel.find_child("Preview_Ligar_Min", true, false)
	var lbl_acum = panel.find_child("Preview_Acumuladas", true, false)
	assert_eq(lbl_dur.text, "Duración: 4h 00m")
	assert_true(lbl_ligar.visible)
	assert_true(str(lbl_ligar.text).contains("ligar"))
	assert_true(str(lbl_acum.text).contains("Ligar:"))
	sel.free()
	raiz.free()


func test_preview_ui_invalida_muestra_motivo_y_oculta_probabilidades():
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	raiz.mirar_semana = 10
	var sel = load("res://Scripts/GUI/Escena_Principal/Actividades/Reloj/Auxiliar/SeleccionarHorarioReloj.gd").new()
	sel.inicializar(raiz)
	sel.dia_inicio_texto.text = "L"
	sel.hora_inicio_texto.text = "17"
	sel.minuto_inicio_texto.text = "59"
	sel.dia_final_texto.text = "M"
	sel.hora_final_texto.text = "6"
	sel.minuto_final_texto.text = "0"
	sel.Actualizar_Preview_Fiesta(raiz)

	var panel = raiz.get_node_or_null("Actividades/Seleccionar_Horario/Preview_Fiesta")
	assert_not_null(panel)
	var lbl_motivo = panel.find_child("Preview_Motivo", true, false)
	var lbl_ligar = panel.find_child("Preview_Ligar_Min", true, false)
	assert_true(lbl_motivo.visible)
	assert_true(str(lbl_motivo.text).contains("18:00"))
	assert_false(lbl_ligar.visible)
	sel.free()
	raiz.free()


# ---------------------------------------------------------------------------
# AC-16: no regresión de jerarquía
# ---------------------------------------------------------------------------

func test_fiesta_no_pisa_trabajo_ni_examen():
	var fiesta = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	var trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	Variables_Dinamicas.Matriz_Jugador[1200][10] = trabajo
	assert_false(Actividades.Crear_Actividad(10, 1200, fiesta))
	assert_eq(Variables_Dinamicas.Matriz_Jugador[1200][10], trabajo)

	var examen = Actividad_Examen.new()
	Variables_Dinamicas.Matriz_Jugador[1201][10] = examen
	assert_false(Actividades.Crear_Actividad(10, 1201, fiesta))
	assert_eq(Variables_Dinamicas.Matriz_Jugador[1201][10], examen)


func test_fiesta_pisa_temporal():
	var fiesta = Variables_Estaticas.Catalogo_Actividades[NOMBRE]
	var dormir = Variables_Estaticas.Catalogo_Actividades["Dormir"]
	Variables_Dinamicas.Matriz_Jugador[1202][10] = dormir
	assert_true(Actividades.Crear_Actividad(10, 1202, fiesta))
	assert_eq(Variables_Dinamicas.Matriz_Jugador[1202][10], fiesta)
