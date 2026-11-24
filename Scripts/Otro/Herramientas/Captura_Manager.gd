extends Node

# Herramienta de QA visual de «El Mánager».
# Uso (con display):
#   godot --path . res://Escenas/Herramientas/Captura_Manager.tscn
# Guarda las capturas en /tmp/opencode/capturas_manager.

const DIR_SALIDA := "/tmp/opencode/capturas_manager"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR_SALIDA)
	await get_tree().process_frame

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261124
	var eco: Dictionary = Simulador_Manager.Crear_Ecosistema(
		"Deportivo del Sim", ["#0f766e", "#ffffff"], 1, rng, "Valoria")
	var est: Dictionary = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	est["Desbloqueado"] = true
	est["Activo"] = true
	est["Titulo_Entrenador"] = true
	est["Clubes"] = eco["Clubes"]
	est["Divisiones"] = eco["Divisiones"]
	est["Reputacion"] = 48
	est["Temporada"] = 2
	est["Jornada_Actual"] = 2

	var usr_id: String = str(est.get("Club_Usuario_Id", "club_usr"))
	var div4_raw: Array = eco["Divisiones"].get("4", [])
	var ia_ids: Array = []
	for cid in div4_raw:
		if str(cid) != usr_id:
			ia_ids.append(str(cid))
	var rival_id: String = str(ia_ids[0]) if not ia_ids.is_empty() else "club_0"
	var u_club: Dictionary = eco["Clubes"][usr_id]
	u_club["victorias"] = 2
	u_club["empates"] = 0
	u_club["derrotas"] = 0
	u_club["puntos"] = 6
	u_club["goles_favor"] = 5
	u_club["goles_contra"] = 1
	u_club["racha"] = ["V", "V"]
	u_club["instalaciones"] = {"estadio": 2, "entrenamiento": 2, "cantera": 1}
	u_club["cantera_dia"] = Variables_Dinamicas.Minute_Day
	u_club["cantera_candidatos"] = Simulador_Manager.Generar_Canteranos_Ojeo(usr_id, 4, 2, rng)
	var u_pl: Array = u_club.get("plantilla", [])
	if u_pl.size() >= 10:
		u_pl[9]["goles"] = 3
		u_pl[9]["asistencias"] = 2
		u_pl[9]["partidos_jugados"] = 2
		u_pl[8]["goles"] = 2
		u_pl[8]["asistencias"] = 1
		u_pl[8]["partidos_jugados"] = 2
	if ia_ids.size() >= 3:
		var r1: Dictionary = eco["Clubes"][str(ia_ids[0])]
		r1["victorias"] = 1
		r1["empates"] = 1
		r1["derrotas"] = 0
		r1["puntos"] = 4
		r1["goles_favor"] = 3
		r1["goles_contra"] = 2
		var r2: Dictionary = eco["Clubes"][str(ia_ids[1])]
		r2["victorias"] = 0
		r2["empates"] = 1
		r2["derrotas"] = 1
		r2["puntos"] = 1
		r2["goles_favor"] = 1
		r2["goles_contra"] = 3
		var r3: Dictionary = eco["Clubes"][str(ia_ids[2])]
		r3["victorias"] = 0
		r3["empates"] = 0
		r3["derrotas"] = 2
		r3["puntos"] = 0
		r3["goles_favor"] = 0
		r3["goles_contra"] = 4

	est["Partido_Pendiente"] = true
	est["Partido_Local_Id"] = usr_id
	est["Partido_Visitante_Id"] = rival_id
	est["Partido_Es_Local"] = true
	est["Partido_Jornada"] = 2
	est["Ultimos_Resultados"] = [
		{"temporada": 2, "jornada": 2, "rival": str(eco["Clubes"][str(ia_ids[1])]["nombre"]) if ia_ids.size() > 1 else "Atlético Norte", "marcador": "3-1", "resultado": "Victoria", "auto": false},
		{"temporada": 2, "jornada": 1, "rival": str(eco["Clubes"][str(ia_ids[2])]["nombre"]) if ia_ids.size() > 2 else "Unión Sur", "marcador": "2-0", "resultado": "Victoria", "auto": false}
	]
	Variables_Dinamicas.Manager_Estado = est
	Variables_Dinamicas.Dinero = 2450.0

	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var panel = load("res://Escenas/Escena_Principal/Panel_Manager.tscn").instantiate()
	vp.add_child(panel)
	await get_tree().process_frame
	await get_tree().process_frame

	await _Capturar(vp, "manager_club.png")

	panel._tab_actual = "plantilla"
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_plantilla.png")

	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var jugador: Dictionary = club["plantilla"][0]
	panel._Abrir_Ficha_Jugador(str(jugador["id"]))
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_ficha.png")
	panel._Cerrar_Ficha()

	panel._tab_actual = "tactica"
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_tactica.png")

	panel._tab_actual = "mercado"
	panel._mercado_modo = "fichar"
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_mercado.png")

	panel._mercado_modo = "cantera"
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_cantera.png")

	var clubes: Dictionary = Sistema_Manager.Obtener_Clubes()
	var primer_rival: Dictionary = {}
	for club_id in clubes.keys():
		if str(club_id) != Sistema_Manager.Club_Usuario_Id():
			primer_rival = clubes[club_id]
			break
	var jugador_rival: Dictionary = primer_rival["plantilla"][0]
	panel._Abrir_Modal_Oferta(str(jugador_rival["id"]))
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_oferta.png")
	panel._Cerrar_Modal_Oferta()

	panel._tab_actual = "liga"
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_liga.png")

	# Partido en vivo: minuto 45 descanso y minuto 63 en vivo.
	var estado: Dictionary = Simulador_Manager.Crear_Estado_Partido(
		Sistema_Manager.Club_Usuario(), primer_rival)
	estado["temporada"] = 2
	estado["jornada"] = 2
	estado["lado_usuario"] = "local"
	estado["utilizados_local"] = (estado["alineacion_local"] as Array).duplicate()
	estado["utilizados_visitante"] = (estado["alineacion_visitante"] as Array).duplicate()
	var rng_partido := RandomNumberGenerator.new()
	rng_partido.seed = 424242
	for _i in range(45):
		Simulador_Manager.Simular_Minuto(estado, rng_partido)
	var panel_partido = load("res://Escenas/Escena_Principal/Panel_Manager_Partido.tscn").instantiate()
	vp.add_child(panel_partido)
	panel_partido.abrir(estado)
	panel_partido._jugando = false
	panel_partido._Abrir_Modal_Descanso()
	await get_tree().create_timer(0.15).timeout
	await _Capturar(vp, "manager_descanso.png")
	panel_partido._Cerrar_Modal_Descanso()

	for _i in range(18):
		Simulador_Manager.Simular_Minuto(estado, rng_partido)
	panel_partido._jugando = false
	panel_partido._Anadir_Nuevos_Eventos()
	panel_partido._Actualizar_Todo()
	await get_tree().create_timer(0.20).timeout
	await _Capturar(vp, "manager_partido.png")
	panel_partido._Abrir_Modal_Cambios()
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_cambios.png")
	panel_partido._Cerrar_Modal_Cambios()
	Simulador_Manager.Simular_Partido_Completo(estado, rng_partido)
	panel_partido._Anadir_Nuevos_Eventos()
	panel_partido._Actualizar_Todo()
	panel_partido._Mostrar_Resultado()
	await get_tree().create_timer(0.15).timeout
	await _Capturar(vp, "manager_resultado.png")
	panel_partido.queue_free()
	await get_tree().process_frame

	# Desbloqueo y fundación.
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Variables_Dinamicas.Carrera_Futbol["Activo"] = false
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_desbloqueo.png")

	Variables_Dinamicas.Manager_Estado["Desbloqueado"] = true
	panel._Refrescar(true)
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_fundacion.png")

	# Tarjeta Banner_Manager del Hub (estado club activo).
	Variables_Dinamicas.Manager_Estado = est
	var banner := Banner_Manager.new()
	banner.position = Vector2(20, 40)
	banner.size = Vector2(680, 146)
	vp.add_child(banner)
	banner.configurar(Sistema_Manager.Club_Usuario())
	await get_tree().create_timer(0.12).timeout
	await _Capturar(vp, "manager_banner.png")
	banner.queue_free()

	# Telón animado de entrada al minijuego en horizontal.
	var trans := Transicion_Minijuego.new()
	trans.configurar_tema("manager", Sistema_Manager.Club_Usuario())
	vp.add_child(trans)
	await trans.Cubrir(str(Sistema_Manager.Club_Usuario().get("nombre", "El Mánager")),
		"Preparando el vestuario y la pizarra…")
	await get_tree().create_timer(0.10).timeout
	await _Capturar(vp, "manager_transicion.png")
	trans.queue_free()

	print("Capturas de El Mánager guardadas en ", DIR_SALIDA)
	get_tree().quit()


func _Capturar(vp: SubViewport, nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
