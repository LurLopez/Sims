class_name Runner_Mundo
extends Control

# ============================================================================
# MUNDO 3D DEL MINIJUEGO "SALIR A CORRER" (PARK RUSH 3D)
#
# Aloja un SubViewport 3D propio (gl_compatibility friendly) con Camera3D,
# iluminación exterior de 3 puntos, cielo procedural + niebla atmosférica,
# 6 chunks infinitos del bulevar del parque, el corredor 3D del Sim actual,
# obstáculos/monedas/power-ups sincronizados desde Runner_Simulacion y un
# pool de partículas 3D (MultiMeshInstance3D) sin asignaciones por fotograma.
# ============================================================================

signal moneda_recogida(total: int, posicion: Vector3)
signal powerup_recogido(tipo: String, duracion: float)
signal tabla_activada(restantes: int)
signal tabla_salvo()
signal tropiezo()
signal choque(tipo: String)
signal caido(tipo: String)
signal revivido()
signal llave_recogida(total: int)
signal caja_abierta(texto: String)
signal mision_completada(texto: String)
signal intro_terminada()
signal vuelo_iniciado()
signal vuelo_terminado()
signal jetpack_iniciado()
signal pogo_iniciado()
signal salto_realizado(super_salto: bool)
signal deslizamiento_realizado()
signal carril_cambiado(direccion: int)
signal aterrizaje()
signal paso_dado(en_techo: bool)
signal hito(distancia_hito: int)

const NUM_CHUNKS: int = 6
const MAX_PARTICULAS: int = 160
const SHADER_CIELO: Shader = preload("res://Shaders/Runner_Cielo.gdshader")

var simulacion: Runner_Simulacion
var _texturas: Runner_Texturas_3D
var _escenario: Runner_Escenario_3D

var _vp_container: SubViewportContainer
var _viewport: SubViewport
var _raiz_3d: Node3D
var _camara: Camera3D
var _entorno: WorldEnvironment
var _env_res: Environment
var _sky_mat: ShaderMaterial
var _sol: DirectionalLight3D
var _luz_borde: DirectionalLight3D
var _factor_noche_actual: float = 0.0
var _curva_x_actual: float = 0.0
var _curva_y_actual: float = 0.0022
var _acum_trail_tabla: float = 0.0

var _chunks: Array[Node3D] = []
var _personaje_3d: Runner_Personaje_3D
var _guardia_3d: Runner_Guardia_3D
var _nodos_obstaculos: Dictionary = {} # id -> Node3D
var _nodos_monedas: Dictionary = {} # id -> Node3D
var _nodos_powerups: Dictionary = {} # id -> Node3D

# Pool de partículas 3D (zero-GC)
var _mmi_particulas: MultiMeshInstance3D
var _mm_particulas: MultiMesh
var _particulas: Array[Dictionary] = []
var _cursor_particula: int = 0

# Estado visual y cámara
var _modo: String = "menu" # menu | listo | intro | jugando | detenido
var _pausado: bool = false
var _intro_t: float = 0.0
var _tiempo: float = 0.0
var _tiempo_carrera: float = 0.0
var _hitstop: float = 0.0
var _shake_trauma: float = 0.0
var _cam_pos := Vector3(1.8, 2.95, 5.6)
var _cam_look := Vector3(0.0, 1.65, -14.0)
var _fov_actual: float = 62.0
var _factor_tunel: float = 0.0
var _factor_vuelo: float = 0.0
var _cam_roll: float = 0.0
var _tamano_vista := Vector2(720.0, 1280.0)
var _ultimo_minuto_clima: int = -1
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	simulacion = Runner_Simulacion.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tamano_vista = get_viewport_rect().size
	if _tamano_vista.x <= 1.0 or _tamano_vista.y <= 1.0:
		_tamano_vista = Vector2(720.0, 1280.0)
	_construir_escena_3d()
	_sincronizar_entidades()
	_actualizar_ambiente_horario(true)
	_actualizar_camara(0.016, true)
	if _personaje_3d != null:
		_personaje_3d.actualizar_animacion(simulacion.jugador, simulacion.powerups, 0.0, true, 0.016, true)


func _construir_escena_3d() -> void:
	_texturas = Runner_Texturas_3D.new()
	_escenario = Runner_Escenario_3D.new(_texturas)

	_vp_container = SubViewportContainer.new()
	_vp_container.name = "Contenedor_3D"
	_vp_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp_container.stretch = true
	_vp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vp_container)

	_viewport = SubViewport.new()
	_viewport.name = "Viewport_3D"
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.handle_input_locally = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp_container.add_child(_viewport)

	_raiz_3d = Node3D.new()
	_raiz_3d.name = "Raiz_3D"
	_viewport.add_child(_raiz_3d)

	# Cámara 3D
	_camara = Camera3D.new()
	_camara.name = "Camara_Runner"
	_camara.fov = 62.0
	_camara.near = 0.25
	_camara.far = 220.0
	_camara.current = true
	_raiz_3d.add_child(_camara)

	# Cielo estilizado Subway Surfers (nubes pintadas, sol, luna y estrellas) + niebla atmosférica lejana
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SHADER_CIELO

	var sky := Sky.new()
	sky.sky_material = _sky_mat

	_env_res = Environment.new()
	_env_res.background_mode = Environment.BG_SKY
	_env_res.sky = sky
	_env_res.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env_res.ambient_light_sky_contribution = 0.85
	_env_res.ambient_light_energy = 0.56
	_env_res.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env_res.tonemap_exposure = 1.02
	_env_res.fog_enabled = true
	_env_res.fog_mode = Environment.FOG_MODE_DEPTH
	_env_res.fog_light_color = Color("#7ecbf8")
	_env_res.fog_depth_begin = 68.0
	_env_res.fog_depth_end = 158.0
	_env_res.fog_density = 0.88
	_env_res.fog_sky_affect = 0.0

	_entorno = WorldEnvironment.new()
	_entorno.name = "Entorno_Parque"
	_entorno.environment = _env_res
	_raiz_3d.add_child(_entorno)

	# Iluminación exterior vibrante estilo Subway Surfers (sol cálido + relleno cielo azul)
	_sol = DirectionalLight3D.new()
	_sol.name = "Luz_Sol"
	_sol.light_color = Color("#fff4d6")
	_sol.light_energy = 1.05
	_sol.shadow_enabled = true
	_sol.shadow_bias = 0.04
	_sol.shadow_normal_bias = 0.55
	_sol.shadow_opacity = 0.68
	_sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sol.directional_shadow_max_distance = 58.0
	_sol.rotation_degrees = Vector3(-46.0, 28.0, 0.0)
	_raiz_3d.add_child(_sol)

	_luz_borde = DirectionalLight3D.new()
	_luz_borde.name = "Luz_Relleno"
	_luz_borde.light_color = Color("#74c0fc")
	_luz_borde.light_energy = 0.36
	_luz_borde.shadow_enabled = false
	_luz_borde.rotation_degrees = Vector3(-26.0, -148.0, 0.0)
	_raiz_3d.add_child(_luz_borde)

	# 6 chunks continuos del bulevar del parque
	for i in range(NUM_CHUNKS):
		var chunk: Node3D = _escenario.crear_chunk_parque(i)
		chunk.position.z = 16.0 - float(i) * Runner_Escenario_3D.LARGO_CHUNK
		_raiz_3d.add_child(chunk)
		_chunks.append(chunk)

	# Personaje 3D articulado del Sim
	_personaje_3d = Runner_Personaje_3D.new(_texturas.sombra_contacto)
	_raiz_3d.add_child(_personaje_3d)

	# Guardia y perro que persiguen al Sim (Subway Surfers)
	_guardia_3d = Runner_Guardia_3D.new()
	_raiz_3d.add_child(_guardia_3d)

	# Pool de partículas 3D (MultiMeshInstance3D)
	_construir_pool_particulas()


func _construir_pool_particulas() -> void:
	_mm_particulas = MultiMesh.new()
	_mm_particulas.transform_format = MultiMesh.TRANSFORM_3D
	_mm_particulas.use_colors = true
	var p_box := BoxMesh.new()
	p_box.size = Vector3(0.16, 0.16, 0.16)
	_mm_particulas.mesh = p_box
	_mm_particulas.instance_count = MAX_PARTICULAS

	var p_mat := StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.vertex_color_use_as_albedo = true

	_mmi_particulas = MultiMeshInstance3D.new()
	_mmi_particulas.name = "Particulas_3D"
	_mmi_particulas.multimesh = _mm_particulas
	_mmi_particulas.material_override = p_mat
	_mmi_particulas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi_particulas.extra_cull_margin = 100.0
	_raiz_3d.add_child(_mmi_particulas)

	var oculto := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0.0, -100.0, 0.0))
	_particulas.clear()
	for i in range(MAX_PARTICULAS):
		_mm_particulas.set_instance_transform(i, oculto)
		_mm_particulas.set_instance_color(i, Color.WHITE)
		_particulas.append({
			"activa": false,
			"pos": Vector3.ZERO,
			"vel": Vector3.ZERO,
			"vida": 0.0,
			"vida_max": 0.4,
			"tam": 1.0,
			"color": Color("#ffd43b"),
		})


# ----------------------------------------------------------------------------
# API pública (usada por Minijuego_Correr.gd y Captura_Correr.gd)
# ----------------------------------------------------------------------------

func configurar_tamano(tam: Vector2) -> void:
	if tam.x <= 1.0 or tam.y <= 1.0:
		return
	_tamano_vista = tam


func aplicar_apariencia_sim(apariencia: Dictionary, edad: int = -1) -> void:
	if _personaje_3d != null:
		_personaje_3d.aplicar_apariencia(apariencia, edad)


func iniciar_menu(apariencia: Dictionary, edad: int = -1) -> void:
	_limpiar_mallas_dinamicas()
	simulacion.reiniciar(true)
	aplicar_apariencia_sim(apariencia, edad)
	_resetear_chunks()
	_modo = "menu"
	_pausado = false
	_tiempo_carrera = 0.0
	_hitstop = 0.0
	_shake_trauma = 0.0
	_sincronizar_entidades()
	_actualizar_ambiente_horario(true)
	_actualizar_camara(0.016, true)
	if _personaje_3d != null:
		_personaje_3d.actualizar_animacion(simulacion.jugador, simulacion.powerups, _tiempo, true, 0.016, true)


func preparar(apariencia: Dictionary, edad: int = -1) -> void:
	_limpiar_mallas_dinamicas()
	simulacion.reiniciar(true)
	aplicar_apariencia_sim(apariencia, edad)
	_resetear_chunks()
	_modo = "listo"
	_pausado = false
	_tiempo_carrera = 0.0
	_hitstop = 0.0
	_shake_trauma = 0.0
	_sincronizar_entidades()
	_actualizar_ambiente_horario(true)


func iniciar(apariencia: Dictionary, edad: int = -1, con_intro: bool = true) -> void:
	aplicar_apariencia_sim(apariencia, edad)
	if _modo != "listo":
		_limpiar_mallas_dinamicas()
		simulacion.reiniciar(true)
		_resetear_chunks()
	_modo = "intro" if con_intro else "jugando"
	_intro_t = 0.0
	if con_intro:
		simulacion.guardia_distancia = 2.6
		_cam_pos = Vector3(0.0, 2.35, 4.25)
		_cam_look = Vector3(0.0, 1.5, -7.0)
		_fov_actual = 58.0
	else:
		simulacion.guardia_distancia = Runner_Simulacion.DISTANCIA_GUARDIA_LEJOS
	_pausado = false
	_tiempo_carrera = 0.0
	_hitstop = 0.0
	_shake_trauma = 0.0
	_sincronizar_entidades()


func pausar(valor: bool) -> void:
	_pausado = valor


func detener() -> void:
	_modo = "detenido"
	_pausado = true


func cambiar_carril(direccion: int) -> void:
	if _modo != "jugando" or _pausado:
		return
	var cmd: String = "IZQUIERDA" if direccion < 0 else "DERECHA"
	var res: String = simulacion.aplicar_comando(cmd)
	if res == "CARRIL":
		carril_cambiado.emit(direccion)
		_emitir_particulas(Vector3(float(simulacion.jugador["x"]), float(simulacion.jugador["y"]) + 0.15, 0.2), 5, Color("#e2e8f0"), 3.2)
	elif res == "TROPIEZO":
		_shake_trauma = minf(1.0, _shake_trauma + 0.55)
		tropiezo.emit()
		_emitir_particulas(Vector3(float(simulacion.jugador["x"]), float(simulacion.jugador["y"]) + 0.9, 0.0), 12, Color("#f97316"), 4.8)
	elif res == "TROPIEZO_CAIDA":
		_al_caer(str(simulacion.jugador.get("tipo_caida", "lateral")))


func saltar() -> void:
	if _modo != "jugando" or _pausado:
		return
	var res: String = simulacion.aplicar_comando("SALTAR")
	if res == "SALTAR":
		var es_super: bool = float(simulacion.powerups["zapatillas"]) > 0.0
		salto_realizado.emit(es_super)
		var col := Color("#39ff88") if es_super else Color("#fef08a")
		_emitir_particulas(Vector3(float(simulacion.jugador["x"]), float(simulacion.jugador["y"]) + 0.12, 0.0), 10, col, 4.5)


func deslizar() -> void:
	if _modo != "jugando" or _pausado:
		return
	var res: String = simulacion.aplicar_comando("RODAR")
	if res == "RODAR" or res == "CAIDA_RODAR":
		deslizamiento_realizado.emit()
		_emitir_particulas(Vector3(float(simulacion.jugador["x"]), float(simulacion.jugador["y"]) + 0.25, 0.1), 8, Color("#cbd5e1"), 3.6)


func activar_tabla() -> bool:
	if _modo != "jugando" or _pausado:
		return false
	var res: String = simulacion.aplicar_comando("TABLA")
	if res == "TABLA":
		tabla_activada.emit(simulacion.tablas_restantes)
		var base := Vector3(float(simulacion.jugador["x"]), float(simulacion.jugador["y"]) + 0.4, 0.0)
		_emitir_particulas(base, 20, Color("#38bdf8"), 6.2)
		_emitir_particulas(base, 14, Color("#f43f5e"), 5.2)
		return true
	return false


func Obtener_Distancia() -> float:
	return simulacion.distancia


func Obtener_Puntuacion() -> int:
	return int(floor(simulacion.puntuacion))


func Obtener_Monedas() -> int:
	return simulacion.monedas


func Obtener_Multiplicador() -> int:
	return simulacion.obtener_multiplicador()


func Obtener_Progreso_Velocidad() -> float:
	return simulacion.obtener_progreso_velocidad()


func Obtener_Powerups() -> Dictionary:
	return simulacion.powerups.duplicate()


func Obtener_Tablas_Restantes() -> int:
	return simulacion.tablas_restantes


func Esta_Vivo() -> bool:
	return simulacion.esta_vivo()


func Esta_En_Techo() -> bool:
	return bool(simulacion.jugador.get("en_techo", false))


func Esta_Tropezando() -> bool:
	return float(simulacion.jugador.get("tiempo_tropiezo", 0.0)) > 0.0


func Esta_Reanimable() -> bool:
	return simulacion.esta_reanimable() and _modo == "jugando"


func Obtener_Llaves() -> int:
	return simulacion.llaves


func Gastar_Llaves(cantidad: int) -> bool:
	if cantidad <= 0:
		return true
	if simulacion.llaves < cantidad:
		return false
	simulacion.llaves -= cantidad
	return true


func Obtener_Misiones() -> Array[Dictionary]:
	return simulacion.misiones.duplicate(true)


func Obtener_Mision_Actual() -> Dictionary:
	for m in simulacion.misiones:
		if not bool(m.get("completada", false)):
			return m
	return {}


func Obtener_Distancia_Guardia() -> float:
	return simulacion.guardia_distancia


## Reanima al corredor tras una caída (la UI decide si es gratis o cuesta llave).
func revivir() -> bool:
	if not simulacion.revivir():
		return false
	_hitstop = 0.0
	_shake_trauma = 0.25
	_modo = "jugando"
	_pausado = false
	var jx: float = float(simulacion.jugador["x"])
	_emitir_particulas(Vector3(jx, 1.0, 0.0), 30, Color("#fef08a"), 7.5)
	_emitir_particulas(Vector3(jx, 0.8, 0.0), 22, Color("#38bdf8"), 6.0)
	revivido.emit()
	return true


func obtener_personaje_3d() -> Runner_Personaje_3D:
	return _personaje_3d


func forzar_sincronizacion_visual() -> void:
	_sincronizar_entidades()
	_actualizar_ambiente_horario(true)
	_actualizar_curva_horizonte()
	_actualizar_camara(0.016, true)
	if _personaje_3d != null:
		_personaje_3d.actualizar_animacion(simulacion.jugador, simulacion.powerups, _tiempo, _modo == "menu", 0.016, true)
	_actualizar_guardia(0.016)


# ----------------------------------------------------------------------------
# Bucle principal
# ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if _pausado or _modo == "detenido":
		return

	var dt: float = minf(delta, 0.12)
	_tiempo += dt
	if _shake_trauma > 0.0:
		_shake_trauma = maxf(0.0, _shake_trauma - dt * 2.1)

	if _modo == "intro":
		_intro_t += dt
		_sincronizar_entidades()
		if _personaje_3d != null:
			var intro_factor: float = clampf(_intro_t / 0.45, 0.0, 1.0)
			_personaje_3d.actualizar_animacion(simulacion.jugador, simulacion.powerups, _tiempo, false, dt, false, intro_factor)
		_actualizar_guardia(dt)
		_actualizar_camara(dt, false)
		_actualizar_ambiente_horario(false)
		_actualizar_curva_horizonte()
		if _sky_mat != null:
			_sky_mat.set_shader_parameter("tiempo", _tiempo)
		if _intro_t >= 1.35:
			_modo = "jugando"
			intro_terminada.emit()
		return

	if _modo == "jugando":
		if _hitstop > 0.0:
			_hitstop = maxf(0.0, _hitstop - dt)
		elif simulacion.esta_vivo():
			var subpasos: int = maxi(1, int(ceil(dt / 0.035)))
			var sub_dt: float = dt / float(subpasos)
			for _s in range(subpasos):
				_tiempo_carrera += sub_dt
				var ev: Dictionary = simulacion.avanzar(sub_dt, true)
				_desplazar_chunks(float(ev["dz"]))
				_procesar_eventos_simulacion(ev)
				if bool(ev["choco"]):
					break
			# Estela neón continua al surfear con la Hoverboard
			if float(simulacion.powerups["tabla"]) > 0.0:
				_acum_trail_tabla += dt
				if _acum_trail_tabla >= 0.045:
					_acum_trail_tabla = 0.0
					var jx: float = float(simulacion.jugador["x"])
					var jy: float = float(simulacion.jugador["y"])
					_emitir_particulas(Vector3(jx + _rng.randf_range(-0.22, 0.22), jy + 0.14, 0.55), 2, Color("#38bdf8"), 2.4)
					_emitir_particulas(Vector3(jx, jy + 0.12, 0.65), 1, Color("#fb3868"), 2.1)

			# Llama del jetpack y chispas del pogo
			var estado_pj: String = str(simulacion.jugador.get("estado", "CORRIENDO"))
			if estado_pj == "VOLANDO":
				_acum_trail_tabla += dt
				if _acum_trail_tabla >= 0.03:
					_acum_trail_tabla = 0.0
					var jx_f: float = float(simulacion.jugador["x"])
					var jy_f: float = float(simulacion.jugador["y"])
					_emitir_particulas(Vector3(jx_f - 0.22, jy_f + 0.88, 0.72), 2, Color("#fb923c"), 4.6)
					_emitir_particulas(Vector3(jx_f + 0.22, jy_f + 0.88, 0.72), 2, Color("#fde047"), 4.0)
			elif estado_pj == "POGO":
				_acum_trail_tabla += dt
				if _acum_trail_tabla >= 0.06:
					_acum_trail_tabla = 0.0
					var jx_p: float = float(simulacion.jugador["x"])
					var jy_p: float = float(simulacion.jugador["y"])
					_emitir_particulas(Vector3(jx_p, jy_p + 0.10, 0.30), 1, Color("#a78bfa"), 3.0)

	_sincronizar_entidades()
	if _personaje_3d != null:
		_personaje_3d.actualizar_animacion(simulacion.jugador, simulacion.powerups, _tiempo, _modo == "menu", dt, false)
	_actualizar_guardia(dt)
	_actualizar_particulas(dt)
	_actualizar_camara(dt, false)
	_actualizar_ambiente_horario(false)
	_actualizar_curva_horizonte()
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("tiempo", _tiempo)


func _procesar_eventos_simulacion(ev: Dictionary) -> void:
	var jx: float = float(simulacion.jugador["x"])
	var jy: float = float(simulacion.jugador["y"])

	if bool(ev["paso"]):
		paso_dado.emit(bool(simulacion.jugador.get("en_techo", false)))
		_emitir_particulas(Vector3(jx, jy + 0.08, 0.25), 2, Color("#e2e8f0"), 1.9)
	if bool(ev["aterrizo"]):
		aterrizaje.emit()
		_emitir_particulas(Vector3(jx, jy + 0.10, 0.1), 8, Color("#f1f5f9"), 3.8)
	if str(ev["buffer_disparado"]) == "SALTAR":
		salto_realizado.emit(float(simulacion.powerups["zapatillas"]) > 0.0)
	elif str(ev["buffer_disparado"]) == "RODAR":
		deslizamiento_realizado.emit()
	if bool(ev.get("tropiezo", false)):
		tropiezo.emit()
		_shake_trauma = minf(1.0, _shake_trauma + 0.55)
		_emitir_particulas(Vector3(jx, jy + 0.9, 0.0), 12, Color("#f97316"), 4.8)
	if bool(ev.get("jetpack_fin", false)) or bool(ev.get("pogo_fin", false)):
		vuelo_terminado.emit()
		_emitir_particulas(Vector3(jx, jy + 0.8, 0.0), 18, Color("#38bdf8"), 6.0)

	var recogidas: Array = ev["monedas_recogidas"]
	for pos_m in recogidas:
		moneda_recogida.emit(simulacion.monedas, pos_m)
		_emitir_particulas(pos_m, 7, Color("#ffd43b"), 4.4)

	var pu: String = str(ev["powerup_recogido"])
	if pu != "":
		var dur: float = 0.0
		match pu:
			"IMAN":
				dur = Runner_Simulacion.DURACION_IMAN
			"ZAPATILLAS":
				dur = Runner_Simulacion.DURACION_ZAPATILLAS
			"MULTIPLICADOR":
				dur = Runner_Simulacion.DURACION_MULTIPLICADOR
			"TABLA":
				dur = Runner_Simulacion.DURACION_TABLA
			"JETPACK":
				dur = Runner_Simulacion.DURACION_JETPACK
				jetpack_iniciado.emit()
				vuelo_iniciado.emit()
			"POGO":
				dur = Runner_Simulacion.DURACION_POGO
				pogo_iniciado.emit()
				vuelo_iniciado.emit()
		powerup_recogido.emit(pu, dur)
		_emitir_particulas(Vector3(jx, jy + 1.1, 0.0), 18, Color("#38bdf8"), 6.0)

	if int(ev.get("llave", 0)) > 0:
		llave_recogida.emit(simulacion.llaves)
		_emitir_particulas(Vector3(jx, jy + 0.9, 0.0), 12, Color("#fde047"), 5.0)

	if str(ev.get("caja_recompensa", "")) != "":
		caja_abierta.emit(str(ev["caja_recompensa"]))
		_emitir_particulas(Vector3(jx, jy + 1.0, 0.0), 22, Color("#fbbf24"), 6.8)

	if str(ev.get("mision_completada", "")) != "":
		mision_completada.emit(str(ev["mision_completada"]))
		_emitir_particulas(Vector3(jx, jy + 1.2, 0.0), 20, Color("#a7f3d0"), 6.4)

	if bool(ev["tabla_salvo"]):
		_shake_trauma = 0.85
		tabla_salvo.emit()
		_emitir_particulas(Vector3(jx, jy + 0.9, -1.0), 28, Color("#38bdf8"), 8.8)
		_emitir_particulas(Vector3(jx, jy + 0.9, -1.0), 20, Color("#f43f5e"), 7.4)

	if int(ev["hito"]) > 0:
		hito.emit(int(ev["hito"]))

	if bool(ev.get("caido", false)):
		_al_caer(str(ev["tipo_choque"]))
	elif bool(ev["choco"]):
		_al_chocar(str(ev["tipo_choque"]))


func _al_chocar(tipo: String) -> void:
	_hitstop = 0.08
	_shake_trauma = 1.0
	var jx: float = float(simulacion.jugador["x"])
	var jy: float = float(simulacion.jugador["y"])
	_emitir_particulas(Vector3(jx, jy + 1.0, 0.0), 26, Color("#ff6b35"), 7.0)
	_emitir_particulas(Vector3(jx, jy + 0.8, 0.0), 16, Color("#facc15"), 5.4)
	choque.emit(tipo)


func _al_caer(tipo: String) -> void:
	_al_chocar(tipo)
	caido.emit(tipo)


# ----------------------------------------------------------------------------
# Sincronización 3D (chunks, entidades, cámara, partículas, clima)
# ----------------------------------------------------------------------------

func _resetear_chunks() -> void:
	for i in range(_chunks.size()):
		_chunks[i].position.z = 16.0 - float(i) * Runner_Escenario_3D.LARGO_CHUNK


func _desplazar_chunks(dz: float) -> void:
	if dz <= 0.0:
		return
	var min_z: float = INF
	for c in _chunks:
		c.position.z += dz
		if c.position.z < min_z:
			min_z = c.position.z
	for c in _chunks:
		if c.position.z > 40.0:
			c.position.z = min_z - Runner_Escenario_3D.LARGO_CHUNK
			min_z = c.position.z


func _limpiar_mallas_dinamicas() -> void:
	for nodo in _nodos_obstaculos.values():
		if is_instance_valid(nodo):
			nodo.queue_free()
	_nodos_obstaculos.clear()
	for nodo in _nodos_monedas.values():
		if is_instance_valid(nodo):
			nodo.queue_free()
	_nodos_monedas.clear()
	for nodo in _nodos_powerups.values():
		if is_instance_valid(nodo):
			nodo.queue_free()
	_nodos_powerups.clear()


func _sincronizar_entidades() -> void:
	if _raiz_3d == null:
		return

	# Evitar que carteles de puentes y pórticos elevados detrás del corredor bloqueen o corten la cámara
	for c in _chunks:
		for nombre_alto in ["PuenteCartel", "portico_catenaria"]:
			var alto := c.get_node_or_null(nombre_alto) as Node3D
			if alto != null:
				alto.visible = (c.position.z + alto.position.z) < -0.8

	# 1. Obstáculos
	var ids_obs: Dictionary = {}
	for obs in simulacion.obstaculos:
		var id: int = int(obs["id"])
		ids_obs[id] = true
		var nodo: Node3D = _nodos_obstaculos.get(id, null)
		if nodo == null:
			var tipo: String = str(obs["tipo"])
			if tipo == "VALLA_BAJA":
				nodo = _escenario.crear_valla_baja()
			elif tipo == "ARCO_ALTO":
				nodo = _escenario.crear_arco_alto()
			elif tipo == "PASARELA_RAMPA":
				nodo = _escenario.crear_pasarela_rampa(obs)
			elif tipo == "CICLISTA":
				nodo = _escenario.crear_ciclista(obs)
			elif tipo == "TREN_MOVIL":
				nodo = _escenario.crear_tren_movil(obs)
			elif tipo == "TREN_LARGO" or tipo == "TREN_LARGO_RAMPA":
				nodo = _escenario.crear_tren_largo(obs)
			elif tipo == "TUNEL":
				nodo = _escenario.crear_tunel(obs)
			else:
				nodo = _escenario.crear_seto_alto(obs)
			_raiz_3d.add_child(nodo)
			_nodos_obstaculos[id] = nodo
		nodo.position = Vector3(Runner_Simulacion.carril_a_x(int(obs["carril"])), 0.0, float(obs["z"]))

	for id in _nodos_obstaculos.keys():
		if not ids_obs.has(id):
			var n: Node3D = _nodos_obstaculos[id]
			if is_instance_valid(n):
				n.queue_free()
			_nodos_obstaculos.erase(id)

	# 2. Monedas giratorias
	var ids_mon: Dictionary = {}
	for c in simulacion.monedas_entidades:
		var id: int = int(c["id"])
		ids_mon[id] = true
		var nodo: Node3D = _nodos_monedas.get(id, null)
		if nodo == null:
			nodo = _escenario.crear_moneda()
			_raiz_3d.add_child(nodo)
			_nodos_monedas[id] = nodo
		var bob: float = 0.0 if bool(c["magnetizada"]) else sin(_tiempo * 4.2 + float(c["fase"])) * 0.14
		nodo.position = Vector3(float(c["x"]), float(c["y"]) + bob, float(c["z"]))
		nodo.rotation.y = _tiempo * 3.4 + float(c["fase"])

	for id in _nodos_monedas.keys():
		if not ids_mon.has(id):
			var n: Node3D = _nodos_monedas[id]
			if is_instance_valid(n):
				n.queue_free()
			_nodos_monedas.erase(id)

	# 3. Power-ups 3D
	var ids_pu: Dictionary = {}
	for pu in simulacion.powerups_entidades:
		var id: int = int(pu["id"])
		ids_pu[id] = true
		var nodo: Node3D = _nodos_powerups.get(id, null)
		if nodo == null:
			nodo = _escenario.crear_powerup(str(pu["tipo"]))
			_raiz_3d.add_child(nodo)
			_nodos_powerups[id] = nodo
		var fase: float = float(pu["fase"])
		nodo.position = Vector3(
			Runner_Simulacion.carril_a_x(int(pu["carril"])),
			float(pu["y"]) + sin(_tiempo * 4.0 + fase) * 0.22,
			float(pu["z"])
		)
		nodo.rotation.y = _tiempo * 2.5 + fase

	for id in _nodos_powerups.keys():
		if not ids_pu.has(id):
			var n: Node3D = _nodos_powerups[id]
			if is_instance_valid(n):
				n.queue_free()
			_nodos_powerups.erase(id)


func _actualizar_camara(dt: float, inmediato: bool) -> void:
	if _camara == null:
		return

	var es_vertical: bool = _tamano_vista.y > _tamano_vista.x
	var alfa: float = 1.0 if inmediato else (1.0 - exp(-9.5 * maxf(dt, 0.016)))

	var jx: float = float(simulacion.jugador["x"])
	var jy: float = float(simulacion.jugador["y"])

	if _modo == "intro":
		_factor_tunel = 0.0
		var t: float = clampf(_intro_t / 1.15, 0.0, 1.0)
		var ease: float = 1.0 - pow(1.0 - t, 3.0)
		var destino_pos := Vector3(0.0, 4.55 if es_vertical else 4.35, 8.15 if es_vertical else 7.45)
		var destino_look := Vector3(0.0, 1.55, -15.0)
		_cam_pos = Vector3(0.0, 2.35, 4.25).lerp(destino_pos, ease)
		_cam_look = Vector3(0.0, 1.5, -7.0).lerp(destino_look, ease)
		_fov_actual = lerpf(58.0, 66.0 if es_vertical else 58.0, ease)
		if absf(_camara.fov - _fov_actual) > 0.04:
			_camara.fov = _fov_actual
		_camara.position = _cam_pos
		_camara.look_at(_cam_look, Vector3.UP)
		return

	if _modo == "menu":
		_factor_tunel = 0.0
		_factor_vuelo = 0.0
		_cam_roll = 0.0
		var tx: float = (1.35 if es_vertical else 1.55) + sin(_tiempo * 0.55) * 0.35
		var ty: float = (2.85 if es_vertical else 3.15) + cos(_tiempo * 0.45) * 0.10
		var tz: float = 5.4 if es_vertical else 5.8
		_cam_pos = _cam_pos.lerp(Vector3(tx, ty, tz), alfa)
		_cam_look = _cam_look.lerp(Vector3(0.0, 1.55, -14.0), alfa)
		var fov_obj: float = 64.0 if es_vertical else 56.0
		_fov_actual = lerpf(_fov_actual, fov_obj, alfa)
	else:
		var objetivo_tunel: float = 1.0 if bool(simulacion.jugador.get("tunel", false)) else 0.0
		var alfa_tunel: float = 1.0 if inmediato else (1.0 - exp(-4.5 * maxf(dt, 0.016)))
		_factor_tunel = lerpf(_factor_tunel, objetivo_tunel, alfa_tunel)

		var objetivo_vuelo: float = 1.0 if str(simulacion.jugador.get("estado", "")) == "VOLANDO" else 0.0
		var alfa_vuelo: float = 1.0 if inmediato else (1.0 - exp(-4.2 * maxf(dt, 0.016)))
		_factor_vuelo = lerpf(_factor_vuelo, objetivo_vuelo, alfa_vuelo)

		var base_y: float = 4.55 if es_vertical else 4.35
		var base_z: float = 8.15 if es_vertical else 7.45
		var ater_t: float = clampf(float(simulacion.jugador.get("aterrizaje_t", 0.0)) / 0.24, 0.0, 1.0)
		var dip_y: float = -0.05 * sin(ater_t * PI)

		var pos_suelo := Vector3(
			jx * 0.54,
			base_y + jy * 0.72 + dip_y - 1.45 * _factor_tunel,
			base_z + 0.35 * _factor_tunel
		)
		var look_suelo := Vector3(
			jx * 0.48,
			1.55 + jy * 0.58 + dip_y * 0.5 - 0.35 * _factor_tunel,
			-15.0
		)

		var pos_vuelo := Vector3(jx * 0.62 + 2.25, jy + 0.85, base_z - 0.20)
		var look_vuelo := Vector3(jx * 0.44 - 0.22, jy - 0.58, -18.0)

		var obj_pos: Vector3 = pos_suelo.lerp(pos_vuelo, _factor_vuelo)
		var obj_look: Vector3 = look_suelo.lerp(look_vuelo, _factor_vuelo)
		var alfa_x: float = 1.0 if inmediato else (1.0 - exp(-6.8 * maxf(dt, 0.016)))
		_cam_pos.x = lerpf(_cam_pos.x, obj_pos.x, alfa_x)
		_cam_pos.y = lerpf(_cam_pos.y, obj_pos.y, alfa)
		_cam_pos.z = lerpf(_cam_pos.z, obj_pos.z, alfa)
		_cam_look.x = lerpf(_cam_look.x, obj_look.x, alfa_x)
		_cam_look.y = lerpf(_cam_look.y, obj_look.y, alfa)
		_cam_look.z = lerpf(_cam_look.z, obj_look.z, alfa)

		var vel_t: float = simulacion.obtener_progreso_velocidad()
		var aire_fov: float = 1.2 if str(simulacion.jugador.get("estado", "")) in ["SALTANDO", "POGO"] else 0.0
		var base_fov: float = 66.0 if es_vertical else 58.0
		var fov_obj: float = base_fov + vel_t * 6.0 + aire_fov + (2.5 if float(simulacion.powerups["tabla"]) > 0.0 else 0.0) + 2.0 * _factor_tunel + 7.0 * _factor_vuelo
		var alfa_fov: float = 1.0 if inmediato else (1.0 - exp(-5.0 * maxf(dt, 0.016)))
		_fov_actual = lerpf(_fov_actual, fov_obj, alfa_fov)

		# Inclinación mínima anti-mareo: solo un leve matiz lateral sin voltear el horizonte
		var roll_obj: float = clampf(-float(simulacion.jugador.get("vx", 0.0)) * 0.00055, -0.010, 0.010)
		_cam_roll = roll_obj if inmediato else lerpf(_cam_roll, roll_obj, 1.0 - exp(-7.5 * maxf(dt, 0.016)))

	if absf(_camara.fov - _fov_actual) > 0.04:
		_camara.fov = _fov_actual

	var shake := Vector3.ZERO
	if _shake_trauma > 0.0:
		var amt: float = _shake_trauma * _shake_trauma * 0.42
		shake.x = _rng.randf_range(-amt, amt)
		shake.y = _rng.randf_range(-amt, amt)

	_camara.position = _cam_pos + shake
	_camara.look_at(_cam_look, Vector3.UP)
	if absf(_cam_roll) > 0.0002:
		_camara.rotate_z(_cam_roll)


func _actualizar_guardia(_dt: float) -> void:
	if _guardia_3d == null:
		return
	if _modo == "menu" or _modo == "detenido":
		_guardia_3d.visible = false
		return
	var estado: String = str(simulacion.jugador.get("estado", "CORRIENDO"))
	var atrapando: bool = estado == "CAIDO" or estado == "CHOCADO"
	var corriendo: bool = _modo == "jugando" or _modo == "listo"
	var suelo_y: float = float(simulacion.jugador.get("suelo_y", 0.0))
	var jx: float = float(simulacion.jugador.get("x", 0.0))
	var offset_guardia: float = -1.15 if _modo == "intro" else 0.0
	_guardia_3d.actualizar(simulacion.guardia_distancia, _tiempo, jx + offset_guardia, suelo_y, corriendo, atrapando)


func _emitir_particulas(origen: Vector3, cantidad: int, color: Color, rapidez: float) -> void:
	if _particulas.is_empty():
		return
	for _i in range(cantidad):
		var slot: Dictionary = _particulas[_cursor_particula]
		_cursor_particula = (_cursor_particula + 1) % MAX_PARTICULAS
		slot["activa"] = true
		slot["pos"] = origen + Vector3(
			_rng.randf_range(-0.22, 0.22),
			_rng.randf_range(-0.18, 0.18),
			_rng.randf_range(-0.22, 0.22)
		)
		var theta: float = _rng.randf() * TAU
		var up: float = _rng.randf_range(0.25, 1.15)
		var sp: float = rapidez * _rng.randf_range(0.45, 1.2)
		slot["vel"] = Vector3(cos(theta) * sp, up * sp, sin(theta) * sp * 0.7)
		var vida_max: float = _rng.randf_range(0.26, 0.54)
		slot["vida_max"] = vida_max
		slot["vida"] = vida_max
		slot["tam"] = _rng.randf_range(0.65, 1.45)
		slot["color"] = color


func _actualizar_particulas(dt: float) -> void:
	if _mm_particulas == null:
		return
	var oculto := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0.0, -100.0, 0.0))
	for i in range(_particulas.size()):
		var p: Dictionary = _particulas[i]
		if not bool(p["activa"]):
			continue
		var vida: float = float(p["vida"]) - dt
		p["vida"] = vida
		if vida <= 0.0:
			p["activa"] = false
			_mm_particulas.set_instance_transform(i, oculto)
			continue
		var vel: Vector3 = p["vel"]
		vel.y -= 16.0 * dt
		p["vel"] = vel
		var pos: Vector3 = p["pos"] + vel * dt
		p["pos"] = pos
		var t: float = vida / maxf(0.01, float(p["vida_max"]))
		var sc: float = float(p["tam"]) * t
		var basis := Basis.from_euler(Vector3(vida * 8.0, vida * 6.0, 0.0)).scaled(Vector3(sc, sc, sc))
		_mm_particulas.set_instance_transform(i, Transform3D(basis, pos))
		_mm_particulas.set_instance_color(i, p["color"])


func _actualizar_curva_horizonte() -> void:
	if _escenario == null:
		return
	# Curvatura icónica estilo Subway Surfers (suave caída en el horizonte + leve giro orgánico)
	if _modo == "menu":
		_curva_x_actual = 0.00048
		_curva_y_actual = 0.00175
	else:
		_curva_x_actual = sin(simulacion.distancia * 0.011 + 0.5) * 0.00070
		_curva_y_actual = 0.00185
	_escenario.actualizar_curva_y_clima(_curva_x_actual, _curva_y_actual, _factor_noche_actual)


func _actualizar_ambiente_horario(forzar: bool) -> void:
	var minuto: int = 900
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol != null and arbol.root != null:
		var vd := arbol.root.get_node_or_null("Variables_Dinamicas")
		if vd != null and "Minute_Minute" in vd:
			minuto = int(vd.get("Minute_Minute"))

	var tramo: int = minuto / 15
	if not forzar and tramo == _ultimo_minuto_clima:
		return
	_ultimo_minuto_clima = tramo

	var hora: float = float(posmod(minuto, 1440)) / 60.0
	var factor_noche: float = 0.0
	var factor_ocaso: float = 0.0
	if hora >= 21.0 or hora < 5.5:
		factor_noche = 1.0
	elif hora >= 18.5 and hora < 21.0:
		var t: float = (hora - 18.5) / 2.5
		factor_ocaso = sin(t * PI)
		factor_noche = smoothstep(0.35, 1.0, t)
	elif hora >= 5.5 and hora < 7.5:
		var t: float = (hora - 5.5) / 2.0
		factor_ocaso = sin(t * PI)
		factor_noche = 1.0 - smoothstep(0.0, 0.65, t)

	_factor_noche_actual = factor_noche

	# Paleta cielo Subway Surfers: azul mediterráneo intenso / atardecer dorado / noche índigo estrellada
	var cenit := Color("#0d4ec2").lerp(Color("#060c22"), factor_noche).lerp(Color("#3a3a82"), factor_ocaso * 0.55)
	var medio := Color("#1f80eb").lerp(Color("#11214a"), factor_noche).lerp(Color("#e86f7c"), factor_ocaso * 0.58)
	var horiz := Color("#74c9ff").lerp(Color("#1e3666"), factor_noche).lerp(Color("#ffc078"), factor_ocaso * 0.78)
	var nube_luz := Color("#ffffff").lerp(Color("#4c6496"), factor_noche).lerp(Color("#ffd9a8"), factor_ocaso * 0.72)
	var nube_somb := Color("#88bcf0").lerp(Color("#1d2e56"), factor_noche).lerp(Color("#b67fa8"), factor_ocaso * 0.65)
	var niebla := Color("#7cc7f8").lerp(Color("#16284d"), factor_noche).lerp(Color("#f7b282"), factor_ocaso * 0.65)
	var sol_col := Color("#fff0c8").lerp(Color("#7aa4e8"), factor_noche).lerp(Color("#ffc880"), factor_ocaso * 0.75)

	if _sky_mat != null:
		_sky_mat.set_shader_parameter("cielo_cenit", cenit)
		_sky_mat.set_shader_parameter("cielo_medio", medio)
		_sky_mat.set_shader_parameter("cielo_horizonte", horiz)
		_sky_mat.set_shader_parameter("suelo_color", horiz.lerp(Color("#6b7a60"), 0.35))
		_sky_mat.set_shader_parameter("nube_luz", nube_luz)
		_sky_mat.set_shader_parameter("nube_sombra", nube_somb)
		_sky_mat.set_shader_parameter("sol_color", sol_col)
		_sky_mat.set_shader_parameter("noche_factor", factor_noche)

	_env_res.fog_light_color = niebla
	_env_res.ambient_light_color = Color("#d8e4f5").lerp(Color("#2a3d72"), factor_noche)
	_env_res.ambient_light_sky_contribution = lerpf(0.42, 0.55, factor_noche)
	_env_res.ambient_light_energy = lerpf(0.32, 0.11, factor_noche)
	_env_res.tonemap_exposure = lerpf(1.06, 0.86, factor_noche)
	_sol.light_color = sol_col
	_sol.light_energy = lerpf(1.28, 0.28, factor_noche)
	_luz_borde.light_color = Color("#8ecaff").lerp(Color("#4c64b0"), factor_noche)
	_luz_borde.light_energy = lerpf(0.28, 0.14, factor_noche)
	_actualizar_curva_horizonte()
