class_name Texturas_Personaje_3D
extends RefCounted

# ============================================================================
# MOTOR DE TEXTURAS 2D -> 3D DEL PERSONAJE (FIDELIDAD 1:1 CON PERSONAJE_VISUAL)
#
# Rasteriza sobre ImageTexture de alta resolución exactamente las mismas curvas
# Catmull-Rom, proporciones, ojos, iris recortados, pestañas/delineado, cejas,
# nariz, boca, labios, rubor, pecas, lunar, vello facial, marcas de edad
# (Envejecimiento_Personaje), flequillo/patillas de los 16 peinados, los 5
# estilos de gafas, faldas/vestidos y los 19 estilos de vestuario (frente y
# espalda) con trazos de tinta (#111827) y cel-shading de Personaje_Visual.gd.
# ============================================================================

const TINTA := Color("#111827")


## Compensa la iluminación solar + ambiental + tonemapping ACES del SubViewport 3D
## para que el color final en pantalla coincida con la paleta 2D de Personaje_Visual.
static func calibrar_color_3d(col: Color, _factor_oscurecer: float = 0.16) -> Color:
	var lum: float = col.r * 0.299 + col.g * 0.587 + col.b * 0.114
	var f_v: float = 0.12 + 0.15 * lum
	var mult_s: float = (1.12 + 0.38 * lum) if col.s > 0.08 else 1.04
	return Color.from_hsv(
		col.h,
		clampf(col.s * mult_s, 0.0, 1.0),
		clampf(col.v * (1.0 - f_v), 0.0, 1.0),
		col.a
	)


class Lienzo_2D extends RefCounted:
	var img: Image
	var origen: Vector2 = Vector2.ZERO
	var escala: float = 1.0
	var clip_x0: int = 0
	var clip_y0: int = 0
	var clip_x1: int = 256
	var clip_y1: int = 256

	func _init(imagen: Image, orig: Vector2, esc: float, rect_clip: Rect2i = Rect2i()) -> void:
		img = imagen
		origen = orig
		escala = esc
		if rect_clip.size.x > 0 and rect_clip.size.y > 0:
			clip_x0 = clampi(rect_clip.position.x, 0, img.get_width())
			clip_y0 = clampi(rect_clip.position.y, 0, img.get_height())
			clip_x1 = clampi(rect_clip.position.x + rect_clip.size.x, 0, img.get_width())
			clip_y1 = clampi(rect_clip.position.y + rect_clip.size.y, 0, img.get_height())
		else:
			clip_x0 = 0
			clip_y0 = 0
			clip_x1 = img.get_width()
			clip_y1 = img.get_height()

	func _mezclar_pixel(px: int, py: int, col: Color) -> void:
		if px < clip_x0 or px >= clip_x1 or py < clip_y0 or py >= clip_y1:
			return
		var a: float = clampf(col.a, 0.0, 1.0)
		if a <= 0.002:
			return
		if a >= 0.995:
			img.set_pixel(px, py, Color(col.r, col.g, col.b, 1.0))
			return
		var dst: Color = img.get_pixel(px, py)
		var inv: float = 1.0 - a
		img.set_pixel(px, py, Color(
			dst.r * inv + col.r * a,
			dst.g * inv + col.g * a,
			dst.b * inv + col.b * a,
			1.0
		))

	func _rellenar_tramo(py: int, xf0: float, xf1: float, col: Color) -> void:
		if py < clip_y0 or py >= clip_y1:
			return
		var x0: float = maxf(float(clip_x0), xf0)
		var x1: float = minf(float(clip_x1) - 0.001, xf1)
		if x1 <= x0:
			return
		var ix0: int = int(ceil(x0 - 0.5))
		var ix1: int = int(floor(x1 - 0.5))
		var left_px: int = ix0 - 1
		if left_px >= clip_x0 and left_px < clip_x1:
			var cov_l: float = clampf((float(left_px) + 1.0) - x0, 0.0, 1.0)
			if cov_l > 0.02:
				_mezclar_pixel(left_px, py, Color(col.r, col.g, col.b, col.a * cov_l))
		var right_px: int = ix1 + 1
		if right_px >= clip_x0 and right_px < clip_x1 and right_px != left_px:
			var cov_r: float = clampf(x1 - float(right_px), 0.0, 1.0)
			if cov_r > 0.02:
				_mezclar_pixel(right_px, py, Color(col.r, col.g, col.b, col.a * cov_r))
		var s0: int = maxi(clip_x0, ix0)
		var s1: int = mini(clip_x1 - 1, ix1)
		if s1 < s0:
			return
		if col.a >= 0.995:
			img.fill_rect(Rect2i(s0, py, s1 - s0 + 1, 1), Color(col.r, col.g, col.b, 1.0))
		else:
			var a: float = clampf(col.a, 0.0, 1.0)
			var inv: float = 1.0 - a
			for px in range(s0, s1 + 1):
				var dst: Color = img.get_pixel(px, py)
				img.set_pixel(px, py, Color(
					dst.r * inv + col.r * a,
					dst.g * inv + col.g * a,
					dst.b * inv + col.b * a,
					1.0
				))

	func poligono_px(tp: PackedVector2Array, col: Color) -> void:
		var n: int = tp.size()
		if n < 3 or col.a <= 0.002:
			return
		var min_y: float = tp[0].y
		var max_y: float = tp[0].y
		for i in range(1, n):
			var y: float = tp[i].y
			if y < min_y:
				min_y = y
			if y > max_y:
				max_y = y
		var y0: int = maxi(clip_y0, int(floor(min_y)))
		var y1: int = mini(clip_y1 - 1, int(ceil(max_y)))
		if y1 < y0:
			return
		var xs := PackedFloat32Array()
		for py in range(y0, y1 + 1):
			var yf: float = float(py) + 0.5
			xs.clear()
			var p_prev: Vector2 = tp[n - 1]
			for i in range(n):
				var p_cur: Vector2 = tp[i]
				if (p_prev.y <= yf and p_cur.y > yf) or (p_cur.y <= yf and p_prev.y > yf):
					var t: float = (yf - p_prev.y) / (p_cur.y - p_prev.y)
					xs.append(p_prev.x + t * (p_cur.x - p_prev.x))
				p_prev = p_cur
			var m: int = xs.size()
			if m < 2:
				continue
			for i in range(1, m):
				var key: float = xs[i]
				var j: int = i - 1
				while j >= 0 and xs[j] > key:
					xs[j + 1] = xs[j]
					j -= 1
				xs[j + 1] = key
			var k: int = 0
			while k + 1 < m:
				_rellenar_tramo(py, xs[k], xs[k + 1], col)
				k += 2

	func poligono(pts: PackedVector2Array, col: Color) -> void:
		var n: int = pts.size()
		if n < 3 or col.a <= 0.002:
			return
		var tp := PackedVector2Array()
		tp.resize(n)
		for i in range(n):
			tp[i] = pts[i] * escala + origen
		poligono_px(tp, col)

	func circulo_px(tc: Vector2, tr: float, col: Color) -> void:
		if tr <= 0.1 or col.a <= 0.002:
			return
		var y0: int = maxi(clip_y0, int(floor(tc.y - tr - 1.0)))
		var y1: int = mini(clip_y1 - 1, int(ceil(tc.y + tr + 1.0)))
		var r2: float = tr * tr
		for py in range(y0, y1 + 1):
			var dy: float = (float(py) + 0.5) - tc.y
			var dy2: float = dy * dy
			if dy2 >= r2:
				continue
			var dx: float = sqrt(r2 - dy2)
			_rellenar_tramo(py, tc.x - dx, tc.x + dx, col)

	func circulo(c: Vector2, radio: float, col: Color) -> void:
		circulo_px(c * escala + origen, maxf(0.45, radio * escala), col)

	func linea(p0: Vector2, p1: Vector2, col: Color, grosor: float = 1.5) -> void:
		if col.a <= 0.002:
			return
		var a: Vector2 = p0 * escala + origen
		var b: Vector2 = p1 * escala + origen
		var r: float = maxf(0.55, grosor * escala * 0.5)
		var diff: Vector2 = b - a
		var len_sq: float = diff.length_squared()
		if len_sq < 0.04:
			circulo_px(a, r, col)
			return
		var dir: Vector2 = diff / sqrt(len_sq)
		var n: Vector2 = Vector2(-dir.y, dir.x) * r
		var d: Vector2 = dir * r
		var d7: Vector2 = d * 0.7071
		var n7: Vector2 = n * 0.7071
		var capsula := PackedVector2Array([
			a + n,
			b + n,
			b + n7 + d7,
			b + d,
			b - n7 + d7,
			b - n,
			a - n,
			a - n7 - d7,
			a - d,
			a + n7 - d7,
		])
		poligono_px(capsula, col)

	func polilinea(pts: PackedVector2Array, col: Color, grosor: float = 1.8, cerrado: bool = false) -> void:
		var n: int = pts.size()
		if n < 2 or col.a <= 0.002:
			return
		for i in range(n - 1):
			linea(pts[i], pts[i + 1], col, grosor)
		if cerrado and n > 2:
			linea(pts[n - 1], pts[0], col, grosor)

	func poligono_tinta(pts: PackedVector2Array, relleno: Color, grosor: float = 2.0, col_tinta: Color = TINTA) -> void:
		if pts.size() < 3:
			return
		poligono(pts, relleno)
		polilinea(pts, col_tinta, grosor, true)

	func arco(centro: Vector2, radio: float, a0: float, a1: float, segs: int, col: Color, grosor: float = 1.5) -> void:
		var pasos: int = maxi(4, segs)
		var pts := PackedVector2Array()
		for i in range(pasos + 1):
			var a: float = lerpf(a0, a1, float(i) / float(pasos))
			pts.append(centro + Vector2(cos(a), sin(a)) * radio)
		polilinea(pts, col, grosor, false)

	func rectangulo(rect: Rect2, col: Color) -> void:
		poligono(PackedVector2Array([
			rect.position,
			Vector2(rect.position.x + rect.size.x, rect.position.y),
			rect.position + rect.size,
			Vector2(rect.position.x, rect.position.y + rect.size.y),
		]), col)


# ----------------------------------------------------------------------------
# Utilidades geométricas (idénticas a Personaje_Visual.gd)
# ----------------------------------------------------------------------------

static func suavizar_cerrado(pts: PackedVector2Array, segs: int = 4) -> PackedVector2Array:
	var n: int = pts.size()
	if n < 3:
		return pts
	var out := PackedVector2Array()
	for i in range(n):
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n]
		for s in range(segs):
			var t: float = float(s) / float(segs)
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	return out


static func suavizar_abierta(pts: PackedVector2Array, segs: int = 4) -> PackedVector2Array:
	var n: int = pts.size()
	if n < 2:
		return pts
	var ext := PackedVector2Array()
	ext.append(pts[0])
	for p: Vector2 in pts:
		ext.append(p)
	ext.append(pts[n - 1])
	var out := PackedVector2Array()
	for i in range(1, ext.size() - 2):
		var p0: Vector2 = ext[i - 1]
		var p1: Vector2 = ext[i]
		var p2: Vector2 = ext[i + 1]
		var p3: Vector2 = ext[i + 2]
		for s in range(segs):
			var t: float = float(s) / float(segs)
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	out.append(pts[n - 1])
	return out


static func recortar_elipse_a_ojo(centro: Vector2, rx_i: float, ry_i: float, ec: Vector2, rx_ojo: float, ry_ojo: float, segs: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(segs):
		var a: float = TAU * float(i) / float(segs)
		var px: float = centro.x + cos(a) * rx_i
		var py: float = centro.y + sin(a) * ry_i
		var dx: float = (px - ec.x) / rx_ojo
		var dy: float = (py - ec.y) / ry_ojo
		var d: float = sqrt(dx * dx + dy * dy)
		if d > 0.96:
			px = ec.x + (dx / d) * rx_ojo * 0.96
			py = ec.y + (dy / d) * ry_ojo * 0.96
		var nx: float = clampf((px - ec.x) / rx_ojo, -1.0, 1.0)
		var lid_top: float = ec.y - ry_ojo * (0.86 - 0.52 * nx * nx)
		var lid_bot: float = ec.y + ry_ojo * (0.78 - 0.44 * nx * nx)
		py = clampf(py, lid_top, lid_bot)
		out.append(Vector2(px, py))
	return out


static func elipse_pts(centro: Vector2, rx: float, ry: float, segs: int, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ca: float = cos(rot)
	var sa: float = sin(rot)
	for i in range(segs):
		var a: float = TAU * float(i) / float(segs)
		var lx: float = cos(a) * rx
		var ly: float = sin(a) * ry
		pts.append(centro + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
	return pts


static func puntos_estrella(centro: Vector2, radio_ext: float, radio_int: float, puntas: int = 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(puntas * 2):
		var ang: float = -PI * 0.5 + PI * float(i) / float(puntas)
		var r: float = radio_ext if i % 2 == 0 else radio_int
		pts.append(centro + Vector2(cos(ang), sin(ang)) * r)
	return pts


static func transformar_pts(pts: PackedVector2Array, pos: Vector2, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var ca: float = cos(rot)
	var sa: float = sin(rot)
	for p in pts:
		out.append(pos + Vector2(p.x * ca - p.y * sa, p.x * sa + p.y * ca))
	return out


static func rotar(v: Vector2, rot: float) -> Vector2:
	var ca: float = cos(rot)
	var sa: float = sin(rot)
	return Vector2(v.x * ca - v.y * sa, v.x * sa + v.y * ca)


static func sombra_piel(piel: Color) -> Color:
	var s: Color = piel.darkened(0.18)
	s.r = minf(1.0, s.r * 1.04)
	return s


static func metricas_cuerpo(es_mujer: bool, ap: Dictionary) -> Dictionary:
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

	return {
		"sh_x": sh_x,
		"waist_x": waist_x,
		"hip_x": hip_x,
		"hip_leg_x": hip_x * 0.50,
		"nw": nw,
		"arm_scale": arm_scale,
		"leg_scale": leg_scale,
		"jaw_w": jaw_w,
	}


# ============================================================================
# 1. GENERADOR DE TEXTURA DEL ROSTRO 2D -> 3D (384x384)
# ============================================================================

const TAM_TEX_CARA: int = 384
const ESC_TEX_CARA: float = 4.5
const ORIG_TEX_CARA := Vector2(192.0, 192.0)


static func uv_cara(x_2d: float, y_2d: float) -> Vector2:
	return Vector2(
		clampf((ORIG_TEX_CARA.x + x_2d * ESC_TEX_CARA) / float(TAM_TEX_CARA), 0.04, 0.96),
		clampf((ORIG_TEX_CARA.y + y_2d * ESC_TEX_CARA) / float(TAM_TEX_CARA), 0.04, 0.96)
	)


static func generar_textura_rostro(ap: Dictionary, edad: int, expresion: String = "feliz", mirada: Vector2 = Vector2.ZERO, parpadeo: bool = false) -> ImageTexture:
	var rasgos_edad: Dictionary = Envejecimiento_Personaje.rasgos(edad)
	var es_mujer: bool = Apariencia_Personaje.es_mujer(ap)
	var met: Dictionary = metricas_cuerpo(es_mujer, ap)
	var jaw_w: float = float(met["jaw_w"])

	var piel_raw: Color = Envejecimiento_Personaje.color_piel(
		Apariencia_Personaje.color_de(ap, "color_piel", Color("#f8cfb4")),
		float(rasgos_edad.get("piel_apagada", 0.0)))
	var piel: Color = calibrar_color_3d(piel_raw, 0.12)
	var piel_som: Color = sombra_piel(piel)
	var ojos: Color = Apariencia_Personaje.color_de(ap, "color_ojos", Color("#6b4226"))
	var pelo_raw: Color = Envejecimiento_Personaje.color_pelo(
		Apariencia_Personaje.color_de(ap, "color_pelo", Color("#7c4728")),
		float(rasgos_edad.get("canas", 0.0)))
	var pelo: Color = calibrar_color_3d(pelo_raw, 0.08)

	var forma_ojos := str(ap.get("forma_ojos", "almendrados"))
	var estilo_cejas := str(ap.get("estilo_cejas", "naturales"))
	var forma_nariz := str(ap.get("forma_nariz", "normal"))
	var forma_boca := str(ap.get("forma_boca", "normal"))
	var color_labios: Color = Apariencia_Personaje.color_labios_de(ap, piel_raw)
	var estilo_pelo := str(ap.get("estilo_pelo", "alborotado"))
	var vello := str(ap.get("vello_facial", "ninguno"))
	var gafas := str(ap.get("gafas", "ninguna"))
	var pecas := bool(ap.get("pecas", false))
	var lunar := str(ap.get("lunar", "ninguno"))
	var rubor_lvl := str(ap.get("rubor", "suave"))
	var delineado := bool(ap.get("delineado", false))
	var grosor: float = 2.35

	var img := Image.create(TAM_TEX_CARA, TAM_TEX_CARA, false, Image.FORMAT_RGBA8)
	img.fill(piel)
	var l := Lienzo_2D.new(img, ORIG_TEX_CARA, ESC_TEX_CARA)

	# 1. Sombra cel-shading suave en lado derecho de mandíbula y sien
	var sombra_cara := suavizar_cerrado(PackedVector2Array([
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
	l.poligono(sombra_cara, Color(piel_som, 0.38))

	# 2. Sombra suave en la frente bajo la línea del pelo
	if estilo_pelo != "calvo":
		var sombra_frente := suavizar_cerrado(PackedVector2Array([
			Vector2(-21.0 * jaw_w, -23.0), Vector2(-10.0, -27.0), Vector2(0.0, -26.0),
			Vector2(10.0, -27.0), Vector2(21.0 * jaw_w, -23.0), Vector2(18.0 * jaw_w, -18.5),
			Vector2(0.0, -21.5), Vector2(-18.0 * jaw_w, -18.5),
		]), 3)
		l.poligono(sombra_frente, Color(piel_som, 0.22))

	# 3. Rubor cálido en mejillas
	var base_rubor := 0.0
	if rubor_lvl == "suave":
		base_rubor = 0.28 if es_mujer else 0.16
	elif rubor_lvl == "intenso":
		base_rubor = 0.44 if es_mujer else 0.30
	if base_rubor > 0.01:
		var color_rubor := Color("#f43f5e", base_rubor)
		for lado: float in [-1.0, 1.0]:
			l.poligono(elipse_pts(Vector2(lado * 17.5, 10.5), 6.0, 3.1, 18), color_rubor)

	# 4. Pecas y lunar
	if pecas:
		var col_peca := piel_som.darkened(0.28)
		for p: Vector2 in [
			Vector2(-16.5, 8.0), Vector2(-12.5, 10.0), Vector2(-19.5, 10.8),
			Vector2(16.5, 8.0), Vector2(12.5, 10.0), Vector2(19.5, 10.8),
			Vector2(-3.5, 7.6), Vector2(3.5, 7.6),
		]:
			l.circulo(p, 1.05, col_peca)

	if lunar != "ninguno":
		var pos_l := Vector2(15.5, 11.5)
		if lunar == "labio":
			pos_l = Vector2(-10.5, 15.5)
		elif lunar == "ceja":
			pos_l = Vector2(19.0, -7.5)
		l.circulo(pos_l, 1.35, Color("#3f271d", 0.88))

	# 5. Barba sombra / corta / completa / candado (detrás de boca)
	if not es_mujer and vello in ["sombra", "barba_corta", "barba_completa", "candado"]:
		_dibujar_vello_facial(l, jaw_w, vello, pelo, grosor)

	# 6. Ojos expresivos almendrados/Sims (idénticos a Personaje_Visual._dibujar_ojos)
	_dibujar_ojos(l, es_mujer, forma_ojos, delineado, piel_som, ojos, mirada, grosor, expresion, parpadeo)

	# 7. Cejas esculpidas
	_dibujar_cejas(l, es_mujer, estilo_cejas, pelo, expresion, rasgos_edad)

	# 8. Nariz cómic limpia
	_dibujar_nariz(l, forma_nariz, piel, piel_som)

	# 9. Marcas de la edad (frente, entrecejo, patas de gallo, bolsas, surcos, manchas, papada)
	_dibujar_marcas_edad(l, piel_som, rasgos_edad, jaw_w)

	# 10. Boca expresiva y labios
	_dibujar_boca(l, ap, es_mujer, forma_boca, color_labios, piel_som, grosor, expresion)

	# 11. Bigote / perilla
	if not es_mujer and vello in ["bigote", "perilla"]:
		_dibujar_vello_facial(l, jaw_w, vello, pelo, grosor)

	# 12. Gafas 2D en el rostro (para que las lentes de sol, reflejos y monturas sean 1:1 con Personaje_Visual)
	if gafas != "ninguna":
		_dibujar_gafas_2d(l, gafas)

	# 13. Flequillo y patillas delanteras 2D (idénticas a Personaje_Visual._dibujar_pelo_delantero)
	_dibujar_pelo_delantero_2d(l, estilo_pelo, pelo, float(rasgos_edad.get("canas", 0.0)), grosor)

	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _dibujar_gafas_2d(l: Lienzo_2D, tipo: String) -> void:
	var cristal := Color(0.90, 0.97, 1.0, 0.16) if tipo != "sol" else Color("#0f172a", 0.94)
	var montura := Color("#1e293b")
	var y: float = -0.5

	match tipo:
		"redondas":
			for lado: float in [-1.0, 1.0]:
				var pos := Vector2(lado * 12.2, y)
				l.circulo(pos, 9.6, cristal)
				l.arco(pos, 9.6, 0.0, TAU, 26, montura, 1.85)
				l.linea(pos + Vector2(-5.2, -4.6), pos + Vector2(-2.2, -6.4), Color(1.0, 1.0, 1.0, 0.55), 1.3)
			l.linea(Vector2(-2.6, y - 0.8), Vector2(2.6, y - 0.8), montura, 1.7)
		"cuadradas":
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.4
				var marco := suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 9.4, y - 7.0), Vector2(cx + 9.4, y - 7.0),
					Vector2(cx + 8.8, y + 6.8), Vector2(cx - 8.8, y + 6.8),
				]), 2)
				l.poligono(marco, cristal)
				l.polilinea(marco, montura, 1.9, true)
			l.linea(Vector2(-3.0, y - 1.5), Vector2(3.0, y - 1.5), montura, 1.7)
		"aviador":
			var mont_av := Color("#b45309")
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.6
				var lente := suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 9.8 * lado, y - 6.8), Vector2(cx + 9.4 * lado, y - 5.2),
					Vector2(cx + 9.6 * lado, y + 3.8), Vector2(cx + 1.5 * lado, y + 8.6),
					Vector2(cx - 7.5 * lado, y + 5.0),
				]), 3)
				l.poligono(lente, Color("#0284c7", 0.28))
				l.polilinea(lente, mont_av, 1.7, true)
			l.linea(Vector2(-3.0, y - 4.2), Vector2(3.0, y - 4.2), mont_av, 1.5)
			l.linea(Vector2(-9.5, y - 6.4), Vector2(9.5, y - 6.4), mont_av, 1.3)
		"cateye":
			var mont_ce := Color("#7f1d1d")
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.4
				var marco := suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 8.6 * lado, y - 5.4), Vector2(cx + 10.6 * lado, y - 8.4),
					Vector2(cx + 8.2 * lado, y + 6.0), Vector2(cx - 8.0 * lado, y + 5.8),
				]), 2)
				l.poligono(marco, cristal)
				l.polilinea(marco, mont_ce, 2.0, true)
			l.linea(Vector2(-3.4, y - 2.0), Vector2(3.4, y - 2.0), mont_ce, 1.7)
		"sol":
			for lado: float in [-1.0, 1.0]:
				var cx: float = lado * 12.6
				var marco := suavizar_cerrado(PackedVector2Array([
					Vector2(cx - 10.0, y - 7.0), Vector2(cx + 10.0, y - 7.0),
					Vector2(cx + 9.2, y + 7.2), Vector2(cx - 9.2, y + 7.2),
				]), 2)
				l.poligono(marco, cristal)
				l.polilinea(marco, montura, 2.2, true)
				l.linea(Vector2(cx - 5.5, y - 4.0), Vector2(cx - 0.5, y + 3.5), Color(1.0, 1.0, 1.0, 0.48), 2.0)
			l.linea(Vector2(-3.0, y - 2.4), Vector2(3.0, y - 2.4), montura, 2.2)


static func _dibujar_pelo_delantero_2d(l: Lienzo_2D, estilo: String, pelo: Color, canas: float, grosor: float) -> void:
	var brillo := pelo.lightened(lerpf(0.24, 0.07, canas))
	var mech_ink := Color(pelo.darkened(0.36), 0.72)

	match estilo:
		"calvo":
			var br := suavizar_abierta(PackedVector2Array([
				Vector2(-11.0, -29.0), Vector2(-4.0, -33.0), Vector2(5.0, -32.0),
			]), 3)
			l.polilinea(br, Color(1.0, 1.0, 1.0, 0.45), 2.6)
		"rapado":
			var pts := suavizar_cerrado(PackedVector2Array([
				Vector2(-29.0, -8.0), Vector2(-29.0, -21.0), Vector2(-19.0, -34.5),
				Vector2(0.0, -38.8), Vector2(19.0, -34.5), Vector2(29.0, -21.0),
				Vector2(29.0, -8.0), Vector2(25.2, -18.0), Vector2(14.0, -24.0),
				Vector2(0.0, -25.0), Vector2(-14.0, -24.0), Vector2(-25.2, -18.0),
			]), 3)
			l.poligono_tinta(pts, pelo, grosor * 0.80)
		"alborotado":
			var base_alb := PackedVector2Array([
				Vector2(-29.0, -4.0), Vector2(-32.5, -15.5), Vector2(-35.0, -23.0),
				Vector2(-28.5, -28.5), Vector2(-26.0, -37.0), Vector2(-15.0, -42.5),
				Vector2(-6.0, -40.5), Vector2(5.5, -50.5), Vector2(15.5, -43.5),
				Vector2(30.0, -47.0), Vector2(29.0, -33.5), Vector2(36.5, -26.0),
				Vector2(31.5, -14.5), Vector2(29.0, -4.0), Vector2(25.2, -16.0),
				Vector2(18.0, -22.5), Vector2(11.5, -14.5), Vector2(5.5, -23.5),
				Vector2(-3.5, -15.5), Vector2(-12.5, -23.0), Vector2(-23.5, -14.5),
			])
			l.poligono_tinta(suavizar_cerrado(base_alb, 4), pelo, grosor * 0.92)
			l.polilinea(suavizar_abierta(PackedVector2Array([
				Vector2(-12.0, -36.0), Vector2(-4.0, -31.0), Vector2(5.0, -36.5),
			]), 4), mech_ink, 1.45)
			l.polilinea(suavizar_abierta(PackedVector2Array([
				Vector2(13.0, -40.5), Vector2(17.5, -32.5), Vector2(26.0, -33.0),
			]), 4), mech_ink, 1.35)
			_brillo_pelo_2d(l, Vector2(-14.0, -32.0), Vector2(12.0, -34.5), brillo)
		"tupe":
			var pts_t := suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -4.0), Vector2(-31.5, -20.0), Vector2(-24.0, -37.0),
				Vector2(-6.0, -49.5), Vector2(15.0, -52.0), Vector2(28.0, -42.0),
				Vector2(32.5, -24.0), Vector2(29.5, -4.0), Vector2(25.5, -18.0),
				Vector2(16.0, -24.5), Vector2(2.0, -23.0), Vector2(-15.0, -25.0),
				Vector2(-25.5, -17.0),
			]), 4)
			l.poligono_tinta(pts_t, pelo, grosor * 0.94)
			_brillo_pelo_2d(l, Vector2(-11.0, -34.0), Vector2(14.0, -35.0), brillo)
		"corto":
			var pts := suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -3.0), Vector2(-32.5, -19.0), Vector2(-22.0, -37.0),
				Vector2(0.0, -43.5), Vector2(22.0, -39.0), Vector2(32.5, -21.0),
				Vector2(29.5, -3.0), Vector2(24.8, -16.5), Vector2(12.0, -23.0),
				Vector2(-4.0, -20.0), Vector2(-18.0, -15.5), Vector2(-25.2, -12.0),
			]), 4)
			l.poligono_tinta(pts, pelo, grosor * 0.94)
			_brillo_pelo_2d(l, Vector2(-11.0, -32.0), Vector2(13.0, -31.5), brillo)
		"degradado":
			var fade := suavizar_cerrado(PackedVector2Array([
				Vector2(-28.5, -10.0), Vector2(-29.5, -23.0), Vector2(-21.0, -36.0),
				Vector2(21.0, -36.0), Vector2(29.5, -23.0), Vector2(28.5, -10.0),
				Vector2(25.0, -21.0), Vector2(15.0, -25.0), Vector2(-15.0, -25.0), Vector2(-25.0, -21.0),
			]), 3)
			l.poligono_tinta(fade, pelo.darkened(0.18), grosor * 0.80)
			var top_d := suavizar_cerrado(PackedVector2Array([
				Vector2(-24.0, -26.0), Vector2(-21.0, -41.0), Vector2(-7.0, -46.5),
				Vector2(8.0, -47.5), Vector2(22.0, -40.5), Vector2(24.0, -26.0),
				Vector2(12.0, -22.5), Vector2(0.0, -25.0), Vector2(-12.0, -22.5),
			]), 3)
			l.poligono_tinta(top_d, pelo, grosor * 0.92)
			_brillo_pelo_2d(l, Vector2(-12.0, -33.0), Vector2(12.0, -34.0), brillo)
		"raya_lado":
			var pts_rl := suavizar_cerrado(PackedVector2Array([
				Vector2(-29.5, -3.0), Vector2(-32.5, -19.0), Vector2(-22.5, -37.0),
				Vector2(0.0, -43.8), Vector2(22.5, -38.0), Vector2(32.5, -19.0),
				Vector2(29.5, -3.0), Vector2(25.0, -16.5), Vector2(13.0, -24.5),
				Vector2(-1.0, -18.5), Vector2(-14.0, -15.5), Vector2(-25.0, -13.0),
			]), 4)
			l.poligono_tinta(pts_rl, pelo, grosor * 0.94)
			l.polilinea(suavizar_abierta(PackedVector2Array([
				Vector2(14.0, -39.0), Vector2(12.5, -29.0), Vector2(13.0, -24.5),
			]), 3), mech_ink, 1.5)
			_brillo_pelo_2d(l, Vector2(-14.0, -32.0), Vector2(8.0, -33.0), brillo)
		"rizado":
			var crown := suavizar_cerrado(PackedVector2Array([
				Vector2(-31.0, -8.0), Vector2(-34.5, -18.0), Vector2(-30.5, -28.0),
				Vector2(-27.0, -38.0), Vector2(-16.0, -43.5), Vector2(-4.0, -46.5),
				Vector2(8.0, -46.0), Vector2(20.0, -41.5), Vector2(29.5, -32.0),
				Vector2(34.5, -20.0), Vector2(31.0, -8.0), Vector2(25.5, -16.5),
				Vector2(17.5, -22.5), Vector2(7.0, -20.5), Vector2(-2.0, -24.0),
				Vector2(-12.0, -20.5), Vector2(-22.5, -22.0), Vector2(-27.0, -14.5),
			]), 3)
			l.poligono_tinta(crown, pelo, grosor * 0.94)
			_brillo_pelo_2d(l, Vector2(-9.0, -33.5), Vector2(10.0, -34.5), brillo)
		"afro":
			var frente_a := suavizar_cerrado(PackedVector2Array([
				Vector2(-32.0, -12.0), Vector2(-30.0, -26.0), Vector2(-18.0, -38.0),
				Vector2(0.0, -41.0), Vector2(18.0, -38.0), Vector2(30.0, -26.0),
				Vector2(32.0, -12.0), Vector2(26.0, -21.0), Vector2(14.0, -25.5),
				Vector2(0.0, -26.5), Vector2(-14.0, -25.5), Vector2(-26.0, -21.0),
			]), 4)
			l.poligono(frente_a, pelo)
			_brillo_pelo_2d(l, Vector2(-13.0, -33.0), Vector2(13.0, -33.0), brillo)
		"largo", "ondulado":
			var pts_l := suavizar_cerrado(PackedVector2Array([
				Vector2(-32.5, 22.0), Vector2(-36.5, -12.0), Vector2(-26.0, -36.5),
				Vector2(0.0, -44.2), Vector2(26.0, -36.5), Vector2(36.5, -12.0),
				Vector2(32.5, 22.0), Vector2(27.5, -4.0), Vector2(20.0, -19.5),
				Vector2(6.0, -24.5), Vector2(-6.0, -16.5), Vector2(-20.5, -19.5),
				Vector2(-27.5, -4.0),
			]), 4)
			l.poligono_tinta(pts_l, pelo, grosor * 0.94)
			l.polilinea(suavizar_abierta(PackedVector2Array([
				Vector2(6.0, -41.0), Vector2(6.0, -29.0), Vector2(6.0, -24.5),
			]), 3), mech_ink, 1.4)
			_brillo_pelo_2d(l, Vector2(-13.0, -32.5), Vector2(13.0, -32.5), brillo)
		"media_melena":
			var pts_m := suavizar_cerrado(PackedVector2Array([
				Vector2(-32.5, 23.0), Vector2(-36.0, -12.0), Vector2(-26.0, -36.5),
				Vector2(0.0, -44.2), Vector2(26.0, -36.5), Vector2(36.0, -12.0),
				Vector2(32.5, 23.0), Vector2(26.5, 1.0), Vector2(22.5, -18.5),
				Vector2(9.0, -15.5), Vector2(0.0, -21.5), Vector2(-9.0, -15.5),
				Vector2(-22.5, -18.5), Vector2(-26.5, 1.0),
			]), 4)
			l.poligono_tinta(pts_m, pelo, grosor * 0.94)
			_brillo_pelo_2d(l, Vector2(-13.0, -32.5), Vector2(13.0, -32.5), brillo)
		"bob":
			var pts_b := suavizar_cerrado(PackedVector2Array([
				Vector2(-32.0, 14.0), Vector2(-35.5, -12.0), Vector2(-25.5, -36.0),
				Vector2(0.0, -43.5), Vector2(25.5, -36.0), Vector2(35.5, -12.0),
				Vector2(32.0, 14.0), Vector2(26.5, -4.0), Vector2(22.5, -16.0),
				Vector2(10.0, -15.5), Vector2(0.0, -15.0), Vector2(-10.0, -15.5),
				Vector2(-22.5, -16.0), Vector2(-26.5, -4.0),
			]), 4)
			l.poligono_tinta(pts_b, pelo, grosor * 0.94)
			for fx: float in [-8.0, 0.0, 8.0]:
				l.linea(Vector2(fx, -22.0), Vector2(fx, -15.5), mech_ink, 1.25)
			_brillo_pelo_2d(l, Vector2(-13.0, -32.5), Vector2(13.0, -32.5), brillo)
		"coleta", "mono", "dos_coletas":
			var pts_c := suavizar_cerrado(PackedVector2Array([
				Vector2(-30.0, -3.0), Vector2(-32.0, -20.0), Vector2(-22.0, -36.5),
				Vector2(0.0, -43.0), Vector2(22.0, -36.5), Vector2(32.0, -20.0),
				Vector2(30.0, -3.0), Vector2(25.5, -16.0), Vector2(13.0, -22.5),
				Vector2(0.0, -20.0), Vector2(-13.0, -22.5), Vector2(-25.5, -16.0),
			]), 4)
			l.poligono_tinta(pts_c, pelo, grosor * 0.94)
			_brillo_pelo_2d(l, Vector2(-11.0, -32.5), Vector2(11.0, -32.5), brillo)


static func _brillo_pelo_2d(l: Lienzo_2D, p0: Vector2, p1: Vector2, col: Color) -> void:
	var medio := (p0 + p1) * 0.5 + Vector2(0.0, -3.5)
	l.polilinea(suavizar_abierta(PackedVector2Array([p0, medio, p1]), 4), Color(col, 0.62), 3.0)


static func _dibujar_ojos(l: Lienzo_2D, es_mujer: bool, forma_ojos: String, delineado: bool,
		piel_sombra: Color, color_ojos: Color, mirada: Vector2, grosor: float,
		e: String, parpadeo: bool) -> void:
	var en_shock: bool = e in ["sorpresa", "panico", "asustado_frio"]
	var ojos_dormidos: bool = e in ["dormido", "roncando", "cansado", "bostezo"]
	var ojos_felices: bool = e in ["feliz_cerrado", "satisfecho", "cantando", "reir"]

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
			var arco_feliz := suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.85, 1.8),
				ec_local + Vector2(0.0, -3.6),
				ec_local + Vector2(rx * 0.85, 1.8),
			]), 4)
			l.polilinea(arco_feliz, TINTA, grosor * 1.02)
			continue

		if parpadeo or ojos_dormidos:
			var dy_mid: float = 2.6 if ojos_dormidos else -1.0
			var arco_cerrado := suavizar_abierta(PackedVector2Array([
				ec_local + Vector2(-rx * 0.85, 0.2),
				ec_local + Vector2(0.0, dy_mid),
				ec_local + Vector2(rx * 0.85, 0.2),
			]), 4)
			l.polilinea(arco_cerrado, TINTA, grosor * 0.92)
			continue

		# 1. Esclerótica
		var sclera_local: PackedVector2Array
		var tilt_l := tilt * lado
		if en_shock:
			sclera_local = elipse_pts(ec_local, rx, ry, 24, 0.0)
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
			sclera_local = transformar_pts(suavizar_cerrado(pts_o, 4), ec_local, tilt_l)
		l.poligono(sclera_local, Color("#fcfcfd"))

		# 2. Iris recortado al ojo + brillo inferior + pupila
		var ic_local := ec_local + mirada * 0.85 + Vector2(0.0, 0.0 if en_shock else -0.35)
		var r_iris: float = 3.8 if en_shock else 4.85
		var iris_ext: PackedVector2Array
		var iris_body: PackedVector2Array
		var pupila_pts: PackedVector2Array

		if en_shock:
			iris_ext = elipse_pts(ic_local, r_iris, r_iris, 20, 0.0)
			iris_body = elipse_pts(ic_local, r_iris * 0.76, r_iris * 0.76, 18, 0.0)
			pupila_pts = elipse_pts(ic_local, 1.9, 1.9, 14, 0.0)
		else:
			iris_ext = recortar_elipse_a_ojo(ic_local, r_iris, r_iris * 1.04, ec_local, rx, ry, 22)
			iris_body = recortar_elipse_a_ojo(ic_local + Vector2(0.0, 0.25), r_iris * 0.78, r_iris * 0.80, ec_local, rx, ry, 18)
			pupila_pts = recortar_elipse_a_ojo(ic_local + Vector2(0.0, 0.15), 2.15, 2.25, ec_local, rx, ry, 16)

		l.poligono(iris_ext, color_ojos.darkened(0.42))
		l.poligono(iris_body, color_ojos)

		if not en_shock:
			var glow_pts := recortar_elipse_a_ojo(ic_local + Vector2(0.0, 1.9), r_iris * 0.54, r_iris * 0.34, ec_local, rx, ry, 14)
			l.poligono(glow_pts, Color(color_ojos.lightened(0.40), 0.75))

		l.poligono(pupila_pts, TINTA)

		# 3. Sombra suave bajo el párpado superior
		if not en_shock:
			var sh_top := suavizar_abierta(PackedVector2Array([
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
			l.poligono(transformar_pts(sh_poly, ec_local, tilt_l), Color(0.18, 0.24, 0.38, 0.16))

		# 4. Brillos especulares nítidos
		l.circulo(ic_local + Vector2(-1.45, -1.45), 1.45, Color.WHITE)
		l.circulo(ic_local + Vector2(1.4, 1.3), 0.70, Color(1.0, 1.0, 1.0, 0.88))

		# 5. Párpado superior con trazo limpio + pestañas / delineado
		if en_shock:
			l.polilinea(sclera_local, TINTA, 2.0, true)
		else:
			var lid_top := transformar_pts(suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 1.04, 0.6),
				Vector2(-rx * 0.58, -ry * 0.94),
				Vector2(0.0, -ry * 1.06),
				Vector2(rx * 0.62, -ry * 0.90),
				Vector2(rx * 1.04, 0.3),
			]), 5), ec_local, tilt_l)
			var ancho_lid := 2.9 if (es_mujer or delineado) else 2.4
			l.polilinea(lid_top, TINTA, ancho_lid)

			var pliegue := transformar_pts(suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 0.58, -ry * 1.32),
				Vector2(0.0, -ry * 1.46),
				Vector2(rx * 0.58, -ry * 1.28),
			]), 4), ec_local, tilt_l)
			l.polilinea(pliegue, Color(piel_sombra, 0.68), 1.15)

			var lid_bot := transformar_pts(suavizar_abierta(PackedVector2Array([
				Vector2(-rx * 0.45, ry * 0.80),
				Vector2(0.0, ry * 0.90),
				Vector2(rx * 0.45, ry * 0.82),
			]), 4), ec_local, tilt_l)
			l.polilinea(lid_bot, Color(piel_sombra, 0.58), 1.1)

			if delineado or es_mujer:
				var wb := rotar(Vector2(lado * (rx * 0.92), -ry * 0.22), tilt_l) + ec_local
				var ala := PackedVector2Array([
					wb + Vector2(-lado * 1.2, -1.2),
					wb + Vector2(lado * (4.4 if delineado else 3.2), -2.8 if delineado else -2.2),
					wb + Vector2(lado * 1.1, 0.9),
				])
				l.poligono(ala, TINTA)
				if delineado:
					var tip2 := rotar(Vector2(lado * (rx * 0.68), -ry * 0.72), tilt_l) + ec_local
					l.linea(tip2, tip2 + Vector2(lado * 2.5, -2.2), TINTA, 1.5)


static func _dibujar_cejas(l: Lienzo_2D, es_mujer: bool, estilo_cejas: String, color_pelo: Color, expr_activa: String, rasgos_edad: Dictionary) -> void:
	var col_ceja := color_pelo.darkened(0.26)
	var thick: float = (2.2 if es_mujer else 3.0) * (1.0 - 0.32 * float(rasgos_edad.get("cejas_finas", 0.0)))
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

		var ceja := suavizar_cerrado(PackedVector2Array([
			Vector2(lado * 5.6, yb + dy_in - thick * 0.44),
			Vector2(lado * 12.6, yb + dy_mid - thick * 0.48),
			Vector2(lado * 20.6, yb + dy_out),
			Vector2(lado * 12.6, yb + dy_mid + thick * 0.48),
			Vector2(lado * 5.8, yb + dy_in + thick * 0.52),
		]), 3)
		l.poligono_tinta(ceja, col_ceja, 1.15)


static func _dibujar_nariz(l: Lienzo_2D, forma_nariz: String, piel: Color, piel_sombra: Color) -> void:
	var brillo_n := piel.lightened(0.20)
	match forma_nariz:
		"respingona":
			l.poligono(elipse_pts(Vector2(0.4, 8.6), 2.8, 1.6, 12), Color(piel_sombra, 0.52))
			l.circulo(Vector2(-0.5, 6.8), 1.2, Color(brillo_n, 0.65))
			var curva := suavizar_abierta(PackedVector2Array([
				Vector2(-2.2, 8.0), Vector2(0.0, 9.2), Vector2(2.4, 7.6),
			]), 4)
			l.polilinea(curva, Color(TINTA, 0.78), 1.45)
		"recta":
			var bridge := PackedVector2Array([
				Vector2(0.2, 0.5), Vector2(1.8, 8.6), Vector2(0.0, 10.6), Vector2(-1.2, 8.8),
			])
			l.poligono(bridge, Color(piel_sombra, 0.42))
			l.linea(Vector2(-0.6, 2.0), Vector2(-0.6, 7.8), Color(brillo_n, 0.60), 1.3)
			var curva := suavizar_abierta(PackedVector2Array([
				Vector2(-2.0, 9.8), Vector2(0.4, 10.6), Vector2(2.8, 9.4),
			]), 4)
			l.polilinea(curva, Color(TINTA, 0.78), 1.45)
		"ancha":
			l.poligono(elipse_pts(Vector2(0.4, 9.6), 4.4, 2.0, 14), Color(piel_sombra, 0.50))
			l.circulo(Vector2(-0.6, 7.6), 1.5, Color(brillo_n, 0.60))
			var curva := suavizar_abierta(PackedVector2Array([
				Vector2(-3.8, 9.0), Vector2(-1.8, 10.4), Vector2(1.8, 10.4), Vector2(3.8, 9.0),
			]), 4)
			l.polilinea(curva, Color(TINTA, 0.78), 1.50)
		"fina":
			l.linea(Vector2(0.9, 1.8), Vector2(1.2, 8.2), Color(piel_sombra, 0.48), 1.6)
			var curva := suavizar_abierta(PackedVector2Array([
				Vector2(-1.6, 9.2), Vector2(0.3, 10.0), Vector2(2.0, 8.9),
			]), 4)
			l.polilinea(curva, Color(TINTA, 0.74), 1.35)
		_:
			var puente := PackedVector2Array([
				Vector2(0.4, 1.2), Vector2(1.8, 7.6), Vector2(0.2, 10.2), Vector2(-1.0, 8.4),
			])
			l.poligono(puente, Color(piel_sombra, 0.40))
			l.circulo(Vector2(-0.6, 7.8), 1.35, Color(brillo_n, 0.62))
			var curva := suavizar_abierta(PackedVector2Array([
				Vector2(-2.6, 9.2), Vector2(0.0, 10.5), Vector2(2.8, 9.2),
			]), 4)
			l.polilinea(curva, Color(TINTA, 0.78), 1.48)


static func _dibujar_marcas_edad(l: Lienzo_2D, piel_sombra: Color, rasgos_edad: Dictionary, jaw_w: float) -> void:
	var frente := float(rasgos_edad.get("frente", 0.0))
	var gallo := float(rasgos_edad.get("patas_gallo", 0.0))
	var bolsas := float(rasgos_edad.get("bolsas", 0.0))
	var surcos := float(rasgos_edad.get("surcos", 0.0))
	var manchas := float(rasgos_edad.get("manchas", 0.0))
	var flacidez := float(rasgos_edad.get("flacidez", 0.0))

	if frente > 0.02:
		var col_f := Color(piel_sombra.darkened(0.12), 0.13 + 0.32 * frente)
		var ancho := 13.0 * jaw_w
		for i in range(2):
			var y := -28.6 + float(i) * 4.2
			var onda := 1.2 - float(i) * 0.25
			var arruga := suavizar_abierta(PackedVector2Array([
				Vector2(-ancho, y + onda),
				Vector2(-ancho * 0.45, y - onda * 0.7),
				Vector2(0.0, y + onda * 0.35),
				Vector2(ancho * 0.45, y - onda * 0.7),
				Vector2(ancho, y + onda),
			]), 4)
			l.polilinea(arruga, col_f, 0.8 + 0.75 * frente)
		if frente > 0.40:
			var col_g := Color(piel_sombra.darkened(0.16), 0.14 + 0.26 * frente)
			for lado: float in [-1.0, 1.0]:
				var glabela := suavizar_abierta(PackedVector2Array([
					Vector2(lado * 2.2, -14.4),
					Vector2(lado * 3.2, -12.0),
					Vector2(lado * 2.4, -9.6),
				]), 3)
				l.polilinea(glabela, col_g, 0.85 + 0.45 * frente)

	for lado: float in [-1.0, 1.0]:
		if gallo > 0.02:
			var col_p := Color(piel_sombra.darkened(0.12), 0.12 + 0.30 * gallo)
			for i in range(3):
				var y0 := -2.4 + float(i) * 2.6
				var ala := suavizar_abierta(PackedVector2Array([
					Vector2(lado * 19.0, y0),
					Vector2(lado * (21.2 + 0.4 * float(i)), y0 - 0.7),
					Vector2(lado * (23.2 + 0.8 * float(i)), y0 - 1.8 - 0.3 * float(i)),
				]), 3)
				l.polilinea(ala, col_p, 0.75 + 0.5 * gallo)

		if bolsas > 0.02:
			l.poligono(elipse_pts(Vector2(lado * 12.2, 6.3), 6.3, 1.9, 16), Color(piel_sombra, 0.09 + 0.15 * bolsas))
			var arco_b := suavizar_abierta(PackedVector2Array([
				Vector2(lado * 6.4, 5.7),
				Vector2(lado * 12.2, 7.8),
				Vector2(lado * 18.2, 5.4),
			]), 4)
			l.polilinea(arco_b, Color(piel_sombra.darkened(0.12), 0.11 + 0.24 * bolsas), 0.85 + 0.45 * bolsas)

	if surcos > 0.02:
		var col_s := Color(piel_sombra.darkened(0.12), 0.10 + 0.32 * surcos)
		for lado: float in [-1.0, 1.0]:
			var surco := suavizar_abierta(PackedVector2Array([
				Vector2(lado * 4.8, 11.2),
				Vector2(lado * 8.2, 14.6),
				Vector2(lado * (10.0 * jaw_w), 18.6),
			]), 4)
			l.polilinea(surco, col_s, 0.75 + 0.75 * surcos)

	if surcos > 0.55:
		var km := (surcos - 0.55) / 0.45
		var menton := suavizar_abierta(PackedVector2Array([
			Vector2(-4.0, 29.9), Vector2(0.0, 30.9), Vector2(4.0, 29.9),
		]), 3)
		l.polilinea(menton, Color(piel_sombra.darkened(0.10), 0.10 + 0.22 * km), 0.85 + 0.45 * km)

	if flacidez > 0.05:
		var papada := suavizar_abierta(PackedVector2Array([
			Vector2(-16.0 * jaw_w, 25.0),
			Vector2(-9.0 * jaw_w, 30.0),
			Vector2(0.0, 32.2),
			Vector2(9.0 * jaw_w, 30.0),
			Vector2(16.0 * jaw_w, 25.0),
		]), 4)
		l.polilinea(papada, Color(piel_sombra.darkened(0.10), 0.08 + 0.18 * flacidez), 1.0 + 0.7 * flacidez)

	if manchas > 0.03:
		var col_m := Color(piel_sombra.darkened(0.24), 0.07 + 0.20 * manchas)
		var radio := 1.25 + 0.45 * manchas
		for p: Vector2 in [
			Vector2(-17.5, 6.5), Vector2(-21.5, -1.5), Vector2(-11.0, 13.2),
			Vector2(18.0, 8.5), Vector2(21.8, 1.5), Vector2(12.5, 14.5),
		]:
			l.poligono(elipse_pts(p, radio, radio * 0.72, 10, 0.45), col_m)


static func _dibujar_boca(l: Lienzo_2D, ap: Dictionary, es_mujer: bool, forma_boca: String,
		color_labios: Color, piel_sombra: Color, grosor: float, e: String) -> void:
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

	var mostrar_labios: bool = es_mujer or (str(ap.get("color_labios", "natural")) != "natural") or (forma_boca == "gruesa")
	var col_labio_tint := Color(color_labios, 0.58 if es_mujer or str(ap.get("color_labios", "natural")) != "natural" else 0.35)

	match e:
		"sorpresa", "panico":
			var b_pts := suavizar_cerrado(PackedVector2Array([
				Vector2(-9.5 * w_scale, 18.8), Vector2(-5.2 * w_scale, 14.8), Vector2(5.2 * w_scale, 14.8),
				Vector2(9.5 * w_scale, 18.8), Vector2(8.0 * w_scale, 26.2), Vector2(0.0, 28.0), Vector2(-8.0 * w_scale, 26.2),
			]), 3)
			l.poligono_tinta(b_pts, Color("#45121d"), grosor * 0.78)
			l.poligono(PackedVector2Array([
				Vector2(-6.2 * w_scale, 16.0), Vector2(6.2 * w_scale, 16.0),
				Vector2(5.8 * w_scale, 18.6), Vector2(-5.8 * w_scale, 18.6),
			]), Color.WHITE)
			l.poligono(elipse_pts(Vector2(0.0, 24.8), 5.2 * w_scale, 2.5, 14), Color("#fb7185"))
		"dormido":
			var paz := suavizar_abierta(PackedVector2Array([
				Vector2(-5.6 * w_scale, 19.6), Vector2(0.0, 21.2), Vector2(5.6 * w_scale, 19.6),
			]), 3)
			l.polilinea(paz, Color(TINTA, 0.82), 1.85)
		"feliz", "feliz_cerrado", "reir":
			var mw := 11.4 * w_scale
			if mostrar_labios:
				var aura_l := suavizar_cerrado(PackedVector2Array([
					Vector2(-mw - 1.2, 16.0), Vector2(-3.0, 16.4 - lip_h), Vector2(0.0, 17.2), Vector2(3.0, 16.4 - lip_h), Vector2(mw + 1.2, 16.0),
					Vector2(8.8 * w_scale, 25.0 + lip_h), Vector2(0.0, 27.6 + lip_h * 1.2), Vector2(-8.8 * w_scale, 25.0 + lip_h),
				]), 4)
				l.poligono(aura_l, col_labio_tint)
			var b_pts := suavizar_cerrado(PackedVector2Array([
				Vector2(-mw, 16.6), Vector2(0.0, 18.2), Vector2(mw, 16.6),
				Vector2(8.6 * w_scale, 24.0), Vector2(0.0, 26.2), Vector2(-8.6 * w_scale, 24.0),
			]), 4)
			l.poligono_tinta(b_pts, Color("#45121d"), 1.85)
			var dientes := suavizar_cerrado(PackedVector2Array([
				Vector2(-mw * 0.84, 17.3), Vector2(0.0, 18.5), Vector2(mw * 0.84, 17.3),
				Vector2(mw * 0.74, 20.4), Vector2(0.0, 21.2), Vector2(-mw * 0.74, 20.4),
			]), 3)
			l.poligono(dientes, Color.WHITE)
			l.poligono(elipse_pts(Vector2(0.0, 23.8), 5.2 * w_scale, 2.0, 16), Color("#fb7185"))
			var labio_sup := suavizar_abierta(PackedVector2Array([
				Vector2(-mw * 1.06, 16.0), Vector2(0.0, 18.3), Vector2(mw * 1.06, 16.0),
			]), 5)
			l.polilinea(labio_sup, TINTA, 1.95)
			var menton := suavizar_abierta(PackedVector2Array([
				Vector2(-3.2, 29.5), Vector2(0.0, 30.2), Vector2(3.2, 29.5),
			]), 3)
			l.polilinea(menton, Color(piel_sombra, 0.65), 1.35)
		"concentrado", "neutral":
			var lw := 7.6 * w_scale
			if mostrar_labios:
				l.poligono(elipse_pts(Vector2(0.0, 20.4), lw * 0.68, 2.1 * lip_h, 14), col_labio_tint)
			var linea_b := suavizar_abierta(PackedVector2Array([
				Vector2(-lw, 19.4), Vector2(0.0, 20.0), Vector2(lw, 19.0),
			]), 4)
			l.polilinea(linea_b, TINTA, 2.0)
		_:
			var sw := 9.8 * w_scale
			if mostrar_labios:
				var lab_sup := suavizar_cerrado(PackedVector2Array([
					Vector2(-sw * 0.9, 18.2), Vector2(-2.6, 16.4 - lip_h * 0.8),
					Vector2(0.0, 17.2), Vector2(2.6, 16.4 - lip_h * 0.8), Vector2(sw * 0.9, 18.2),
					Vector2(0.0, 21.6),
				]), 3)
				l.poligono(lab_sup, col_labio_tint)
				l.poligono(elipse_pts(Vector2(0.0, 22.0 + lip_h * 0.4), sw * 0.56, 2.2 * lip_h, 14), col_labio_tint)
			var sonrisa := suavizar_abierta(PackedVector2Array([
				Vector2(-sw, 17.4), Vector2(-sw * 0.45, 20.8), Vector2(0.0, 21.6),
				Vector2(sw * 0.45, 20.8), Vector2(sw, 17.4),
			]), 4)
			l.polilinea(sonrisa, TINTA, 2.0)
			for lado_c: float in [-1.0, 1.0]:
				var com := Vector2(lado_c * sw, 17.3)
				l.linea(com + Vector2(-lado_c * 0.8, -0.9), com + Vector2(lado_c * 0.8, 0.8), Color(TINTA, 0.45), 1.2)
			var ment_s := suavizar_abierta(PackedVector2Array([
				Vector2(-3.0, 25.4), Vector2(0.0, 26.2), Vector2(3.0, 25.4),
			]), 3)
			l.polilinea(ment_s, Color(piel_sombra, 0.65), 1.35)


static func _dibujar_vello_facial(l: Lienzo_2D, jaw_w: float, tipo: String, pelo: Color, grosor: float) -> void:
	var col := pelo.darkened(0.16)
	match tipo:
		"sombra":
			var sombra_b := suavizar_cerrado(PackedVector2Array([
				Vector2(-26.5 * jaw_w, 8.0), Vector2(-23.0 * jaw_w, 20.5), Vector2(-13.5 * jaw_w, 31.2),
				Vector2(0.0, 35.0), Vector2(13.5 * jaw_w, 31.2), Vector2(23.0 * jaw_w, 20.5),
				Vector2(26.5 * jaw_w, 8.0), Vector2(21.5 * jaw_w, 13.5), Vector2(13.0 * jaw_w, 23.0),
				Vector2(0.0, 25.8), Vector2(-13.0 * jaw_w, 23.0), Vector2(-21.5 * jaw_w, 13.5),
			]), 3)
			l.poligono(sombra_b, Color(col, 0.28))
		"barba_corta":
			var barba := suavizar_cerrado(PackedVector2Array([
				Vector2(-27.0 * jaw_w, 9.0), Vector2(-23.6 * jaw_w, 21.0), Vector2(-14.0 * jaw_w, 32.0),
				Vector2(0.0, 36.2), Vector2(14.0 * jaw_w, 32.0), Vector2(23.6 * jaw_w, 21.0),
				Vector2(27.0 * jaw_w, 9.0), Vector2(22.0 * jaw_w, 14.5), Vector2(13.5 * jaw_w, 24.0),
				Vector2(0.0, 26.8), Vector2(-13.5 * jaw_w, 24.0), Vector2(-22.0 * jaw_w, 14.5),
			]), 3)
			l.poligono_tinta(barba, Color(col, 0.92), grosor * 0.56)
		"barba_completa":
			var barba_f := suavizar_cerrado(PackedVector2Array([
				Vector2(-27.8 * jaw_w, 6.0), Vector2(-26.0 * jaw_w, 23.0), Vector2(-16.0 * jaw_w, 37.0),
				Vector2(0.0, 44.5), Vector2(16.0 * jaw_w, 37.0), Vector2(26.0 * jaw_w, 23.0),
				Vector2(27.8 * jaw_w, 6.0), Vector2(21.5 * jaw_w, 13.0), Vector2(11.5, 16.5),
				Vector2(0.0, 15.2), Vector2(-11.5, 16.5), Vector2(-21.5 * jaw_w, 13.0),
			]), 3)
			l.poligono_tinta(barba_f, col, grosor * 0.68)
		"bigote":
			var big := suavizar_cerrado(PackedVector2Array([
				Vector2(-13.0, 16.2), Vector2(-5.5, 12.6), Vector2(0.0, 14.0),
				Vector2(5.5, 12.6), Vector2(13.0, 16.2), Vector2(7.8, 17.4),
				Vector2(0.0, 15.8), Vector2(-7.8, 17.4),
			]), 3)
			l.poligono_tinta(big, col, grosor * 0.58)
		"perilla":
			var per := suavizar_cerrado(PackedVector2Array([
				Vector2(-7.8, 26.2), Vector2(0.0, 27.8), Vector2(7.8, 26.2),
				Vector2(5.6, 34.8), Vector2(0.0, 37.0), Vector2(-5.6, 34.8),
			]), 3)
			l.poligono_tinta(per, col, grosor * 0.58)
		"candado":
			var big_c := suavizar_cerrado(PackedVector2Array([
				Vector2(-12.5, 16.0), Vector2(-5.2, 12.6), Vector2(0.0, 14.0),
				Vector2(5.2, 12.6), Vector2(12.5, 16.0), Vector2(7.8, 17.2),
				Vector2(0.0, 15.6), Vector2(-7.8, 17.2),
			]), 3)
			var per_c := suavizar_cerrado(PackedVector2Array([
				Vector2(-8.6, 26.5), Vector2(0.0, 28.0), Vector2(8.6, 26.5),
				Vector2(6.0, 35.0), Vector2(0.0, 37.2), Vector2(-6.0, 35.0),
			]), 3)
			l.poligono_tinta(big_c, col, grosor * 0.56)
			l.poligono_tinta(per_c, col, grosor * 0.56)
			for lado_k: float in [-1.0, 1.0]:
				var tira := PackedVector2Array([
					Vector2(lado_k * 10.0, 15.5), Vector2(lado_k * 12.8, 16.2),
					Vector2(lado_k * 9.8, 28.5), Vector2(lado_k * 6.8, 27.5),
				])
				l.poligono_tinta(tira, col, grosor * 0.50)


# ============================================================================
# 2. GENERADOR DE TEXTURA DEL TORSO Y VESTUARIO (FRENTE Y ESPALDA · 512x256)
# ============================================================================

const ANCHO_TEX_TORSO: int = 512
const ALTO_TEX_TORSO: int = 256
const ESC_TEX_TORSO: float = 2.65
const Y0_TORSO_2D: float = 40.0


static func uv_torso_frente(x_2d: float, y_2d: float) -> Vector2:
	return Vector2(
		clampf((128.0 + x_2d * ESC_TEX_TORSO) / float(ANCHO_TEX_TORSO), 0.01, 0.49),
		clampf(((y_2d - Y0_TORSO_2D) * ESC_TEX_TORSO) / float(ALTO_TEX_TORSO), 0.02, 0.98)
	)


static func uv_torso_espalda(x_2d: float, y_2d: float) -> Vector2:
	return Vector2(
		clampf((384.0 + x_2d * ESC_TEX_TORSO) / float(ANCHO_TEX_TORSO), 0.51, 0.99),
		clampf(((y_2d - Y0_TORSO_2D) * ESC_TEX_TORSO) / float(ALTO_TEX_TORSO), 0.02, 0.98)
	)


static func generar_textura_torso(ap: Dictionary, edad: int) -> ImageTexture:
	var rasgos_edad: Dictionary = Envejecimiento_Personaje.rasgos(edad)
	var es_mujer: bool = Apariencia_Personaje.es_mujer(ap)
	var met: Dictionary = metricas_cuerpo(es_mujer, ap)

	var piel_raw: Color = Envejecimiento_Personaje.color_piel(
		Apariencia_Personaje.color_de(ap, "color_piel", Color("#f8cfb4")),
		float(rasgos_edad.get("piel_apagada", 0.0)))
	var piel: Color = calibrar_color_3d(piel_raw, 0.12)
	var piel_som: Color = sombra_piel(piel)
	var ropa: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa", Color("#2563eb")), 0.08)
	var ropa_sec: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa_secundario", Color("#f8fafc")), 0.06)
	var ropa_det: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa_detalle", Color("#f8fafc")), 0.06)
	var ropa_sup := str(ap.get("ropa_superior", "sudadera"))
	var estilo_atuendo := str(ap.get("estilo_ropa", "base"))
	var detalle_atuendo := str(ap.get("detalle_ropa", ""))
	var grosor: float = 2.15

	var img := Image.create(ANCHO_TEX_TORSO, ALTO_TEX_TORSO, false, Image.FORMAT_RGBA8)
	var col_base_fondo: Color = piel if ropa_sup == "top" else ropa
	img.fill(col_base_fondo)

	var orig_frente := Vector2(128.0, -Y0_TORSO_2D * ESC_TEX_TORSO)
	var orig_espalda := Vector2(384.0, -Y0_TORSO_2D * ESC_TEX_TORSO)
	var l_frente := Lienzo_2D.new(img, orig_frente, ESC_TEX_TORSO, Rect2i(0, 0, 256, 256))
	var l_espalda := Lienzo_2D.new(img, orig_espalda, ESC_TEX_TORSO, Rect2i(256, 0, 256, 256))

	# 1. Frente del torso (idéntico a Personaje_Visual._dibujar_torso + _dibujar_atuendo_encima)
	_dibujar_torso_frente(l_frente, es_mujer, met, ropa_sup, ropa, piel, piel_som, grosor)
	if estilo_atuendo != "base":
		_dibujar_atuendo_frente(l_frente, es_mujer, met, estilo_atuendo, ropa, ropa_sec, ropa_det, grosor, ropa_sup, detalle_atuendo)

	# 2. Espalda del torso (misma paleta, costuras de tinta, cel-shading y detalles traseros del atuendo)
	_dibujar_torso_espalda(l_espalda, es_mujer, met, ropa_sup, estilo_atuendo, detalle_atuendo, ropa, ropa_sec, ropa_det, piel, piel_som, grosor)

	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _dibujar_torso_frente(l: Lienzo_2D, es_mujer: bool, met: Dictionary, ropa_sup: String,
		ropa: Color, piel: Color, piel_sombra: Color, grosor: float) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var nw: float = met["nw"]
	var ropa_sombra := ropa.darkened(0.22)
	var ropa_brillo := ropa.lightened(0.16)

	if ropa_sup == "top":
		l.rectangulo(Rect2(-48.0, 38.0, 96.0, 96.0), piel)
		_dibujar_claviculas(l, nw, piel, piel_sombra)
		var top_p := suavizar_cerrado(PackedVector2Array([
			Vector2(-18.5, 48.0), Vector2(-12.5, 47.0), Vector2(-10.5, 61.0),
			Vector2(0.0, 64.5), Vector2(10.5, 61.0), Vector2(12.5, 47.0),
			Vector2(18.5, 48.0), Vector2(waist_x + 4.0, 74.0), Vector2(waist_x + 4.0, 100.0),
			Vector2(hip_x + 6.0, 130.0), Vector2(-hip_x - 6.0, 130.0),
			Vector2(-waist_x - 4.0, 100.0), Vector2(-waist_x - 4.0, 74.0),
		]), 3)
		l.poligono_tinta(top_p, ropa, grosor * 0.90)
		l.linea(Vector2(waist_x - 3.0, 74.0), Vector2(hip_x - 4.0, 122.0), Color(ropa_sombra, 0.55), 3.0)
		return

	l.rectangulo(Rect2(-48.0, 38.0, 96.0, 96.0), ropa)

	# Cel-shading lateral derecho y brillo en hombro izquierdo
	var sombra_ctrl := PackedVector2Array([
		Vector2(13.0, 48.0),
		Vector2(sh_x + 4.0, 56.0),
		Vector2(sh_x + 4.0, 69.0),
		Vector2(waist_x + 4.0, 99.0),
		Vector2(hip_x + 4.0, 128.0),
		Vector2(10.0, 128.0),
		Vector2(15.0, 95.0),
		Vector2(16.0, 67.0),
	])
	l.poligono(suavizar_cerrado(sombra_ctrl, 3), Color(ropa_sombra, 0.65))
	l.linea(Vector2(-sh_x + 7.0, 56.0), Vector2(-17.0, 50.0), Color(ropa_brillo, 0.8), 2.8)

	match ropa_sup:
		"camiseta":
			var esc_c := suavizar_cerrado(PackedVector2Array([
				Vector2(-12.5, 44.5), Vector2(0.0, 56.5), Vector2(12.5, 44.5),
				Vector2(15.2, 49.0), Vector2(0.0, 62.0), Vector2(-15.2, 49.0),
			]), 3)
			l.poligono_tinta(esc_c, ropa_sombra, grosor * 0.65)
			var esc_piel := suavizar_cerrado(PackedVector2Array([
				Vector2(-12.0, 40.0), Vector2(12.0, 40.0), Vector2(11.0, 49.0),
				Vector2(0.0, 56.0), Vector2(-11.0, 49.0),
			]), 3)
			l.poligono(esc_piel, piel)
			_dibujar_claviculas(l, nw, piel, piel_sombra)
			var borde_esc := suavizar_abierta(PackedVector2Array([
				Vector2(-12.0, 44.5), Vector2(-7.0, 52.5), Vector2(0.0, 56.0),
				Vector2(7.0, 52.5), Vector2(12.0, 44.5),
			]), 4)
			l.polilinea(borde_esc, TINTA, grosor * 0.68)
			l.linea(Vector2(-hip_x - 4.0, 122.0), Vector2(hip_x + 4.0, 122.0), Color(ropa_sombra, 0.75), 2.2)

		"camisa":
			var v_piel := PackedVector2Array([
				Vector2(-10.0, 40.0), Vector2(10.0, 40.0), Vector2(0.0, 62.0),
			])
			l.poligono(v_piel, piel)
			_dibujar_claviculas(l, nw, piel, piel_sombra)
			var sol_l := PackedVector2Array([
				Vector2(-12.0, 42.5), Vector2(-20.0, 53.0), Vector2(-5.5, 62.0), Vector2(0.0, 56.0),
			])
			var sol_r := PackedVector2Array([
				Vector2(12.0, 42.5), Vector2(20.0, 53.0), Vector2(5.5, 62.0), Vector2(0.0, 56.0),
			])
			l.poligono_tinta(sol_l, ropa_brillo, grosor * 0.68)
			l.poligono_tinta(sol_r, ropa_brillo, grosor * 0.68)
			l.linea(Vector2(0.0, 58.0), Vector2(0.0, 128.0), Color(TINTA, 0.65), 1.6)
			for by: float in [69.0, 84.0, 99.0, 114.0]:
				l.circulo(Vector2(0.0, by), 2.1, ropa_sombra)
				l.arco(Vector2(0.0, by), 2.1, 0.0, TAU, 10, Color(TINTA, 0.7), 1.0)
			if not es_mujer:
				var bol := PackedVector2Array([Vector2(9.0, 68.0), Vector2(20.0, 68.0), Vector2(20.0, 80.0), Vector2(14.5, 83.0), Vector2(9.0, 80.0)])
				l.polilinea(bol, Color(TINTA, 0.55), 1.4)

		"chaqueta":
			var tee := PackedVector2Array([
				Vector2(-11.0, 42.0), Vector2(11.0, 42.0),
				Vector2(9.0, 129.0), Vector2(-9.0, 129.0),
			])
			l.poligono_tinta(tee, Color("#f8fafc"), grosor * 0.72)
			for lado: float in [-1.0, 1.0]:
				var sol_j := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 10.0, 43.5), Vector2(lado * 19.0, 48.0),
					Vector2(lado * 15.0, 66.0), Vector2(lado * 8.5, 62.0),
				]), 2)
				l.poligono_tinta(sol_j, ropa_sombra, grosor * 0.7)
				l.linea(Vector2(lado * 9.0, 62.0), Vector2(lado * 9.0, 126.0), Color("#cbd5e1"), 2.0)
				l.linea(Vector2(lado * 14.0, 94.0), Vector2(lado * (waist_x - 3.0), 108.0), Color(TINTA, 0.55), 1.6)
			var dob_j := PackedVector2Array([
				Vector2(-hip_x - 4.0, 120.5), Vector2(-9.0, 120.5), Vector2(-9.0, 128.0), Vector2(-hip_x - 4.0, 128.0),
			])
			var dob_jr := PackedVector2Array([
				Vector2(9.0, 120.5), Vector2(hip_x + 4.0, 120.5), Vector2(hip_x + 4.0, 128.0), Vector2(9.0, 128.0),
			])
			l.poligono_tinta(dob_j, ropa_sombra, grosor * 0.72)
			l.poligono_tinta(dob_jr, ropa_sombra, grosor * 0.72)

		"jersey":
			var cuello_j := suavizar_cerrado(PackedVector2Array([
				Vector2(-nw - 2.0, 40.0), Vector2(nw + 2.0, 40.0),
				Vector2(nw + 4.5, 53.0), Vector2(0.0, 56.0), Vector2(-nw - 4.5, 53.0),
			]), 3)
			l.poligono_tinta(cuello_j, ropa_sombra, grosor * 0.78)
			for rx_c: float in [-5.0, 0.0, 5.0]:
				l.linea(Vector2(rx_c, 42.0), Vector2(rx_c, 52.0), Color(TINTA, 0.30), 1.4)
			var dob_je := PackedVector2Array([
				Vector2(-hip_x - 4.0, 120.0), Vector2(hip_x + 4.0, 120.0),
				Vector2(hip_x + 4.0, 128.0), Vector2(-hip_x - 4.0, 128.0),
			])
			l.poligono_tinta(dob_je, ropa_sombra, grosor * 0.72)

		_:
			# "sudadera" canónica
			var escote := PackedVector2Array([
				Vector2(-11.5, 44.5), Vector2(0.0, 55.0), Vector2(11.5, 44.5),
				Vector2(14.5, 50.0), Vector2(0.0, 61.5), Vector2(-14.5, 50.0),
			])
			l.poligono_tinta(escote, Color.WHITE, grosor * 0.72)
			var cap_l := suavizar_cerrado(PackedVector2Array([
				Vector2(-12.0, 42.5), Vector2(-23.5, 48.5), Vector2(-17.0, 59.5), Vector2(-3.5, 61.5)
			]), 3)
			var cap_r := suavizar_cerrado(PackedVector2Array([
				Vector2(12.0, 42.5), Vector2(23.5, 48.5), Vector2(17.0, 59.5), Vector2(3.5, 61.5)
			]), 3)
			l.poligono_tinta(cap_l, ropa_sombra, grosor * 0.74)
			l.poligono_tinta(cap_r, ropa_sombra, grosor * 0.74)
			for lado: float in [-1.0, 1.0]:
				var x: float = lado * 7.6
				l.linea(Vector2(x, 59.5), Vector2(x + lado * 1.2, 83.0), TINTA, 3.8)
				l.linea(Vector2(x, 59.5), Vector2(x + lado * 1.2, 83.0), Color.WHITE, 2.0)
				l.circulo(Vector2(x + lado * 1.2, 84.2), 1.8, TINTA)
			var bol_c := PackedVector2Array([
				Vector2(-waist_x * 0.65, 102.0), Vector2(waist_x * 0.65, 102.0),
				Vector2(hip_x * 0.75, 118.0), Vector2(-hip_x * 0.75, 118.0),
			])
			l.poligono(bol_c, Color(ropa_sombra, 0.35))
			l.polilinea(PackedVector2Array([bol_c[3], bol_c[0], bol_c[1], bol_c[2]]), Color(TINTA, 0.55), 1.5)
			var dob := PackedVector2Array([
				Vector2(-hip_x - 4.0, 121.0), Vector2(hip_x + 4.0, 121.0),
				Vector2(hip_x + 4.0, 128.0), Vector2(-hip_x - 4.0, 128.0),
			])
			l.poligono_tinta(dob, ropa_sombra, grosor * 0.72)


static func _dibujar_claviculas(l: Lienzo_2D, nw: float, _piel: Color, piel_sombra: Color) -> void:
	l.linea(Vector2(-nw - 2.0, 50.0), Vector2(-3.5, 52.5), Color(piel_sombra, 0.75), 1.4)
	l.linea(Vector2(nw + 2.0, 50.0), Vector2(3.5, 52.5), Color(piel_sombra, 0.75), 1.4)


static func _dibujar_flor(l: Lienzo_2D, centro: Vector2, radio: float, petalo: Color, centro_col: Color) -> void:
	for i in range(5):
		var a := TAU * float(i) / 5.0
		l.circulo(centro + Vector2(cos(a), sin(a)) * radio * 0.8, radio * 0.55, petalo)
	l.circulo(centro, radio * 0.42, centro_col)


static func _dibujar_atuendo_frente(l: Lienzo_2D, _es_mujer: bool, met: Dictionary, estilo: String,
		ropa: Color, ropa_sec: Color, ropa_det: Color, grosor: float, _ropa_sup: String, detalle: String) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]
	var sombra := ropa.darkened(0.22)

	if estilo == "delantal":
		for lado: float in [-1.0, 1.0]:
			var tirante := suavizar_cerrado(PackedVector2Array([
				Vector2(lado * 8.0, 43.0), Vector2(lado * 13.5, 44.0),
				Vector2(lado * 12.0, 66.0), Vector2(lado * 6.5, 66.0),
			]), 2)
			l.poligono_tinta(tirante, ropa_sec, grosor * 0.66)
		var peto := suavizar_cerrado(PackedVector2Array([
			Vector2(-13.0, 64.0), Vector2(13.0, 64.0),
			Vector2(16.0, 119.0), Vector2(0.0, 123.0), Vector2(-16.0, 119.0),
		]), 3)
		l.poligono_tinta(peto, ropa_sec, grosor * 0.78)
		l.linea(Vector2(-waist_x - 3.0, 100.0), Vector2(waist_x + 3.0, 100.0), ropa_det, 2.6)
		var bolsillo := suavizar_cerrado(PackedVector2Array([
			Vector2(-8.0, 94.0), Vector2(8.0, 94.0), Vector2(8.0, 110.0),
			Vector2(0.0, 112.5), Vector2(-8.0, 110.0),
		]), 2)
		l.poligono(bolsillo, ropa_sec.darkened(0.05))
		l.polilinea(PackedVector2Array([
			Vector2(-8.0, 94.0), Vector2(8.0, 94.0), Vector2(8.0, 110.0),
			Vector2(0.0, 112.5), Vector2(-8.0, 110.0),
		]), Color(ropa_det, 0.85), 1.8, true)
		return

	match estilo:
		"casual":
			if detalle == "cuadros":
				for x: float in [-24.0, -18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0, 24.0]:
					l.linea(Vector2(x, 44.0), Vector2(x, 126.0), Color(ropa_sec, 0.62), 1.5)
				for y: float in [52.0, 64.0, 76.0, 88.0, 100.0, 112.0, 122.0]:
					l.linea(Vector2(-32.0, y), Vector2(32.0, y), Color(ropa_sec, 0.62), 1.5)
				l.linea(Vector2(0.0, 58.0), Vector2(0.0, 126.0), Color(ropa_det, 0.78), 1.7)
				for by: float in [70.0, 86.0, 102.0, 118.0]:
					l.circulo(Vector2(0.0, by), 1.8, ropa_det)
			elif detalle == "universidad":
				var escudo := suavizar_cerrado(PackedVector2Array([
					Vector2(-20.0, 68.0), Vector2(-10.0, 66.0), Vector2(-10.0, 82.0),
					Vector2(-15.0, 89.0), Vector2(-20.0, 82.0),
				]), 2)
				l.poligono_tinta(escudo, ropa_sec, grosor * 0.55)
				l.linea(Vector2(-18.0, 73.0), Vector2(-12.0, 73.0), ropa_det, 1.4)
				l.linea(Vector2(-17.0, 78.0), Vector2(-13.0, 78.0), ropa_det, 1.2)
				l.linea(Vector2(-waist_x - 3.0, 106.0), Vector2(waist_x + 3.0, 106.0), Color(ropa_sec, 0.82), 2.8)
			return

		"deportivo":
			l.linea(Vector2(0.0, 57.0), Vector2(0.0, 124.0), ropa_det, 2.4)
			for lado: float in [-1.0, 1.0]:
				var franja := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 9.0, 45.0), Vector2(lado * 16.0, 50.0),
					Vector2(lado * 9.0, 70.0), Vector2(lado * 3.5, 67.0),
				]), 2)
				l.poligono(franja, ropa_sec)
			var centro := Vector2(-15.0, 82.0)
			l.circulo(centro, 5.2, ropa_sec)
			l.arco(centro, 5.2, 0.0, TAU, 14, Color(TINTA, 0.55), 1.0)
			l.poligono(puntos_estrella(centro, 3.5, 1.5, 5), ropa_det)
			l.linea(Vector2(-hip_x - 3.0, 121.0), Vector2(hip_x + 3.0, 121.0), Color(ropa_sec, 0.65), 2.4)
			return

		"verano":
			l.linea(Vector2(-waist_x - 2.0, 98.0), Vector2(waist_x + 2.0, 98.0), ropa_det, 2.4)
			var franja := suavizar_cerrado(PackedVector2Array([
				Vector2(-16.0, 58.0), Vector2(-10.0, 57.0), Vector2(15.0, 92.0), Vector2(9.0, 95.0),
			]), 2)
			l.poligono(franja, Color(ropa_sec, 0.88))
			var sol := Vector2(13.0, 72.0)
			l.circulo(sol, 4.4, ropa_sec)
			for i in range(8):
				var a := TAU * float(i) / 8.0
				l.linea(sol + Vector2(cos(a), sin(a)) * 5.2, sol + Vector2(cos(a), sin(a)) * 7.4, Color(ropa_sec, 0.9), 1.2)
			l.circulo(sol, 2.1, ropa_det)
			return

		"invierno":
			if detalle == "abrigo":
				for lado: float in [-1.0, 1.0]:
					var panel := suavizar_cerrado(PackedVector2Array([
						Vector2(lado * 12.0, 43.5), Vector2(lado * (sh_x + 4.0), 53.0),
						Vector2(lado * (waist_x + 5.0), 100.0), Vector2(lado * (hip_x + 5.0), 130.0),
						Vector2(lado * 5.5, 130.0), Vector2(lado * 6.0, 102.0),
						Vector2(lado * 6.0, 58.0), Vector2(lado * 9.0, 46.0),
					]), 3)
					l.poligono_tinta(panel, ropa_sec, grosor * 0.82)
					var solapa := PackedVector2Array([
						Vector2(lado * 7.0, 44.0), Vector2(lado * 12.0, 43.5),
						Vector2(lado * 8.0, 64.0), Vector2(lado * 4.0, 58.0),
					])
					l.poligono_tinta(solapa, ropa_sec.lightened(0.14), grosor * 0.55)
				l.linea(Vector2(-waist_x - 4.0, 112.0), Vector2(waist_x + 4.0, 112.0), ropa_sec.darkened(0.32), 4.0)
				l.poligono(PackedVector2Array([
					Vector2(-4.0, 109.0), Vector2(4.0, 109.0), Vector2(4.0, 115.0), Vector2(-4.0, 115.0),
				]), ropa_det)
				for y: float in [72.0, 88.0, 104.0, 122.0]:
					for lado: float in [-1.0, 1.0]:
						l.circulo(Vector2(lado * 7.0, y), 2.0, ropa_det)
			var col_buf: Color = ropa_det if detalle == "abrigo" else ropa_sec
			var bufanda := suavizar_cerrado(PackedVector2Array([
				Vector2(-14.0, 42.5), Vector2(14.0, 42.5), Vector2(15.5, 51.0),
				Vector2(8.0, 57.0), Vector2(0.0, 54.0), Vector2(-8.0, 57.0), Vector2(-15.5, 51.0),
			]), 3)
			l.poligono_tinta(bufanda, col_buf, grosor * 0.62)
			var cola_1 := PackedVector2Array([
				Vector2(7.0, 51.0), Vector2(13.0, 50.0), Vector2(17.0, 82.0), Vector2(10.0, 84.0),
			])
			var cola_2 := PackedVector2Array([
				Vector2(-12.0, 50.0), Vector2(-5.0, 51.0), Vector2(-7.0, 76.0), Vector2(-14.0, 74.0),
			])
			l.poligono_tinta(cola_1, col_buf.darkened(0.06), grosor * 0.55)
			l.poligono_tinta(cola_2, col_buf.darkened(0.04), grosor * 0.55)
			if detalle != "abrigo":
				for x: float in [-12.0, -6.0, 0.0, 6.0, 12.0]:
					l.linea(Vector2(x, 64.0), Vector2(x, 118.0), Color(ropa.darkened(0.14), 0.5), 1.4)
			return

		"traje":
			var blazer := ropa_sec
			for lado: float in [-1.0, 1.0]:
				var panel := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 12.5, 43.5), Vector2(lado * (sh_x + 4.0), 53.0),
					Vector2(lado * (waist_x + 4.0), 100.0), Vector2(lado * (hip_x + 4.0), 129.0),
					Vector2(lado * 4.5, 129.0), Vector2(lado * 6.5, 102.0),
					Vector2(lado * 6.5, 60.0), Vector2(lado * 9.0, 46.0),
				]), 3)
				l.poligono_tinta(panel, blazer, grosor * 0.82)
				var solapa := PackedVector2Array([
					Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
					Vector2(lado * 8.0, 64.0), Vector2(lado * 4.0, 58.0),
				])
				l.poligono_tinta(solapa, blazer.lightened(0.14), grosor * 0.58)
				l.circulo(Vector2(lado * 6.2, 108.0), 1.9, ropa_det)
			l.poligono(PackedVector2Array([
				Vector2(-16.0, 78.0), Vector2(-12.0, 76.0), Vector2(-13.0, 82.0),
			]), ropa_det.lightened(0.2))
			if detalle == "pajarita":
				for lado: float in [-1.0, 1.0]:
					l.poligono(PackedVector2Array([
						Vector2(lado * 1.2, 53.0), Vector2(lado * 9.0, 49.5), Vector2(lado * 9.0, 56.5),
					]), ropa_det)
				l.circulo(Vector2(0.0, 53.0), 2.4, ropa_det.darkened(0.10))
			else:
				var corbata := suavizar_cerrado(PackedVector2Array([
					Vector2(-2.6, 49.0), Vector2(2.6, 49.0), Vector2(3.4, 91.0),
					Vector2(0.0, 98.0), Vector2(-3.4, 91.0),
				]), 2)
				l.poligono_tinta(corbata, ropa_det, grosor * 0.55)
			return

		"bata":
			var bata := ropa_sec
			for lado: float in [-1.0, 1.0]:
				var panel := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 12.0, 43.5), Vector2(lado * (sh_x + 4.0), 53.0),
					Vector2(lado * (waist_x + 4.0), 100.0), Vector2(lado * (hip_x + 4.0), 129.0),
					Vector2(lado * 5.0, 129.0), Vector2(lado * 6.5, 102.0),
					Vector2(lado * 6.5, 58.0), Vector2(lado * 9.0, 46.0),
				]), 3)
				l.poligono_tinta(panel, bata, grosor * 0.82)
				var solapa := PackedVector2Array([
					Vector2(lado * 6.5, 44.0), Vector2(lado * 12.0, 43.5),
					Vector2(lado * 7.0, 66.0), Vector2(lado * 3.5, 59.0),
				])
				l.poligono_tinta(solapa, bata.lightened(0.10), grosor * 0.55)
			for y: float in [74.0, 92.0, 110.0]:
				l.circulo(Vector2(0.0, y), 2.0, ropa_det)
			var insignia := suavizar_cerrado(PackedVector2Array([
				Vector2(-19.0, 76.0), Vector2(-11.0, 74.0), Vector2(-11.0, 88.0),
				Vector2(-15.0, 93.0), Vector2(-19.0, 88.0),
			]), 2)
			l.poligono_tinta(insignia, ropa_det, grosor * 0.5)
			l.circulo(Vector2(-15.0, 81.0), 2.4, Color.WHITE)
			l.linea(Vector2(-15.0, 78.0), Vector2(-15.0, 84.0), ropa_det, 1.4)
			l.linea(Vector2(-17.0, 81.0), Vector2(-13.0, 81.0), ropa_det, 1.4)
			return

		"mono":
			var peto := suavizar_cerrado(PackedVector2Array([
				Vector2(-13.0, 61.0), Vector2(13.0, 61.0), Vector2(17.0, 126.0),
				Vector2(0.0, 128.0), Vector2(-17.0, 126.0),
			]), 3)
			l.poligono_tinta(peto, ropa_sec, grosor * 0.82)
			for lado: float in [-1.0, 1.0]:
				var tirante := PackedVector2Array([
					Vector2(lado * 7.0, 43.0), Vector2(lado * 11.0, 44.0),
					Vector2(lado * 14.0, 64.0), Vector2(lado * 10.0, 65.0),
				])
				l.poligono_tinta(tirante, ropa_sec.darkened(0.08), grosor * 0.55)
				l.circulo(Vector2(lado * 12.0, 65.0), 2.2, ropa_det)
			var bolsillo := PackedVector2Array([
				Vector2(-8.0, 84.0), Vector2(8.0, 84.0), Vector2(8.0, 102.0),
				Vector2(0.0, 107.0), Vector2(-8.0, 102.0),
			])
			l.poligono(bolsillo, ropa_sec.darkened(0.06))
			l.polilinea(bolsillo, Color(ropa_det, 0.78), 1.4, true)
			return

		"camarero":
			for lado: float in [-1.0, 1.0]:
				var panel := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 11.0, 43.5), Vector2(lado * (sh_x + 3.0), 53.0),
					Vector2(lado * (waist_x + 3.0), 104.0), Vector2(lado * 4.0, 106.0),
					Vector2(lado * 5.5, 61.0), Vector2(lado * 8.0, 46.0),
				]), 3)
				l.poligono_tinta(panel, ropa_sec, grosor * 0.78)
			for y: float in [78.0, 90.0, 100.0]:
				l.circulo(Vector2(0.0, y), 1.9, ropa_sec.lightened(0.28))
			for lado: float in [-1.0, 1.0]:
				l.poligono(PackedVector2Array([
					Vector2(lado * 1.0, 53.0), Vector2(lado * 9.0, 49.5), Vector2(lado * 9.0, 56.5),
				]), ropa_det)
			l.circulo(Vector2(0.0, 53.0), 2.4, ropa_det.darkened(0.10))
			l.poligono_tinta(PackedVector2Array([
				Vector2(-18.0, 82.0), Vector2(-11.0, 80.0), Vector2(-10.0, 94.0), Vector2(-17.0, 96.0),
			]), Color("#f8fafc"), 1.1)
			return

		"pijama":
			l.linea(Vector2(0.0, 56.0), Vector2(0.0, 124.0), ropa_det, 2.2)
			for y: float in [68.0, 84.0, 100.0, 116.0]:
				l.circulo(Vector2(0.0, y), 1.9, ropa_det)
			l.polilinea(PackedVector2Array([
				Vector2(-11.0, 44.0), Vector2(0.0, 55.0), Vector2(11.0, 44.0),
			]), ropa_det, 1.8)
			for p: Vector2 in [
				Vector2(-15.0, 74.0), Vector2(13.0, 88.0), Vector2(-9.0, 108.0),
				Vector2(16.0, 111.0), Vector2(5.0, 72.0), Vector2(-4.0, 92.0),
			]:
				l.poligono(puntos_estrella(p, 4.2, 1.8, 5), ropa_sec)
			l.circulo(Vector2(-17.0, 94.0), 5.4, ropa_sec)
			l.circulo(Vector2(-15.0, 92.5), 4.5, ropa)
			return

		"fiesta":
			for lado: float in [-1.0, 1.0]:
				var panel := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 12.5, 43.5), Vector2(lado * (sh_x + 4.0), 53.0),
					Vector2(lado * (waist_x + 4.0), 100.0), Vector2(lado * (hip_x + 4.0), 128.0),
					Vector2(lado * 4.5, 129.0), Vector2(lado * 6.5, 102.0),
					Vector2(lado * 6.5, 60.0), Vector2(lado * 9.0, 46.0),
				]), 3)
				l.poligono_tinta(panel, ropa_sec, grosor * 0.82)
				var solapa := PackedVector2Array([
					Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
					Vector2(lado * 8.0, 66.0), Vector2(lado * 4.0, 59.0),
				])
				l.poligono_tinta(solapa, ropa_sec.lightened(0.18), grosor * 0.58)
				l.polilinea(PackedVector2Array([
					Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5), Vector2(lado * 10.0, 126.0),
				]), ropa_det, 2.0)
			l.poligono(PackedVector2Array([
				Vector2(10.0, 62.0), Vector2(4.0, 88.0), Vector2(9.0, 88.0),
				Vector2(2.0, 120.0), Vector2(4.0, 94.0), Vector2(-1.0, 94.0),
			]), ropa_det)
			for p: Vector2 in [
				Vector2(-16.0, 70.0), Vector2(-12.0, 78.0), Vector2(-18.0, 86.0),
				Vector2(-10.0, 96.0), Vector2(-16.0, 108.0), Vector2(16.0, 74.0),
				Vector2(18.0, 92.0), Vector2(14.0, 112.0),
			]:
				l.circulo(p, 1.8, Color.WHITE)
				l.circulo(p + Vector2(1.2, 1.2), 1.1, ropa_det)
			return

		"futbol":
			l.poligono_tinta(PackedVector2Array([
				Vector2(-10.0, 44.0), Vector2(10.0, 44.0), Vector2(0.0, 58.0),
			]), ropa_sec, grosor * 0.55)
			l.polilinea(PackedVector2Array([
				Vector2(-10.0, 44.0), Vector2(0.0, 58.0), Vector2(10.0, 44.0),
			]), ropa_det, 1.8)
			for lado: float in [-1.0, 1.0]:
				l.poligono(PackedVector2Array([
					Vector2(lado * 11.0, 45.0), Vector2(lado * 18.0, 49.0),
					Vector2(lado * 14.0, 64.0), Vector2(lado * 9.0, 61.0),
				]), ropa_sec)
			var centro := Vector2(-16.0, 80.0)
			var escudo := suavizar_cerrado(PackedVector2Array([
				Vector2(centro.x - 4.5, centro.y - 4.0), Vector2(centro.x + 4.5, centro.y - 4.0),
				Vector2(centro.x + 4.0, centro.y + 3.0), Vector2(centro.x, centro.y + 7.0),
				Vector2(centro.x - 4.0, centro.y + 3.0),
			]), 2)
			l.poligono_tinta(escudo, ropa_det, grosor * 0.5)
			l.poligono(puntos_estrella(centro + Vector2(0.0, 1.0), 2.8, 1.2, 5), ropa_sec)
			_dibujar_dorsal_10(l, Vector2(0.0, 95.0), 1.0, ropa_det)
			return

		"cuero":
			var cuero := ropa_sec
			for lado: float in [-1.0, 1.0]:
				var panel := suavizar_cerrado(PackedVector2Array([
					Vector2(lado * 12.5, 43.5), Vector2(lado * (sh_x + 4.0), 53.0),
					Vector2(lado * (waist_x + 4.0), 100.0), Vector2(lado * (hip_x + 4.0), 127.0),
					Vector2(lado * 4.5, 128.0), Vector2(lado * 6.5, 102.0),
					Vector2(lado * 6.5, 60.0), Vector2(lado * 9.0, 46.0),
				]), 3)
				l.poligono_tinta(panel, cuero, grosor * 0.82)
				var solapa := PackedVector2Array([
					Vector2(lado * 7.0, 44.0), Vector2(lado * 12.5, 43.5),
					Vector2(lado * 9.0, 66.0), Vector2(lado * 4.0, 59.0),
				])
				l.poligono_tinta(solapa, cuero.lightened(0.12), grosor * 0.58)
				l.linea(Vector2(lado * 9.0, 58.0), Vector2(lado * 15.0, 122.0), ropa_det, 1.8)
				for y: float in [56.0, 64.0, 72.0, 80.0]:
					l.circulo(Vector2(lado * 8.0, y), 1.4, ropa_det)
			l.linea(Vector2(-hip_x - 3.0, 124.0), Vector2(hip_x + 3.0, 124.0), cuero.darkened(0.35), 4.0)
			l.poligono(PackedVector2Array([
				Vector2(-4.0, 121.0), Vector2(4.0, 121.0), Vector2(4.0, 127.0), Vector2(-4.0, 127.0),
			]), ropa_det)
			return

		"astronauta":
			for lado: float in [-1.0, 1.0]:
				l.poligono(PackedVector2Array([
					Vector2(lado * 13.0, 47.0), Vector2(lado * (sh_x + 4.0), 54.0),
					Vector2(lado * (sh_x + 3.0), 61.0), Vector2(lado * 14.0, 55.0),
				]), ropa_sec)
			var pecho := suavizar_cerrado(PackedVector2Array([
				Vector2(-15.0, 64.0), Vector2(15.0, 64.0), Vector2(17.0, 112.0),
				Vector2(0.0, 120.0), Vector2(-17.0, 112.0),
			]), 4)
			l.poligono_tinta(pecho, ropa.lightened(0.04), grosor * 0.78)
			var panel := suavizar_cerrado(PackedVector2Array([
				Vector2(-10.0, 76.0), Vector2(10.0, 76.0), Vector2(10.0, 104.0),
				Vector2(0.0, 109.0), Vector2(-10.0, 104.0),
			]), 2)
			l.poligono_tinta(panel, ropa_det, grosor * 0.55)
			for y: float in [82.0, 90.0, 98.0]:
				for x: float in [-6.0, 0.0, 6.0]:
					l.circulo(Vector2(x, y), 1.8, ropa_sec if int(y) % 16 == 0 else Color.WHITE)
			var anillo := suavizar_cerrado(PackedVector2Array([
				Vector2(-12.0, 47.0), Vector2(12.0, 47.0), Vector2(13.0, 54.0),
				Vector2(0.0, 58.0), Vector2(-13.0, 54.0),
			]), 3)
			l.poligono_tinta(anillo, ropa_det, grosor * 0.58)
			var parche := Vector2(-16.0, 68.0)
			l.circulo(parche, 4.4, ropa_det)
			l.poligono(puntos_estrella(parche, 3.0, 1.3, 5), Color.WHITE)
			return

		"vestido":
			var es_largo := (detalle == "largo")
			var col_cint: Color = ropa_det if detalle != "" else Color("#16a34a")
			l.linea(Vector2(-waist_x - 3.0, 99.0), Vector2(waist_x + 3.0, 99.0), col_cint, 3.2)
			l.circulo(Vector2(0.0, 99.0), 2.8, col_cint)
			for lado: float in [-1.0, 1.0]:
				l.linea(Vector2(lado * 2.0, 100.0), Vector2(lado * 8.0, 108.0), col_cint, 1.8)
			l.polilinea(PackedVector2Array([
				Vector2(-10.0, 45.0), Vector2(0.0, 55.0), Vector2(10.0, 45.0),
			]), col_cint, 1.8)
			if not es_largo:
				for p: Vector2 in [
					Vector2(-13.0, 74.0), Vector2(11.0, 82.0), Vector2(-9.0, 112.0), Vector2(11.0, 116.0),
				]:
					_dibujar_flor(l, p, 3.6, ropa_sec, col_cint)
			else:
				for p: Vector2 in [
					Vector2(-13.0, 74.0), Vector2(11.0, 84.0), Vector2(-8.0, 114.0), Vector2(12.0, 118.0),
				]:
					l.circulo(p, 1.8, ropa_sec)
			return

	# Chaquetas de chef, gala y Michelin
	l.rectangulo(Rect2(-48.0, 42.0, 96.0, 88.0), ropa)
	l.poligono(suavizar_cerrado(PackedVector2Array([
		Vector2(11.0, 48.0), Vector2(sh_x + 3.0, 56.0), Vector2(waist_x + 3.0, 99.0),
		Vector2(hip_x + 3.0, 127.0), Vector2(9.0, 127.0), Vector2(13.0, 96.0), Vector2(14.0, 67.0),
	]), 3), Color(sombra, 0.55))

	var es_gala := (estilo == "gala")
	var es_michelin := (estilo == "michelin")
	var es_chef := (estilo == "chef")

	if es_chef:
		var panuelo := PackedVector2Array([Vector2(-7.0, 45.0), Vector2(7.0, 45.0), Vector2(0.0, 59.0)])
		l.poligono_tinta(panuelo, ropa_sec, grosor * 0.55)
		l.circulo(Vector2(0.0, 55.5), 2.8, ropa_sec.darkened(0.16))
	elif es_gala:
		var ascot := suavizar_cerrado(PackedVector2Array([
			Vector2(-7.5, 44.0), Vector2(7.5, 44.0), Vector2(4.0, 58.0), Vector2(0.0, 63.0), Vector2(-4.0, 58.0),
		]), 2)
		l.poligono_tinta(ascot, ropa_sec, grosor * 0.55)
		l.circulo(Vector2(0.0, 55.0), 2.2, ropa_det)
	else:
		l.poligono(PackedVector2Array([Vector2(-8.5, 44.0), Vector2(8.5, 44.0), Vector2(0.0, 63.0)]), ropa_sec)
		for lado: float in [-1.0, 1.0]:
			l.poligono(PackedVector2Array([
				Vector2(lado * 1.2, 53.0), Vector2(lado * 9.0, 49.5), Vector2(lado * 9.0, 55.5),
			]), ropa_det)
		l.circulo(Vector2(0.0, 52.8), 2.4, ropa_det.darkened(0.10))

	var ys_botones := [72.0, 86.0, 100.0, 114.0] if es_chef else [72.0, 90.0, 108.0]
	for y in ys_botones:
		for lado: float in [-1.0, 1.0]:
			l.circulo(Vector2(lado * 5.4, y), 2.3, ropa_det)
			l.arco(Vector2(lado * 5.4, y), 2.3, 0.0, TAU, 10, Color(TINTA, 0.62), 1.0)

	if es_gala or es_michelin:
		l.polilinea(PackedVector2Array([Vector2(-7.0, 44.0), Vector2(0.0, 58.0), Vector2(7.0, 44.0)]), ropa_det, 2.0)
		for lado: float in [-1.0, 1.0]:
			l.linea(Vector2(lado * 10.5, 62.0), Vector2(lado * (waist_x - 3.0), 99.0), Color(ropa_det, 0.8), 1.6)
		l.linea(Vector2(-hip_x - 3.0, 123.0), Vector2(hip_x + 3.0, 123.0), Color(ropa_det, 0.85), 2.2)

	if es_michelin:
		var fajin := PackedVector2Array([
			Vector2(-hip_x - 2.0, 113.0), Vector2(hip_x + 2.0, 113.0),
			Vector2(hip_x + 2.0, 120.0), Vector2(-hip_x - 2.0, 120.0),
		])
		l.poligono(fajin, Color(ropa_det, 0.92))
		var estrella := puntos_estrella(Vector2(-15.0, 82.0), 8.5, 3.7, 5)
		l.poligono_tinta(estrella, ropa_det, 1.2)
		l.circulo(Vector2(-15.0, 82.0), 1.6, Color.WHITE)


static func _dibujar_torso_espalda(l: Lienzo_2D, _es_mujer: bool, met: Dictionary, ropa_sup: String,
		estilo: String, detalle: String, ropa: Color, ropa_sec: Color, ropa_det: Color,
		piel: Color, piel_sombra: Color, grosor: float) -> void:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]

	var col_espalda: Color = ropa
	if estilo in ["traje", "bata", "cuero", "fiesta", "camarero"]:
		col_espalda = ropa_sec
	elif estilo == "invierno" and detalle == "abrigo":
		col_espalda = ropa_sec
	var sombra := col_espalda.darkened(0.22)
	var brillo := col_espalda.lightened(0.15)

	if ropa_sup == "top" and estilo in ["base", "verano", "vestido"]:
		l.rectangulo(Rect2(-48.0, 38.0, 96.0, 96.0), piel)
		l.linea(Vector2(0.0, 46.0), Vector2(0.0, 62.0), Color(piel_sombra, 0.45), 1.6)
		var top_b := suavizar_cerrado(PackedVector2Array([
			Vector2(-17.0, 48.0), Vector2(-11.0, 47.0), Vector2(-8.0, 62.0),
			Vector2(8.0, 62.0), Vector2(11.0, 47.0), Vector2(17.0, 48.0),
			Vector2(waist_x + 4.0, 74.0), Vector2(hip_x + 6.0, 129.0),
			Vector2(-hip_x - 6.0, 129.0), Vector2(-waist_x - 4.0, 74.0),
		]), 3)
		l.poligono_tinta(top_b, ropa, grosor * 0.88)
		if estilo == "verano":
			var franja_v := suavizar_cerrado(PackedVector2Array([
				Vector2(15.0, 58.0), Vector2(9.0, 57.0), Vector2(-15.0, 92.0), Vector2(-9.0, 95.0),
			]), 2)
			l.poligono(franja_v, Color(ropa_sec, 0.88))
			l.linea(Vector2(-waist_x - 2.0, 98.0), Vector2(waist_x + 2.0, 98.0), ropa_det, 2.4)
		elif estilo == "vestido":
			var col_cint: Color = ropa_det if detalle != "" else Color("#16a34a")
			l.linea(Vector2(-waist_x - 3.0, 99.0), Vector2(waist_x + 3.0, 99.0), col_cint, 3.2)
			if detalle != "largo":
				for p: Vector2 in [Vector2(-12.0, 78.0), Vector2(12.0, 84.0), Vector2(0.0, 112.0)]:
					_dibujar_flor(l, p, 3.6, ropa_sec, col_cint)
		return

	l.rectangulo(Rect2(-48.0, 38.0, 96.0, 96.0), col_espalda)

	# Cel-shading y pliegues naturales de espalda
	var som_b := suavizar_cerrado(PackedVector2Array([
		Vector2(12.0, 46.0), Vector2(sh_x + 4.0, 54.0), Vector2(waist_x + 4.0, 99.0),
		Vector2(hip_x + 4.0, 128.0), Vector2(9.0, 128.0), Vector2(14.0, 94.0), Vector2(15.0, 65.0),
	]), 3)
	l.poligono(som_b, Color(sombra, 0.58))
	l.linea(Vector2(-sh_x + 6.0, 54.0), Vector2(-15.0, 48.0), Color(brillo, 0.75), 2.6)

	# Capucha trasera dibujada en la espalda de la sudadera / deportivo
	if ropa_sup == "sudadera" or estilo == "deportivo":
		var cap_espalda := suavizar_cerrado(PackedVector2Array([
			Vector2(-21.0, 43.0), Vector2(21.0, 43.0),
			Vector2(18.0, 58.0), Vector2(0.0, 63.5), Vector2(-18.0, 58.0),
		]), 3)
		l.poligono_tinta(cap_espalda, sombra, grosor * 0.78)
		l.polilinea(suavizar_abierta(PackedVector2Array([
			Vector2(-13.0, 48.0), Vector2(0.0, 54.5), Vector2(13.0, 48.0),
		]), 3), Color(TINTA, 0.55), 1.4)

	# Dobladillo inferior con tinta
	var dob := PackedVector2Array([
		Vector2(-hip_x - 4.0, 121.0), Vector2(hip_x + 4.0, 121.0),
		Vector2(hip_x + 4.0, 128.0), Vector2(-hip_x - 4.0, 128.0),
	])
	l.poligono_tinta(dob, sombra, grosor * 0.72)

	# Pliegue vertical sutil de espalda
	l.linea(Vector2(0.0, 66.0), Vector2(0.0, 116.0), Color(sombra, 0.45), 1.6)

	# Detalles traseros específicos de cada estilo
	match estilo:
		"casual":
			if detalle == "cuadros":
				for x: float in [-24.0, -18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0, 24.0]:
					l.linea(Vector2(x, 44.0), Vector2(x, 126.0), Color(ropa_sec, 0.62), 1.5)
				for y: float in [52.0, 64.0, 76.0, 88.0, 100.0, 112.0, 122.0]:
					l.linea(Vector2(-32.0, y), Vector2(32.0, y), Color(ropa_sec, 0.62), 1.5)
				l.linea(Vector2(-sh_x, 62.0), Vector2(sh_x, 62.0), Color(TINTA, 0.55), 1.6)
			elif detalle == "universidad":
				l.linea(Vector2(-waist_x - 3.0, 106.0), Vector2(waist_x + 3.0, 106.0), Color(ropa_sec, 0.82), 2.8)
		"deportivo":
			l.linea(Vector2(-sh_x, 68.0), Vector2(sh_x, 68.0), ropa_sec, 3.4)
			l.linea(Vector2(-sh_x, 74.0), Vector2(sh_x, 74.0), ropa_det, 2.2)
			l.linea(Vector2(-hip_x - 3.0, 121.0), Vector2(hip_x + 3.0, 121.0), Color(ropa_sec, 0.65), 2.4)
		"futbol":
			for lado: float in [-1.0, 1.0]:
				l.poligono(PackedVector2Array([
					Vector2(lado * 11.0, 45.0), Vector2(lado * 22.0, 49.0),
					Vector2(lado * 18.0, 62.0), Vector2(lado * 9.0, 58.0),
				]), ropa_sec)
			_dibujar_dorsal_10(l, Vector2(0.0, 84.0), 1.45, ropa_det)
			l.linea(Vector2(-waist_x - 2.0, 118.0), Vector2(waist_x + 2.0, 118.0), Color(ropa_det, 0.7), 2.0)
		"delantal":
			for lado: float in [-1.0, 1.0]:
				l.linea(Vector2(lado * 9.0, 44.0), Vector2(lado * 12.0, 62.0), ropa_sec, 3.6)
			l.linea(Vector2(-waist_x - 3.0, 100.0), Vector2(waist_x + 3.0, 100.0), ropa_det, 3.0)
			l.circulo(Vector2(0.0, 101.0), 3.2, ropa_det)
			l.linea(Vector2(0.0, 101.0), Vector2(-7.0, 114.0), ropa_det, 2.2)
			l.linea(Vector2(0.0, 101.0), Vector2(7.0, 114.0), ropa_det, 2.2)
		"mono":
			for lado: float in [-1.0, 1.0]:
				l.linea(Vector2(lado * 9.0, 44.0), Vector2(-lado * 11.0, 96.0), ropa_sec, 5.0)
				l.linea(Vector2(lado * 9.0, 44.0), Vector2(-lado * 11.0, 96.0), TINTA, 1.4)
			var faja_m := PackedVector2Array([
				Vector2(-waist_x - 4.0, 94.0), Vector2(waist_x + 4.0, 94.0),
				Vector2(hip_x + 4.0, 128.0), Vector2(-hip_x - 4.0, 128.0),
			])
			l.poligono_tinta(faja_m, ropa_sec, grosor * 0.75)
		"pijama":
			for p: Vector2 in [
				Vector2(-14.0, 68.0), Vector2(14.0, 76.0), Vector2(0.0, 92.0),
				Vector2(-12.0, 108.0), Vector2(13.0, 110.0),
			]:
				l.poligono(puntos_estrella(p, 4.4, 1.9, 5), ropa_sec)
		"fiesta":
			l.poligono(PackedVector2Array([
				Vector2(4.0, 60.0), Vector2(-3.0, 86.0), Vector2(3.0, 86.0),
				Vector2(-4.0, 116.0), Vector2(0.0, 92.0), Vector2(-6.0, 92.0),
			]), ropa_det)
			for p: Vector2 in [
				Vector2(-15.0, 68.0), Vector2(15.0, 72.0), Vector2(-14.0, 98.0), Vector2(14.0, 102.0),
			]:
				l.circulo(p, 1.8, Color.WHITE)
				l.circulo(p + Vector2(1.2, 1.2), 1.1, ropa_det)
		"gala", "michelin":
			l.linea(Vector2(-hip_x - 3.0, 122.0), Vector2(hip_x + 3.0, 122.0), ropa_det, 2.2)
			if estilo == "michelin":
				l.rectangulo(Rect2(-hip_x - 2.0, 113.0, (hip_x + 2.0) * 2.0, 7.0), ropa_det)
		"invierno":
			if detalle == "abrigo":
				l.linea(Vector2(-waist_x - 4.0, 112.0), Vector2(waist_x + 4.0, 112.0), ropa_sec.darkened(0.32), 4.2)
			else:
				for x: float in [-12.0, -6.0, 0.0, 6.0, 12.0]:
					l.linea(Vector2(x, 60.0), Vector2(x, 118.0), Color(ropa.darkened(0.14), 0.5), 1.4)
		"cuero":
			l.linea(Vector2(-sh_x, 64.0), Vector2(0.0, 70.0), ropa_det, 1.8)
			l.linea(Vector2(0.0, 70.0), Vector2(sh_x, 64.0), ropa_det, 1.8)
			l.linea(Vector2(-hip_x - 3.0, 124.0), Vector2(hip_x + 3.0, 124.0), col_espalda.darkened(0.35), 4.0)


static func _dibujar_dorsal_10(l: Lienzo_2D, centro: Vector2, esc: float, col: Color) -> void:
	var x1: float = centro.x - 6.5 * esc
	var y0: float = centro.y - 9.0 * esc
	var y1: float = centro.y + 9.0 * esc
	l.linea(Vector2(x1 - 2.5 * esc, y0 + 3.0 * esc), Vector2(x1, y0), TINTA, 4.2 * esc)
	l.linea(Vector2(x1, y0), Vector2(x1, y1), TINTA, 4.6 * esc)
	l.linea(Vector2(x1 - 2.5 * esc, y0 + 3.0 * esc), Vector2(x1, y0), col, 2.4 * esc)
	l.linea(Vector2(x1, y0), Vector2(x1, y1), col, 2.8 * esc)
	var c0 := Vector2(centro.x + 5.0 * esc, centro.y)
	var aro_ext := elipse_pts(c0, 5.5 * esc, 9.0 * esc, 16)
	l.polilinea(aro_ext, TINTA, 4.4 * esc, true)
	l.polilinea(aro_ext, col, 2.6 * esc, true)


# ============================================================================
# 3. GENERADOR DE TEXTURA PARA FALDA Y VESTIDOS (256x256)
# ============================================================================

static func generar_textura_falda(ap: Dictionary) -> ImageTexture:
	var estilo := str(ap.get("estilo_ropa", "base"))
	var detalle := str(ap.get("detalle_ropa", ""))
	var ropa: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa", Color("#f472b6")), 0.08)
	var ropa_sec: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa_secundario", Color("#fef3c7")), 0.06)
	var ropa_det: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa_detalle", Color("#16a34a")), 0.06)
	var pant: Color = calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_pantalon", Color("#1e293b")), 0.08)

	var col_base: Color = ropa if estilo == "vestido" else pant
	var sombra: Color = col_base.darkened(0.22)
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(col_base)

	var l := Lienzo_2D.new(img, Vector2(128.0, 0.0), 2.56)

	# Sombra lateral cel-shading y pliegues de falda
	l.rectangulo(Rect2(14.0, 0.0, 36.0, 100.0), Color(sombra, 0.45))
	for px_f: float in [-24.0, -8.0, 8.0, 24.0]:
		l.linea(Vector2(px_f * 0.7, 6.0), Vector2(px_f, 94.0), Color(sombra, 0.62), 1.5)

	if estilo == "vestido":
		var es_largo := (detalle == "largo")
		var col_cint: Color = ropa_det if detalle != "" else Color("#16a34a")
		l.linea(Vector2(-50.0, 3.0), Vector2(50.0, 3.0), col_cint, 3.5)
		if not es_largo:
			for p: Vector2 in [
				Vector2(-26.0, 24.0), Vector2(4.0, 20.0), Vector2(28.0, 30.0),
				Vector2(-16.0, 52.0), Vector2(16.0, 56.0), Vector2(-30.0, 74.0),
				Vector2(0.0, 76.0), Vector2(26.0, 78.0),
			]:
				_dibujar_flor(l, p, 4.2, ropa_sec, col_cint)
		else:
			for p: Vector2 in [
				Vector2(-24.0, 22.0), Vector2(8.0, 26.0), Vector2(28.0, 34.0),
				Vector2(-14.0, 50.0), Vector2(18.0, 56.0), Vector2(-26.0, 74.0),
				Vector2(4.0, 78.0), Vector2(24.0, 82.0),
			]:
				l.circulo(p, 2.0, ropa_sec)
			l.linea(Vector2(-50.0, 92.0), Vector2(50.0, 92.0), ropa_sec, 3.2)

	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
