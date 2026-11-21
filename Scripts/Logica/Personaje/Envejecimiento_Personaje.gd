class_name Envejecimiento_Personaje
extends RefCounted
## Modelo puro del paso del tiempo sobre el aspecto del Sim.
## Traduce la edad (años) en factores 0..1 que Personaje_Visual usa para
## envejecer el retrato de forma continua y acumulativa: canas, arrugas,
## flacidez, manchas, pelo más fino, postura y piel apagada.
##
## Sin estado ni aleatoriedad: dos Sims de la misma edad (y misma apariencia)
## se ven exactamente igual. Cada rasgo tiene su propia curva de progresión,
## así el cambio es gota a gota y nunca da saltos entre años.
##
## El dibujo de las marcas de edad vive aquí (funciones estáticas que reciben
## el CanvasItem) para que Personaje_Visual solo tenga que hacer un par de
## llamadas y el sistema quede aislado y fácil de ajustar.

## Edad de referencia: el personaje empieza la partida con 18 años.
const EDAD_MIN := 18
## A partir de esta edad todos los rasgos están al 100 %.
const EDAD_MAX := 100

## Curvas de progresión por rasgo: [edad de inicio, edad de plenitud].
## Entre ambas edades el factor sube con una curva suave (smoothstep).
const CURVAS: Dictionary = {
	"canas": [33.0, 76.0],
	"frente": [33.0, 76.0],
	"surcos": [29.0, 68.0],
	"patas_gallo": [38.0, 80.0],
	"bolsas": [41.0, 82.0],
	"flacidez": [44.0, 88.0],
	"manchas": [52.0, 90.0],
	"pelo_fino": [30.0, 84.0],
	"cejas_finas": [50.0, 88.0],
	"piel_apagada": [44.0, 92.0],
	"postura": [56.0, 94.0],
}

## Orden en el que aparecen los rasgos (documental y útil para tests).
const RASGOS: Array[String] = [
	"surcos", "pelo_fino", "frente", "canas", "patas_gallo",
	"bolsas", "piel_apagada", "flacidez", "cejas_finas",
	"manchas", "postura",
]


# ---------------------------------------------------------------- factores

## Devuelve todos los factores de envejecimiento para una edad concreta.
## Las claves coinciden con las de CURVAS e incluyen siempre 0..1.
static func rasgos(edad: int) -> Dictionary:
	var out := {}
	for clave: String in CURVAS:
		out[clave] = factor(edad, clave)
	return out


## Factor 0..1 de un rasgo concreto para la edad indicada.
static func factor(edad: int, clave: String) -> float:
	if not CURVAS.has(clave):
		return 0.0
	var tramo: Array = CURVAS[clave]
	return tramo_suave(float(edad), float(tramo[0]), float(tramo[1]))


## Curva suave (smoothstep) 0..1 entre dos edades.
static func tramo_suave(valor: float, inicio: float, fin: float) -> float:
	if fin <= inicio:
		return 1.0 if valor >= fin else 0.0
	var k := clampf((valor - inicio) / (fin - inicio), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## Color del pelo con canas progresivas: primero pierde pigmento hacia un
## gris plata y después aclara hasta el blanco. Respeta la luminosidad original
## para que el pelo muy oscuro y el muy claro envejezcan de forma creíble.
static func color_pelo(base: Color, canas: float) -> Color:
	var t := clampf(canas, 0.0, 1.0)
	if t <= 0.001:
		return base
	var gris := Color("#9aa2ae")
	var blanco := Color("#f3f5f9")
	var c: Color
	if t < 0.55:
		c = base.lerp(gris, smoothstep(0.0, 0.55, t))
	else:
		c = gris.lerp(blanco, smoothstep(0.55, 1.0, t))
	# Las canas reflejan menos brillo y quedan ligeramente más apagadas.
	c.v = lerpf(base.v, c.v, lerpf(1.0, 0.92, t))
	return c


## Piel con el paso de los años: pierde saturación poco a poco y aclara muy
## ligeramente. Se mantiene el tono original (no hay "blanqueamiento").
static func color_piel(base: Color, apagado: float) -> Color:
	var t := clampf(apagado, 0.0, 1.0)
	if t <= 0.001:
		return base
	var c := base
	c.s = lerpf(base.s, base.s * 0.78, t)
	c.v = clampf(base.v * lerpf(1.0, 1.03, t), 0.0, 1.0)
	return c


## Etiqueta legible de la etapa de vida (para el Perfil y los mensajes).
static func etapa(edad: int) -> String:
	if edad < 30:
		return "Joven adulto"
	if edad < 45:
		return "Adulto"
	if edad < 60:
		return "Madurez"
	if edad < 75:
		return "Madurez tardía"
	return "Vejez"


## Porcentaje global de envejecimiento (0-100) útil para UI y debug.
static func porcentaje_envejecimiento(edad: int) -> int:
	return int(round(tramo_suave(float(edad), float(EDAD_MIN), float(EDAD_MAX)) * 100.0))


# ---------------------------------------------------------------- dibujo de las marcas

## Dibuja sobre la cara (coordenadas locales de la cabeza) todas las marcas
## que dependen de la edad: arrugas de frente y entrecejo, patas de gallo,
## bolsas, surcos nasogenianos, pliegues del mentón, manchas y papada.
## Se llama después de la nariz y antes de la boca/pelo, así el pelo del
## flequillo tapa las arrugas de la frente de forma natural.
static func dibujar_marcas_cara(ci: CanvasItem, c: Vector2, r: float,
		piel_sombra: Color, rasgos_edad: Dictionary, jaw_w: float = 1.0) -> void:
	if ci == null:
		return
	var frente := float(rasgos_edad.get("frente", 0.0))
	var gallo := float(rasgos_edad.get("patas_gallo", 0.0))
	var bolsas := float(rasgos_edad.get("bolsas", 0.0))
	var surcos := float(rasgos_edad.get("surcos", 0.0))
	var manchas := float(rasgos_edad.get("manchas", 0.0))
	var flacidez := float(rasgos_edad.get("flacidez", 0.0))

	# 1. Arrugas horizontales de la frente
	if frente > 0.02:
		var col_f := Color(piel_sombra.darkened(0.12), 0.13 + 0.32 * frente)
		var ancho := 13.0 * jaw_w
		for i in range(2):
			var y := -28.6 + float(i) * 4.2
			var onda := 1.2 - float(i) * 0.25
			var arruga := _curva_abierta(PackedVector2Array([
				Vector2(-ancho, y + onda),
				Vector2(-ancho * 0.45, y - onda * 0.7),
				Vector2(0.0, y + onda * 0.35),
				Vector2(ancho * 0.45, y - onda * 0.7),
				Vector2(ancho, y + onda),
			]), 4)
			ci.draw_polyline(_transformar(arruga, c, r), col_f, 0.8 + 0.75 * frente, true)
		# Entrecejo: dos pliegues verticales entre las cejas
		if frente > 0.40:
			var col_g := Color(piel_sombra.darkened(0.16), 0.14 + 0.26 * frente)
			for lado: float in [-1.0, 1.0]:
				var glabela := _curva_abierta(PackedVector2Array([
					Vector2(lado * 2.2, -14.4),
					Vector2(lado * 3.2, -12.0),
					Vector2(lado * 2.4, -9.6),
				]), 3)
				ci.draw_polyline(_transformar(glabela, c, r), col_g, 0.85 + 0.45 * frente, true)

	# 2. Patas de gallo y bolsas bajo los ojos
	for lado: float in [-1.0, 1.0]:
		if gallo > 0.02:
			var col_p := Color(piel_sombra.darkened(0.12), 0.12 + 0.30 * gallo)
			for i in range(3):
				var y0 := -2.4 + float(i) * 2.6
				var ala := _curva_abierta(PackedVector2Array([
					Vector2(lado * 19.0, y0),
					Vector2(lado * (21.2 + 0.4 * float(i)), y0 - 0.7),
					Vector2(lado * (23.2 + 0.8 * float(i)), y0 - 1.8 - 0.3 * float(i)),
				]), 3)
				ci.draw_polyline(_transformar(ala, c, r), col_p, 0.75 + 0.5 * gallo, true)

		if bolsas > 0.02:
			var pos_b: Vector2 = _rotar(Vector2(lado * 12.2, 6.3), r) + c
			ci.draw_colored_polygon(_elipse(pos_b, 6.3, 1.9, 16, r), Color(piel_sombra, 0.09 + 0.15 * bolsas))
			var arco_b := _curva_abierta(PackedVector2Array([
				Vector2(lado * 6.4, 5.7),
				Vector2(lado * 12.2, 7.8),
				Vector2(lado * 18.2, 5.4),
			]), 4)
			ci.draw_polyline(_transformar(arco_b, c, r),
				Color(piel_sombra.darkened(0.12), 0.11 + 0.24 * bolsas), 0.85 + 0.45 * bolsas, true)

	# 3. Surcos nasogenianos (de la nariz a la comisura de la boca)
	if surcos > 0.02:
		var col_s := Color(piel_sombra.darkened(0.12), 0.10 + 0.32 * surcos)
		for lado: float in [-1.0, 1.0]:
			var surco := _curva_abierta(PackedVector2Array([
				Vector2(lado * 4.8, 11.2),
				Vector2(lado * 8.2, 14.6),
				Vector2(lado * (10.0 * jaw_w), 18.6),
			]), 4)
			ci.draw_polyline(_transformar(surco, c, r), col_s, 0.75 + 0.75 * surcos, true)

	# 4. Pliegue del mentón y sombra de papada
	if surcos > 0.55:
		var km := (surcos - 0.55) / 0.45
		var menton := _curva_abierta(PackedVector2Array([
			Vector2(-4.0, 29.9), Vector2(0.0, 30.9), Vector2(4.0, 29.9),
		]), 3)
		ci.draw_polyline(_transformar(menton, c, r),
			Color(piel_sombra.darkened(0.10), 0.10 + 0.22 * km), 0.85 + 0.45 * km, true)

	if flacidez > 0.05:
		var papada := _curva_abierta(PackedVector2Array([
			Vector2(-16.0 * jaw_w, 25.0),
			Vector2(-9.0 * jaw_w, 30.0),
			Vector2(0.0, 32.2),
			Vector2(9.0 * jaw_w, 30.0),
			Vector2(16.0 * jaw_w, 25.0),
		]), 4)
		ci.draw_polyline(_transformar(papada, c, r),
			Color(piel_sombra.darkened(0.10), 0.08 + 0.18 * flacidez), 1.0 + 0.7 * flacidez, true)

	# 5. Manchas de la edad en mejillas y sienes
	if manchas > 0.03:
		var col_m := Color(piel_sombra.darkened(0.24), 0.07 + 0.20 * manchas)
		var radio := 1.25 + 0.45 * manchas
		for p: Vector2 in [
			Vector2(-17.5, 6.5), Vector2(-21.5, -1.5), Vector2(-11.0, 13.2),
			Vector2(18.0, 8.5), Vector2(21.8, 1.5), Vector2(12.5, 14.5),
		]:
			ci.draw_colored_polygon(_elipse(_rotar(p, r) + c, radio, radio * 0.72, 10, r + 0.45), col_m)

	# 6. Pliegues del cuello (van en el mismo espacio que la cabeza)
	if flacidez > 0.02:
		var col_c := Color(piel_sombra.darkened(0.10), 0.11 + 0.27 * flacidez)
		for i in range(2):
			var y := 42.8 + float(i) * 4.2
			var pliegue := _curva_abierta(PackedVector2Array([
				Vector2(-7.2, y + 0.7),
				Vector2(0.0, y - 0.6),
				Vector2(7.2, y + 0.7),
			]), 4)
			ci.draw_polyline(_transformar(pliegue, c, r), col_c, 0.85 + 0.55 * flacidez, true)


# ---------------------------------------------------------------- geometría auxiliar

static func _curva_abierta(pts: PackedVector2Array, segs: int = 4) -> PackedVector2Array:
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
			out.append(0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	out.append(pts[n - 1])
	return out


static func _elipse(centro: Vector2, rx: float, ry: float, segs: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ca := cos(rot)
	var sa := sin(rot)
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		var lx := cos(a) * rx
		var ly := sin(a) * ry
		pts.append(centro + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
	return pts


static func _transformar(pts: PackedVector2Array, pos: Vector2, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var ca := cos(rot)
	var sa := sin(rot)
	for p in pts:
		out.append(pos + Vector2(p.x * ca - p.y * sa, p.x * sa + p.y * ca))
	return out


static func _rotar(v: Vector2, rot: float) -> Vector2:
	var ca := cos(rot)
	var sa := sin(rot)
	return Vector2(v.x * ca - v.y * sa, v.x * sa + v.y * ca)
