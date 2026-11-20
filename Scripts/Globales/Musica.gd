extends Node

# ============================================================================
# Música de fondo global del juego.
#
# - Pista general: menú principal, escena principal y resto del juego.
# - Pista del minijuego: minijuego de cocina de comida rápida.
#
# Usa dos AudioStreamPlayer con fundido cruzado sobre el bus "Musica".
# El estado del reproductor general se conserva (pausado) mientras dura el
# minijuego y se reanuda justo donde se quedó al salir. Las preferencias de
# silencio/volumen se guardan en user://configuracion_audio.cfg.
# ============================================================================

signal silencio_cambiado(silenciado: bool)

const RUTA_CONFIG := "user://configuracion_audio.cfg"

const PISTA_GENERAL := preload("res://Sonidos/Musica/Lunchtime_Conspiracies.mp3")
const PISTA_MINIJUEGO := preload("res://Sonidos/Musica/Seven_Minutes_to_Service.mp3")

const BUS_MUSICA := "Musica"
const DURACION_FUNDIDO := 0.9
const VOLUMEN_GENERAL_DB := -9.0
const VOLUMEN_MINIJUEGO_DB := -7.0
const VOLUMEN_APAGADO_DB := -80.0
const VOLUMEN_PREDETERMINADO := 0.85

enum Pista { GENERAL, MINIJUEGO }

var _reproductor_general: AudioStreamPlayer
var _reproductor_minijuego: AudioStreamPlayer
var _pista_activa: Pista = Pista.GENERAL
var _tween_fundido: Tween
var _volumen: float = VOLUMEN_PREDETERMINADO
var _silenciado: bool = false
var _app_pausada: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Asegurar_Bus()
	_Cargar_Configuracion()

	_reproductor_general = _Crear_Reproductor(
		"Reproductor_General", PISTA_GENERAL, _on_general_finished)
	_reproductor_minijuego = _Crear_Reproductor(
		"Reproductor_Minijuego", PISTA_MINIJUEGO, _on_minijuego_finished)

	_Aplicar_Volumen_Bus()
	Reproducir_General()


func _exit_tree() -> void:
	if _tween_fundido != null and _tween_fundido.is_valid():
		_tween_fundido.kill()
	for reproductor in [_reproductor_general, _reproductor_minijuego]:
		if reproductor != null and is_instance_valid(reproductor):
			reproductor.stop()


# ----------------------------------------------------------------------------
# API pública
# ----------------------------------------------------------------------------

# Reproduce (o reanuda) la música general del juego con un fundido suave.
func Reproducir_General() -> void:
	_Cambiar_Pista(Pista.GENERAL)


# Reproduce la música del minijuego de comida rápida con un fundido suave.
func Reproducir_Minijuego() -> void:
	_Cambiar_Pista(Pista.MINIJUEGO)


func Esta_Silenciado() -> bool:
	return _silenciado


func Obtener_Volumen() -> float:
	return _volumen


func Establecer_Silencio(valor: bool) -> void:
	if _silenciado == valor:
		return
	_silenciado = valor
	_Aplicar_Volumen_Bus()
	_Guardar_Configuracion()
	silencio_cambiado.emit(_silenciado)


func Alternar_Silencio() -> void:
	Establecer_Silencio(not _silenciado)


func Establecer_Volumen(volumen: float) -> void:
	var nuevo := clampf(volumen, 0.0, 1.0)
	if is_equal_approx(nuevo, _volumen):
		return
	_volumen = nuevo
	_Aplicar_Volumen_Bus()
	_Guardar_Configuracion()


# ----------------------------------------------------------------------------
# Gestión de pistas y fundido cruzado
# ----------------------------------------------------------------------------

func _Cambiar_Pista(pista: Pista) -> void:
	if _reproductor_general == null or _reproductor_minijuego == null:
		return

	var destino: AudioStreamPlayer = _reproductor_general if pista == Pista.GENERAL else _reproductor_minijuego
	var origen: AudioStreamPlayer = _reproductor_minijuego if pista == Pista.GENERAL else _reproductor_general

	if _pista_activa == pista and destino.playing:
		return

	_pista_activa = pista
	if _tween_fundido != null and _tween_fundido.is_valid():
		_tween_fundido.kill()

	# Si la pista estaba detenida, arranca desde el principio y entra en silencio.
	if not destino.playing:
		destino.volume_db = VOLUMEN_APAGADO_DB
		destino.play()
	# Si estaba pausada (música general durante el minijuego), se reanuda aquí.
	destino.stream_paused = _app_pausada

	if origen.playing:
		if origen == _reproductor_general:
			# Mantener la posición de la pista general para reanudarla al volver.
			origen.stream_paused = false
		_tween_fundido = create_tween()
		_tween_fundido.set_parallel(true)
		_tween_fundido.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_fundido.tween_property(destino, "volume_db", _Volumen_Destino(pista), DURACION_FUNDIDO)
		_tween_fundido.tween_property(origen, "volume_db", VOLUMEN_APAGADO_DB, DURACION_FUNDIDO)
		_tween_fundido.chain().tween_callback(_Finalizar_Fundido.bind(origen, pista))
	else:
		_tween_fundido = create_tween()
		_tween_fundido.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_fundido.tween_property(destino, "volume_db", _Volumen_Destino(pista), DURACION_FUNDIDO)


func _Finalizar_Fundido(origen: AudioStreamPlayer, pista_activa: Pista) -> void:
	if _pista_activa != pista_activa:
		return
	if origen == null or not is_instance_valid(origen):
		return
	if origen == _reproductor_general:
		# La general se pausa (no se detiene) para conservar el punto de reproducción.
		if _pista_activa != Pista.GENERAL:
			origen.stream_paused = true
	else:
		origen.stop()
		origen.volume_db = VOLUMEN_APAGADO_DB


func _Volumen_Destino(pista: Pista) -> float:
	return VOLUMEN_GENERAL_DB if pista == Pista.GENERAL else VOLUMEN_MINIJUEGO_DB


# ----------------------------------------------------------------------------
# Reproductores, bus y preferencias
# ----------------------------------------------------------------------------

func _Crear_Reproductor(nombre: String, pista: AudioStream,
		al_terminar: Callable) -> AudioStreamPlayer:
	var reproductor := AudioStreamPlayer.new()
	reproductor.name = nombre
	reproductor.stream = pista
	reproductor.bus = BUS_MUSICA
	reproductor.volume_db = VOLUMEN_APAGADO_DB
	reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
	reproductor.finished.connect(al_terminar)
	add_child(reproductor)
	return reproductor


func _Asegurar_Bus() -> void:
	if AudioServer.get_bus_index(BUS_MUSICA) != -1:
		return
	AudioServer.add_bus()
	var indice := AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, BUS_MUSICA)
	AudioServer.set_bus_send(indice, "Master")


func _Aplicar_Volumen_Bus() -> void:
	var indice := AudioServer.get_bus_index(BUS_MUSICA)
	if indice == -1:
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(_volumen, 0.0001)))
	AudioServer.set_bus_mute(indice, _silenciado)


func _Cargar_Configuracion() -> void:
	var config := ConfigFile.new()
	if config.load(RUTA_CONFIG) != OK:
		return
	_volumen = clampf(float(config.get_value("audio", "volumen", VOLUMEN_PREDETERMINADO)), 0.0, 1.0)
	_silenciado = bool(config.get_value("audio", "silenciado", false))


func _Guardar_Configuracion() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volumen", _volumen)
	config.set_value("audio", "silenciado", _silenciado)
	config.save(RUTA_CONFIG)


# ----------------------------------------------------------------------------
# Seguridad de bucle y pausa de la aplicación
# ----------------------------------------------------------------------------

func _on_general_finished() -> void:
	if _pista_activa == Pista.GENERAL:
		_reproductor_general.play()


func _on_minijuego_finished() -> void:
	if _pista_activa == Pista.MINIJUEGO:
		_reproductor_minijuego.play()


func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_PAUSED:
			_app_pausada = true
			_Actualizar_Pausa_Reproductores()
		NOTIFICATION_APPLICATION_RESUMED:
			_app_pausada = false
			_Actualizar_Pausa_Reproductores()


func _Actualizar_Pausa_Reproductores() -> void:
	if _reproductor_general != null:
		_reproductor_general.stream_paused = _app_pausada or _pista_activa != Pista.GENERAL
	if _reproductor_minijuego != null:
		_reproductor_minijuego.stream_paused = _app_pausada or _pista_activa != Pista.MINIJUEGO
