extends GutTest

# ============================================================================
# Tests de la pestaña Tienda > Bienestar.
#
# Cubren el catálogo, los anuncios simulados, los servicios pagados con euros,
# el rejuvenecimiento del Sim y la UI. No usan red ni SDK: el proveedor de
# anuncios es el simulado y cada test trabaja sobre una ruta de guardado
# temporal para no tocar la partida real.
# ============================================================================

const RUTA_TEST := "user://test_recompensas.cfg"

var _ruta_original: String
var _proveedor_original: Proveedor_Anuncios
var _necesidades_originales: Array
var _dinero_original: float
var _tuppers_originales: Array
var _tupper_idx_original: int
var _rejuvenecimiento_original: int
var _tratamientos_originales: int
var _first_time_dia_original: int
var _minute_day_original: int
var _modo_rapido_original: bool


func before_all() -> void:
	_ruta_original = Recompensas._ruta_guardado
	_proveedor_original = Recompensas._proveedor_anuncios
	_necesidades_originales = Variables_Dinamicas.Necesidades_Basicas.duplicate(true)
	_dinero_original = Variables_Dinamicas.Dinero
	_tuppers_originales = Variables_Dinamicas.Tuppers.duplicate(true)
	_tupper_idx_original = Variables_Dinamicas.Tupper_Seleccionado_Idx
	_rejuvenecimiento_original = Variables_Dinamicas.Rejuvenecimiento_Anios
	_tratamientos_originales = Variables_Dinamicas.Tratamientos_Rejuvenecimiento
	_first_time_dia_original = Variables_Estaticas.First_Time_Minute_Day
	_minute_day_original = Variables_Dinamicas.Minute_Day
	_modo_rapido_original = Variables_Estaticas.Modo_Rapido
	Recompensas._ruta_guardado = RUTA_TEST


func after_all() -> void:
	Recompensas._ruta_guardado = _ruta_original
	Recompensas.Configurar_Proveedor_Anuncios(_proveedor_original)
	Recompensas._Cargar()
	Variables_Dinamicas.Necesidades_Basicas = _necesidades_originales
	Variables_Dinamicas.Dinero = _dinero_original
	Variables_Dinamicas.Tuppers = _tuppers_originales
	Variables_Dinamicas.Tupper_Seleccionado_Idx = _tupper_idx_original
	Variables_Dinamicas.Rejuvenecimiento_Anios = _rejuvenecimiento_original
	Variables_Dinamicas.Tratamientos_Rejuvenecimiento = _tratamientos_originales
	Variables_Estaticas.First_Time_Minute_Day = _first_time_dia_original
	Variables_Dinamicas.Minute_Day = _minute_day_original
	Variables_Estaticas.Modo_Rapido = _modo_rapido_original
	if FileAccess.file_exists(RUTA_TEST):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_TEST))


func before_each() -> void:
	var anuncios := Proveedor_Simulado_Anuncios.new()
	anuncios.latencia_verificacion = 0.0
	Recompensas._ruta_guardado = RUTA_TEST
	Recompensas.Configurar_Proveedor_Anuncios(anuncios)
	Recompensas.Reiniciar_Esperas()
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Variables_Dinamicas.Dinero = 5000.0
	Variables_Dinamicas.Tuppers = []
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	Variables_Dinamicas.Rejuvenecimiento_Anios = 0
	Variables_Dinamicas.Tratamientos_Rejuvenecimiento = 0
	# Edad controlada: 18 + (70 - 0) / 7 = 28 años.
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.First_Time_Minute_Day = 0
	Variables_Dinamicas.Minute_Day = 70


# ----------------------------------------------------------------------------
# Catálogo
# ----------------------------------------------------------------------------

func test_catalogo_tiene_ids_unicos_y_campos_obligatorios() -> void:
	var vistos: Dictionary = {}
	for id in Recompensas_Catalogo.PRODUCTOS:
		var producto: Dictionary = Recompensas_Catalogo.PRODUCTOS[id]
		assert_false(vistos.has(id), "ID duplicado: %s" % id)
		vistos[id] = true
		assert_eq(str(producto.get("id", "")), id, "El id interno debe coincidir con la clave")
		assert_has(producto, "seccion")
		assert_has(producto, "tipo")
		assert_has(producto, "titulo")
		assert_has(producto, "icono")
		assert_has(producto, "color")
		assert_has(producto, "recompensas")
		assert_true(producto.get("color") is Color, "El color debe ser Color")


func test_secciones_y_grupos_del_catalogo() -> void:
	assert_eq(Recompensas_Catalogo.Productos_De(Recompensas_Catalogo.SECCION_ANUNCIOS).size(), 4)
	assert_eq(Recompensas_Catalogo.Servicios_De_Grupo(
		Recompensas_Catalogo.GRUPO_REJUVENECIMIENTO).size(), 3)
	assert_eq(Recompensas_Catalogo.Servicios_De_Grupo(
		Recompensas_Catalogo.GRUPO_CUIDADO).size(), 2)
	for anuncio in Recompensas_Catalogo.Productos_De(Recompensas_Catalogo.SECCION_ANUNCIOS):
		assert_gt(int(anuncio.get("cooldown_seg", 0)), 0)
		assert_gt(float(anuncio.get("duracion_simulada", 0.0)), 0.0)
		assert_ne(str(anuncio.get("recompensa_texto", "")), "")


func test_recompensas_del_catalogo_son_tipos_conocidos() -> void:
	var conocidos := {
		"euros": true, "necesidades_todas": true, "necesidades_sumar": true,
		"necesidad": true, "tuppers": true, "rejuvenecer": true,
	}
	for id in Recompensas_Catalogo.PRODUCTOS:
		for recompensa in Recompensas_Catalogo.Obtener_Recompensas(
				Recompensas_Catalogo.PRODUCTOS[id]):
			assert_true(recompensa is Dictionary)
			assert_true(conocidos.has(str(recompensa.get("tipo", ""))),
				"Recompensa desconocida en %s" % id)


# ----------------------------------------------------------------------------
# Anuncios
# ----------------------------------------------------------------------------

func test_anuncio_de_dinero_concede_euros_y_arranca_cooldown() -> void:
	var antes := float(Variables_Dinamicas.Dinero)
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_dinero")
	assert_true(solicitud.get("ok", false))
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(int(solicitud.get("token", 0)))
	assert_true(resultado.get("ok", false))
	assert_almost_eq(Variables_Dinamicas.Dinero, antes + 150.0, 0.001)
	var estado := Recompensas.Obtener_Estado_Anuncio("anuncio_dinero")
	assert_false(estado.get("disponible", true))
	assert_gt(int(estado.get("segundos_restantes", 0)), 0)
	var segunda: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_dinero")
	assert_false(segunda.get("ok", false))
	assert_eq(str(segunda.get("codigo", "")), "cooldown")


func test_anuncio_de_bienestar_suma_necesidades_sin_pasar_de_100() -> void:
	Variables_Dinamicas.Necesidades_Basicas = [10, 20, 90, 100, 40]
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_bienestar")
	assert_true(solicitud.get("ok", false))
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(int(solicitud.get("token", 0)))
	assert_true(resultado.get("ok", false))
	assert_eq(Variables_Dinamicas.Necesidades_Basicas, [40, 50, 100, 100, 70])


func test_anuncio_de_comida_crea_dos_tuppers() -> void:
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_comida")
	assert_true(solicitud.get("ok", false))
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(int(solicitud.get("token", 0)))
	assert_true(resultado.get("ok", false))
	assert_eq(Variables_Dinamicas.Tuppers.size(), 2)
	for tupper in Variables_Dinamicas.Tuppers:
		assert_eq(int(tupper.get("calidad", 0)), 100)
		assert_almost_eq(float(tupper.get("porcentaje_restante", 0.0)), 100.0, 0.001)


func test_anuncio_de_juventud_resta_un_anio() -> void:
	assert_eq(Recompensas.Obtener_Edad_Actual(), 28)
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_juventud")
	assert_true(solicitud.get("ok", false))
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(int(solicitud.get("token", 0)))
	assert_true(resultado.get("ok", false))
	assert_eq(int(resultado.get("edad", 0)), 27)
	assert_eq(Variables_Dinamicas.Rejuvenecimiento_Anios, 1)


func test_cancelar_anuncio_no_concede_recompensa() -> void:
	var antes := float(Variables_Dinamicas.Dinero)
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_dinero")
	assert_true(solicitud.get("ok", false))
	Recompensas.Cancelar_Anuncio(int(solicitud.get("token", 0)))
	assert_almost_eq(Variables_Dinamicas.Dinero, antes, 0.001)
	var estado := Recompensas.Obtener_Estado_Anuncio("anuncio_dinero")
	assert_true(estado.get("disponible", false), "Cancelar no debe arrancar el cooldown")


func test_token_de_anuncio_invalido_falla() -> void:
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(99999)
	assert_false(resultado.get("ok", false))
	assert_eq(str(resultado.get("codigo", "")), "token_invalido")


# ----------------------------------------------------------------------------
# Servicios
# ----------------------------------------------------------------------------

func test_servicio_de_bienestar_restaura_todas_las_necesidades_y_cobra() -> void:
	Variables_Dinamicas.Necesidades_Basicas = [1, 2, 3, 4, 5]
	var antes := float(Variables_Dinamicas.Dinero)
	var resultado: Dictionary = await Recompensas.Comprar_Servicio("servicio_bienestar")
	assert_true(resultado.get("ok", false))
	for valor in Variables_Dinamicas.Necesidades_Basicas:
		assert_eq(int(valor), 100)
	assert_almost_eq(Variables_Dinamicas.Dinero, antes - 120.0, 0.001)


func test_servicio_de_cesta_crea_tuppers_y_cobra() -> void:
	var antes := float(Variables_Dinamicas.Dinero)
	var resultado: Dictionary = await Recompensas.Comprar_Servicio("servicio_cesta")
	assert_true(resultado.get("ok", false))
	assert_eq(Variables_Dinamicas.Tuppers.size(), 3)
	assert_almost_eq(Variables_Dinamicas.Dinero, antes - 90.0, 0.001)


func test_servicio_de_rejuvenecimiento_baja_la_edad_y_sube_el_precio() -> void:
	var antes := float(Variables_Dinamicas.Dinero)
	var coste_inicial := Recompensas.Obtener_Coste_Servicio("servicio_spa")
	assert_almost_eq(coste_inicial, 400.0, 0.001)
	var resultado: Dictionary = await Recompensas.Comprar_Servicio("servicio_spa")
	assert_true(resultado.get("ok", false))
	assert_eq(int(resultado.get("edad", 0)), 27)
	assert_eq(Variables_Dinamicas.Rejuvenecimiento_Anios, 1)
	assert_eq(Variables_Dinamicas.Tratamientos_Rejuvenecimiento, 1)
	assert_almost_eq(Variables_Dinamicas.Dinero, antes - 400.0, 0.001)
	assert_almost_eq(Recompensas.Obtener_Coste_Servicio("servicio_spa"), 550.0, 0.001)


func test_servicio_sin_dinero_falla_sin_cobrar() -> void:
	Variables_Dinamicas.Dinero = 10.0
	var resultado: Dictionary = await Recompensas.Comprar_Servicio("servicio_bienestar")
	assert_false(resultado.get("ok", false))
	assert_eq(str(resultado.get("codigo", "")), "dinero_insuficiente")
	assert_almost_eq(Variables_Dinamicas.Dinero, 10.0, 0.001)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas, [50, 50, 50, 50, 50])


func test_rejuvenecimiento_no_baja_de_los_18_anios() -> void:
	Variables_Dinamicas.Minute_Day = 0
	assert_eq(Recompensas.Obtener_Edad_Actual(), 18)
	var resultado: Dictionary = await Recompensas.Comprar_Servicio("servicio_spa")
	assert_false(resultado.get("ok", false))
	assert_eq(str(resultado.get("codigo", "")), "edad_minima")
	assert_eq(Variables_Dinamicas.Rejuvenecimiento_Anios, 0)


# ----------------------------------------------------------------------------
# Persistencia
# ----------------------------------------------------------------------------

func test_persistencia_guarda_cooldowns_e_historial() -> void:
	# Aísla el test de cualquier espera residual de otro test del mismo proceso.
	Recompensas.Reiniciar_Esperas()
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio("anuncio_dinero")
	assert_true(solicitud.get("ok", false), "El anuncio debe poder solicitarse sin esperas")
	await Recompensas.Completar_Anuncio(int(solicitud.get("token", 0)))
	Recompensas._Cargar()
	assert_false(Recompensas.Obtener_Estado_Anuncio("anuncio_dinero").get("disponible", true))
	assert_gt(Recompensas.Obtener_Historial().size(), 0)


# ----------------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------------

func test_tienda_bienestar_construye_tarjetas_y_refresca_saldo() -> void:
	var tienda := Tienda_Bienestar.new()
	add_child_autofree(tienda)
	await wait_process_frames(3)
	assert_not_null(tienda._scroll)
	assert_not_null(tienda._lbl_dinero)
	assert_eq(tienda._ads_refs.size(), 4)
	assert_eq(tienda._servicios_refs.size(), 5)
	assert_eq(tienda._lbl_dinero.text, tienda._Formatear_Euros(int(round(Variables_Dinamicas.Dinero))))
	Variables_Dinamicas.Dinero += 50.0
	tienda._Sincronizar(false)
	assert_eq(tienda._lbl_dinero.text, tienda._Formatear_Euros(int(round(Variables_Dinamicas.Dinero))))


func test_modal_tratamiento_muestra_antes_y_despues() -> void:
	var producto := Recompensas_Catalogo.Obtener_Producto("servicio_spa")
	var modal := Modal_Tratamiento.new()
	modal.servicio = producto
	modal.coste = 400.0
	modal.dinero_disponible = 1000.0
	modal.edad_actual = 30
	modal.edad_objetivo = 29
	modal.es_rejuvenecimiento = true
	add_child_autofree(modal)
	await wait_process_frames(3)
	assert_eq(modal.layer, 112)
	assert_not_null(modal._btn_confirmar)
	assert_not_null(modal._vista_formulario)
	assert_false(modal._vista_exito.visible)
	modal.Mostrar_Exito({
		"ok": true,
		"dinero": 600.0,
		"edad": 29,
		"recompensas": [{"tipo": "rejuvenecer", "cantidad": 1}],
	})
	await wait_process_frames(2)
	assert_true(modal._vista_exito.visible)
	assert_eq(modal._lbl_exito_grande.text, "−1 año")


func test_modal_anuncio_bienestar_cuenta_y_muestra_recompensa() -> void:
	var anuncio := Recompensas_Catalogo.Obtener_Producto("anuncio_juventud")
	var modal := Modal_Anuncio_Bienestar.new()
	modal.anuncio = anuncio
	modal.token = 1
	add_child_autofree(modal)
	await wait_process_frames(3)
	assert_eq(modal.layer, 113)
	assert_almost_eq(modal._duracion, 8.0, 0.001)
	assert_false(modal._overlay_recompensa.visible)
	modal.Mostrar_Recompensa({
		"ok": true,
		"edad": 27,
		"dinero": 1000.0,
		"recompensas": [{"tipo": "rejuvenecer", "cantidad": 1}],
	})
	await wait_process_frames(2)
	assert_true(modal._overlay_recompensa.visible)
	assert_eq(modal._lbl_recompensa_grande.text, "−1 año")


func test_flujo_de_tratamiento_desde_la_tienda_rejuvenece_y_cobra() -> void:
	var tienda := Tienda_Bienestar.new()
	add_child_autofree(tienda)
	await wait_process_frames(2)
	var antes := float(Variables_Dinamicas.Dinero)
	tienda._Abrir_Tratamiento(Recompensas_Catalogo.Obtener_Producto("servicio_spa"))
	await wait_process_frames(2)
	assert_not_null(tienda._modal_tratamiento)
	var modal := tienda._modal_tratamiento
	modal.confirmado.emit()
	await wait_seconds(0.6)
	assert_eq(Recompensas.Obtener_Edad_Actual(), 27)
	assert_almost_eq(Variables_Dinamicas.Dinero, antes - 400.0, 0.001)
	assert_true(modal._vista_exito.visible, "El modal debe mostrar el éxito")
	modal._Cerrar()


func test_flujo_de_anuncio_desde_la_tienda_concede_recompensa() -> void:
	var tienda := Tienda_Bienestar.new()
	add_child_autofree(tienda)
	await wait_process_frames(2)
	var antes := float(Variables_Dinamicas.Dinero)
	var anuncio := Recompensas_Catalogo.Obtener_Producto("anuncio_dinero")
	tienda._Ver_Anuncio(anuncio)
	await wait_process_frames(2)
	assert_not_null(tienda._modal_anuncio)
	var modal := tienda._modal_anuncio
	# Simula que el anuncio ha llegado al final sin esperar los 5 s reales.
	modal.visto.emit(modal.token)
	await wait_process_frames(4)
	assert_almost_eq(Variables_Dinamicas.Dinero, antes + 150.0, 0.001)
	assert_true(modal._overlay_recompensa.visible, "Debe mostrarse la recompensa")
	modal._Cerrar()
	await wait_process_frames(1)
