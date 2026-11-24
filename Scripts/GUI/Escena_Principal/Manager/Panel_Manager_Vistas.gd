class_name Panel_Manager_Vistas
extends RefCounted

# Vistas modulares de alta visibilidad y toque «humano» para «El Mánager»:
# ficha de jugador con barras de atributos y entrenamiento directo, mercado
# con retratos, comparativas y cantera, modal de oferta sin SpinBox oscuro
# y pestaña de liga con zonas, emparejamientos y líderes de la división.

const LIMITE_MERCADO_INICIAL: int = 20


# ------------------------------------------------------------------
# Ficha humana del jugador y entrenamiento directo
# ------------------------------------------------------------------

static func construir_ficha_jugador(panel: Panel_Manager, jugador_id: String,
		feedback_entreno: String = "", feedback_ok: bool = true) -> void:
	panel._Cerrar_Ficha()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var jugador: Dictionary = Sistema_Manager.Obtener_Jugador_De_Club(
		Sistema_Manager.Club_Usuario_Id(), jugador_id)
	if jugador.is_empty():
		return

	var colores: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club.get("escudo_patron", 1))
	var capitan_id: String = str(club.get("capitan_id", ""))
	var es_capitan: bool = capitan_id == jugador_id
	var alineacion = club.get("alineacion", [])
	var es_titular: bool = alineacion is Array and alineacion.has(jugador_id)
	var roles = jugador.get("roles", ["MC"])
	var rol_p: String = str(roles[0]) if (roles is Array and not roles.is_empty()) else "MC"
	var roles_txt: String = " / ".join(roles) if roles is Array else rol_p
	var color_rol: Color = Datos_Manager.Color_De_Rol(rol_p)

	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.07, 0.11, 0.68)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	panel.add_child(overlay)
	panel._modal_ficha = overlay

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 48.0
	card.offset_right = -48.0
	card.offset_top = 24.0
	card.offset_bottom = -24.0
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE, 20, Estilos_UI.BORDE_FUERTE, 1, 5))
	overlay.add_child(card)
	var v := VBoxContainer.new()
	card.add_child(v)

	# Cabecera humana con retrato en equipación real y dorsal.
	var cab_panel := PanelContainer.new()
	cab_panel.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE_2, 18, Estilos_UI.BORDE, 0, 0))
	v.add_child(cab_panel)
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 14)
	cm.add_theme_constant_override("margin_right", 14)
	cm.add_theme_constant_override("margin_top", 12)
	cm.add_theme_constant_override("margin_bottom", 12)
	cab_panel.add_child(cm)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	cm.add_child(cab)

	cab.add_child(Estilo_Manager.crear_retrato_jugador(
		jugador, colores, patron, 82, true, "busto", false))

	var info_cab := VBoxContainer.new()
	info_cab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_cab.add_theme_constant_override("separation", 3)
	cab.add_child(info_cab)

	var nombre_row := HBoxContainer.new()
	nombre_row.add_theme_constant_override("separation", 6)
	info_cab.add_child(nombre_row)
	var tit_lbl := Estilos_UI.titulo(str(jugador.get("nombre", "")), 19, Estilos_UI.TINTA)
	tit_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nombre_row.add_child(tit_lbl)

	var pills_cab := HBoxContainer.new()
	pills_cab.add_theme_constant_override("separation", 5)
	info_cab.add_child(pills_cab)
	pills_cab.add_child(Estilos_UI.pill_estado(roles_txt, Color(color_rol, 0.14), color_rol))
	pills_cab.add_child(Estilos_UI.pill_estado(
		"XI Titular" if es_titular else "Suplente",
		Estilo_Manager.COLOR_MANAGER_SUAVE if es_titular else Estilos_UI.SUPERFICIE,
		Estilo_Manager.COLOR_MANAGER_OSCURO if es_titular else Estilos_UI.TINTA_SUAVE))
	if es_capitan:
		pills_cab.add_child(Estilos_UI.pill_estado("Capitán",
			Estilo_Manager.COLOR_ORO_SUAVE, Color("#92400e")))

	info_cab.add_child(Estilos_UI.texto("#%d · %d años · %s" % [
		int(jugador.get("dorsal", 1)), int(jugador.get("edad", 18)),
		panel._Estrellas(int(jugador.get("estrellas", 1)))],
		12, Estilos_UI.TINTA_SUAVE, 600))
	info_cab.add_child(Estilos_UI.texto("%d cm · %d kg · Pie %s" % [
		int(jugador.get("altura", 180)), int(jugador.get("peso", 75)),
		str(jugador.get("pie", "derecho"))],
		11, Estilos_UI.TINTA_FANTASMA, 500))

	var btn_cerrar := Estilos_UI.boton_icono("x", Estilos_UI.TINTA, 44)
	btn_cerrar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	btn_cerrar.pressed.connect(panel._Cerrar_Ficha)
	cab.add_child(btn_cerrar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margen)
	var cuerpo_split := HBoxContainer.new()
	cuerpo_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo_split.add_theme_constant_override("separation", 18)
	margen.add_child(cuerpo_split)

	var cuerpo := VBoxContainer.new()
	cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.size_flags_stretch_ratio = 1.0
	cuerpo.add_theme_constant_override("separation", 10)
	cuerpo_split.add_child(cuerpo)

	var cuerpo_der := VBoxContainer.new()
	cuerpo_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo_der.size_flags_stretch_ratio = 1.1
	cuerpo_der.add_theme_constant_override("separation", 8)
	cuerpo_split.add_child(cuerpo_der)

	# Nota humana de vestuario.
	var cita_box := PanelContainer.new()
	cita_box.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Color("#f0fdfa"), 12, Color("#99f6e4"), 1, 0))
	cuerpo.add_child(cita_box)
	var cm_cita := MarginContainer.new()
	cm_cita.add_theme_constant_override("margin_left", 12)
	cm_cita.add_theme_constant_override("margin_right", 12)
	cm_cita.add_theme_constant_override("margin_top", 8)
	cm_cita.add_theme_constant_override("margin_bottom", 8)
	cita_box.add_child(cm_cita)
	var v_cita := VBoxContainer.new()
	v_cita.add_theme_constant_override("separation", 2)
	cm_cita.add_child(v_cita)
	v_cita.add_child(Estilos_UI.texto(Simulador_Manager.Rasgo_Humano_Jugador(jugador),
		12, Estilo_Manager.COLOR_MANAGER_OSCURO, 700))
	v_cita.add_child(Estilos_UI.parrafo(Simulador_Manager.Frase_Vestuario_Jugador(jugador),
		12, Estilos_UI.TINTA_SUAVE))

	# Chips clave.
	var resumen := panel._Chip_Grid(cuerpo, 2)
	resumen.add_child(panel._Chip_Estadistica("Calidad", "%.1f" % float(jugador.get("calidad", 0.0)),
		Estilos_UI.color_valor(float(jugador.get("calidad", 0.0)))))
	resumen.add_child(panel._Chip_Estadistica("Valor de mercado", panel._Euros(int(jugador.get("valor_mercado", 0))),
		Estilos_UI.AZUL))
	resumen.add_child(panel._Chip_Estadistica("Cláusula", panel._Euros(int(jugador.get("clausula_rescision", 0))),
		Estilo_Manager.COLOR_ORO))
	resumen.add_child(panel._Chip_Estadistica("Salario", "%s/sem" % panel._Euros(
		int(jugador.get("salario_semanal", 0))), Estilos_UI.PELIGRO))

	panel._Barra(cuerpo, "Energía", float(jugador.get("energia", 100.0)),
		Estilos_UI.color_valor(float(jugador.get("energia", 100.0))))

	var stats_h := HBoxContainer.new()
	stats_h.add_theme_constant_override("separation", 8)
	cuerpo.add_child(stats_h)
	stats_h.add_child(panel._Chip_Estadistica("Partidos", str(int(jugador.get("partidos_jugados", 0))), Estilos_UI.TINTA))
	stats_h.add_child(panel._Chip_Estadistica("Goles", str(int(jugador.get("goles", 0))), Estilos_UI.EXITO))
	stats_h.add_child(panel._Chip_Estadistica("Asist.", str(int(jugador.get("asistencias", 0))), Estilos_UI.AZUL))
	stats_h.add_child(panel._Chip_Estadistica("Contrato", "%d temp." % int(jugador.get("contrato_temporadas", 1)),
		Estilo_Manager.COLOR_ORO))

	# Controles humanos: capitanía, dorsal y renovación.
	var gest_h := HBoxContainer.new()
	gest_h.add_theme_constant_override("separation", 8)
	cuerpo.add_child(gest_h)

	var btn_cap := Estilo_Manager.boton(
		"Es capitán" if es_capitan else "Hacer capitán",
		"oro" if es_capitan else "suave", "crown", Estilo_Manager.COLOR_ORO, 44)
	btn_cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cap.disabled = es_capitan
	btn_cap.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("ding")
		Sistema_Manager.Cambiar_Capitan(jugador_id)
		construir_ficha_jugador(panel, jugador_id, "Asignado como nuevo capitán del club.", true)
		panel._Refrescar(false))
	gest_h.add_child(btn_cap)

	var btn_renovar := Estilo_Manager.boton("Renovar (+2 temp.)", "suave", "bookmark",
		Estilos_UI.AZUL, 44)
	btn_renovar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_renovar.disabled = int(jugador.get("contrato_temporadas", 1)) >= 5
	btn_renovar.pressed.connect(func():
		var res: Dictionary = Sistema_Manager.Renovar_Contrato(jugador_id)
		if bool(res.get("ok", false)):
			Estilo_Manager.reproducir_sfx("coin")
			construir_ficha_jugador(panel, jugador_id,
				"Contrato ampliado a %d temporadas (prima %s)." % [
					int(res.get("contrato", 1)), panel._Euros(int(res.get("prima", 0)))], true)
			panel._Refrescar(false)
		else:
			construir_ficha_jugador(panel, jugador_id, str(res.get("motivo", "")), false))
	gest_h.add_child(btn_renovar)

	# Selector de dorsal rápido.
	var dorsal_h := HBoxContainer.new()
	dorsal_h.add_theme_constant_override("separation", 8)
	cuerpo.add_child(dorsal_h)
	var lbl_dor := Estilos_UI.texto("Dorsal en la camiseta", 12, Estilos_UI.TINTA_SUAVE, 600)
	lbl_dor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dorsal_h.add_child(lbl_dor)
	var dorsal_act: int = int(jugador.get("dorsal", 1))
	var btn_d_menos := Estilo_Manager.boton("−", "chip", "", Estilos_UI.TINTA, 40)
	btn_d_menos.custom_minimum_size = Vector2(48, 40)
	btn_d_menos.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		Sistema_Manager.Cambiar_Dorsal(jugador_id, maxi(1, dorsal_act - 1))
		construir_ficha_jugador(panel, jugador_id)
		panel._Refrescar(false))
	dorsal_h.add_child(btn_d_menos)
	var dor_val := Estilos_UI.titulo("#%d" % dorsal_act, 16, Estilo_Manager.COLOR_MANAGER_OSCURO)
	dor_val.custom_minimum_size = Vector2(46, 0)
	dor_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dorsal_h.add_child(dor_val)
	var btn_d_mas := Estilo_Manager.boton("+", "chip", "", Estilos_UI.TINTA, 40)
	btn_d_mas.custom_minimum_size = Vector2(48, 40)
	btn_d_mas.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		Sistema_Manager.Cambiar_Dorsal(jugador_id, mini(99, dorsal_act + 1))
		construir_ficha_jugador(panel, jugador_id)
		panel._Refrescar(false))
	dorsal_h.add_child(btn_d_mas)

	cuerpo_der.add_child(Estilos_UI.titulo("Atributos (★ clave para %s)" % rol_p, 16, Estilos_UI.TINTA))
	var claves_rol: Array = Datos_Manager.ATRIBUTOS_CLAVE_ROL.get(rol_p, [])

	for bloque in ["defensa", "ataque", "fisico_mental"]:
		var titulo_bloque: String = {
			"defensa": "Defensa",
			"ataque": "Ataque",
			"fisico_mental": "Físico / Mental"
		}.get(bloque, bloque)
		cuerpo_der.add_child(Estilos_UI.texto(titulo_bloque.to_upper(), 10,
			Estilo_Manager.COLOR_MANAGER_OSCURO, 700))
		var valores = jugador.get(bloque, {})
		if not (valores is Dictionary):
			continue
		for atributo in Datos_Manager.BLOQUES_ATRIBUTOS[bloque]:
			var valor: int = int(valores.get(atributo, 50))
			cuerpo_der.add_child(Estilo_Manager.barra_atributo(
				str(Datos_Manager.NOMBRES_ATRIBUTOS.get(atributo, atributo)),
				valor, claves_rol.has(atributo)))

	cuerpo_der.add_child(Estilos_UI.divisor_horizontal())
	var entrenado_hoy: bool = int(jugador.get("entrenado_dia", -1)) == Variables_Dinamicas.Minute_Day
	var cab_ent := HBoxContainer.new()
	cab_ent.add_theme_constant_override("separation", 8)
	cuerpo_der.add_child(cab_ent)
	var tit_ent := Estilos_UI.titulo("Entrenamiento individual", 16, Estilos_UI.TINTA)
	tit_ent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab_ent.add_child(tit_ent)
	cab_ent.add_child(Estilos_UI.pill_estado(
		"Completado hoy" if entrenado_hoy else "Disponible (−12% energía)",
		Estilos_UI.SUPERFICIE_2 if entrenado_hoy else Estilos_UI.EXITO_SUAVE,
		Estilos_UI.TINTA_SUAVE if entrenado_hoy else Estilos_UI.EXITO_OSCURO))

	if feedback_entreno != "":
		var fb := PanelContainer.new()
		fb.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Estilos_UI.EXITO_SUAVE if feedback_ok else Estilos_UI.PELIGRO_SUAVE,
			10, Estilos_UI.EXITO if feedback_ok else Estilos_UI.PELIGRO, 1, 0))
		cuerpo_der.add_child(fb)
		var fbm := MarginContainer.new()
		fbm.add_theme_constant_override("margin_left", 10)
		fbm.add_theme_constant_override("margin_right", 10)
		fbm.add_theme_constant_override("margin_top", 8)
		fbm.add_theme_constant_override("margin_bottom", 8)
		fb.add_child(fbm)
		fbm.add_child(Estilos_UI.parrafo(feedback_entreno, 12,
			Estilos_UI.EXITO_OSCURO if feedback_ok else Estilos_UI.PELIGRO))

	# Ordenar atributos recomendados para el rol primero.
	var orden_attrs: Array = []
	for c in claves_rol:
		orden_attrs.append(c)
	for a in Datos_Manager.ATRIBUTOS:
		if not orden_attrs.has(a):
			orden_attrs.append(a)

	var grid_entreno := GridContainer.new()
	grid_entreno.columns = 3
	grid_entreno.add_theme_constant_override("h_separation", 8)
	grid_entreno.add_theme_constant_override("v_separation", 6)
	cuerpo_der.add_child(grid_entreno)
	var energia_suficiente: bool = float(jugador.get("energia", 100.0)) >= Datos_Manager.COSTE_ENERGIA_ENTRENAMIENTO
	for atributo2 in orden_attrs:
		var attr_str: String = str(atributo2)
		var es_clave: bool = claves_rol.has(attr_str)
		var nombre_a: String = str(Datos_Manager.NOMBRES_ATRIBUTOS.get(attr_str, attr_str))
		var val_a: int = int(Simulador_Manager._Atributo(jugador, attr_str))
		var btn_attr := Estilo_Manager.boton(
			("%s%s (%d)" % ["★ " if es_clave else "+ ", nombre_a, val_a]),
			"primario" if (es_clave and not entrenado_hoy) else "suave", "",
			Estilo_Manager.COLOR_ORO if es_clave else Estilo_Manager.COLOR_MANAGER, 44)
		btn_attr.add_theme_font_size_override("font_size", 11)
		btn_attr.disabled = entrenado_hoy or not energia_suficiente or val_a >= Datos_Manager.ATRIBUTO_MAXIMO
		btn_attr.pressed.connect(func():
			var resultado: Dictionary = Sistema_Manager.Entrenar_Jugador(jugador_id, attr_str)
			if bool(resultado.get("ok", false)):
				var mejora: int = int(resultado.get("mejora", 0))
				Estilo_Manager.reproducir_sfx("star" if mejora > 0 else "ding")
				var msg: String = "%s: %s → %d (+%d). Energía restante: %d%%." % [
					nombre_a, "sube" if mejora > 0 else "sin mejora hoy",
					int(resultado.get("valor", val_a)), mejora,
					int(round(float(resultado.get("energia", 0.0))))]
				construir_ficha_jugador(panel, jugador_id, msg, true)
				panel._Refrescar(false)
			else:
				Estilo_Manager.reproducir_sfx("click")
				construir_ficha_jugador(panel, jugador_id, str(resultado.get("motivo", "")), false))
		grid_entreno.add_child(btn_attr)

	cuerpo.add_child(Estilos_UI.divisor_horizontal())
	var btn_vender := Estilo_Manager.boton(
		"Vender jugador (~%s)" % panel._Euros(int(jugador.get("valor_mercado", 0))),
		"peligro", "hand-coins", Estilos_UI.PELIGRO, 48)
	var nombre_vender: String = str(jugador.get("nombre", ""))
	btn_vender.pressed.connect(func(): panel._Confirmar_Venta(jugador_id, nombre_vender))
	cuerpo.add_child(btn_vender)


# ------------------------------------------------------------------
# Pestaña Mercado (Fichar / Vender / Cantera)
# ------------------------------------------------------------------

static func construir_pestana_mercado(panel: Panel_Manager, club: Dictionary) -> void:
	var resumen: Dictionary = Sistema_Manager.Resumen_Plantilla(club)
	var presupuesto: int = int(club.get("presupuesto", 0))
	var tamano: int = int(resumen.get("tamano", 0))
	var plantilla_completa: bool = tamano >= Datos_Manager.PLANTILLA_MAXIMA

	var cab := panel._Tarjeta()
	var cab_h := HBoxContainer.new()
	cab_h.add_theme_constant_override("separation", 12)
	cab.add_child(cab_h)
	var ct_v := VBoxContainer.new()
	ct_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ct_v.add_theme_constant_override("separation", 2)
	cab_h.add_child(ct_v)
	panel._Titulo_Seccion(ct_v, "Mercado y Cantera")
	if presupuesto < 0:
		ct_v.add_child(Estilos_UI.parrafo(
			"Números rojos: el mercado está bloqueado hasta volver a positivo.",
			12, Estilos_UI.PELIGRO))
	elif plantilla_completa and panel._mercado_modo == "fichar":
		var aviso_h := HBoxContainer.new()
		aviso_h.add_theme_constant_override("separation", 8)
		ct_v.add_child(aviso_h)
		var lbl_av := Estilos_UI.parrafo(
			"Plantilla completa (18/18): vende un futbolista antes de fichar.",
			12, Estilos_UI.AVISO)
		lbl_av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		aviso_h.add_child(lbl_av)
		var btn_ir_vender := Estilo_Manager.boton("Ir a Vender", "oro", "hand-coins",
			Estilo_Manager.COLOR_ORO, 38)
		btn_ir_vender.add_theme_font_size_override("font_size", 11)
		btn_ir_vender.pressed.connect(func():
			panel._mercado_modo = "vender"
			panel.call_deferred("_Refrescar", true))
		aviso_h.add_child(btn_ir_vender)

	cab_h.add_child(panel._Chip_Estadistica("Presupuesto", panel._Euros(presupuesto),
		Estilos_UI.EXITO if presupuesto >= 0 else Estilos_UI.PELIGRO))
	cab_h.add_child(panel._Chip_Estadistica("Plantilla", "%d / %d" % [tamano, Datos_Manager.PLANTILLA_MAXIMA],
		Estilo_Manager.COLOR_MANAGER if not plantilla_completa else Estilo_Manager.COLOR_ORO))

	var modos := Estilo_Manager.selector_chips(
		[["fichar", "Fichar"], ["vender", "Vender"], ["cantera", "Cantera"]],
		panel._mercado_modo, Estilo_Manager.COLOR_MANAGER,
		func(modo_id: String):
			panel._mercado_modo = modo_id
			panel.call_deferred("_Refrescar", false))
	cab.add_child(modos)

	if panel._mercado_modo == "vender":
		_construir_mercado_vender(panel, club)
		return
	if panel._mercado_modo == "cantera":
		_construir_mercado_cantera(panel, club)
		return

	# Filtros visuales en una sola fila apaisada.
	var filtro_card := panel._Tarjeta()
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 10)
	filtro_card.add_child(fh)
	var opciones_rol: Array = [["", "Todos"], ["POR", "POR"], ["DEF", "DEF"], ["MED", "MED"], ["ATA", "ATA"]]
	var roles_ctrl := Estilo_Manager.selector_chips(
		opciones_rol, panel._mercado_filtro_rol, Estilo_Manager.COLOR_MANAGER,
		func(r_id: String):
			panel._mercado_filtro_rol = r_id
			panel._mercado_limite = LIMITE_MERCADO_INICIAL
			panel.call_deferred("_Refrescar", false), false, 11)
	roles_ctrl.size_flags_stretch_ratio = 1.4
	fh.add_child(roles_ctrl)

	var tgl := Estilo_Manager.toggle_pill("Solo asequibles", panel._mercado_solo_asequibles,
		Estilo_Manager.COLOR_MANAGER, func(activo: bool):
			panel._mercado_solo_asequibles = activo
			panel._mercado_limite = LIMITE_MERCADO_INICIAL
			panel.call_deferred("_Refrescar", false))
	tgl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(tgl)

	var tgl_joven := Estilo_Manager.toggle_pill("Sub-23", panel._mercado_solo_jovenes,
		Estilos_UI.AZUL, func(activo: bool):
			panel._mercado_solo_jovenes = activo
			panel._mercado_limite = LIMITE_MERCADO_INICIAL
			panel.call_deferred("_Refrescar", false))
	tgl_joven.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(tgl_joven)

	# Calcular mejor calidad actual por línea en nuestro club para mostrar comparativa.
	var mejor_por_linea: Dictionary = {"POR": 0.0, "DEF": 0.0, "MED": 0.0, "ATA": 0.0}
	for mj in club.get("plantilla", []):
		if mj is Dictionary:
			var l: String = Datos_Manager.Linea_De_Rol(Simulador_Manager._Rol_Principal(mj))
			mejor_por_linea[l] = maxf(float(mejor_por_linea.get(l, 0.0)), float(mj.get("calidad", 0.0)))

	var candidatos: Array = []
	var clubes: Dictionary = Sistema_Manager.Obtener_Clubes()
	for club_id in clubes.keys():
		if str(club_id) == Sistema_Manager.Club_Usuario_Id():
			continue
		var otro = clubes[club_id]
		if not (otro is Dictionary):
			continue
		var plantilla = otro.get("plantilla", [])
		if not (plantilla is Array):
			continue
		for jugador in plantilla:
			if not (jugador is Dictionary):
				continue
			var rol_j: String = Simulador_Manager._Rol_Principal(jugador)
			var linea_j: String = Datos_Manager.Linea_De_Rol(rol_j)
			if panel._mercado_filtro_rol != "" and linea_j != panel._mercado_filtro_rol:
				continue
			if panel._mercado_solo_jovenes and int(jugador.get("edad", 25)) > 23:
				continue
			if panel._mercado_solo_asequibles and int(jugador.get("clausula_rescision", 0)) > presupuesto:
				continue
			candidatos.append({
				"jugador": jugador,
				"club_id": str(club_id),
				"club_nombre": str(otro.get("nombre", "")),
				"club_colores": otro.get("colores", Datos_Manager.COLORES_POR_DEFECTO),
				"club_patron": int(otro.get("escudo_patron", 1)),
				"division": int(otro.get("division", 4)),
				"linea": linea_j
			})

	candidatos.sort_custom(func(a, b):
		return float(a["jugador"].get("calidad", 0.0)) > float(b["jugador"].get("calidad", 0.0)))

	var lista_card := panel._Tarjeta()
	panel._Titulo_Seccion(lista_card, "Jugadores disponibles (%d)" % candidatos.size())
	if candidatos.is_empty():
		lista_card.add_child(Estilos_UI.parrafo(
			"No hay jugadores que coincidan. Prueba a desactivar algún filtro.",
			12, Estilos_UI.TINTA_SUAVE))
	var puede_fichar: bool = not plantilla_completa and presupuesto >= 0
	var grid_cand := GridContainer.new()
	grid_cand.columns = 2
	grid_cand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_cand.add_theme_constant_override("h_separation", 10)
	grid_cand.add_theme_constant_override("v_separation", 10)
	lista_card.add_child(grid_cand)
	var limite: int = mini(panel._mercado_limite, candidatos.size())
	for i in range(limite):
		var ent: Dictionary = candidatos[i]
		var mejora_vs: float = float(ent["jugador"].get("calidad", 0.0)) - float(
			mejor_por_linea.get(str(ent.get("linea", "MED")), 0.0))
		grid_cand.add_child(_fila_mercado(panel, ent, presupuesto, puede_fichar, mejora_vs))

	if candidatos.size() > limite:
		var btn_mas := Estilo_Manager.boton(
			"Mostrar más (%d restantes)" % (candidatos.size() - limite),
			"suave", "plus", Estilo_Manager.COLOR_MANAGER, 44)
		btn_mas.pressed.connect(func():
			panel._mercado_limite += 20
			panel.call_deferred("_Refrescar", false))
		lista_card.add_child(btn_mas)


static func _fila_mercado(panel: Panel_Manager, entrada: Dictionary, presupuesto: int,
		puede_fichar: bool, mejora_vs_mejor: float) -> PanelContainer:
	var jugador: Dictionary = entrada.get("jugador", {})
	var cols: Array = entrada.get("club_colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(entrada.get("club_patron", 1))
	var rol_j: String = Simulador_Manager._Rol_Principal(jugador)
	var col_rol: Color = Datos_Manager.Color_De_Rol(rol_j)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE_2, 14, Estilos_UI.BORDE, 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	v.add_child(cab)

	cab.add_child(Estilo_Manager.crear_retrato_jugador(jugador, cols, patron, 50, false, "retrato", false))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	cab.add_child(info)

	var top_r := HBoxContainer.new()
	top_r.add_theme_constant_override("separation", 6)
	info.add_child(top_r)
	top_r.add_child(Estilos_UI.pill_estado(rol_j, Color(col_rol, 0.14), col_rol))
	var nombre := Estilos_UI.texto(str(jugador.get("nombre", "")), 14, Estilos_UI.TINTA, 700)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top_r.add_child(nombre)

	var club_row := HBoxContainer.new()
	club_row.add_theme_constant_override("separation", 5)
	info.add_child(club_row)
	var mini_c := Cresta_Manager.new()
	mini_c.custom_minimum_size = Vector2(18, 18)
	mini_c.size = Vector2(18, 18)
	mini_c.configurar(str(entrada.get("club_nombre", "")), cols, patron, false)
	club_row.add_child(mini_c)
	club_row.add_child(Estilos_UI.texto("%s · %d años · %s" % [
		str(entrada.get("club_nombre", "")), int(jugador.get("edad", 18)),
		Simulador_Manager.Rasgo_Humano_Jugador(jugador)], 11, Estilos_UI.TINTA_SUAVE, 500))

	var cal_col := VBoxContainer.new()
	cal_col.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_col.add_theme_constant_override("separation", 1)
	cab.add_child(cal_col)
	var cal_lbl := Estilos_UI.titulo("%.1f" % float(jugador.get("calidad", 0.0)), 18,
		Estilos_UI.color_valor(float(jugador.get("calidad", 0.0))))
	cal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cal_col.add_child(cal_lbl)
	var est_lbl := Estilos_UI.texto(panel._Estrellas(int(jugador.get("estrellas", 1))),
		10, Estilo_Manager.COLOR_ORO, 700)
	est_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cal_col.add_child(est_lbl)

	# Precios y comparativa con tu mejor jugador en esa línea.
	var datos_h := HBoxContainer.new()
	datos_h.add_theme_constant_override("separation", 8)
	v.add_child(datos_h)
	var precios_lbl := Estilos_UI.texto("Valor %s · Cláusula %s" % [
		panel._Euros(int(jugador.get("valor_mercado", 0))),
		panel._Euros(int(jugador.get("clausula_rescision", 0)))],
		11, Estilos_UI.TINTA_SUAVE, 600)
	precios_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	datos_h.add_child(precios_lbl)
	if mejora_vs_mejor > 0.5:
		datos_h.add_child(Estilos_UI.pill_estado("+%.1f vs tu mejor %s" % [mejora_vs_mejor, str(entrada.get("linea", "MED"))],
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	v.add_child(acciones)
	var id_local: String = str(jugador.get("id", ""))
	var btn_oferta := Estilo_Manager.boton("Hacer oferta", "suave", "message-circle",
		Estilo_Manager.COLOR_MANAGER, 44)
	btn_oferta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_oferta.disabled = not puede_fichar
	btn_oferta.pressed.connect(func(): panel._Abrir_Modal_Oferta(id_local))
	acciones.add_child(btn_oferta)

	var importe_clausula: int = int(jugador.get("clausula_rescision", 0))
	var btn_clausula := Estilo_Manager.boton("Cláusula %s" % panel._Euros(importe_clausula),
		"oro", "hand-coins", Estilo_Manager.COLOR_ORO, 44)
	btn_clausula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_clausula.disabled = not puede_fichar or presupuesto < importe_clausula
	var nombre_clausula: String = str(jugador.get("nombre", ""))
	btn_clausula.pressed.connect(func():
		panel._Confirmar_Clausula(id_local, nombre_clausula, importe_clausula))
	acciones.add_child(btn_clausula)
	return card


static func _construir_mercado_vender(panel: Panel_Manager, club: Dictionary) -> void:
	var card := panel._Tarjeta()
	panel._Titulo_Seccion(card, "Vender futbolistas")
	card.add_child(Estilos_UI.parrafo(
		"Los clubes pagan entre el 90% y el 110% del valor de mercado. Necesitas al menos 15 futbolistas para vender y no puedes quedarte sin portero.",
		12, Estilos_UI.TINTA_SUAVE))
	var cols: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club.get("escudo_patron", 1))
	var plantilla = club.get("plantilla", [])
	var lista: Array = []
	if plantilla is Array:
		for jugador in plantilla:
			if jugador is Dictionary:
				lista.append(jugador)
	lista.sort_custom(func(a, b):
		return float(a.get("calidad", 0.0)) > float(b.get("calidad", 0.0)))
	var puede_vender_general: bool = lista.size() > Datos_Manager.PLANTILLA_MINIMA
	var porteros: int = Simulador_Manager.Contar_Rol(lista, "POR")

	var grid_v := GridContainer.new()
	grid_v.columns = 2
	grid_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_v.add_theme_constant_override("h_separation", 10)
	grid_v.add_theme_constant_override("v_separation", 8)
	card.add_child(grid_v)

	for jugador in lista:
		var rol_j: String = Simulador_Manager._Rol_Principal(jugador)
		var unico_por: bool = rol_j == "POR" and porteros <= 1
		var fila := PanelContainer.new()
		fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 10)
		m.add_theme_constant_override("margin_right", 10)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		fila.add_child(m)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		m.add_child(h)
		h.add_child(Estilo_Manager.crear_retrato_jugador(jugador, cols, patron, 44, false, "retrato", true))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(Estilos_UI.texto(str(jugador.get("nombre", "")), 13, Estilos_UI.TINTA, 700))
		v.add_child(Estilos_UI.texto("%s · %d años · Cal %.1f · ~%s" % [
			rol_j, int(jugador.get("edad", 18)), float(jugador.get("calidad", 0.0)),
			panel._Euros(int(jugador.get("valor_mercado", 0)))],
			11, Estilos_UI.TINTA_SUAVE, 500))
		var btn := Estilo_Manager.boton("Vender", "peligro", "hand-coins", Estilos_UI.PELIGRO, 44)
		btn.add_theme_font_size_override("font_size", 12)
		btn.disabled = not puede_vender_general or unico_por
		var id_local: String = str(jugador.get("id", ""))
		var nombre_local: String = str(jugador.get("nombre", ""))
		btn.pressed.connect(func(): panel._Confirmar_Venta(id_local, nombre_local))
		h.add_child(btn)
		grid_v.add_child(fila)


static func _construir_mercado_cantera(panel: Panel_Manager, club: Dictionary) -> void:
	var card := panel._Tarjeta()
	panel._Titulo_Seccion(card, "Academia y ojeador de cantera")
	var inst = club.get("instalaciones", {})
	var nivel_cantera: int = int(inst.get("cantera", 1)) if inst is Dictionary else 1
	var div: int = clampi(int(club.get("division", 4)), 1, 4)
	var coste_ojeo: int = int(Datos_Manager.COSTE_OJEAR_CANTERA.get(div, 1800))
	var candidatos = club.get("cantera_candidatos", [])
	var ojeado_hoy: bool = int(club.get("cantera_dia", -1)) == Variables_Dinamicas.Minute_Day \
		and candidatos is Array and not candidatos.is_empty()

	card.add_child(Estilos_UI.parrafo(
		"Envía a tus ojeadores a buscar 3 jóvenes talentos (16–20 años) para subirlos al primer equipo. Academia actual: Nivel %d/%d." % [
			nivel_cantera, Datos_Manager.INSTALACIONES_NIVEL_MAX],
		12, Estilos_UI.TINTA_SUAVE))

	if not ojeado_hoy:
		var btn_ojear := Estilo_Manager.boton("Ojear cantera (%s)" % panel._Euros(coste_ojeo),
			"primario", "sparkles", Estilo_Manager.COLOR_MANAGER, 48)
		btn_ojear.disabled = int(club.get("presupuesto", 0)) < coste_ojeo
		btn_ojear.pressed.connect(func():
			var res: Dictionary = Sistema_Manager.Ojear_Cantera()
			if bool(res.get("ok", false)):
				Estilo_Manager.reproducir_sfx("ding")
				panel.call_deferred("_Refrescar", false)
			else:
				panel._Mostrar_Info("No se pudo ojear", str(res.get("motivo", ""))))
		card.add_child(btn_ojear)
		return

	var cols: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club.get("escudo_patron", 1))
	var plantilla = club.get("plantilla", [])
	var hay_hueco: bool = plantilla is Array and plantilla.size() < Datos_Manager.PLANTILLA_MAXIMA

	var grid_c := GridContainer.new()
	grid_c.columns = 3
	grid_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_c.add_theme_constant_override("h_separation", 12)
	grid_c.add_theme_constant_override("v_separation", 10)
	card.add_child(grid_c)

	for i in range(candidatos.size()):
		var cand = candidatos[i]
		if not (cand is Dictionary):
			continue
		var rol_c: String = Simulador_Manager._Rol_Principal(cand)
		var fila := PanelContainer.new()
		fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 12)
		m.add_theme_constant_override("margin_right", 12)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_bottom", 10)
		fila.add_child(m)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		m.add_child(cv)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		cv.add_child(h)
		h.add_child(Estilo_Manager.crear_retrato_jugador(cand, cols, patron, 52, false, "retrato", true))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(Estilos_UI.texto("%s (%s)" % [str(cand.get("nombre", "")), rol_c],
			13, Estilos_UI.TINTA, 700))
		info.add_child(Estilos_UI.texto("%d años · Cal %.1f · %s" % [
			int(cand.get("edad", 18)), float(cand.get("calidad", 0.0)),
			panel._Estrellas(int(cand.get("estrellas", 1)))],
			11, Estilos_UI.TINTA_SUAVE, 600))
		info.add_child(Estilos_UI.texto("Salario %s/sem" % panel._Euros(int(cand.get("salario_semanal", 50))),
			11, Estilo_Manager.COLOR_MANAGER_OSCURO, 600))
		var idx: int = i
		var btn_subir := Estilo_Manager.boton("Subir al primer equipo", "exito", "plus", Estilos_UI.EXITO, 42)
		btn_subir.disabled = not hay_hueco
		btn_subir.pressed.connect(func():
			var res: Dictionary = Sistema_Manager.Fichar_Canterano(idx)
			if bool(res.get("ok", false)):
				Estilo_Manager.reproducir_sfx("star")
				panel._Mostrar_Info("Canterano incorporado", "%s ya entrena con el primer equipo." % str(cand.get("nombre", "")))
				panel.call_deferred("_Refrescar", false)
			else:
				panel._Mostrar_Info("No se pudo incorporar", str(res.get("motivo", ""))))
		cv.add_child(btn_subir)
		grid_c.add_child(fila)


# ------------------------------------------------------------------
# Modal de Oferta legible (sin SpinBox oscuro)
# ------------------------------------------------------------------

static func construir_modal_oferta(panel: Panel_Manager, jugador_id: String) -> void:
	panel._Cerrar_Modal_Oferta()
	var club_id: String = Sistema_Manager.Club_De_Jugador(jugador_id)
	var jugador: Dictionary = Sistema_Manager.Obtener_Jugador_De_Club(club_id, jugador_id)
	if jugador.is_empty():
		return
	var club_origen: Dictionary = Sistema_Manager.Obtener_Club(club_id)
	var cols: Array = club_origen.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club_origen.get("escudo_patron", 1))
	var valor_mercado: int = int(jugador.get("valor_mercado", 1000))
	var clausula: int = int(jugador.get("clausula_rescision", 1500))

	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.07, 0.11, 0.68)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 210
	panel.add_child(overlay)
	panel._modal_oferta = overlay

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(650, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE, 20, Estilos_UI.BORDE_FUERTE, 1, 5))
	centro.add_child(card)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	cab.add_child(Estilo_Manager.crear_retrato_jugador(jugador, cols, patron, 58, false, "retrato", false))
	var tit_col := VBoxContainer.new()
	tit_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_col.add_theme_constant_override("separation", 2)
	cab.add_child(tit_col)
	tit_col.add_child(Estilos_UI.titulo("Oferta por %s" % str(jugador.get("nombre", "")), 18, Estilos_UI.TINTA))
	tit_col.add_child(Estilos_UI.texto("%s · %s · %d años · Cal %.1f" % [
		Sistema_Manager.Obtener_Nombre_Club(club_id),
		Simulador_Manager._Rol_Principal(jugador),
		int(jugador.get("edad", 18)), float(jugador.get("calidad", 0.0))],
		12, Estilos_UI.TINTA_SUAVE, 600))
	var cerrar := Estilos_UI.boton_icono("x", Estilos_UI.TINTA, 44)
	cerrar.pressed.connect(panel._Cerrar_Modal_Oferta)
	cab.add_child(cerrar)

	panel._Fila_Dato(v, "Valor de mercado", panel._Euros(valor_mercado), Estilos_UI.AZUL)
	panel._Fila_Dato(v, "Cláusula obligatoria", panel._Euros(clausula), Estilo_Manager.COLOR_ORO)

	var oferta_estado := {"importe": maxi(500, int(round(float(valor_mercado) * 1.05 / 100.0)) * 100)}
	var lbl_importe := Estilos_UI.titulo(panel._Euros(int(oferta_estado["importe"])), 28,
		Estilo_Manager.COLOR_MANAGER_OSCURO)
	lbl_importe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var eval_pill := Estilos_UI.pill_estado("Evaluando...", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA)
	eval_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var eval_lbl: Label = null
	for h in eval_pill.get_children():
		if h is Label:
			eval_lbl = h
			break

	var actualizar_eval := func():
		var monto: int = int(oferta_estado["importe"])
		lbl_importe.text = panel._Euros(monto)
		var prev: Dictionary = Sistema_Manager.Evaluar_Oferta_Preview(jugador_id, monto)
		var ok: bool = bool(prev.get("aceptada", false))
		var st_p: StyleBoxFlat = Estilos_UI.caja(
			Estilos_UI.EXITO_SUAVE if ok else Estilos_UI.AVISO_SUAVE,
			999, Color(Estilos_UI.EXITO if ok else Estilos_UI.AVISO, 0.25), 1, 0)
		st_p.content_margin_left = 12
		st_p.content_margin_right = 12
		st_p.content_margin_top = 5
		st_p.content_margin_bottom = 5
		eval_pill.add_theme_stylebox_override("panel", st_p)
		if eval_lbl != null:
			eval_lbl.text = str(prev.get("texto", ""))
			eval_lbl.add_theme_color_override("font_color",
				Estilos_UI.EXITO_OSCURO if ok else Color("#92400e"))

	var importe_box := PanelContainer.new()
	importe_box.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilos_UI.SUPERFICIE_2, 14, Estilos_UI.BORDE, 1, 0))
	v.add_child(importe_box)
	var im := MarginContainer.new()
	im.add_theme_constant_override("margin_left", 12)
	im.add_theme_constant_override("margin_right", 12)
	im.add_theme_constant_override("margin_top", 10)
	im.add_theme_constant_override("margin_bottom", 10)
	importe_box.add_child(im)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 8)
	im.add_child(iv)
	var cap := Estilos_UI.texto("TU OFERTA", 10, Estilos_UI.TINTA_FANTASMA, 700)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	iv.add_child(cap)
	iv.add_child(lbl_importe)
	iv.add_child(eval_pill)

	var paso: int = maxi(500, int(round(float(valor_mercado) * 0.05 / 100.0)) * 100)
	var fila_step := HBoxContainer.new()
	fila_step.add_theme_constant_override("separation", 6)
	iv.add_child(fila_step)
	for delta_info in [
		[-paso * 2, "−%s" % panel._Formatear_Numero(paso * 2)],
		[-paso, "−%s" % panel._Formatear_Numero(paso)],
		[paso, "+%s" % panel._Formatear_Numero(paso)],
		[paso * 2, "+%s" % panel._Formatear_Numero(paso * 2)]
	]:
		var d_val: int = int(delta_info[0])
		var b_s := Estilo_Manager.boton(str(delta_info[1]), "chip", "", Estilos_UI.TINTA, 42)
		b_s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_s.add_theme_font_size_override("font_size", 11)
		b_s.pressed.connect(func():
			Estilo_Manager.reproducir_sfx("click")
			oferta_estado["importe"] = maxi(500, int(oferta_estado["importe"]) + d_val)
			actualizar_eval.call())
		fila_step.add_child(b_s)

	actualizar_eval.call()

	var club_usuario: Dictionary = Sistema_Manager.Club_Usuario()
	var plantilla_usuario = club_usuario.get("plantilla", [])
	var plantilla_llena: bool = plantilla_usuario is Array \
		and plantilla_usuario.size() >= Datos_Manager.PLANTILLA_MAXIMA
	var presupuesto_usuario: int = int(club_usuario.get("presupuesto", 0))

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	v.add_child(acciones)
	var btn_enviar := Estilo_Manager.boton("Enviar oferta", "exito", "message-circle",
		Estilos_UI.EXITO, 48)
	btn_enviar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_enviar.disabled = plantilla_llena or presupuesto_usuario < 0
	btn_enviar.pressed.connect(func():
		panel._Enviar_Oferta(jugador_id, int(oferta_estado["importe"])))
	acciones.add_child(btn_enviar)

	var btn_clausula := Estilo_Manager.boton("Pagar cláusula", "oro", "hand-coins",
		Estilo_Manager.COLOR_ORO, 48)
	btn_clausula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nombre_j: String = str(jugador.get("nombre", ""))
	btn_clausula.disabled = plantilla_llena or presupuesto_usuario < clausula
	btn_clausula.pressed.connect(func():
		panel._Cerrar_Modal_Oferta()
		panel._Confirmar_Clausula(jugador_id, nombre_j, clausula))
	acciones.add_child(btn_clausula)


# ------------------------------------------------------------------
# Pestaña Liga (Zonas, Emparejamientos y Líderes)
# ------------------------------------------------------------------

static func construir_pestana_liga(panel: Panel_Manager) -> void:
	if panel._liga_division < 1 or panel._liga_division > 4:
		panel._liga_division = Sistema_Manager.Division_Usuario()

	var div_usr: int = Sistema_Manager.Division_Usuario()
	var selector_card := panel._Tarjeta()
	panel._Titulo_Seccion(selector_card, "Divisiones")
	var opciones_div: Array = []
	for d in range(1, 5):
		var etiqueta: String = Datos_Manager.Nombre_Division(d)
		if d == div_usr:
			etiqueta = "★ " + etiqueta
		opciones_div.append([str(d), etiqueta])
	selector_card.add_child(Estilo_Manager.selector_chips(
		opciones_div, str(panel._liga_division), Estilo_Manager.COLOR_MANAGER,
		func(d_str: String):
			panel._liga_division = int(d_str)
			panel.call_deferred("_Refrescar", false), true, 12))
	selector_card.add_child(Estilos_UI.parrafo(
		"Los 2 primeros ascienden y los 2 últimos descienden. En la jornada 4 (playoff) el 1º vs 2º decide el título y el 3º vs 4º la permanencia.",
		12, Estilos_UI.TINTA_SUAVE))

	# Distribución horizontal en 2 columnas.
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	panel._contenido.add_child(split)
	var col_izq := panel._Crear_Columna(split, 1.2)
	var col_der := panel._Crear_Columna(split, 1.0)

	# Tabla de clasificación con franja de zona y PJ/V/E/D.
	var clasificacion: Array = Sistema_Manager.Obtener_Clasificacion(panel._liga_division)
	var tabla := panel._Tarjeta(Color.WHITE, col_izq)
	panel._Titulo_Seccion(tabla, "Clasificación · %s" % Datos_Manager.Nombre_Division(panel._liga_division))
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 5)
	tabla.add_child(cab)
	panel._Celda_Tabla(cab, "#", 22, Estilos_UI.TINTA_FANTASMA, true)
	panel._Celda_Tabla(cab, "Club", 0, Estilos_UI.TINTA_FANTASMA, true)
	panel._Celda_Tabla(cab, "PJ", 26, Estilos_UI.TINTA_FANTASMA, true)
	panel._Celda_Tabla(cab, "V-E-D", 54, Estilos_UI.TINTA_FANTASMA, true)
	panel._Celda_Tabla(cab, "DG", 34, Estilos_UI.TINTA_FANTASMA, true)
	panel._Celda_Tabla(cab, "Pts", 34, Estilos_UI.TINTA_FANTASMA, true)

	for entrada in clasificacion:
		if not (entrada is Dictionary):
			continue
		var pos: int = int(entrada.get("posicion", 0))
		var es_usuario: bool = bool(entrada.get("es_usuario", false))
		var sube: bool = panel._liga_division > 1 and pos <= 2
		var baja: bool = panel._liga_division < 4 and pos >= 3

		var fila := PanelContainer.new()
		fila.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Estilo_Manager.COLOR_MANAGER_SUAVE if es_usuario else Estilos_UI.SUPERFICIE_2,
			10, Estilo_Manager.COLOR_MANAGER if es_usuario else Estilos_UI.BORDE,
			1, 0))
		tabla.add_child(fila)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 6)
		m.add_theme_constant_override("margin_right", 8)
		m.add_theme_constant_override("margin_top", 6)
		m.add_theme_constant_override("margin_bottom", 6)
		fila.add_child(m)
		var fila_h := HBoxContainer.new()
		fila_h.add_theme_constant_override("separation", 5)
		m.add_child(fila_h)

		# Indicador visual de zona (ascenso verde / descenso rojo).
		var marca := ColorRect.new()
		marca.custom_minimum_size = Vector2(4, 22)
		marca.color = Estilos_UI.EXITO if sube else (Estilos_UI.PELIGRO if baja else Color("#94a3b8"))
		fila_h.add_child(marca)

		var color_fila: Color = Estilo_Manager.COLOR_MANAGER_OSCURO if es_usuario else Estilos_UI.TINTA
		panel._Celda_Tabla(fila_h, str(pos), 18, color_fila, es_usuario)
		var mini := Cresta_Manager.new()
		mini.custom_minimum_size = Vector2(24, 24)
		mini.size = Vector2(24, 24)
		mini.configurar(str(entrada.get("nombre", "")),
			entrada.get("colores", Datos_Manager.COLORES_POR_DEFECTO),
			int(entrada.get("escudo_patron", 1)), false)
		fila_h.add_child(mini)
		var nombre := Estilos_UI.texto(str(entrada.get("nombre", "")), 12,
			color_fila, 700 if es_usuario else 600)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		fila_h.add_child(nombre)

		panel._Celda_Tabla(fila_h, str(int(entrada.get("partidos", 0))), 26, color_fila, false)
		panel._Celda_Tabla(fila_h, "%d-%d-%d" % [
			int(entrada.get("victorias", 0)), int(entrada.get("empates", 0)),
			int(entrada.get("derrotas", 0))], 54, color_fila, false)
		panel._Celda_Tabla(fila_h, "%+d" % int(entrada.get("diferencia", 0)), 34, color_fila, false)
		panel._Celda_Tabla(fila_h, str(int(entrada.get("puntos", 0))), 34, color_fila, true)

	var leyenda := HBoxContainer.new()
	leyenda.add_theme_constant_override("separation", 10)
	tabla.add_child(leyenda)
	if panel._liga_division > 1:
		leyenda.add_child(Estilos_UI.pill_estado("1º–2º Ascenso", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
	if panel._liga_division < 4:
		leyenda.add_child(Estilos_UI.pill_estado("3º–4º Descenso", Estilos_UI.PELIGRO_SUAVE, Estilos_UI.PELIGRO))

	# Emparejamientos de la próxima jornada (columna izquierda).
	var jornada_act: int = Sistema_Manager.Obtener_Jornada()
	var parejas: Array = Sistema_Manager.Obtener_Emparejamientos_Division(panel._liga_division, jornada_act)
	if not parejas.is_empty():
		var emparej_card := panel._Tarjeta(Color.WHITE, col_izq)
		panel._Titulo_Seccion(emparej_card, "Emparejamientos · Jornada %d/4" % (jornada_act + 1))
		for par in parejas:
			var cl_id: String = str(par.get("local_id", ""))
			var cv_id: String = str(par.get("visitante_id", ""))
			var cl: Dictionary = Sistema_Manager.Obtener_Club(cl_id)
			var cv: Dictionary = Sistema_Manager.Obtener_Club(cv_id)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			emparej_card.add_child(h)
			var cr_l := Cresta_Manager.new()
			cr_l.custom_minimum_size = Vector2(24, 24)
			cr_l.configurar(str(cl.get("nombre", "")), cl.get("colores", []), int(cl.get("escudo_patron", 1)), false)
			h.add_child(cr_l)
			var nl := Estilos_UI.texto(str(cl.get("nombre", "")), 12,
				Estilo_Manager.COLOR_MANAGER_OSCURO if cl_id == Sistema_Manager.Club_Usuario_Id() else Estilos_UI.TINTA,
				700 if cl_id == Sistema_Manager.Club_Usuario_Id() else 600)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(nl)
			h.add_child(Estilos_UI.pill_estado("VS", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE))
			var nv := Estilos_UI.texto(str(cv.get("nombre", "")), 12,
				Estilo_Manager.COLOR_MANAGER_OSCURO if cv_id == Sistema_Manager.Club_Usuario_Id() else Estilos_UI.TINTA,
				700 if cv_id == Sistema_Manager.Club_Usuario_Id() else 600)
			nv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(nv)
			var cr_v := Cresta_Manager.new()
			cr_v.custom_minimum_size = Vector2(24, 24)
			cr_v.configurar(str(cv.get("nombre", "")), cv.get("colores", []), int(cv.get("escudo_patron", 1)), false)
			h.add_child(cr_v)

	# Máximos goleadores y asistentes (columna derecha).
	var lideres: Dictionary = Sistema_Manager.Obtener_Lideres_Division(panel._liga_division)
	var goleadores: Array = lideres.get("goleadores", [])
	var asistentes: Array = lideres.get("asistentes", [])
	if not goleadores.is_empty() or not asistentes.is_empty():
		var lid_card := panel._Tarjeta(Color.WHITE, col_der)
		panel._Titulo_Seccion(lid_card, "Líderes de la división")
		if not goleadores.is_empty():
			lid_card.add_child(Estilos_UI.texto("MÁXIMOS GOLEADORES", 10, Estilo_Manager.COLOR_ORO, 700))
			for entry in goleadores:
				_fila_lider(lid_card, entry, "goles", Estilo_Manager.COLOR_ORO)
		if not asistentes.is_empty():
			lid_card.add_child(Estilos_UI.texto("MÁXIMOS ASISTENTES", 10, Estilos_UI.AZUL, 700))
			for entry2 in asistentes:
				_fila_lider(lid_card, entry2, "asist.", Estilos_UI.AZUL)

	# Calendario y resultados.
	var calendario := panel._Tarjeta(Color.WHITE, col_izq)
	panel._Titulo_Seccion(calendario, "Calendario y partido")
	calendario.add_child(Estilos_UI.parrafo(Sistema_Manager.Obtener_Resumen_Calendario(),
		12, Estilos_UI.TINTA_SUAVE))
	calendario.add_child(Estilos_UI.texto(Sistema_Manager.Obtener_Proximo_Partido_Texto(),
		13, Estilo_Manager.COLOR_MANAGER_OSCURO, 700))
	var pendiente: bool = Sistema_Manager.Puede_Jugar_Manual()
	var btn_jugar := Estilo_Manager.boton("Jugar partido oficial",
		"exito" if pendiente else "secundario", "play",
		Estilos_UI.EXITO if pendiente else Estilos_UI.TINTA_SUAVE, 48)
	btn_jugar.disabled = not pendiente
	btn_jugar.pressed.connect(panel._Jugar_Partido)
	calendario.add_child(btn_jugar)

	var resultados := panel._Tarjeta(Color.WHITE, col_der)
	panel._Titulo_Seccion(resultados, "Resultados recientes")
	var ultimos: Array = Sistema_Manager.Obtener_Ultimos_Resultados()
	if ultimos.is_empty():
		resultados.add_child(Estilos_UI.parrafo("Sin partidos disputados todavía.",
			12, Estilos_UI.TINTA_SUAVE))
	else:
		for i in range(mini(6, ultimos.size())):
			var r: Dictionary = ultimos[i]
			if not (r is Dictionary):
				continue
			var color_r: Color = Estilos_UI.EXITO
			if str(r.get("resultado", "")) == "Derrota":
				color_r = Estilos_UI.PELIGRO
			elif str(r.get("resultado", "")) == "Empate":
				color_r = Estilos_UI.AVISO
			panel._Fila_Dato(resultados, "T%d · J%d · %s" % [
				int(r.get("temporada", 1)), int(r.get("jornada", 1)),
				str(r.get("rival", ""))], "%s · %s" % [
					str(r.get("resultado", "")), str(r.get("marcador", ""))], color_r)


static func _fila_lider(parent: VBoxContainer, entry: Dictionary, sufijo: String,
		color: Color) -> void:
	var j: Dictionary = entry.get("jugador", {})
	var cols: Array = entry.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(entry.get("patron", 1))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	h.add_child(Estilo_Manager.crear_retrato_jugador(j, cols, patron, 32, false, "retrato", false))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	col.add_child(Estilos_UI.texto(str(j.get("nombre", "")), 12, Estilos_UI.TINTA, 700))
	col.add_child(Estilos_UI.texto(str(entry.get("club_nombre", "")), 10, Estilos_UI.TINTA_SUAVE, 500))
	h.add_child(Estilos_UI.pill_estado("%d %s" % [int(entry.get("valor", 0)), sufijo],
		Color(color, 0.14), color))
