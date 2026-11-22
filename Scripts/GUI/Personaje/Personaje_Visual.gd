class_name Personaje_Visual
extends Control
## Renderizador modular y articulado del personaje en estilo cómic/Sims.
## Usa curvas Catmull-Rom / Bézier suaves, jerarquía de grosores de tinta (#111827),
## cel-shading cálido y soporte completo de rasgos faciales, peinados, complexión,
## prendas superiores/inferiores, calzado y accesorios.

const TINTA := Color("#111827")

var apariencia: Dictionary = Apariencia_Personaje.por_defecto():
	set(val):
		apariencia = Apariencia_Personaje.normalizar(val)
		queue_redraw()

## Margen extra (en unidades de dibujo) alrededor del encuadre del retrato.
var margen_retrato: float = 0.0:
	set(val):
		margen_retrato = maxf(0.0, val)
		queue_redraw()

## "retrato", "retrato_cercano", "busto", "cuerpo_completo"
var modo: String = "busto":
	set(val):
		modo = val
		queue_redraw()

## "idle", "celebrar", "sorpresa", "volando", "correr", "dormir", "comer",
## "duchar", "estudiar", "tv", "manualidades", "trabajar", "cocinar", "fiesta", "futbol"
var pose: String = "idle":
	set(val):
		pose = val
		queue_redraw()

## "feliz", "sonrisa", "sorpresa", "panico", "neutral", "concentrado", "cansado",
## "dormido", "roncando", "masticando", "soplando", "satisfecho", "cantando",
## "feliz_cerrado", "reir", "asustado_frio", "bostezo"
var expresion: String = "feliz":
	set(val):
		expresion = val
		queue_redraw()

## "ninguno", "gorro_fiesta", "gorro_volando"
var accesorio_cabeza: String = "ninguno":
	set(val):
		accesorio_cabeza = val
		queue_redraw()

## "ninguno", "tarta_18", "botella", "tenedor", "vaso", "servilleta", "cuchillo",
## "esponja", "lapiz", "mando", "pincel", "taza", "movil", "espatula"
var prop_mano: String = "ninguno":
	set(val):
		prop_mano = val
		queue_redraw()

var prop_mano_izq: String = "ninguno":
	set(val):
		prop_mano_izq = val
		queue_redraw()

var variacion: String = "":
	set(val):
		variacion = val
		queue_redraw()

var fase_variacion: float = 0.0

## "completo", "sin_brazos_delanteros", "solo_brazos_delanteros"
var modo_capa: String = "completo":
	set(val):
		modo_capa = val
		queue_redraw()

var fuente_overlay: Personaje_Visual = null

var ciclo_comer: float = -1.0
var color_bocado: Color = Color("#f59e0b")
var color_bebida: Color = Color("#fb923c")
var estilo_vaso: String = "normal"
var estilo_tenedor: String = "metal"
var mancha_salsa: bool = false

var en_ducha: bool = false:
	set(val):
		en_ducha = val
		queue_redraw()

var animar_idle: bool = true:
	set(val):
		animar_idle = val
		# El nodo sigue procesando aunque no anime: así detecta el cambio de edad
		# y se vuelve a pintar (avatares y retratos estáticos también envejecen).
		set_process(true)
		queue_redraw()

## Edad del personaje en años. `-1` (por defecto) toma automáticamente la edad
## real de la partida con `Variables_Estaticas.Calcular_Edad()`, de modo que el
## retrato envejece solo con el paso de las semanas. Se puede forzar una edad
## concreta (creador de personaje, capturas o pruebas).
var edad: int = -1:
	set(val):
		edad = val
		queue_redraw()

var _edad_pintada: int = -1
## Factores de envejecimiento del último dibujo (los consume el pelo y las marcas).
var _rasgos_edad: Dictionary = {}

var dibujar_fondo_sunburst: bool = false:
	set(val):
		dibujar_fondo_sunburst = val
		queue_redraw()

var color_fondo_base: Color = Color("#bae6fd"):
	set(val):
		color_fondo_base = val
		queue_redraw()

var color_fondo_rayo: Color = Color("#7dd3fc"):
	set(val):
		color_fondo_rayo = val
		queue_redraw()

var _t: float = 0.0
var _fase_parpadeo: float = 0.0


func _init(datos: Dictionary = {}, modo_inicial: String = "busto") -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	apariencia = Apariencia_Personaje.normalizar(datos)
	modo = modo_inicial
	_fase_parpadeo = randf_range(0.0, 3.0)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if not visible:
		return
	if animar_idle:
		_t += delta
		queue_redraw()
		return
	# Retratos estáticos: repintar en cuanto cambie la edad del personaje.
	if obtener_edad() != _edad_pintada:
		queue_redraw()


## Edad efectiva del retrato. Sin valor forzado usa el reloj de la partida.
func obtener_edad() -> int:
	# Las capas de brazos delanteros copian la edad del personaje base.
	if modo_capa == "solo_brazos_delanteros" and fuente_overlay != null:
		return fuente_overlay.obtener_edad()
	if edad >= 0:
		return edad
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol != null and arbol.root != null:
		var reloj := arbol.root.get_node_or_null("Variables_Estaticas")
		if reloj != null and reloj.has_method("Calcular_Edad"):
			return int(reloj.call("Calcular_Edad"))
	return Envejecimiento_Personaje.EDAD_MIN


## Factores de envejecimiento (0..1) que consumen las rutinas de dibujo.
func obtener_rasgos_edad() -> Dictionary:
	return Envejecimiento_Personaje.rasgos(obtener_edad())


func establecer_actividad(nombre_actividad: String) -> void:
	pose = Apariencia_Personaje.pose_para_actividad(nombre_actividad)
	en_ducha = (pose == "duchar")
	variacion = ""
	prop_mano = "ninguno"
	prop_mano_izq = "ninguno"
	mancha_salsa = false
	match pose:
		"correr", "futbol":
			expresion = "concentrado"
		"dormir":
			expresion = "dormido"
		"comer":
			expresion = "masticando"
			prop_mano = "tenedor"
			prop_mano_izq = "cuchillo" if estilo_tenedor == "metal" else "ninguno"
		"duchar":
			expresion = "feliz"
			prop_mano = "esponja"
		"estudiar":
			expresion = "concentrado"
			prop_mano = "lapiz"
		"tv":
			expresion = "sonrisa"
		"manualidades":
			expresion = "concentrado"
			prop_mano = "pincel"
		"cocinar":
			expresion = "feliz"
			prop_mano = "espatula"
		"fiesta":
			expresion = "feliz"
		"trabajar":
			expresion = "concentrado"
		_:
			expresion = "feliz"


func obtener_ciclo_comer(t: float = -1.0) -> float:
	if ciclo_comer >= 0.0:
		return clampf(ciclo_comer, 0.0, 1.0)
	var tiempo := _t if t < 0.0 else t
	return fmod(maxf(0.0, tiempo), 3.4) / 3.4


func esta_sosteniendo_vaso() -> bool:
	return pose == "comer" and variacion == "beber" and fase_variacion >= 0.16 and fase_variacion <= 0.88


func esta_sosteniendo_servilleta() -> bool:
	return pose == "comer" and variacion == "limpiar_boca" and fase_variacion >= 0.16 and fase_variacion <= 0.88


func esta_sosteniendo_tenedor() -> bool:
	return pose == "comer" and (variacion == "" or variacion == "soplar")


func esta_sosteniendo_cuchillo() -> bool:
	return pose == "comer" and variacion == "" and estilo_tenedor == "metal"


func obtener_punto_local_a_escena(punto_local: Vector2) -> Vector2:
	var es_mujer := Apariencia_Personaje.es_mujer(apariencia)
	var rig := obtener_rig_pose(pose, _t, es_mujer, apariencia)
	var tr := _calcular_transform_camara()
	var esc: float = tr["scale"]
	var centro: Vector2 = tr["origin"]
	var rig_off: Vector2 = rig["offset"]
	var rig_rot: float = float(rig["root_rot"])
	var origen: Vector2 = centro + rig_off * esc
	return position + origen + _rotar(punto_local, rig_rot) * esc


func obtener_punta_tenedor_escena() -> Vector2:
	var es_mujer := Apariencia_Personaje.es_mujer(apariencia)
	var rig := obtener_rig_pose(pose, _t, es_mujer, apariencia)
	var mano_r: Vector2 = rig["arm_r"][2]
	var rot_p: float = float(rig.get("prop_r_rot", -0.85))
	var punta_local := mano_r + _rotar(Vector2(0.0, -22.0), rot_p)
	return obtener_punto_local_a_escena(punta_local)


# ---------------------------------------------------------------- métricas de cuerpo

func _metricas_cuerpo(es_mujer: bool, ap: Dictionary) -> Dictionary:
	var comp := str(ap.get("complexion", "normal"))
	var sh_x := 27.5 if es_mujer else 32.5
	var waist_x := 21.5 if es_mujer else 27.5
	var hip_x := 28.5 if es_mujer else 29.5
	var nw := 8.2 if es_mujer else 9.6
	var arm_scale := 0.92 if es_mujer else 1.0
	var leg_scale := 0.96 if es_mujer else 1.0
	var jaw_w := 1.0

	match comp:
		"delgado":
			sh_x -= 3.0
			waist_x -= 3.0
			hip_x -= 2.5
			nw -= 0.9
			arm_scale *= 0.86
			leg_scale *= 0.88
			jaw_w = 0.96
		"atletico":
			sh_x += 2.5 if es_mujer else 4.5
			waist_x -= 1.0
			hip_x += 0.5
			nw += 0.7
			arm_scale *= 1.12
			leg_scale *= 1.08
			jaw_w = 1.01
		"robusto":
			sh_x += 4.0
			waist_x += 7.5
			hip_x += 6.0
			nw += 1.5
			arm_scale *= 1.22
			leg_scale *= 1.20
			jaw_w = 1.07

	var hip_leg_x := hip_x * 0.50
	return {
		"sh_x": sh_x,
		"waist_x": waist_x,
		"hip_x": hip_x,
		"hip_leg_x": hip_leg_x,
		"nw": nw,
		"arm_scale": arm_scale,
		"leg_scale": leg_scale,
		"jaw_w": jaw_w,
	}


# ---------------------------------------------------------------- rig articulado

func obtener_rig_pose(nombre_pose: String, t: float, es_mujer: bool, ap_datos: Dictionary = {},
		ignorar_variacion: bool = false) -> Dictionary:
	var ap_uso := apariencia if ap_datos.is_empty() else ap_datos
	# La versión "base" del rig se usa para fundir las micro-acciones con la pose
	# de reposo y evitar saltos bruscos de brazos y cabeza.
	var variacion: String = "" if ignorar_variacion else self.variacion
	var fase_variacion: float = 0.0 if ignorar_variacion else self.fase_variacion
	var met := _metricas_cuerpo(es_mujer, ap_uso)
	var sh_x: float = met["sh_x"]
	var hip_x: float = met["hip_leg_x"]
	# Postura con la edad (0..1): amortigua el balanceo y, más abajo, hunde los
	# hombros y la cabeza. Con 18 años vale 0 y el rig es exactamente el original.
	var postura := Envejecimiento_Personaje.factor(obtener_edad(), "postura")
	var bob := sin(t * (2.4 - 0.30 * postura)) * 1.4 * (1.0 - 0.38 * postura) if animar_idle else 0.0

	var arm_sh_x := sh_x - 3.2
	var rig := {
		"offset": Vector2(0.0, bob),
		"root_rot": 0.0,
		"head_offset": Vector2(0.0, bob * 0.35),
		"head_rot": 0.0,
		"arm_l": [Vector2(-arm_sh_x, 61.0), Vector2(-sh_x - 9.0, 92.0), Vector2(-sh_x - 5.0, 123.0)],
		"arm_r": [Vector2(arm_sh_x, 61.0), Vector2(sh_x + 9.0, 92.0), Vector2(sh_x + 5.0, 123.0)],
		"hand_l_tipo": "abierta",
		"hand_r_tipo": "abierta",
		"leg_l": [Vector2(-hip_x, 124.0), Vector2(-hip_x - 1.0, 165.0), Vector2(-hip_x - 2.0, 203.0)],
		"leg_r": [Vector2(hip_x, 124.0), Vector2(hip_x + 1.0, 165.0), Vector2(hip_x + 2.0, 203.0)],
		"mirada": Vector2.ZERO,
		"brazos_delante": false,
	}

	match nombre_pose:
		"celebrar":
			var b := sin(t * 3.2) * 1.5 if animar_idle else 0.0
			rig["offset"] = Vector2(0.0, b)
			rig["head_rot"] = deg_to_rad(-3.0)
			rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 24.0, 75.0), Vector2(-sh_x - 22.0, 34.0)]
			rig["hand_l_tipo"] = "puno"
			rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 22.0, 92.0), Vector2(sh_x + 52.0, 86.0)]
			rig["hand_r_tipo"] = "sostener"
			rig["mirada"] = Vector2(1.2, -0.4)
		"sorpresa":
			var temblor := sin(t * 24.0) * 0.8 if animar_idle else 0.0
			rig["offset"] = Vector2(temblor, 2.0)
			rig["head_rot"] = deg_to_rad(1.5)
			rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 17.0, 78.0), Vector2(-30.0, 14.0)]
			rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 17.0, 78.0), Vector2(30.0, 14.0)]
			rig["hand_l_tipo"] = "mejilla_l"
			rig["hand_r_tipo"] = "mejilla_r"
			rig["brazos_delante"] = true
		"volando":
			var osc := sin(t * 9.5) * 2.0 if animar_idle else 0.0
			rig["offset"] = Vector2(0.0, osc)
			rig["root_rot"] = deg_to_rad(25.0)
			rig["head_rot"] = deg_to_rad(-16.0)
			rig["arm_l"] = [Vector2(-sh_x, 55.0), Vector2(-sh_x - 28.0, 33.0), Vector2(-sh_x - 50.0, 43.0)]
			rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 24.0, 72.0), Vector2(sh_x + 42.0, 92.0)]
			rig["leg_l"] = [Vector2(-hip_x, 122.0), Vector2(-48.0, 142.0), Vector2(-82.0, 148.0)]
			rig["leg_r"] = [Vector2(hip_x, 122.0), Vector2(4.0, 162.0), Vector2(-24.0, 182.0)]
			rig["mirada"] = Vector2(-1.8, 1.0)
		"correr":
			var vel: float = 13.5 if variacion == "sprint" else (6.8 if variacion in ["beber_agua", "secar_sudor"] else 9.0)
			var fase_carrera: float = t * vel
			var cyc: float = sin(fase_carrera)
			var cyc2: float = cos(fase_carrera)
			var salto_y: float = 0.0
			if variacion == "salto":
				salto_y = -sin(clampf(fase_variacion, 0.0, 1.0) * PI) * 30.0
			rig["offset"] = Vector2(cyc2 * 1.2, -absf(cyc) * (7.0 if variacion == "sprint" else 5.0) + salto_y)
			rig["root_rot"] = deg_to_rad((16.0 if variacion == "sprint" else 9.0) + absf(cyc) * 1.5)
			rig["head_rot"] = deg_to_rad(-5.0 - absf(cyc) * 2.0)
			rig["head_offset"] = Vector2(-cyc2 * 0.8, sin(fase_carrera * 2.0) * 1.2)
			rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 9.0 + cyc * 15.0, 82.0 - absf(cyc) * 4.0), Vector2(-sh_x + cyc * 27.0, 63.0 + maxf(0.0, cyc) * 9.0)]
			rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 9.0 - cyc * 15.0, 82.0 - absf(cyc) * 4.0), Vector2(sh_x - cyc * 27.0, 63.0 + maxf(0.0, -cyc) * 9.0)]
			rig["leg_l"] = [Vector2(-hip_x, 124.0), Vector2(-hip_x + cyc * 22.0, 162.0 - maxf(0.0, cyc) * 7.0), Vector2(-hip_x + cyc * 34.0, 200.0 - maxf(0.0, cyc) * 20.0)]
			rig["leg_r"] = [Vector2(hip_x, 124.0), Vector2(hip_x - cyc * 22.0, 162.0 - maxf(0.0, -cyc) * 7.0), Vector2(hip_x - cyc * 34.0, 200.0 - maxf(0.0, -cyc) * 20.0)]
			rig["mirada"] = Vector2(1.4, -0.3)
			if variacion == "salto":
				var medio := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["leg_l"][1] = Vector2(-hip_x + 12.0 * medio, 156.0 - medio * 12.0)
				rig["leg_r"][1] = Vector2(hip_x + 8.0 * medio, 158.0 - medio * 10.0)
			elif variacion == "secar_sudor":
				var sw := sin(t * 7.5) * 9.0
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 19.0, 44.0), Vector2(6.0 + sw, -20.0)]
				rig["brazos_delante"] = true
			elif variacion == "beber_agua":
				rig["head_rot"] = deg_to_rad(-11.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 17.0, 65.0), Vector2(16.0, 22.0)]
				rig["brazos_delante"] = true
			elif variacion == "senalar":
				var se := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["head_rot"] = deg_to_rad(-8.0)
				rig["mirada"] = Vector2(2.0, -0.6)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 24.0, 52.0), Vector2(sh_x + 48.0 + se * 14.0, 35.0)]
				rig["brazos_delante"] = true
		"dormir":
			var resp := sin(t * 1.9) * 2.2
			var cabeceo := sin(t * 1.3) * 1.3
			var rot_cabeza := deg_to_rad(-9.0 + cabeceo)
			var off_x := sin(t * 0.33) * 0.9
			if variacion == "darse_vuelta":
				var k := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rot_cabeza = deg_to_rad(16.0 * k)
				off_x = k * 4.0
			elif variacion == "roncar":
				resp = sin(t * 3.8) * 3.4
				rot_cabeza = deg_to_rad(-3.0 + sin(t * 3.8) * 4.0)
			elif variacion == "sonar":
				rot_cabeza = deg_to_rad(-6.0 + sin(t * 0.9) * 3.0)
			rig["offset"] = Vector2(off_x, resp)
			rig["head_offset"] = Vector2(0.0, cabeceo * 0.5 + resp * 0.15)
			rig["head_rot"] = rot_cabeza
			rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 13.0, 81.0), Vector2(-21.0, 56.0)]
			rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 13.0, 81.0), Vector2(21.0, 56.0)]
			if variacion == "estirar_brazo":
				var est := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 22.0, 26.0 - est * 18.0), Vector2(-sh_x - 13.0, -14.0 - est * 24.0)]
			elif variacion == "abrazar_almohada":
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 20.0, 76.0), Vector2(-12.0, 64.0)]
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 20.0, 76.0), Vector2(12.0, 64.0)]
				rig["brazos_delante"] = true
				rig["head_rot"] = deg_to_rad(-12.0 + sin(t * 1.2) * 2.0)
		"comer":
			_aplicar_rig_comer(rig, sh_x, t, variacion, fase_variacion)
		"duchar":
			var frote := sin(t * 6.0)
			var frote2 := sin(t * 6.0 + 1.2)
			rig["offset"] = Vector2(sin(t * 4.0) * 1.2, sin(t * 3.5) * 1.8)
			rig["head_offset"] = Vector2(0.0, sin(t * 2.2) * 0.8)
			rig["head_rot"] = deg_to_rad(frote * 4.0)
			rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 15.0, 74.0), Vector2(-22.0 + frote * 5.0, 56.0)]
			rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 17.0, 48.0), Vector2(14.0 - frote * 9.0, -28.0)]
			rig["brazos_delante"] = true
			rig["mirada"] = Vector2(frote2 * 0.4, 0.3)
			if variacion == "cantar":
				rig["offset"] = Vector2(sin(t * 4.0) * 2.0, -absf(sin(t * 5.0)) * 3.0 + sin(t * 2.5) * 1.0)
				rig["head_rot"] = deg_to_rad(sin(t * 5.0) * 10.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 17.0, 67.0), Vector2(16.0, 26.0)]
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 22.0, 56.0), Vector2(-sh_x - 30.0, 26.0)]
			elif variacion == "espuma_pelo":
				var sf := sin(t * 11.0) * 8.0
				rig["head_rot"] = deg_to_rad(sin(t * 11.0) * 5.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 17.0, 34.0), Vector2(-15.0 + sf, -34.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 17.0, 34.0), Vector2(15.0 - sf, -34.0)]
			elif variacion == "agua_fria":
				rig["offset"] = Vector2(sin(t * 34.0) * 3.2, -3.0)
				rig["head_rot"] = deg_to_rad(sin(t * 30.0) * 2.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 8.0, 77.0), Vector2(10.0, 70.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 8.0, 77.0), Vector2(-10.0, 70.0)]
			elif variacion == "burbuja_gigante":
				var bu := sin(t * 2.0) * 2.0
				rig["head_rot"] = deg_to_rad(-3.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 20.0, 62.0), Vector2(-18.0, 34.0 + bu)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 62.0), Vector2(18.0, 34.0 + bu)]
		"estudiar":
			var scribble := sin(t * 10.0) * 5.0
			var resp := sin(t * 2.0) * 0.9
			rig["offset"] = Vector2(sin(t * 0.46) * 0.8, 2.0 + resp)
			rig["head_rot"] = deg_to_rad(5.0 + sin(t * 0.8) * 1.6)
			rig["head_offset"] = Vector2(0.0, sin(t * 1.1) * 0.5)
			rig["mirada"] = Vector2(sin(t * 0.35) * 0.5, 1.8)
			rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 9.0, 87.0), Vector2(-16.0, 96.0)]
			rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 11.0, 87.0), Vector2(14.0 + scribble, 94.0)]
			rig["brazos_delante"] = true
			if variacion == "bombilla":
				rig["head_rot"] = deg_to_rad(-6.0)
				rig["mirada"] = Vector2(0.0, -0.8)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 48.0), Vector2(sh_x + 16.0, 12.0)]
			elif variacion == "pensar":
				rig["head_rot"] = deg_to_rad(-8.0)
				rig["mirada"] = Vector2(1.8, -1.4)
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 13.0, 72.0), Vector2(11.0, 34.0)]
			elif variacion == "pasar_pagina":
				var pg := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 8.0, 82.0), Vector2(-12.0 + pg * 28.0, 92.0 - pg * 18.0)]
			elif variacion == "bostezo":
				rig["head_rot"] = deg_to_rad(-7.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 22.0, 38.0), Vector2(-sh_x - 16.0, 4.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 22.0, 38.0), Vector2(sh_x + 16.0, 4.0)]
			elif variacion == "subrayar":
				var sub := (sin(t * 3.0) + 1.0) * 0.5
				rig["head_rot"] = deg_to_rad(7.0)
				rig["mirada"] = Vector2(0.0, 1.9)
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 9.0, 84.0), Vector2(-2.0 + sub * 34.0, 92.0)]
		"tv":
			var resp := sin(t * 2.0) * 1.2
			rig["offset"] = Vector2(sin(t * 0.7) * 0.8, resp)
			rig["head_rot"] = deg_to_rad(-2.0 + sin(t * 0.5) * 1.5)
			rig["head_offset"] = Vector2(0.0, sin(t * 1.3) * 0.5)
			rig["mirada"] = Vector2(1.0, 0.4)
			rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 13.0, 85.0), Vector2(-23.0, 96.0)]
			rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 13.0, 85.0), Vector2(23.0, 96.0)]
			rig["brazos_delante"] = true
			if variacion == "reir":
				rig["offset"] = Vector2(sin(t * 16.0) * 1.4, sin(t * 16.0) * 3.2)
				rig["head_rot"] = deg_to_rad(-7.0 + sin(t * 12.0) * 5.0)
			elif variacion == "palomitas":
				var pc := (sin(t * 4.2) + 1.0) * 0.5
				rig["head_rot"] = deg_to_rad(-3.0 - pc * 4.0)
				rig["mirada"] = Vector2(0.0, -0.6)
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 17.0, 74.0), Vector2(15.0 + (1.0 - pc) * 10.0, 78.0 - pc * 44.0)]
			elif variacion == "cambiar_canal":
				var apunta := 0.5 + sin(t * 2.0) * 0.5
				rig["head_rot"] = deg_to_rad(-2.0)
				rig["mirada"] = Vector2(1.7, 0.2)
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 22.0, 76.0), Vector2(sh_x + 40.0 + apunta * 4.0, 64.0)]
			elif variacion == "sorpresa_tv":
				var so := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -4.0 - so * 5.0)
				rig["head_rot"] = deg_to_rad(-8.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 20.0, 44.0), Vector2(-sh_x - 14.0, 8.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 44.0), Vector2(sh_x + 14.0, 8.0)]
			elif variacion == "bostezo_tv":
				var bt := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -bt * 3.0)
				rig["head_rot"] = deg_to_rad(-6.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 24.0, 38.0), Vector2(-sh_x - 18.0, 2.0 + bt * 4.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 24.0, 38.0), Vector2(sh_x + 18.0, 2.0 + bt * 4.0)]
		"manualidades":
			var trazo := sin(t * 6.5) * 10.0
			rig["offset"] = Vector2(sin(t * 0.8) * 0.8, sin(t * 2.5) * 1.3)
			rig["head_rot"] = deg_to_rad(3.0 + trazo * 0.22)
			rig["head_offset"] = Vector2(0.0, cos(t * 6.5) * 0.5)
			rig["mirada"] = Vector2(0.9, 1.3)
			rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 13.0, 84.0), Vector2(-20.0, 92.0)]
			rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 68.0), Vector2(25.0 + trazo, 52.0 + cos(t * 6.5) * 7.0)]
			rig["brazos_delante"] = true
			if variacion == "pincelada_rapida":
				var tr2 := sin(t * 15.0) * 14.0
				rig["offset"] = Vector2(sin(t * 1.2) * 1.4, sin(t * 7.5) * 1.8)
				rig["head_rot"] = deg_to_rad(tr2 * 0.18)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 22.0, 62.0), Vector2(23.0 + tr2, 46.0 + cos(t * 15.0) * 10.0)]
			elif variacion == "admirar":
				var ad := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["head_rot"] = deg_to_rad(-9.0)
				rig["mirada"] = Vector2(-0.5, 0.8)
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 13.0, 74.0), Vector2(12.0, 34.0)]
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 14.0, 72.0), Vector2(-10.0, 40.0 - ad * 4.0)]
				rig["hand_l_tipo"] = "mejilla_l"
				rig["hand_r_tipo"] = "mejilla_r"
			elif variacion == "soplar_pintura":
				var so := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(so * 3.0, so * 1.0)
				rig["head_rot"] = deg_to_rad(6.0)
				rig["mirada"] = Vector2(1.4, 1.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 18.0, 65.0), Vector2(25.0, 52.0)]
				rig["brazos_delante"] = true
		"cocinar":
			var rem := sin(t * 7.5) * 10.0
			var sal := cos(t * 7.5) * 4.0
			rig["offset"] = Vector2(sin(t * 0.7) * 0.7, sin(t * 3.0) * 1.3)
			rig["head_rot"] = deg_to_rad(3.0 + sin(t * 1.2) * 1.2)
			rig["head_offset"] = Vector2(0.0, sin(t * 1.6) * 0.4)
			rig["mirada"] = Vector2(0.5, 1.5)
			rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 14.0, 82.0), Vector2(-20.0, 92.0)]
			rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 18.0, 76.0), Vector2(12.0 + rem, 82.0 + sal)]
			rig["brazos_delante"] = true
			if variacion == "probar":
				rig["head_rot"] = deg_to_rad(-7.0)
				rig["mirada"] = Vector2(0.0, 1.2)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 16.0, 68.0), Vector2(14.0, 30.0)]
			elif variacion == "saltear":
				var salt := sin(t * 13.0) * 11.0
				rig["offset"] = Vector2(0.0, sin(t * 6.5) * 1.4)
				rig["head_rot"] = deg_to_rad(4.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 16.0, 78.0), Vector2(18.0, 76.0 - absf(salt))]
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 14.0, 82.0), Vector2(-24.0, 88.0)]
			elif variacion == "oler_guiso":
				var ol := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, ol * 2.4)
				rig["head_rot"] = deg_to_rad(8.0 + ol * 3.0)
				rig["head_offset"] = Vector2(0.0, ol * 1.4)
				rig["mirada"] = Vector2(0.0, 1.8)
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 12.0, 80.0), Vector2(-24.0, 86.0)]
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 12.0, 80.0), Vector2(24.0, 86.0)]
		"fiesta":
			var groove := sin(t * 7.5)
			var groove2 := sin(t * 7.5 + 1.6)
			var bounce := absf(sin(t * 7.5)) * 5.0
			rig["offset"] = Vector2(groove * 4.5, -bounce)
			rig["root_rot"] = deg_to_rad(groove * 5.0)
			rig["head_rot"] = deg_to_rad(-groove * 7.0)
			rig["head_offset"] = Vector2(groove2 * 1.2, 0.0)
			rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 20.0, 48.0 + groove * 12.0), Vector2(-sh_x - 16.0, 14.0 - groove * 14.0)]
			rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 48.0 - groove * 12.0), Vector2(sh_x + 16.0, 14.0 + groove * 14.0)]
			rig["leg_l"] = [Vector2(-hip_x, 124.0), Vector2(-hip_x - 4.0 + groove * 6.0, 164.0), Vector2(-hip_x - 6.0 + groove * 8.0, 202.0)]
			rig["leg_r"] = [Vector2(hip_x, 124.0), Vector2(hip_x + 4.0 + groove * 6.0, 164.0), Vector2(hip_x + 6.0 + groove * 8.0, 202.0)]
			rig["hand_l_tipo"] = "puno"
			rig["hand_r_tipo"] = "puno"
			if variacion == "brindar":
				var br := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -br * 2.0)
				rig["head_rot"] = deg_to_rad(-8.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 40.0), Vector2(sh_x + 14.0, -2.0)]
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 22.0, 58.0), Vector2(-sh_x - 30.0, 34.0)]
			elif variacion == "saltar":
				var sj := absf(sin(clampf(fase_variacion, 0.0, 1.0) * PI * 2.0))
				rig["offset"] = Vector2(0.0, -sj * 14.0)
				rig["head_rot"] = deg_to_rad(-6.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 22.0, 34.0), Vector2(-sh_x - 18.0, -12.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 22.0, 34.0), Vector2(sh_x + 18.0, -12.0)]
				rig["leg_l"] = [Vector2(-hip_x, 124.0), Vector2(-hip_x - 10.0, 152.0), Vector2(-hip_x - 12.0, 188.0)]
				rig["leg_r"] = [Vector2(hip_x, 124.0), Vector2(hip_x + 10.0, 152.0), Vector2(hip_x + 12.0, 188.0)]
		"futbol":
			var cyc_f := sin(t * 6.5)
			var resp_f := sin(t * 2.0) * 1.2
			rig["offset"] = Vector2(0.0, -absf(cyc_f) * 4.5 + resp_f * 0.3)
			rig["root_rot"] = deg_to_rad(3.0 + cyc_f * 4.0)
			rig["head_rot"] = deg_to_rad(-cyc_f * 3.0 + sin(t * 1.4) * 1.4)
			rig["head_offset"] = Vector2(0.0, sin(t * 3.0) * 0.5)
			rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 18.0, 76.0 - cyc_f * 8.0), Vector2(-sh_x - 26.0, 64.0 - cyc_f * 10.0)]
			rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 18.0, 76.0 + cyc_f * 8.0), Vector2(sh_x + 26.0, 64.0 + cyc_f * 10.0)]
			var empuje_r := maxf(0.0, cyc_f) * 24.0
			var empuje_l := maxf(0.0, -cyc_f) * 20.0
			rig["leg_l"] = [Vector2(-hip_x, 124.0), Vector2(-hip_x - 7.0 - empuje_l * 0.35, 164.0 - empuje_l * 0.25), Vector2(-hip_x - 11.0 - empuje_l * 0.55, 203.0 - empuje_l)]
			rig["leg_r"] = [Vector2(hip_x, 124.0), Vector2(hip_x + 13.0 + empuje_r * 0.40, 158.0 - empuje_r * 0.35), Vector2(hip_x + 22.0 + empuje_r * 0.60, 198.0 - empuje_r)]
			rig["mirada"] = Vector2(0.6, 1.5)
			if variacion == "celebrar_gol":
				var cg := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -cg * 10.0)
				rig["head_rot"] = deg_to_rad(-10.0)
				rig["arm_l"] = [Vector2(-sh_x, 57.0), Vector2(-sh_x - 24.0, 34.0), Vector2(-sh_x - 18.0, -14.0)]
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 24.0, 34.0), Vector2(sh_x + 18.0, -14.0)]
				rig["hand_l_tipo"] = "puno"
				rig["hand_r_tipo"] = "puno"
			elif variacion == "regate":
				var rg := sin(t * 8.0)
				rig["offset"] = Vector2(rg * 4.0, -absf(rg) * 2.0)
				rig["root_rot"] = deg_to_rad(rg * 7.0)
				rig["head_rot"] = deg_to_rad(-rg * 4.0)
				rig["leg_l"] = [Vector2(-hip_x, 124.0), Vector2(-hip_x + rg * 14.0, 160.0), Vector2(-hip_x + rg * 22.0, 200.0)]
				rig["leg_r"] = [Vector2(hip_x, 124.0), Vector2(hip_x - rg * 14.0, 160.0), Vector2(hip_x - rg * 22.0, 200.0)]
			elif variacion == "toques":
				rig["head_rot"] = deg_to_rad(-4.0)
				rig["mirada"] = Vector2(0.0, 1.9)
		"trabajar":
			var tec_l := sin(t * 12.0) * 4.0
			var tec_r := cos(t * 12.0) * 4.0
			var resp_t := sin(t * 2.2) * 0.9
			rig["offset"] = Vector2(sin(t * 0.5) * 0.6, resp_t)
			rig["head_rot"] = deg_to_rad(-1.0 + sin(t * 0.7) * 1.5)
			rig["head_offset"] = Vector2(0.0, sin(t * 1.4) * 0.4)
			rig["mirada"] = Vector2(sin(t * 0.3) * 0.6, 1.4)
			rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 9.0, 87.0), Vector2(-14.0, 96.0 + tec_l)]
			rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 9.0, 87.0), Vector2(14.0, 96.0 + tec_r)]
			rig["brazos_delante"] = true
			if variacion == "cafe":
				var ca := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["head_rot"] = deg_to_rad(-6.0 - ca * 2.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 17.0, 68.0), Vector2(14.0, 26.0)]
			elif variacion == "mirar_reloj":
				rig["head_rot"] = deg_to_rad(8.0)
				rig["mirada"] = Vector2(-1.6, 1.6)
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 11.0, 76.0), Vector2(-14.0, 56.0)]
			elif variacion == "ganar_dinero":
				var gd := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -gd * 3.0)
				rig["head_rot"] = deg_to_rad(-4.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 20.0, 56.0), Vector2(sh_x + 18.0, 22.0)]
				rig["hand_r_tipo"] = "puno"
			elif variacion == "estirar_cuello":
				var ec := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["head_rot"] = deg_to_rad(-ec * 10.0)
				rig["head_offset"] = Vector2(ec * 2.0, -ec * 1.0)
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 12.0, 78.0), Vector2(-8.0, 84.0)]
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 12.0, 78.0), Vector2(8.0, 84.0)]
		_:
			# "idle" con variaciones y respiración natural
			if variacion == "saludar":
				var wave := sin(t * 11.0) * 11.0
				rig["head_rot"] = deg_to_rad(-5.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 24.0, 48.0), Vector2(sh_x + 26.0 + wave, 14.0)]
				rig["brazos_delante"] = true
			elif variacion == "mirar_movil":
				rig["head_rot"] = deg_to_rad(6.0)
				rig["mirada"] = Vector2(0.0, 2.0)
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 9.0, 85.0), Vector2(-10.0, 76.0)]
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 9.0, 85.0), Vector2(10.0, 74.0)]
				rig["brazos_delante"] = true
			elif variacion == "estirarse":
				var st := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -st * 5.0)
				rig["arm_l"] = [Vector2(-sh_x, 55.0), Vector2(-sh_x - 20.0, 32.0 - st * 18.0), Vector2(-sh_x - 11.0, -6.0 - st * 22.0)]
				rig["arm_r"] = [Vector2(sh_x, 55.0), Vector2(sh_x + 20.0, 32.0 - st * 18.0), Vector2(sh_x + 11.0, -6.0 - st * 22.0)]
			elif variacion == "silbar":
				rig["head_rot"] = deg_to_rad(sin(t * 4.5) * 8.0)
				rig["mirada"] = Vector2(1.4, -1.2)
			elif variacion == "flexionar":
				var fx := sin(t * 7.0) * 3.0
				rig["head_rot"] = deg_to_rad(-4.0)
				rig["arm_r"] = [Vector2(sh_x, 57.0), Vector2(sh_x + 24.0, 56.0), Vector2(sh_x + 14.0, 26.0 + fx)]
				rig["hand_r_tipo"] = "puno"
			elif variacion == "tomar_notas":
				var sc := sin(t * 11.0) * 4.0
				rig["head_rot"] = deg_to_rad(6.0)
				rig["mirada"] = Vector2(0.0, 2.0)
				rig["arm_l"] = [Vector2(-sh_x, 59.0), Vector2(-sh_x - 10.0, 82.0), Vector2(-8.0, 78.0)]
				rig["arm_r"] = [Vector2(sh_x, 59.0), Vector2(sh_x + 11.0, 82.0), Vector2(10.0 + sc, 76.0)]
				rig["brazos_delante"] = true

	# Postura con la edad: hombros caídos, cabeza hundida y balanceo más rígido.
	if postura > 0.001:
		rig["head_offset"] = rig["head_offset"] + Vector2(0.0, 1.7 * postura)
		for clave_brazo in ["arm_l", "arm_r"]:
			var brazo: Array = rig[clave_brazo]
			brazo[0] = brazo[0] + Vector2(0.0, 1.4 * postura)
		if nombre_pose == "idle" and animar_idle:
			rig["root_rot"] = float(rig["root_rot"]) + deg_to_rad(0.9 * postura)

	if not ignorar_variacion and variacion != "":
		var rig_base := obtener_rig_pose(nombre_pose, t, es_mujer, ap_datos, true)
		var peso := minf(
			clampf(fase_variacion / 0.14, 0.0, 1.0),
			clampf((1.0 - fase_variacion) / 0.14, 0.0, 1.0)
		)
		peso = peso * peso * (3.0 - 2.0 * peso)
		rig = _mezclar_rig(rig_base, rig, peso)

	return rig


func _mezclar_rig(base: Dictionary, var_: Dictionary, peso: float) -> Dictionary:
	var out := base.duplicate(true)
	for clave in ["offset", "head_offset"]:
		if base.has(clave) and var_.has(clave):
			out[clave] = (base[clave] as Vector2).lerp(var_[clave] as Vector2, peso)
	for clave in ["root_rot", "head_rot"]:
		if base.has(clave) and var_.has(clave):
			out[clave] = lerpf(float(base[clave]), float(var_[clave]), peso)
	for clave in ["arm_l", "arm_r", "leg_l", "leg_r"]:
		if base.has(clave) and var_.has(clave):
			var brazo: Array = []
			var b: Array = base[clave]
			var v: Array = var_[clave]
			for i in range(mini(b.size(), v.size())):
				brazo.append((b[i] as Vector2).lerp(v[i] as Vector2, peso))
			out[clave] = brazo
	for clave in ["mirada", "prop_r_rot", "prop_l_rot", "nivel_bebida",
			"comer_boca_apertura", "comer_masticacion", "comer_mejillas", "comer_rubor_extra"]:
		if base.has(clave) and var_.has(clave):
			if base[clave] is Vector2 and var_[clave] is Vector2:
				out[clave] = (base[clave] as Vector2).lerp(var_[clave] as Vector2, peso)
			else:
				out[clave] = lerpf(float(base[clave]), float(var_[clave]), peso)
	# Los estados discretos (manos, props, expresiones) cambian a mitad del fundido.
	# Los brazos pasan delante del torso en cuanto empieza la acción para evitar
	# un salto visible de orden de dibujo a mitad de la transición.
	var usar_var := peso >= 0.5
	for clave in ["hand_l_tipo", "hand_r_tipo", "brazos_delante", "prop_r_override",
			"prop_l_override", "bocado_en_tenedor", "comer_ojos_felices", "comer_expresion_override"]:
		if var_.has(clave):
			if clave == "brazos_delante":
				out[clave] = bool(var_[clave]) if (peso > 0.10 or not base.has(clave)) else bool(base[clave])
			else:
				out[clave] = var_[clave] if usar_var or not base.has(clave) else base[clave]
	return out


func _suave(x: float) -> float:
	var k := clampf(x, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


func _suave_mas(x: float) -> float:
	var k := clampf(x, 0.0, 1.0)
	return k * k * k * (k * (k * 6.0 - 15.0) + 10.0)


func _tramo(valor: float, inicio: float, fin: float) -> float:
	if fin <= inicio:
		return 1.0 if valor >= fin else 0.0
	return _suave((valor - inicio) / (fin - inicio))


func _aplicar_rig_comer(rig: Dictionary, sh_x: float, t: float,
		var_uso: String = "", fase_uso: float = -1.0) -> void:
	rig["brazos_delante"] = true

	var sh_l := Vector2(-sh_x, 57.0)
	var sh_r := Vector2(sh_x, 57.0)
	var el_l_rep := Vector2(-sh_x - 14.0, 76.0)
	var ha_l_rep := Vector2(-35.0, 76.0)
	var el_r_rep := Vector2(sh_x + 14.0, 76.0)
	var ha_r_rep := Vector2(36.0, 75.0)
	var rot_r_rep := -1.12

	var el_r_plato := Vector2(sh_x + 11.0, 72.0)
	var ha_r_plato := Vector2(22.0, 67.0)
	var rot_r_plato := -2.06

	var el_r_boca := Vector2(sh_x + 13.0, 65.0)
	var ha_r_boca := Vector2(18.5, 36.5)
	var rot_r_boca := -0.84

	rig["offset"] = Vector2(0.0, sin(t * 2.1) * 0.7)
	rig["head_offset"] = Vector2.ZERO
	rig["head_rot"] = 0.0
	rig["arm_l"] = [sh_l, el_l_rep, ha_l_rep]
	rig["arm_r"] = [sh_r, el_r_rep, ha_r_rep]
	rig["prop_r_rot"] = rot_r_rep
	rig["prop_l_rot"] = 1.35
	rig["bocado_en_tenedor"] = false
	rig["nivel_bebida"] = 0.76
	rig["comer_boca_apertura"] = 0.0
	rig["comer_masticacion"] = 0.0
	rig["comer_mejillas"] = 0.0
	rig["comer_rubor_extra"] = 0.0
	rig["comer_ojos_felices"] = false
	rig["comer_expresion_override"] = ""

	var fase := clampf(fase_uso if fase_uso >= 0.0 else fase_variacion, 0.0, 1.0)

	match var_uso:
		"beber":
			var vaso_mesa := Vector2(63.0, 71.0)
			var el_vaso_mesa := Vector2(sh_x + 20.0, 72.0)
			var vaso_boca := Vector2(20.0, 34.5)
			var el_vaso_boca := Vector2(sh_x + 15.0, 63.0)

			var el_r := el_r_rep
			var ha_r := ha_r_rep
			var rot_v := 0.0
			var h_rot := 0.0
			var nivel := 0.76
			var ojos_f := false
			var expr_ov := "sonrisa"

			if fase < 0.18:
				var k := _tramo(fase, 0.0, 0.18)
				el_r = el_r_rep.lerp(el_vaso_mesa, k)
				ha_r = ha_r_rep.lerp(vaso_mesa, k)
				rig["mirada"] = Vector2(1.5 * k, 1.5 * k)
			elif fase < 0.38:
				var k := _suave_mas((fase - 0.18) / 0.20)
				el_r = el_vaso_mesa.lerp(el_vaso_boca, k)
				ha_r = vaso_mesa.lerp(vaso_boca, k) + Vector2(sin(k * PI) * 8.0, -sin(k * PI) * 5.0)
				rot_v = lerpf(0.0, -0.66, k)
				h_rot = deg_to_rad(lerpf(0.0, -7.5, k))
				rig["mirada"] = Vector2(1.5 * (1.0 - k), 1.5 * (1.0 - k))
				if k > 0.65:
					ojos_f = true
					expr_ov = "satisfecho"
			elif fase < 0.74:
				var u := (fase - 0.38) / 0.36
				var sorbo := sin(u * PI * 2.0)
				el_r = el_vaso_boca + Vector2(0.0, -maxf(0.0, sorbo) * 2.2)
				ha_r = vaso_boca + Vector2(-maxf(0.0, sorbo) * 2.0, -maxf(0.0, sorbo) * 1.8)
				rot_v = -0.68 - maxf(0.0, sorbo) * 0.16
				h_rot = deg_to_rad(-8.5 - maxf(0.0, sorbo) * 3.0)
				rig["head_offset"] = Vector2(0.0, -maxf(0.0, sorbo) * 1.4)
				nivel = lerpf(0.76, 0.54, u)
				ojos_f = true
				expr_ov = "satisfecho"
			elif fase < 0.88:
				var k := _suave_mas((fase - 0.74) / 0.14)
				el_r = el_vaso_boca.lerp(el_vaso_mesa, k)
				ha_r = vaso_boca.lerp(vaso_mesa, k) + Vector2(sin(k * PI) * 6.0, -sin(k * PI) * 4.0)
				rot_v = lerpf(-0.66, 0.0, k)
				h_rot = deg_to_rad(lerpf(-7.5, 0.0, k))
				nivel = 0.54
				rig["mirada"] = Vector2(1.3 * k, 1.3 * k)
				expr_ov = "sonrisa"
			else:
				var k := _tramo(fase, 0.88, 1.0)
				el_r = el_vaso_mesa.lerp(el_r_rep, k)
				ha_r = vaso_mesa.lerp(ha_r_rep, k)
				nivel = 0.54
				ojos_f = fase < 0.96
				expr_ov = "satisfecho" if fase < 0.96 else "sonrisa"

			rig["arm_r"] = [sh_r, el_r, ha_r]
			rig["head_rot"] = h_rot
			rig["prop_r_rot"] = rot_v
			rig["nivel_bebida"] = nivel
			rig["comer_ojos_felices"] = ojos_f
			rig["comer_expresion_override"] = expr_ov
			rig["prop_r_override"] = "vaso" if (fase >= 0.16 and fase <= 0.88) else "ninguno"
			rig["prop_l_override"] = "ninguno"

		"soplar":
			var el_sop := Vector2(sh_x + 17.0, 66.0)
			var ha_sop := Vector2(35.0, 40.0)
			var rot_sop := -0.78

			var el_r := el_r_rep
			var ha_r := ha_r_rep
			var rot_f := rot_r_rep
			var bocado := fase < 0.84
			var h_rot := 0.0
			var mejillas := 0.0
			var apertura := 0.0
			var ojos_f := false
			var expr_ov := "soplando"

			if fase < 0.16:
				var k := _suave_mas(fase / 0.16)
				el_r = el_r_plato.lerp(el_sop, k)
				ha_r = ha_r_plato.lerp(ha_sop, k) + Vector2(sin(k * PI) * 5.0, -sin(k * PI) * 3.0)
				rot_f = lerpf(rot_r_plato, rot_sop, k)
				rig["mirada"] = Vector2(0.7, 1.3)
				expr_ov = "sonrisa"
			elif fase < 0.70:
				var u := (fase - 0.16) / 0.54
				var rafaga := maxf(0.0, sin(u * PI * 2.0))
				el_r = el_sop + Vector2(0.0, sin(t * 7.0) * 0.9)
				ha_r = ha_sop + Vector2(sin(t * 9.0) * 0.8, cos(t * 7.0) * 0.8)
				rot_f = rot_sop
				h_rot = deg_to_rad(3.5 + rafaga * 2.5)
				rig["head_offset"] = Vector2(rafaga * 1.4, rafaga * 1.0)
				mejillas = 0.55 + rafaga * 0.45
				rig["mirada"] = Vector2(0.8, 1.3)
				expr_ov = "soplando"
			elif fase < 0.85:
				var k := _suave_mas((fase - 0.70) / 0.15)
				el_r = el_sop.lerp(el_r_boca, k)
				ha_r = ha_sop.lerp(ha_r_boca, k)
				rot_f = lerpf(rot_sop, rot_r_boca, k)
				h_rot = deg_to_rad(lerpf(3.0, -2.0, k))
				apertura = sin(k * PI)
				expr_ov = "masticando"
			else:
				var k := _tramo(fase, 0.85, 1.0)
				el_r = el_r_boca.lerp(el_r_rep, k)
				ha_r = ha_r_boca.lerp(ha_r_rep, k)
				rot_f = lerpf(rot_r_boca, rot_r_rep, k)
				mejillas = 0.55 * (1.0 - k * 0.5)
				ojos_f = true
				expr_ov = "satisfecho"

			rig["arm_r"] = [sh_r, el_r, ha_r]
			rig["prop_r_rot"] = rot_f
			rig["bocado_en_tenedor"] = bocado
			rig["head_rot"] = h_rot
			rig["comer_mejillas"] = mejillas
			rig["comer_boca_apertura"] = apertura
			rig["comer_ojos_felices"] = ojos_f
			rig["comer_expresion_override"] = expr_ov
			rig["prop_r_override"] = "tenedor"
			rig["prop_l_override"] = "ninguno"

		"delicioso":
			var k := minf(_tramo(fase, 0.0, 0.18), 1.0 - _tramo(fase, 0.82, 1.0))
			var balanceo := sin(fase * TAU * 2.0) * k
			var h_rot := deg_to_rad(balanceo * 7.5)
			var dy := -absf(balanceo) * 2.2

			var mej_l := Vector2(-29.0, 19.0) + Vector2(balanceo * 2.2, dy)
			var mej_r := Vector2(29.0, 19.0) + Vector2(balanceo * 2.2, dy)
			var el_l_m := Vector2(-sh_x - 15.0, 62.0)
			var el_r_m := Vector2(sh_x + 15.0, 62.0)

			rig["offset"] = Vector2(0.0, dy)
			rig["head_rot"] = h_rot
			rig["arm_l"] = [sh_l, el_l_rep.lerp(el_l_m, k), ha_l_rep.lerp(mej_l, k) + Vector2(-sin(k * PI) * 8.0, 0.0)]
			rig["arm_r"] = [sh_r, el_r_rep.lerp(el_r_m, k), ha_r_rep.lerp(mej_r, k) + Vector2(sin(k * PI) * 8.0, 0.0)]
			if k > 0.65:
				rig["hand_l_tipo"] = "mejilla_l"
				rig["hand_r_tipo"] = "mejilla_r"
			rig["comer_rubor_extra"] = k * 0.34
			rig["comer_ojos_felices"] = k > 0.25
			rig["comer_expresion_override"] = "feliz_cerrado" if k > 0.25 else "sonrisa"
			rig["prop_r_override"] = "ninguno"
			rig["prop_l_override"] = "ninguno"

		"limpiar_boca":
			var serv_mesa := Vector2(-61.0, 77.0)
			var el_serv_mesa := Vector2(-sh_x - 19.0, 74.0)
			var serv_boca := Vector2(-10.0, 26.0)
			var el_serv_boca := Vector2(-sh_x - 15.0, 62.0)

			var el_l := el_l_rep
			var ha_l := ha_l_rep
			var rot_s := 0.0
			var h_rot := 0.0

			if fase < 0.18:
				var k := _tramo(fase, 0.0, 0.18)
				el_l = el_l_rep.lerp(el_serv_mesa, k)
				ha_l = ha_l_rep.lerp(serv_mesa, k)
				rig["mirada"] = Vector2(-1.5 * k, 1.5 * k)
			elif fase < 0.32:
				var k := _suave_mas((fase - 0.18) / 0.14)
				el_l = el_serv_mesa.lerp(el_serv_boca, k)
				ha_l = serv_mesa.lerp(serv_boca, k) + Vector2(-sin(k * PI) * 6.0, -sin(k * PI) * 4.0)
				rot_s = lerpf(0.0, 0.22, k)
				rig["mirada"] = Vector2(-1.5 * (1.0 - k), 1.5 * (1.0 - k))
			elif fase < 0.72:
				var u := (fase - 0.32) / 0.40
				var dab := sin(u * PI * 3.0)
				el_l = el_serv_boca + Vector2(dab * 2.2, 0.0)
				ha_l = serv_boca + Vector2(dab * 6.0, absf(cos(u * PI * 3.0)) * 2.0)
				rot_s = 0.22 + dab * 0.16
				h_rot = deg_to_rad(dab * 3.0)
			elif fase < 0.88:
				var k := _suave_mas((fase - 0.72) / 0.16)
				el_l = el_serv_boca.lerp(el_serv_mesa, k)
				ha_l = serv_boca.lerp(serv_mesa, k) + Vector2(-sin(k * PI) * 5.0, -sin(k * PI) * 3.0)
				rot_s = lerpf(0.22, 0.0, k)
				rig["mirada"] = Vector2(-1.2 * k, 1.4 * k)
			else:
				var k := _tramo(fase, 0.88, 1.0)
				el_l = el_serv_mesa.lerp(el_l_rep, k)
				ha_l = serv_mesa.lerp(ha_l_rep, k)

			rig["arm_l"] = [sh_l, el_l, ha_l]
			rig["head_rot"] = h_rot
			rig["prop_l_rot"] = rot_s
			rig["comer_expresion_override"] = "sonrisa"
			rig["prop_r_override"] = "ninguno"
			rig["prop_l_override"] = "servilleta" if (fase >= 0.16 and fase <= 0.88) else "ninguno"

		"oler":
			var k := minf(_tramo(fase, 0.0, 0.20), 1.0 - _tramo(fase, 0.80, 1.0))
			var inhala := sin(clampf((fase - 0.15) / 0.70, 0.0, 1.0) * PI)
			rig["offset"] = Vector2(0.0, 3.0 * k - inhala * 3.6)
			rig["head_offset"] = Vector2(0.0, -inhala * 1.4)
			rig["head_rot"] = deg_to_rad(-6.5 * inhala + sin(t * 3.5) * 1.6 * k)
			rig["arm_l"] = [sh_l, el_l_rep.lerp(Vector2(-sh_x - 10.0, 75.0), k), ha_l_rep.lerp(Vector2(-23.0, 73.0), k)]
			rig["arm_r"] = [sh_r, el_r_rep.lerp(Vector2(sh_x + 10.0, 75.0), k), ha_r_rep.lerp(Vector2(23.0, 73.0), k)]
			rig["comer_rubor_extra"] = inhala * 0.20
			rig["comer_ojos_felices"] = k > 0.28
			rig["comer_expresion_override"] = "satisfecho" if k > 0.28 else "sonrisa"
			rig["prop_r_override"] = "ninguno"
			rig["prop_l_override"] = "ninguno"

		_:
			var c := obtener_ciclo_comer(t)
			var el_r := el_r_rep
			var ha_r := ha_r_rep
			var rot_f := rot_r_rep
			var el_l := el_l_rep
			var ha_l := ha_l_rep
			var rot_k := 1.35
			var bocado := false
			var apertura := 0.0
			var masticacion := 0.0
			var mejillas := 0.0
			var h_rot := 0.0
			var h_off := Vector2.ZERO
			var mirada := Vector2.ZERO
			var ojos_f := false

			if c < 0.10:
				var k := _tramo(c, 0.0, 0.10)
				el_r = el_r_rep.lerp(el_r_plato, k)
				ha_r = ha_r_rep.lerp(ha_r_plato, k)
				rot_f = lerpf(rot_r_rep, rot_r_plato, k)
				ha_l = ha_l_rep.lerp(Vector2(-25.0, 73.0), k)
				mirada = Vector2(0.4, 1.9)
				h_rot = deg_to_rad(3.2 * k)
			elif c < 0.22:
				var u := (c - 0.10) / 0.12
				var poke := sin(u * PI * 2.0)
				el_r = el_r_plato + Vector2(0.0, absf(poke) * 1.4)
				ha_r = ha_r_plato + Vector2(-maxf(0.0, poke) * 2.8, absf(poke) * 2.8)
				rot_f = rot_r_plato + poke * 0.18
				ha_l = Vector2(-24.5, 72.5) + Vector2(poke * 1.6, absf(poke) * 1.2)
				rot_k = 1.65 - poke * 0.15
				bocado = c >= 0.15
				mirada = Vector2(0.4, 1.9)
				h_rot = deg_to_rad(3.4)
			elif c < 0.41:
				var k := _suave_mas((c - 0.22) / 0.19)
				el_r = el_r_plato.lerp(el_r_boca, k)
				ha_r = ha_r_plato.lerp(ha_r_boca, k) + Vector2(sin(k * PI) * 6.5, -sin(k * PI) * 4.0)
				rot_f = lerpf(rot_r_plato, rot_r_boca, k)
				ha_l = Vector2(-24.5, 72.5).lerp(ha_l_rep, k)
				rot_k = lerpf(1.65, 1.35, k)
				bocado = true
				mirada = Vector2(0.4, 1.9).lerp(Vector2(0.6, 0.5), k)
				h_rot = deg_to_rad(lerpf(3.4, -2.6, k))
				apertura = _tramo(c, 0.28, 0.40)
			elif c < 0.50:
				var u := (c - 0.41) / 0.09
				var acercar := sin(u * PI)
				el_r = el_r_boca
				ha_r = ha_r_boca + Vector2(-acercar * 2.4, -acercar * 1.0)
				rot_f = rot_r_boca - acercar * 0.06
				bocado = c < 0.46
				mirada = Vector2(0.5, 0.5)
				h_rot = deg_to_rad(lerpf(-2.6, 1.6, u))
				h_off = Vector2(0.0, acercar * 1.0)
				apertura = 1.0 - _tramo(c, 0.43, 0.49)
			elif c < 0.68:
				var k := _suave((c - 0.50) / 0.18)
				el_r = el_r_boca.lerp(el_r_rep, k)
				ha_r = ha_r_boca.lerp(ha_r_rep, k) + Vector2(sin(k * PI) * 5.0, -sin(k * PI) * 2.0)
				rot_f = lerpf(rot_r_boca, rot_r_rep, k)
				bocado = false
			else:
				el_r = el_r_rep
				ha_r = ha_r_rep
				rot_f = rot_r_rep
				bocado = false

			if c >= 0.48 and c <= 0.96:
				var env := _tramo(c, 0.48, 0.54) * (1.0 - _tramo(c, 0.88, 0.96))
				var ang_m := (c - 0.48) * 3.5 * TAU
				var pulso := (sin(ang_m) + 1.0) * 0.5
				mejillas = env * (0.52 + pulso * 0.48)
				masticacion = env * sin(ang_m)
				h_off += Vector2(0.0, env * sin(ang_m) * 1.1)
				h_rot += deg_to_rad(env * sin(ang_m * 0.5) * 3.6)
				ojos_f = (c >= 0.54 and c <= 0.72)

			if c >= 0.78:
				var km := _tramo(c, 0.78, 0.96)
				mirada = Vector2(0.0, 0.0).lerp(Vector2(0.4, 1.9), km)

			rig["arm_l"] = [sh_l, el_l, ha_l]
			rig["arm_r"] = [sh_r, el_r, ha_r]
			rig["prop_r_rot"] = rot_f
			rig["prop_l_rot"] = rot_k
			rig["bocado_en_tenedor"] = bocado
			rig["comer_boca_apertura"] = apertura
			rig["comer_masticacion"] = masticacion
			rig["comer_mejillas"] = mejillas
			rig["comer_ojos_felices"] = ojos_f
			rig["head_rot"] = h_rot
			rig["head_offset"] = h_off
			rig["mirada"] = mirada
			rig["prop_r_override"] = "tenedor"
			rig["prop_l_override"] = "cuchillo" if estilo_tenedor == "metal" else "ninguno"


# ---------------------------------------------------------------- render principal

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var src: Personaje_Visual = fuente_overlay if (modo_capa == "solo_brazos_delanteros" and fuente_overlay != null) else self

	if src.dibujar_fondo_sunburst and modo_capa != "solo_brazos_delanteros":
		_dibujar_fondo_sunburst()

	var ap: Dictionary = src.apariencia
	var es_mujer := Apariencia_Personaje.es_mujer(ap)
	var met := _metricas_cuerpo(es_mujer, ap)

	var edad_pj := src.obtener_edad()
	_rasgos_edad = Envejecimiento_Personaje.rasgos(edad_pj)
	_edad_pintada = edad_pj

	var piel := Envejecimiento_Personaje.color_piel(
		Apariencia_Personaje.color_de(ap, "color_piel", Color("#f8cfb4")),
		float(_rasgos_edad.get("piel_apagada", 0.0)))
	var piel_sombra := _sombra_piel(piel)
	var ojos := Apariencia_Personaje.color_de(ap, "color_ojos", Color("#6b4226"))
	var pelo := Envejecimiento_Personaje.color_pelo(
		Apariencia_Personaje.color_de(ap, "color_pelo", Color("#7c4728")),
		float(_rasgos_edad.get("canas", 0.0)))
	var ropa := Apariencia_Personaje.color_de(ap, "color_ropa", Color("#2563eb"))
	var pantalon := Apariencia_Personaje.color_de(ap, "color_pantalon", Color("#3b6ea5"))
	var calzado_col := Apariencia_Personaje.color_de(ap, "color_calzado", Color("#2563eb"))

	var estilo_pelo := str(ap.get("estilo_pelo", "alborotado"))
	var ropa_sup := str(ap.get("ropa_superior", "sudadera"))
	var ropa_inf := str(ap.get("ropa_inferior", "vaqueros"))
	var tipo_calzado := str(ap.get("calzado", "zapatillas"))
	var estilo_atuendo := str(ap.get("estilo_ropa", "base"))
	var detalle_atuendo := str(ap.get("detalle_ropa", ""))
	var ropa_sec := Apariencia_Personaje.color_de(ap, "color_ropa_secundario", Color("#f8fafc"))
	var ropa_det := Apariencia_Personaje.color_de(ap, "color_ropa_detalle", Color("#f8fafc"))

	# Algunos atuendos llevan una prenda exterior con mangas. Los brazos deben
	# usar el color y el largo de esa capa, no los de la camisa interior.
	var ropa_sup_brazos := ropa_sup
	var ropa_brazos := ropa
	match estilo_atuendo:
		"traje", "bata", "cuero", "fiesta":
			ropa_sup_brazos = "chaqueta"
			ropa_brazos = ropa_sec
		"invierno":
			if detalle_atuendo == "abrigo":
				ropa_sup_brazos = "chaqueta"
				ropa_brazos = ropa_sec
		"astronauta":
			ropa_sup_brazos = "chaqueta"
			ropa_brazos = ropa

	var rig := src.obtener_rig_pose(src.pose, src._t, es_mujer, ap)
	var tr := src._calcular_transform_camara()
	var esc: float = tr["scale"]
	var centro: Vector2 = tr["origin"]
	var grosor := 2.35

	draw_set_transform(centro + rig["offset"] * esc, rig["root_rot"], Vector2(esc, esc))

	var head_pos: Vector2 = rig["head_offset"]
	var head_rot: float = rig["head_rot"]
	var brazos_delante: bool = bool(rig.get("brazos_delante", false))

	var prop_r: String = str(rig.get("prop_r_override", src.prop_mano))
	var prop_l: String = str(rig.get("prop_l_override", src.prop_mano_izq))

	if modo_capa != "solo_brazos_delanteros":
		# 1. Pelo trasero (detrás del torso y cuello)
		_dibujar_pelo_trasero(head_pos, head_rot, estilo_pelo, pelo, grosor)

		# 2. Piernas y calzado (si cuerpo completo)
		if src.modo == "cuerpo_completo":
			_dibujar_piernas(rig["leg_l"], rig["leg_r"], met, ropa_inf, pantalon, tipo_calzado,
				calzado_col, piel, piel_sombra, grosor, estilo_atuendo, ropa_sec, ropa_det,
				detalle_atuendo)

		# 3. Brazos traseros
		if not brazos_delante:
			_dibujar_brazo(rig["arm_l"], met, ropa_sup_brazos, ropa_brazos, piel, piel_sombra, rig["hand_l_tipo"], src.en_ducha, grosor, estilo_atuendo, detalle_atuendo, ropa_sec)
			_dibujar_brazo(rig["arm_r"], met, ropa_sup_brazos, ropa_brazos, piel, piel_sombra, rig["hand_r_tipo"], src.en_ducha, grosor, estilo_atuendo, detalle_atuendo, ropa_sec)

		# 4. Torso / prenda superior y cuello
		_dibujar_torso(es_mujer, met, ropa_sup, ropa, piel, piel_sombra, src.en_ducha, grosor)

		# 4b. Detalles propios de los atuendos (delantal, chef, traje, vestido...)
		if estilo_atuendo != "base" and not src.en_ducha:
			_dibujar_atuendo_encima(es_mujer, met, estilo_atuendo, ropa, ropa_sec, ropa_det,
				grosor, ropa_sup, detalle_atuendo)

		# 5. Cabeza + cara + pelo delantero + accesorios
		_dibujar_cabeza_completa(
			head_pos, head_rot, es_mujer, met, piel, piel_sombra, ojos, pelo,
			ap, rig["mirada"], grosor, rig, src
		)

		# Espuma de champú en la cabeza durante la ducha
		if src.en_ducha and src.variacion == "espuma_pelo":
			_dibujar_espuma_cabeza(head_pos, head_rot, grosor)

	if modo_capa != "sin_brazos_delanteros":
		if brazos_delante:
			_dibujar_brazo(rig["arm_l"], met, ropa_sup_brazos, ropa_brazos, piel, piel_sombra, rig["hand_l_tipo"], src.en_ducha, grosor, estilo_atuendo, detalle_atuendo, ropa_sec)
			_dibujar_brazo(rig["arm_r"], met, ropa_sup_brazos, ropa_brazos, piel, piel_sombra, rig["hand_r_tipo"], src.en_ducha, grosor, estilo_atuendo, detalle_atuendo, ropa_sec)

		if prop_l != "ninguno":
			var pos_mano_l: Vector2 = rig["arm_l"][2]
			_dibujar_prop_en_mano(prop_l, pos_mano_l, grosor, rig, true, src)

		if prop_r != "ninguno":
			var pos_mano_r: Vector2 = rig["arm_r"][2]
			if prop_r == "tarta_18":
				_dibujar_tarta_18(pos_mano_r + Vector2(8.0, -4.0), grosor)
			else:
				_dibujar_prop_en_mano(prop_r, pos_mano_r, grosor, rig, false, src)

		if src.pose == "sorpresa" or (src.pose == "correr" and src.variacion in ["secar_sudor", "sprint"]):
			_dibujar_gotas_sudor(head_pos + Vector2(40.0, -14.0), grosor)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _calcular_transform_camara() -> Dictionary:
	var view_rect: Rect2
	match modo:
		"retrato":
			view_rect = Rect2(-50.0, -54.0, 100.0, 102.0)
		"retrato_cercano":
			view_rect = Rect2(-40.0, -44.0, 80.0, 86.0)
		"cuerpo_completo":
			if pose == "volando":
				view_rect = Rect2(-108.0, -78.0, 218.0, 286.0)
			else:
				view_rect = Rect2(-78.0, -70.0, 156.0, 300.0)
		_:
			if prop_mano == "tarta_18":
				view_rect = Rect2(-86.0, -90.0, 226.0, 212.0)
			elif accesorio_cabeza == "gorro_volando":
				view_rect = Rect2(-80.0, -96.0, 160.0, 206.0)
			else:
				view_rect = Rect2(-72.0, -74.0, 144.0, 196.0)

	if margen_retrato > 0.0 and (modo == "retrato" or modo == "retrato_cercano"):
		view_rect = view_rect.grow(margen_retrato)

	var sx := size.x / view_rect.size.x
	var sy := size.y / view_rect.size.y
	var esc := minf(sx, sy)
	var centro_view := view_rect.get_center()
	var origin := size * 0.5 - centro_view * esc
	return {"scale": esc, "origin": origin}


func _dibujar_fondo_sunburst() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color_fondo_base)
	var c := size * 0.5
	var r := size.length() * 0.85
	var rayos := 14
	for i in range(rayos):
		var a0 := TAU * float(i) / float(rayos)
		var a1 := a0 + TAU / float(rayos * 2)
		draw_colored_polygon(PackedVector2Array([
			c,
			c + Vector2(cos(a0), sin(a0)) * r,
			c + Vector2(cos(a1), sin(a1)) * r,
		]), color_fondo_rayo)


# ---------------------------------------------------------------- piernas, calzado, brazos y torso

func _dibujar_piernas(leg_l: Array, leg_r: Array, met: Dictionary, ropa_inf: String,
		pantalon: Color, tipo_calzado: String, calzado_col: Color,
		piel: Color, piel_sombra: Color, grosor: float, estilo_atuendo: String = "base",
		ropa_sec: Color = Color.WHITE, ropa_det: Color = Color.WHITE,
		detalle_atuendo: String = "") -> void:
	var ls: float = met["leg_scale"]
	var hip_w: float = met["hip_x"]
	var pant_sombra := pantalon.darkened(0.22)
	var es_shorts_o_falda := ropa_inf in ["shorts", "falda"]

	var idx := 0
	for pierna in [leg_l, leg_r]:
		var hip: Vector2 = pierna[0]
		var knee: Vector2 = pierna[1]
		var foot: Vector2 = pierna[2]
		if es_shorts_o_falda:
			_dibujar_extremidad_continua(hip, knee, foot, 11.4 * ls, 8.8 * ls, 6.8 * ls, piel, piel_sombra, grosor * 0.88)
			if ropa_inf == "shorts":
				var fin_sh := hip.lerp(knee, 0.62)
				_dibujar_extremidad_continua(hip, hip.lerp(fin_sh, 0.5), fin_sh, 12.6 * ls, 11.8 * ls, 11.2 * ls, pantalon, pant_sombra, grosor * 0.90)
		else:
			_dibujar_extremidad_continua(hip, knee, foot, 12.6 * ls, 10.4 * ls, 8.6 * ls, pantalon, pant_sombra, grosor * 0.9)
			if ropa_inf == "chandal":
				draw_line(hip + Vector2((-8.5 if idx == 0 else 8.5) * ls, 4.0), foot + Vector2((-5.5 if idx == 0 else 5.5) * ls, -8.0), Color(1, 1, 1, 0.82), 2.4, true)
			elif ropa_inf == "chino":
				draw_line(hip.lerp(knee, 0.25), knee.lerp(foot, 0.65), Color(pant_sombra, 0.45), 1.4, true)
			if estilo_atuendo in ["gala", "michelin"]:
				var lado_ext := -1.0 if idx == 0 else 1.0
				draw_line(hip + Vector2(lado_ext * 7.0 * ls, 4.0),
					foot + Vector2(lado_ext * 5.0 * ls, -8.0), Color(0.98, 0.75, 0.15, 0.9), 1.8, true)
			elif estilo_atuendo == "pijama":
				# Ribete lateral del pantalón del pijama.
				draw_line(hip + Vector2((-7.5 if idx == 0 else 7.5) * ls, 3.0),
					foot + Vector2((-4.8 if idx == 0 else 4.8) * ls, -8.0),
					Color(ropa_sec, 0.72), 1.6, true)

		if estilo_atuendo == "futbol":
			# Medias altas del equipo sobre la piel descubierta por el short.
			var media_ini := knee.lerp(foot, 0.10)
			var media_fin := foot + Vector2(0.0, -3.0)
			_dibujar_extremidad_continua(knee.lerp(foot, 0.02), media_ini, media_fin,
				9.2 * ls, 8.2 * ls, 7.2 * ls, ropa_sec, ropa_sec.darkened(0.18), grosor * 0.78)
			draw_line(knee.lerp(foot, 0.35), knee.lerp(foot, 0.39),
				Color(ropa_det, 0.85), 2.0, true)

		var dir_pie := (foot - knee).normalized()
		var flip := -1.0 if (pose != "volando" and idx == 0) else 1.0
		_dibujar_calzado(foot, dir_pie, flip, tipo_calzado, calzado_col, grosor)
		idx += 1

	# Falda encima de las caderas
	if ropa_inf == "falda":
		var l_hip: Vector2 = leg_l[0]
		var r_hip: Vector2 = leg_r[0]
		var l_knee: Vector2 = leg_l[1]
		var r_knee: Vector2 = leg_r[1]
		var y_top := minf(l_hip.y, r_hip.y) - 4.0
		var y_bot := (l_knee.y + r_knee.y) * 0.5 - 6.0
		var cx := (l_hip.x + r_hip.x) * 0.5
		var falda := _suavizar_cerrado(PackedVector2Array([
			Vector2(cx - hip_w * 0.96, y_top),
			Vector2(cx + hip_w * 0.96, y_top),
			Vector2(cx + hip_w * 1.38, y_bot - 4.0),
			Vector2(cx + hip_w * 0.7, y_bot + 2.0),
			Vector2(cx, y_bot + 3.0),
			Vector2(cx - hip_w * 0.7, y_bot + 2.0),
			Vector2(cx - hip_w * 1.38, y_bot - 4.0),
		]), 3)
		_poligono_tinta(falda, pantalon, grosor * 0.92)
		# Pliegues de falda
		for px_f: float in [-0.45, 0.0, 0.45]:
			draw_line(Vector2(cx + hip_w * px_f * 0.6, y_top + 6.0), Vector2(cx + hip_w * px_f * 1.1, y_bot - 2.0), Color(pant_sombra, 0.65), 1.5, true)


func _dibujar_calzado(pos: Vector2, dir: Vector2, flip_x: float, tipo: String, color_zap: Color, grosor: float) -> void:
	var ang := atan2(dir.y, dir.x) - PI * 0.5
	var centro := pos + Vector2(0.0, 4.5)
	if tipo == "botas":
		var bota := PackedVector2Array([
			Vector2(-9.8 * flip_x, -10.5),
			Vector2(9.2 * flip_x, -10.5),
			Vector2(10.5 * flip_x, -1.5),
			Vector2(17.5 * flip_x, 4.5),
			Vector2(17.0 * flip_x, 11.8),
			Vector2(-11.2 * flip_x, 11.8),
			Vector2(-11.4 * flip_x, 1.0),
		])
		var suela_b := PackedVector2Array([
			Vector2(-11.2 * flip_x, 8.2),
			Vector2(17.2 * flip_x, 8.2),
			Vector2(16.8 * flip_x, 12.6),
			Vector2(-11.0 * flip_x, 12.6),
		])
		_poligono_tinta(_transformar_pts(_suavizar_cerrado(bota, 3), centro, ang), color_zap, grosor * 0.88)
		_poligono_tinta(_transformar_pts(suela_b, centro, ang), Color("#1e293b"), grosor * 0.72)
		draw_line(centro + _rotar(Vector2(5.5 * flip_x, -5.0), ang), centro + _rotar(Vector2(8.5 * flip_x, -3.5), ang), Color("#e2e8f0"), 1.5, true)
		draw_line(centro + _rotar(Vector2(6.5 * flip_x, -1.5), ang), centro + _rotar(Vector2(9.5 * flip_x, 0.0), ang), Color("#e2e8f0"), 1.5, true)
		return

	if tipo == "zapatos":
		var zap := PackedVector2Array([
			Vector2(-9.2 * flip_x, -3.0),
			Vector2(9.2 * flip_x, -3.0),
			Vector2(18.0 * flip_x, 4.2),
			Vector2(17.5 * flip_x, 10.6),
			Vector2(-10.8 * flip_x, 10.6),
			Vector2(-11.0 * flip_x, 2.5),
		])
		var suela_z := PackedVector2Array([
			Vector2(-10.8 * flip_x, 8.0),
			Vector2(17.5 * flip_x, 8.0),
			Vector2(17.2 * flip_x, 11.4),
			Vector2(-10.6 * flip_x, 11.4),
		])
		_poligono_tinta(_transformar_pts(_suavizar_cerrado(zap, 3), centro, ang), color_zap, grosor * 0.86)
		_poligono_tinta(_transformar_pts(suela_z, centro, ang), color_zap.darkened(0.45), grosor * 0.68)
		draw_line(centro + _rotar(Vector2(2.0 * flip_x, 1.5), ang), centro + _rotar(Vector2(11.0 * flip_x, 3.0), ang), Color(1, 1, 1, 0.35), 1.5, true)
		return

	# Zapatillas deportivas modernas
	var base := PackedVector2Array([
		Vector2(-9.5 * flip_x, -3.5),
		Vector2(9.5 * flip_x, -3.5),
		Vector2(17.5 * flip_x, 4.5),
		Vector2(17.0 * flip_x, 11.2),
		Vector2(-11.0 * flip_x, 11.2),
		Vector2(-11.2 * flip_x, 3.0),
	])
	var suela := PackedVector2Array([
		Vector2(-11.0 * flip_x, 7.8),
		Vector2(17.2 * flip_x, 7.8),
		Vector2(16.8 * flip_x, 12.0),
		Vector2(-10.8 * flip_x, 12.0),
	])
	var puntera := PackedVector2Array([
		Vector2(10.0 * flip_x, 1.5),
		Vector2(17.0 * flip_x, 4.5),
		Vector2(16.8 * flip_x, 8.0),
		Vector2(10.5 * flip_x, 8.0),
	])
	_poligono_tinta(_transformar_pts(_suavizar_cerrado(base, 3), centro, ang), color_zap, grosor * 0.88)
	draw_colored_polygon(_transformar_pts(puntera, centro, ang), Color.WHITE)
	_poligono_tinta(_transformar_pts(suela, centro, ang), Color.WHITE, grosor * 0.72)
	draw_line(centro + _rotar(Vector2(4.0 * flip_x, -1.0), ang), centro + _rotar(Vector2(8.0 * flip_x, 1.0), ang), Color.WHITE, 1.6, true)
	draw_line(centro + _rotar(Vector2(6.5 * flip_x, 1.5), ang), centro + _rotar(Vector2(10.2 * flip_x, 3.2), ang), Color.WHITE, 1.6, true)


func _dibujar_brazo(arm: Array, met: Dictionary, ropa_sup: String, ropa: Color,
		piel: Color, piel_sombra: Color, tipo_mano: String, esta_ducha: bool, grosor: float,
		estilo: String = "", _detalle: String = "", color_extra: Color = Color.WHITE) -> void:
	var sh: Vector2 = arm[0]
	var el: Vector2 = arm[1]
	var ha: Vector2 = arm[2]
	var as_m: float = met["arm_scale"]
	var muneca := el.lerp(ha, 0.80)
	var dir_m := (ha - el).normalized()
	var perp_m := Vector2(-dir_m.y, dir_m.x)

	var r_sh := (8.4 if esta_ducha else 9.0) * as_m
	var r_el := (7.6 if esta_ducha else 8.2) * as_m
	var r_wr := (6.4 if esta_ducha else 7.0) * as_m

	var sin_manga := esta_ducha or ropa_sup == "top"
	var manga_corta := (not sin_manga) and (ropa_sup == "camiseta")
	var manga_remangada := (not sin_manga) and (ropa_sup == "camisa")

	if sin_manga:
		_dibujar_extremidad_continua(sh, el, muneca, r_sh * 0.92, r_el * 0.90, r_wr * 0.88, piel, piel_sombra, grosor * 0.88)
	elif manga_corta:
		_dibujar_extremidad_continua(sh, el, muneca, r_sh * 0.92, r_el * 0.88, r_wr * 0.88, piel, piel_sombra, grosor * 0.86)
		var fin_manga := sh.lerp(el, 0.72)
		var mid_m := sh.lerp(fin_manga, 0.5)
		_dibujar_extremidad_continua(sh, mid_m, fin_manga, r_sh, r_sh * 0.96, r_el * 1.04, ropa, ropa.darkened(0.20), grosor * 0.90)
	elif manga_remangada:
		_dibujar_extremidad_continua(sh, el, muneca, r_sh * 0.92, r_el * 0.88, r_wr * 0.88, piel, piel_sombra, grosor * 0.86)
		var fin_cam := el.lerp(muneca, 0.36)
		_dibujar_extremidad_continua(sh, el, fin_cam, r_sh, r_el * 1.02, r_el * 0.96, ropa, ropa.darkened(0.18), grosor * 0.90)
		var d_c := (fin_cam - el).normalized()
		var p_c := Vector2(-d_c.y, d_c.x)
		var doblez := PackedVector2Array([
			fin_cam - d_c * 3.5 + p_c * (r_el * 1.05),
			fin_cam + d_c * 2.5 + p_c * (r_el * 1.02),
			fin_cam + d_c * 2.5 - p_c * (r_el * 1.02),
			fin_cam - d_c * 3.5 - p_c * (r_el * 1.05),
		])
		_poligono_tinta(doblez, ropa.lightened(0.12), grosor * 0.72)
	else:
		var col_b := ropa.darkened(0.06) if ropa_sup == "chaqueta" else ropa
		var col_s := col_b.darkened(0.22)
		_dibujar_extremidad_continua(sh, el, muneca, r_sh, r_el, r_wr, col_b, col_s, grosor * 0.90)
		var col_puno := col_b.darkened(0.24) if ropa_sup == "chaqueta" else col_s
		var puno := PackedVector2Array([
			muneca - dir_m * 3.0 + perp_m * (r_wr + 0.8),
			muneca + dir_m * 3.0 + perp_m * (r_wr + 0.4),
			muneca + dir_m * 3.0 - perp_m * (r_wr + 0.4),
			muneca - dir_m * 3.0 - perp_m * (r_wr + 0.8),
		])
		_poligono_tinta(puno, col_puno, grosor * 0.74)

	# Traje de astronauta: banda naranja en el brazo.
	if estilo == "astronauta" and not esta_ducha:
		var p_banda := sh.lerp(el, 0.34)
		var d_banda := (el - sh).normalized()
		var perp_banda := Vector2(-d_banda.y, d_banda.x)
		var r_banda := lerpf(r_sh, r_el, 0.34) + 0.6
		draw_line(p_banda - perp_banda * r_banda, p_banda + perp_banda * r_banda,
			color_extra, 3.4, true)
		draw_line(p_banda - perp_banda * r_banda + Vector2(0.0, 3.0),
			p_banda + perp_banda * r_banda + Vector2(0.0, 3.0),
			color_extra.darkened(0.18), 1.6, true)

	_dibujar_mano(ha, dir_m, piel, piel_sombra, tipo_mano, grosor)


func _dibujar_extremidad_continua(p0: Vector2, p1: Vector2, p2: Vector2, r0: float, r1: float, r2: float,
		relleno: Color, sombra: Color, grosor: float) -> void:
	var d0 := (p1 - p0).normalized()
	var d1 := (p2 - p1).normalized()
	var n0 := Vector2(-d0.y, d0.x)
	var n1 := Vector2(-d1.y, d1.x)
	var n_mid := (n0 + n1)
	if n_mid.length() < 0.01:
		n_mid = n0
	else:
		n_mid = n_mid.normalized()

	var lado_b := PackedVector2Array([
		p2 - n1 * r2,
		p1 - n_mid * r1,
		p0 - n0 * r0,
	])

	var contorno := PackedVector2Array()
	for i in range(6):
		var a := atan2(n0.y, n0.x) + PI * float(i) / 5.0
		contorno.append(p0 + Vector2(cos(a), sin(a)) * r0)
	contorno.append(p1 - n_mid * r1)
	for i in range(6):
		var a := atan2(-n1.y, -n1.x) + PI * float(i) / 5.0
		contorno.append(p2 + Vector2(cos(a), sin(a)) * r2)
	contorno.append(p1 + n_mid * r1)

	if not Geometry2D.triangulate_polygon(contorno).is_empty():
		draw_colored_polygon(contorno, relleno)
	var som := PackedVector2Array([p0, p1, p2, lado_b[0], lado_b[1], lado_b[2]])
	if not Geometry2D.triangulate_polygon(som).is_empty():
		draw_colored_polygon(som, Color(sombra, 0.40))

	var cerrado := PackedVector2Array(contorno)
	cerrado.append(contorno[0])
	draw_polyline(cerrado, TINTA, grosor, true)


func _dibujar_mano(pos: Vector2, dir: Vector2, piel: Color, piel_sombra: Color, tipo: String, grosor: float) -> void:
	match tipo:
		"puno":
			draw_circle(pos, 9.6, piel, true, -1.0, true)
			draw_arc(pos, 9.6, 0.0, TAU, 24, TINTA, grosor * 0.88, true)
			draw_line(pos + Vector2(-4.8, -1.8), pos + Vector2(3.6, -1.8), piel_sombra, 2.0, true)
			draw_arc(pos + Vector2(3.0, 1.0), 4.0, -0.3, PI * 0.9, 10, TINTA, grosor * 0.68, true)
		"mejilla_l", "mejilla_r":
			var lado := -1.0 if tipo == "mejilla_l" else 1.0
			var palma := _elipse_pts(pos, 7.0, 10.6, 18, lado * -0.15)
			_poligono_tinta(palma, piel, grosor * 0.82)
			for i in range(-1, 2):
				var y := pos.y - 5.0 + float(i) * 3.2
				draw_line(Vector2(pos.x - 3.2 * lado, y), Vector2(pos.x + 2.2 * lado, y - 1.0), Color(TINTA, 0.72), 1.4, true)
		"sostener":
			var mano_s := _elipse_pts(pos + Vector2(2.5, 2.0), 10.2, 6.2, 18, 0.0)
			_poligono_tinta(mano_s, piel, grosor * 0.82)
		_:
			var ang := atan2(dir.y, dir.x)
			var palma := _elipse_pts(pos, 8.6, 6.8, 18, ang)
			_poligono_tinta(palma, piel, grosor * 0.82)
			var pulgar := pos + Vector2(cos(ang - 1.05), sin(ang - 1.05)) * 7.6
			draw_circle(pulgar, 3.3, piel, true, -1.0, true)
			draw_arc(pulgar, 3.3, 0.0, TAU, 12, TINTA, grosor * 0.70, true)


func _dibujar_torso(es_mujer: bool, met: Dictionary, ropa_sup: String, ropa: Color,
		piel: Color, piel_sombra: Color, esta_ducha: bool, grosor: float) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var nw: float = met["nw"]

	if esta_ducha:
		var hombros := _suavizar_cerrado(PackedVector2Array([
			Vector2(-nw, 43.0), Vector2(nw, 43.0), Vector2(sh_x, 53.0),
			Vector2(sh_x, 120.0), Vector2(-sh_x, 120.0), Vector2(-sh_x, 53.0),
		]), 4)
		_poligono_tinta(hombros, piel, grosor * 0.92)
		_dibujar_cuello(nw, piel, piel_sombra, grosor, true)
		return

	var ropa_sombra := ropa.darkened(0.22)
	var ropa_brillo := ropa.lightened(0.16)

	var torso_ctrl := PackedVector2Array([
		Vector2(-13.5, 44.0),
		Vector2(13.5, 44.0),
		Vector2(sh_x, 53.0),
		Vector2(sh_x + 1.5, 69.0),
		Vector2(waist_x, 99.0),
		Vector2(hip_x, 124.0),
		Vector2(0.0, 128.0),
		Vector2(-hip_x, 124.0),
		Vector2(-waist_x, 99.0),
		Vector2(-sh_x - 1.5, 69.0),
		Vector2(-sh_x, 53.0),
	])
	var torso := _suavizar_cerrado(torso_ctrl, 4)

	if ropa_sup == "top":
		# Hombros y parte superior de piel continuos sin escalones + top encima
		var hombros_t := _suavizar_cerrado(PackedVector2Array([
			Vector2(-nw, 42.0), Vector2(nw, 42.0),
			Vector2(sh_x - 1.0, 53.0), Vector2(sh_x - 1.0, 68.0),
			Vector2(waist_x, 96.0), Vector2(-waist_x, 96.0),
			Vector2(-sh_x + 1.0, 68.0), Vector2(-sh_x + 1.0, 53.0),
		]), 4)
		_poligono_tinta(hombros_t, piel, grosor * 0.90)
		_dibujar_cuello(nw, piel, piel_sombra, grosor, true)

		var top_p := _suavizar_cerrado(PackedVector2Array([
			Vector2(-18.5, 48.0), Vector2(-12.5, 47.0), Vector2(-10.5, 61.0),
			Vector2(0.0, 64.5), Vector2(10.5, 61.0), Vector2(12.5, 47.0),
			Vector2(18.5, 48.0), Vector2(waist_x + 2.0, 74.0), Vector2(waist_x, 100.0),
			Vector2(hip_x, 124.0), Vector2(0.0, 127.0), Vector2(-hip_x, 124.0),
			Vector2(-waist_x, 100.0), Vector2(-waist_x - 2.0, 74.0),
		]), 3)
		_poligono_tinta(top_p, ropa, grosor * 0.92)
		draw_line(Vector2(waist_x - 3.0, 74.0), Vector2(hip_x - 4.0, 122.0), Color(ropa_sombra, 0.55), 3.0, true)
		return

	# Base del torso vestido
	_poligono_tinta(torso, ropa, grosor * 0.95)

	# Sombra cel-shading lateral derecha y brillo en hombro izquierdo
	var sombra_ctrl := PackedVector2Array([
		Vector2(13.0, 48.0),
		Vector2(sh_x - 2.0, 56.0),
		Vector2(sh_x - 0.5, 69.0),
		Vector2(waist_x - 2.0, 99.0),
		Vector2(hip_x - 2.0, 123.0),
		Vector2(10.0, 125.0),
		Vector2(15.0, 95.0),
		Vector2(16.0, 67.0),
	])
	draw_colored_polygon(_suavizar_cerrado(sombra_ctrl, 3), Color(ropa_sombra, 0.65))
	draw_line(Vector2(-sh_x + 7.0, 56.0), Vector2(-17.0, 50.0), Color(ropa_brillo, 0.8), 2.8, true)

	match ropa_sup:
		"camiseta":
			_dibujar_cuello(nw, piel, piel_sombra, grosor, true)
			# Escote redondo limpio y ribete
			var esc_c := _suavizar_cerrado(PackedVector2Array([
				Vector2(-12.5, 44.5), Vector2(0.0, 56.5), Vector2(12.5, 44.5),
				Vector2(15.2, 49.0), Vector2(0.0, 62.0), Vector2(-15.2, 49.0),
			]), 3)
			_poligono_tinta(esc_c, ropa_sombra, grosor * 0.65)
			var esc_piel := _suavizar_cerrado(PackedVector2Array([
				Vector2(-12.0, 42.5), Vector2(12.0, 42.5), Vector2(11.0, 49.0),
				Vector2(0.0, 56.0), Vector2(-11.0, 49.0),
			]), 3)
			draw_colored_polygon(esc_piel, piel)
			var borde_esc := _suavizar_abierta(PackedVector2Array([
				Vector2(-12.0, 44.5), Vector2(-7.0, 52.5), Vector2(0.0, 56.0),
				Vector2(7.0, 52.5), Vector2(12.0, 44.5),
			]), 4)
			draw_polyline(borde_esc, TINTA, grosor * 0.68, true)
			# Dobladillo inferior
			draw_line(Vector2(-hip_x + 3.0, 122.0), Vector2(hip_x - 3.0, 122.0), Color(ropa_sombra, 0.75), 2.0, true)

		"camisa":
			_dibujar_cuello(nw, piel, piel_sombra, grosor, true)
			# Apertura V del cuello
			var v_piel := PackedVector2Array([
				Vector2(-9.5, 43.0), Vector2(9.5, 43.0), Vector2(0.0, 62.0),
			])
			draw_colored_polygon(v_piel, piel)
			# Solapas de camisa
			var sol_l := PackedVector2Array([
				Vector2(-12.0, 42.5), Vector2(-20.0, 53.0), Vector2(-5.5, 62.0), Vector2(0.0, 56.0),
			])
			var sol_r := PackedVector2Array([
				Vector2(12.0, 42.5), Vector2(20.0, 53.0), Vector2(5.5, 62.0), Vector2(0.0, 56.0),
			])
			_poligono_tinta(sol_l, ropa_brillo, grosor * 0.68)
			_poligono_tinta(sol_r, ropa_brillo, grosor * 0.68)
			# Tapeta central y botones
			draw_line(Vector2(0.0, 58.0), Vector2(0.0, 125.0), Color(TINTA, 0.65), 1.6, true)
			for by: float in [69.0, 84.0, 99.0, 114.0]:
				draw_circle(Vector2(0.0, by), 2.0, ropa_sombra, true, -1.0, true)
				draw_arc(Vector2(0.0, by), 2.0, 0.0, TAU, 10, Color(TINTA, 0.7), 1.1, true)
			# Bolsillo pectoral
			if not es_mujer:
				var bol := PackedVector2Array([Vector2(9.0, 68.0), Vector2(20.0, 68.0), Vector2(20.0, 80.0), Vector2(14.5, 83.0), Vector2(9.0, 80.0)])
				draw_polyline(bol, Color(TINTA, 0.55), 1.4, true)

		"chaqueta":
			# Camiseta blanca interior en el centro
			var tee := PackedVector2Array([
				Vector2(-11.0, 44.0), Vector2(11.0, 44.0),
				Vector2(9.0, 127.0), Vector2(-9.0, 127.0),
			])
			_poligono_tinta(tee, Color("#f8fafc"), grosor * 0.72)
			_dibujar_cuello(nw, piel, piel_sombra, grosor, false)
			# Solapas de la chaqueta abierta
			for lado: float in [-1.0, 1.0]:
				var sol_j := _suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 10.0, 43.5), Vector2(lado * 19.0, 48.0),
					Vector2(lado * 15.0, 66.0), Vector2(lado * 8.5, 62.0),
				]), 2)
				_poligono_tinta(sol_j, ropa_sombra, grosor * 0.7)
				draw_line(Vector2(lado * 9.0, 62.0), Vector2(lado * 9.0, 124.0), Color("#cbd5e1"), 2.0, true)
				draw_line(Vector2(lado * 14.0, 94.0), Vector2(lado * (waist_x - 3.0), 108.0), Color(TINTA, 0.55), 1.6, true)
			var dob_j := PackedVector2Array([
				Vector2(-hip_x + 1.0, 120.5), Vector2(-9.0, 120.5), Vector2(-9.0, 127.0), Vector2(-hip_x, 127.0),
			])
			var dob_jr := PackedVector2Array([
				Vector2(9.0, 120.5), Vector2(hip_x - 1.0, 120.5), Vector2(hip_x, 127.0), Vector2(9.0, 127.0),
			])
			_poligono_tinta(dob_j, ropa_sombra, grosor * 0.72)
			_poligono_tinta(dob_jr, ropa_sombra, grosor * 0.72)

		"jersey":
			_dibujar_cuello(nw, piel, piel_sombra, grosor, false)
			# Cuello alto de punto acanalado
			var cuello_j := _suavizar_cerrado(PackedVector2Array([
				Vector2(-nw - 2.0, 38.0), Vector2(nw + 2.0, 38.0),
				Vector2(nw + 4.5, 53.0), Vector2(0.0, 56.0), Vector2(-nw - 4.5, 53.0),
			]), 3)
			_poligono_tinta(cuello_j, ropa_sombra, grosor * 0.78)
			for rx_c: float in [-5.0, 0.0, 5.0]:
				draw_line(Vector2(rx_c, 41.0), Vector2(rx_c, 52.0), Color(TINTA, 0.30), 1.4, true)
			var dob_je := PackedVector2Array([
				Vector2(-hip_x + 1.0, 120.0), Vector2(hip_x - 1.0, 120.0),
				Vector2(hip_x, 127.5), Vector2(-hip_x, 127.5),
			])
			_poligono_tinta(dob_je, ropa_sombra, grosor * 0.72)

		_:
			# "sudadera" — rediseñada limpia y estilizada como vineta_1.png
			_dibujar_cuello(nw, piel, piel_sombra, grosor, false)
			var escote := PackedVector2Array([
				Vector2(-11.5, 44.5), Vector2(0.0, 55.0), Vector2(11.5, 44.5),
				Vector2(14.5, 50.0), Vector2(0.0, 61.5), Vector2(-14.5, 50.0),
			])
			_poligono_tinta(escote, Color.WHITE, grosor * 0.72)

			var cap_l := _suavizar_cerrado(PackedVector2Array([
				Vector2(-12.0, 42.5), Vector2(-23.5, 48.5), Vector2(-17.0, 59.5), Vector2(-3.5, 61.5)
			]), 3)
			var cap_r := _suavizar_cerrado(PackedVector2Array([
				Vector2(12.0, 42.5), Vector2(23.5, 48.5), Vector2(17.0, 59.5), Vector2(3.5, 61.5)
			]), 3)
			_poligono_tinta(cap_l, ropa_sombra, grosor * 0.74)
			_poligono_tinta(cap_r, ropa_sombra, grosor * 0.74)

			# Cordones estilizados de sudadera
			for lado: float in [-1.0, 1.0]:
				var x: float = lado * 7.6
				draw_line(Vector2(x, 59.5), Vector2(x + lado * 1.2, 83.0), TINTA, 3.8, true)
				draw_line(Vector2(x, 59.5), Vector2(x + lado * 1.2, 83.0), Color.WHITE, 2.0, true)
				draw_circle(Vector2(x + lado * 1.2, 84.2), 1.8, TINTA, true, -1.0, true)

			# Bolsillo canguro frontal sutil
			var bol_c := PackedVector2Array([
				Vector2(-waist_x * 0.65, 102.0), Vector2(waist_x * 0.65, 102.0),
				Vector2(hip_x * 0.75, 118.0), Vector2(-hip_x * 0.75, 118.0),
			])
			draw_colored_polygon(bol_c, Color(ropa_sombra, 0.35))
			draw_polyline(PackedVector2Array([bol_c[3], bol_c[0], bol_c[1], bol_c[2]]), Color(TINTA, 0.55), 1.5, true)

			var dob := PackedVector2Array([
				Vector2(-hip_x + 1.0, 121.0), Vector2(hip_x - 1.0, 121.0),
				Vector2(hip_x, 127.5), Vector2(-hip_x, 127.5),
			])
			_poligono_tinta(dob, ropa_sombra, grosor * 0.72)


func _dibujar_atuendo_encima(_es_mujer: bool, met: Dictionary, estilo: String, ropa: Color,
		ropa_sec: Color, ropa_det: Color, grosor: float, ropa_sup: String = "",
		detalle: String = "") -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var nw: float = met["nw"]
	var sombra := ropa.darkened(0.22)

	if estilo == "delantal":
		# Tirantes del delantal sobre los hombros.
		for lado: float in [-1.0, 1.0]:
			var tirante := _suavizar_cerrado(PackedVector2Array([
				Vector2(lado * 8.0, 43.0),
				Vector2(lado * 13.5, 44.0),
				Vector2(lado * 12.0, 66.0),
				Vector2(lado * 6.5, 66.0),
			]), 2)
			_poligono_tinta(tirante, ropa_sec, grosor * 0.66)

		# Peto principal del delantal.
		var peto := _suavizar_cerrado(PackedVector2Array([
			Vector2(-13.0, 64.0),
			Vector2(13.0, 64.0),
			Vector2(16.0, 119.0),
			Vector2(0.0, 123.0),
			Vector2(-16.0, 119.0),
		]), 3)
		_poligono_tinta(peto, ropa_sec, grosor * 0.78)
		draw_colored_polygon(_suavizar_cerrado(PackedVector2Array([
			Vector2(8.0, 68.0), Vector2(15.0, 70.0), Vector2(15.0, 118.0),
			Vector2(6.0, 120.0),
		]), 2), Color(ropa_sec.darkened(0.12), 0.55))

		# Cintura y lazada.
		draw_line(Vector2(-waist_x + 1.0, 100.0), Vector2(waist_x - 1.0, 100.0), ropa_det, 2.6, true)
		for lado: float in [-1.0, 1.0]:
			var nudo := Vector2(lado * (waist_x - 0.5), 101.0)
			draw_circle(nudo, 2.4, ropa_det, true, -1.0, true)
			draw_line(nudo, nudo + Vector2(lado * 8.0, 4.0), ropa_det, 2.0, true)
			draw_line(nudo, nudo + Vector2(lado * 7.0, -3.0), ropa_det, 2.0, true)

		# Bolsillo frontal con pespunte.
		var bolsillo := _suavizar_cerrado(PackedVector2Array([
			Vector2(-8.0, 94.0), Vector2(8.0, 94.0), Vector2(8.0, 110.0),
			Vector2(0.0, 112.5), Vector2(-8.0, 110.0),
		]), 2)
		draw_colored_polygon(bolsillo, ropa_sec.darkened(0.05))
		draw_polyline(PackedVector2Array([
			Vector2(-8.0, 94.0), Vector2(8.0, 94.0), Vector2(8.0, 110.0),
			Vector2(0.0, 112.5), Vector2(-8.0, 110.0), Vector2(-8.0, 94.0),
		]), Color(ropa_det, 0.85), 1.8, true)
		draw_line(Vector2(-6.0, 106.0), Vector2(-2.0, 106.0), Color(ropa_det, 0.7), 1.2, true)
		draw_line(Vector2(2.0, 106.0), Vector2(6.0, 106.0), Color(ropa_det, 0.7), 1.2, true)
		return

	if estilo in ["casual", "deportivo", "verano", "invierno", "traje", "bata",
			"mono", "camarero", "pijama", "fiesta", "futbol", "cuero",
			"astronauta", "vestido"]:
		match estilo:
			"casual":
				_dibujar_detalles_casual(met, ropa, ropa_sec, ropa_det, grosor, ropa_sup, detalle)
			"deportivo":
				_dibujar_detalles_deportivo(met, ropa, ropa_sec, ropa_det, grosor)
			"verano":
				_dibujar_detalles_verano(met, ropa, ropa_sec, ropa_det, grosor)
			"invierno":
				_dibujar_detalles_invierno(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"traje":
				_dibujar_detalles_traje(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"bata":
				_dibujar_detalles_bata(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"mono":
				_dibujar_detalles_mono(met, ropa, ropa_sec, ropa_det, grosor)
			"camarero":
				_dibujar_detalles_camarero(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"pijama":
				_dibujar_detalles_pijama(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"fiesta":
				_dibujar_detalles_fiesta(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"futbol":
				_dibujar_detalles_futbol(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"cuero":
				_dibujar_detalles_cuero(met, ropa, ropa_sec, ropa_det, grosor)
			"astronauta":
				_dibujar_detalles_astronauta(met, ropa, ropa_sec, ropa_det, grosor, detalle)
			"vestido":
				_dibujar_detalles_vestido(met, ropa, ropa_sec, ropa_det, grosor, detalle)
		return

	# Chaquetas de chef, gala y Michelin: cubrimos la prenda base y dibujamos
	# el frente de doble botonadura con su cuello y detalles.
	var cubierta := _suavizar_cerrado(PackedVector2Array([
		Vector2(-13.5, 43.5),
		Vector2(-7.0, 44.0),
		Vector2(0.0, 58.0),
		Vector2(7.0, 44.0),
		Vector2(13.5, 43.5),
		Vector2(sh_x, 53.0),
		Vector2(sh_x + 1.0, 70.0),
		Vector2(waist_x, 99.0),
		Vector2(hip_x, 124.0),
		Vector2(0.0, 128.0),
		Vector2(-hip_x, 124.0),
		Vector2(-waist_x, 99.0),
		Vector2(-sh_x - 1.0, 70.0),
		Vector2(-sh_x, 53.0),
	]), 4)
	_poligono_tinta(cubierta, ropa, grosor * 0.82)

	# Sombra lateral y brillo de hombro para dar volumen a la chaqueta.
	draw_colored_polygon(_suavizar_cerrado(PackedVector2Array([
		Vector2(11.0, 48.0), Vector2(sh_x - 2.0, 56.0), Vector2(sh_x - 0.5, 70.0),
		Vector2(waist_x - 2.0, 99.0), Vector2(hip_x - 2.0, 123.0),
		Vector2(9.0, 126.0), Vector2(13.0, 96.0), Vector2(14.0, 67.0),
	]), 3), Color(sombra, 0.55))
	draw_line(Vector2(-sh_x + 7.0, 56.0), Vector2(-17.0, 50.0), Color(ropa.lightened(0.15), 0.8), 2.6, true)

	# Cuello de la chaqueta.
	var cuello := PackedVector2Array([
		Vector2(-nw - 1.5, 41.5),
		Vector2(nw + 1.5, 41.5),
		Vector2(nw + 2.0, 48.0),
		Vector2(0.0, 53.0),
		Vector2(-nw - 2.0, 48.0),
	])
	_poligono_tinta(cuello, ropa, grosor * 0.66)

	var es_gala := (estilo == "gala")
	var es_michelin := (estilo == "michelin")
	var es_chef := (estilo == "chef")

	if es_chef:
		# Pañuelo rojo anudado al cuello.
		var panuelo := PackedVector2Array([
			Vector2(-7.0, 45.0), Vector2(7.0, 45.0), Vector2(0.0, 59.0),
		])
		_poligono_tinta(panuelo, ropa_sec, grosor * 0.55)
		draw_circle(Vector2(0.0, 55.5), 2.8, ropa_sec.darkened(0.16), true, -1.0, true)
		draw_arc(Vector2(0.0, 55.5), 2.8, 0.0, TAU, 12, Color(TINTA, 0.65), 1.0, true)
	elif es_gala:
		# Ascot blanco con alfiler dorado.
		var ascot := _suavizar_cerrado(PackedVector2Array([
			Vector2(-7.5, 44.0), Vector2(7.5, 44.0), Vector2(4.0, 58.0),
			Vector2(0.0, 63.0), Vector2(-4.0, 58.0),
		]), 2)
		_poligono_tinta(ascot, ropa_sec, grosor * 0.55)
		draw_circle(Vector2(0.0, 55.0), 2.2, ropa_det, true, -1.0, true)
		draw_arc(Vector2(0.0, 55.0), 2.2, 0.0, TAU, 10, Color(TINTA, 0.6), 1.0, true)
	else:
		# Camisa blanca en V y pajarita dorada (Michelin).
		var camisa_v := PackedVector2Array([
			Vector2(-8.5, 44.0), Vector2(8.5, 44.0), Vector2(0.0, 63.0),
		])
		draw_colored_polygon(camisa_v, ropa_sec)
		draw_polyline(PackedVector2Array([
			Vector2(-8.5, 44.0), Vector2(0.0, 63.0), Vector2(8.5, 44.0),
		]), Color(TINTA, 0.55), 1.4, true)
		var lazo_l := PackedVector2Array([
			Vector2(-1.2, 53.0), Vector2(-9.0, 49.5), Vector2(-9.0, 55.5),
		])
		var lazo_r := PackedVector2Array([
			Vector2(1.2, 53.0), Vector2(9.0, 49.5), Vector2(9.0, 55.5),
		])
		draw_colored_polygon(lazo_l, ropa_det)
		draw_colored_polygon(lazo_r, ropa_det)
		draw_circle(Vector2(0.0, 52.8), 2.4, ropa_det.darkened(0.10), true, -1.0, true)
		draw_arc(Vector2(0.0, 52.8), 2.4, 0.0, TAU, 10, Color(TINTA, 0.55), 1.0, true)

	# Botonadura doble y galones según el atuendo.
	var color_boton := ropa_det
	var radio_boton := 2.2 if es_chef else 2.5
	var ys_botones := [72.0, 86.0, 100.0, 114.0] if es_chef else [72.0, 90.0, 108.0]
	for y in ys_botones:
		for lado: float in [-1.0, 1.0]:
			var p := Vector2(lado * 5.4, y)
			draw_circle(p, radio_boton, color_boton, true, -1.0, true)
			draw_arc(p, radio_boton, 0.0, TAU, 12, Color(TINTA, 0.62), 1.0, true)

	if es_gala or es_michelin:
		# Galones dorados en el borde de la solapa y bajo la chaqueta.
		draw_polyline(PackedVector2Array([
			Vector2(-7.0, 44.0), Vector2(0.0, 58.0), Vector2(7.0, 44.0),
		]), color_boton, 2.0, true)
		for lado: float in [-1.0, 1.0]:
			draw_line(Vector2(lado * 10.5, 62.0), Vector2(lado * (waist_x - 3.0), 99.0),
				Color(color_boton, 0.8), 1.6, true)
		draw_line(Vector2(-hip_x + 3.0, 123.0), Vector2(hip_x - 3.0, 123.0),
			Color(color_boton, 0.85), 2.0, true)

	if es_gala:
		# Hombreras doradas y pañuelo de bolsillo.
		for lado: float in [-1.0, 1.0]:
			var hombrera := _suavizar_cerrado(PackedVector2Array([
				Vector2(lado * (sh_x - 8.0), 54.0),
				Vector2(lado * (sh_x - 0.5), 55.5),
				Vector2(lado * (sh_x - 1.0), 60.0),
				Vector2(lado * (sh_x - 8.0), 58.5),
			]), 2)
			_poligono_tinta(hombrera, ropa_det, grosor * 0.5)

	if es_michelin:
		# Solapas de satén y fajín dorado.
		for lado: float in [-1.0, 1.0]:
			var solapa := _suavizar_cerrado(PackedVector2Array([
				Vector2(lado * 11.5, 47.0),
				Vector2(lado * 3.4, 60.0),
				Vector2(lado * 4.0, 98.0),
				Vector2(lado * 9.5, 110.0),
				Vector2(lado * 13.0, 66.0),
			]), 3)
			_poligono_tinta(solapa, ropa.lightened(0.10), grosor * 0.55)
		var fajin := PackedVector2Array([
			Vector2(-hip_x * 0.90, 113.0), Vector2(hip_x * 0.90, 113.0),
			Vector2(hip_x * 0.86, 120.0), Vector2(-hip_x * 0.86, 120.0),
		])
		draw_colored_polygon(fajin, Color(color_boton, 0.92))
		draw_line(Vector2(0.0, 113.0), Vector2(0.0, 120.0), Color(TINTA, 0.35), 1.2, true)
		# Estrella Michelin en el pecho.
		var estrella := _puntos_estrella(Vector2(-15.0, 82.0), 8.5, 3.7, 5)
		draw_colored_polygon(estrella, color_boton)
		var estrella_cerrada := PackedVector2Array(estrella)
		estrella_cerrada.append(estrella[0])
		draw_polyline(estrella_cerrada, Color(TINTA, 0.55), 1.2, true)
		draw_circle(Vector2(-15.0, 82.0), 1.6, Color.WHITE, true, -1.0, true)


func _dibujar_detalles_casual(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _ropa_sup: String, detalle: String) -> void:
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]

	if detalle == "cuadros":
		for x: float in [-18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0]:
			draw_line(Vector2(x, 58.0), Vector2(x, 122.0), Color(ropa_sec, 0.62), 1.5, true)
		for y: float in [64.0, 76.0, 88.0, 100.0, 112.0, 122.0]:
			draw_line(Vector2(-18.0, y), Vector2(18.0, y), Color(ropa_sec, 0.62), 1.5, true)
		draw_line(Vector2(0.0, 58.0), Vector2(0.0, 124.0), Color(ropa_det, 0.75), 1.6, true)
		for by: float in [70.0, 86.0, 102.0, 118.0]:
			draw_circle(Vector2(0.0, by), 1.7, ropa_det, true, -1.0, true)
		var bolsillo := PackedVector2Array([
			Vector2(-15.0, 74.0), Vector2(-8.0, 73.0), Vector2(-8.0, 84.0),
			Vector2(-11.5, 87.0), Vector2(-15.0, 84.0),
		])
		draw_polyline(PackedVector2Array([bolsillo[0], bolsillo[1], bolsillo[2], bolsillo[3], bolsillo[4], bolsillo[0]]),
			Color(ropa_det, 0.55), 1.3, true)
		return

	if detalle == "universidad":
		var escudo := _suavizar_cerrado(PackedVector2Array([
			Vector2(-20.0, 68.0), Vector2(-10.0, 66.0), Vector2(-10.0, 82.0),
			Vector2(-15.0, 89.0), Vector2(-20.0, 82.0),
		]), 2)
		_poligono_tinta(escudo, ropa_sec, grosor * 0.55)
		draw_line(Vector2(-18.0, 73.0), Vector2(-12.0, 73.0), ropa_det, 1.4, true)
		draw_line(Vector2(-17.0, 78.0), Vector2(-13.0, 78.0), ropa_det, 1.2, true)
		draw_line(Vector2(-16.0, 83.0), Vector2(-14.0, 83.0), ropa_det, 1.2, true)
		draw_line(Vector2(-waist_x + 2.0, 106.0), Vector2(waist_x - 2.0, 106.0),
			Color(ropa_sec, 0.78), 2.6, true)
		return

	# Camiseta básica: bolsillo sutil y costura inferior.
	var bol := PackedVector2Array([
		Vector2(-15.0, 73.0), Vector2(-8.0, 72.0), Vector2(-8.0, 83.0),
		Vector2(-11.5, 86.0), Vector2(-15.0, 83.0),
	])
	draw_polyline(PackedVector2Array([bol[0], bol[1], bol[2], bol[3], bol[4], bol[0]]),
		Color(ropa_det, 0.42), 1.2, true)
	draw_line(Vector2(-hip_x + 3.0, 122.0), Vector2(hip_x - 3.0, 122.0),
		Color(ropa.darkened(0.14), 0.7), 1.5, true)


func _dibujar_detalles_deportivo(met: Dictionary, _ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float) -> void:
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]

	# Cremallera central.
	draw_line(Vector2(0.0, 57.0), Vector2(0.0, 122.0), ropa_det, 2.2, true)
	for y: float in range(64, 120, 8):
		draw_line(Vector2(-1.7, float(y)), Vector2(1.7, float(y)), Color(ropa_det, 0.65), 1.0, true)

	# Franjas deportivas en los hombros.
	for lado: float in [-1.0, 1.0]:
		var franja := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 9.0, 45.0),
			Vector2(lado * 16.0, 50.0),
			Vector2(lado * 9.0, 70.0),
			Vector2(lado * 3.5, 67.0),
		]), 2)
		draw_colored_polygon(franja, ropa_sec)

	# Escudo deportivo en el pecho.
	var centro := Vector2(-15.0, 82.0)
	draw_circle(centro, 5.2, ropa_sec, true, -1.0, true)
	draw_arc(centro, 5.2, 0.0, TAU, 16, Color(TINTA, 0.55), 1.0, true)
	var estrella := _puntos_estrella(centro, 3.5, 1.5, 5)
	draw_colored_polygon(estrella, ropa_det)

	# Cintura elástica y puños.
	draw_line(Vector2(-waist_x, 99.0), Vector2(waist_x, 99.0), Color(ropa_det, 0.45), 1.5, true)
	draw_line(Vector2(-hip_x + 2.0, 121.0), Vector2(hip_x - 2.0, 121.0),
		Color(ropa_sec, 0.55), 2.2, true)


func _dibujar_detalles_verano(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float) -> void:
	var waist_x: float = met["waist_x"]

	# Cordón de la cintura.
	draw_line(Vector2(-waist_x + 2.0, 98.0), Vector2(waist_x - 2.0, 98.0), ropa_det, 2.4, true)
	for lado: float in [-1.0, 1.0]:
		var nudo := Vector2(lado * 4.5, 100.0)
		draw_circle(nudo, 1.8, ropa_det, true, -1.0, true)
		draw_line(nudo, nudo + Vector2(lado * 3.0, 10.0), ropa_det, 1.8, true)

	# Franja diagonal y sol estampado.
	var franja := _suavizar_cerrado(PackedVector2Array([
		Vector2(-16.0, 58.0), Vector2(-10.0, 57.0), Vector2(15.0, 92.0),
		Vector2(9.0, 95.0),
	]), 2)
	draw_colored_polygon(franja, Color(ropa_sec, 0.88))
	var sol := Vector2(13.0, 72.0)
	draw_circle(sol, 4.2, ropa_sec, true, -1.0, true)
	for i in range(8):
		var a := TAU * float(i) / 8.0
		draw_line(sol + Vector2(cos(a), sin(a)) * 5.2, sol + Vector2(cos(a), sin(a)) * 7.2,
			Color(ropa_sec, 0.9), 1.2, true)
	draw_circle(sol, 2.0, ropa_det, true, -1.0, true)

	# Vuelta del bajo y bolsillo.
	draw_line(Vector2(-met["hip_x"] + 2.0, 121.0), Vector2(met["hip_x"] - 2.0, 121.0),
		Color(ropa.darkened(0.16), 0.7), 1.5, true)
	draw_line(Vector2(-15.0, 78.0), Vector2(-8.0, 77.0), Color(ropa_det, 0.55), 1.2, true)


func _dibujar_detalles_invierno(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]

	if detalle == "abrigo":
		# Abrigo largo de paño con solapas, cinturón y doble botonadura.
		for lado: float in [-1.0, 1.0]:
			var panel := _suavizar_cerrado(PackedVector2Array([
				Vector2(lado * 12.0, 43.5),
				Vector2(lado * sh_x, 53.0),
				Vector2(lado * (waist_x + 2.0), 100.0),
				Vector2(lado * (hip_x + 2.0), 156.0),
				Vector2(lado * 5.0, 158.0),
				Vector2(lado * 6.0, 102.0),
				Vector2(lado * 6.0, 58.0),
				Vector2(lado * 9.0, 46.0),
			]), 3)
			_poligono_tinta(panel, ropa_sec, grosor * 0.82)
			var solapa := PackedVector2Array([
				Vector2(lado * 7.0, 44.0), Vector2(lado * 12.0, 43.5),
				Vector2(lado * 8.0, 64.0), Vector2(lado * 4.0, 58.0),
			])
			_poligono_tinta(solapa, ropa_sec.lightened(0.14), grosor * 0.55)

		draw_line(Vector2(-waist_x - 1.0, 112.0), Vector2(waist_x + 1.0, 112.0),
			ropa_sec.darkened(0.32), 4.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-4.0, 109.0), Vector2(4.0, 109.0), Vector2(4.0, 115.0), Vector2(-4.0, 115.0),
		]), ropa_det)
		for y: float in [72.0, 88.0, 104.0, 124.0, 140.0]:
			for lado: float in [-1.0, 1.0]:
				draw_circle(Vector2(lado * 7.0, y), 2.0, ropa_det, true, -1.0, true)
		# Bolsillos.
		for lado: float in [-1.0, 1.0]:
			draw_line(Vector2(lado * 13.0, 126.0), Vector2(lado * 20.0, 126.0),
				Color(ropa_sec.darkened(0.3), 0.8), 1.6, true)
		# Bufanda roja sobre el cuello, con dos caídas y flecos.
		var bufanda := _suavizar_cerrado(PackedVector2Array([
			Vector2(-14.0, 42.5), Vector2(14.0, 42.5), Vector2(15.5, 51.0),
			Vector2(8.0, 57.0), Vector2(0.0, 54.0), Vector2(-8.0, 57.0), Vector2(-15.5, 51.0),
		]), 3)
		_poligono_tinta(bufanda, ropa_det, grosor * 0.62)
		var cola_l := PackedVector2Array([
			Vector2(-12.0, 50.0), Vector2(-5.0, 51.0), Vector2(-8.0, 82.0), Vector2(-15.0, 80.0),
		])
		var cola_r := PackedVector2Array([
			Vector2(7.0, 51.0), Vector2(12.0, 50.0), Vector2(16.0, 72.0), Vector2(10.0, 74.0),
		])
		_poligono_tinta(cola_l, ropa_det.darkened(0.06), grosor * 0.55)
		_poligono_tinta(cola_r, ropa_det.darkened(0.04), grosor * 0.55)
		for i in range(3):
			draw_line(Vector2(-14.0 + i * 2.2, 80.0), Vector2(-14.5 + i * 2.2, 85.0),
				Color(ropa_det.darkened(0.28), 0.8), 1.2, true)
			draw_line(Vector2(11.0 + i * 1.6, 72.0), Vector2(11.5 + i * 1.6, 76.0),
				Color(ropa_det.darkened(0.28), 0.8), 1.2, true)
		return

	# Jersey de punto con bufanda y textura de trenza.
	var bufanda := _suavizar_cerrado(PackedVector2Array([
		Vector2(-13.5, 43.0), Vector2(13.5, 43.0), Vector2(15.0, 51.0),
		Vector2(8.0, 56.5), Vector2(0.0, 53.0), Vector2(-8.0, 56.5), Vector2(-15.0, 51.0),
	]), 3)
	_poligono_tinta(bufanda, ropa_sec, grosor * 0.62)
	var cola_1 := PackedVector2Array([
		Vector2(8.0, 51.0), Vector2(13.0, 50.0), Vector2(17.0, 82.0), Vector2(11.0, 84.0),
	])
	var cola_2 := PackedVector2Array([
		Vector2(-8.0, 51.0), Vector2(-3.0, 52.0), Vector2(-5.0, 72.0), Vector2(-10.0, 70.0),
	])
	_poligono_tinta(cola_1, ropa_sec.darkened(0.08), grosor * 0.55)
	_poligono_tinta(cola_2, ropa_sec.darkened(0.05), grosor * 0.55)
	for i in range(3):
		draw_line(Vector2(11.0 + i * 1.6, 82.0), Vector2(11.5 + i * 1.6, 87.0),
			Color(ropa_sec.darkened(0.28), 0.8), 1.2, true)
		draw_line(Vector2(-9.0 + i * 1.6, 70.0), Vector2(-9.5 + i * 1.6, 75.0),
			Color(ropa_sec.darkened(0.28), 0.8), 1.2, true)
	for x: float in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		draw_line(Vector2(x, 64.0), Vector2(x, 118.0), Color(ropa.darkened(0.13), 0.5), 1.4, true)
	for y: float in [72.0, 88.0, 104.0]:
		draw_line(Vector2(-waist_x + 3.0, y), Vector2(waist_x - 3.0, y),
			Color(ropa.darkened(0.10), 0.35), 1.2, true)


func _dibujar_detalles_traje(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var blazer := ropa_sec

	for lado: float in [-1.0, 1.0]:
		var panel := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 12.5, 43.5),
			Vector2(lado * sh_x, 53.0),
			Vector2(lado * (waist_x + 2.0), 100.0),
			Vector2(lado * (hip_x + 1.0), 128.0),
			Vector2(lado * 4.5, 130.0),
			Vector2(lado * 6.5, 102.0),
			Vector2(lado * 6.5, 60.0),
			Vector2(lado * 9.0, 46.0),
		]), 3)
		_poligono_tinta(panel, blazer, grosor * 0.82)
		var solapa := PackedVector2Array([
			Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
			Vector2(lado * 8.0, 64.0), Vector2(lado * 4.0, 58.0),
		])
		_poligono_tinta(solapa, blazer.lightened(0.14), grosor * 0.58)
		draw_line(Vector2(lado * 6.0, 76.0), Vector2(lado * 6.0, 126.0),
			Color(blazer.darkened(0.24), 0.6), 1.4, true)
		draw_circle(Vector2(lado * 6.2, 108.0), 1.9, ropa_det, true, -1.0, true)

	# Pañuelo de bolsillo.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16.0, 78.0), Vector2(-12.0, 76.0), Vector2(-13.0, 82.0),
	]), ropa_det.lightened(0.2))

	if detalle == "pajarita":
		for lado: float in [-1.0, 1.0]:
			var lazo := PackedVector2Array([
				Vector2(lado * 1.2, 53.0),
				Vector2(lado * 9.0, 49.5),
				Vector2(lado * 9.0, 56.5),
			])
			draw_colored_polygon(lazo, ropa_det)
		draw_circle(Vector2(0.0, 53.0), 2.4, ropa_det.darkened(0.10), true, -1.0, true)
		draw_arc(Vector2(0.0, 53.0), 2.4, 0.0, TAU, 10, Color(TINTA, 0.55), 1.0, true)
	else:
		var corbata := _suavizar_cerrado(PackedVector2Array([
			Vector2(-2.6, 49.0), Vector2(2.6, 49.0), Vector2(3.4, 91.0),
			Vector2(0.0, 98.0), Vector2(-3.4, 91.0),
		]), 2)
		_poligono_tinta(corbata, ropa_det, grosor * 0.55)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-3.6, 47.0), Vector2(3.6, 47.0), Vector2(2.6, 53.0), Vector2(-2.6, 53.0),
		]), ropa_det.darkened(0.10))


func _dibujar_detalles_bata(met: Dictionary, _ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var bata := ropa_sec

	for lado: float in [-1.0, 1.0]:
		var panel := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 12.0, 43.5),
			Vector2(lado * sh_x, 53.0),
			Vector2(lado * (waist_x + 2.0), 100.0),
			Vector2(lado * (hip_x + 3.0), 166.0),
			Vector2(lado * 5.0, 168.0),
			Vector2(lado * 6.5, 102.0),
			Vector2(lado * 6.5, 58.0),
			Vector2(lado * 9.0, 46.0),
		]), 3)
		_poligono_tinta(panel, bata, grosor * 0.82)
		var solapa := PackedVector2Array([
			Vector2(lado * 6.5, 44.0), Vector2(lado * 12.0, 43.5),
			Vector2(lado * 7.0, 66.0), Vector2(lado * 3.5, 59.0),
		])
		_poligono_tinta(solapa, bata.lightened(0.10), grosor * 0.55)

	# Botones y bolsillos.
	for y: float in [74.0, 92.0, 110.0, 128.0, 146.0]:
		draw_circle(Vector2(0.0, y), 2.0, ropa_det, true, -1.0, true)
	for lado: float in [-1.0, 1.0]:
		draw_line(Vector2(lado * 12.0, 120.0), Vector2(lado * 20.0, 120.0),
			Color(bata.darkened(0.22), 0.8), 1.5, true)
		draw_line(Vector2(lado * 12.0, 136.0), Vector2(lado * 20.0, 136.0),
			Color(bata.darkened(0.22), 0.8), 1.5, true)

	# Insignia y bolígrafo.
	var insignia := _suavizar_cerrado(PackedVector2Array([
		Vector2(-19.0, 76.0), Vector2(-11.0, 74.0), Vector2(-11.0, 88.0),
		Vector2(-15.0, 93.0), Vector2(-19.0, 88.0),
	]), 2)
	_poligono_tinta(insignia, ropa_det, grosor * 0.5)
	draw_circle(Vector2(-15.0, 81.0), 2.4, Color.WHITE, true, -1.0, true)
	draw_line(Vector2(-15.0, 78.0), Vector2(-15.0, 84.0), ropa_det, 1.4, true)
	draw_line(Vector2(-17.0, 81.0), Vector2(-13.0, 81.0), ropa_det, 1.4, true)
	draw_line(Vector2(-6.0, 118.0), Vector2(-4.0, 108.0), Color("#0f172a"), 2.0, true)


func _dibujar_detalles_mono(met: Dictionary, _ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float) -> void:
	var waist_x: float = met["waist_x"]

	var peto := _suavizar_cerrado(PackedVector2Array([
		Vector2(-13.0, 61.0), Vector2(13.0, 61.0), Vector2(16.0, 120.0),
		Vector2(0.0, 124.0), Vector2(-16.0, 120.0),
	]), 3)
	_poligono_tinta(peto, ropa_sec, grosor * 0.82)

	for lado: float in [-1.0, 1.0]:
		var tirante := PackedVector2Array([
			Vector2(lado * 7.0, 43.0), Vector2(lado * 11.0, 44.0),
			Vector2(lado * 14.0, 64.0), Vector2(lado * 10.0, 65.0),
		])
		_poligono_tinta(tirante, ropa_sec.darkened(0.08), grosor * 0.55)
		draw_circle(Vector2(lado * 12.0, 65.0), 2.2, ropa_det, true, -1.0, true)
		draw_line(Vector2(lado * (waist_x - 1.0), 105.0), Vector2(lado * 6.0, 104.0),
			Color(ropa_det, 0.85), 1.6, true)

	# Bolsillo del pecho y herramientas.
	var bolsillo := PackedVector2Array([
		Vector2(-8.0, 84.0), Vector2(8.0, 84.0), Vector2(8.0, 102.0),
		Vector2(0.0, 107.0), Vector2(-8.0, 102.0),
	])
	draw_colored_polygon(bolsillo, ropa_sec.darkened(0.06))
	draw_polyline(PackedVector2Array([bolsillo[0], bolsillo[1], bolsillo[2], bolsillo[3], bolsillo[4], bolsillo[0]]),
		Color(ropa_det, 0.75), 1.4, true)
	draw_line(Vector2(-4.0, 92.0), Vector2(4.0, 92.0), ropa_det, 1.4, true)
	draw_line(Vector2(-3.0, 96.0), Vector2(3.0, 96.0), ropa_det, 1.2, true)


func _dibujar_detalles_camarero(met: Dictionary, _ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]

	for lado: float in [-1.0, 1.0]:
		var panel := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 11.0, 43.5),
			Vector2(lado * sh_x, 53.0),
			Vector2(lado * (waist_x + 1.0), 102.0),
			Vector2(lado * 4.0, 104.0),
			Vector2(lado * 5.5, 61.0),
			Vector2(lado * 8.0, 46.0),
		]), 3)
		_poligono_tinta(panel, ropa_sec, grosor * 0.78)

	# V del chaleco y botones.
	draw_polyline(PackedVector2Array([
		Vector2(-8.0, 46.0), Vector2(0.0, 68.0), Vector2(8.0, 46.0),
	]), ropa_sec.lightened(0.18), 1.6, true)
	for y: float in [78.0, 90.0, 100.0]:
		draw_circle(Vector2(0.0, y), 1.9, ropa_sec.lightened(0.28), true, -1.0, true)

	# Pajarita roja.
	for lado: float in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(lado * 1.0, 53.0), Vector2(lado * 9.0, 49.5), Vector2(lado * 9.0, 56.5),
		]), ropa_det)
	draw_circle(Vector2(0.0, 53.0), 2.4, ropa_det.darkened(0.10), true, -1.0, true)
	draw_arc(Vector2(0.0, 53.0), 2.4, 0.0, TAU, 10, Color(TINTA, 0.55), 1.0, true)

	# Bloc de notas en el bolsillo.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18.0, 82.0), Vector2(-11.0, 80.0), Vector2(-10.0, 94.0), Vector2(-17.0, 96.0),
	]), Color("#f8fafc"))
	draw_polyline(PackedVector2Array([
		Vector2(-18.0, 82.0), Vector2(-11.0, 80.0), Vector2(-10.0, 94.0), Vector2(-17.0, 96.0), Vector2(-18.0, 82.0),
	]), Color(TINTA, 0.45), 1.1, true)
	for i in range(3):
		draw_line(Vector2(-17.0, 85.0 + i * 3.0), Vector2(-12.5, 84.2 + i * 3.0),
			Color("#64748b", 0.8), 1.0, true)


func _dibujar_detalles_pijama(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _detalle: String) -> void:
	var waist_x: float = met["waist_x"]

	# Tapeta y botones.
	draw_line(Vector2(0.0, 56.0), Vector2(0.0, 122.0), ropa_det, 2.2, true)
	for y: float in [68.0, 84.0, 100.0, 116.0]:
		draw_circle(Vector2(0.0, y), 1.9, ropa_det, true, -1.0, true)

	# Ribetes del cuello y bajo.
	draw_polyline(PackedVector2Array([
		Vector2(-11.0, 44.0), Vector2(0.0, 55.0), Vector2(11.0, 44.0),
	]), ropa_det, 1.8, true)
	draw_line(Vector2(-waist_x + 2.0, 121.0), Vector2(waist_x - 2.0, 121.0),
		Color(ropa_det, 0.85), 1.8, true)

	# Estrellas y luna.
	for p: Vector2 in [
		Vector2(-15.0, 74.0), Vector2(13.0, 88.0), Vector2(-9.0, 108.0),
		Vector2(16.0, 111.0), Vector2(5.0, 72.0), Vector2(-4.0, 92.0),
	]:
		var estrella := _puntos_estrella(p, 4.2, 1.8, 5)
		draw_colored_polygon(estrella, ropa_sec)
	draw_circle(Vector2(-17.0, 94.0), 5.4, ropa_sec, true, -1.0, true)
	draw_circle(Vector2(-15.0, 92.5), 4.5, ropa, true, -1.0, true)

	# Pespunte del pantalón y bolsillo.
	draw_line(Vector2(-15.0, 78.0), Vector2(-8.0, 77.0), Color(ropa_det, 0.65), 1.2, true)
	draw_circle(Vector2(waist_x - 5.0, 101.0), 1.6, ropa_det, true, -1.0, true)


func _dibujar_detalles_fiesta(met: Dictionary, _ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]

	for lado: float in [-1.0, 1.0]:
		var panel := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 12.5, 43.5),
			Vector2(lado * sh_x, 53.0),
			Vector2(lado * (waist_x + 2.0), 100.0),
			Vector2(lado * (hip_x + 1.0), 128.0),
			Vector2(lado * 4.5, 130.0),
			Vector2(lado * 6.5, 102.0),
			Vector2(lado * 6.5, 60.0),
			Vector2(lado * 9.0, 46.0),
		]), 3)
		_poligono_tinta(panel, ropa_sec, grosor * 0.82)
		var solapa := PackedVector2Array([
			Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
			Vector2(lado * 8.0, 66.0), Vector2(lado * 4.0, 59.0),
		])
		_poligono_tinta(solapa, ropa_sec.lightened(0.18), grosor * 0.58)
		draw_polyline(PackedVector2Array([
			Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
			Vector2(lado * 10.0, 126.0),
		]), ropa_det, 2.0, true)

	# Rayo en el pecho y lentejuelas.
	draw_colored_polygon(PackedVector2Array([
		Vector2(10.0, 62.0), Vector2(4.0, 88.0), Vector2(9.0, 88.0),
		Vector2(2.0, 120.0), Vector2(4.0, 94.0), Vector2(-1.0, 94.0),
	]), ropa_det)
	for p: Vector2 in [
		Vector2(-16.0, 70.0), Vector2(-12.0, 78.0), Vector2(-18.0, 86.0),
		Vector2(-10.0, 96.0), Vector2(-16.0, 108.0), Vector2(16.0, 74.0),
		Vector2(18.0, 92.0), Vector2(14.0, 112.0), Vector2(-4.0, 104.0),
	]:
		draw_circle(p, 1.7, Color(1, 1, 1, 0.9), true, -1.0, true)
		draw_circle(p + Vector2(1.2, 1.2), 1.0, Color(ropa_det, 0.85), true, -1.0, true)

	draw_line(Vector2(-hip_x + 3.0, 127.0), Vector2(hip_x - 3.0, 127.0), ropa_det, 1.6, true)


func _dibujar_detalles_futbol(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _detalle: String) -> void:
	var waist_x: float = met["waist_x"]

	# Cuello en V con ribete.
	_poligono_tinta(PackedVector2Array([
		Vector2(-10.0, 44.0), Vector2(10.0, 44.0), Vector2(0.0, 58.0),
	]), ropa_sec, grosor * 0.55)
	draw_polyline(PackedVector2Array([
		Vector2(-10.0, 44.0), Vector2(0.0, 58.0), Vector2(10.0, 44.0),
	]), ropa_det, 1.8, true)

	# Franjas de los hombros.
	for lado: float in [-1.0, 1.0]:
		var franja := PackedVector2Array([
			Vector2(lado * 11.0, 45.0), Vector2(lado * 16.0, 49.0),
			Vector2(lado * 13.0, 64.0), Vector2(lado * 9.0, 61.0),
		])
		draw_colored_polygon(franja, ropa_sec)

	# Escudo del club.
	var centro := Vector2(-16.0, 80.0)
	var escudo := _suavizar_cerrado(PackedVector2Array([
		Vector2(centro.x - 4.5, centro.y - 4.0), Vector2(centro.x + 4.5, centro.y - 4.0),
		Vector2(centro.x + 4.0, centro.y + 3.0), Vector2(centro.x, centro.y + 7.0),
		Vector2(centro.x - 4.0, centro.y + 3.0),
	]), 2)
	_poligono_tinta(escudo, ropa_det, grosor * 0.5)
	var estrella := _puntos_estrella(centro + Vector2(0.0, 1.0), 2.8, 1.2, 5)
	draw_colored_polygon(estrella, ropa_sec)

	# Dorsal 10 en el pecho.
	var fuente := ThemeDB.fallback_font
	if fuente != null:
		draw_string(fuente, Vector2(-8.0, 104.0), "10", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, ropa_det)

	# Cintura del short.
	draw_line(Vector2(-waist_x + 2.0, 100.0), Vector2(waist_x - 2.0, 100.0),
		Color(ropa_det, 0.65), 1.6, true)


func _dibujar_detalles_cuero(met: Dictionary, _ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var cuero := ropa_sec

	for lado: float in [-1.0, 1.0]:
		var panel := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 12.5, 43.5),
			Vector2(lado * sh_x, 53.0),
			Vector2(lado * (waist_x + 2.0), 100.0),
			Vector2(lado * (hip_x + 1.0), 126.0),
			Vector2(lado * 4.5, 128.0),
			Vector2(lado * 6.5, 102.0),
			Vector2(lado * 6.5, 60.0),
			Vector2(lado * 9.0, 46.0),
		]), 3)
		_poligono_tinta(panel, cuero, grosor * 0.82)
		var solapa := PackedVector2Array([
			Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
			Vector2(lado * 9.0, 66.0), Vector2(lado * 4.0, 59.0),
		])
		_poligono_tinta(solapa, cuero.lightened(0.12), grosor * 0.58)
		draw_line(Vector2(lado * 9.0, 58.0), Vector2(lado * 15.0, 122.0), ropa_det, 1.8, true)
		for y: float in [56.0, 64.0, 72.0, 80.0]:
			draw_circle(Vector2(lado * 8.0, y), 1.4, ropa_det, true, -1.0, true)

	# Cinturón y hebilla.
	draw_line(Vector2(-hip_x + 1.0, 125.0), Vector2(hip_x - 1.0, 125.0),
		cuero.darkened(0.35), 4.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4.0, 122.0), Vector2(4.0, 122.0), Vector2(4.0, 128.0), Vector2(-4.0, 128.0),
	]), ropa_det)
	draw_circle(Vector2(0.0, 125.0), 1.6, cuero.darkened(0.4), true, -1.0, true)


func _dibujar_detalles_astronauta(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, _detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]

	# Franjas naranjas de los hombros.
	for lado: float in [-1.0, 1.0]:
		var franja := PackedVector2Array([
			Vector2(lado * 13.0, 47.0), Vector2(lado * sh_x, 54.0),
			Vector2(lado * (sh_x - 1.0), 61.0), Vector2(lado * 14.0, 55.0),
		])
		draw_colored_polygon(franja, ropa_sec)

	# Panel pectoral acolchado.
	var pecho := _suavizar_cerrado(PackedVector2Array([
		Vector2(-15.0, 64.0), Vector2(15.0, 64.0), Vector2(17.0, 112.0),
		Vector2(0.0, 120.0), Vector2(-17.0, 112.0),
	]), 4)
	_poligono_tinta(pecho, ropa.lightened(0.04), grosor * 0.78)
	draw_colored_polygon(_suavizar_cerrado(PackedVector2Array([
		Vector2(9.0, 68.0), Vector2(15.0, 67.0), Vector2(16.0, 110.0),
		Vector2(8.0, 114.0),
	]), 2), Color(ropa.darkened(0.12), 0.45))

	# Panel de control.
	var panel := _suavizar_cerrado(PackedVector2Array([
		Vector2(-10.0, 76.0), Vector2(10.0, 76.0), Vector2(10.0, 104.0),
		Vector2(0.0, 109.0), Vector2(-10.0, 104.0),
	]), 2)
	_poligono_tinta(panel, ropa_det, grosor * 0.55)
	for y: float in [82.0, 90.0, 98.0]:
		for x: float in [-6.0, 0.0, 6.0]:
			draw_circle(Vector2(x, y), 1.7, ropa_sec if int(y) % 16 == 0 else Color.WHITE,
				true, -1.0, true)
	draw_line(Vector2(-7.0, 100.0), Vector2(7.0, 100.0), Color(ropa_sec, 0.8), 1.2, true)

	# Manguera y anillo del cuello.
	draw_polyline(PackedVector2Array([
		Vector2(10.0, 96.0), Vector2(16.0, 104.0), Vector2(18.0, 90.0), Vector2(14.0, 84.0),
	]), ropa_det, 2.4, true)
	var anillo := _suavizar_cerrado(PackedVector2Array([
		Vector2(-12.0, 47.0), Vector2(12.0, 47.0), Vector2(13.0, 54.0),
		Vector2(0.0, 58.0), Vector2(-13.0, 54.0),
	]), 3)
	_poligono_tinta(anillo, ropa_det, grosor * 0.58)
	draw_polyline(PackedVector2Array([
		Vector2(-11.0, 49.0), Vector2(0.0, 55.0), Vector2(11.0, 49.0),
	]), Color(1, 1, 1, 0.55), 1.4, true)

	# Insignia de misión.
	var parche := Vector2(-16.0, 68.0)
	draw_circle(parche, 4.4, ropa_det, true, -1.0, true)
	var estrella := _puntos_estrella(parche, 3.0, 1.3, 5)
	draw_colored_polygon(estrella, Color.WHITE)

	draw_line(Vector2(-waist_x + 2.0, 119.0), Vector2(waist_x - 2.0, 119.0),
		Color(ropa_sec, 0.7), 2.0, true)


func _dibujar_detalles_vestido(met: Dictionary, ropa: Color, ropa_sec: Color, ropa_det: Color,
		grosor: float, detalle: String) -> void:
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var es_largo := detalle == "largo"
	var y_bajo := 202.0 if es_largo else 164.0
	var ancho_bajo := hip_x * (1.55 if es_largo else 1.22)

	# Falda acampanada.
	var falda := _suavizar_cerrado(PackedVector2Array([
		Vector2(-waist_x + 1.0, 98.0),
		Vector2(waist_x - 1.0, 98.0),
		Vector2(ancho_bajo, y_bajo - 8.0),
		Vector2(ancho_bajo * 0.72, y_bajo),
		Vector2(0.0, y_bajo + 3.0),
		Vector2(-ancho_bajo * 0.72, y_bajo),
		Vector2(-ancho_bajo, y_bajo - 8.0),
	]), 4)
	_poligono_tinta(falda, ropa, grosor * 0.9)
	draw_colored_polygon(_suavizar_cerrado(PackedVector2Array([
		Vector2(4.0, 100.0), Vector2(waist_x + 2.0, 98.0),
		Vector2(ancho_bajo * 0.92, y_bajo - 10.0), Vector2(ancho_bajo * 0.45, y_bajo - 2.0),
		Vector2(1.0, y_bajo + 1.0),
	]), 3), Color(ropa.darkened(0.18), 0.45))
	if es_largo:
		draw_line(Vector2(8.0, 108.0), Vector2(15.0, y_bajo - 6.0),
			Color(ropa.darkened(0.26), 0.65), 2.0, true)

	# Cinturón y lazo.
	draw_line(Vector2(-waist_x, 99.0), Vector2(waist_x, 99.0), ropa_det, 3.0, true)
	draw_circle(Vector2(0.0, 99.0), 2.6, ropa_det, true, -1.0, true)
	for lado: float in [-1.0, 1.0]:
		draw_line(Vector2(lado * 2.0, 100.0), Vector2(lado * 8.0, 108.0), ropa_det, 1.8, true)

	# Escote y pinzas del corpiño.
	draw_polyline(PackedVector2Array([
		Vector2(-10.0, 45.0), Vector2(0.0, 55.0), Vector2(10.0, 45.0),
	]), ropa_det, 1.7, true)
	for lado: float in [-1.0, 1.0]:
		draw_line(Vector2(lado * 6.0, 60.0), Vector2(lado * 8.0, 96.0),
			Color(ropa.darkened(0.16), 0.55), 1.3, true)

	if detalle == "flores":
		for p: Vector2 in [
			Vector2(-16.0, 74.0), Vector2(14.0, 84.0), Vector2(-10.0, 112.0),
			Vector2(12.0, 128.0), Vector2(-18.0, 140.0), Vector2(6.0, 150.0),
			Vector2(-4.0, 118.0), Vector2(18.0, 108.0),
		]:
			_dibujar_flor(p, 3.6, ropa_sec, ropa_det)
	else:
		for p: Vector2 in [
			Vector2(-14.0, 78.0), Vector2(12.0, 88.0), Vector2(-8.0, 116.0),
			Vector2(14.0, 132.0), Vector2(-16.0, 146.0), Vector2(4.0, 160.0),
			Vector2(-2.0, 126.0),
		]:
			draw_circle(p, 1.6, ropa_sec, true, -1.0, true)
		draw_line(Vector2(-ancho_bajo * 0.95, y_bajo - 8.0),
			Vector2(ancho_bajo * 0.95, y_bajo - 8.0), ropa_sec, 2.0, true)


func _dibujar_flor(centro: Vector2, radio: float, petalo: Color, centro_col: Color) -> void:
	for i in range(5):
		var a := TAU * float(i) / 5.0
		draw_circle(centro + Vector2(cos(a), sin(a)) * radio * 0.8, radio * 0.55,
			petalo, true, -1.0, true)
	draw_circle(centro, radio * 0.42, centro_col, true, -1.0, true)


func _puntos_estrella(centro: Vector2, radio_ext: float, radio_int: float, puntas: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(puntas * 2):
		var ang := -PI * 0.5 + PI * float(i) / float(puntas)
		var r := radio_ext if i % 2 == 0 else radio_int
		pts.append(centro + Vector2(cos(ang), sin(ang)) * r)
	return pts


func _dibujar_cuello(nw: float, piel: Color, piel_sombra: Color, grosor: float, con_claviculas: bool) -> void:
	var cuello_piel := PackedVector2Array([
		Vector2(-nw, 27.0), Vector2(nw, 27.0),
		Vector2(nw + 1.4, 49.0), Vector2(0.0, 55.5), Vector2(-nw - 1.4, 49.0),
	])
	_poligono_tinta(cuello_piel, piel, grosor * 0.80)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-nw, 30.0), Vector2(nw, 30.0),
		Vector2(nw - 0.8, 42.5), Vector2(-nw + 1.8, 39.5),
	]), piel_sombra)
	if con_claviculas:
		draw_line(Vector2(-nw - 2.0, 50.0), Vector2(-3.5, 52.5), Color(piel_sombra, 0.75), 1.4, true)
		draw_line(Vector2(nw + 2.0, 50.0), Vector2(3.5, 52.5), Color(piel_sombra, 0.75), 1.4, true)


# ---------------------------------------------------------------- cabeza, cara y peinados

func _dibujar_cabeza_completa(
		head_pos: Vector2, head_rot: float, es_mujer: bool, met: Dictionary,
		piel: Color, piel_sombra: Color, ojos: Color, pelo: Color,
		ap: Dictionary, mirada: Vector2, grosor: float, rig: Dictionary,
		src: Personaje_Visual) -> void:
	var c := head_pos
	var r := head_rot
	var jaw_w: float = met["jaw_w"]

	var forma_cara := str(ap.get("forma_cara", "ovalada"))
	var forma_ojos := str(ap.get("forma_ojos", "almendrados"))
	var estilo_cejas := str(ap.get("estilo_cejas", "naturales"))
	var forma_nariz := str(ap.get("forma_nariz", "normal"))
	var forma_boca := str(ap.get("forma_boca", "normal"))
	var color_labios := Apariencia_Personaje.color_labios_de(ap, piel)
	var estilo_pelo := str(ap.get("estilo_pelo", "alborotado"))
	var gafas := str(ap.get("gafas", "ninguna"))
	var vello := str(ap.get("vello_facial", "ninguno"))
	var pecas := bool(ap.get("pecas", false))
	var lunar := str(ap.get("lunar", "ninguno"))
	var rubor_lvl := str(ap.get("rubor", "suave"))
	var delineado := bool(ap.get("delineado", false))
	var sombrero := str(ap.get("sombrero", "ninguno"))
	var pendientes := str(ap.get("pendientes", "ninguno"))

	var expr_activa: String = str(rig.get("comer_expresion_override", ""))
	if expr_activa == "":
		expr_activa = src.expresion
	var mejillas_infladas: float = float(rig.get("comer_mejillas", 0.0))
	var rubor_extra: float = float(rig.get("comer_rubor_extra", 0.0))
	var ojos_felices_extra: bool = bool(rig.get("comer_ojos_felices", false))

	# 1. Orejas proporcionadas y pegadas de forma natural + pendientes
	var ear_x: float = 28.4 * jaw_w
	for lado: float in [-1.0, 1.0]:
		var o_pos: Vector2 = _rotar(Vector2(lado * ear_x, 3.8), r) + c
		var oreja := _elipse_pts(o_pos, 5.2, 8.6, 22, r + lado * 0.10)
		_poligono_tinta(oreja, piel, grosor * 0.80)
		var oreja_int := _elipse_pts(o_pos + _rotar(Vector2(-lado * 0.8, 0.4), r), 2.5, 4.4, 14, r)
		draw_colored_polygon(oreja_int, Color(piel_sombra, 0.70))
		draw_arc(o_pos + _rotar(Vector2(-lado * 0.6, 0.3), r), 2.6, 0.4, PI * 1.45, 10, Color(TINTA, 0.55), 1.3, true)

		if pendientes != "ninguno" and not src.en_ducha:
			_dibujar_pendiente(o_pos + _rotar(Vector2(lado * 0.6, 8.2), r), r, pendientes, grosor)

	# 2. Rostro con curva Catmull-Rom refinada según forma_cara
	var pts_cara := _forma_rostro(es_mujer, forma_cara, jaw_w)
	if mejillas_infladas > 0.02:
		var exp_m := mejillas_infladas * 2.5
		var mod := PackedVector2Array(pts_cara)
		mod[4] = mod[4] + Vector2(exp_m, 0.8 * mejillas_infladas)
		mod[8] = mod[8] + Vector2(-exp_m, 0.8 * mejillas_infladas)
		pts_cara = mod
	var cara_suave := _suavizar_cerrado(pts_cara, 5)
	_poligono_tinta(_transformar_pts(cara_suave, c, r), piel, grosor * 0.96)

	# Sombra cel-shading suave en lado derecho de mandíbula y sien
	var sombra_cara := _suavizar_cerrado(PackedVector2Array([
		Vector2(21.0 * jaw_w, -16.0),
		Vector2(27.5 * jaw_w, 2.0),
		Vector2(24.0 * jaw_w, 19.0),
		Vector2(13.0 * jaw_w, 30.5),
		Vector2(0.0, 34.0),
		Vector2(-7.0, 31.8),
		Vector2(7.0, 28.8),
		Vector2(17.5 * jaw_w, 19.0),
		Vector2(22.0 * jaw_w, 3.0),
	]), 3)
	draw_colored_polygon(_transformar_pts(sombra_cara, c, r), Color(piel_sombra, 0.34))

	# Sombra suave en la frente bajo la línea del pelo (si no es calvo)
	if estilo_pelo != "calvo":
		var sombra_frente := _suavizar_cerrado(PackedVector2Array([
			Vector2(-21.0 * jaw_w, -23.0), Vector2(-10.0, -27.0), Vector2(0.0, -26.0),
			Vector2(10.0, -27.0), Vector2(21.0 * jaw_w, -23.0), Vector2(18.0 * jaw_w, -18.5),
			Vector2(0.0, -21.5), Vector2(-18.0 * jaw_w, -18.5),
		]), 3)
		draw_colored_polygon(_transformar_pts(sombra_frente, c, r), Color(piel_sombra, 0.14))

	# Rubor cálido en mejillas
	var base_rubor := 0.0
	if rubor_lvl == "suave":
		base_rubor = 0.24 if es_mujer else 0.12
	elif rubor_lvl == "intenso":
		base_rubor = 0.40 if es_mujer else 0.26
	var alpha_rubor: float = clampf(base_rubor + rubor_extra + mejillas_infladas * 0.12, 0.0, 0.62)
	if alpha_rubor > 0.01:
		var color_rubor := Color("#fb7185", alpha_rubor)
		var rx_rubor := 6.0 + mejillas_infladas * 1.4 + rubor_extra * 2.5
		var ry_rubor := 3.1 + mejillas_infladas * 1.1 + rubor_extra * 1.4
		for lado: float in [-1.0, 1.0]:
			var pos_r: Vector2 = _rotar(Vector2(lado * (17.5 + mejillas_infladas * 1.0), 10.5 + mejillas_infladas * 1.5), r) + c
			draw_colored_polygon(_elipse_pts(pos_r, rx_rubor, ry_rubor, 18, r), color_rubor)
			if mejillas_infladas > 0.35:
				var arco_m := _suavizar_abierta(PackedVector2Array([
					Vector2(lado * 15.5, 15.5),
					Vector2(lado * (18.2 + mejillas_infladas * 1.4), 18.5),
					Vector2(lado * 15.5, 21.8),
				]), 3)
				draw_polyline(_transformar_pts(arco_m, c, r), Color(piel_sombra, 0.55 * mejillas_infladas), 1.5, true)

	# Pecas y lunar
	if pecas:
		var col_peca := piel_sombra.darkened(0.28)
		for p: Vector2 in [
			Vector2(-16.5, 8.0), Vector2(-12.5, 10.0), Vector2(-19.5, 10.8),
			Vector2(16.5, 8.0), Vector2(12.5, 10.0), Vector2(19.5, 10.8),
			Vector2(-3.5, 7.6), Vector2(3.5, 7.6),
		]:
			draw_circle(_rotar(p, r) + c, 1.05, col_peca, true, -1.0, true)

	if lunar != "ninguno":
		var pos_l := Vector2(15.5, 11.5)
		if lunar == "labio":
			pos_l = Vector2(-10.5, 15.5)
		elif lunar == "ceja":
			pos_l = Vector2(19.0, -7.5)
		draw_circle(_rotar(pos_l, r) + c, 1.35, Color("#3f271d", 0.85), true, -1.0, true)

	# 3. Barba sombra / corta / completa / candado (detrás de boca)
	if not es_mujer and vello in ["sombra", "barba_corta", "barba_completa", "candado"]:
		_dibujar_vello_facial(c, r, jaw_w, vello, pelo, grosor)

	# 4. Ojos expresivos almendrados/Sims (proporcionados, naturales)
	_dibujar_ojos(c, r, es_mujer, forma_ojos, delineado, piel_sombra, ojos, mirada, grosor, expr_activa, ojos_felices_extra)

	# 5. Cejas esculpidas
	_dibujar_cejas(c, r, es_mujer, estilo_cejas, pelo, expr_activa)

	# 6. Nariz cómic limpia (sin garfio raro)
	_dibujar_nariz(c, r, forma_nariz, piel, piel_sombra)

	# 6b. Marcas de la edad (frente, patas de gallo, bolsas, surcos, manchas...)
	Envejecimiento_Personaje.dibujar_marcas_cara(self, c, r, piel_sombra, _rasgos_edad, jaw_w)

	# 7. Boca expresiva y labios
	_dibujar_boca(c, r, es_mujer, forma_boca, color_labios, piel_sombra, grosor, expr_activa, rig, src)

	if src.mancha_salsa:
		var p_mancha: Vector2 = _rotar(Vector2(-11.2, 20.5), r) + c
		draw_circle(p_mancha, 2.3, Color("#dc2626", 0.88), true, -1.0, true)
		draw_circle(p_mancha + _rotar(Vector2(-2.0, 2.0), r), 1.2, Color("#ea580c", 0.82), true, -1.0, true)

	# 8. Bigote / perilla
	if not es_mujer and vello in ["bigote", "perilla"]:
		_dibujar_vello_facial(c, r, jaw_w, vello, pelo, grosor)

	# 9. Gafas (ocultas al dormir o en la ducha)
	var ocultar_accesorios_sueno := src.en_ducha or src.pose == "dormir"
	if gafas != "ninguna" and not ocultar_accesorios_sueno:
		_dibujar_gafas(c, r, gafas)

	# 10. Pelo delantero orgánico
	_dibujar_pelo_delantero(c, r, estilo_pelo, pelo, grosor)

	# 11. Sombrero o diadema (oculto si lleva gorro de fiesta, está en ducha o durmiendo)
	if sombrero != "ninguno" and src.accesorio_cabeza == "ninguno" and not ocultar_accesorios_sueno:
		var color_ropa_sombrero := Apariencia_Personaje.color_de(src.apariencia, "color_ropa", Color("#2563eb"))
		_dibujar_sombrero(c, r, sombrero, color_ropa_sombrero, grosor)

	# 12. Gorro de cumpleaños del cómic introductorio
	if src.accesorio_cabeza == "gorro_fiesta":
		_dibujar_gorro_fiesta(c + _rotar(Vector2(-10.0, -34.0), r), r - 0.24, grosor, true)
	elif src.accesorio_cabeza == "gorro_volando":
		_dibujar_gorro_fiesta(c + _rotar(Vector2(-18.0, -64.0), r), r - 0.52, grosor, false)


func _forma_rostro(es_mujer: bool, forma: String, jaw_w: float) -> PackedVector2Array:
	var pts: PackedVector2Array
	match forma:
		"cuadrada":
			pts = PackedVector2Array([
				Vector2(0.0, -37.0),
				Vector2(19.5, -33.0),
				Vector2(28.5, -17.0),
				Vector2(29.0, 3.0),
				Vector2(25.8, 22.0),
				Vector2(15.5, 32.0),
				Vector2(0.0, 34.8),
				Vector2(-15.5, 32.0),
				Vector2(-25.8, 22.0),
				Vector2(-29.0, 3.0),
				Vector2(-28.5, -17.0),
				Vector2(-19.5, -33.0),
			])
		"redonda":
			pts = PackedVector2Array([
				Vector2(0.0, -36.5),
				Vector2(20.5, -32.0),
				Vector2(29.5, -15.0),
				Vector2(30.5, 4.0),
				Vector2(26.5, 20.5),
				Vector2(14.5, 30.8),
				Vector2(0.0, 33.8),
				Vector2(-14.5, 30.8),
				Vector2(-26.5, 20.5),
				Vector2(-30.5, 4.0),
				Vector2(-29.5, -15.0),
				Vector2(-20.5, -32.0),
			])
		"alargada":
			pts = PackedVector2Array([
				Vector2(0.0, -38.5),
				Vector2(18.5, -34.5),
				Vector2(26.8, -17.0),
				Vector2(27.0, 4.0),
				Vector2(22.5, 22.5),
				Vector2(11.8, 34.0),
				Vector2(0.0, 37.5),
				Vector2(-11.8, 34.0),
				Vector2(-22.5, 22.5),
				Vector2(-27.0, 4.0),
				Vector2(-26.8, -17.0),
				Vector2(-18.5, -34.5),
			])
		"corazon":
			pts = PackedVector2Array([
				Vector2(0.0, -37.0),
				Vector2(20.0, -32.5),
				Vector2(29.5, -15.5),
				Vector2(29.2, 2.0),
				Vector2(22.0, 18.5),
				Vector2(10.5, 30.5),
				Vector2(0.0, 34.5),
				Vector2(-10.5, 30.5),
				Vector2(-22.0, 18.5),
				Vector2(-29.2, 2.0),
				Vector2(-29.5, -15.5),
				Vector2(-20.0, -32.5),
			])
		_:
			# "ovalada" equilibrada y atractiva
			var jx := 23.2 if es_mujer else 25.0
			var cx := 11.8 if es_mujer else 13.8
			pts = PackedVector2Array([
				Vector2(0.0, -37.2),
				Vector2(19.5, -33.2),
				Vector2(28.5, -16.5),
				Vector2(28.8, 2.5),
				Vector2(jx, 20.0),
				Vector2(cx, 31.8),
				Vector2(0.0, 35.2),
				Vector2(-cx, 31.8),
				Vector2(-jx, 20.0),
				Vector2(-28.8, 2.5),
				Vector2(-28.5, -16.5),
				Vector2(-19.5, -33.2),
			])

	if absf(jaw_w - 1.0) > 0.005:
		var out := PackedVector2Array()
		for p in pts:
			out.append(Vector2(p.x * jaw_w, p.y))
		return out
	return pts


func _esta_parpadeando(expr_activa: String = "") -> bool:
	var e := expresion if expr_activa == "" else expr_activa
	if not animar_idle or e in ["sorpresa", "panico", "asustado_frio", "dormido", "roncando", "feliz_cerrado", "satisfecho", "cantando", "reir"]:
		return false
	var ciclo := fmod(_t + _fase_parpadeo, 3.8)
	return ciclo > 3.64


func _dibujar_ojos(c: Vector2, r: float, es_mujer: bool, forma_ojos: String, delineado: bool,
		piel_sombra: Color, color_ojos: Color, mirada: Vector2, grosor: float,
		expr_activa: String = "", ojos_felices_extra: bool = false) -> void:
	var e := expresion if expr_activa == "" else expr_activa
	var parpadeo := _esta_parpadeando(e)
	var en_shock: bool = e in ["sorpresa", "panico", "asustado_frio"]
	var ojos_dormidos: bool = e in ["dormido", "roncando", "cansado", "bostezo"]
	var ojos_felices: bool = ojos_felices_extra or (e in ["feliz_cerrado", "satisfecho", "cantando", "reir"])

	var eye_y: float = -0.5
	var eye_x: float = 12.2
	var rx: float = 7.0
	var ry: float = 5.4 if not es_mujer else 5.7
	var tilt: float = -0.05

	match forma_ojos:
		"grandes":
			rx = 7.4
			ry = 6.4
			tilt = 0.0
		"rasgados":
			rx = 7.4
			ry = 4.5
			tilt = -0.15
		"caidos":
			rx = 7.0
			ry = 5.3
			tilt = 0.11

	if en_shock:
		rx = 8.0
		ry = 8.4
		tilt = 0.0

	for lado: float in [-1.0, 1.0]:
		var ec_local := Vector2(lado * eye_x, eye_y)

		if ojos_felices:
			var arco_feliz := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.85, 1.8),
				ec_local + Vector2(0.0, -3.6),
				ec_local + Vector2(rx * 0.85, 1.8),
			]), 4)
			draw_polyline(_transformar_pts(arco_feliz, c, r), TINTA, grosor * 1.02, true)
			continue

		if parpadeo or ojos_dormidos:
			var dy_mid: float = 2.6 if ojos_dormidos else -1.0
			var arco_cerrado := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.85, 0.2),
				ec_local + Vector2(0.0, dy_mid),
				ec_local + Vector2(rx * 0.85, 0.2),
			]), 4)
			draw_polyline(_transformar_pts(arco_cerrado, c, r), TINTA, grosor * 0.92, true)
			continue

		# 1. Esclerótica con forma almendrada elegante (o redonda en shock)
		var sclera_local: PackedVector2Array
		var tilt_l := tilt * lado
		if en_shock:
			sclera_local = _elipse_pts(ec_local, rx, ry, 24, 0.0)
		else:
			var pts_o := PackedVector2Array([
				Vector2(-rx, 0.6),
				Vector2(-rx * 0.56, -ry * 0.92),
				Vector2(0.0, -ry * 1.04),
				Vector2(rx * 0.60, -ry * 0.88),
				Vector2(rx, 0.3),
				Vector2(rx * 0.55, ry * 0.84),
				Vector2(0.0, ry * 0.88),
				Vector2(-rx * 0.55, ry * 0.80),
			])
			sclera_local = _transformar_pts(_suavizar_cerrado(pts_o, 4), ec_local, tilt_l)
		draw_colored_polygon(_transformar_pts(sclera_local, c, r), Color("#fcfcfd"))

		# 2. Iris proporcionado y ligeramente cubierto por el párpado superior (da mirada natural y cálida)
		var ic_local := ec_local + mirada * 0.85 + Vector2(0.0, 0.0 if en_shock else -0.35)
		var r_iris: float = 3.8 if en_shock else 4.85
		var iris_ext: PackedVector2Array
		var iris_body: PackedVector2Array
		var pupila_pts: PackedVector2Array

		if en_shock:
			iris_ext = _elipse_pts(ic_local, r_iris, r_iris, 20, 0.0)
			iris_body = _elipse_pts(ic_local, r_iris * 0.76, r_iris * 0.76, 18, 0.0)
			pupila_pts = _elipse_pts(ic_local, 1.9, 1.9, 14, 0.0)
		else:
			iris_ext = _recortar_elipse_a_ojo(ic_local, r_iris, r_iris * 1.04, ec_local, rx, ry, 22)
			iris_body = _recortar_elipse_a_ojo(ic_local + Vector2(0.0, 0.25), r_iris * 0.78, r_iris * 0.80, ec_local, rx, ry, 18)
			pupila_pts = _recortar_elipse_a_ojo(ic_local + Vector2(0.0, 0.15), 2.15, 2.25, ec_local, rx, ry, 16)

		draw_colored_polygon(_transformar_pts(iris_ext, c, r), color_ojos.darkened(0.42))
		draw_colored_polygon(_transformar_pts(iris_body, c, r), color_ojos)

		if not en_shock:
			var glow_pts := _recortar_elipse_a_ojo(ic_local + Vector2(0.0, 1.9), r_iris * 0.54, r_iris * 0.34, ec_local, rx, ry, 14)
			draw_colored_polygon(_transformar_pts(glow_pts, c, r), Color(color_ojos.lightened(0.40), 0.75))

		draw_colored_polygon(_transformar_pts(pupila_pts, c, r), TINTA)

		# 3. Sombra suave proyectada por el párpado superior
		if not en_shock:
			var sh_top := _suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 0.94, -ry * 0.04),
				Vector2(-rx * 0.50, -ry * 0.86),
				Vector2(0.0, -ry * 0.96),
				Vector2(rx * 0.52, -ry * 0.82),
				Vector2(rx * 0.94, -ry * 0.06),
			]), 4)
			var sh_poly := PackedVector2Array(sh_top)
			sh_poly.append(Vector2(rx * 0.90, -ry * 0.32))
			sh_poly.append(Vector2(0.0, -ry * 0.46))
			sh_poly.append(Vector2(-rx * 0.90, -ry * 0.32))
			if not Geometry2D.triangulate_polygon(sh_poly).is_empty():
				draw_colored_polygon(_transformar_pts(_transformar_pts(sh_poly, ec_local, tilt_l), c, r), Color(0.18, 0.24, 0.38, 0.15))

		# 4. Brillos especulares nítidos
		var ic_w: Vector2 = _rotar(ic_local, r) + c
		draw_circle(ic_w + _rotar(Vector2(-1.45, -1.45), r), 1.45, Color.WHITE, true, -1.0, true)
		draw_circle(ic_w + _rotar(Vector2(1.4, 1.3), r), 0.70, Color(1.0, 1.0, 1.0, 0.88), true, -1.0, true)

		# 5. Párpado superior con trazo limpio + pestañas / delineado opcional
		if en_shock:
			var cerr := _transformar_pts(sclera_local, c, r)
			cerr.append(cerr[0])
			draw_polyline(cerr, TINTA, 2.0, true)
		else:
			var lid_top := _transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 1.04, 0.6),
				Vector2(-rx * 0.58, -ry * 0.94),
				Vector2(0.0, -ry * 1.06),
				Vector2(rx * 0.62, -ry * 0.90),
				Vector2(rx * 1.04, 0.3),
			]), 5), ec_local, tilt_l)
			var ancho_lid := 2.9 if (es_mujer or delineado) else 2.4
			draw_polyline(_transformar_pts(lid_top, c, r), TINTA, ancho_lid, true)

			# Pliegue suave del párpado superior
			var pliegue := _transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 0.58, -ry * 1.32),
				Vector2(0.0, -ry * 1.46),
				Vector2(rx * 0.58, -ry * 1.28),
			]), 4), ec_local, tilt_l)
			draw_polyline(_transformar_pts(pliegue, c, r), Color(piel_sombra, 0.68), 1.15, true)

			# Borde inferior muy sutil en tono sombra piel
			var lid_bot := _transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 0.45, ry * 0.80),
				Vector2(0.0, ry * 0.90),
				Vector2(rx * 0.45, ry * 0.82),
			]), 4), ec_local, tilt_l)
			draw_polyline(_transformar_pts(lid_bot, c, r), Color(piel_sombra, 0.58), 1.1, true)

			if delineado or es_mujer:
				var wb := _rotar(Vector2(lado * (rx * 0.92), -ry * 0.22), tilt_l) + ec_local
				var ala := PackedVector2Array([
					wb + Vector2(-lado * 1.2, -1.2),
					wb + Vector2(lado * (4.4 if delineado else 3.2), -2.8 if delineado else -2.2),
					wb + Vector2(lado * 1.1, 0.9),
				])
				if not Geometry2D.triangulate_polygon(ala).is_empty():
					draw_colored_polygon(_transformar_pts(ala, c, r), TINTA)
				if delineado:
					var tip2: Vector2 = _rotar(_rotar(Vector2(lado * (rx * 0.68), -ry * 0.72), tilt_l) + ec_local, r) + c
					draw_line(tip2, tip2 + _rotar(Vector2(lado * 2.5, -2.2), r), TINTA, 1.5, true)


func _dibujar_cejas(c: Vector2, r: float, es_mujer: bool, estilo_cejas: String, color_pelo: Color, expr_activa: String) -> void:
	var col_ceja := color_pelo.darkened(0.26)
	var thick: float = (2.2 if es_mujer else 3.0) * (1.0 - 0.32 * float(_rasgos_edad.get("cejas_finas", 0.0)))
	match estilo_cejas:
		"gruesas":
			thick += 1.2
		"finas":
			thick = maxf(1.5, thick - 0.9)

	var yb: float = -13.8 if expr_activa in ["sorpresa", "panico"] else -10.4

	for lado: float in [-1.0, 1.0]:
		var dy_in: float = 0.2
		var dy_mid: float = -2.2
		var dy_out: float = 0.6

		match estilo_cejas:
			"arqueadas":
				dy_in = 0.6
				dy_mid = -3.4
				dy_out = 0.8
			"rectas":
				dy_in = -0.6
				dy_mid = -1.0
				dy_out = -0.4

		if expr_activa == "panico":
			dy_in -= 2.2
			dy_out += 2.4
		elif expr_activa == "sorpresa":
			dy_mid -= 2.4
		elif expr_activa == "concentrado":
			dy_in += 2.2
			dy_out -= 1.2

		var ceja := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 5.6, yb + dy_in - thick * 0.44),
			Vector2(lado * 12.6, yb + dy_mid - thick * 0.48),
			Vector2(lado * 20.6, yb + dy_out),
			Vector2(lado * 12.6, yb + dy_mid + thick * 0.48),
			Vector2(lado * 5.8, yb + dy_in + thick * 0.52),
		]), 3)
		_poligono_tinta(_transformar_pts(ceja, c, r), col_ceja, 1.15)


func _dibujar_nariz(c: Vector2, r: float, forma_nariz: String, piel: Color, piel_sombra: Color) -> void:
	var brillo_n := piel.lightened(0.20)
	match forma_nariz:
		"respingona":
			# Sombra suave de puente corto + punta respingona sutil
			var som_p := _elipse_pts(_rotar(Vector2(0.4, 8.6), r) + c, 2.8, 1.6, 12, r)
			draw_colored_polygon(som_p, Color(piel_sombra, 0.52))
			draw_circle(_rotar(Vector2(-0.5, 6.8), r) + c, 1.2, Color(brillo_n, 0.65), true, -1.0, true)
			var curva := _suavizar_abierta(PackedVector2Array([
				Vector2(-2.2, 8.0), Vector2(0.0, 9.2), Vector2(2.4, 7.6),
			]), 4)
			draw_polyline(_transformar_pts(curva, c, r), Color(TINTA, 0.78), 1.45, true)
		"recta":
			# Puente definido + sombra lateral limpia
			var bridge := PackedVector2Array([
				Vector2(0.2, 0.5), Vector2(1.8, 8.6), Vector2(0.0, 10.6), Vector2(-1.2, 8.8),
			])
			draw_colored_polygon(_transformar_pts(bridge, c, r), Color(piel_sombra, 0.42))
			draw_line(_rotar(Vector2(-0.6, 2.0), r) + c, _rotar(Vector2(-0.6, 7.8), r) + c, Color(brillo_n, 0.60), 1.3, true)
			var curva := _suavizar_abierta(PackedVector2Array([
				Vector2(-2.0, 9.8), Vector2(0.4, 10.6), Vector2(2.8, 9.4),
			]), 4)
			draw_polyline(_transformar_pts(curva, c, r), Color(TINTA, 0.78), 1.45, true)
		"ancha":
			var som_a := _elipse_pts(_rotar(Vector2(0.4, 9.6), r) + c, 4.4, 2.0, 14, r)
			draw_colored_polygon(som_a, Color(piel_sombra, 0.50))
			draw_circle(_rotar(Vector2(-0.6, 7.6), r) + c, 1.5, Color(brillo_n, 0.60), true, -1.0, true)
			var curva := _suavizar_abierta(PackedVector2Array([
				Vector2(-3.8, 9.0), Vector2(-1.8, 10.4), Vector2(1.8, 10.4), Vector2(3.8, 9.0),
			]), 4)
			draw_polyline(_transformar_pts(curva, c, r), Color(TINTA, 0.78), 1.50, true)
		"fina":
			draw_line(_rotar(Vector2(0.9, 1.8), r) + c, _rotar(Vector2(1.2, 8.2), r) + c, Color(piel_sombra, 0.48), 1.6, true)
			var curva := _suavizar_abierta(PackedVector2Array([
				Vector2(-1.6, 9.2), Vector2(0.3, 10.0), Vector2(2.0, 8.9),
			]), 4)
			draw_polyline(_transformar_pts(curva, c, r), Color(TINTA, 0.74), 1.35, true)
		_:
			# "normal" — sombra suave de puente + curva limpia de punta (estilo vineta_1.png)
			var puente := PackedVector2Array([
				Vector2(0.4, 1.2), Vector2(1.8, 7.6), Vector2(0.2, 10.2), Vector2(-1.0, 8.4),
			])
			draw_colored_polygon(_transformar_pts(puente, c, r), Color(piel_sombra, 0.40))
			draw_circle(_rotar(Vector2(-0.6, 7.8), r) + c, 1.35, Color(brillo_n, 0.62), true, -1.0, true)
			var curva := _suavizar_abierta(PackedVector2Array([
				Vector2(-2.6, 9.2), Vector2(0.0, 10.5), Vector2(2.8, 9.2),
			]), 4)
			draw_polyline(_transformar_pts(curva, c, r), Color(TINTA, 0.78), 1.48, true)


func _dibujar_boca(c: Vector2, r: float, es_mujer: bool, forma_boca: String, color_labios: Color,
		piel_sombra: Color, grosor: float, expr_activa: String, rig: Dictionary, src: Personaje_Visual) -> void:
	var e := src.expresion if expr_activa == "" else expr_activa
	var w_scale := 1.0
	var lip_h := 1.0
	match forma_boca:
		"amplia":
			w_scale = 1.15
		"gruesa":
			lip_h = 1.45
		"fina":
			w_scale = 0.92
			lip_h = 0.68

	var mostrar_labios: bool = es_mujer or (str(apariencia.get("color_labios", "natural")) != "natural") or (forma_boca == "gruesa")
	var col_labio_tint := Color(color_labios, 0.58 if es_mujer or str(apariencia.get("color_labios", "natural")) != "natural" else 0.35)

	match e:
		"sorpresa", "panico":
			var b_pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-9.5 * w_scale, 18.8), Vector2(-5.2 * w_scale, 14.8), Vector2(5.2 * w_scale, 14.8),
				Vector2(9.5 * w_scale, 18.8), Vector2(8.0 * w_scale, 26.2), Vector2(0.0, 28.0), Vector2(-8.0 * w_scale, 26.2),
			]), 3)
			_poligono_tinta(_transformar_pts(b_pts, c, r), Color("#45121d"), grosor * 0.78)
			draw_colored_polygon(_transformar_pts(PackedVector2Array([
				Vector2(-6.2 * w_scale, 16.0), Vector2(6.2 * w_scale, 16.0),
				Vector2(5.8 * w_scale, 18.6), Vector2(-5.8 * w_scale, 18.6),
			]), c, r), Color.WHITE)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 24.8), r) + c, 5.2 * w_scale, 2.5, 14, r), Color("#fb7185"))
		"asustado_frio":
			var wave_b := _suavizar_abierta(PackedVector2Array([
				Vector2(-9.5 * w_scale, 20.0), Vector2(-4.5, 17.8), Vector2(0.0, 20.4),
				Vector2(4.5, 17.8), Vector2(9.5 * w_scale, 20.0),
			]), 3)
			draw_polyline(_transformar_pts(wave_b, c, r), TINTA, 2.1, true)
		"roncando", "bostezo":
			var r_b: float = 5.0 + sin(_t * 3.8) * 2.0 if e == "roncando" else 6.6
			var o_pts := _elipse_pts(_rotar(Vector2(0.0, 21.0), r) + c, r_b * 0.85 * w_scale, r_b, 18, r)
			_poligono_tinta(o_pts, Color("#45121d"), 1.9)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 23.2), r) + c, r_b * 0.52, r_b * 0.34, 12, r), Color("#fb7185"))
		"dormido":
			var paz := _suavizar_abierta(PackedVector2Array([
				Vector2(-5.6 * w_scale, 19.6), Vector2(0.0, 21.2), Vector2(5.6 * w_scale, 19.6),
			]), 3)
			draw_polyline(_transformar_pts(paz, c, r), Color(TINTA, 0.82), 1.85, true)
		"soplando":
			var mej := float(rig.get("comer_mejillas", 0.5))
			var r_o := 2.9 + mej * 1.0
			var p_o := _elipse_pts(_rotar(Vector2(0.5, 20.4), r) + c, r_o, r_o * 0.92, 16, r)
			_poligono_tinta(p_o, Color("#6b1d2e"), 1.8)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.5, 21.4), r) + c, r_o * 0.48, r_o * 0.34, 10, r), Color("#fb7185"))
			for lado_s: float in [-1.0, 1.0]:
				var hoyo := _suavizar_abierta(PackedVector2Array([
					Vector2(lado_s * 6.5, 18.4), Vector2(lado_s * 5.4, 20.4), Vector2(lado_s * 6.5, 22.4),
				]), 3)
				draw_polyline(_transformar_pts(hoyo, c, r), Color(piel_sombra, 0.72), 1.3, true)
		"masticando":
			if src.pose == "comer":
				var apertura: float = float(rig.get("comer_boca_apertura", 0.0))
				var mast_val: float = float(rig.get("comer_masticacion", 0.0))
				if apertura > 0.12:
					var aw := (5.8 + apertura * 4.4) * w_scale
					var ah := 2.2 + apertura * 7.2
					var b_ab := _suavizar_cerrado(PackedVector2Array([
						Vector2(-aw, 18.0), Vector2(0.0, 17.2 - apertura * 1.0), Vector2(aw, 18.0),
						Vector2(aw * 0.82, 19.2 + ah), Vector2(0.0, 20.2 + ah), Vector2(-aw * 0.82, 19.2 + ah),
					]), 4)
					_poligono_tinta(_transformar_pts(b_ab, c, r), Color("#45121d"), 1.9)
					if apertura > 0.35:
						var dt := PackedVector2Array([
							Vector2(-aw * 0.70, 17.8), Vector2(aw * 0.70, 17.8),
							Vector2(aw * 0.62, 19.8), Vector2(-aw * 0.62, 19.8),
						])
						draw_colored_polygon(_transformar_pts(dt, c, r), Color.WHITE)
					draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 19.2 + ah * 0.68), r) + c, aw * 0.54, maxf(1.5, ah * 0.30), 14, r), Color("#fb7185"))
				elif absf(mast_val) > 0.02:
					var dx_m := mast_val * 1.5
					var dy_m := absf(mast_val) * 1.3
					var ancho_c := (8.6 - absf(mast_val) * 1.1) * w_scale
					var m_curva := _suavizar_abierta(PackedVector2Array([
						Vector2(-ancho_c + dx_m, 18.8 - dy_m * 0.3),
						Vector2(-ancho_c * 0.4 + dx_m, 20.8 + dy_m * 0.5),
						Vector2(dx_m, 19.8 + dy_m * 0.8),
						Vector2(ancho_c * 0.4 + dx_m, 20.8 + dy_m * 0.5),
						Vector2(ancho_c + dx_m, 18.8 - dy_m * 0.3),
					]), 4)
					var pts_m := _transformar_pts(m_curva, c, r)
					if mostrar_labios:
						draw_polyline(pts_m, col_labio_tint, 3.0 * lip_h, true)
					draw_polyline(pts_m, TINTA, 2.0, true)
				else:
					_dibujar_sonrisa_cerrada(c, r, w_scale, lip_h, mostrar_labios, col_labio_tint, piel_sombra)
			else:
				var mast := (sin(_t * 9.0) + 1.0) * 0.5
				var ancho_m: float = (8.0 + mast * 2.8) * w_scale
				var alto_m: float = 1.5 + mast * 3.5
				var m_pts := _suavizar_cerrado(PackedVector2Array([
					Vector2(-ancho_m, 18.8), Vector2(0.0, 19.0 - alto_m * 0.3), Vector2(ancho_m, 18.8),
					Vector2(ancho_m * 0.7, 19.8 + alto_m), Vector2(0.0, 20.5 + alto_m), Vector2(-ancho_m * 0.7, 19.8 + alto_m),
				]), 3)
				_poligono_tinta(_transformar_pts(m_pts, c, r), Color("#45121d"), 1.85)
				draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 19.8 + alto_m * 0.6), r) + c, 3.8, 1.7, 12, r), Color("#fb7185"))
		"satisfecho":
			_dibujar_sonrisa_cerrada(c, r, w_scale * 1.04, lip_h, mostrar_labios, col_labio_tint, piel_sombra)
		"cantando":
			var canto := (sin(_t * 8.0) + 1.0) * 0.5
			var rx_c: float = (6.0 + canto * 2.2) * w_scale
			var ry_c: float = 5.0 + canto * 3.2
			var c_pts := _elipse_pts(_rotar(Vector2(0.0, 20.8), r) + c, rx_c, ry_c, 18, r)
			_poligono_tinta(c_pts, Color("#45121d"), 1.9)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 23.0), r) + c, rx_c * 0.6, ry_c * 0.36, 12, r), Color("#fb7185"))
		"feliz", "feliz_cerrado", "reir":
			var mw := 11.4 * w_scale
			if mostrar_labios:
				var aura_l := _suavizar_cerrado(PackedVector2Array([
					Vector2(-mw - 1.2, 16.0), Vector2(-3.0, 16.4 - lip_h), Vector2(0.0, 17.2), Vector2(3.0, 16.4 - lip_h), Vector2(mw + 1.2, 16.0),
					Vector2(8.8 * w_scale, 25.0 + lip_h), Vector2(0.0, 27.6 + lip_h * 1.2), Vector2(-8.8 * w_scale, 25.0 + lip_h),
				]), 4)
				draw_colored_polygon(_transformar_pts(aura_l, c, r), col_labio_tint)
			var b_pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-mw, 16.6), Vector2(0.0, 18.2), Vector2(mw, 16.6),
				Vector2(8.6 * w_scale, 24.0), Vector2(0.0, 26.2), Vector2(-8.6 * w_scale, 24.0),
			]), 4)
			_poligono_tinta(_transformar_pts(b_pts, c, r), Color("#45121d"), 1.85)
			var dientes := _suavizar_cerrado(PackedVector2Array([
				Vector2(-mw * 0.84, 17.3), Vector2(0.0, 18.5), Vector2(mw * 0.84, 17.3),
				Vector2(mw * 0.74, 20.4), Vector2(0.0, 21.2), Vector2(-mw * 0.74, 20.4),
			]), 3)
			draw_colored_polygon(_transformar_pts(dientes, c, r), Color.WHITE)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 23.8), r) + c, 5.2 * w_scale, 2.0, 16, r), Color("#fb7185"))
			var labio_sup := _suavizar_abierta(PackedVector2Array([
				Vector2(-mw * 1.06, 16.0), Vector2(0.0, 18.3), Vector2(mw * 1.06, 16.0),
			]), 5)
			draw_polyline(_transformar_pts(labio_sup, c, r), TINTA, 1.95, true)
			var menton := _suavizar_abierta(PackedVector2Array([
				Vector2(-3.2, 29.5), Vector2(0.0, 30.2), Vector2(3.2, 29.5),
			]), 3)
			draw_polyline(_transformar_pts(menton, c, r), Color(piel_sombra, 0.65), 1.35, true)
		"concentrado", "neutral":
			var lw := 7.6 * w_scale
			if mostrar_labios:
				draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 20.4), r) + c, lw * 0.68, 2.1 * lip_h, 14, r), col_labio_tint)
			var linea := _suavizar_abierta(PackedVector2Array([
				Vector2(-lw, 19.4), Vector2(0.0, 20.0), Vector2(lw, 19.0),
			]), 4)
			draw_polyline(_transformar_pts(linea, c, r), TINTA, 2.0, true)
		_:
			_dibujar_sonrisa_cerrada(c, r, w_scale, lip_h, mostrar_labios, col_labio_tint, piel_sombra)


func _dibujar_sonrisa_cerrada(c: Vector2, r: float, w_scale: float, lip_h: float,
		mostrar_labios: bool, col_labio: Color, piel_sombra: Color) -> void:
	var sw := 9.8 * w_scale
	if mostrar_labios:
		var lab_sup := _suavizar_cerrado(PackedVector2Array([
			Vector2(-sw * 0.9, 18.2), Vector2(-2.6, 16.4 - lip_h * 0.8),
			Vector2(0.0, 17.2), Vector2(2.6, 16.4 - lip_h * 0.8), Vector2(sw * 0.9, 18.2),
			Vector2(0.0, 21.6),
		]), 3)
		draw_colored_polygon(_transformar_pts(lab_sup, c, r), col_labio)
		draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 22.0 + lip_h * 0.4), r) + c, sw * 0.56, 2.2 * lip_h, 14, r), col_labio)

	var sonrisa := _suavizar_abierta(PackedVector2Array([
		Vector2(-sw, 17.4), Vector2(-sw * 0.45, 20.8), Vector2(0.0, 21.6),
		Vector2(sw * 0.45, 20.8), Vector2(sw, 17.4),
	]), 4)
	draw_polyline(_transformar_pts(sonrisa, c, r), TINTA, 2.0, true)
	# Comisuras sutiles y sombrita bajo el labio inferior
	for lado_c: float in [-1.0, 1.0]:
		var com := _rotar(Vector2(lado_c * sw, 17.3), r) + c
		draw_line(com + _rotar(Vector2(-lado_c * 0.8, -0.9), r), com + _rotar(Vector2(lado_c * 0.8, 0.8), r), Color(TINTA, 0.45), 1.2, true)
	var ment_s := _suavizar_abierta(PackedVector2Array([
		Vector2(-3.0, 25.4), Vector2(0.0, 26.2), Vector2(3.0, 25.4),
	]), 3)
	draw_polyline(_transformar_pts(ment_s, c, r), Color(piel_sombra, 0.65), 1.35, true)


func _dibujar_vello_facial(c: Vector2, r: float, jaw_w: float, tipo: String, pelo: Color, grosor: float) -> void:
	var col := pelo.darkened(0.16)
	match tipo:
		"sombra":
			var sombra_b := _suavizar_cerrado(PackedVector2Array([
				Vector2(-26.5 * jaw_w, 8.0), Vector2(-23.0 * jaw_w, 20.5), Vector2(-13.5 * jaw_w, 31.2),
				Vector2(0.0, 35.0), Vector2(13.5 * jaw_w, 31.2), Vector2(23.0 * jaw_w, 20.5),
				Vector2(26.5 * jaw_w, 8.0), Vector2(21.5 * jaw_w, 13.5), Vector2(13.0 * jaw_w, 23.0),
				Vector2(0.0, 25.8), Vector2(-13.0 * jaw_w, 23.0), Vector2(-21.5 * jaw_w, 13.5),
			]), 3)
			draw_colored_polygon(_transformar_pts(sombra_b, c, r), Color(col, 0.28))
		"barba_corta":
			var barba := _suavizar_cerrado(PackedVector2Array([
				Vector2(-27.0 * jaw_w, 9.0), Vector2(-23.6 * jaw_w, 21.0), Vector2(-14.0 * jaw_w, 32.0),
				Vector2(0.0, 36.2), Vector2(14.0 * jaw_w, 32.0), Vector2(23.6 * jaw_w, 21.0),
				Vector2(27.0 * jaw_w, 9.0), Vector2(22.0 * jaw_w, 14.5), Vector2(13.5 * jaw_w, 24.0),
				Vector2(0.0, 26.8), Vector2(-13.5 * jaw_w, 24.0), Vector2(-22.0 * jaw_w, 14.5),
			]), 3)
			_poligono_tinta(_transformar_pts(barba, c, r), Color(col, 0.92), grosor * 0.56)
		"barba_completa":
			var barba_f := _suavizar_cerrado(PackedVector2Array([
				Vector2(-27.8 * jaw_w, 6.0), Vector2(-26.0 * jaw_w, 23.0), Vector2(-16.0 * jaw_w, 37.0),
				Vector2(0.0, 44.5), Vector2(16.0 * jaw_w, 37.0), Vector2(26.0 * jaw_w, 23.0),
				Vector2(27.8 * jaw_w, 6.0), Vector2(21.5 * jaw_w, 13.0), Vector2(11.5, 16.5),
				Vector2(0.0, 15.2), Vector2(-11.5, 16.5), Vector2(-21.5 * jaw_w, 13.0),
			]), 3)
			_poligono_tinta(_transformar_pts(barba_f, c, r), col, grosor * 0.68)
		"bigote":
			var big := _suavizar_cerrado(PackedVector2Array([
				Vector2(-13.0, 16.2), Vector2(-5.5, 12.6), Vector2(0.0, 14.0),
				Vector2(5.5, 12.6), Vector2(13.0, 16.2), Vector2(7.8, 17.4),
				Vector2(0.0, 15.8), Vector2(-7.8, 17.4),
			]), 3)
			_poligono_tinta(_transformar_pts(big, c, r), col, grosor * 0.58)
		"perilla":
			var per := _suavizar_cerrado(PackedVector2Array([
				Vector2(-7.8, 26.2), Vector2(0.0, 27.8), Vector2(7.8, 26.2),
				Vector2(5.6, 34.8), Vector2(0.0, 37.0), Vector2(-5.6, 34.8),
			]), 3)
			_poligono_tinta(_transformar_pts(per, c, r), col, grosor * 0.58)
		"candado":
			var big_c := _suavizar_cerrado(PackedVector2Array([
				Vector2(-12.5, 16.0), Vector2(-5.2, 12.6), Vector2(0.0, 14.0),
				Vector2(5.2, 12.6), Vector2(12.5, 16.0), Vector2(7.8, 17.2),
				Vector2(0.0, 15.6), Vector2(-7.8, 17.2),
			]), 3)
			var per_c := _suavizar_cerrado(PackedVector2Array([
				Vector2(-8.6, 26.5), Vector2(0.0, 28.0), Vector2(8.6, 26.5),
				Vector2(6.0, 35.0), Vector2(0.0, 37.2), Vector2(-6.0, 35.0),
			]), 3)
			_poligono_tinta(_transformar_pts(big_c, c, r), col, grosor * 0.56)
			_poligono_tinta(_transformar_pts(per_c, c, r), col, grosor * 0.56)
			for lado_k: float in [-1.0, 1.0]:
				var tira := PackedVector2Array([
					Vector2(lado_k * 10.0, 15.5), Vector2(lado_k * 12.8, 16.2),
					Vector2(lado_k * 9.8, 28.5), Vector2(lado_k * 6.8, 27.5),
				])
				_poligono_tinta(_transformar_pts(tira, c, r), col, grosor * 0.50)


func _dibujar_gafas(c: Vector2, r: float, tipo: String) -> void:
	var cristal := Color(0.90, 0.97, 1.0, 0.14) if tipo != "sol" else Color("#0f172a", 0.86)
	var montura := Color("#1e293b")
	var y: float = -0.5

	match tipo:
		"redondas":
			for lado: float in [-1.0, 1.0]:
				var pos: Vector2 = _rotar(Vector2(lado * 12.2, y), r) + c
				draw_circle(pos, 9.6, cristal, true, -1.0, true)
				draw_arc(pos, 9.6, 0.0, TAU, 28, montura, 1.85, true)
				draw_line(pos + _rotar(Vector2(-5.2, -4.6), r), pos + _rotar(Vector2(-2.2, -6.4), r), Color(1.0, 1.0, 1.0, 0.55), 1.3, true)
			draw_line(_rotar(Vector2(-2.6, y - 0.8), r) + c, _rotar(Vector2(2.6, y - 0.8), r) + c, montura, 1.7, true)
		"cuadradas":
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.4
				var marco := _suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 9.4, y - 7.0), Vector2(cx + 9.4, y - 7.0),
					Vector2(cx + 8.8, y + 6.8), Vector2(cx - 8.8, y + 6.8),
				]), 2)
				var t_m := _transformar_pts(marco, c, r)
				draw_colored_polygon(t_m, cristal)
				var cerrado := PackedVector2Array(t_m)
				cerrado.append(t_m[0])
				draw_polyline(cerrado, montura, 1.9, true)
			draw_line(_rotar(Vector2(-3.0, y - 1.5), r) + c, _rotar(Vector2(3.0, y - 1.5), r) + c, montura, 1.7, true)
		"aviador":
			var mont_av := Color("#b45309")
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.6
				var lente := _suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 9.8 * lado, y - 6.8), Vector2(cx + 9.4 * lado, y - 5.2),
					Vector2(cx + 9.6 * lado, y + 3.8), Vector2(cx + 1.5 * lado, y + 8.6),
					Vector2(cx - 7.5 * lado, y + 5.0),
				]), 3)
				var t_l := _transformar_pts(lente, c, r)
				draw_colored_polygon(t_l, Color("#0284c7", 0.24))
				var cerr := PackedVector2Array(t_l)
				cerr.append(t_l[0])
				draw_polyline(cerr, mont_av, 1.7, true)
			draw_line(_rotar(Vector2(-3.0, y - 4.2), r) + c, _rotar(Vector2(3.0, y - 4.2), r) + c, mont_av, 1.5, true)
			draw_line(_rotar(Vector2(-9.5, y - 6.4), r) + c, _rotar(Vector2(9.5, y - 6.4), r) + c, mont_av, 1.3, true)
		"cateye":
			var mont_ce := Color("#7f1d1d")
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.4
				var marco := _suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 8.6 * lado, y - 5.4), Vector2(cx + 10.6 * lado, y - 8.4),
					Vector2(cx + 8.2 * lado, y + 6.0), Vector2(cx - 8.0 * lado, y + 5.8),
				]), 2)
				var t_c := _transformar_pts(marco, c, r)
				draw_colored_polygon(t_c, cristal)
				var cerr := PackedVector2Array(t_c)
				cerr.append(t_c[0])
				draw_polyline(cerr, mont_ce, 2.0, true)
			draw_line(_rotar(Vector2(-3.4, y - 2.0), r) + c, _rotar(Vector2(3.4, y - 2.0), r) + c, mont_ce, 1.7, true)
		"sol":
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.6
				var marco := _suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 10.0, y - 7.0), Vector2(cx + 10.0, y - 7.0),
					Vector2(cx + 9.2, y + 7.2), Vector2(cx - 9.2, y + 7.2),
				]), 2)
				var t_s := _transformar_pts(marco, c, r)
				draw_colored_polygon(t_s, cristal)
				var cerr := PackedVector2Array(t_s)
				cerr.append(t_s[0])
				draw_polyline(cerr, montura, 2.2, true)
				draw_line(_rotar(Vector2(cx - 5.5, y - 4.0), r) + c, _rotar(Vector2(cx - 0.5, y + 3.5), r) + c, Color(1.0, 1.0, 1.0, 0.42), 2.0, true)
			draw_line(_rotar(Vector2(-3.0, y - 2.4), r) + c, _rotar(Vector2(3.0, y - 2.4), r) + c, montura, 2.2, true)


# ---------------------------------------------------------------- peinados orgánicos y sombreros

func _dibujar_pelo_trasero(c: Vector2, r: float, estilo: String, pelo: Color, grosor: float) -> void:
	var pelo_sombra := pelo.darkened(0.24)
	match estilo:
		"largo":
			var back := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -44.0), Vector2(27.0, -37.0), Vector2(39.0, -10.0),
				Vector2(43.0, 30.0), Vector2(40.0, 74.0), Vector2(24.0, 86.0),
				Vector2(0.0, 80.0), Vector2(-24.0, 86.0), Vector2(-40.0, 74.0),
				Vector2(-43.0, 30.0), Vector2(-39.0, -10.0), Vector2(-27.0, -37.0),
			]), 4)
			_poligono_tinta(_transformar_pts(back, c, r), pelo_sombra, grosor * 0.94)
		"ondulado":
			var back_w := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -44.0), Vector2(28.0, -37.0), Vector2(41.0, -10.0),
				Vector2(37.0, 16.0), Vector2(45.0, 42.0), Vector2(39.0, 76.0),
				Vector2(22.0, 88.0), Vector2(0.0, 81.0), Vector2(-22.0, 88.0),
				Vector2(-39.0, 76.0), Vector2(-45.0, 42.0), Vector2(-37.0, 16.0),
				Vector2(-41.0, -10.0), Vector2(-28.0, -37.0),
			]), 4)
			_poligono_tinta(_transformar_pts(back_w, c, r), pelo_sombra, grosor * 0.94)
		"media_melena":
			var bob := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -44.0), Vector2(27.0, -37.0), Vector2(39.0, -10.0),
				Vector2(41.0, 22.0), Vector2(34.0, 46.0), Vector2(18.0, 49.0),
				Vector2(-18.0, 49.0), Vector2(-34.0, 46.0), Vector2(-41.0, 22.0),
				Vector2(-39.0, -10.0), Vector2(-27.0, -37.0),
			]), 4)
			_poligono_tinta(_transformar_pts(bob, c, r), pelo_sombra, grosor * 0.94)
		"bob":
			var bob_c := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -43.5), Vector2(26.5, -36.5), Vector2(37.5, -10.0),
				Vector2(38.0, 16.0), Vector2(30.0, 32.0), Vector2(16.0, 34.0),
				Vector2(-16.0, 34.0), Vector2(-30.0, 32.0), Vector2(-38.0, 16.0),
				Vector2(-37.5, -10.0), Vector2(-26.5, -36.5),
			]), 4)
			_poligono_tinta(_transformar_pts(bob_c, c, r), pelo_sombra, grosor * 0.92)
		"coleta":
			var cola := _suavizar_cerrado(PackedVector2Array([
				Vector2(17.0, -33.0), Vector2(42.0, -29.0), Vector2(54.0, -2.0),
				Vector2(52.0, 32.0), Vector2(39.0, 48.0), Vector2(30.0, 25.0),
				Vector2(32.0, -2.0), Vector2(15.0, -16.0),
			]), 4)
			_poligono_tinta(_transformar_pts(cola, c, r), pelo, grosor * 0.92)
			var goma := _elipse_pts(_rotar(Vector2(23.0, -28.0), r) + c, 5.8, 8.2, 16, r + 0.4)
			_poligono_tinta(goma, Color("#ef4444"), grosor * 0.70)
		"dos_coletas":
			for lado: float in [-1.0, 1.0]:
				var c_p := _suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 25.0, -14.0), Vector2(lado * 41.0, -6.0),
					Vector2(lado * 46.0, 22.0), Vector2(lado * 40.0, 50.0),
					Vector2(lado * 27.0, 42.0), Vector2(lado * 26.0, 14.0),
				]), 4)
				_poligono_tinta(_transformar_pts(c_p, c, r), pelo_sombra, grosor * 0.88)
				_poligono_tinta(_elipse_pts(_rotar(Vector2(lado * 30.0, -11.0), r) + c, 4.5, 4.5, 14, r), Color("#f43f5e"), grosor * 0.65)
		"mono":
			var pos_m := _rotar(Vector2(0.0, -47.5), r) + c
			_poligono_tinta(_elipse_pts(pos_m, 16.5, 14.0, 26, r), pelo, grosor * 0.92)
			_poligono_tinta(_elipse_pts(_rotar(Vector2(0.0, -36.0), r) + c, 11.8, 3.5, 16, r), Color("#ef4444"), grosor * 0.70)
		"rizado":
			# Silueta rizada orgánica detrás de la cabeza y sienes (sin círculos sueltos raros)
			var back_r := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -47.0), Vector2(18.0, -46.0), Vector2(31.0, -35.0),
				Vector2(39.0, -18.0), Vector2(38.0, 1.0), Vector2(33.0, 16.0),
				Vector2(24.0, 22.0), Vector2(-24.0, 22.0), Vector2(-33.0, 16.0),
				Vector2(-38.0, 1.0), Vector2(-39.0, -18.0), Vector2(-31.0, -35.0), Vector2(-18.0, -46.0),
			]), 4)
			_poligono_tinta(_transformar_pts(back_r, c, r), pelo_sombra, grosor * 0.90)
		"afro":
			var pts_a := PackedVector2Array()
			var segs := 24
			for i in range(segs):
				var a := -PI * 0.5 + TAU * float(i) / float(segs)
				var bump := 3.2 if i % 2 == 0 else -1.8
				var rx_a := 44.0 + bump
				var ry_a := 41.0 + bump
				var py := -14.0 + sin(a) * ry_a
				if py > 18.0:
					py = 18.0 + (py - 18.0) * 0.25
				pts_a.append(Vector2(cos(a) * rx_a, py))
			_poligono_tinta(_transformar_pts(_suavizar_cerrado(pts_a, 3), c, r), pelo_sombra, grosor * 0.94)


func _dibujar_pelo_delantero(c: Vector2, r: float, estilo: String, pelo: Color, grosor: float) -> void:
	# Las canas reflejan menos brillo: el pelo blanco se ve mate.
	var canas := float(_rasgos_edad.get("canas", 0.0))
	var brillo := pelo.lightened(lerpf(0.24, 0.07, canas))
	var mech_ink := Color(pelo.darkened(0.36), 0.72)

	match estilo:
		"calvo":
			# Brillo sutil en la coronilla
			var br := _transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(-11.0, -29.0), Vector2(-4.0, -33.0), Vector2(5.0, -32.0),
			]), 3), c, r)
			draw_polyline(br, Color(1.0, 1.0, 1.0, 0.45), 2.8, true)

		"rapado":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-29.0, -8.0), Vector2(-29.0, -21.0), Vector2(-19.0, -34.5),
				Vector2(0.0, -38.8), Vector2(19.0, -34.5), Vector2(29.0, -21.0),
				Vector2(29.0, -8.0), Vector2(25.2, -18.0), Vector2(14.0, -24.0),
				Vector2(0.0, -25.0), Vector2(-14.0, -24.0), Vector2(-25.2, -18.0),
			]), 3)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor * 0.80)

		"alborotado":
			# Curvas fluidas y mechones dinámicos inspirados en vineta_1.png
			var base_alb := PackedVector2Array([
				Vector2(-29.0, -4.0),
				Vector2(-32.5, -15.5),
				Vector2(-35.0, -23.0),
				Vector2(-28.5, -28.5),
				Vector2(-26.0, -37.0),
				Vector2(-15.0, -42.5),
				Vector2(-6.0, -40.5),
				Vector2(5.5, -50.5),
				Vector2(15.5, -43.5),
				Vector2(30.0, -47.0),
				Vector2(29.0, -33.5),
				Vector2(36.5, -26.0),
				Vector2(31.5, -14.5),
				Vector2(29.0, -4.0),
				Vector2(25.2, -16.0),
				Vector2(18.0, -22.5),
				Vector2(11.5, -14.5),
				Vector2(5.5, -23.5),
				Vector2(-3.5, -15.5),
				Vector2(-12.5, -23.0),
				Vector2(-23.5, -14.5),
			])
			_poligono_tinta(_transformar_pts(_suavizar_cerrado(base_alb, 4), c, r), pelo, grosor * 0.92)
			draw_polyline(_transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(-12.0, -36.0), Vector2(-4.0, -31.0), Vector2(5.0, -36.5),
			]), 4), c, r), mech_ink, 1.45, true)
			draw_polyline(_transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(13.0, -40.5), Vector2(17.5, -32.5), Vector2(26.0, -33.0),
			]), 4), c, r), mech_ink, 1.35, true)
			_brillo_pelo(c, r, Vector2(-14.0, -34.0), Vector2(12.0, -37.5), brillo)

		"tupe":
			var pts_t := _suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -4.0), Vector2(-31.5, -20.0), Vector2(-24.0, -37.0),
				Vector2(-6.0, -49.5), Vector2(15.0, -52.0), Vector2(28.0, -42.0),
				Vector2(32.5, -24.0), Vector2(29.5, -4.0), Vector2(25.5, -18.0),
				Vector2(16.0, -24.5), Vector2(2.0, -23.0), Vector2(-15.0, -25.0),
				Vector2(-25.5, -17.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts_t, c, r), pelo, grosor * 0.94)
			draw_polyline(_transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(-16.0, -34.0), Vector2(0.0, -40.5), Vector2(17.0, -38.5),
			]), 4), c, r), mech_ink, 1.5, true)
			_brillo_pelo(c, r, Vector2(-11.0, -41.0), Vector2(14.0, -43.0), brillo)

		"corto":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -3.0), Vector2(-32.5, -19.0), Vector2(-22.0, -37.0),
				Vector2(0.0, -43.5), Vector2(22.0, -39.0), Vector2(32.5, -21.0),
				Vector2(29.5, -3.0), Vector2(24.8, -16.5), Vector2(12.0, -23.0),
				Vector2(-4.0, -20.0), Vector2(-18.0, -15.5), Vector2(-25.2, -12.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor * 0.94)
			_brillo_pelo(c, r, Vector2(-11.0, -34.0), Vector2(13.0, -33.5), brillo)

		"degradado":
			var fade := _suavizar_cerrado(PackedVector2Array([
				Vector2(-28.5, -10.0), Vector2(-29.5, -23.0), Vector2(-21.0, -36.0),
				Vector2(21.0, -36.0), Vector2(29.5, -23.0), Vector2(28.5, -10.0),
				Vector2(25.0, -21.0), Vector2(15.0, -25.0), Vector2(-15.0, -25.0), Vector2(-25.0, -21.0),
			]), 3)
			_poligono_tinta(_transformar_pts(fade, c, r), pelo.darkened(0.18), grosor * 0.80)
			var top_d := _suavizar_cerrado(PackedVector2Array([
				Vector2(-24.0, -26.0), Vector2(-21.0, -41.0), Vector2(-7.0, -46.5),
				Vector2(8.0, -47.5), Vector2(22.0, -40.5), Vector2(24.0, -26.0),
				Vector2(12.0, -22.5), Vector2(0.0, -25.0), Vector2(-12.0, -22.5),
			]), 3)
			_poligono_tinta(_transformar_pts(top_d, c, r), pelo, grosor * 0.92)
			_brillo_pelo(c, r, Vector2(-12.0, -37.0), Vector2(12.0, -38.0), brillo)

		"raya_lado":
			var pts_rl := _suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -3.0), Vector2(-32.5, -19.0), Vector2(-22.5, -37.0),
				Vector2(0.0, -43.8), Vector2(22.5, -38.0), Vector2(32.5, -19.0),
				Vector2(29.5, -3.0), Vector2(25.0, -16.5), Vector2(13.0, -24.5),
				Vector2(-1.0, -18.5), Vector2(-14.0, -15.5), Vector2(-25.0, -13.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts_rl, c, r), pelo, grosor * 0.94)
			draw_polyline(_transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(14.0, -39.0), Vector2(12.5, -29.0), Vector2(13.0, -24.5),
			]), 3), c, r), mech_ink, 1.5, true)
			_brillo_pelo(c, r, Vector2(-14.0, -33.0), Vector2(8.0, -35.0), brillo)

		"rizado":
			# Corona orgánica continua de rizos suaves (sin círculos desconectados)
			var crown := _suavizar_cerrado(PackedVector2Array([
				Vector2(-31.0, -8.0), Vector2(-34.5, -18.0), Vector2(-30.5, -28.0),
				Vector2(-27.0, -38.0), Vector2(-16.0, -43.5), Vector2(-4.0, -46.5),
				Vector2(8.0, -46.0), Vector2(20.0, -41.5), Vector2(29.5, -32.0),
				Vector2(34.5, -20.0), Vector2(31.0, -8.0), Vector2(25.5, -16.5),
				Vector2(17.5, -22.5), Vector2(7.0, -20.5), Vector2(-2.0, -24.0),
				Vector2(-12.0, -20.5), Vector2(-22.5, -22.0), Vector2(-27.0, -14.5),
			]), 3)
			_poligono_tinta(_transformar_pts(crown, c, r), pelo, grosor * 0.94)
			for rz_p: Vector2 in [Vector2(-14.0, -33.0), Vector2(2.0, -36.0), Vector2(16.0, -31.0)]:
				var arc_r := _transformar_pts(_suavizar_abierta(PackedVector2Array([
					rz_p + Vector2(-5.5, 1.0), rz_p + Vector2(0.0, -3.5), rz_p + Vector2(5.5, 1.0),
				]), 3), c, r)
				draw_polyline(arc_r, mech_ink, 1.45, true)
			_brillo_pelo(c, r, Vector2(-9.0, -39.5), Vector2(10.0, -40.5), brillo)

		"afro":
			var frente_a := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.0, -12.0), Vector2(-30.0, -26.0), Vector2(-18.0, -38.0),
				Vector2(0.0, -41.0), Vector2(18.0, -38.0), Vector2(30.0, -26.0),
				Vector2(32.0, -12.0), Vector2(26.0, -21.0), Vector2(14.0, -25.5),
				Vector2(0.0, -26.5), Vector2(-14.0, -25.5), Vector2(-26.0, -21.0),
			]), 4)
			draw_colored_polygon(_transformar_pts(frente_a, c, r), pelo)
			_brillo_pelo(c, r, Vector2(-13.0, -37.0), Vector2(13.0, -37.0), brillo)

		"largo", "ondulado":
			var pts_l := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.5, 22.0), Vector2(-36.5, -12.0), Vector2(-26.0, -36.5),
				Vector2(0.0, -44.2), Vector2(26.0, -36.5), Vector2(36.5, -12.0),
				Vector2(32.5, 22.0), Vector2(27.5, -4.0), Vector2(20.0, -19.5),
				Vector2(6.0, -24.5), Vector2(-6.0, -16.5), Vector2(-20.5, -19.5),
				Vector2(-27.5, -4.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts_l, c, r), pelo, grosor * 0.94)
			draw_polyline(_transformar_pts(_suavizar_abierta(PackedVector2Array([
				Vector2(6.0, -41.0), Vector2(6.0, -29.0), Vector2(6.0, -24.5),
			]), 3), c, r), mech_ink, 1.4, true)
			_brillo_pelo(c, r, Vector2(-13.0, -33.5), Vector2(13.0, -33.5), brillo)

		"media_melena":
			var pts_m := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.5, 23.0), Vector2(-36.0, -12.0), Vector2(-26.0, -36.5),
				Vector2(0.0, -44.2), Vector2(26.0, -36.5), Vector2(36.0, -12.0),
				Vector2(32.5, 23.0), Vector2(26.5, 1.0), Vector2(22.5, -18.5),
				Vector2(9.0, -15.5), Vector2(0.0, -21.5), Vector2(-9.0, -15.5),
				Vector2(-22.5, -18.5), Vector2(-26.5, 1.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts_m, c, r), pelo, grosor * 0.94)
			_brillo_pelo(c, r, Vector2(-13.0, -33.5), Vector2(13.0, -33.5), brillo)

		"bob":
			var pts_b := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.0, 14.0), Vector2(-35.5, -12.0), Vector2(-25.5, -36.0),
				Vector2(0.0, -43.5), Vector2(25.5, -36.0), Vector2(35.5, -12.0),
				Vector2(32.0, 14.0), Vector2(26.5, -4.0), Vector2(22.5, -16.0),
				Vector2(10.0, -15.5), Vector2(0.0, -15.0), Vector2(-10.0, -15.5),
				Vector2(-22.5, -16.0), Vector2(-26.5, -4.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts_b, c, r), pelo, grosor * 0.94)
			for fx: float in [-8.0, 0.0, 8.0]:
				draw_line(_rotar(Vector2(fx, -22.0), r) + c, _rotar(Vector2(fx, -15.5), r) + c, mech_ink, 1.25, true)
			_brillo_pelo(c, r, Vector2(-13.0, -33.5), Vector2(13.0, -33.5), brillo)

		"coleta", "mono", "dos_coletas":
			var pts_c := _suavizar_cerrado(PackedVector2Array([
				Vector2(-30.0, -3.0), Vector2(-32.0, -20.0), Vector2(-22.0, -36.5),
				Vector2(0.0, -43.0), Vector2(22.0, -36.5), Vector2(32.0, -20.0),
				Vector2(30.0, -3.0), Vector2(25.5, -16.0), Vector2(13.0, -22.5),
				Vector2(0.0, -20.0), Vector2(-13.0, -22.5), Vector2(-25.5, -16.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts_c, c, r), pelo, grosor * 0.94)
			_brillo_pelo(c, r, Vector2(-11.0, -33.5), Vector2(11.0, -33.5), brillo)


func _dibujar_sombrero(c: Vector2, r: float, tipo: String, color_ropa: Color, grosor: float) -> void:
	var col_s := color_ropa.darkened(0.08)
	var col_s_dark := color_ropa.darkened(0.28)
	match tipo:
		"gorra":
			var copa := _suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -20.0), Vector2(-27.0, -38.0), Vector2(-14.0, -47.0),
				Vector2(0.0, -49.0), Vector2(14.0, -47.0), Vector2(27.0, -38.0),
				Vector2(29.5, -20.0), Vector2(16.0, -23.0), Vector2(0.0, -24.0), Vector2(-16.0, -23.0),
			]), 3)
			_poligono_tinta(_transformar_pts(copa, c, r), col_s, grosor * 0.92)
			draw_line(_rotar(Vector2(0.0, -48.5), r) + c, _rotar(Vector2(0.0, -24.5), r) + c, Color(TINTA, 0.35), 1.4, true)
			# Visera curva hacia adelante/izquierda
			var visera := _suavizar_cerrado(PackedVector2Array([
				Vector2(-28.0, -21.0), Vector2(-14.0, -24.0), Vector2(14.0, -24.0),
				Vector2(27.0, -21.0), Vector2(22.0, -14.5), Vector2(0.0, -16.5), Vector2(-25.0, -15.5),
			]), 3)
			_poligono_tinta(_transformar_pts(visera, c, r), col_s_dark, grosor * 0.88)
			draw_circle(_rotar(Vector2(0.0, -49.5), r) + c, 2.4, col_s_dark, true, -1.0, true)
		"gorro":
			var cuerpo_g := _suavizar_cerrado(PackedVector2Array([
				Vector2(-30.0, -20.0), Vector2(-28.0, -39.0), Vector2(-14.0, -50.0),
				Vector2(0.0, -52.5), Vector2(14.0, -50.0), Vector2(28.0, -39.0), Vector2(30.0, -20.0),
			]), 3)
			_poligono_tinta(_transformar_pts(cuerpo_g, c, r), col_s, grosor * 0.92)
			var vuelta := _suavizar_cerrado(PackedVector2Array([
				Vector2(-31.5, -23.0), Vector2(0.0, -26.0), Vector2(31.5, -23.0),
				Vector2(30.5, -14.0), Vector2(0.0, -17.0), Vector2(-30.5, -14.0),
			]), 3)
			_poligono_tinta(_transformar_pts(vuelta, c, r), col_s_dark, grosor * 0.86)
			draw_circle(_rotar(Vector2(0.0, -55.0), r) + c, 6.2, col_s_dark, true, -1.0, true)
			draw_arc(_rotar(Vector2(0.0, -55.0), r) + c, 6.2, 0.0, TAU, 14, TINTA, grosor * 0.72, true)
		"boina":
			var boina := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.0, -21.0), Vector2(-35.0, -35.0), Vector2(-16.0, -47.5),
				Vector2(14.0, -46.0), Vector2(32.0, -34.0), Vector2(28.0, -21.5),
				Vector2(12.0, -25.5), Vector2(-12.0, -24.0),
			]), 4)
			_poligono_tinta(_transformar_pts(boina, c, r), col_s, grosor * 0.92)
			draw_line(_rotar(Vector2(-2.0, -47.0), r) + c, _rotar(Vector2(1.0, -52.5), r) + c, TINTA, 2.2, true)
		"diadema":
			var dia := _suavizar_abierta(PackedVector2Array([
				Vector2(-28.0, -13.0), Vector2(-22.0, -31.0), Vector2(0.0, -38.5),
				Vector2(22.0, -31.0), Vector2(28.0, -13.0),
			]), 5)
			var pts_d := _transformar_pts(dia, c, r)
			draw_polyline(pts_d, TINTA, 6.2, true)
			draw_polyline(pts_d, col_s.lightened(0.15), 3.6, true)


func _dibujar_pendiente(pos: Vector2, r: float, tipo: String, grosor: float) -> void:
	match tipo:
		"aros":
			draw_arc(pos + _rotar(Vector2(0.0, 3.6), r), 3.6, 0.0, TAU, 16, Color("#f59e0b"), 2.0, true)
			draw_arc(pos + _rotar(Vector2(0.0, 3.6), r), 3.6, 0.0, TAU, 16, Color(TINTA, 0.55), 0.8, true)
		"perlas":
			draw_circle(pos, 2.5, Color("#f8fafc"), true, -1.0, true)
			draw_arc(pos, 2.5, 0.0, TAU, 12, TINTA, grosor * 0.5, true)
		"cruz":
			draw_line(pos, pos + _rotar(Vector2(0.0, 6.8), r), Color("#cbd5e1"), 1.8, true)
			draw_line(pos + _rotar(Vector2(-2.2, 3.2), r), pos + _rotar(Vector2(2.2, 3.2), r), Color("#cbd5e1"), 1.8, true)
			draw_circle(pos, 1.5, Color("#f59e0b"), true, -1.0, true)


func _brillo_pelo(c: Vector2, r: float, p0: Vector2, p1: Vector2, col: Color) -> void:
	var medio := (p0 + p1) * 0.5 + Vector2(0.0, -3.5)
	var pts := _transformar_pts(_suavizar_abierta(PackedVector2Array([p0, medio, p1]), 4), c, r)
	draw_polyline(pts, Color(col, 0.62), 3.0, true)


# ---------------------------------------------------------------- accesorios y props del cómic

func _dibujar_gorro_fiesta(pos: Vector2, rot: float, grosor: float, con_elastico: bool) -> void:
	if con_elastico:
		draw_line(pos + _rotar(Vector2(-14.0, 12.0), rot), pos + _rotar(Vector2(-18.0, 42.0), rot), TINTA, 1.8, true)

	var cono := PackedVector2Array([
		Vector2(0.0, -36.0), Vector2(18.0, 12.0), Vector2(-18.0, 12.0),
	])
	_poligono_tinta(_transformar_pts(cono, pos, rot), Color("#ef4444"), grosor * 0.9)

	var franja1 := PackedVector2Array([
		Vector2(-6.5, -18.0), Vector2(6.5, -18.0), Vector2(10.0, -8.0), Vector2(-10.0, -8.0),
	])
	var franja2 := PackedVector2Array([
		Vector2(-13.5, 1.0), Vector2(13.5, 1.0), Vector2(16.5, 9.0), Vector2(-16.5, 9.0),
	])
	_poligono_tinta(_transformar_pts(franja1, pos, rot), Color("#fde047"), grosor * 0.6)
	_poligono_tinta(_transformar_pts(franja2, pos, rot), Color("#fde047"), grosor * 0.6)

	var punta := pos + _rotar(Vector2(0.0, -38.0), rot)
	draw_circle(punta, 7.5, Color("#fbbf24"), true, -1.0, true)
	draw_arc(punta, 7.5, 0.0, TAU, 18, TINTA, grosor * 0.8, true)


func _dibujar_tarta_18(pos: Vector2, grosor: float) -> void:
	var pulso := 22.0 + sin(_t * 6.5) * 3.0 if animar_idle else 22.0
	draw_circle(pos + Vector2(0.0, -48.0), pulso, Color(1.0, 0.94, 0.58, 0.35), true, -1.0, true)

	var plato := _elipse_pts(pos + Vector2(0.0, 4.0), 38.0, 8.5, 24, 0.0)
	_poligono_tinta(plato, Color("#e2e8f0"), grosor * 0.85)

	var cuerpo := PackedVector2Array([
		pos + Vector2(-28.0, -28.0), pos + Vector2(28.0, -28.0),
		pos + Vector2(29.0, 1.0), pos + Vector2(-29.0, 1.0),
	])
	_poligono_tinta(cuerpo, Color("#fde68a"), grosor * 0.88)

	draw_line(pos + Vector2(-28.0, -12.0), pos + Vector2(28.0, -12.0), Color("#fb7185"), 4.2, true)
	draw_line(pos + Vector2(-28.0, -12.0), pos + Vector2(28.0, -12.0), TINTA, 1.4, true)

	var glaseado := PackedVector2Array([
		pos + Vector2(-29.0, -29.0), pos + Vector2(29.0, -29.0), pos + Vector2(29.0, -21.0),
		pos + Vector2(20.0, -17.0), pos + Vector2(12.0, -23.0), pos + Vector2(2.0, -16.0),
		pos + Vector2(-8.0, -22.0), pos + Vector2(-19.0, -17.0), pos + Vector2(-29.0, -22.0),
	])
	_poligono_tinta(glaseado, Color("#f472b6"), grosor * 0.8)

	var col_vela := Color("#fb923c")
	var v1 := PackedVector2Array([
		pos + Vector2(-12.0, -45.0), pos + Vector2(-5.5, -45.0),
		pos + Vector2(-5.5, -28.0), pos + Vector2(-12.0, -28.0),
	])
	_poligono_tinta(v1, col_vela, grosor * 0.72)
	for cy: float in [-40.5, -32.5]:
		draw_circle(pos + Vector2(8.5, cy), 5.6, col_vela, true, -1.0, true)
		draw_arc(pos + Vector2(8.5, cy), 5.6, 0.0, TAU, 16, TINTA, grosor * 0.72, true)
		draw_circle(pos + Vector2(8.5, cy), 1.8, Color("#fff7ed"), true, -1.0, true)

	var flama_dx := sin(_t * 11.0) * 1.1 if animar_idle else 0.0
	for vx: float in [-8.7, 8.5]:
		var base: Vector2 = pos + Vector2(vx, -47.0)
		var llama := PackedVector2Array([
			base + Vector2(flama_dx, -11.0), base + Vector2(4.2, -3.0),
			base + Vector2(0.0, 1.0), base + Vector2(-4.2, -3.0),
		])
		_poligono_tinta(llama, Color("#f97316"), grosor * 0.55)
		draw_circle(base + Vector2(flama_dx * 0.4, -3.5), 2.2, Color("#fef08a"), true, -1.0, true)


func _dibujar_gotas_sudor(pos: Vector2, grosor: float) -> void:
	for info: Array in [[Vector2.ZERO, 1.0, -0.25], [Vector2(4.0, 13.0), 0.78, 0.15]]:
		var p: Vector2 = pos + info[0]
		var s: float = info[1]
		var ang: float = info[2]
		var gota := _suavizar_cerrado(PackedVector2Array([
			Vector2(-7.0, 0.0) * s, Vector2(2.0, -4.5) * s,
			Vector2(7.0, 0.0) * s, Vector2(2.0, 4.5) * s,
		]), 2)
		_poligono_tinta(_transformar_pts(gota, p, ang), Color("#38bdf8"), grosor * 0.65)


func _dibujar_espuma_cabeza(c: Vector2, r: float, grosor: float) -> void:
	var espuma := Color("#f8fafc")
	var burbujas := [
		[Vector2(-22.0, -34.0), 11.0],
		[Vector2(-8.0, -44.0), 14.5],
		[Vector2(10.0, -43.0), 13.5],
		[Vector2(24.0, -33.0), 10.5],
		[Vector2(0.0, -52.0), 11.5],
	]
	for b: Array in burbujas:
		var bp: Vector2 = _rotar(b[0], r) + c
		var br: float = b[1]
		draw_circle(bp, br, espuma, true, -1.0, true)
		draw_arc(bp, br, 0.0, TAU, 18, Color("#94a3b8"), grosor * 0.6, true)


func _dibujar_prop_en_mano(tipo: String, pos: Vector2, grosor: float, rig: Dictionary = {}, es_izquierda: bool = false, src: Personaje_Visual = null) -> void:
	var origen: Personaje_Visual = self if src == null else src
	var rot_p: float = float(rig.get("prop_l_rot" if es_izquierda else "prop_r_rot", 0.0))
	match tipo:
		"botella":
			var cuerpo := PackedVector2Array([
				pos + Vector2(-7.0, -18.0), pos + Vector2(7.0, -18.0),
				pos + Vector2(8.0, 10.0), pos + Vector2(-8.0, 10.0),
			])
			_poligono_tinta(cuerpo, Color("#38bdf8"), grosor * 0.75)
			var tapon := PackedVector2Array([
				pos + Vector2(-4.5, -24.0), pos + Vector2(4.5, -24.0),
				pos + Vector2(4.5, -18.0), pos + Vector2(-4.5, -18.0),
			])
			_poligono_tinta(tapon, Color("#1d4ed8"), grosor * 0.7)
		"tenedor":
			var con_bocado: bool = bool(rig.get("bocado_en_tenedor", true))
			_dibujar_tenedor(pos, rot_p, con_bocado, origen.color_bocado, origen.estilo_tenedor, grosor)
		"cuchillo":
			_dibujar_cuchillo(pos, rot_p, grosor)
		"vaso":
			var nivel: float = float(rig.get("nivel_bebida", 0.74))
			_dibujar_vaso(pos, rot_p, nivel, origen.color_bebida, origen.estilo_vaso, grosor)
		"servilleta":
			_dibujar_servilleta(pos, rot_p, origen.estilo_vaso, grosor)
		"esponja":
			var esp := _elipse_pts(pos + Vector2(-2.0, -4.0), 11.5, 8.5, 16, -0.3)
			_poligono_tinta(esp, Color("#fde047"), grosor * 0.75)
			for p_dot: Vector2 in [Vector2(-5.0, -5.0), Vector2(2.0, -3.0), Vector2(-1.0, 0.0)]:
				draw_circle(pos + p_dot, 1.6, Color("#ca8a04"), true, -1.0, true)
		"lapiz":
			draw_line(pos + Vector2(10.0, -16.0), pos + Vector2(-8.0, 8.0), TINTA, 6.0, true)
			draw_line(pos + Vector2(10.0, -16.0), pos + Vector2(-8.0, 8.0), Color("#facc15"), 3.5, true)
			draw_circle(pos + Vector2(11.0, -17.0), 2.8, Color("#fb7185"), true, -1.0, true)
		"mando":
			var m_pts := PackedVector2Array([
				pos + Vector2(-5.0, -14.0), pos + Vector2(5.0, -14.0),
				pos + Vector2(5.0, 12.0), pos + Vector2(-5.0, 12.0),
			])
			_poligono_tinta(m_pts, Color("#334155"), grosor * 0.72)
			draw_circle(pos + Vector2(0.0, -8.0), 2.2, Color("#ef4444"), true, -1.0, true)
		"pincel":
			draw_line(pos + Vector2(-8.0, 10.0), pos + Vector2(12.0, -16.0), TINTA, 5.2, true)
			draw_line(pos + Vector2(-8.0, 10.0), pos + Vector2(12.0, -16.0), Color("#b45309"), 2.8, true)
			draw_circle(pos + Vector2(14.5, -19.5), 4.6, Color("#ec4899"), true, -1.0, true)
			draw_arc(pos + Vector2(14.5, -19.5), 4.6, 0.0, TAU, 12, TINTA, 1.5, true)
		"espatula":
			draw_line(pos + Vector2(8.0, 10.0), pos + Vector2(-8.0, -16.0), TINTA, 5.4, true)
			draw_line(pos + Vector2(8.0, 10.0), pos + Vector2(-8.0, -16.0), Color("#b45309"), 3.0, true)
			var pala := PackedVector2Array([
				pos + Vector2(-14.0, -24.0), pos + Vector2(-4.0, -26.0),
				pos + Vector2(-3.0, -15.0), pos + Vector2(-12.0, -13.0),
			])
			_poligono_tinta(pala, Color("#cbd5e1"), grosor * 0.65)
		"taza":
			var t_pts := PackedVector2Array([
				pos + Vector2(-9.0, -10.0), pos + Vector2(9.0, -10.0),
				pos + Vector2(8.0, 10.0), pos + Vector2(-8.0, 10.0),
			])
			_poligono_tinta(t_pts, Color.WHITE, grosor * 0.75)
			draw_arc(pos + Vector2(9.0, 0.0), 5.0, -PI * 0.5, PI * 0.5, 10, TINTA, 2.4, true)
		"movil":
			var tel := PackedVector2Array([
				pos + Vector2(-8.0, -14.0), pos + Vector2(8.0, -14.0),
				pos + Vector2(8.0, 12.0), pos + Vector2(-8.0, 12.0),
			])
			_poligono_tinta(tel, Color("#1e293b"), grosor * 0.75)
			var pant := PackedVector2Array([
				pos + Vector2(-6.0, -11.0), pos + Vector2(6.0, -11.0),
				pos + Vector2(6.0, 9.0), pos + Vector2(-6.0, 9.0),
			])
			draw_colored_polygon(pant, Color("#38bdf8"))


func _dibujar_tenedor(pos: Vector2, rot: float, con_bocado: bool, col_bocado: Color, estilo: String, grosor: float) -> void:
	var es_plastico := (estilo == "plastico")
	var col_metal := Color("#f8fafc") if es_plastico else Color("#cbd5e1")
	var col_sombra := Color("#cbd5e1") if es_plastico else Color("#64748b")

	var mango := PackedVector2Array([
		Vector2(-2.6, 10.0), Vector2(2.6, 10.0),
		Vector2(1.8, -11.0), Vector2(4.6, -15.0),
		Vector2(-4.6, -15.0), Vector2(-1.8, -11.0),
	])
	_poligono_tinta(_transformar_pts(mango, pos, rot), col_metal, grosor * 0.62)
	draw_line(pos + _rotar(Vector2(0.8, 8.0), rot), pos + _rotar(Vector2(0.8, -11.0), rot), col_sombra, 1.3, true)

	for dx: float in [-3.4, 0.0, 3.4]:
		var p0 := pos + _rotar(Vector2(dx, -14.8), rot)
		var p1 := pos + _rotar(Vector2(dx * 1.05, -24.5), rot)
		draw_line(p0, p1, TINTA, 2.5, true)
		draw_line(p0, p1, col_metal, 1.1, true)

	if con_bocado:
		var centro_b := pos + _rotar(Vector2(0.0, -21.5), rot)
		var b_poly := _suavizar_cerrado(PackedVector2Array([
			Vector2(-5.4, -22.0), Vector2(-3.2, -26.2), Vector2(2.6, -26.0),
			Vector2(5.6, -22.2), Vector2(4.2, -17.8), Vector2(-3.8, -17.6),
		]), 3)
		_poligono_tinta(_transformar_pts(b_poly, pos, rot), col_bocado, grosor * 0.60)
		draw_circle(centro_b + _rotar(Vector2(1.5, 1.6), rot), 2.4, Color(col_bocado.darkened(0.24), 0.72), true, -1.0, true)
		draw_circle(centro_b + _rotar(Vector2(-1.8, -2.0), rot), 1.5, Color(1.0, 1.0, 1.0, 0.65), true, -1.0, true)
		draw_circle(centro_b + _rotar(Vector2(1.8, -1.8), rot), 1.2, Color("#22c55e"), true, -1.0, true)


func _dibujar_cuchillo(pos: Vector2, rot: float, grosor: float) -> void:
	var mango := PackedVector2Array([
		Vector2(-2.4, 9.0), Vector2(2.4, 9.0),
		Vector2(2.0, -3.0), Vector2(-2.0, -3.0),
	])
	_poligono_tinta(_transformar_pts(mango, pos, rot), Color("#64748b"), grosor * 0.58)
	var hoja := PackedVector2Array([
		Vector2(-1.8, -3.0), Vector2(2.0, -3.0),
		Vector2(2.8, -17.5), Vector2(0.2, -21.0), Vector2(-1.8, -17.0),
	])
	_poligono_tinta(_transformar_pts(hoja, pos, rot), Color("#e2e8f0"), grosor * 0.58)
	draw_line(pos + _rotar(Vector2(0.6, -4.5), rot), pos + _rotar(Vector2(1.2, -16.0), rot), Color.WHITE, 1.2, true)


func _dibujar_vaso(pos: Vector2, rot: float, nivel: float, col_bebida: Color, estilo: String, grosor: float) -> void:
	if estilo == "copa":
		var base_c := _elipse_pts(pos + _rotar(Vector2(0.0, 11.5), rot), 6.2, 2.0, 16, rot)
		_poligono_tinta(base_c, Color("#e0f2fe"), grosor * 0.55)
		draw_line(pos + _rotar(Vector2(0.0, 11.0), rot), pos + _rotar(Vector2(0.0, 2.0), rot), TINTA, 3.2, true)
		draw_line(pos + _rotar(Vector2(0.0, 11.0), rot), pos + _rotar(Vector2(0.0, 2.0), rot), Color("#e0f2fe"), 1.5, true)
		var caliz := _suavizar_cerrado(PackedVector2Array([
			Vector2(-7.8, -13.0), Vector2(7.8, -13.0),
			Vector2(7.4, -2.0), Vector2(3.6, 2.8), Vector2(-3.6, 2.8), Vector2(-7.4, -2.0),
		]), 3)
		_poligono_tinta(_transformar_pts(caliz, pos, rot), Color(0.88, 0.96, 1.0, 0.80), grosor * 0.62)
		var y_liq := lerpf(0.0, -9.0, clampf(nivel, 0.15, 0.95))
		var inclin := clampf(rot * 4.0, -3.5, 3.5)
		var liq_c := PackedVector2Array([
			Vector2(-6.5, y_liq - inclin), Vector2(6.5, y_liq + inclin),
			Vector2(6.0, -2.0), Vector2(3.0, 1.8), Vector2(-3.0, 1.8), Vector2(-6.0, -2.0),
		])
		draw_colored_polygon(_transformar_pts(liq_c, pos, rot), col_bebida)
		var boca_c := _elipse_pts(pos + _rotar(Vector2(0.0, -13.0), rot), 7.8, 2.2, 18, rot)
		_poligono_tinta(boca_c, Color(1.0, 1.0, 1.0, 0.45), grosor * 0.55)
		draw_line(pos + _rotar(Vector2(-4.4, -10.0), rot), pos + _rotar(Vector2(-4.0, -2.0), rot), Color(1.0, 1.0, 1.0, 0.8), 1.6, true)
		return

	if estilo == "carton":
		var cup := PackedVector2Array([
			Vector2(-8.2, -12.5), Vector2(8.2, -12.5),
			Vector2(6.0, 10.5), Vector2(-6.0, 10.5),
		])
		_poligono_tinta(_transformar_pts(cup, pos, rot), Color("#f8fafc"), grosor * 0.65)
		var banda := PackedVector2Array([
			Vector2(-7.3, -4.5), Vector2(7.3, -4.5),
			Vector2(6.6, 3.5), Vector2(-6.6, 3.5),
		])
		_poligono_tinta(_transformar_pts(banda, pos, rot), Color("#d97706"), grosor * 0.45)
		var tapa := PackedVector2Array([
			Vector2(-9.2, -15.5), Vector2(9.2, -15.5),
			Vector2(8.6, -12.0), Vector2(-8.6, -12.0),
		])
		_poligono_tinta(_transformar_pts(tapa, pos, rot), Color("#e2e8f0"), grosor * 0.62)
		return

	var v_pts := PackedVector2Array([
		Vector2(-8.2, -13.0), Vector2(8.2, -13.0),
		Vector2(6.2, 10.5), Vector2(-6.2, 10.5),
	])
	_poligono_tinta(_transformar_pts(v_pts, pos, rot), Color(0.84, 0.95, 1.0, 0.78), grosor * 0.68)

	var y_top := lerpf(6.5, -8.5, clampf(nivel, 0.15, 0.95))
	var tilt_y := clampf(rot * 4.5, -3.5, 3.5)
	var w_top := lerpf(5.6, 7.2, (10.5 - y_top) / 23.5)
	var zumo := PackedVector2Array([
		Vector2(-w_top, y_top - tilt_y), Vector2(w_top, y_top + tilt_y),
		Vector2(5.4, 9.2), Vector2(-5.4, 9.2),
	])
	draw_colored_polygon(_transformar_pts(zumo, pos, rot), col_bebida)
	var menisco := _elipse_pts(pos + _rotar(Vector2(0.0, y_top), rot), w_top, 1.8, 14, rot * 0.45)
	draw_colored_polygon(menisco, col_bebida.lightened(0.22))

	var rim := _elipse_pts(pos + _rotar(Vector2(0.0, -13.0), rot), 8.2, 2.2, 18, rot)
	_poligono_tinta(rim, Color(1.0, 1.0, 1.0, 0.45), grosor * 0.58)
	draw_line(pos + _rotar(Vector2(-4.8, -9.5), rot), pos + _rotar(Vector2(-3.8, 6.5), rot), Color(1.0, 1.0, 1.0, 0.78), 1.8, true)


func _dibujar_servilleta(pos: Vector2, rot: float, estilo: String, grosor: float) -> void:
	var col_tela := Color("#fef3c7") if estilo == "copa" else Color("#ffffff")
	var col_borde := Color("#f59e0b") if estilo == "copa" else Color("#ef4444")
	var serv := _suavizar_cerrado(PackedVector2Array([
		Vector2(-10.5, -7.5), Vector2(9.5, -9.5),
		Vector2(11.0, 8.5), Vector2(-8.5, 9.5),
	]), 2)
	_poligono_tinta(_transformar_pts(serv, pos, rot), col_tela, grosor * 0.65)
	draw_line(pos + _rotar(Vector2(-7.5, -4.5), rot), pos + _rotar(Vector2(7.0, 6.0), rot), Color("#cbd5e1"), 1.6, true)
	draw_line(pos + _rotar(Vector2(-6.5, 5.5), rot), pos + _rotar(Vector2(7.5, 4.5), rot), Color(col_borde, 0.65), 1.8, true)


# ---------------------------------------------------------------- utilidades geométricas y Catmull-Rom

func _suavizar_cerrado(pts: PackedVector2Array, segs: int = 4) -> PackedVector2Array:
	var n := pts.size()
	if n < 3:
		return pts
	var out := PackedVector2Array()
	for i in range(n):
		var p0 := pts[(i - 1 + n) % n]
		var p1 := pts[i]
		var p2 := pts[(i + 1) % n]
		var p3 := pts[(i + 2) % n]
		for s in range(segs):
			var t := float(s) / float(segs)
			var t2 := t * t
			var t3 := t2 * t
			var q := 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			out.append(q)
	return out


func _suavizar_abierta(pts: PackedVector2Array, segs: int = 4) -> PackedVector2Array:
	var n := pts.size()
	if n < 2:
		return pts
	var ext := PackedVector2Array()
	ext.append(pts[0])
	for p: Vector2 in pts:
		ext.append(p)
	ext.append(pts[n - 1])
	var out := PackedVector2Array()
	for i in range(1, ext.size() - 2):
		var p0 := ext[i - 1]
		var p1 := ext[i]
		var p2 := ext[i + 1]
		var p3 := ext[i + 2]
		for s in range(segs):
			var t := float(s) / float(segs)
			var t2 := t * t
			var t3 := t2 * t
			var q := 0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			out.append(q)
	out.append(pts[n - 1])
	return out


func _recortar_elipse_a_ojo(centro: Vector2, rx_i: float, ry_i: float, ec: Vector2, rx_ojo: float, ry_ojo: float, segs: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		var px := centro.x + cos(a) * rx_i
		var py := centro.y + sin(a) * ry_i
		var dx := (px - ec.x) / rx_ojo
		var dy := (py - ec.y) / ry_ojo
		var d := sqrt(dx * dx + dy * dy)
		if d > 0.96:
			px = ec.x + (dx / d) * rx_ojo * 0.96
			py = ec.y + (dy / d) * ry_ojo * 0.96
		var nx := clampf((px - ec.x) / rx_ojo, -1.0, 1.0)
		var lid_top := ec.y - ry_ojo * (0.86 - 0.52 * nx * nx)
		var lid_bot := ec.y + ry_ojo * (0.78 - 0.44 * nx * nx)
		py = clampf(py, lid_top, lid_bot)
		out.append(Vector2(px, py))
	return out


func _poligono_tinta(pts: PackedVector2Array, relleno: Color, grosor: float) -> void:
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, relleno)
	var cerrado := PackedVector2Array(pts)
	cerrado.append(pts[0])
	draw_polyline(cerrado, TINTA, grosor, true)


func _elipse_pts(centro: Vector2, rx: float, ry: float, segs: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ca := cos(rot)
	var sa := sin(rot)
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		var lx := cos(a) * rx
		var ly := sin(a) * ry
		pts.append(centro + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
	return pts


func _transformar_pts(pts: PackedVector2Array, pos: Vector2, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var ca := cos(rot)
	var sa := sin(rot)
	for p in pts:
		out.append(pos + Vector2(p.x * ca - p.y * sa, p.x * sa + p.y * ca))
	return out


func _rotar(v: Vector2, rot: float) -> Vector2:
	var ca := cos(rot)
	var sa := sin(rot)
	return Vector2(v.x * ca - v.y * sa, v.x * sa + v.y * ca)


func _sombra_piel(piel: Color) -> Color:
	var s := piel.darkened(0.18)
	s.r = minf(1.0, s.r * 1.04)
	return s
