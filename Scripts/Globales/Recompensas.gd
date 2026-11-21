extends Node

# ============================================================================
# RECOMPENSAS Y BIENESTAR
#
# Dominio de la pestaña Tienda > Bienestar:
# - Anuncios recompensados simulados con espera persistente.
# - Servicios de bienestar pagados con euros de la partida.
# - Tratamientos de rejuvenecimiento que restan años reales al Sim.
#
# No existe moneda premium, pago real ni SDK externo. La UI pide operaciones
# aquí y este autoload valida, aplica la recompensa, actualiza el estado y lo
# persiste en un archivo propio. Las recompensas de partida (dinero,
# necesidades, tuppers y edad) viven en Variables_Dinamicas y se guardan con
# la partida, no en este archivo.
#
# Para producción solo habría que registrar un proveedor de anuncios real:
#   Recompensas.Configurar_Proveedor_Anuncios(Mi_Proveedor_AdMob.new())
# ============================================================================

signal estado_cambiado
signal recompensa_aplicada(origen_id: String, recompensas: Array)
signal anuncio_autorizado(anuncio_id: String, token: int)
signal anuncio_completado(anuncio_id: String, resultado: Dictionary)
signal anuncio_cancelado(anuncio_id: String)
signal edad_cambiada(edad_anterior: int, edad_nueva: int)

const RUTA_GUARDADO := "user://recompensas.cfg"
const VERSION_DATOS := 1
const MAX_HISTORIAL := 20

var _ruta_guardado: String = RUTA_GUARDADO
var _cooldowns: Dictionary = {}
var _historial: Array = []
var _operacion_en_curso: bool = false
var _anuncio_token: int = 0
var _anuncio_actual_id: String = ""
var _siguiente_token: int = 1
var _proveedor_anuncios: Proveedor_Anuncios


func _ready() -> void:
	_proveedor_anuncios = Proveedor_Simulado_Anuncios.new()
	_Cargar()


func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE:
			_Guardar()


# ----------------------------------------------------------------------------
# API pública: consultas
# ----------------------------------------------------------------------------

func Obtener_Edad_Actual() -> int:
	return Variables_Estaticas.Calcular_Edad()


func Obtener_Anios_Rejuvenecidos() -> int:
	return maxi(0, int(Variables_Dinamicas.Rejuvenecimiento_Anios))


func Obtener_Tratamientos_Realizados() -> int:
	return maxi(0, int(Variables_Dinamicas.Tratamientos_Rejuvenecimiento))


func Obtener_Coste_Servicio(servicio_id: String) -> float:
	var producto := Recompensas_Catalogo.Obtener_Producto(servicio_id)
	if producto.is_empty() or str(producto.get("seccion", "")) != Recompensas_Catalogo.SECCION_SERVICIOS:
		return 0.0
	return Recompensas_Catalogo.Coste_Servicio(producto, Obtener_Tratamientos_Realizados())


func Obtener_Historial() -> Array:
	return _historial.duplicate(true)


func Obtener_Estado() -> Dictionary:
	return {
		"cooldowns": _cooldowns.duplicate(true),
		"historial": Obtener_Historial(),
		"edad": Obtener_Edad_Actual(),
		"anios_rejuvenecidos": Obtener_Anios_Rejuvenecidos(),
		"tratamientos": Obtener_Tratamientos_Realizados(),
		"dinero": Variables_Dinamicas.Dinero,
	}


func Obtener_Proveedor_Anuncios_Nombre() -> String:
	return _proveedor_anuncios.Obtener_Canal() if _proveedor_anuncios != null else "Sin proveedor"


func Esta_Disponible_Anuncio() -> bool:
	return _proveedor_anuncios != null and _proveedor_anuncios.Esta_Disponible()


func Hay_Operacion_En_Curso() -> bool:
	return _operacion_en_curso


func Obtener_Estado_Anuncio(anuncio_id: String) -> Dictionary:
	var anuncio := Recompensas_Catalogo.Obtener_Producto(anuncio_id)
	if anuncio.is_empty() or str(anuncio.get("tipo", "")) != Recompensas_Catalogo.TIPO_ANUNCIO:
		return {
			"ok": false,
			"disponible": false,
			"segundos_restantes": 0,
			"cooldown_total": 0,
			"mensaje": "Anuncio desconocido.",
		}

	var cooldown_total := maxi(0, int(anuncio.get("cooldown_seg", 0)))
	var hasta := int(_cooldowns.get(anuncio_id, 0))
	var restantes := maxi(0, hasta - _Ahora_Seg())
	var disponible := restantes <= 0
	var progreso := 1.0
	if not disponible and cooldown_total > 0:
		progreso = clampf(1.0 - float(restantes) / float(cooldown_total), 0.0, 1.0)
	return {
		"ok": true,
		"disponible": disponible,
		"segundos_restantes": restantes,
		"cooldown_total": cooldown_total,
		"progreso": progreso,
		"mensaje": "Disponible" if disponible else "Disponible en %s" % _Formatear_Segundos(restantes),
	}


# ----------------------------------------------------------------------------
# API pública: servicios pagados con euros
# ----------------------------------------------------------------------------

func Comprar_Servicio(servicio_id: String) -> Dictionary:
	if _operacion_en_curso:
		return _error("operacion_en_curso", "Espera a que termine la operación actual.")
	if _anuncio_token > 0:
		return _error("anuncio_en_curso", "Termina el anuncio antes de comprar un servicio.")
	var producto := Recompensas_Catalogo.Obtener_Producto(servicio_id)
	if producto.is_empty() or str(producto.get("seccion", "")) != Recompensas_Catalogo.SECCION_SERVICIOS:
		return _error("producto_desconocido", "Ese servicio no existe.")

	var coste := Obtener_Coste_Servicio(servicio_id)
	var dinero := float(Variables_Dinamicas.Dinero)
	if dinero < coste:
		var falta := int(ceil(coste - dinero))
		var error := _error("dinero_insuficiente",
			"Te faltan %d € para este tratamiento. Puedes conseguirlos con un anuncio." % falta)
		error["faltan"] = falta
		return error

	var es_rejuvenecimiento := _Tiene_Recompensa(producto, "rejuvenecer")
	var edad_anterior := Obtener_Edad_Actual()
	if es_rejuvenecimiento and edad_anterior <= 18:
		return _error("edad_minima", "Tu Sim ya tiene 18 años: no puede rejuvenecer más.")

	_operacion_en_curso = true
	# Pequeña espera para que el botón muestre feedback sin parecer roto.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		await tree.create_timer(0.35).timeout

	var dinero_actual := float(Variables_Dinamicas.Dinero)
	if dinero_actual < coste:
		_operacion_en_curso = false
		var falta_final := int(ceil(coste - dinero_actual))
		var error_final := _error("dinero_insuficiente",
			"Te faltan %d € para este tratamiento." % falta_final)
		error_final["faltan"] = falta_final
		return error_final

	Variables_Dinamicas.Dinero -= coste
	if es_rejuvenecimiento:
		Variables_Dinamicas.Tratamientos_Rejuvenecimiento += 1
	var recompensas := _Aplicar_Recompensas(producto)
	_Registrar_Historial(
		"servicio",
		str(producto.get("titulo", "Servicio")),
		str(producto.get("recompensa_texto", "Servicio aplicado")),
		-int(round(coste))
	)
	_Guardar()
	_operacion_en_curso = false

	var exito := {
		"ok": true,
		"codigo": "ok",
		"mensaje": "Servicio aplicado.",
		"producto_id": servicio_id,
		"producto": producto,
		"coste": coste,
		"recompensas": recompensas,
		"dinero": Variables_Dinamicas.Dinero,
		"edad": Obtener_Edad_Actual(),
		"edad_anterior": edad_anterior,
	}
	estado_cambiado.emit()
	return exito


# ----------------------------------------------------------------------------
# API pública: anuncios recompensados
# ----------------------------------------------------------------------------

func Solicitar_Anuncio(anuncio_id: String) -> Dictionary:
	if _anuncio_token > 0:
		return _error("anuncio_en_curso", "Ya hay un anuncio en curso.")
	if _operacion_en_curso:
		return _error("operacion_en_curso", "Espera a que termine la operación actual.")
	var anuncio := Recompensas_Catalogo.Obtener_Producto(anuncio_id)
	if anuncio.is_empty() or str(anuncio.get("tipo", "")) != Recompensas_Catalogo.TIPO_ANUNCIO:
		return _error("anuncio_desconocido", "Ese anuncio no existe.")
	if _proveedor_anuncios == null or not _proveedor_anuncios.Esta_Disponible():
		return _error("anuncio_no_disponible", "La red de anuncios no está disponible.")

	var estado := Obtener_Estado_Anuncio(anuncio_id)
	if not bool(estado.get("disponible", false)):
		var error := _error("cooldown", str(estado.get("mensaje", "Espera un poco.")))
		error["segundos_restantes"] = int(estado.get("segundos_restantes", 0))
		return error

	if _Tiene_Recompensa(anuncio, "rejuvenecer") and Obtener_Edad_Actual() <= 18:
		return _error("edad_minima", "Tu Sim ya tiene 18 años: no necesita rejuvenecer más.")

	var preparado: Dictionary = _proveedor_anuncios.Preparar_Anuncio(anuncio)
	if not bool(preparado.get("ok", false)):
		return _resultado_error_base(anuncio_id, preparado)

	_anuncio_actual_id = anuncio_id
	_anuncio_token = _siguiente_token
	_siguiente_token += 1
	anuncio_autorizado.emit(anuncio_id, _anuncio_token)
	return {
		"ok": true,
		"token": _anuncio_token,
		"anuncio": anuncio,
	}


func Completar_Anuncio(token: int) -> Dictionary:
	if token <= 0 or token != _anuncio_token or _anuncio_actual_id == "":
		return _error("token_invalido", "La recompensa del anuncio ya no es válida.")

	var anuncio_id := _anuncio_actual_id
	var anuncio := Recompensas_Catalogo.Obtener_Producto(anuncio_id)
	# Se invalida el token antes de esperar: evita dobles cobros si la UI
	# intenta completar el mismo anuncio dos veces.
	_anuncio_token = 0
	_anuncio_actual_id = ""

	if anuncio.is_empty() or _proveedor_anuncios == null:
		return _error("anuncio_desconocido", "No se pudo recuperar el anuncio.")

	var verificacion: Dictionary = await _proveedor_anuncios.Confirmar_Anuncio(token, anuncio)
	if not bool(verificacion.get("ok", false)):
		estado_cambiado.emit()
		return _resultado_error_base(anuncio_id, verificacion)

	var edad_anterior := Obtener_Edad_Actual()
	var recompensas := _Aplicar_Recompensas(anuncio)
	var cooldown := maxi(0, int(anuncio.get("cooldown_seg", 0)))
	_cooldowns[anuncio_id] = _Ahora_Seg() + cooldown
	_Registrar_Historial(
		"anuncio",
		str(anuncio.get("titulo", "Anuncio")),
		str(anuncio.get("recompensa_texto", "Recompensa")),
		0
	)
	_Guardar()

	var exito := {
		"ok": true,
		"codigo": "ok",
		"mensaje": "Recompensa concedida.",
		"anuncio_id": anuncio_id,
		"anuncio": anuncio,
		"referencia": str(verificacion.get("referencia", "")),
		"recompensas": recompensas,
		"dinero": Variables_Dinamicas.Dinero,
		"edad": Obtener_Edad_Actual(),
		"edad_anterior": edad_anterior,
		"cooldown_seg": cooldown,
	}
	anuncio_completado.emit(anuncio_id, exito)
	estado_cambiado.emit()
	return exito


func Cancelar_Anuncio(token: int) -> void:
	if token <= 0 or token != _anuncio_token:
		return
	var anuncio_id := _anuncio_actual_id
	_anuncio_token = 0
	_anuncio_actual_id = ""
	anuncio_cancelado.emit(anuncio_id)


# ----------------------------------------------------------------------------
# Proveedores (integración futura)
# ----------------------------------------------------------------------------

func Configurar_Proveedor_Anuncios(proveedor: Proveedor_Anuncios) -> void:
	if proveedor == null:
		return
	_proveedor_anuncios = proveedor
	estado_cambiado.emit()


# ----------------------------------------------------------------------------
# Reset de esperas (no revierte recompensas ni la partida)
# ----------------------------------------------------------------------------

func Reiniciar_Esperas() -> void:
	_cooldowns.clear()
	_historial.clear()
	_anuncio_token = 0
	_anuncio_actual_id = ""
	_operacion_en_curso = false
	_Guardar()
	estado_cambiado.emit()


# ----------------------------------------------------------------------------
# Aplicación de recompensas
# ----------------------------------------------------------------------------

func _Aplicar_Recompensas(producto: Dictionary) -> Array:
	var aplicadas: Array = []
	var recompensas: Array = Recompensas_Catalogo.Obtener_Recompensas(producto)

	for recompensa in recompensas:
		if not (recompensa is Dictionary):
			continue
		var tipo := str(recompensa.get("tipo", ""))
		match tipo:
			"euros":
				var euros := maxf(0.0, float(recompensa.get("cantidad", 0.0)))
				if euros > 0.0:
					Variables_Dinamicas.Dinero += euros
					aplicadas.append({"tipo": tipo, "cantidad": euros})
			"necesidades_todas":
				var valor := clampi(int(recompensa.get("valor", 100)), 1, 100)
				for i in range(Variables_Dinamicas.Necesidades_Basicas.size()):
					Variables_Dinamicas.Necesidades_Basicas[i] = valor
				aplicadas.append({"tipo": tipo, "valor": valor})
			"necesidades_sumar":
				var suma := maxi(0, int(recompensa.get("cantidad", 0)))
				if suma > 0:
					for i in range(Variables_Dinamicas.Necesidades_Basicas.size()):
						var actual := int(Variables_Dinamicas.Necesidades_Basicas[i])
						Variables_Dinamicas.Necesidades_Basicas[i] = clampi(actual + suma, 1, 100)
					aplicadas.append({"tipo": tipo, "cantidad": suma})
			"necesidad":
				var indice := clampi(int(recompensa.get("indice", 0)), 0,
					Variables_Dinamicas.Necesidades_Basicas.size() - 1)
				var valor_actual := int(Variables_Dinamicas.Necesidades_Basicas[indice])
				var nuevo := clampi(
					int(recompensa.get("valor", valor_actual + int(recompensa.get("delta", 0)))),
					1, 100)
				Variables_Dinamicas.Necesidades_Basicas[indice] = nuevo
				aplicadas.append({"tipo": tipo, "indice": indice, "valor": nuevo})
			"tuppers":
				var cantidad_tuppers := maxi(0, int(recompensa.get("cantidad", 0)))
				var calidad := clampi(int(recompensa.get("calidad", 100)), 1, 100)
				var creados := _Crear_Tuppers(cantidad_tuppers, calidad)
				if creados > 0:
					aplicadas.append({"tipo": tipo, "cantidad": creados, "calidad": calidad})
			"rejuvenecer":
				var anios := maxi(1, int(recompensa.get("cantidad", 1)))
				var edad_anterior := Obtener_Edad_Actual()
				var edad_objetivo := maxi(18, edad_anterior - anios)
				var aplicados := edad_anterior - edad_objetivo
				if aplicados > 0:
					Variables_Dinamicas.Rejuvenecimiento_Anios += aplicados
					aplicadas.append({
						"tipo": tipo,
						"cantidad": aplicados,
						"edad_anterior": edad_anterior,
						"edad_nueva": edad_objetivo,
					})
					edad_cambiada.emit(edad_anterior, edad_objetivo)
			_:
				push_warning("Recompensas: recompensa desconocida '%s'." % tipo)

	if not aplicadas.is_empty():
		recompensa_aplicada.emit(str(producto.get("id", "")), aplicadas)
	return aplicadas


func _Tiene_Recompensa(producto: Dictionary, tipo_buscado: String) -> bool:
	for recompensa in Recompensas_Catalogo.Obtener_Recompensas(producto):
		if recompensa is Dictionary and str(recompensa.get("tipo", "")) == tipo_buscado:
			return true
	return false


func _Crear_Tuppers(cantidad: int, calidad: int) -> int:
	if cantidad <= 0:
		return 0
	var creados := 0
	for i in range(cantidad):
		var tupper: Dictionary = Alimentacion.Crear_Tupper()
		tupper["calidad"] = calidad
		creados += 1
	return creados


# ----------------------------------------------------------------------------
# Persistencia
# ----------------------------------------------------------------------------

func _Cargar() -> void:
	var config := ConfigFile.new()
	var error := config.load(_ruta_guardado)
	if error != OK:
		_cooldowns.clear()
		_historial.clear()
		return

	_cooldowns = _Sanear_Cooldowns(config.get_value("estado", "cooldowns", {}))
	_historial = _Sanear_Historial(config.get_value("estado", "historial", []))


func _Guardar() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", VERSION_DATOS)
	config.set_value("meta", "proveedor_anuncios", Obtener_Proveedor_Anuncios_Nombre())
	config.set_value("estado", "cooldowns", _cooldowns)
	config.set_value("estado", "historial", _historial)
	var error := config.save(_ruta_guardado)
	if error != OK:
		push_warning("Recompensas: no se pudo guardar el estado (%s)." % error_string(error))


func _Sanear_Cooldowns(crudo: Variant) -> Dictionary:
	var limpio: Dictionary = {}
	if not (crudo is Dictionary):
		return limpio
	var ahora := _Ahora_Seg()
	for clave in crudo:
		var id := str(clave)
		if not Recompensas_Catalogo.Es_Anuncio(id):
			continue
		var hasta := int(crudo[clave])
		# Descarta cooldowns absurdamente lejanos (reloj cambiado/corrupción).
		if hasta > ahora + 86400 * 30:
			continue
		limpio[id] = maxi(0, hasta)
	return limpio


func _Sanear_Historial(crudo: Variant) -> Array:
	var limpio: Array = []
	if not (crudo is Array):
		return limpio
	for entrada in crudo:
		if entrada is Dictionary:
			limpio.append(entrada)
			if limpio.size() >= MAX_HISTORIAL:
				break
	return limpio


func _Registrar_Historial(tipo: String, titulo: String, detalle: String, importe_delta: int) -> void:
	_historial.push_front({
		"tipo": tipo,
		"titulo": titulo,
		"detalle": detalle,
		"importe_delta": importe_delta,
		"fecha_unix": _Ahora_Seg(),
	})
	while _historial.size() > MAX_HISTORIAL:
		_historial.pop_back()


# ----------------------------------------------------------------------------
# Utilidades
# ----------------------------------------------------------------------------

func _Ahora_Seg() -> int:
	return int(Time.get_unix_time_from_system())


func _Formatear_Segundos(segundos: int) -> String:
	var seguros := maxi(0, segundos)
	return "%02d:%02d" % [seguros / 60, seguros % 60]


func _resultado_error_base(producto_id: String, respuesta: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"codigo": str(respuesta.get("codigo", "error")),
		"mensaje": str(respuesta.get("mensaje", "No se pudo completar la operación.")),
		"producto_id": producto_id,
	}


func _error(codigo: String, mensaje: String) -> Dictionary:
	return {"ok": false, "codigo": codigo, "mensaje": mensaje}
