class_name Personaje_Visual
extends Control
## Renderizador modular y articulado del personaje en estilo cómic (curvas suaves, tinta #111827 y cel-shading).
## Reutilizable en el creador de personaje, las viñetas del cómic, el avatar circular
## de la barra superior y preparado con rig articulado para futuras animaciones de actividad
## (correr, estudiar, dormir, trabajar, etc.).

const TINTA := Color("#111827")

var apariencia: Dictionary = Apariencia_Personaje.por_defecto():
	set(val):
		apariencia = Apariencia_Personaje.normalizar(val)
		queue_redraw()

## "retrato" (cara/hombros), "busto" (medio cuerpo), "cuerpo_completo" (cuerpo entero)
var modo: String = "busto":
	set(val):
		modo = val
		queue_redraw()

## "idle", "celebrar", "sorpresa", "volando", "correr" (y extensible para futuras actividades)
var pose: String = "idle":
	set(val):
		pose = val
		queue_redraw()

## "feliz", "sonrisa", "sorpresa", "panico", "neutral", "concentrado", "cansado"
var expresion: String = "feliz":
	set(val):
		expresion = val
		queue_redraw()

## "ninguno", "gorro_fiesta", "gorro_volando"
var accesorio_cabeza: String = "ninguno":
	set(val):
		accesorio_cabeza = val
		queue_redraw()

## "ninguno", "tarta_18", "botella", "tenedor", "vaso", "servilleta", "cuchillo", "esponja", "lapiz", "mando", "pincel", "taza", "movil"
var prop_mano: String = "ninguno":
	set(val):
		prop_mano = val
		queue_redraw()

## Prop opcional en la mano izquierda ("ninguno", "cuchillo", "servilleta")
var prop_mano_izq: String = "ninguno":
	set(val):
		prop_mano_izq = val
		queue_redraw()

## Micro-acción espontánea temporal dentro de la actividad actual (ej. "sprint", "cantar", "roncar", "beber", etc.)
var variacion: String = "":
	set(val):
		variacion = val
		queue_redraw()

## Progreso normalizado (0..1) de la variación activa
var fase_variacion: float = 0.0

## Control de capas para intercalar muebles (ej. mesa de comer entre torso y brazos):
## "completo" (default), "sin_brazos_delanteros", "solo_brazos_delanteros"
var modo_capa: String = "completo":
	set(val):
		modo_capa = val
		queue_redraw()

## Si este nodo es una capa "solo_brazos_delanteros", copia estado y rig desde el personaje base
var fuente_overlay: Personaje_Visual = null

## Estado detallado del ciclo de comida (conducido por Escenario_Actividad o automático desde _t)
var ciclo_comer: float = -1.0
var color_bocado: Color = Color("#f59e0b")
var color_bebida: Color = Color("#fb923c")
var estilo_vaso: String = "normal" # "normal", "copa", "carton"
var estilo_tenedor: String = "metal" # "metal", "plastico"
var mancha_salsa: bool = false

## Oculta la sudadera y dibuja hombros descubiertos (para la escena de ducha, con espuma delante)
var en_ducha: bool = false:
	set(val):
		en_ducha = val
		queue_redraw()

var animar_idle: bool = true:
	set(val):
		animar_idle = val
		set_process(animar_idle)
		queue_redraw()

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
	set_process(animar_idle)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()


## Configura pose y expresión base para una actividad del catálogo.
func establecer_actividad(nombre_actividad: String) -> void:
	pose = Apariencia_Personaje.pose_para_actividad(nombre_actividad)
	en_ducha = (pose == "duchar")
	variacion = ""
	prop_mano = "ninguno"
	prop_mano_izq = "ninguno"
	mancha_salsa = false
	match pose:
		"correr":
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
	var rig := obtener_rig_pose(pose, _t, es_mujer)
	var tr := _calcular_transform_camara()
	var esc: float = tr["scale"]
	var centro: Vector2 = tr["origin"]
	var rig_off: Vector2 = rig["offset"]
	var rig_rot: float = float(rig["root_rot"])
	var origen: Vector2 = centro + rig_off * esc
	return position + origen + _rotar(punto_local, rig_rot) * esc


func obtener_punta_tenedor_escena() -> Vector2:
	var es_mujer := Apariencia_Personaje.es_mujer(apariencia)
	var rig := obtener_rig_pose(pose, _t, es_mujer)
	var mano_r: Vector2 = rig["arm_r"][2]
	var rot_p: float = float(rig.get("prop_r_rot", -0.85))
	var punta_local := mano_r + _rotar(Vector2(0.0, -22.0), rot_p)
	return obtener_punto_local_a_escena(punta_local)


# ---------------------------------------------------------------- rig articulado

func obtener_rig_pose(nombre_pose: String, t: float, es_mujer: bool) -> Dictionary:
	var sh_x := 28.0 if es_mujer else 33.0
	var hip_x := 14.0 if es_mujer else 15.5
	var bob := sin(t * 2.4) * 1.5 if animar_idle else 0.0

	var rig := {
		"offset": Vector2(0.0, bob),
		"root_rot": 0.0,
		"head_offset": Vector2(0.0, bob * 0.35),
		"head_rot": 0.0,
		"arm_l": [Vector2(-sh_x, 58.0), Vector2(-sh_x - 11.0, 92.0), Vector2(-sh_x - 7.0, 124.0)],
		"arm_r": [Vector2(sh_x, 58.0), Vector2(sh_x + 11.0, 92.0), Vector2(sh_x + 7.0, 124.0)],
		"hand_l_tipo": "abierta",
		"hand_r_tipo": "abierta",
		"leg_l": [Vector2(-hip_x, 124.0), Vector2(-hip_x - 1.0, 166.0), Vector2(-hip_x - 2.0, 204.0)],
		"leg_r": [Vector2(hip_x, 124.0), Vector2(hip_x + 1.0, 166.0), Vector2(hip_x + 2.0, 204.0)],
		"mirada": Vector2.ZERO,
		"brazos_delante": false,
	}

	match nombre_pose:
		"celebrar":
			var b := sin(t * 3.2) * 1.6 if animar_idle else 0.0
			rig["offset"] = Vector2(0.0, b)
			rig["head_rot"] = deg_to_rad(-3.0)
			rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 26.0, 76.0), Vector2(-sh_x - 24.0, 34.0)]
			rig["hand_l_tipo"] = "puno"
			rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 24.0, 94.0), Vector2(sh_x + 56.0, 88.0)]
			rig["hand_r_tipo"] = "sostener"
			rig["mirada"] = Vector2(1.4, -0.5)
		"sorpresa":
			var temblor := sin(t * 24.0) * 0.9 if animar_idle else 0.0
			rig["offset"] = Vector2(temblor, 2.0)
			rig["head_rot"] = deg_to_rad(1.5)
			rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 18.0, 80.0), Vector2(-33.0, 14.0)]
			rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 18.0, 80.0), Vector2(33.0, 14.0)]
			rig["hand_l_tipo"] = "mejilla_l"
			rig["hand_r_tipo"] = "mejilla_r"
			rig["brazos_delante"] = true
		"volando":
			var osc := sin(t * 9.5) * 2.2 if animar_idle else 0.0
			rig["offset"] = Vector2(0.0, osc)
			rig["root_rot"] = deg_to_rad(25.0)
			rig["head_rot"] = deg_to_rad(-16.0)
			rig["arm_l"] = [Vector2(-sh_x, 56.0), Vector2(-sh_x - 30.0, 34.0), Vector2(-sh_x - 52.0, 44.0)]
			rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 26.0, 74.0), Vector2(sh_x + 44.0, 94.0)]
			rig["leg_l"] = [Vector2(-hip_x, 122.0), Vector2(-50.0, 142.0), Vector2(-84.0, 148.0)]
			rig["leg_r"] = [Vector2(hip_x, 122.0), Vector2(4.0, 162.0), Vector2(-24.0, 182.0)]
			rig["mirada"] = Vector2(-2.2, 1.2)
		"correr":
			var vel: float = 14.0 if variacion == "sprint" else (6.5 if variacion in ["beber_agua", "secar_sudor"] else 9.0)
			var cyc: float = sin(t * vel)
			var salto_y: float = 0.0
			if variacion == "salto":
				salto_y = -sin(clampf(fase_variacion, 0.0, 1.0) * PI) * 26.0
			rig["offset"] = Vector2(0.0, -absf(cyc) * 6.5 + salto_y)
			rig["root_rot"] = deg_to_rad(13.0 if variacion == "sprint" else 8.0)
			rig["head_rot"] = deg_to_rad(-4.0)
			rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 10.0 + cyc * 16.0, 84.0), Vector2(-sh_x + cyc * 26.0, 68.0)]
			rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 10.0 - cyc * 16.0, 84.0), Vector2(sh_x - cyc * 26.0, 68.0)]
			rig["leg_l"] = [Vector2(-hip_x, 124.0), Vector2(-hip_x + cyc * 22.0, 162.0), Vector2(-hip_x + cyc * 34.0, 200.0 - maxf(0.0, cyc) * 16.0)]
			rig["leg_r"] = [Vector2(hip_x, 124.0), Vector2(hip_x - cyc * 22.0, 162.0), Vector2(hip_x - cyc * 34.0, 200.0 - maxf(0.0, -cyc) * 16.0)]
			rig["mirada"] = Vector2(1.8, -0.4)
			if variacion == "secar_sudor":
				var sw := sin(t * 7.5) * 9.0
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 20.0, 44.0), Vector2(6.0 + sw, -20.0)]
				rig["brazos_delante"] = true
			elif variacion == "beber_agua":
				rig["head_rot"] = deg_to_rad(-11.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 18.0, 66.0), Vector2(16.0, 22.0)]
				rig["brazos_delante"] = true
		"dormir":
			var resp := sin(t * 1.9) * 2.0
			var rot_cabeza := deg_to_rad(-9.0) + sin(t * 1.3) * 0.04
			if variacion == "darse_vuelta":
				rot_cabeza = deg_to_rad(16.0 * sin(clampf(fase_variacion, 0.0, 1.0) * PI))
			elif variacion == "roncar":
				resp = sin(t * 3.8) * 3.2
			rig["offset"] = Vector2(0.0, resp)
			rig["head_rot"] = rot_cabeza
			rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 14.0, 82.0), Vector2(-22.0, 56.0)]
			rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 14.0, 82.0), Vector2(22.0, 56.0)]
			if variacion == "estirar_brazo":
				var est := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 24.0, 26.0 - est * 18.0), Vector2(-sh_x - 14.0, -14.0 - est * 24.0)]
		"comer":
			_aplicar_rig_comer(rig, sh_x, t)
		"duchar":
			var frote := sin(t * 7.0)
			rig["offset"] = Vector2(0.0, sin(t * 3.5) * 1.6)
			rig["head_rot"] = deg_to_rad(frote * 4.5)
			rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 16.0, 78.0), Vector2(-18.0 + frote * 6.0, 62.0)]
			rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 18.0, 48.0), Vector2(14.0 - frote * 9.0, -28.0)]
			rig["brazos_delante"] = true
			if variacion == "cantar":
				rig["head_rot"] = deg_to_rad(sin(t * 5.0) * 9.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 18.0, 68.0), Vector2(16.0, 26.0)]
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 24.0, 56.0), Vector2(-sh_x - 32.0, 26.0)]
			elif variacion == "espuma_pelo":
				var sf := sin(t * 11.0) * 8.0
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 18.0, 34.0), Vector2(-16.0 + sf, -34.0)]
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 18.0, 34.0), Vector2(16.0 - sf, -34.0)]
			elif variacion == "agua_fria":
				rig["offset"] = Vector2(sin(t * 34.0) * 3.2, -3.0)
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 8.0, 78.0), Vector2(10.0, 70.0)]
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 8.0, 78.0), Vector2(-10.0, 70.0)]
		"estudiar":
			var scribble := sin(t * 10.0) * 5.0
			rig["offset"] = Vector2(0.0, 2.0 + sin(t * 2.0) * 0.9)
			rig["head_rot"] = deg_to_rad(5.0)
			rig["mirada"] = Vector2(0.0, 2.2)
			rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 10.0, 88.0), Vector2(-16.0, 96.0)]
			rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 12.0, 88.0), Vector2(14.0 + scribble, 94.0)]
			rig["brazos_delante"] = true
			if variacion == "bombilla":
				rig["head_rot"] = deg_to_rad(-6.0)
				rig["mirada"] = Vector2(0.0, -1.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 22.0, 48.0), Vector2(sh_x + 18.0, 12.0)]
			elif variacion == "pensar":
				rig["head_rot"] = deg_to_rad(-8.0)
				rig["mirada"] = Vector2(2.0, -1.8)
				rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 14.0, 72.0), Vector2(12.0, 34.0)]
			elif variacion == "pasar_pagina":
				var pg := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 8.0, 82.0), Vector2(-12.0 + pg * 30.0, 92.0 - pg * 18.0)]
			elif variacion == "bostezo":
				rig["head_rot"] = deg_to_rad(-7.0)
				rig["arm_l"] = [Vector2(-sh_x, 58.0), Vector2(-sh_x - 24.0, 38.0), Vector2(-sh_x - 18.0, 4.0)]
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 24.0, 38.0), Vector2(sh_x + 18.0, 4.0)]
		"tv":
			rig["offset"] = Vector2(0.0, sin(t * 2.0) * 1.2)
			rig["head_rot"] = deg_to_rad(-2.0)
			rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 14.0, 86.0), Vector2(-24.0, 96.0)]
			rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 14.0, 86.0), Vector2(24.0, 96.0)]
			rig["brazos_delante"] = true
			if variacion == "reir":
				rig["offset"] = Vector2(0.0, sin(t * 16.0) * 3.0)
				rig["head_rot"] = deg_to_rad(-7.0 + sin(t * 12.0) * 4.0)
			elif variacion == "palomitas":
				var pc := (sin(t * 5.0) + 1.0) * 0.5
				rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 18.0, 74.0), Vector2(14.0 + (1.0 - pc) * 18.0, 26.0 + (1.0 - pc) * 54.0)]
			elif variacion == "cambiar_canal":
				rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 24.0, 76.0), Vector2(sh_x + 42.0, 66.0)]
			elif variacion == "sorpresa_tv":
				rig["offset"] = Vector2(0.0, -4.0)
		"manualidades":
			var trazo := sin(t * 6.5) * 10.0
			rig["offset"] = Vector2(0.0, sin(t * 2.5) * 1.3)
			rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 14.0, 84.0), Vector2(-20.0, 92.0)]
			rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 22.0, 68.0), Vector2(26.0 + trazo, 52.0 + cos(t * 6.5) * 7.0)]
			rig["brazos_delante"] = true
			if variacion == "pincelada_rapida":
				var tr2 := sin(t * 15.0) * 14.0
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 24.0, 62.0), Vector2(24.0 + tr2, 46.0 + cos(t * 15.0) * 10.0)]
			elif variacion == "admirar":
				rig["head_rot"] = deg_to_rad(-9.0)
				rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 14.0, 74.0), Vector2(12.0, 34.0)]
		"trabajar":
			var tec_l := sin(t * 12.0) * 4.0
			var tec_r := cos(t * 12.0) * 4.0
			rig["offset"] = Vector2(0.0, sin(t * 2.2) * 1.0)
			rig["mirada"] = Vector2(0.0, 1.5)
			rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 10.0, 88.0), Vector2(-14.0, 96.0 + tec_l)]
			rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 10.0, 88.0), Vector2(14.0, 96.0 + tec_r)]
			rig["brazos_delante"] = true
			if variacion == "cafe":
				rig["head_rot"] = deg_to_rad(-6.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 18.0, 68.0), Vector2(14.0, 26.0)]
			elif variacion == "mirar_reloj":
				rig["head_rot"] = deg_to_rad(8.0)
				rig["mirada"] = Vector2(-2.0, 2.0)
				rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 12.0, 76.0), Vector2(-14.0, 56.0)]
			elif variacion == "ganar_dinero":
				rig["head_rot"] = deg_to_rad(-4.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 22.0, 56.0), Vector2(sh_x + 20.0, 22.0)]
				rig["hand_r_tipo"] = "puno"
		_:
			# "idle" (Tiempo libre) con variaciones vivas
			if variacion == "saludar":
				var wave := sin(t * 11.0) * 11.0
				rig["head_rot"] = deg_to_rad(-5.0)
				rig["arm_r"] = [Vector2(sh_x, 58.0), Vector2(sh_x + 26.0, 48.0), Vector2(sh_x + 28.0 + wave, 14.0)]
				rig["brazos_delante"] = true
			elif variacion == "mirar_movil":
				rig["head_rot"] = deg_to_rad(6.0)
				rig["mirada"] = Vector2(0.0, 2.4)
				rig["arm_l"] = [Vector2(-sh_x, 60.0), Vector2(-sh_x - 10.0, 86.0), Vector2(-10.0, 76.0)]
				rig["arm_r"] = [Vector2(sh_x, 60.0), Vector2(sh_x + 10.0, 86.0), Vector2(10.0, 74.0)]
				rig["brazos_delante"] = true
			elif variacion == "estirarse":
				var st := sin(clampf(fase_variacion, 0.0, 1.0) * PI)
				rig["offset"] = Vector2(0.0, -st * 5.0)
				rig["arm_l"] = [Vector2(-sh_x, 56.0), Vector2(-sh_x - 22.0, 32.0 - st * 18.0), Vector2(-sh_x - 12.0, -6.0 - st * 22.0)]
				rig["arm_r"] = [Vector2(sh_x, 56.0), Vector2(sh_x + 22.0, 32.0 - st * 18.0), Vector2(sh_x + 12.0, -6.0 - st * 22.0)]
			elif variacion == "silbar":
				rig["head_rot"] = deg_to_rad(sin(t * 4.5) * 8.0)
				rig["mirada"] = Vector2(1.8, -1.6)

	return rig


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


func _aplicar_rig_comer(rig: Dictionary, sh_x: float, t: float) -> void:
	rig["brazos_delante"] = true

	var sh_l := Vector2(-sh_x, 57.0)
	var sh_r := Vector2(sh_x, 57.0)
	var el_l_rep := Vector2(-sh_x - 15.0, 76.0)
	var ha_l_rep := Vector2(-35.0, 76.0)
	var el_r_rep := Vector2(sh_x + 15.0, 76.0)
	var ha_r_rep := Vector2(36.0, 75.0)
	var rot_r_rep := -1.12

	var el_r_plato := Vector2(sh_x + 12.0, 72.0)
	var ha_r_plato := Vector2(22.0, 67.0)
	var rot_r_plato := -2.06

	var el_r_boca := Vector2(sh_x + 14.0, 65.0)
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

	var fase := clampf(fase_variacion, 0.0, 1.0)

	match variacion:
		"beber":
			# Alcanza el vaso en la mesa, lo levanta, bebe con 2 sorbos y lo devuelve suavemente
			var vaso_mesa := Vector2(63.0, 71.0)
			var el_vaso_mesa := Vector2(sh_x + 22.0, 72.0)
			var vaso_boca := Vector2(20.0, 34.5)
			var el_vaso_boca := Vector2(sh_x + 16.0, 63.0)

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
				rig["mirada"] = Vector2(1.8 * k, 1.8 * k)
			elif fase < 0.38:
				var k := _suave_mas((fase - 0.18) / 0.20)
				el_r = el_vaso_mesa.lerp(el_vaso_boca, k)
				ha_r = vaso_mesa.lerp(vaso_boca, k) + Vector2(sin(k * PI) * 8.0, -sin(k * PI) * 5.0)
				rot_v = lerpf(0.0, -0.66, k)
				h_rot = deg_to_rad(lerpf(0.0, -7.5, k))
				rig["mirada"] = Vector2(1.8 * (1.0 - k), 1.8 * (1.0 - k))
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
				rig["mirada"] = Vector2(1.6 * k, 1.6 * k)
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
			# Sostiene un bocado humeante delante de la boca, sopla en 2 ráfagas y se lo come feliz
			var el_sop := Vector2(sh_x + 18.0, 66.0)
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
				rig["mirada"] = Vector2(0.8, 1.5)
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
				rig["mirada"] = Vector2(0.9, 1.6)
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
			# Sube ambas manos a las mejillas con balanceo feliz y brillo
			var k := minf(_tramo(fase, 0.0, 0.18), 1.0 - _tramo(fase, 0.82, 1.0))
			var balanceo := sin(fase * TAU * 2.0) * k
			var h_rot := deg_to_rad(balanceo * 7.5)
			var dy := -absf(balanceo) * 2.2

			var mej_l := Vector2(-31.0, 19.5) + Vector2(balanceo * 2.2, dy)
			var mej_r := Vector2(31.0, 19.5) + Vector2(balanceo * 2.2, dy)
			var el_l_m := Vector2(-sh_x - 16.0, 62.0)
			var el_r_m := Vector2(sh_x + 16.0, 62.0)

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
			# Recoge la servilleta de la izquierda con la mano izquierda, da 2 toques suaves y la devuelve
			var serv_mesa := Vector2(-61.0, 77.0)
			var el_serv_mesa := Vector2(-sh_x - 20.0, 74.0)
			var serv_boca := Vector2(-10.0, 26.0)
			var el_serv_boca := Vector2(-sh_x - 16.0, 62.0)

			var el_l := el_l_rep
			var ha_l := ha_l_rep
			var rot_s := 0.0
			var h_rot := 0.0

			if fase < 0.18:
				var k := _tramo(fase, 0.0, 0.18)
				el_l = el_l_rep.lerp(el_serv_mesa, k)
				ha_l = ha_l_rep.lerp(serv_mesa, k)
				rig["mirada"] = Vector2(-1.8 * k, 1.8 * k)
			elif fase < 0.32:
				var k := _suave_mas((fase - 0.18) / 0.14)
				el_l = el_serv_mesa.lerp(el_serv_boca, k)
				ha_l = serv_mesa.lerp(serv_boca, k) + Vector2(-sin(k * PI) * 6.0, -sin(k * PI) * 4.0)
				rot_s = lerpf(0.0, 0.22, k)
				rig["mirada"] = Vector2(-1.8 * (1.0 - k), 1.8 * (1.0 - k))
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
				rig["mirada"] = Vector2(-1.4 * k, 1.6 * k)
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
			# Se inclina levemente sobre el plato e inhala profundamente el aroma con ojos cerrados
			var k := minf(_tramo(fase, 0.0, 0.20), 1.0 - _tramo(fase, 0.80, 1.0))
			var inhala := sin(clampf((fase - 0.15) / 0.70, 0.0, 1.0) * PI)
			rig["offset"] = Vector2(0.0, 3.0 * k - inhala * 3.6)
			rig["head_offset"] = Vector2(0.0, -inhala * 1.4)
			rig["head_rot"] = deg_to_rad(-6.5 * inhala + sin(t * 3.5) * 1.6 * k)
			rig["arm_l"] = [sh_l, el_l_rep.lerp(Vector2(-sh_x - 11.0, 75.0), k), ha_l_rep.lerp(Vector2(-23.0, 73.0), k)]
			rig["arm_r"] = [sh_r, el_r_rep.lerp(Vector2(sh_x + 11.0, 75.0), k), ha_r_rep.lerp(Vector2(23.0, 73.0), k)]
			rig["comer_rubor_extra"] = inhala * 0.20
			rig["comer_ojos_felices"] = k > 0.28
			rig["comer_expresion_override"] = "satisfecho" if k > 0.28 else "sonrisa"
			rig["prop_r_override"] = "ninguno"
			rig["prop_l_override"] = "ninguno"

		_:
			# Ciclo natural de comida en 4 fases: pinchar -> llevar a boca -> morder -> masticar feliz
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
				mirada = Vector2(0.4, 2.3)
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
				mirada = Vector2(0.4, 2.3)
				h_rot = deg_to_rad(3.4)
			elif c < 0.41:
				var k := _suave_mas((c - 0.22) / 0.19)
				el_r = el_r_plato.lerp(el_r_boca, k)
				ha_r = ha_r_plato.lerp(ha_r_boca, k) + Vector2(sin(k * PI) * 6.5, -sin(k * PI) * 4.0)
				rot_f = lerpf(rot_r_plato, rot_r_boca, k)
				ha_l = Vector2(-24.5, 72.5).lerp(ha_l_rep, k)
				rot_k = lerpf(1.65, 1.35, k)
				bocado = true
				mirada = Vector2(0.4, 2.3).lerp(Vector2(0.7, 0.7), k)
				h_rot = deg_to_rad(lerpf(3.4, -2.6, k))
				apertura = _tramo(c, 0.28, 0.40)
			elif c < 0.50:
				var u := (c - 0.41) / 0.09
				var acercar := sin(u * PI)
				el_r = el_r_boca
				ha_r = ha_r_boca + Vector2(-acercar * 2.4, -acercar * 1.0)
				rot_f = rot_r_boca - acercar * 0.06
				bocado = c < 0.46
				mirada = Vector2(0.6, 0.6)
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

			# Masticación rítmica y feliz entre 0.48 y 0.95
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
				mirada = Vector2(0.0, 0.0).lerp(Vector2(0.4, 2.3), km)

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
	var piel := Apariencia_Personaje.color_de(ap, "color_piel", Color("#f8cfb4"))
	var piel_sombra := _sombra_piel(piel)
	var ojos := Apariencia_Personaje.color_de(ap, "color_ojos", Color("#6b4226"))
	var pelo := Apariencia_Personaje.color_de(ap, "color_pelo", Color("#7c4728"))
	var ropa := Apariencia_Personaje.color_de(ap, "color_ropa", Color("#2563eb"))
	var estilo_pelo := str(ap.get("estilo_pelo", "alborotado"))
	var gafas := str(ap.get("gafas", "ninguna"))
	var vello := str(ap.get("vello_facial", "ninguno"))
	var pecas := bool(ap.get("pecas", false))

	var rig := src.obtener_rig_pose(src.pose, src._t, es_mujer)
	var tr := src._calcular_transform_camara()
	var esc: float = tr["scale"]
	var centro: Vector2 = tr["origin"]
	var grosor := 2.9

	draw_set_transform(centro + rig["offset"] * esc, rig["root_rot"], Vector2(esc, esc))

	var head_pos: Vector2 = rig["head_offset"]
	var head_rot: float = rig["head_rot"]
	var brazos_delante: bool = bool(rig.get("brazos_delante", false))

	var prop_r: String = str(rig.get("prop_r_override", src.prop_mano))
	var prop_l: String = str(rig.get("prop_l_override", src.prop_mano_izq))

	if modo_capa != "solo_brazos_delanteros":
		# 1. Pelo trasero (detrás del torso y cuello)
		_dibujar_pelo_trasero(head_pos, head_rot, estilo_pelo, pelo, grosor)

		# 2. Piernas (si cuerpo completo)
		if src.modo == "cuerpo_completo":
			_dibujar_piernas(rig["leg_l"], rig["leg_r"], ropa, grosor)

		# 3. Brazos traseros
		if not brazos_delante:
			_dibujar_brazo(rig["arm_l"], ropa, piel, piel_sombra, rig["hand_l_tipo"], grosor)
			_dibujar_brazo(rig["arm_r"], ropa, piel, piel_sombra, rig["hand_r_tipo"], grosor)

		# 4. Torso / sudadera y cuello
		_dibujar_torso(es_mujer, ropa, piel, piel_sombra, grosor)

		# 5. Cabeza + cara + pelo delantero + accesorios
		_dibujar_cabeza_completa(
			head_pos, head_rot, es_mujer, piel, piel_sombra, ojos, pelo,
			estilo_pelo, gafas, vello, pecas, rig["mirada"], grosor, rig
		)

		# Espuma de champú en la cabeza durante la ducha
		if src.en_ducha and src.variacion == "espuma_pelo":
			_dibujar_espuma_cabeza(head_pos, head_rot, grosor)

	if modo_capa != "sin_brazos_delanteros":
		# 6. Brazos delanteros (cuando interactúan delante del rostro/pecho: comer, ducha, sorpresa, estudiar, etc.)
		if brazos_delante:
			_dibujar_brazo(rig["arm_l"], ropa, piel, piel_sombra, rig["hand_l_tipo"], grosor)
			_dibujar_brazo(rig["arm_r"], ropa, piel, piel_sombra, rig["hand_r_tipo"], grosor)

		# 7. Props en mano izquierda y derecha
		if prop_l != "ninguno":
			var pos_mano_l: Vector2 = rig["arm_l"][2]
			_dibujar_prop_en_mano(prop_l, pos_mano_l, grosor, rig, true, src)

		if prop_r != "ninguno":
			var pos_mano_r: Vector2 = rig["arm_r"][2]
			if prop_r == "tarta_18":
				_dibujar_tarta_18(pos_mano_r + Vector2(8.0, -4.0), grosor)
			else:
				_dibujar_prop_en_mano(prop_r, pos_mano_r, grosor, rig, false, src)

		# 8. Gotas de sudor cómicas en pose sorpresa o al secarse el sudor corriendo
		if src.pose == "sorpresa" or (src.pose == "correr" and src.variacion in ["secar_sudor", "sprint"]):
			_dibujar_gotas_sudor(head_pos + Vector2(44.0, -14.0), grosor)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _calcular_transform_camara() -> Dictionary:
	var view_rect: Rect2
	match modo:
		"retrato":
			view_rect = Rect2(-50.0, -54.0, 100.0, 102.0)
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


# ---------------------------------------------------------------- piernas, brazos y torso

func _dibujar_piernas(leg_l: Array, leg_r: Array, ropa: Color, grosor: float) -> void:
	var vaquero := Color("#3b6ea5")
	var vaquero_sombra := Color("#294e78")
	var zapatilla := ropa.darkened(0.05)
	var idx := 0
	for pierna in [leg_l, leg_r]:
		var hip: Vector2 = pierna[0]
		var knee: Vector2 = pierna[1]
		var foot: Vector2 = pierna[2]
		_dibujar_extremidad_continua(hip, knee, foot, 13.0, 11.0, 9.0, vaquero, vaquero_sombra, grosor)
		var dir_pie := (foot - knee).normalized()
		var flip := -1.0 if (pose != "volando" and idx == 0) else 1.0
		_dibujar_zapatilla(foot, dir_pie, flip, zapatilla, grosor)
		idx += 1


func _dibujar_zapatilla(pos: Vector2, dir: Vector2, flip_x: float, color_zap: Color, grosor: float) -> void:
	var ang := atan2(dir.y, dir.x) - PI * 0.5
	var base := PackedVector2Array([
		Vector2(-9.5 * flip_x, -3.5),
		Vector2(9.5 * flip_x, -3.5),
		Vector2(17.5 * flip_x, 4.5),
		Vector2(17.0 * flip_x, 11.5),
		Vector2(-11.0 * flip_x, 11.5),
		Vector2(-11.5 * flip_x, 3.0),
	])
	var suela := PackedVector2Array([
		Vector2(-11.0 * flip_x, 8.0),
		Vector2(17.2 * flip_x, 8.0),
		Vector2(16.8 * flip_x, 12.2),
		Vector2(-10.8 * flip_x, 12.2),
	])
	var puntera := PackedVector2Array([
		Vector2(10.0 * flip_x, 1.5),
		Vector2(17.2 * flip_x, 4.5),
		Vector2(17.0 * flip_x, 8.2),
		Vector2(10.5 * flip_x, 8.2),
	])
	var centro := pos + Vector2(0.0, 4.5)
	_poligono_tinta(_transformar_pts(_suavizar_cerrado(base, 3), centro, ang), color_zap, grosor * 0.9)
	draw_colored_polygon(_transformar_pts(puntera, centro, ang), Color.WHITE)
	_poligono_tinta(_transformar_pts(suela, centro, ang), Color.WHITE, grosor * 0.78)


func _dibujar_brazo(arm: Array, ropa: Color, piel: Color, piel_sombra: Color, tipo_mano: String, grosor: float) -> void:
	var sh: Vector2 = arm[0]
	var el: Vector2 = arm[1]
	var ha: Vector2 = arm[2]
	var col_brazo: Color = piel if en_ducha else ropa
	var col_sombra: Color = piel_sombra if en_ducha else ropa.darkened(0.20)
	var muneca := el.lerp(ha, 0.80)

	_dibujar_extremidad_continua(sh, el, muneca, 10.6 if en_ducha else 11.2, 8.8 if en_ducha else 9.2, 7.2 if en_ducha else 7.6, col_brazo, col_sombra, grosor)

	var dir_m := (ha - el).normalized()
	if not en_ducha:
		var perp_m := Vector2(-dir_m.y, dir_m.x)
		var puno := PackedVector2Array([
			muneca - dir_m * 3.0 + perp_m * 8.2,
			muneca + dir_m * 3.2 + perp_m * 7.8,
			muneca + dir_m * 3.2 - perp_m * 7.8,
			muneca - dir_m * 3.0 - perp_m * 8.2,
		])
		_poligono_tinta(puno, col_sombra, grosor * 0.8)

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

	# Contorno cerrado continuo sin costuras en codo/rodilla
	var contorno := PackedVector2Array()
	for i in range(6):
		var a := atan2(n0.y, n0.x) + PI * float(i) / 5.0
		contorno.append(p0 + Vector2(cos(a), sin(a)) * r0)
	contorno.append(p1 - n_mid * r1)
	for i in range(6):
		var a := atan2(-n1.y, -n1.x) + PI * float(i) / 5.0
		contorno.append(p2 + Vector2(cos(a), sin(a)) * r2)
	contorno.append(p1 + n_mid * r1)

	draw_colored_polygon(contorno, relleno)

	# Banda de sombra sutil a un lado
	var som := PackedVector2Array([
		p0, p1, p2,
		lado_b[0], lado_b[1], lado_b[2],
	])
	draw_colored_polygon(som, Color(sombra, 0.45))

	# Un solo trazo de tinta exterior limpio
	var cerrado := PackedVector2Array(contorno)
	cerrado.append(contorno[0])
	draw_polyline(cerrado, TINTA, grosor, true)


func _dibujar_mano(pos: Vector2, dir: Vector2, piel: Color, piel_sombra: Color, tipo: String, grosor: float) -> void:
	match tipo:
		"puno":
			draw_circle(pos, 10.5, piel, true, -1.0, true)
			draw_arc(pos, 10.5, 0.0, TAU, 24, TINTA, grosor, true)
			draw_line(pos + Vector2(-5.5, -2.0), pos + Vector2(4.0, -2.0), piel_sombra, 2.2, true)
			draw_arc(pos + Vector2(3.5, 1.0), 4.5, -0.3, PI * 0.9, 10, TINTA, grosor * 0.75, true)
		"mejilla_l", "mejilla_r":
			var lado := -1.0 if tipo == "mejilla_l" else 1.0
			var palma := _elipse_pts(pos, 7.5, 11.5, 18, lado * -0.15)
			_poligono_tinta(palma, piel, grosor * 0.9)
			for i in range(-1, 2):
				var y := pos.y - 5.5 + float(i) * 3.4
				draw_line(Vector2(pos.x - 3.5 * lado, y), Vector2(pos.x + 2.5 * lado, y - 1.2), TINTA, 1.6, true)
		"sostener":
			var mano_s := _elipse_pts(pos + Vector2(3.0, 2.0), 11.0, 6.5, 18, 0.0)
			_poligono_tinta(mano_s, piel, grosor * 0.9)
		_:
			var ang := atan2(dir.y, dir.x)
			var palma := _elipse_pts(pos, 9.2, 7.6, 18, ang)
			_poligono_tinta(palma, piel, grosor * 0.9)
			var pulgar := pos + Vector2(cos(ang - 1.05), sin(ang - 1.05)) * 8.2
			draw_circle(pulgar, 3.6, piel, true, -1.0, true)
			draw_arc(pulgar, 3.6, 0.0, TAU, 12, TINTA, grosor * 0.75, true)


func _dibujar_torso(es_mujer: bool, ropa: Color, piel: Color, piel_sombra: Color, grosor: float) -> void:
	var sh_x := 30.0 if es_mujer else 35.5
	var waist_x := 23.5 if es_mujer else 30.5
	var hip_x := 29.5 if es_mujer else 33.0
	var nw := 9.2 if es_mujer else 10.8

	if en_ducha:
		# Hombros descubiertos (el primer plano de la ducha cubre el torso con espuma y vapor)
		var hombros := _suavizar_cerrado(PackedVector2Array([
			Vector2(-nw, 44.0), Vector2(nw, 44.0), Vector2(sh_x, 53.0),
			Vector2(sh_x, 120.0), Vector2(-sh_x, 120.0), Vector2(-sh_x, 53.0),
		]), 4)
		_poligono_tinta(hombros, piel, grosor)
		var cuello_d := PackedVector2Array([
			Vector2(-nw, 28.0), Vector2(nw, 28.0),
			Vector2(nw + 1.2, 50.0), Vector2(0.0, 56.0), Vector2(-nw - 1.2, 50.0),
		])
		draw_colored_polygon(cuello_d, piel)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-nw, 32.0), Vector2(nw, 32.0),
			Vector2(nw - 1.0, 43.0), Vector2(-nw + 2.0, 40.5),
		]), piel_sombra)
		return

	var ropa_sombra := ropa.darkened(0.22)
	var ropa_brillo := ropa.lightened(0.16)

	var torso_ctrl := PackedVector2Array([
		Vector2(-14.0, 44.0),
		Vector2(14.0, 44.0),
		Vector2(sh_x, 53.0),
		Vector2(sh_x + 2.0, 70.0),
		Vector2(waist_x, 100.0),
		Vector2(hip_x, 125.0),
		Vector2(0.0, 129.0),
		Vector2(-hip_x, 125.0),
		Vector2(-waist_x, 100.0),
		Vector2(-sh_x - 2.0, 70.0),
		Vector2(-sh_x, 53.0),
	])
	var torso := _suavizar_cerrado(torso_ctrl, 4)
	_poligono_tinta(torso, ropa, grosor)

	# Sombra lateral suave en el lado derecho
	var sombra_ctrl := PackedVector2Array([
		Vector2(13.0, 48.0),
		Vector2(sh_x - 2.0, 56.0),
		Vector2(sh_x, 70.0),
		Vector2(waist_x - 2.0, 100.0),
		Vector2(hip_x - 2.0, 124.0),
		Vector2(10.0, 126.0),
		Vector2(15.0, 96.0),
		Vector2(16.0, 68.0),
	])
	draw_colored_polygon(_suavizar_cerrado(sombra_ctrl, 3), Color(ropa_sombra, 0.7))
	draw_line(Vector2(-sh_x + 7.0, 56.0), Vector2(-17.0, 50.0), ropa_brillo, 3.0, true)

	# Cuello de piel
	var cuello_piel := PackedVector2Array([
		Vector2(-nw, 28.0),
		Vector2(nw, 28.0),
		Vector2(nw + 1.2, 50.0),
		Vector2(0.0, 56.0),
		Vector2(-nw - 1.2, 50.0),
	])
	_poligono_tinta(cuello_piel, piel, grosor * 0.88)

	# Sombra bajo la barbilla
	draw_colored_polygon(PackedVector2Array([
		Vector2(-nw, 32.0), Vector2(nw, 32.0),
		Vector2(nw - 1.0, 43.0), Vector2(-nw + 2.0, 40.5),
	]), piel_sombra)

	# Escote camiseta blanca interior
	var escote := PackedVector2Array([
		Vector2(-12.5, 45.0),
		Vector2(0.0, 55.0),
		Vector2(12.5, 45.0),
		Vector2(15.5, 50.5),
		Vector2(0.0, 62.0),
		Vector2(-15.5, 50.5),
	])
	_poligono_tinta(escote, Color.WHITE, grosor * 0.78)

	# Cuello/solapas suaves de la capucha
	var cap_l := _suavizar_cerrado(PackedVector2Array([
		Vector2(-12.5, 43.0), Vector2(-24.0, 49.0), Vector2(-18.0, 60.5), Vector2(-4.0, 62.0)
	]), 3)
	var cap_r := _suavizar_cerrado(PackedVector2Array([
		Vector2(12.5, 43.0), Vector2(24.0, 49.0), Vector2(18.0, 60.5), Vector2(4.0, 62.0)
	]), 3)
	_poligono_tinta(cap_l, ropa_sombra, grosor * 0.78)
	_poligono_tinta(cap_r, ropa_sombra, grosor * 0.78)

	# Cordones blancos de sudadera
	for lado: float in [-1.0, 1.0]:
		var x: float = lado * 8.2
		draw_line(Vector2(x, 60.0), Vector2(x + lado * 1.4, 86.0), TINTA, 4.4, true)
		draw_line(Vector2(x, 60.0), Vector2(x + lado * 1.4, 86.0), Color.WHITE, 2.3, true)
		draw_circle(Vector2(x + lado * 1.4, 87.5), 2.1, TINTA, true, -1.0, true)

	# Dobladillo inferior
	var dob := PackedVector2Array([
		Vector2(-hip_x + 1.0, 121.0), Vector2(hip_x - 1.0, 121.0),
		Vector2(hip_x, 127.5), Vector2(-hip_x, 127.5),
	])
	_poligono_tinta(dob, ropa_sombra, grosor * 0.78)


# ---------------------------------------------------------------- cabeza, cara y peinados

func _dibujar_cabeza_completa(
		head_pos: Vector2, head_rot: float, es_mujer: bool,
		piel: Color, piel_sombra: Color, ojos: Color, pelo: Color,
		estilo_pelo: String, gafas: String, vello: String, pecas: bool,
		mirada: Vector2, grosor: float, rig: Dictionary = {}) -> void:
	var c := head_pos
	var r := head_rot
	var expr_activa: String = str(rig.get("comer_expresion_override", ""))
	if expr_activa == "":
		expr_activa = expresion
	var mejillas_infladas: float = float(rig.get("comer_mejillas", 0.0))
	var rubor_extra: float = float(rig.get("comer_rubor_extra", 0.0))
	var ojos_felices_extra: bool = bool(rig.get("comer_ojos_felices", false))

	# 1. Orejas
	for lado: float in [-1.0, 1.0]:
		var o_pos: Vector2 = _rotar(Vector2(lado * 30.5, 5.5), r) + c
		var oreja := _elipse_pts(o_pos, 6.2, 9.5, 22, r + lado * 0.12)
		_poligono_tinta(oreja, piel, grosor * 0.85)
		var oreja_int := _elipse_pts(o_pos + _rotar(Vector2(-lado * 0.9, 0.5), r), 3.0, 5.0, 14, r)
		draw_colored_polygon(oreja_int, Color(piel_sombra, 0.7))
		draw_arc(o_pos + _rotar(Vector2(-lado * 0.8, 0.5), r), 3.0, 0.4, PI * 1.5, 10, Color(TINTA, 0.75), 1.4, true)

	# 2. Rostro con curva Catmull-Rom perfectamente suave (con ligera expansión en mejillas al masticar/soplar)
	var forma_cara := _forma_rostro(es_mujer)
	if mejillas_infladas > 0.02:
		var exp_m := mejillas_infladas * 2.8
		var mod := PackedVector2Array(forma_cara)
		mod[4] = mod[4] + Vector2(exp_m, 0.8 * mejillas_infladas)
		mod[8] = mod[8] + Vector2(-exp_m, 0.8 * mejillas_infladas)
		forma_cara = mod
	var cara_suave := _suavizar_cerrado(forma_cara, 5)
	_poligono_tinta(_transformar_pts(cara_suave, c, r), piel, grosor)

	# Sombra cel-shading suave en mejilla/mandíbula derecha
	var sombra_cara := _suavizar_cerrado(PackedVector2Array([
		Vector2(23.0, -14.0),
		Vector2(29.8, 3.0),
		Vector2(26.0, 20.0),
		Vector2(14.0, 32.0),
		Vector2(0.0, 35.8),
		Vector2(-8.0, 33.5),
		Vector2(8.0, 30.5),
		Vector2(19.0, 21.0),
		Vector2(24.0, 5.0),
	]), 3)
	draw_colored_polygon(_transformar_pts(sombra_cara, c, r), Color(piel_sombra, 0.38))

	# Sombra suave proyectada por el flequillo en la frente
	var sombra_frente := _suavizar_cerrado(PackedVector2Array([
		Vector2(-27.0, -19.0), Vector2(-12.0, -24.0), Vector2(0.0, -23.0),
		Vector2(12.0, -24.0), Vector2(27.0, -19.0), Vector2(24.0, -14.0),
		Vector2(0.0, -18.0), Vector2(-24.0, -14.0),
	]), 3)
	draw_colored_polygon(_transformar_pts(sombra_frente, c, r), Color(piel_sombra, 0.28))

	# Rubor cálido en mejillas (intensificado en "delicioso", "oler" y al masticar)
	var alpha_rubor: float = clampf((0.30 if es_mujer else 0.14) + rubor_extra + mejillas_infladas * 0.12, 0.0, 0.62)
	var color_rubor := Color("#fb7185", alpha_rubor)
	var rx_rubor := 6.5 + mejillas_infladas * 1.4 + rubor_extra * 3.0
	var ry_rubor := 3.6 + mejillas_infladas * 1.2 + rubor_extra * 1.6
	for lado: float in [-1.0, 1.0]:
		var pos_r: Vector2 = _rotar(Vector2(lado * (19.5 + mejillas_infladas * 1.2), 11.5 + mejillas_infladas * 1.6), r) + c
		draw_colored_polygon(_elipse_pts(pos_r, rx_rubor, ry_rubor, 18, r), color_rubor)
		# Curva cómica de carrillo inflado al masticar o soplar
		if mejillas_infladas > 0.35:
			var arco_m := _suavizar_abierta(PackedVector2Array([
				Vector2(lado * 16.5, 16.5),
				Vector2(lado * (19.2 + mejillas_infladas * 1.6), 19.5),
				Vector2(lado * 16.5, 22.8),
			]), 3)
			draw_polyline(_transformar_pts(arco_m, c, r), Color(piel_sombra, 0.55 * mejillas_infladas), 1.6, true)

	# Pecas opcionales
	if pecas:
		var col_peca := piel_sombra.darkened(0.28)
		for p: Vector2 in [
			Vector2(-18.5, 9.0), Vector2(-14.0, 11.2), Vector2(-21.5, 12.0),
			Vector2(18.5, 9.0), Vector2(14.0, 11.2), Vector2(21.5, 12.0),
			Vector2(-4.0, 8.8), Vector2(4.0, 8.8),
		]:
			draw_circle(_rotar(p, r) + c, 1.25, col_peca, true, -1.0, true)

	# 3. Barba corta (detrás de boca)
	if not es_mujer and vello == "barba_corta":
		_dibujar_vello_facial(c, r, vello, pelo, grosor)

	# 4. Ojos expresivos rediseñados (almendrados, iris grande con brillo y párpado superior)
	_dibujar_ojos(c, r, es_mujer, piel_sombra, ojos, mirada, grosor, expr_activa, ojos_felices_extra)

	# 5. Cejas esculpidas
	_dibujar_cejas(c, r, es_mujer, pelo, grosor)

	# 6. Nariz estilizada cómic
	_dibujar_nariz(c, r, piel, piel_sombra, grosor)

	# 7. Boca expresiva
	_dibujar_boca(c, r, es_mujer, piel_sombra, grosor, expr_activa, rig)

	# Pequeña mancha de salsa junto a la comisura durante la primera mitad de "limpiar_boca"
	if mancha_salsa:
		var p_mancha: Vector2 = _rotar(Vector2(-11.8, 22.0), r) + c
		draw_circle(p_mancha, 2.5, Color("#dc2626", 0.88), true, -1.0, true)
		draw_circle(p_mancha + _rotar(Vector2(-2.2, 2.2), r), 1.3, Color("#ea580c", 0.82), true, -1.0, true)

	# 8. Bigote / perilla
	if not es_mujer and (vello == "bigote" or vello == "perilla"):
		_dibujar_vello_facial(c, r, vello, pelo, grosor)

	# 9. Gafas (montura fina moderna y cristal muy translúcido)
	if gafas != "ninguna":
		_dibujar_gafas(c, r, gafas, grosor)

	# 10. Pelo delantero
	_dibujar_pelo_delantero(c, r, estilo_pelo, pelo, grosor)

	# 11. Gorro de cumpleaños
	if accesorio_cabeza == "gorro_fiesta":
		_dibujar_gorro_fiesta(c + _rotar(Vector2(-10.0, -34.0), r), r - 0.24, grosor, true)
	elif accesorio_cabeza == "gorro_volando":
		_dibujar_gorro_fiesta(c + _rotar(Vector2(-18.0, -64.0), r), r - 0.52, grosor, false)


func _forma_rostro(es_mujer: bool) -> PackedVector2Array:
	if es_mujer:
		return PackedVector2Array([
			Vector2(0.0, -37.5),
			Vector2(20.0, -33.5),
			Vector2(30.5, -17.0),
			Vector2(31.0, 2.0),
			Vector2(25.5, 20.0),
			Vector2(13.5, 32.5),
			Vector2(0.0, 36.8),
			Vector2(-13.5, 32.5),
			Vector2(-25.5, 20.0),
			Vector2(-31.0, 2.0),
			Vector2(-30.5, -17.0),
			Vector2(-20.0, -33.5),
		])
	return PackedVector2Array([
		Vector2(0.0, -38.0),
		Vector2(21.0, -34.0),
		Vector2(31.5, -17.0),
		Vector2(32.0, 3.0),
		Vector2(27.5, 21.5),
		Vector2(16.5, 33.5),
		Vector2(0.0, 37.8),
		Vector2(-16.5, 33.5),
		Vector2(-27.5, 21.5),
		Vector2(-32.0, 3.0),
		Vector2(-31.5, -17.0),
		Vector2(-21.0, -34.0),
	])


func _esta_parpadeando(expr_activa: String = "") -> bool:
	var e := expresion if expr_activa == "" else expr_activa
	if not animar_idle or e in ["sorpresa", "panico", "asustado_frio", "dormido", "roncando", "feliz_cerrado", "satisfecho", "cantando", "reir"]:
		return false
	var ciclo := fmod(_t + _fase_parpadeo, 3.8)
	return ciclo > 3.64


func _dibujar_ojos(c: Vector2, r: float, es_mujer: bool, piel_sombra: Color, color_ojos: Color, mirada: Vector2, grosor: float, expr_activa: String = "", ojos_felices_extra: bool = false) -> void:
	var e := expresion if expr_activa == "" else expr_activa
	var parpadeo := _esta_parpadeando(e)
	var en_shock: bool = e in ["sorpresa", "panico", "asustado_frio"]
	var ojos_dormidos: bool = e in ["dormido", "roncando", "cansado", "bostezo"]
	var ojos_felices: bool = ojos_felices_extra or (e in ["feliz_cerrado", "satisfecho", "cantando", "reir"])
	var eye_y: float = 0.5
	var eye_x: float = 13.6
	var rx: float = 9.0 if en_shock else 8.6
	var ry: float = 10.4 if en_shock else (7.6 if es_mujer else 7.2)

	for lado: float in [-1.0, 1.0]:
		var ec_local := Vector2(lado * eye_x, eye_y)

		if ojos_felices:
			# Ojos felices cerrados en arco ^ ^
			var arco_feliz := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.85, 2.2),
				ec_local + Vector2(0.0, -4.4),
				ec_local + Vector2(rx * 0.85, 2.2),
			]), 4)
			draw_polyline(_transformar_pts(arco_feliz, c, r), TINTA, grosor * 1.05, true)
			continue

		if parpadeo or ojos_dormidos:
			# Ojos cerrados relajados (curva suave hacia abajo al dormir)
			var dy_mid: float = 3.2 if ojos_dormidos else -1.4
			var arco_cerrado := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.85, 0.2),
				ec_local + Vector2(0.0, dy_mid),
				ec_local + Vector2(rx * 0.85, 0.2),
			]), 4)
			draw_polyline(_transformar_pts(arco_cerrado, c, r), TINTA, grosor * 0.95, true)
			continue

		# 1. Forma almendrada/suave de la esclerótica (blanca, sin anillo negro inferior pesado)
		var sclera_local: PackedVector2Array
		if en_shock:
			sclera_local = _elipse_pts(ec_local, rx, ry, 26, 0.0)
		else:
			sclera_local = _suavizar_cerrado(PackedVector2Array([
				ec_local + Vector2(-rx, 1.0),
				ec_local + Vector2(-rx * 0.58, -ry * 0.92),
				ec_local + Vector2(0.0, -ry * 1.04),
				ec_local + Vector2(rx * 0.62, -ry * 0.86),
				ec_local + Vector2(rx, 0.6),
				ec_local + Vector2(rx * 0.55, ry * 0.82),
				ec_local + Vector2(0.0, ry * 0.86),
				ec_local + Vector2(-rx * 0.55, ry * 0.78),
			]), 4)
		draw_colored_polygon(_transformar_pts(sclera_local, c, r), Color.WHITE)

		# 2. Iris grande y expresivo (ligeramente resguardado bajo el párpado superior)
		var ic_local := ec_local + mirada + Vector2(0.0, 0.0 if en_shock else 0.4)
		var r_iris: float = 4.4 if en_shock else 5.8
		var iris_ext: PackedVector2Array
		var iris_body: PackedVector2Array
		var pupila_pts: PackedVector2Array

		if en_shock:
			iris_ext = _elipse_pts(ic_local, r_iris, r_iris, 22, 0.0)
			iris_body = _elipse_pts(ic_local, r_iris * 0.76, r_iris * 0.76, 18, 0.0)
			pupila_pts = _elipse_pts(ic_local, 2.2, 2.2, 16, 0.0)
		else:
			iris_ext = _recortar_elipse_a_ojo(ic_local, r_iris, r_iris * 1.04, ec_local, rx, ry, 24)
			iris_body = _recortar_elipse_a_ojo(ic_local + Vector2(0.0, 0.35), r_iris * 0.78, r_iris * 0.80, ec_local, rx, ry, 20)
			pupila_pts = _recortar_elipse_a_ojo(ic_local + Vector2(0.0, 0.15), 2.9, 3.0, ec_local, rx, ry, 18)

		# Anillo limbal oscuro + cuerpo vivo del color de ojos
		draw_colored_polygon(_transformar_pts(iris_ext, c, r), color_ojos.darkened(0.40))
		draw_colored_polygon(_transformar_pts(iris_body, c, r), color_ojos)

		# Media luna luminosa inferior dentro del iris (da profundidad viva tipo Pixar/Sims)
		if not en_shock:
			var glow_pts := _recortar_elipse_a_ojo(ic_local + Vector2(0.0, 2.5), r_iris * 0.56, r_iris * 0.36, ec_local, rx, ry, 16)
			draw_colored_polygon(_transformar_pts(glow_pts, c, r), Color(color_ojos.lightened(0.42), 0.78))

		# Pupila oscura
		draw_colored_polygon(_transformar_pts(pupila_pts, c, r), TINTA)

		# 3. Sombra suave proyectada por el párpado superior sobre la parte alta del ojo
		if not en_shock:
			var sh_top := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.94, -ry * 0.05),
				ec_local + Vector2(-rx * 0.50, -ry * 0.85),
				ec_local + Vector2(0.0, -ry * 0.95),
				ec_local + Vector2(rx * 0.52, -ry * 0.80),
				ec_local + Vector2(rx * 0.94, -ry * 0.08),
			]), 4)
			var sh_poly := PackedVector2Array(sh_top)
			sh_poly.append(ec_local + Vector2(rx * 0.90, -ry * 0.34))
			sh_poly.append(ec_local + Vector2(0.0, -ry * 0.48))
			sh_poly.append(ec_local + Vector2(-rx * 0.90, -ry * 0.34))
			draw_colored_polygon(_transformar_pts(sh_poly, c, r), Color(0.15, 0.22, 0.36, 0.17))

		# 4. Brillos especulares blancos encima de la sombra para mirada brillante
		var ic_w: Vector2 = _rotar(ic_local, r) + c
		draw_circle(ic_w + _rotar(Vector2(-2.0, -2.0), r), 1.9, Color.WHITE, true, -1.0, true)
		draw_circle(ic_w + _rotar(Vector2(2.0, 1.8), r), 0.9, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)

		# 5. Línea de pestañas superior expresiva + borde inferior muy sutil
		if en_shock:
			var cerr := _transformar_pts(sclera_local, c, r)
			cerr.append(cerr[0])
			draw_polyline(cerr, TINTA, 2.3, true)
		else:
			var lid_top := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 1.04, 0.8),
				ec_local + Vector2(-rx * 0.58, -ry * 0.94),
				ec_local + Vector2(0.0, -ry * 1.06),
				ec_local + Vector2(rx * 0.62, -ry * 0.88),
				ec_local + Vector2(rx * 1.04, 0.5),
			]), 5)
			draw_polyline(_transformar_pts(lid_top, c, r), TINTA, 3.4 if es_mujer else 2.8, true)

			# Pliegue suave sobre el párpado
			var pliegue := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.62, -ry * 1.28),
				ec_local + Vector2(0.0, -ry * 1.42),
				ec_local + Vector2(rx * 0.62, -ry * 1.24),
			]), 4)
			draw_polyline(_transformar_pts(pliegue, c, r), Color(piel_sombra, 0.72), 1.2, true)

			# Toque muy delicado en el borde inferior (sin encerrar el ojo con línea gruesa)
			var lid_bot := _suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.52, ry * 0.78),
				ec_local + Vector2(0.0, ry * 0.88),
				ec_local + Vector2(rx * 0.52, ry * 0.80),
			]), 4)
			draw_polyline(_transformar_pts(lid_bot, c, r), Color(TINTA, 0.30), 1.1, true)

			# Pestañas estilizadas para mujer
			if es_mujer:
				var wb := ec_local + Vector2(lado * (rx * 0.94), -ry * 0.18)
				var ala := PackedVector2Array([
					wb + Vector2(-lado * 1.5, -1.6),
					wb + Vector2(lado * 4.2, -3.1),
					wb + Vector2(lado * 1.4, 1.0),
				])
				draw_colored_polygon(_transformar_pts(ala, c, r), TINTA)
				var tip2: Vector2 = _rotar(ec_local + Vector2(lado * (rx * 0.72), -ry * 0.68), r) + c
				draw_line(tip2, tip2 + _rotar(Vector2(lado * 2.8, -2.6), r), TINTA, 1.8, true)


func _dibujar_cejas(c: Vector2, r: float, es_mujer: bool, color_pelo: Color, _grosor: float) -> void:
	var col_ceja := color_pelo.darkened(0.22)
	var thick: float = 2.5 if es_mujer else 3.7
	var yb: float = -15.5 if expresion in ["sorpresa", "panico"] else -11.6

	for lado: float in [-1.0, 1.0]:
		var dy_in: float = 0.0
		var dy_mid: float = -2.6
		var dy_out: float = 0.6
		if expresion == "panico":
			dy_in = -2.4
			dy_out = 2.8
		elif expresion == "sorpresa":
			dy_mid = -4.8
		elif expresion == "concentrado":
			dy_in = 2.4
			dy_out = -1.2

		var ceja := _suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 6.0, yb + dy_in - thick * 0.45),
			Vector2(lado * 13.8, yb + dy_mid - thick * 0.45),
			Vector2(lado * 22.2, yb + dy_out),
			Vector2(lado * 13.8, yb + dy_mid + thick * 0.50),
			Vector2(lado * 6.2, yb + dy_in + thick * 0.55),
		]), 3)
		_poligono_tinta(_transformar_pts(ceja, c, r), col_ceja, 1.4)


func _dibujar_nariz(c: Vector2, r: float, piel: Color, piel_sombra: Color, _grosor: float) -> void:
	var brillo_n := piel.lightened(0.18)
	draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.2, 11.4), r) + c, 4.0, 2.1, 16, r), Color(piel_sombra, 0.55))
	draw_colored_polygon(_elipse_pts(_rotar(Vector2(-0.8, 9.6), r) + c, 2.1, 1.2, 12, r), Color(brillo_n, 0.65))
	var curva := _suavizar_abierta(PackedVector2Array([
		Vector2(-2.8, 10.0), Vector2(0.0, 11.5), Vector2(3.0, 10.1), Vector2(2.4, 8.6),
	]), 4)
	draw_polyline(_transformar_pts(curva, c, r), Color(TINTA, 0.85), 1.8, true)


func _dibujar_boca(c: Vector2, r: float, es_mujer: bool, piel_sombra: Color, grosor: float, expr_activa: String = "", rig: Dictionary = {}) -> void:
	var e := expresion if expr_activa == "" else expr_activa
	match e:
		"sorpresa", "panico":
			var b_pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-10.5, 19.5), Vector2(-5.8, 15.2), Vector2(5.8, 15.2),
				Vector2(10.5, 19.5), Vector2(8.8, 27.4), Vector2(0.0, 29.4), Vector2(-8.8, 27.4),
			]), 3)
			_poligono_tinta(_transformar_pts(b_pts, c, r), Color("#3b151e"), grosor * 0.78)
			draw_colored_polygon(_transformar_pts(PackedVector2Array([
				Vector2(-7.0, 16.6), Vector2(7.0, 16.6), Vector2(6.5, 19.4), Vector2(-6.5, 19.4),
			]), c, r), Color.WHITE)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 25.8), r) + c, 5.8, 2.8, 14, r), Color("#fb7185"))
		"asustado_frio":
			# Boca temblorosa por agua fría
			var wave_b := _suavizar_abierta(PackedVector2Array([
				Vector2(-10.0, 21.0), Vector2(-5.0, 18.5), Vector2(0.0, 21.5),
				Vector2(5.0, 18.5), Vector2(10.0, 21.0),
			]), 3)
			draw_polyline(_transformar_pts(wave_b, c, r), TINTA, 2.4, true)
		"roncando", "bostezo":
			var r_b: float = 5.5 + sin(_t * 3.8) * 2.2 if e == "roncando" else 7.2
			var o_pts := _elipse_pts(_rotar(Vector2(0.0, 22.0), r) + c, r_b * 0.85, r_b, 18, r)
			_poligono_tinta(o_pts, Color("#4a1924"), 2.0)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 24.5), r) + c, r_b * 0.55, r_b * 0.36, 12, r), Color("#fb7185"))
		"dormido":
			var paz := _suavizar_abierta(PackedVector2Array([
				Vector2(-6.0, 20.5), Vector2(0.0, 22.2), Vector2(6.0, 20.5),
			]), 3)
			draw_polyline(_transformar_pts(paz, c, r), Color(TINTA, 0.85), 2.0, true)
		"soplando":
			var mej := float(rig.get("comer_mejillas", 0.5))
			var r_o := 3.1 + mej * 1.1
			var p_o := _elipse_pts(_rotar(Vector2(0.5, 21.2), r) + c, r_o, r_o * 0.92, 16, r)
			_poligono_tinta(p_o, Color("#6b1d2e"), 1.9)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.5, 22.2), r) + c, r_o * 0.48, r_o * 0.34, 10, r), Color("#fb7185"))
			# Hoyuelos fruncidos al soplar
			for lado_s: float in [-1.0, 1.0]:
				var hoyo := _suavizar_abierta(PackedVector2Array([
					Vector2(lado_s * 6.8, 19.2), Vector2(lado_s * 5.6, 21.2), Vector2(lado_s * 6.8, 23.2),
				]), 3)
				draw_polyline(_transformar_pts(hoyo, c, r), Color(piel_sombra, 0.75), 1.4, true)
		"masticando":
			if pose == "comer":
				var apertura: float = float(rig.get("comer_boca_apertura", 0.0))
				var mast_val: float = float(rig.get("comer_masticacion", 0.0))
				if apertura > 0.12:
					# Boca abriéndose con ganas para recibir el bocado ("¡Aaah!")
					var aw := 6.2 + apertura * 4.8
					var ah := 2.4 + apertura * 7.6
					var b_ab := _suavizar_cerrado(PackedVector2Array([
						Vector2(-aw, 18.8), Vector2(0.0, 18.0 - apertura * 1.0), Vector2(aw, 18.8),
						Vector2(aw * 0.82, 20.0 + ah), Vector2(0.0, 21.0 + ah), Vector2(-aw * 0.82, 20.0 + ah),
					]), 4)
					_poligono_tinta(_transformar_pts(b_ab, c, r), Color("#4a1924"), 2.0)
					if apertura > 0.35:
						var dt := PackedVector2Array([
							Vector2(-aw * 0.70, 18.6), Vector2(aw * 0.70, 18.6),
							Vector2(aw * 0.62, 20.6), Vector2(-aw * 0.62, 20.6),
						])
						draw_colored_polygon(_transformar_pts(dt, c, r), Color.WHITE)
					draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 20.0 + ah * 0.68), r) + c, aw * 0.54, maxf(1.6, ah * 0.30), 14, r), Color("#fb7185"))
				elif absf(mast_val) > 0.02:
					# Masticación natural con boca cerrada, ligero movimiento lateral y comisuras felices
					var dx_m := mast_val * 1.6
					var dy_m := absf(mast_val) * 1.4
					var ancho_c := 9.2 - absf(mast_val) * 1.2
					var m_curva := _suavizar_abierta(PackedVector2Array([
						Vector2(-ancho_c + dx_m, 19.4 - dy_m * 0.3),
						Vector2(-ancho_c * 0.4 + dx_m, 21.6 + dy_m * 0.5),
						Vector2(dx_m, 20.6 + dy_m * 0.8),
						Vector2(ancho_c * 0.4 + dx_m, 21.6 + dy_m * 0.5),
						Vector2(ancho_c + dx_m, 19.4 - dy_m * 0.3),
					]), 4)
					var pts_m := _transformar_pts(m_curva, c, r)
					if es_mujer:
						draw_polyline(pts_m, Color("#e11d48", 0.38), 3.2, true)
					draw_polyline(pts_m, TINTA, 2.2, true)
					# Pequeña sombra bajo el labio inferior
					var ment_m := _suavizar_abierta(PackedVector2Array([
						Vector2(-3.2 + dx_m, 24.4 + dy_m * 0.6),
						Vector2(dx_m, 25.0 + dy_m * 0.6),
						Vector2(3.2 + dx_m, 24.4 + dy_m * 0.6),
					]), 3)
					draw_polyline(_transformar_pts(ment_m, c, r), Color(piel_sombra, 0.7), 1.4, true)
				else:
					# Sonrisa relajada mirando el plato
					var son_c := _suavizar_abierta(PackedVector2Array([
						Vector2(-10.0, 18.6), Vector2(-4.5, 21.8), Vector2(0.0, 22.4),
						Vector2(4.5, 21.8), Vector2(10.0, 18.6),
					]), 4)
					var pts_sc := _transformar_pts(son_c, c, r)
					if es_mujer:
						draw_polyline(pts_sc, Color("#e11d48", 0.40), 3.2, true)
					draw_polyline(pts_sc, TINTA, 2.1, true)
			else:
				var mast := (sin(_t * 9.0) + 1.0) * 0.5
				var ancho_m: float = 8.5 + mast * 3.0
				var alto_m: float = 1.6 + mast * 3.8
				var m_pts := _suavizar_cerrado(PackedVector2Array([
					Vector2(-ancho_m, 19.5), Vector2(0.0, 19.8 - alto_m * 0.3), Vector2(ancho_m, 19.5),
					Vector2(ancho_m * 0.7, 20.5 + alto_m), Vector2(0.0, 21.2 + alto_m), Vector2(-ancho_m * 0.7, 20.5 + alto_m),
				]), 3)
				_poligono_tinta(_transformar_pts(m_pts, c, r), Color("#4a1924"), 1.9)
				draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 20.5 + alto_m * 0.6), r) + c, 4.0, 1.8, 12, r), Color("#fb7185"))
		"satisfecho":
			var son_sat := _suavizar_abierta(PackedVector2Array([
				Vector2(-10.8, 17.8), Vector2(-4.8, 22.4), Vector2(0.0, 23.4),
				Vector2(4.8, 22.4), Vector2(10.8, 17.8),
			]), 4)
			var pts_sat := _transformar_pts(son_sat, c, r)
			if es_mujer:
				draw_polyline(pts_sat, Color("#e11d48", 0.42), 3.4, true)
			draw_polyline(pts_sat, TINTA, 2.2, true)
			var ment_s := _suavizar_abierta(PackedVector2Array([
				Vector2(-3.2, 26.8), Vector2(0.0, 27.6), Vector2(3.2, 26.8),
			]), 3)
			draw_polyline(_transformar_pts(ment_s, c, r), Color(piel_sombra, 0.68), 1.4, true)
		"cantando":
			var canto := (sin(_t * 8.0) + 1.0) * 0.5
			var rx_c: float = 6.5 + canto * 2.4
			var ry_c: float = 5.5 + canto * 3.5
			var c_pts := _elipse_pts(_rotar(Vector2(0.0, 21.8), r) + c, rx_c, ry_c, 18, r)
			_poligono_tinta(c_pts, Color("#4a1924"), 2.0)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 24.0), r) + c, rx_c * 0.6, ry_c * 0.36, 12, r), Color("#fb7185"))
		"feliz", "feliz_cerrado", "reir":
			var b_pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-12.6, 16.8), Vector2(0.0, 18.6), Vector2(12.6, 16.8),
				Vector2(9.6, 24.8), Vector2(0.0, 27.4), Vector2(-9.6, 24.8),
			]), 4)
			_poligono_tinta(_transformar_pts(b_pts, c, r), Color("#4a1924"), 2.0)
			var dientes := _suavizar_cerrado(PackedVector2Array([
				Vector2(-10.6, 17.6), Vector2(0.0, 19.0), Vector2(10.6, 17.6),
				Vector2(9.2, 21.0), Vector2(0.0, 21.8), Vector2(-9.2, 21.0),
			]), 3)
			draw_colored_polygon(_transformar_pts(dientes, c, r), Color.WHITE)
			draw_colored_polygon(_elipse_pts(_rotar(Vector2(0.0, 24.8), r) + c, 5.6, 2.3, 16, r), Color("#fb7185"))
			var labio_sup := _suavizar_abierta(PackedVector2Array([
				Vector2(-13.4, 16.4), Vector2(0.0, 18.7), Vector2(13.4, 16.4),
			]), 5)
			draw_polyline(_transformar_pts(labio_sup, c, r), TINTA, 2.1, true)
			if es_mujer:
				var brillo_labio := _suavizar_abierta(PackedVector2Array([
					Vector2(-5.5, 28.4), Vector2(0.0, 29.4), Vector2(5.5, 28.4),
				]), 3)
				draw_polyline(_transformar_pts(brillo_labio, c, r), Color("#f43f5e", 0.36), 2.0, true)
			var menton := _suavizar_abierta(PackedVector2Array([
				Vector2(-3.5, 30.8), Vector2(0.0, 31.6), Vector2(3.5, 30.8),
			]), 3)
			draw_polyline(_transformar_pts(menton, c, r), Color(piel_sombra, 0.72), 1.5, true)
		"concentrado", "neutral":
			var linea := _suavizar_abierta(PackedVector2Array([
				Vector2(-8.2, 20.0), Vector2(0.0, 20.8), Vector2(8.2, 19.6),
			]), 4)
			draw_polyline(_transformar_pts(linea, c, r), TINTA, 2.2, true)
		_:
			var sonrisa := _suavizar_abierta(PackedVector2Array([
				Vector2(-11.2, 17.6), Vector2(-5.2, 21.8), Vector2(0.0, 22.8),
				Vector2(5.2, 21.8), Vector2(11.2, 17.6),
			]), 4)
			var pts_s := _transformar_pts(sonrisa, c, r)
			if es_mujer:
				draw_polyline(pts_s, Color("#e11d48", 0.45), 3.4, true)
			draw_polyline(pts_s, TINTA, 2.2, true)


func _dibujar_vello_facial(c: Vector2, r: float, tipo: String, pelo: Color, grosor: float) -> void:
	var col := pelo.darkened(0.14)
	match tipo:
		"barba_corta":
			var barba := _suavizar_cerrado(PackedVector2Array([
				Vector2(-28.5, 10.0), Vector2(-24.8, 22.5), Vector2(-15.0, 33.0),
				Vector2(0.0, 37.6), Vector2(15.0, 33.0), Vector2(24.8, 22.5),
				Vector2(28.5, 10.0), Vector2(23.5, 15.5), Vector2(14.5, 25.0),
				Vector2(0.0, 28.0), Vector2(-14.5, 25.0), Vector2(-23.5, 15.5),
			]), 3)
			_poligono_tinta(_transformar_pts(barba, c, r), Color(col, 0.90), grosor * 0.62)
		"bigote":
			var big := _suavizar_cerrado(PackedVector2Array([
				Vector2(-14.0, 17.0), Vector2(-6.2, 13.0), Vector2(0.0, 14.4),
				Vector2(6.2, 13.0), Vector2(14.0, 17.0), Vector2(8.6, 18.2),
				Vector2(0.0, 16.6), Vector2(-8.6, 18.2),
			]), 3)
			_poligono_tinta(_transformar_pts(big, c, r), col, grosor * 0.68)
		"perilla":
			var per := _suavizar_cerrado(PackedVector2Array([
				Vector2(-8.6, 27.0), Vector2(0.0, 28.8), Vector2(8.6, 27.0),
				Vector2(6.2, 35.8), Vector2(0.0, 38.4), Vector2(-6.2, 35.8),
			]), 3)
			_poligono_tinta(_transformar_pts(per, c, r), col, grosor * 0.68)


func _dibujar_gafas(c: Vector2, r: float, tipo: String, _grosor: float) -> void:
	var cristal := Color(0.90, 0.97, 1.0, 0.11)
	var montura := Color("#1e293b")
	var y: float = 0.5

	if tipo == "redondas":
		for lado: float in [-1.0, 1.0]:
			var pos: Vector2 = _rotar(Vector2(lado * 13.8, y), r) + c
			draw_circle(pos, 10.5, cristal, true, -1.0, true)
			draw_arc(pos, 10.5, 0.0, TAU, 28, montura, 1.9, true)
			draw_line(pos + _rotar(Vector2(-5.8, -5.0), r), pos + _rotar(Vector2(-2.6, -7.0), r), Color(1.0, 1.0, 1.0, 0.55), 1.4, true)
		draw_line(_rotar(Vector2(-3.3, y - 0.8), r) + c, _rotar(Vector2(3.3, y - 0.8), r) + c, montura, 1.8, true)
	elif tipo == "cuadradas":
		for lado: float in [-1.0, 1.0]:
			var cx: float = lado * 13.8
			var marco := _suavizar_cerrado(PackedVector2Array([
				Vector2(cx - 10.4, y - 7.8), Vector2(cx + 10.4, y - 7.8),
				Vector2(cx + 9.6, y + 7.8), Vector2(cx - 9.6, y + 7.8),
			]), 2)
			var t_m := _transformar_pts(marco, c, r)
			draw_colored_polygon(t_m, cristal)
			var cerrado := PackedVector2Array(t_m)
			cerrado.append(t_m[0])
			draw_polyline(cerrado, montura, 2.0, true)
		draw_line(_rotar(Vector2(-3.4, y - 1.6), r) + c, _rotar(Vector2(3.4, y - 1.6), r) + c, montura, 1.8, true)


# ---------------------------------------------------------------- peinados suaves

func _dibujar_pelo_trasero(c: Vector2, r: float, estilo: String, pelo: Color, grosor: float) -> void:
	var pelo_sombra := pelo.darkened(0.24)
	match estilo:
		"largo":
			var back := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -44.0),
				Vector2(28.0, -37.0),
				Vector2(42.0, -10.0),
				Vector2(46.0, 30.0),
				Vector2(43.0, 74.0),
				Vector2(26.0, 88.0),
				Vector2(0.0, 82.0),
				Vector2(-26.0, 88.0),
				Vector2(-43.0, 74.0),
				Vector2(-46.0, 30.0),
				Vector2(-42.0, -10.0),
				Vector2(-28.0, -37.0),
			]), 4)
			_poligono_tinta(_transformar_pts(back, c, r), pelo_sombra, grosor)
		"media_melena":
			var bob := _suavizar_cerrado(PackedVector2Array([
				Vector2(0.0, -44.0),
				Vector2(28.0, -37.0),
				Vector2(42.0, -10.0),
				Vector2(44.0, 22.0),
				Vector2(36.0, 46.0),
				Vector2(18.0, 49.0),
				Vector2(-18.0, 49.0),
				Vector2(-36.0, 46.0),
				Vector2(-44.0, 22.0),
				Vector2(-42.0, -10.0),
				Vector2(-28.0, -37.0),
			]), 4)
			_poligono_tinta(_transformar_pts(bob, c, r), pelo_sombra, grosor)
		"coleta":
			var cola := _suavizar_cerrado(PackedVector2Array([
				Vector2(18.0, -33.0),
				Vector2(44.0, -30.0),
				Vector2(56.0, -2.0),
				Vector2(54.0, 34.0),
				Vector2(40.0, 50.0),
				Vector2(31.0, 26.0),
				Vector2(33.0, -2.0),
				Vector2(16.0, -16.0),
			]), 4)
			_poligono_tinta(_transformar_pts(cola, c, r), pelo, grosor)
			var goma := _elipse_pts(_rotar(Vector2(24.0, -28.0), r) + c, 6.2, 8.6, 16, r + 0.4)
			_poligono_tinta(goma, Color("#ef4444"), grosor * 0.75)
		"mono":
			var pos_m := _rotar(Vector2(0.0, -48.5), r) + c
			_poligono_tinta(_elipse_pts(pos_m, 18.0, 15.5, 26, r), pelo, grosor)
			_poligono_tinta(_elipse_pts(_rotar(Vector2(0.0, -36.5), r) + c, 12.5, 3.8, 16, r), Color("#ef4444"), grosor * 0.75)
		"rizado":
			for p: Vector2 in [
				Vector2(-33.0, -16.0), Vector2(-37.0, 2.0), Vector2(-28.0, 19.0),
				Vector2(33.0, -16.0), Vector2(37.0, 2.0), Vector2(28.0, 19.0),
				Vector2(-24.0, -33.0), Vector2(0.0, -40.0), Vector2(24.0, -33.0),
			]:
				var pos: Vector2 = _rotar(p, r) + c
				draw_circle(pos, 18.0, pelo_sombra, true, -1.0, true)
				draw_arc(pos, 18.0, 0.0, TAU, 20, TINTA, grosor * 0.88, true)
		"alborotado":
			var nuca := _suavizar_cerrado(PackedVector2Array([
				Vector2(-34.0, -4.0), Vector2(-40.0, 12.0), Vector2(-27.0, 28.0),
				Vector2(27.0, 28.0), Vector2(40.0, 12.0), Vector2(34.0, -4.0),
			]), 3)
			_poligono_tinta(_transformar_pts(nuca, c, r), pelo_sombra, grosor * 0.85)


func _dibujar_pelo_delantero(c: Vector2, r: float, estilo: String, pelo: Color, grosor: float) -> void:
	var brillo := pelo.lightened(0.24)
	match estilo:
		"alborotado":
			var pts := PackedVector2Array([
				Vector2(-32.0, 2.0),
				Vector2(-38.0, -11.0),
				Vector2(-44.0, -19.0),
				Vector2(-34.0, -29.0),
				Vector2(-21.0, -45.0),
				Vector2(-6.0, -40.0),
				Vector2(7.0, -54.0),
				Vector2(18.0, -42.0),
				Vector2(37.0, -48.0),
				Vector2(32.0, -30.0),
				Vector2(42.0, -23.0),
				Vector2(34.0, -10.0),
				Vector2(31.5, 2.0),
				Vector2(26.5, -14.0),
				Vector2(17.0, -18.0),
				Vector2(8.0, -10.0),
				Vector2(2.0, -22.0),
				Vector2(-8.0, -14.0),
				Vector2(-18.0, -22.0),
				Vector2(-27.0, -12.0),
			])
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor)
			_brillo_pelo(c, r, Vector2(-12.0, -34.0), Vector2(14.0, -37.0), brillo)

		"corto":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.0, 0.0),
				Vector2(-35.5, -19.0),
				Vector2(-24.0, -38.0),
				Vector2(0.0, -45.5),
				Vector2(24.0, -41.0),
				Vector2(35.5, -23.0),
				Vector2(32.0, 0.0),
				Vector2(26.5, -15.5),
				Vector2(13.0, -23.5),
				Vector2(-6.0, -21.0),
				Vector2(-20.0, -15.0),
				Vector2(-27.5, -10.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor)
			_brillo_pelo(c, r, Vector2(-11.0, -35.0), Vector2(14.0, -34.0), brillo)

		"rapado":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-30.5, -6.0),
				Vector2(-30.5, -21.0),
				Vector2(-20.0, -35.0),
				Vector2(0.0, -39.5),
				Vector2(20.0, -35.0),
				Vector2(30.5, -21.0),
				Vector2(30.5, -6.0),
				Vector2(26.5, -18.0),
				Vector2(14.0, -24.5),
				Vector2(0.0, -25.5),
				Vector2(-14.0, -24.5),
				Vector2(-26.5, -18.0),
			]), 3)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor * 0.85)

		"rizado":
			var rizos := [
				[Vector2(-25.0, -28.0), 13.0],
				[Vector2(-12.0, -37.5), 14.5],
				[Vector2(4.0, -39.5), 15.0],
				[Vector2(20.0, -33.0), 13.5],
				[Vector2(29.0, -20.0), 11.2],
				[Vector2(-29.0, -18.0), 11.2],
			]
			for rz: Array in rizos:
				var rz_pos: Vector2 = rz[0]
				var rz_rad: float = rz[1]
				draw_circle(_rotar(rz_pos, r) + c, rz_rad, pelo, true, -1.0, true)
			for rz: Array in rizos:
				var rz_pos: Vector2 = rz[0]
				var rz_rad: float = rz[1]
				draw_arc(_rotar(rz_pos, r) + c, rz_rad, PI * 0.85, TAU + 0.35, 16, TINTA, grosor * 0.85, true)
			_brillo_pelo(c, r, Vector2(-8.0, -39.5), Vector2(10.0, -40.5), brillo)

		"largo":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-35.5, 24.0),
				Vector2(-39.5, -12.0),
				Vector2(-28.0, -37.0),
				Vector2(0.0, -45.5),
				Vector2(28.0, -37.0),
				Vector2(39.5, -12.0),
				Vector2(35.5, 24.0),
				Vector2(28.5, -4.0),
				Vector2(21.0, -19.0),
				Vector2(6.0, -24.5),
				Vector2(-6.0, -16.0),
				Vector2(-22.0, -19.0),
				Vector2(-28.5, -4.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor)
			_brillo_pelo(c, r, Vector2(-14.0, -34.0), Vector2(14.0, -34.0), brillo)

		"media_melena":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-35.5, 26.0),
				Vector2(-39.0, -12.0),
				Vector2(-28.0, -37.0),
				Vector2(0.0, -45.5),
				Vector2(28.0, -37.0),
				Vector2(39.0, -12.0),
				Vector2(35.5, 26.0),
				Vector2(27.5, 2.0),
				Vector2(24.0, -18.5),
				Vector2(10.0, -15.5),
				Vector2(0.0, -21.5),
				Vector2(-10.0, -15.5),
				Vector2(-24.0, -18.5),
				Vector2(-27.5, 2.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor)
			_brillo_pelo(c, r, Vector2(-14.0, -34.0), Vector2(14.0, -34.0), brillo)

		"coleta", "mono":
			var pts := _suavizar_cerrado(PackedVector2Array([
				Vector2(-32.5, -2.0),
				Vector2(-34.5, -20.0),
				Vector2(-23.0, -37.5),
				Vector2(0.0, -44.0),
				Vector2(23.0, -37.5),
				Vector2(34.5, -20.0),
				Vector2(32.5, -2.0),
				Vector2(27.0, -16.0),
				Vector2(14.0, -23.0),
				Vector2(0.0, -20.5),
				Vector2(-14.0, -23.0),
				Vector2(-27.0, -16.0),
			]), 4)
			_poligono_tinta(_transformar_pts(pts, c, r), pelo, grosor)
			_brillo_pelo(c, r, Vector2(-12.0, -34.0), Vector2(12.0, -34.0), brillo)


func _brillo_pelo(c: Vector2, r: float, p0: Vector2, p1: Vector2, col: Color) -> void:
	var medio := (p0 + p1) * 0.5 + Vector2(0.0, -3.5)
	var pts := _transformar_pts(PackedVector2Array([p0, medio, p1]), c, r)
	draw_polyline(pts, Color(col, 0.75), 3.4, true)


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

	# Mango y cuello estilizados del tenedor
	var mango := PackedVector2Array([
		Vector2(-2.6, 10.0), Vector2(2.6, 10.0),
		Vector2(1.8, -11.0), Vector2(4.6, -15.0),
		Vector2(-4.6, -15.0), Vector2(-1.8, -11.0),
	])
	_poligono_tinta(_transformar_pts(mango, pos, rot), col_metal, grosor * 0.62)
	draw_line(pos + _rotar(Vector2(0.8, 8.0), rot), pos + _rotar(Vector2(0.8, -11.0), rot), col_sombra, 1.3, true)

	# 3 púas metálicas nítidas
	for dx: float in [-3.4, 0.0, 3.4]:
		var p0 := pos + _rotar(Vector2(dx, -14.8), rot)
		var p1 := pos + _rotar(Vector2(dx * 1.05, -24.5), rot)
		draw_line(p0, p1, TINTA, 2.5, true)
		draw_line(p0, p1, col_metal, 1.1, true)

	# Bocado apetitoso pinchado en las púas (desaparece limpiamente al morder)
	if con_bocado:
		var centro_b := pos + _rotar(Vector2(0.0, -21.5), rot)
		var b_poly := _suavizar_cerrado(PackedVector2Array([
			Vector2(-5.4, -22.0), Vector2(-3.2, -26.2), Vector2(2.6, -26.0),
			Vector2(5.6, -22.2), Vector2(4.2, -17.8), Vector2(-3.8, -17.6),
		]), 3)
		_poligono_tinta(_transformar_pts(b_poly, pos, rot), col_bocado, grosor * 0.60)
		# Sombra y brillo de cel-shading en el bocado
		draw_circle(centro_b + _rotar(Vector2(1.5, 1.6), rot), 2.4, Color(col_bocado.darkened(0.24), 0.72), true, -1.0, true)
		draw_circle(centro_b + _rotar(Vector2(-1.8, -2.0), rot), 1.5, Color(1.0, 1.0, 1.0, 0.65), true, -1.0, true)
		# Pizca de hierba fresca o salsa para darle textura
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
		# Copa elegante para Mesa Premium
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
		# Vaso de cartón con banda y tapa para escena en la calle
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

	# Vaso clásico de cristal con zumo/bebida cuyo nivel compensa la inclinación
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
	# Menisco superior luminoso del líquido
	var menisco := _elipse_pts(pos + _rotar(Vector2(0.0, y_top), rot), w_top, 1.8, 14, rot * 0.45)
	draw_colored_polygon(menisco, col_bebida.lightened(0.22))

	# Borde elíptico del vaso y reflejo cristalino
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
	# Pliegue diagonal y cenefa sutil de tela
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
		var lid_top := ec.y - ry_ojo * (0.88 - 0.55 * nx * nx)
		var lid_bot := ec.y + ry_ojo * (0.76 - 0.45 * nx * nx)
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
