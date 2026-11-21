extends GutTest

# Tests de personalización del personaje estilo Los Sims, compatibilidad con saves
# antiguos, renderizado modular en Personaje_Visual y conexión con Escenario_Actividad.


func after_each() -> void:
	Debug_Pose_Inicio.POSE_FORZADA = "0"
	Debug_Pose_Inicio.FORZAR_CALLE = -1


func test_apariencia_por_defecto_tiene_campos_sims_completos() -> void:
	var ap := Apariencia_Personaje.por_defecto()
	for clave in [
		"nombre", "genero", "personalidad", "complexion", "color_piel",
		"forma_cara", "forma_ojos", "color_ojos", "estilo_cejas",
		"forma_nariz", "forma_boca", "color_labios", "color_pelo",
		"estilo_pelo", "vello_facial", "pecas", "lunar", "rubor", "delineado",
		"ropa_superior", "color_ropa", "ropa_inferior", "color_pantalon",
		"calzado", "color_calzado", "gafas", "sombrero", "pendientes",
	]:
		assert_true(ap.has(clave), "Debe existir la clave '%s' en por_defecto()" % clave)


func test_normalizar_migra_saves_antiguos_y_valida_campos() -> void:
	var antiguo := {
		"nombre": "  Lucas  ",
		"genero": "hombre",
		"color_piel": "#c68255",
		"color_ojos": "#228b4e",
		"color_pelo": "#1e1b18",
		"estilo_pelo": "corto",
		"color_ropa": "#dc2626",
		"gafas": "redondas",
		"vello_facial": "barba_corta",
		"pecas": true,
	}
	var norm := Apariencia_Personaje.normalizar(antiguo)
	assert_eq(norm["nombre"], "Lucas")
	assert_eq(norm["ropa_superior"], "sudadera")
	assert_eq(norm["ropa_inferior"], "vaqueros")
	assert_eq(norm["complexion"], "normal")
	assert_eq(norm["forma_cara"], "ovalada")
	assert_eq(norm["vello_facial"], "barba_corta")

	# Si cambia a mujer, limpia el vello facial
	var mujer_inv := {"genero": "mujer", "vello_facial": "barba_completa", "estilo_pelo": "invalido"}
	var norm_m := Apariencia_Personaje.normalizar(mujer_inv)
	assert_eq(norm_m["vello_facial"], "ninguno")
	assert_eq(norm_m["estilo_pelo"], "largo")


func test_aplicar_arquetipo_cambia_look_segun_genero() -> void:
	var base := Apariencia_Personaje.normalizar({"genero": "mujer", "nombre": "Sofía"})
	var ejec := Apariencia_Personaje.aplicar_arquetipo(base, "ejecutivo")
	assert_eq(ejec["nombre"], "Sofía")
	assert_eq(ejec["ropa_superior"], "camisa")
	assert_eq(ejec["ropa_inferior"], "falda")
	assert_eq(ejec["pendientes"], "perlas")


func test_personaje_visual_y_escenario_actividad_soportan_todas_las_poses() -> void:
	var escenario := Escenario_Actividad.new()
	escenario.size = Vector2(640, 184)
	add_child_autofree(escenario)
	await wait_process_frames(2)

	var ap := Apariencia_Personaje.aleatoria("mujer")
	for act in ["", "Salir_A_Correr", "Dormir", "Comer", "Cocinar", "Duchar", "Estudiar", "Ver_La_Television", "Practicar_Manualidades", "Salir_De_Fiesta", "Partido_Futbol", "Trabajar_En_Comida_Rapida"]:
		escenario.actualizar_estado(act, false, ap, 780, "Mesa_Premium", "Deportista")
		await wait_process_frames(1)
		assert_eq(escenario._personaje.apariencia["estilo_pelo"], ap["estilo_pelo"])
		assert_eq(escenario._personaje.pose, Apariencia_Personaje.pose_para_actividad(act))


func test_debug_pose_inicio_fuerza_las_poses_del_escenario() -> void:
	assert_eq(Debug_Pose_Inicio.actividad_forzada(), "", "Con «0» no debe forzar nada")

	var escenario := Escenario_Actividad.new()
	escenario.size = Vector2(640, 184)
	add_child_autofree(escenario)
	await wait_process_frames(2)

	var ap := Apariencia_Personaje.por_defecto()
	for clave in Debug_Pose_Inicio.ACTIVIDAD_POR_POSE.keys():
		Debug_Pose_Inicio.POSE_FORZADA = clave
		escenario.actualizar_estado("Dormir", false, ap)
		await wait_process_frames(1)
		assert_eq(escenario._pose_actual, clave, "«%s» debe forzar su pose" % clave)

	var sin_atajo: Array = []
	for pose in Escenario_Actividad.VARIACIONES.keys():
		if not Debug_Pose_Inicio.ACTIVIDAD_POR_POSE.has(pose):
			sin_atajo.append(pose)
	assert_eq(sin_atajo, [], "Toda pose con variaciones debe tener atajo en Debug_Pose_Inicio")

	Debug_Pose_Inicio.POSE_FORZADA = "0"
	escenario.actualizar_estado("Dormir", false, ap)
	assert_eq(escenario._pose_actual, "dormir", "Con «0» vuelve a la actividad real")

	Debug_Pose_Inicio.POSE_FORZADA = "idle"
	Debug_Pose_Inicio.FORZAR_CALLE = 1
	escenario.actualizar_estado("Dormir", false, ap)
	assert_true(escenario._en_la_calle, "FORZAR_CALLE=1 debe mostrar la variante de calle")

	Debug_Pose_Inicio.FORZAR_CALLE = -1
	Debug_Pose_Inicio.POSE_FORZADA = "0"


func test_creador_personaje_se_construye_y_emite_apariencia() -> void:
	var script_creador: GDScript = load("res://Scripts/GUI/Menu/Creador_Personaje.gd")
	var creador: CanvasLayer = script_creador.new()
	add_child_autofree(creador)
	await wait_process_frames(2)

	var recibida: Array = []
	creador.confirmado.connect(func(ap: Dictionary, _pos: Vector2):
		recibida.append(ap))

	creador._apariencia["personalidad"] = "Deportista"
	creador._apariencia["ropa_superior"] = "chaqueta"
	creador._confirmar(Vector2.ZERO)
	assert_eq(recibida.size(), 1)
	assert_eq(recibida[0]["personalidad"], "Deportista")
	assert_eq(recibida[0]["ropa_superior"], "chaqueta")
