class_name Visual_Bienestar
extends RefCounted

# ============================================================================
# Piezas visuales dibujadas a mano para la pestaña Tienda > Bienestar.
#
# No dependen de texturas externas: el degradado del héroe de la clínica, el
# medidor de edad, el fondo de las creatividades publicitarias y el confeti se
# pintan en _draw(), así que escalan sin pérdida y comparten la paleta del
# juego. Son deliberadamente ligeras: solo se redibujan si están visibles.
# ============================================================================

const TEAL := Color("#14b8a6")
const TEAL_CLARO := Color("#5eead4")
const AMBAR := Color("#f59e0b")
const CORAL := Color("#f43f5e")
const INDIGO := Color("#818cf8")


class Fondo_Heroe_Clinica extends Control:
	"""Degradado verde profundo con brillos dorados y un barrido de luz lento."""

	var radio: float = 22.0
	var _tiempo: float = 0.0
	var _fase: float = 0.0
	var _acumulador: float = 0.0
	var _estilo_borde: StyleBoxFlat

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_estilo_borde = StyleBoxFlat.new()
		_estilo_borde.bg_color = Color(0, 0, 0, 0)
		_estilo_borde.set_corner_radius_all(int(radio))
		_estilo_borde.set_border_width_all(1)
		_estilo_borde.border_color = Color(1.0, 1.0, 1.0, 0.08)
		_estilo_borde.anti_aliasing = true
		set_process(true)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_tiempo += delta
		_acumulador += delta
		if _acumulador < 0.05:
			return
		_acumulador = 0.0
		_fase = fmod(_tiempo, 7.5)
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 2.0 or s.y < 2.0:
			return
		_Dibujar_Degradado_Redondeado(s)

		# Resplandores suaves, lejos de las esquinas para no romper el radio.
		var centro_teal := Vector2(s.x * 0.80, s.y * 0.18)
		for i in range(7):
			var r := 34.0 + float(i) * 13.0
			draw_circle(centro_teal, r, Color(TEAL_CLARO, 0.012 + float(i) * 0.0025))
		var centro_oro := Vector2(s.x * 0.14, s.y * 0.88)
		for i in range(5):
			var r := 30.0 + float(i) * 15.0
			draw_circle(centro_oro, r, Color("#fbbf24", 0.008 + float(i) * 0.0015))

		# Rayas diagonales dentro del área segura.
		var margen := 14.0
		var paso := 82.0
		var ancho := 22.0
		var sesgo := s.y * 0.42
		var x := -sesgo - margen
		while x < s.x + paso:
			var pts := PackedVector2Array([
				Vector2(maxf(margen, x), s.y - margen),
				Vector2(maxf(margen, x + ancho), s.y - margen),
				Vector2(maxf(margen, x + ancho + sesgo), margen),
				Vector2(maxf(margen, x + sesgo), margen),
			])
			draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, 0.018))
			x += paso

		# Puntos de textura sutiles en la zona segura.
		for i in range(26):
			var px := _Hash(i * 17.0) * maxf(1.0, s.x - margen * 2.0) + margen
			var py := _Hash(i * 31.0 + 4.0) * maxf(1.0, s.y - margen * 2.0) + margen
			var a := 0.03 + _Hash(i * 7.0) * 0.05
			draw_circle(Vector2(px, py), 1.1, Color(1.0, 1.0, 1.0, a))

		# Barrido de luz que cruza el héroe cada 7,5 s.
		var avance := _fase / 7.5
		var x_brillo := lerpf(-s.x * 0.6, s.x * 1.6, avance)
		var ancho_brillo := 90.0
		var pts_brillo := PackedVector2Array([
			Vector2(x_brillo + margen, margen),
			Vector2(x_brillo + ancho_brillo + margen, margen),
			Vector2(x_brillo + ancho_brillo - s.y * 0.3 + margen, s.y - margen),
			Vector2(x_brillo - s.y * 0.3 + margen, s.y - margen),
		])
		draw_colored_polygon(pts_brillo, Color(1.0, 1.0, 1.0, 0.022))

		# Borde interior muy fino.
		if _estilo_borde != null:
			draw_style_box(_estilo_borde, Rect2(Vector2.ZERO, s))

	func _Dibujar_Degradado_Redondeado(s: Vector2) -> void:
		var arriba := Color("#113b38")
		var medio := Color("#0c2528")
		var abajo := Color("#09131f")
		var alto := int(ceil(s.y))
		for y in range(alto):
			var t := float(y) / maxf(1.0, s.y - 1.0)
			var color := arriba.lerp(medio, t / 0.55) if t < 0.55 else medio.lerp(abajo, (t - 0.55) / 0.45)
			var inset := _Inset_Radio(y, s, radio)
			draw_rect(Rect2(inset, float(y), s.x - inset * 2.0, 1.0), color)

	func _Inset_Radio(y: float, s: Vector2, r: float) -> float:
		var dy := 0.0
		if y < r:
			dy = r - y
		elif y > s.y - r:
			dy = y - (s.y - r)
		if dy <= 0.0:
			return 0.0
		var raiz := sqrt(maxf(0.0, r * r - dy * dy))
		return r - raiz

	func _Hash(n: float) -> float:
		return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)


class Fondo_Creativo extends Control:
	"""Fondo de la creatividad de anuncio, con degradado y diagonales."""

	var color_a: Color = Color("#f59e0b")
	var color_b: Color = Color("#dc2626")
	var radio: float = 24.0
	var _tiempo: float = 0.0
	var _estilo_borde: StyleBoxFlat

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_estilo_borde = StyleBoxFlat.new()
		_estilo_borde.bg_color = Color(0, 0, 0, 0)
		_estilo_borde.set_corner_radius_all(int(radio))
		_estilo_borde.set_border_width_all(1)
		_estilo_borde.border_color = Color(1.0, 1.0, 1.0, 0.16)
		_estilo_borde.anti_aliasing = true
		set_process(true)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_tiempo += delta
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 2.0 or s.y < 2.0:
			return
		var alto := int(ceil(s.y))
		for y in range(alto):
			var t := float(y) / maxf(1.0, s.y - 1.0)
			var color := color_a.lerp(color_b, smoothstep(0.0, 1.0, t))
			var inset := _Inset_Radio(y, s, radio)
			draw_rect(Rect2(inset, float(y), s.x - inset * 2.0, 1.0), color)

		# Círculo de luz detrás del producto.
		for i in range(6):
			draw_circle(Vector2(s.x * 0.78, s.y * 0.46), 70.0 + float(i) * 22.0,
				Color(1.0, 1.0, 1.0, 0.018))

		# Franjas diagonales amplias.
		var margen := 10.0
		var paso := 118.0
		var ancho := 40.0
		var sesgo := s.y * 0.5
		var x := -sesgo - margen
		while x < s.x + paso:
			var pts := PackedVector2Array([
				Vector2(maxf(margen, x), s.y - margen),
				Vector2(maxf(margen, x + ancho), s.y - margen),
				Vector2(maxf(margen, x + ancho + sesgo), margen),
				Vector2(maxf(margen, x + sesgo), margen),
			])
			draw_colored_polygon(pts, Color(1.0, 1.0, 1.0, 0.045))
			x += paso

		# Brillo superior.
		draw_rect(Rect2(margen, margen, s.x - margen * 2.0, minf(52.0, s.y * 0.2)),
			Color(1.0, 1.0, 1.0, 0.045))

		if _estilo_borde != null:
			draw_style_box(_estilo_borde, Rect2(Vector2.ZERO, s))

	func _Inset_Radio(y: float, s: Vector2, r: float) -> float:
		var dy := 0.0
		if y < r:
			dy = r - y
		elif y > s.y - r:
			dy = y - (s.y - r)
		if dy <= 0.0:
			return 0.0
		return r - sqrt(maxf(0.0, r * r - dy * dy))


class Fondo_Tarjeta_VIP extends Control:
	"""Fondo oscuro sereno con gradiente sutil para la tarjeta destacada VIP."""

	var radio: float = 18.0
	var _estilo_borde: StyleBoxFlat

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_estilo_borde = StyleBoxFlat.new()
		_estilo_borde.bg_color = Color(0, 0, 0, 0)
		_estilo_borde.set_corner_radius_all(int(radio))
		_estilo_borde.set_border_width_all(1)
		_estilo_borde.border_color = Color(1.0, 1.0, 1.0, 0.10)
		_estilo_borde.anti_aliasing = true
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 2.0 or s.y < 2.0:
			return
		var centro_oro := Vector2(s.x * 0.84, s.y * 0.38)
		var max_r := minf(s.x - centro_oro.x, centro_oro.y) - 6.0
		if max_r > 12.0:
			for i in range(4):
				var r := minf(max_r, 18.0 + float(i) * 10.0)
				draw_circle(centro_oro, r, Color("#f59e0b", 0.022))
		if _estilo_borde != null:
			draw_style_box(_estilo_borde, Rect2(Vector2.ZERO, s))

	func _Inset_Radio(y: float, s: Vector2, r: float) -> float:
		var dy := 0.0
		if y < r:
			dy = r - y
		elif y > s.y - r:
			dy = y - (s.y - r)
		if dy <= 0.0:
			return 0.0
		return r - sqrt(maxf(0.0, r * r - dy * dy))


class Medidor_Edad extends Control:
	"""Barra de edad de 18 a 100 años con marca fantasma de la edad original."""

	const EDAD_MIN := 18.0
	const EDAD_MAX := 100.0

	var edad_actual: int = 18
	var edad_sin_tratamientos: int = 18
	var fondo_oscuro: bool = false
	var _actual_anim: float = 18.0
	var _referencia_anim: float = 18.0
	var _tween: Tween
	var _fondo: StyleBoxFlat
	var _relleno: StyleBoxFlat

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(0, 28)
		_fondo = StyleBoxFlat.new()
		_fondo.bg_color = Color(1, 1, 1, 0.14) if fondo_oscuro else Color("#e2e8f0")
		_fondo.set_corner_radius_all(999)
		_fondo.anti_aliasing = true
		_relleno = StyleBoxFlat.new()
		_relleno.bg_color = TEAL
		_relleno.set_corner_radius_all(999)
		_relleno.anti_aliasing = true
		queue_redraw()

	func Establecer(actual: int, sin_tratamientos: int, animar: bool = true) -> void:
		edad_actual = clampi(actual, int(EDAD_MIN), int(EDAD_MAX))
		edad_sin_tratamientos = clampi(maxi(actual, sin_tratamientos),
			int(EDAD_MIN), int(EDAD_MAX))
		if _tween != null and _tween.is_valid():
			_tween.kill()
		if not animar or not is_inside_tree():
			_actual_anim = float(edad_actual)
			_referencia_anim = float(edad_sin_tratamientos)
			queue_redraw()
			return
		_referencia_anim = float(edad_sin_tratamientos)
		_tween = create_tween()
		_tween.tween_method(Callable(self, "_Poner_Valor_Animado"),
			_actual_anim, float(edad_actual), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	func _Poner_Valor_Animado(valor: float) -> void:
		_actual_anim = valor
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 30.0:
			return
		_fondo.bg_color = Color(1, 1, 1, 0.14) if fondo_oscuro else Color("#e2e8f0")
		var y := s.y * 0.5
		var alto := 8.0
		var margen := 8.0
		var ancho_util := s.x - margen * 2.0
		draw_style_box(_fondo, Rect2(margen, y - alto * 0.5, ancho_util, alto))

		var t_actual := _Progreso(_actual_anim)
		_relleno.bg_color = _Color_Para_Edad(_actual_anim)
		draw_style_box(_relleno, Rect2(margen, y - alto * 0.5,
			maxf(alto, ancho_util * t_actual), alto))

		# Marcas cada 10 años.
		var color_marca := Color(1, 1, 1, 0.18) if fondo_oscuro else Color(0.39, 0.45, 0.55, 0.25)
		for edad in range(20, 101, 10):
			var x := margen + ancho_util * _Progreso(float(edad))
			draw_line(Vector2(x, y - alto * 0.5), Vector2(x, y + alto * 0.5),
				color_marca, 1.0, true)

		# Marca fantasma: dónde estaría el Sim sin los tratamientos.
		if _referencia_anim > _actual_anim + 0.4:
			var x_ref := margen + ancho_util * _Progreso(_referencia_anim)
			var color_ref := Color(1, 1, 1, 0.52) if fondo_oscuro else Color("#64748b")
			draw_line(Vector2(x_ref, y - 9.0), Vector2(x_ref, y + 9.0),
				color_ref, 2.0, true)
			draw_circle(Vector2(x_ref, y - 11.0), 3.0, color_ref)

		# Marcador actual.
		var x_act := margen + ancho_util * t_actual
		draw_circle(Vector2(x_act, y), 8.5, Color(0.06, 0.09, 0.16, 0.18))
		draw_circle(Vector2(x_act, y), 6.5, Color.WHITE)
		draw_circle(Vector2(x_act, y), 4.2, _Color_Para_Edad(_actual_anim))

	func _Progreso(edad: float) -> float:
		return clampf((edad - EDAD_MIN) / (EDAD_MAX - EDAD_MIN), 0.0, 1.0)

	static func _Color_Para_Edad(edad: float) -> Color:
		var t := clampf((edad - EDAD_MIN) / (EDAD_MAX - EDAD_MIN), 0.0, 1.0)
		if t < 0.55:
			return TEAL.lerp(AMBAR, t / 0.55)
		return AMBAR.lerp(CORAL, (t - 0.55) / 0.45)


class Estallido extends Control:
	"""Halo radial breve para celebrar una recompensa detrás de la tarjeta."""

	var color: Color = Color("#fbbf24")
	var _tiempo: float = 0.0
	var _activo: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func Disparar() -> void:
		_tiempo = 0.0
		_activo = true
		visible = true
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		if not _activo:
			return
		_tiempo += delta
		queue_redraw()
		if _tiempo > 1.9:
			_activo = false
			visible = false
			set_process(false)

	func _draw() -> void:
		var s := size
		if s.x < 10.0 or s.y < 10.0 or not _activo:
			return
		var centro := s * 0.5
		var vida := clampf(1.0 - _tiempo / 1.9, 0.0, 1.0)
		for i in range(20):
			var angulo := TAU * float(i) / 20.0 + _tiempo * 0.22
			var largo := 250.0 + 90.0 * sin(float(i) * 2.17)
			var perp := Vector2(-sin(angulo), cos(angulo)) * 7.0
			var p1 := centro + Vector2(cos(angulo), sin(angulo)) * 115.0
			var p2 := centro + Vector2(cos(angulo), sin(angulo)) * largo
			var pts := PackedVector2Array([p1 + perp, p2, p1 - perp])
			draw_colored_polygon(pts, Color(color, 0.105 * vida))
		draw_circle(centro, 170.0, Color(color, 0.035 * vida))


class Confeti extends Control:
	"""Explosión breve de partículas para la pantalla de recompensa."""

	var _particulas: Array = []
	var _tiempo: float = 0.0
	var _activo: bool = false
	var radio_inicial: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func Reiniciar(colores: Array, cantidad: int = 42) -> void:
		_particulas.clear()
		_tiempo = 0.0
		_activo = true
		visible = true
		var s := size if size.x > 10.0 else Vector2(620, 480)
		for i in range(cantidad):
			var color: Color = colores[i % colores.size()]
			var angulo := -PI * 0.5 + randf_range(-1.15, 1.15)
			var velocidad := randf_range(170.0, 480.0)
			var origen := s * 0.5
			if radio_inicial > 0.0:
				var direccion := Vector2(cos(angulo), sin(angulo))
				origen += direccion * randf_range(radio_inicial * 0.6, radio_inicial)
			_particulas.append({
				"pos": origen + Vector2(randf_range(-12, 12), randf_range(-10, 10)),
				"vel": Vector2(cos(angulo), sin(angulo)) * velocidad,
				"giro": randf_range(-8.0, 8.0),
				"angulo": randf_range(0.0, TAU),
				"tam": randf_range(4.0, 9.0),
				"color": color,
				"vida": randf_range(0.9, 1.6),
				"forma": i % 3,
			})
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		if not _activo:
			return
		_tiempo += delta
		var s := size if size.x > 10.0 else Vector2(620, 480)
		for p in _particulas:
			p["vida"] = float(p["vida"]) - delta
			p["vel"] = (p["vel"] as Vector2) + Vector2(0, 520.0 * delta)
			p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
			p["angulo"] = float(p["angulo"]) + float(p["giro"]) * delta
			if float(p["pos"].y) > s.y + 30.0:
				p["vida"] = 0.0
		queue_redraw()
		if _tiempo > 2.2:
			_activo = false
			set_process(false)
			visible = false

	func _draw() -> void:
		for p in _particulas:
			var vida := float(p["vida"])
			if vida <= 0.0:
				continue
			var color: Color = p["color"]
			color.a *= clampf(vida / 0.4, 0.0, 1.0)
			var pos: Vector2 = p["pos"]
			var tam: float = p["tam"]
			var ang: float = p["angulo"]
			if int(p["forma"]) == 0:
				draw_rect(Rect2(pos - Vector2(tam, tam) * 0.5, Vector2(tam, tam * 0.6)), color, true)
			elif int(p["forma"]) == 1:
				draw_circle(pos, tam * 0.42, color)
			else:
				var direccion := Vector2(cos(ang), sin(ang)) * tam
				draw_line(pos - direccion, pos + direccion, color, 1.6, true)
