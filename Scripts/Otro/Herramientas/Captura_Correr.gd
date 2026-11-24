extends Node

# Capturas de QA del minijuego 3D "Salir a correr" (PARK RUSH 3D).
# Usa un SubViewport vertical 720x1280 y no toca la partida real.
# Genera capturas de: menú, partida, techo/rampa, tabla urbana, otro Sim 3D,
# variante nocturna, pausa y resultado.
#
# Uso:
#   godot --path . res://Escenas/Herramientas/Captura_Correr.tscn

const DIR_SALIDA := "user://capturas_correr"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	Variables_Dinamicas.Minute_Minute = 900 # 15:00 soleado
	await get_tree().process_frame

	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var mini: Control = load("res://Escenas/Minijuego_Correr/Minijuego_Correr.tscn").instantiate()
	vp.add_child(mini)
	await _esperar_frames(8)
	var mundo: Runner_Mundo = mini._mundo
	var sim: Runner_Simulacion = mundo.simulacion

	# 1. Menú principal 3D con el Sim actual
	_Guardar(vp, "01_menu.png")

	# 1b. Intro con la cámara acercándose y el guardia detrás
	mini._menu.visible = false
	mini._hud.visible = true
	mini._estado = "jugando"
	mundo.iniciar(mini._Apariencia_Actual(), -1, true)
	await get_tree().create_timer(0.18).timeout
	_Guardar(vp, "01b_intro.png")
	await get_tree().create_timer(1.35).timeout

	# 2. Partida en curso con seto alto, pasarela con rampa, valla, arco, monedas y power-up
	mini._menu.visible = false
	mini._hud.visible = true
	mini._estado = "jugando"
	mundo.iniciar(mini._Apariencia_Actual(), -1, false)
	mundo.pausar(true)
	sim.obstaculos.clear()
	sim.monedas_entidades.clear()
	sim.powerups_entidades.clear()
	sim.distancia = 420.0
	sim.puntuacion = 4200.0
	sim.monedas = 28
	sim.llaves = 2
	sim.jugador["carril_objetivo"] = 0
	sim.jugador["x"] = 0.0
	sim.jugador["y"] = 0.0
	sim.jugador["ciclo_carrera"] = 1.2
	sim.anadir_obstaculo("SETO_ALTO", -1, -18.0, 0)
	sim.anadir_obstaculo("PASARELA_RAMPA", 1, -24.0, 1)
	sim.anadir_obstaculo("VALLA_BAJA", 0, -34.0)
	sim.anadir_obstaculo("ARCO_ALTO", -1, -46.0)
	sim.anadir_obstaculo("TREN_MOVIL", 0, -64.0, 2, 6.0)
	for i in range(6):
		sim.anadir_moneda(0, 0.95, -7.0 - float(i) * 2.6, float(i) * 0.4)
	sim.anadir_powerup("IMAN", 1, 1.15, -11.0)
	sim.anadir_powerup("LLAVE", 1, 1.30, -14.0)
	sim.anadir_powerup("CAJA", 0, 1.20, -18.0)
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02_partida.png")

	# 2a2. Túnel ferroviario con cámara rasante
	sim.obstaculos.clear()
	sim.monedas_entidades.clear()
	sim.powerups_entidades.clear()
	sim.anadir_obstaculo("TUNEL", 0, 0.0)
	for i in range(6):
		sim.anadir_moneda(0, 0.95, -5.0 - float(i) * 3.0, float(i) * 0.3)
	sim.jugador["tunel"] = true
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02a2_tunel.png")

	# 2a3. Tren largo de 3 vagones con rampa para correr por los techos
	sim.jugador["tunel"] = false
	sim.obstaculos.clear()
	sim.monedas_entidades.clear()
	sim.powerups_entidades.clear()
	sim.anadir_obstaculo("TREN_LARGO_RAMPA", -1, -28.0, 1)
	sim.anadir_obstaculo("TREN_LARGO", 1, -46.0, 2)
	for i in range(8):
		sim.anadir_moneda(-1, Runner_Simulacion.ALTURA_PLATAFORMA + 0.95, -12.0 - float(i) * 2.8, float(i) * 0.35)
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02a3_tren_largo.png")

	# 2b. Corriendo sobre la pasarela elevada con monedas delante y ciclista en el centro
	sim.obstaculos.clear()
	sim.monedas_entidades.clear()
	sim.powerups_entidades.clear()
	sim.anadir_obstaculo("PASARELA_RAMPA", 1, -2.0, 1)
	sim.anadir_obstaculo("SETO_ALTO", -1, -10.0, 0)
	sim.anadir_obstaculo("CICLISTA", 0, -28.0, 2)
	for i in range(5):
		sim.anadir_moneda(1, Runner_Simulacion.ALTURA_PLATAFORMA + 0.95, -5.0 - float(i) * 2.5, float(i) * 0.35)
	sim.jugador["carril_objetivo"] = 1
	sim.jugador["x"] = Runner_Simulacion.carril_a_x(1)
	sim.jugador["y"] = Runner_Simulacion.ALTURA_PLATAFORMA
	sim.jugador["suelo_y"] = Runner_Simulacion.ALTURA_PLATAFORMA
	sim.jugador["en_techo"] = true
	sim.jugador["ciclo_carrera"] = 2.1
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02b_techo.png")

	# 2c. Hover-Longboard (Tabla) + Imán + Súper Zapatillas + 2x activos
	sim.jugador["carril_objetivo"] = 0
	sim.jugador["x"] = 0.0
	sim.jugador["y"] = 0.0
	sim.jugador["suelo_y"] = 0.0
	sim.jugador["en_techo"] = false
	sim.powerups["tabla"] = 14.0
	sim.powerups["iman"] = 9.0
	sim.powerups["zapatillas"] = 8.0
	sim.powerups["multiplicador"] = 11.0
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02c_tabla_powerups.png")

	# 2c2. Jetpack de Subway Surfers: el Sim vuela sobre las vías con estela de monedas
	sim.powerups["jetpack"] = 8.0
	sim.powerups["pogo"] = 0.0
	sim.powerups["tabla"] = 0.0
	sim.jugador["estado"] = "VOLANDO"
	sim.jugador["y"] = Runner_Simulacion.ALTURA_VUELO_JETPACK
	sim.jugador["vy"] = 0.0
	sim.obstaculos.clear()
	sim.monedas_entidades.clear()
	for i in range(8):
		sim.anadir_moneda(0 if i % 3 else -1, Runner_Simulacion.ALTURA_VUELO_JETPACK + 0.95, -8.0 - float(i) * 3.0, float(i) * 0.4)
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02c2_jetpack.png")

	# 2c3. Pogo cohete con el arco de monedas
	sim.powerups["jetpack"] = 0.0
	sim.powerups["pogo"] = 3.0
	sim.jugador["estado"] = "POGO"
	sim.jugador["pogo_progreso"] = 0.45
	sim.jugador["y"] = 6.0
	sim.monedas_entidades.clear()
	sim.obstaculos.clear()
	for i in range(7):
		sim.anadir_moneda(-1 if i % 2 else 1, 6.0 + sin(float(i) / 6.0 * PI) * 2.0, -8.0 - float(i) * 4.0, float(i) * 0.35)
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02c3_pogo.png")

	# 2c4. Guardia y perro acercándose tras un tropiezo
	sim.powerups["pogo"] = 0.0
	sim.jugador["estado"] = "TROPEZANDO"
	sim.jugador["y"] = 0.0
	sim.jugador["tiempo_tropiezo"] = 2.4
	sim.guardia_distancia = 4.2
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02c4_guardia.png")

	# 2c5. Modal de reanimación con llaves (primera gratis y siguientes con coste)
	sim.jugador["estado"] = "CAIDO"
	sim.llaves = 2
	sim.guardia_distancia = 4.0
	mundo.forzar_sincronizacion_visual()
	mini._Abrir_Revive()
	await _esperar_frames(5)
	_Guardar(vp, "02c5_reanimar.png")
	mini._modal_revive.visible = false
	mini._revive_activo = false
	mini._estado = "jugando"
	sim.jugador["estado"] = "CORRIENDO"
	sim.jugador["y"] = 0.0
	sim.llaves = 0
	mundo.pausar(false)

	# 2d. Otro Sim completamente distinto (mujer rubia con coleta, vestido rojo y gafas)
	sim.powerups = {"iman": 0.0, "zapatillas": 0.0, "multiplicador": 0.0, "tabla": 0.0, "jetpack": 0.0, "pogo": 0.0}
	var otro_sim: Dictionary = Apariencia_Personaje.normalizar({
		"genero": "mujer",
		"color_piel": "#dfb284",
		"color_pelo": "#eab308",
		"estilo_pelo": "coleta",
		"ropa_superior": "top",
		"color_ropa": "#e11d48",
		"color_ropa_secundario": "#fef08a",
		"ropa_inferior": "falda",
		"color_pantalon": "#be185d",
		"estilo_ropa": "vestido",
		"detalle_ropa": "flores",
		"color_ropa_detalle": "#16a34a",
		"calzado": "zapatillas",
		"color_calzado": "#f1f5f9",
		"gafas": "sol",
		"sombrero": "diadema",
	})
	mundo.iniciar_menu(otro_sim, 24)
	mini._menu.visible = true
	mini._hud.visible = false
	mini._estado = "menu"
	await _esperar_frames(5)
	_Guardar(vp, "02d_otro_sim.png")

	# 2e. Variante nocturna con farolas brillantes
	Variables_Dinamicas.Minute_Minute = 1320 # 22:00 noche
	mini._menu.visible = false
	mini._hud.visible = true
	mini._estado = "jugando"
	mundo.iniciar(mini._Apariencia_Actual(), -1, false)
	mundo.pausar(true)
	mundo.forzar_sincronizacion_visual()
	mini._Actualizar_HUD()
	await _esperar_frames(5)
	_Guardar(vp, "02e_noche.png")
	Variables_Dinamicas.Minute_Minute = 900
	mundo.forzar_sincronizacion_visual()
	await _esperar_frames(3)

	# 3. Pausa
	mini._Alternar_Pausa()
	await _esperar_frames(4)
	_Guardar(vp, "03_pausa.png")

	# 4. Resultado con recompensa al Sim
	mini._modal_pausa.visible = false
	mini._hud.visible = false
	var recompensa: Dictionary = Sistema_Correr.Calcular_Recompensa(850.0, 42)
	var resumen: Dictionary = {
		"distancia": 850.0,
		"monedas": 42,
		"puntuacion": 8500,
		"nuevo_record": true,
		"record_anterior": 306.0,
		"mejor_distancia": 850.0,
		"mejor_puntuacion": 8500,
		"carreras": 5,
		"monedas_totales": 192,
		"recompensa": recompensa,
	}
	mini._Construir_Resultado(resumen)
	mini._modal_fin.visible = true
	mini._modal_fin.modulate.a = 1.0
	await _esperar_frames(4)
	_Guardar(vp, "04_resultado.png")

	mini.queue_free()
	vp.queue_free()
	print("Capturas 3D de correr guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _esperar_frames(n: int) -> void:
	for _i in range(n):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _Guardar(vp: SubViewport, nombre: String) -> void:
	var imagen: Image = vp.get_texture().get_image()
	if imagen == null:
		push_error("No se pudo capturar %s" % nombre)
		return
	imagen.save_png("%s/%s" % [DIR_SALIDA, nombre])
