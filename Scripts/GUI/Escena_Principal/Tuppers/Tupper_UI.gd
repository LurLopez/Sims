class_name Tupper_UI
extends RefCounted

# Filas reutilizables para la despensa de tuppers (modal y pestaña del Perfil).


static func crear_fila(_indice: int, tupper: Dictionary, seleccionado: bool,
		on_elegir: Callable, on_tirar: Callable) -> Control:
	var caducado: bool = Alimentacion.Es_Tupper_Caducado(tupper)
	var calidad: int = int(tupper.get("calidad", 1))
	var restante: float = float(tupper.get("porcentaje_restante", 100.0))
	var acento: Color = Estilos_UI.PELIGRO if caducado else Estilos_UI.EXITO
	var fondo: Color = Color("#fef2f2") if caducado else Estilos_UI.SUPERFICIE
	var borde: Color = Estilos_UI.PELIGRO if caducado else (Estilos_UI.EXITO if seleccionado else Estilos_UI.BORDE)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 104)
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(fondo, 14, borde, 2 if seleccionado or caducado else 1, 1))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margen)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	margen.add_child(h)

	h.add_child(Estilos_UI.badge_icono("package", 38, 19, acento, Color.WHITE, 10))

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)

	var titulo := Estilos_UI.texto("Tupper #%d · Calidad %d" % [int(tupper.get("id", 0)), calidad],
		14, Estilos_UI.TINTA, 700)
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(titulo)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 12)
	bar.show_percentage = false
	bar.value = restante
	bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(acento))
	v.add_child(bar)

	var detalle := Estilos_UI.texto("Restante %s · %s" % [
		Alimentacion.Formatear_Porcentaje(restante),
		Alimentacion.Formatear_Caducidad(tupper)], 11,
		Estilos_UI.PELIGRO if caducado else Estilos_UI.TINTA_SUAVE, 500)
	detalle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(detalle)

	var acciones := VBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_CENTER
	acciones.add_theme_constant_override("separation", 5)
	h.add_child(acciones)

	var btn_elegir := Estilos_UI.boton("En uso" if seleccionado else "Elegir",
		"exito" if seleccionado else "secundario", "check" if seleccionado else "", acento, 34)
	btn_elegir.custom_minimum_size = Vector2(104, 34)
	btn_elegir.disabled = seleccionado
	btn_elegir.set_meta("_estilo_propio", true)
	btn_elegir.pressed.connect(on_elegir)
	acciones.add_child(btn_elegir)

	var btn_tirar := Estilos_UI.boton("Tirar", "peligro", "x", Estilos_UI.PELIGRO, 34)
	btn_tirar.custom_minimum_size = Vector2(104, 34)
	btn_tirar.set_meta("_estilo_propio", true)
	btn_tirar.pressed.connect(on_tirar)
	acciones.add_child(btn_tirar)

	return panel
