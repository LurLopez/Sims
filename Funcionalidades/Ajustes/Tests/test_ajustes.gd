extends GutTest

# Tests de los ajustes globales de audio (música y efectos de sonido).

var _vol_musica: float = 0.85
var _vol_sfx: float = 0.85
var _mudo_musica: bool = false
var _mudo_sfx: bool = false


func before_each() -> void:
	_vol_musica = Ajustes.Obtener_Volumen_Musica()
	_vol_sfx = Ajustes.Obtener_Volumen_SFX()
	_mudo_musica = Ajustes.Esta_Silenciado_Musica()
	_mudo_sfx = Ajustes.Esta_Silenciado_SFX()


func after_each() -> void:
	Ajustes.Establecer_Volumen_Musica(_vol_musica)
	Ajustes.Establecer_Volumen_SFX(_vol_sfx)
	Ajustes.Establecer_Silencio_Musica(_mudo_musica)
	Ajustes.Establecer_Silencio_SFX(_mudo_sfx)


func test_buses_de_audio_existen_y_van_a_master() -> void:
	var idx_musica := AudioServer.get_bus_index(Ajustes.BUS_MUSICA)
	var idx_sfx := AudioServer.get_bus_index(Ajustes.BUS_SFX)
	assert_ne(idx_musica, -1, "El bus de música debe existir")
	assert_ne(idx_sfx, -1, "El bus de efectos debe existir")
	assert_eq(AudioServer.get_bus_send(idx_musica), "Master")
	assert_eq(AudioServer.get_bus_send(idx_sfx), "Master")


func test_volumen_musica_aplica_al_bus() -> void:
	Ajustes.Establecer_Silencio_Musica(false)
	Ajustes.Establecer_Volumen_Musica(0.5)

	var idx := AudioServer.get_bus_index(Ajustes.BUS_MUSICA)
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(idx))


func test_volumen_sfx_aplica_al_bus_y_se_silencia() -> void:
	var idx := AudioServer.get_bus_index(Ajustes.BUS_SFX)
	Ajustes.Establecer_Silencio_SFX(false)
	Ajustes.Establecer_Volumen_SFX(0.4)
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), linear_to_db(0.4), 0.01)
	assert_false(AudioServer.is_bus_mute(idx))

	Ajustes.Establecer_Silencio_SFX(true)
	assert_true(Ajustes.Esta_Silenciado_SFX())
	assert_true(AudioServer.is_bus_mute(idx))


func test_volumen_cero_silencia_el_bus() -> void:
	Ajustes.Establecer_Silencio_SFX(false)
	Ajustes.Establecer_Volumen_SFX(0.0)
	var idx := AudioServer.get_bus_index(Ajustes.BUS_SFX)
	assert_true(AudioServer.is_bus_mute(idx),
		"Un volumen a 0 debe dejar el bus completamente en silencio")


func test_restablecer_audio_vuelve_a_los_valores_por_defecto() -> void:
	Ajustes.Establecer_Volumen_Musica(0.2)
	Ajustes.Establecer_Volumen_SFX(0.3)
	Ajustes.Establecer_Silencio_Musica(true)
	Ajustes.Establecer_Silencio_SFX(true)

	Ajustes.Restablecer_Audio()

	assert_almost_eq(Ajustes.Obtener_Volumen_Musica(), Ajustes.VOLUMEN_MUSICA_PREDETERMINADO, 0.001)
	assert_almost_eq(Ajustes.Obtener_Volumen_SFX(), Ajustes.VOLUMEN_SFX_PREDETERMINADO, 0.001)
	assert_false(Ajustes.Esta_Silenciado_Musica())
	assert_false(Ajustes.Esta_Silenciado_SFX())


func test_musica_delega_el_volumen_y_el_silencio_en_ajustes() -> void:
	Musica.Establecer_Volumen(0.3)
	assert_almost_eq(Ajustes.Obtener_Volumen_Musica(), 0.3, 0.001)

	Musica.Establecer_Silencio(true)
	assert_true(Ajustes.Esta_Silenciado_Musica())
	Musica.Establecer_Silencio(false)
	assert_false(Ajustes.Esta_Silenciado_Musica())


func test_sonidos_cocina_usan_el_bus_sfx() -> void:
	var sonidos := Sonidos_Cocina.new()
	add_child_autofree(sonidos)
	await wait_process_frames(1)
	assert_gt(sonidos._players.size(), 0)
	for reproductor in sonidos._players:
		assert_eq(reproductor.bus, Ajustes.BUS_SFX,
			"Los efectos de la cocina deben pasar por el bus SFX")


func test_panel_ajustes_se_construye_y_cambia_el_volumen() -> void:
	var panel := Panel_Ajustes.new()
	add_child_autofree(panel)
	await wait_process_frames(2)

	assert_eq(panel.layer, 120)
	assert_not_null(panel._barra_musica)
	assert_not_null(panel._barra_sfx)
	assert_not_null(panel._lbl_musica)
	assert_not_null(panel._lbl_sfx)

	panel._barra_musica.Establecer_Valor(0.35, true)
	assert_almost_eq(Ajustes.Obtener_Volumen_Musica(), 0.35, 0.001)
	assert_eq(panel._lbl_musica.text, "35%")

	panel._barra_sfx.Establecer_Valor(0.6, true)
	assert_almost_eq(Ajustes.Obtener_Volumen_SFX(), 0.6, 0.001)
	assert_eq(panel._lbl_sfx.text, "60%")


func test_panel_ajustes_no_se_oculta_al_cambiar_de_pantalla() -> void:
	var raiz := Control.new()
	add_child_autofree(raiz)
	var panel := Panel_Ajustes.new()
	raiz.add_child(panel)
	await wait_process_frames(2)

	assert_true(panel.is_in_group(Gestionar_Visibilidad.GRUPO_OVERLAY_MODAL),
		"El panel debe registrarse como overlay modal persistente")

	Gestionar_Visibilidad.Recursivo_Desvisibilizar(raiz)

	assert_true(panel.get_node("Velo").visible,
		"El modal de ajustes no debe desaparecer al cambiar de pestaña")


func test_botones_de_cabecera_siguen_visibles_al_volver_al_inicio() -> void:
	var raiz := Control.new()
	add_child_autofree(raiz)
	for nombre in [
		"Barra_Abajo", "Fondo", "Moneda", "Dinero_Label", "Boton_Perfil",
		"Economia_Button", "Calendario_Button", "Carrera_Button",
		"Boton_Ajustes_Header",
	]:
		var nodo := Control.new()
		nodo.name = nombre
		raiz.add_child(nodo)

	var boton_ajustes: Control = raiz.get_node("Boton_Ajustes_Header")
	boton_ajustes.visible = false

	Gestionar_Visibilidad.Visibilizar_Lo_Basico(raiz)

	assert_true(boton_ajustes.visible,
		"El engranaje de ajustes debe seguir visible al cambiar de pestaña")


func test_cabecera_principal_agrupa_la_musica_y_los_efectos_en_ajustes() -> void:
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	raiz._Redisenar_Superior()

	assert_null(raiz.get_node_or_null("Boton_Musica_Header"),
		"El altavoz de la cabecera ya no debe existir por separado")
	var boton_ajustes := raiz.get_node_or_null("Boton_Ajustes_Header") as Button
	assert_not_null(boton_ajustes, "La cabecera debe tener un único engranaje de ajustes")
	assert_eq(boton_ajustes.icon, Estilos_UI.icono("settings"),
		"El acceso debe usar el icono de engranaje")
	assert_true(boton_ajustes.pressed.is_connected(Callable(raiz, "_on_boton_ajustes_pressed")),
		"El engranaje debe abrir el panel con música y efectos")
	raiz.free()

