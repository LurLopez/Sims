extends GutTest

# Tests de la simulación 3D del runner "Salir a correr" (PARK RUSH 3D):
# carriles, salto/súpersalto, rodar/caída rápida, subida por rampa a techos,
# esquiva de vallas/arcos, imán 3D, tabla protectora, tropiezos laterales sin
# policía, generador justo de oleadas, sincronización 3D del Sim y escena.

const EscenaCorrer := preload("res://Escenas/Minijuego_Correr/Minijuego_Correr.tscn")


func test_cambio_de_carril_respeta_limites() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	assert_eq(int(sim.jugador["carril_objetivo"]), 0)
	assert_eq(sim.aplicar_comando("IZQUIERDA"), "CARRIL")
	assert_eq(int(sim.jugador["carril_objetivo"]), -1)
	assert_eq(sim.aplicar_comando("IZQUIERDA"), "")
	assert_eq(int(sim.jugador["carril_objetivo"]), -1)
	assert_eq(sim.aplicar_comando("DERECHA"), "CARRIL")
	assert_eq(sim.aplicar_comando("DERECHA"), "CARRIL")
	assert_eq(int(sim.jugador["carril_objetivo"]), 1)
	assert_eq(sim.aplicar_comando("DERECHA"), "")


func test_salto_super_salto_y_caida_rapida_rodar() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	assert_eq(sim.aplicar_comando("SALTAR"), "SALTAR")
	assert_almost_eq(float(sim.jugador["vy"]), Runner_Simulacion.VELOCIDAD_SALTO, 0.01)
	sim.avanzar(0.12, false)
	assert_gt(float(sim.jugador["y"]), 0.5)

	# Rodar en el aire fuerza caída rápida
	assert_eq(sim.aplicar_comando("RODAR"), "CAIDA_RODAR")
	assert_lte(float(sim.jugador["vy"]), Runner_Simulacion.VELOCIDAD_CAIDA_RAPIDA)

	# Súper Zapatillas aumentan la velocidad de salto
	sim.reiniciar(false)
	sim.powerups["zapatillas"] = 5.0
	assert_eq(sim.aplicar_comando("SALTAR"), "SALTAR")
	assert_almost_eq(float(sim.jugador["vy"]), Runner_Simulacion.VELOCIDAD_SUPER_SALTO, 0.01)


func test_valla_baja_se_esquiva_saltando() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("VALLA_BAJA", 0, 0.0)
	assert_false(sim.buscar_obstaculo_colision().is_empty())
	sim.jugador["y"] = Runner_Simulacion.ALTURA_VALLA + 0.1
	assert_true(sim.buscar_obstaculo_colision().is_empty())


func test_arco_alto_se_esquiva_rodando_o_supersaltando() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("ARCO_ALTO", 0, 0.0)
	assert_false(sim.buscar_obstaculo_colision().is_empty())

	sim.jugador["estado"] = "RODANDO"
	assert_true(sim.buscar_obstaculo_colision().is_empty())

	sim.jugador["estado"] = "SALTANDO"
	sim.jugador["y"] = Runner_Simulacion.TECHO_ARCO_ALTO
	assert_true(sim.buscar_obstaculo_colision().is_empty())


func test_subida_por_rampa_y_carrera_sobre_techo() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	# Pasarela elevada con rampa delante del jugador
	sim.anadir_obstaculo("PASARELA_RAMPA", 0, -18.0, 1)
	var subio_al_techo: bool = false
	for _i in range(70):
		var ev: Dictionary = sim.avanzar(0.025, false)
		assert_false(bool(ev["choco"]), "El corredor debe subir la rampa sin chocar")
		if bool(sim.jugador["en_techo"]) and float(sim.jugador["y"]) >= Runner_Simulacion.ALTURA_PLATAFORMA - 0.1:
			subio_al_techo = true
	assert_true(subio_al_techo, "El corredor alcanzó la pasarela elevada por la rampa")


func test_tabla_protege_de_choque_y_despeja_obstaculos() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	assert_eq(sim.tablas_restantes, Runner_Simulacion.TABLAS_INICIALES)
	assert_eq(sim.aplicar_comando("TABLA"), "TABLA")
	assert_eq(sim.tablas_restantes, Runner_Simulacion.TABLAS_INICIALES - 1)
	assert_gt(float(sim.powerups["tabla"]), 0.0)

	sim.anadir_obstaculo("SETO_ALTO", 0, -0.5, 0)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_true(bool(ev["tabla_salvo"]))
	assert_false(bool(ev["choco"]))
	assert_true(sim.esta_vivo())
	assert_almost_eq(float(sim.powerups["tabla"]), 0.0, 0.01)
	assert_gt(float(sim.jugador["invulnerable"]), 0.5)


func test_tropiezo_lateral_y_segundo_tropiezo_sin_policia() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("SETO_ALTO", 1, 0.0, 0)
	assert_eq(sim.aplicar_comando("DERECHA"), "TROPIEZO")
	assert_true(sim.esta_vivo())
	assert_gt(float(sim.jugador["tiempo_tropiezo"]), 0.0)

	# Segundo tropiezo dentro de la ventana de equilibrio provoca caída
	assert_eq(sim.aplicar_comando("DERECHA"), "TROPIEZO_CAIDA")
	assert_false(sim.esta_vivo())


func test_choque_frontal_tropieza_y_segundo_choque_cae() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	var primer_choque: Dictionary = sim.anadir_obstaculo("SETO_ALTO", 0, -0.5, 0)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_true(bool(ev["tropiezo"]))
	assert_false(bool(ev["caido"]))
	assert_true(sim.esta_vivo())
	assert_true(bool(primer_choque["golpeado"]))

	# El segundo obstáculo llega cuando aún está aturdido: cae y queda reanimable.
	sim.anadir_obstaculo("VALLA_BAJA", 0, -12.0)
	ev = sim.avanzar(0.82, false)
	assert_true(bool(ev["caido"]), "El segundo choque durante el tropiezo debe derribar")
	assert_false(sim.esta_vivo())
	assert_true(sim.esta_reanimable())


func test_choque_frontal_con_tren_largo_termina_la_partida() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("TREN_LARGO", 0, -0.5, 0)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_true(bool(ev["caido"]), "Un tren de lleno debe tumbar al Sim al instante")
	assert_true(bool(ev["choco"]))
	assert_false(bool(ev["tropiezo"]), "Un tren no debe dejar al Sim perdiendo el equilibrio")
	assert_false(sim.esta_vivo())
	assert_true(sim.esta_reanimable())
	assert_eq(str(sim.jugador["tipo_caida"]), "TREN_LARGO")


func test_choque_frontal_con_tren_movil_termina_la_partida() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("TREN_MOVIL", 0, -0.5, 1, 6.0)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_true(bool(ev["caido"]))
	assert_false(bool(ev["tropiezo"]))
	assert_false(sim.esta_vivo())
	assert_eq(str(sim.jugador["tipo_caida"]), "TREN_MOVIL")


func test_choque_lateral_con_tren_termina_la_partida() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("TREN_LARGO", 1, 0.0, 0)
	assert_eq(sim.aplicar_comando("DERECHA"), "TROPIEZO_CAIDA")
	assert_false(sim.esta_vivo())
	assert_true(sim.esta_reanimable())


func test_tabla_salva_de_un_tren_y_se_consume() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	assert_eq(sim.aplicar_comando("TABLA"), "TABLA")
	sim.anadir_obstaculo("TREN_LARGO", 0, -0.5, 0)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_true(bool(ev["tabla_salvo"]))
	assert_false(bool(ev["caido"]))
	assert_true(sim.esta_vivo())
	assert_almost_eq(float(sim.powerups["tabla"]), 0.0, 0.01)


func test_tabla_absorbe_choque_lateral_y_permite_el_cambio() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	assert_eq(sim.aplicar_comando("TABLA"), "TABLA")
	sim.anadir_obstaculo("TREN_LARGO", 1, 0.0, 0)
	assert_eq(sim.aplicar_comando("DERECHA"), "CARRIL")
	assert_eq(int(sim.jugador["carril_objetivo"]), 1)
	assert_true(sim.esta_vivo())
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_true(bool(ev["tabla_salvo"]))
	assert_almost_eq(float(sim.powerups["tabla"]), 0.0, 0.01)


func test_tren_movil_avanza_con_velocidad_relativa() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	var tren: Dictionary = sim.anadir_obstaculo("TREN_MOVIL", 0, -60.0, 1, 8.0)
	var z_inicial: float = float(tren["z"])
	sim.avanzar(0.1, false)
	assert_gt(float(tren["z"]), z_inicial + 2.0, "El tren debe acercarse más rápido que el escenario")


func test_jetpack_vuela_y_termina_en_aterrizaje_seguro() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_powerup("JETPACK", 0, 1.0, 0.5)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_eq(str(ev["powerup_recogido"]), "JETPACK")
	assert_eq(str(sim.jugador["estado"]), "VOLANDO")

	for _i in range(20):
		sim.avanzar(0.1, false)
	assert_gt(float(sim.jugador["y"]), 3.0)
	assert_eq(str(sim.jugador["estado"]), "VOLANDO")

	var termino: bool = false
	for _i in range(120):
		ev = sim.avanzar(0.1, false)
		if bool(ev["jetpack_fin"]):
			termino = true
			break
	assert_true(termino, "El jetpack debe terminar con aterrizaje seguro")
	assert_ne(str(sim.jugador["estado"]), "VOLANDO")
	assert_true(sim.esta_vivo())


func test_pogo_hace_arco_y_aterriza() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_powerup("POGO", 0, 1.0, 0.5)
	sim.avanzar(0.02, false)
	assert_eq(str(sim.jugador["estado"]), "POGO")
	var altura_max: float = 0.0
	var termino: bool = false
	for _i in range(80):
		var ev: Dictionary = sim.avanzar(0.1, false)
		altura_max = maxf(altura_max, float(sim.jugador["y"]))
		if bool(ev["pogo_fin"]):
			termino = true
			break
	assert_gt(altura_max, 4.0, "El pogo debe elevar al Sim en un arco alto")
	assert_true(termino)
	assert_true(sim.esta_vivo())


func test_tunel_no_colisiona_y_activa_camara_rasante() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("TUNEL", 0, 0.0)
	sim.avanzar(0.016, false)
	assert_true(bool(sim.jugador["tunel"]))
	assert_true(sim.buscar_obstaculo_colision().is_empty())
	assert_true(sim.esta_vivo())
	# Al alejarse, el túnel deja de afectar a la cámara.
	for _i in range(12):
		sim.avanzar(0.1, false)
	assert_false(bool(sim.jugador["tunel"]))


func test_llave_y_reanimacion() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_powerup("LLAVE", 0, 1.0, 0.5)
	var ev: Dictionary = sim.avanzar(0.02, false)
	assert_eq(int(ev["llave"]), 1)
	assert_eq(sim.llaves, 1)

	sim.jugador["estado"] = "CAIDO"
	assert_true(sim.esta_reanimable())
	assert_true(sim.revivir())
	assert_eq(str(sim.jugador["estado"]), "CORRIENDO")
	assert_gt(float(sim.jugador["invulnerable"]), 1.0)
	assert_true(sim.esta_vivo())


func test_puntuacion_crece_con_distancia_y_multiplicador() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.avanzar(1.0, false)
	assert_almost_eq(sim.puntuacion, Runner_Simulacion.VELOCIDAD_INICIAL * Runner_Simulacion.PUNTOS_POR_METRO, 5.0)

	sim.reiniciar(false)
	sim.powerups["multiplicador"] = 10.0
	sim.avanzar(1.0, false)
	assert_almost_eq(sim.puntuacion, Runner_Simulacion.VELOCIDAD_INICIAL * Runner_Simulacion.PUNTOS_POR_METRO * 2.0, 5.0)


func test_hay_tres_retos_distintos_por_carrera() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	assert_eq(sim.misiones.size(), 3)
	var ids: Dictionary = {}
	for m in sim.misiones:
		ids[str(m["id"])] = true
	assert_eq(ids.size(), 3, "Los retos de una carrera no deben repetirse")


func test_generador_puede_crear_trenes_en_movimiento() -> void:
	var sim := Runner_Simulacion.new()
	sim.configurar_semilla(4242)
	sim.reiniciar(false)
	sim.distancia = 700.0
	var trenes: int = 0
	for _i in range(80):
		sim.generar_oleada(-100.0)
		for obs in sim.obstaculos:
			if str(obs["tipo"]) == "TREN_MOVIL":
				trenes += 1
		sim.obstaculos.clear()
	assert_gt(trenes, 0, "Las oleadas deben incluir trenes en movimiento")


func test_generador_no_amontona_trenes_moviles() -> void:
	var sim := Runner_Simulacion.new()
	sim.configurar_semilla(2026)
	sim.reiniciar(false)
	sim.distancia = 800.0
	var max_activos: int = 0
	for _i in range(120):
		sim.generar_oleada(-100.0)
		var activos: int = 0
		for obs in sim.obstaculos:
			if str(obs["tipo"]) == "TREN_MOVIL":
				activos += 1
		max_activos = maxi(max_activos, activos)
		var quedan: Array[Dictionary] = []
		for obs in sim.obstaculos:
			if str(obs["tipo"]) == "TREN_MOVIL":
				quedan.append(obs)
		sim.obstaculos = quedan
	assert_lte(max_activos, Runner_Simulacion.MAX_TRENES_MOVILES_ACTIVOS,
		"No debe haber más de un tren móvil activo a la vez")


func test_oleada_espera_si_los_tres_carriles_estan_ocupados() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	for carril in [-1, 0, 1]:
		sim.anadir_obstaculo("TREN_LARGO", carril, -120.0)
	var antes: int = sim.obstaculos.size()
	assert_false(sim.generar_oleada(-115.0), "La oleada debe esperar a que se libere un carril")
	assert_eq(sim.obstaculos.size(), antes, "No debe añadir obstáculos sin salida")


func test_oleada_con_dos_carriles_ocupados_usa_el_libre() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.anadir_obstaculo("TREN_LARGO", -1, -120.0)
	sim.anadir_obstaculo("TREN_LARGO", 0, -120.0)
	var id_antes: int = sim._siguiente_id
	assert_true(sim.generar_oleada(-115.0))
	for obs in sim.obstaculos:
		if int(obs["id"]) < id_antes:
			continue
		if int(obs["carril"]) != 1:
			continue
		# En el único carril libre solo puede haber algo saltable, rodable o con rampa.
		if not bool(obs["tiene_rampa"]):
			assert_true(str(obs["tipo"]) == "VALLA_BAJA" or str(obs["tipo"]) == "ARCO_ALTO",
				"El carril libre no puede llevar un muro alto sin rampa")


func test_brecha_entre_oleadas_cubre_un_tren_largo() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim._largo_ultima_oleada = Runner_Simulacion.LARGO_TREN_LARGO
	assert_gte(sim._calcular_brecha_oleada(), Runner_Simulacion.LARGO_TREN_LARGO + Runner_Simulacion.MARGEN_ENTRE_OLEADAS)


func test_simulacion_larga_no_cierra_los_tres_carriles() -> void:
	for semilla in [7, 21, 99]:
		var sim := Runner_Simulacion.new()
		sim.configurar_semilla(semilla)
		sim.reiniciar(false)
		var t: float = 0.0
		while t < 180.0:
			sim.jugador["invulnerable"] = 999.0
			sim.avanzar(0.05, true)
			t += 0.05

			var moviles: int = 0
			for obs in sim.obstaculos:
				if str(obs["tipo"]) == "TREN_MOVIL":
					moviles += 1
			assert_lte(moviles, Runner_Simulacion.MAX_TRENES_MOVILES_ACTIVOS,
				"Semilla %d a %.0f m: demasiados trenes móviles activos" % [semilla, sim.distancia])

			var bloqueados: int = 0
			var hay_rampa: bool = false
			for carril in [-1, 0, 1]:
				for obs in sim.obstaculos:
					if bool(obs.get("golpeado", false)) or int(obs["carril"]) != carril:
						continue
					var tipo: String = str(obs["tipo"])
					if tipo != "SETO_ALTO" and tipo != "PASARELA_RAMPA" and tipo != "TREN_LARGO" and tipo != "TREN_LARGO_RAMPA" and tipo != "TREN_MOVIL":
						continue
					var medio: float = float(obs["largo"]) * 0.5
					if float(obs["z"]) + medio > -0.6 and float(obs["z"]) - medio < 0.6:
						bloqueados += 1
						if bool(obs["tiene_rampa"]):
							hay_rampa = true
						break
			if bloqueados >= 3:
				assert_true(hay_rampa,
					"Semilla %d a %.0f m: muro de tres carriles sin rampa" % [semilla, sim.distancia])


func test_tren_largo_ocupa_tres_vagones_y_se_puede_coronar() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	var tren: Dictionary = sim.anadir_obstaculo("TREN_LARGO", 0, -20.0, 0)
	assert_almost_eq(float(tren["largo"]), Runner_Simulacion.LARGO_TREN_LARGO, 0.01)
	tren["z"] = 0.0
	assert_false(sim.buscar_obstaculo_colision().is_empty())
	sim.jugador["y"] = Runner_Simulacion.ALTURA_PLATAFORMA + 0.1
	assert_true(sim.buscar_obstaculo_colision().is_empty(), "Desde el techo no debe colisionar con el tren")


func test_iman_atrae_monedas_desde_otro_carril() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.powerups["iman"] = 8.0
	sim.anadir_moneda(1, 1.0, -8.0)
	for _i in range(40):
		sim.avanzar(0.025, false)
	assert_eq(sim.monedas, 1)


func test_oleadas_siempre_dejan_un_carril_pasable() -> void:
	var sim := Runner_Simulacion.new()
	sim.configurar_semilla(12345)
	for w in range(30):
		sim.reiniciar(false)
		sim.distancia = float(w) * 40.0
		sim.generar_oleada(-100.0)
		var bloqueados_totales: int = 0
		for carril in [-1, 0, 1]:
			var bloqueado: bool = false
			for obs in sim.obstaculos:
				if int(obs["carril"]) == carril and (str(obs["tipo"]) == "SETO_ALTO" or str(obs["tipo"]) == "CICLISTA"):
					bloqueado = true
			if bloqueado:
				bloqueados_totales += 1
		assert_lt(bloqueados_totales, 3, "Cada oleada debe dejar al menos 1 carril libre, saltable, rodable o con rampa")


func test_personaje_3d_refleja_cambios_de_apariencia_del_sim() -> void:
	var pj := Runner_Personaje_3D.new()
	add_child_autofree(pj)

	var ap_a := Apariencia_Personaje.normalizar({
		"genero": "hombre",
		"estilo_pelo": "calvo",
		"sombrero": "ninguno",
		"color_ropa": "#2563eb",
	})
	pj.aplicar_apariencia(ap_a, 22)
	assert_eq(str(pj.apariencia_actual["estilo_pelo"]), "calvo")
	var hijos_a: int = pj.get_child_count()

	var ap_b := Apariencia_Personaje.normalizar({
		"genero": "mujer",
		"estilo_pelo": "coleta",
		"sombrero": "gorra",
		"gafas": "sol",
		"estilo_ropa": "vestido",
		"color_ropa": "#e11d48",
	})
	pj.aplicar_apariencia(ap_b, 28)
	assert_eq(str(pj.apariencia_actual["estilo_pelo"]), "coleta")
	assert_eq(str(pj.apariencia_actual["color_ropa"]), "#e11d48")
	assert_gt(hijos_a, 0)
	assert_gt(pj.get_child_count(), 0)


func test_personaje_3d_soporta_todos_los_peinados_atuendos_edades_y_poses() -> void:
	var pj := Runner_Personaje_3D.new()
	add_child_autofree(pj)

	for peinado: String in ["alborotado", "tupe", "corto", "degradado", "raya_lado", "rizado", "afro", "rapado", "calvo", "largo", "ondulado", "media_melena", "bob", "coleta", "dos_coletas", "mono"]:
		var ap := Apariencia_Personaje.normalizar({
			"genero": "mujer" if peinado in ["largo", "coleta", "dos_coletas", "bob"] else "hombre",
			"estilo_pelo": peinado,
			"forma_cara": "corazon",
			"forma_ojos": "grandes",
			"forma_nariz": "respingona",
			"forma_boca": "amplia",
			"gafas": "aviador",
			"pendientes": "aros",
			"vello_facial": "barba_completa",
		})
		pj.aplicar_apariencia(ap, 68)
		assert_eq(str(pj.apariencia_actual["estilo_pelo"]), peinado)
		assert_eq(pj.edad_actual, 68)

	for atuendo: Dictionary in Ropa_Catalogo.DATOS:
		var ap_ropa: Dictionary = Apariencia_Personaje.normalizar({
			"estilo_ropa": str(atuendo.get("estilo_visual", "base")),
			"detalle_ropa": str(atuendo.get("detalle_visual", "")),
			"ropa_superior": str(atuendo.get("prenda_superior", "sudadera")),
			"ropa_inferior": str(atuendo.get("prenda_inferior", "vaqueros")),
			"calzado": str(atuendo.get("calzado", "zapatillas")),
			"color_ropa": str(atuendo.get("color_principal", "#2563eb")),
			"color_ropa_secundario": str(atuendo.get("color_secundario", "#f8fafc")),
			"color_ropa_detalle": str(atuendo.get("color_detalle", "#f8fafc")),
		})
		pj.aplicar_apariencia(ap_ropa, 30)
		assert_not_null(pj.get_node_or_null("BodyPivot/Torso/HeadGroup"))

	pj.establecer_actividad("Salir a correr")
	assert_eq(pj.pose_general, "correr")
	pj.actualizar_pose_general(0.5, false)

	pj.establecer_pose("idle", "feliz")
	pj.actualizar_pose_general(0.2, true)
	# En modo título / mirando a cámara, el pivote rota cerca de PI (~3/4 frontal hacia +Z)
	var body_piv := pj.get_node_or_null("BodyPivot") as Node3D
	assert_not_null(body_piv)
	assert_gt(body_piv.rotation.y, 2.0)


func test_formas_2d_runner_personaje_y_banner_usan_personaje_visual_del_sim() -> void:
	var rp_2d := Runner_Personaje.new()
	add_child_autofree(rp_2d)
	var ap_custom := Apariencia_Personaje.normalizar({
		"genero": "mujer",
		"estilo_pelo": "dos_coletas",
		"color_ropa": "#e11d48",
		"estilo_ropa": "deportivo",
	})
	rp_2d.configurar(ap_custom)
	rp_2d.pose = "saltar"
	var pv_hijo := rp_2d.get_node_or_null("Personaje_Visual_2D") as Personaje_Visual
	assert_not_null(pv_hijo)
	assert_eq(pv_hijo.pose, "volando")
	assert_eq(str(pv_hijo.apariencia["estilo_pelo"]), "dos_coletas")

	var banner := Banner_Correr.new()
	banner.size = Vector2(640.0, 142.0)
	add_child_autofree(banner)
	await get_tree().process_frame
	var pv_banner := banner.get_node_or_null("Corredor_Sim_2D") as Personaje_Visual
	assert_not_null(pv_banner)
	assert_eq(pv_banner.pose, "correr")


func test_escena_correr_3d_carga_y_libera_limpio() -> void:
	assert_not_null(EscenaCorrer)
	var instancia := EscenaCorrer.instantiate()
	assert_true(instancia is Control)
	add_child_autofree(instancia)
	await get_tree().process_frame
	assert_not_null(instancia.get_node_or_null("Runner_Mundo"))


func test_animacion_fluida_saltos_transiciones_y_aterrizaje() -> void:
	var sim := Runner_Simulacion.new()
	sim.reiniciar(false)
	sim.jugador["ciclo_carrera"] = 0.0
	assert_eq(sim.aplicar_comando("SALTAR"), "SALTAR")
	var pie1: int = int(sim.jugador["salto_pie"])
	var aterrizo: bool = false
	for _i in range(60):
		var ev := sim.avanzar(0.02, false)
		if bool(ev.get("aterrizo", false)):
			aterrizo = true
			break
	assert_true(aterrizo, "Debe registrar el aterrizaje del primer salto")
	assert_gt(float(sim.jugador.get("aterrizaje_t", 0.0)), 0.0)

	# Segundo salto con la fase opuesta de zancada debe alternar la pierna líder
	sim.jugador["ciclo_carrera"] = PI
	assert_eq(sim.aplicar_comando("SALTAR"), "SALTAR")
	assert_ne(int(sim.jugador["salto_pie"]), pie1)

	var pj := Runner_Personaje_3D.new()
	add_child_autofree(pj)
	var pu := {"tabla": 0.0, "zapatillas": 0.0, "iman": 0.0, "jetpack": 0.0, "pogo": 0.0}
	pj.actualizar_animacion(sim.jugador, pu, 0.2, false, 0.016, false, 1.0)
	pj.actualizar_animacion(sim.jugador, pu, 0.23, false, 0.016, false, 1.0)

	# Transición suave hacia vuelo horizontal en jetpack
	var j_fly: Dictionary = sim.jugador.duplicate()
	j_fly["estado"] = "VOLANDO"
	j_fly["y"] = Runner_Simulacion.ALTURA_VUELO_JETPACK
	var pu_fly := {"tabla": 0.0, "zapatillas": 0.0, "iman": 0.0, "jetpack": 4.0, "pogo": 0.0}
	for f in range(18):
		pj.actualizar_animacion(j_fly, pu_fly, 0.4 + float(f) * 0.016, false, 0.016, false, 1.0)
	var body_piv := pj.get_node_or_null("BodyPivot") as Node3D
	var pogo_node := pj.get_node_or_null("BodyPivot/PogoCohete") as Node3D
	assert_lt(body_piv.rotation.x, -1.1)

	# En Pogo el bastón hereda el giro de BodyPivot sin duplicar rotación Y
	var j_pogo: Dictionary = sim.jugador.duplicate()
	j_pogo["estado"] = "POGO"
	j_pogo["pogo_progreso"] = 0.45
	var pu_pogo := {"tabla": 0.0, "zapatillas": 0.0, "iman": 0.0, "jetpack": 0.0, "pogo": 2.0}
	pj.actualizar_animacion(j_pogo, pu_pogo, 1.0, false, 0.016, true, 1.0)
	assert_almost_eq(pogo_node.rotation.y, 0.0, 0.001)
