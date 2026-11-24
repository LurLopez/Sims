class_name Tienda_Objetos
extends Control
## Pantalla de muebles de la Tienda.

const CATALOGO_TIENDA := preload("res://Scripts/Logica/Escena_Principal/Economia/Catalogo_Tienda.gd")

## Construye las pestañas y la rejilla de tarjetas a partir de
## `Catalogo_Tienda.DATOS`. La rejilla es desplazable, por lo que el catálogo
## puede crecer sin tocar la escena. `Script_Principal` solo se encarga de
## abrir/cerrar la pantalla y de refrescar el dinero.

signal dinero_cambiado
signal objetos_cambiados
signal atras_pressed

const ALTO_CABECERA := 248.0
const ALTO_DOCK := 92.0
const ANCHO_TARJETA := 332.0
const ALTO_TARJETA := 390.0
const SEPARACION_TARJETAS := 16.0

var _categoria_actual: String = "Dormir"
var _scroll: ScrollContainer
var _grid: GridContainer
var _track: Panel
var _scroll_tabs: ScrollContainer
var _tabs_box: HBoxContainer
var _ventajas: Control
var _tarjetas: Dictionary = {}
var _categoria_tarjeta: Dictionary = {}
var _botones_categoria: Dictionary = {}
var _estilo_normal: StyleBoxFlat
var _estilo_propio: StyleBoxFlat
var _estilo_seleccionado: StyleBoxFlat
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("_tema_aplicado", true)
	_Inicializar_Estilos()
	_Construir_Categorias()
	_Construir_Contenido()
	_Construir_Toast()
	_ventajas = get_node_or_null("Objetos_Ventajas") as Control
	if _ventajas != null:
		_ventajas.visible = false
	Ajustar_Disposicion(_Alto_Visible())
	Abrir_Categoria("Dormir")


func _Alto_Visible() -> float:
	var vp := get_viewport()
	var alto: float = vp.get_visible_rect().size.y if vp != null else 1280.0
	return maxf(alto, 1280.0)


func _Inicializar_Estilos() -> void:
	_estilo_normal = Estilos_UI.caja_tarjeta(16, 3)
	_estilo_propio = Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.BORDE_FUERTE, 1, 1)
	_estilo_propio.border_width_bottom = 3
	_estilo_seleccionado = Estilos_UI.caja(Estilos_UI.SUPERFICIE, 16, Estilos_UI.EXITO, 2, 2)


func _Construir_Categorias() -> void:
	_track = Panel.new()
	_track.name = "Categorias_Track"
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.set_meta("_tema_aplicado", true)
	_track.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#e5e7eb"), 12, Color(0, 0, 0, 0), 0, 0))
	add_child(_track)

	_scroll_tabs = ScrollContainer.new()
	_scroll_tabs.name = "Categorias_Scroll"
	_scroll_tabs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll_tabs.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll_tabs.scroll_horizontal_custom_step = 94.0
	_scroll_tabs.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scroll_tabs)

	_tabs_box = HBoxContainer.new()
	_tabs_box.name = "Categorias"
	_tabs_box.add_theme_constant_override("separation", 4)
	_tabs_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tabs_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_tabs.add_child(_tabs_box)

	for categoria in CATALOGO_TIENDA.CATEGORIAS:
		_Crear_Boton_Categoria(categoria)
	_Crear_Boton_Categoria({
		"id": "Ventajas",
		"nombre": "Ventajas",
		"icono": "sparkles",
	})


func _Crear_Boton_Categoria(categoria: Dictionary) -> void:
	var id: String = str(categoria.get("id", ""))
	if id == "":
		return
	var btn := Button.new()
	btn.name = "Tab_" + id
	btn.text = str(categoria.get("nombre", id))
	btn.icon = Estilos_UI.icono(str(categoria.get("icono", "circle-help")))
	btn.expand_icon = false
	btn.custom_minimum_size = Vector2(90, 38)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_meta("_tema_aplicado", true)
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_constant_override("icon_max_width", 14)
	btn.add_theme_constant_override("h_separation", 3)
	btn.pressed.connect(Abrir_Categoria.bind(id))
	_tabs_box.add_child(btn)
	_botones_categoria[id] = btn
	_Marcar_Tabs(_categoria_actual)


func _Marcar_Tabs(activa: String) -> void:
	for id in _botones_categoria:
		var btn: Button = _botones_categoria[id]
		if btn == null or not is_instance_valid(btn):
			continue
		var on: bool = str(id) == activa
		var normal := Estilos_UI.caja(
			Estilos_UI.SUPERFICIE if on else Color(0, 0, 0, 0),
			10,
			Estilos_UI.ROJO_BIT if on else Color(0, 0, 0, 0),
			0,
			1 if on else 0)
		if on:
			normal.border_width_bottom = 2
		var hover := normal.duplicate() as StyleBoxFlat
		if not on:
			hover.bg_color = Color("#f1f3f7")
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Estilos_UI.PRIMARIO_SUAVE
		pressed.border_color = Estilos_UI.ROJO_BIT
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if on else 500))
		var color: Color = Estilos_UI.ROJO_BIT if on else Estilos_UI.TINTA_SUAVE
		for clave in ["font_color", "font_hover_color", "font_pressed_color",
				"icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			btn.add_theme_color_override(clave, color)


func _Construir_Contenido() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "Contenido_Scroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scroll)

	var margen := MarginContainer.new()
	margen.name = "Margen_Objetos"
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 4)
	margen.add_theme_constant_override("margin_bottom", 28)
	_scroll.add_child(margen)

	_grid = GridContainer.new()
	_grid.name = "Rejilla_Objetos"
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", int(SEPARACION_TARJETAS))
	_grid.add_theme_constant_override("v_separation", int(SEPARACION_TARJETAS))
	margen.add_child(_grid)

	for categoria in CATALOGO_TIENDA.CATEGORIAS:
		var id: String = str(categoria.get("id", ""))
		for clave in CATALOGO_TIENDA.Claves_De_Categoria(id):
			_Crear_Tarjeta(clave, categoria)


func _Crear_Tarjeta(clave: String, categoria: Dictionary) -> void:
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos.get(clave, null) as Objeto
	if objeto == null:
		return
	var id: String = str(categoria.get("id", ""))
	var fondo: Color = Color(str(categoria.get("fondo", "#eef5fc")))

	var card := Panel.new()
	card.name = "Card_" + clave
	card.custom_minimum_size = Vector2(ANCHO_TARJETA, ALTO_TARJETA)
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", _estilo_normal)
	card.tooltip_text = objeto.descripcion
	_grid.add_child(card)

	var imagen := Panel.new()
	imagen.name = "Imagen_Placeholder"
	imagen.position = Vector2(14, 14)
	imagen.size = Vector2(304, 196)
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagen.set_meta("_tema_aplicado", true)
	var st_img := Estilos_UI.caja(fondo, 12, Color(0, 0, 0, 0), 0, 0)
	st_img.border_width_bottom = 2
	st_img.border_color = fondo.darkened(0.14)
	imagen.add_theme_stylebox_override("panel", st_img)
	card.add_child(imagen)

	var icono := TextureRect.new()
	icono.name = "Icono_Item"
	icono.position = Vector2(6, 4)
	icono.size = Vector2(292, 188)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagen.add_child(icono)

	# Respaldo Lucide, oculto hasta saber si el PNG del mueble existe.
	var icono_respaldo := Estilos_UI.icono_rect(str(categoria.get("icono", "shopping-bag")),
		58, Color(str(categoria.get("color", "#475569"))))
	icono_respaldo.name = "Icono_Respaldo"
	icono_respaldo.position = Vector2(123, 69)
	icono_respaldo.size = Vector2(58, 58)
	icono_respaldo.visible = false
	imagen.add_child(icono_respaldo)

	var tier: String = objeto.tier
	var tier_txt := "BÁSICO"
	var tier_fg := Estilos_UI.TINTA_SUAVE
	match tier:
		"premium":
			tier_txt = "PREMIUM"
			tier_fg = Estilos_UI.ORO
		"lujo":
			tier_txt = "LUJO"
			tier_fg = Estilos_UI.MORADO
		"elite":
			tier_txt = "ÉLITE"
			tier_fg = Estilos_UI.PRIMARIO
	var pill := Estilos_UI.pill_estado(tier_txt, Color(1, 1, 1, 0.92), tier_fg)
	pill.name = "Tier_Pill"
	pill.position = Vector2(10, 10)
	pill.z_index = 2
	imagen.add_child(pill)

	var nombre := Estilos_UI.texto(objeto.nombre_para_mostrar(), 17, Estilos_UI.TINTA, 700)
	nombre.name = "Nombre"
	nombre.position = Vector2(16, 218)
	nombre.size = Vector2(300, 26)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_child(nombre)

	var precio := Estilos_UI.texto("", 15, Estilos_UI.PRIMARIO, 700)
	precio.name = "Precio"
	precio.position = Vector2(16, 244)
	precio.size = Vector2(300, 24)
	precio.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_child(precio)

	var efecto := Estilos_UI.texto(objeto.etiqueta_efecto, 12, Estilos_UI.TINTA_SUAVE, 500)
	efecto.name = "Multiplicador"
	efecto.position = Vector2(16, 268)
	efecto.size = Vector2(300, 20)
	efecto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	efecto.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.add_child(efecto)

	var estado := Estilos_UI.texto("", 12, Estilos_UI.TINTA_SUAVE, 700)
	estado.name = "En_Uso"
	estado.position = Vector2(16, 292)
	estado.size = Vector2(300, 20)
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_child(estado)

	var comprar := Estilos_UI.boton("Comprar", "exito", "shopping-bag", Estilos_UI.EXITO, 44)
	comprar.name = "Comprar"
	comprar.position = Vector2(16, 326)
	comprar.size = Vector2(300, 44)
	comprar.add_theme_font_size_override("font_size", 13)
	comprar.pressed.connect(_Comprar.bind(clave))
	card.add_child(comprar)

	var elegir := Estilos_UI.boton("Equipar", "primario", "check", Estilos_UI.AZUL, 44)
	elegir.name = "Elegir"
	elegir.position = Vector2(16, 326)
	elegir.size = Vector2(300, 44)
	elegir.add_theme_font_size_override("font_size", 13)
	elegir.pressed.connect(_Elegir.bind(id, clave))
	card.add_child(elegir)

	var vender := Estilos_UI.boton("Vender", "suave", "hand-coins", Estilos_UI.PELIGRO, 44)
	vender.name = "Vender"
	vender.position = Vector2(214, 326)
	vender.size = Vector2(102, 44)
	vender.add_theme_font_size_override("font_size", 12)
	vender.pressed.connect(_Vender.bind(clave))
	card.add_child(vender)

	_tarjetas[clave] = {
		"card": card,
		"icono": icono,
		"respaldo": icono_respaldo,
		"precio": precio,
		"estado": estado,
		"comprar": comprar,
		"elegir": elegir,
		"vender": vender,
	}
	_categoria_tarjeta[clave] = id


func _Construir_Toast() -> void:
	_toast = PanelContainer.new()
	_toast.name = "Toast_Tienda"
	_toast.z_index = 60
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	_toast.set_meta("_tema_aplicado", true)
	_toast.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.EXITO_SUAVE, 12, Estilos_UI.EXITO, 1, 2))
	add_child(_toast)
	_toast_label = Estilos_UI.texto("", 13, Estilos_UI.EXITO_OSCURO, 700)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)


func Ajustar_Disposicion(alto: float) -> void:
	size = Vector2(720, alto)
	if _track != null:
		_track.position = Vector2(20, 184)
		_track.size = Vector2(680, 46)
	if _scroll_tabs != null:
		_scroll_tabs.position = Vector2(24, 188)
		_scroll_tabs.size = Vector2(672, 38)
	if _scroll != null:
		_scroll.position = Vector2(0, ALTO_CABECERA)
		_scroll.size = Vector2(720, maxf(220.0, alto - ALTO_CABECERA - ALTO_DOCK))
	if _ventajas != null:
		_ventajas.position = Vector2(0, ALTO_CABECERA)
		_ventajas.size = Vector2(720, maxf(220.0, alto - ALTO_CABECERA - ALTO_DOCK))
	if _toast != null:
		_toast.position = Vector2(190, alto - 166)
		_toast.size = Vector2(340, 46)


func _Cargar_Icono(clave: String) -> void:
	var refs: Dictionary = _tarjetas.get(clave, {})
	if refs.is_empty():
		return
	var icono: TextureRect = refs["icono"]
	var respaldo: TextureRect = refs["respaldo"]
	var textura := icono.texture
	if textura == null:
		textura = Estilos_UI.icono_tienda(clave)
		icono.texture = textura
	if textura != null:
		icono.visible = true
		respaldo.visible = false
	else:
		icono.texture = null
		icono.visible = false
		respaldo.visible = true


func Abrir_Categoria(id: String) -> void:
	if _toast != null:
		_toast.visible = false
	if id == "Ventajas":
		_categoria_actual = "Ventajas"
		if _scroll != null:
			_scroll.visible = false
		if _ventajas != null:
			_ventajas.visible = true
		_Marcar_Tabs("Ventajas")
		return
	if not CATALOGO_TIENDA.Es_Categoria_De_Objetos(id):
		id = "Dormir"
	_categoria_actual = id
	if _scroll != null:
		_scroll.visible = true
	if _ventajas != null:
		_ventajas.visible = false
	for clave in _tarjetas:
		var refs: Dictionary = _tarjetas[clave]
		var card: Panel = refs["card"]
		var es_actual: bool = str(_categoria_tarjeta.get(clave, "")) == id
		card.visible = es_actual
		if es_actual:
			_Cargar_Icono(clave)
		else:
			var icono: TextureRect = refs["icono"]
			icono.texture = null
	_Marcar_Tabs(id)
	if _scroll != null:
		_scroll.scroll_vertical = 0
	Refrescar()
	_Animar_Tarjetas_Visibles()


func _Animar_Tarjetas_Visibles() -> void:
	var indice := 0
	for clave in _tarjetas:
		var card: Panel = _tarjetas[clave]["card"]
		if not card.visible:
			continue
		Estilos_UI.animar_entrada(card, minf(0.18, indice * 0.025))
		indice += 1


func Refrescar() -> void:
	for clave in _tarjetas:
		_Actualizar_Tarjeta(clave)
	if _ventajas != null and is_instance_valid(_ventajas) and _ventajas.visible \
			and _ventajas.has_method("Refrescar"):
		_ventajas.call("Refrescar")


func _Actualizar_Tarjeta(clave: String) -> void:
	var refs: Dictionary = _tarjetas.get(clave, {})
	if refs.is_empty():
		return
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos.get(clave, null) as Objeto
	if objeto == null:
		return
	var categoria: String = str(_categoria_tarjeta.get(clave, ""))
	var poseido: bool = bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false))
	var seleccionado: bool = str(Variables_Dinamicas.Objeto_Seleccionado.get(categoria, "")) == clave
	var hay_otro: bool = _Hay_Otro_Poseido(categoria, clave)
	var precio: int = int(Variables_Estaticas.Obtener_Precio_Objeto(objeto))

	var card: Panel = refs["card"]
	if seleccionado:
		card.add_theme_stylebox_override("panel", _estilo_seleccionado)
	elif poseido:
		card.add_theme_stylebox_override("panel", _estilo_propio)
	else:
		card.add_theme_stylebox_override("panel", _estilo_normal)

	var lbl_precio: Label = refs["precio"]
	lbl_precio.text = "Gratis" if precio <= 0 else "%d €" % precio

	var estado: Label = refs["estado"]
	if seleccionado:
		estado.text = "En uso"
		estado.add_theme_color_override("font_color", Estilos_UI.EXITO)
	elif poseido:
		estado.text = "En propiedad"
		estado.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
	elif precio > 0 and Variables_Dinamicas.Dinero < precio:
		estado.text = "Te faltan %d €" % int(ceil(float(precio) - Variables_Dinamicas.Dinero))
		estado.add_theme_color_override("font_color", Estilos_UI.PELIGRO)
	else:
		estado.text = "Disponible"
		estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)

	var comprar: Button = refs["comprar"]
	comprar.visible = not poseido
	comprar.text = "Obtener gratis" if precio <= 0 else "Comprar"
	comprar.position = Vector2(16, 326)
	comprar.size = Vector2(300, 44)

	var elegir: Button = refs["elegir"]
	elegir.visible = poseido and not seleccionado
	elegir.position = Vector2(16, 326)
	elegir.size = Vector2(190 if hay_otro else 300, 44)

	var vender: Button = refs["vender"]
	vender.visible = poseido and not seleccionado and hay_otro
	if vender.visible:
		vender.position = Vector2(214, 326)
		vender.size = Vector2(102, 44)


func _Hay_Otro_Poseido(categoria: String, clave: String) -> bool:
	for c in Variables_Dinamicas.Objetos_Poseidos.keys():
		if str(c) == clave:
			continue
		if not bool(Variables_Dinamicas.Objetos_Poseidos.get(c, false)):
			continue
		if CATALOGO_TIENDA.Categoria_De(str(c)) != categoria:
			continue
		return true
	return false


func _Comprar(clave: String) -> void:
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos.get(clave, null) as Objeto
	if objeto == null:
		return
	if bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false)):
		return
	var precio: int = int(Variables_Estaticas.Obtener_Precio_Objeto(objeto))
	if Variables_Dinamicas.Dinero < precio:
		_Mostrar_Toast("Te faltan %d €" % int(ceil(float(precio) - Variables_Dinamicas.Dinero)), "aviso")
		return
	if not Actividades.Comprar_Objeto(clave):
		_Mostrar_Toast("No se pudo completar la compra", "peligro")
		return
	_Mostrar_Toast("¡Añadido a tu casa: %s!" % objeto.nombre_para_mostrar(), "exito")
	Refrescar()
	dinero_cambiado.emit()
	objetos_cambiados.emit()


func _Vender(clave: String) -> void:
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos.get(clave, null) as Objeto
	if objeto == null:
		return
	var categoria: String = objeto.afecta_a
	if str(Variables_Dinamicas.Objeto_Seleccionado.get(categoria, "")) == clave:
		_Mostrar_Toast("Equipa otro objeto antes de venderlo", "aviso")
		return
	if not _Hay_Otro_Poseido(categoria, clave):
		_Mostrar_Toast("Debe quedarte al menos un objeto de esta categoría", "aviso")
		return
	var devolucion: int = int(floor(Variables_Estaticas.Obtener_Precio_Objeto(objeto) * 0.5))
	if not Actividades.Vender_Objeto(clave):
		_Mostrar_Toast("No se pudo vender el objeto", "peligro")
		return
	_Mostrar_Toast("Vendido por %d €" % devolucion, "exito")
	Refrescar()
	dinero_cambiado.emit()
	objetos_cambiados.emit()


func _Elegir(categoria: String, clave: String) -> void:
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos.get(clave, null) as Objeto
	if objeto == null:
		return
	if not Actividades.Seleccionar_Objeto(categoria, clave):
		_Mostrar_Toast("No se pudo equipar el objeto", "peligro")
		return
	_Mostrar_Toast("Ahora usas %s" % objeto.nombre_para_mostrar(), "exito")
	Refrescar()
	objetos_cambiados.emit()


func _Mostrar_Toast(texto: String, tipo: String = "exito") -> void:
	if _toast == null or _toast_label == null:
		return
	match tipo:
		"aviso":
			_toast.add_theme_stylebox_override("panel",
				Estilos_UI.caja(Estilos_UI.AVISO_SUAVE, 12, Estilos_UI.ORO, 1, 2))
			_toast_label.add_theme_color_override("font_color", Estilos_UI.ORO)
		"peligro":
			_toast.add_theme_stylebox_override("panel",
				Estilos_UI.caja(Estilos_UI.PELIGRO_SUAVE, 12, Estilos_UI.PELIGRO, 1, 2))
			_toast_label.add_theme_color_override("font_color", Estilos_UI.PELIGRO)
		_:
			_toast.add_theme_stylebox_override("panel",
				Estilos_UI.caja(Estilos_UI.EXITO_SUAVE, 12, Estilos_UI.EXITO, 1, 2))
			_toast_label.add_theme_color_override("font_color", Estilos_UI.EXITO_OSCURO)
	_toast_label.text = texto
	_toast.visible = true
	_toast.modulate.a = 0.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.14)
	_toast_tween.tween_interval(1.45)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.22)
	_toast_tween.tween_callback(func():
		if _toast != null and is_instance_valid(_toast):
			_toast.visible = false
	)
