extends Node

# ============================================================================
# Música de fondo global del juego.
#
# - Pista general: menú principal, escena principal y resto del juego.
# - Pista del minijuego: minijuego de cocina de comida rápida.
# - Pista de correr: minijuego PARK RUSH 3D (estilo Subway Surfers).
#
# Usa AudioStreamPlayer independientes con fundido cruzado sobre el bus "Musica".
# El estado del reproductor general se conserva (pausado) mientras dura un
# minijuego y se reanuda justo donde se quedó al salir. El volumen y el
# silencio los gestiona el autoload Ajustes (user://configuracion_ajustes.cfg).
# ============================================================================

signal silencio_cambiado(silenciado: bool)

const RUTA_PISTA_GENERAL := "res://Sonidos/Musica/Lunchtime_Conspiracies.mp3"
const RUTA_PISTA_MINIJUEGO := "res://Sonidos/Musica/Seven_Minutes_to_Service.mp3"
const RUTA_PISTA_CORRER := "res://Sonidos/Musica/Subway_Rush_Theme.mp3"
# La pista general es la única que hace falta al arrancar. Las pistas de
# minijuegos se cargan la primera vez que se entra en cada uno.
const PISTA_GENERAL := preload("res://Sonidos/Musica/Lunchtime_Conspiracies.mp3")
var _pista_minijuego: AudioStream = null
var _pista_correr: AudioStream = null

const BUS_MUSICA := "Musica"
const DURACION_FUNDIDO := 0.9
const VOLUMEN_GENERAL_DB := -9.0
const VOLUMEN_MINIJUEGO_DB := -7.0
const VOLUMEN_CORRER_DB := -7.5
const VOLUMEN_APAGADO_DB := -80.0

enum Pista { GENERAL, MINIJUEGO, CORRER }

var _reproductor_general: AudioStreamPlayer
var _reproductor_minijuego: AudioStreamPlayer
var _reproductor_correr: AudioStreamPlayer
var _pista_activa: Pista = Pista.GENERAL
var _tween_fundido: Tween
var _app_pausada: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Asegurar_Bus()

	_reproductor_general = _Crear_Reproductor(
		"Reproductor_General", PISTA_GENERAL, _on_general_finished)
	# Los reproductores de minijuegos se crean sin stream: el MP3 se carga al entrar.
	_reproductor_minijuego = _Crear_Reproductor(
		"Reproductor_Minijuego", null, _on_minijuego_finished)
	_reproductor_correr = _Crear_Reproductor(
		"Reproductor_Correr", null, _on_correr_finished)

	if not Ajustes.silencio_musica_cambiado.is_connected(_on_ajustes_silencio_musica):
		Ajustes.silencio_musica_cambiado.connect(_on_ajustes_silencio_musica)
	Reproducir_General()


func _exit_tree() -> void:
	if _tween_fundido != null and _tween_fundido.is_valid():
		_tween_fundido.kill()
	for reproductor in [_reproductor_general, _reproductor_minijuego, _reproductor_correr]:
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


# Reproduce la música estilo Subway Surfers del minijuego de correr con un fundido suave.
func Reproducir_Correr() -> void:
	_Cambiar_Pista(Pista.CORRER)


func Esta_Silenciado() -> bool:
	return Ajustes.Esta_Silenciado_Musica()


func Obtener_Volumen() -> float:
	return Ajustes.Obtener_Volumen_Musica()


func Establecer_Silencio(valor: bool) -> void:
	Ajustes.Establecer_Silencio_Musica(valor)


func Alternar_Silencio() -> void:
	Ajustes.Alternar_Silencio_Musica()


func Establecer_Volumen(volumen: float) -> void:
	Ajustes.Establecer_Volumen_Musica(volumen)


func _on_ajustes_silencio_musica(silenciado: bool) -> void:
	silencio_cambiado.emit(silenciado)


# ----------------------------------------------------------------------------
# Gestión de pistas y fundido cruzado
# ----------------------------------------------------------------------------

func _Reproductor_De(pista: Pista) -> AudioStreamPlayer:
	match pista:
		Pista.MINIJUEGO:
			return _reproductor_minijuego
		Pista.CORRER:
			return _reproductor_correr
		_:
			return _reproductor_general


func _Asegurar_Stream_Pista(pista: Pista, destino: AudioStreamPlayer) -> void:
	if destino.stream != null:
		return
	if pista == Pista.MINIJUEGO:
		if _pista_minijuego == null:
			_pista_minijuego = load(RUTA_PISTA_MINIJUEGO) as AudioStream
		destino.stream = _pista_minijuego
	elif pista == Pista.CORRER:
		if _pista_correr == null:
			_pista_correr = load(RUTA_PISTA_CORRER) as AudioStream
		destino.stream = _pista_correr


func _Cambiar_Pista(pista: Pista) -> void:
	if _reproductor_general == null or _reproductor_minijuego == null or _reproductor_correr == null:
		return

	var destino: AudioStreamPlayer = _Reproductor_De(pista)
	_Asegurar_Stream_Pista(pista, destino)

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

	var salientes: Array[AudioStreamPlayer] = []
	for candidato in [_reproductor_general, _reproductor_minijuego, _reproductor_correr]:
		if candidato != destino and candidato.playing:
			if candidato == _reproductor_general:
				# Mantener la posición de la pista general para reanudarla al volver.
				candidato.stream_paused = false
			salientes.append(candidato)

	_tween_fundido = create_tween()
	_tween_fundido.set_parallel(true)
	_tween_fundido.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_fundido.tween_property(destino, "volume_db", _Volumen_Destino(pista), DURACION_FUNDIDO)
	for origen in salientes:
		_tween_fundido.tween_property(origen, "volume_db", VOLUMEN_APAGADO_DB, DURACION_FUNDIDO)
	if not salientes.is_empty():
		_tween_fundido.chain().tween_callback(_Finalizar_Fundido.bind(salientes, pista))


func _Finalizar_Fundido(origenes: Array[AudioStreamPlayer], pista_activa: Pista) -> void:
	if _pista_activa != pista_activa:
		return
	for origen in origenes:
		if origen == null or not is_instance_valid(origen):
			continue
		if origen == _reproductor_general:
			# La general se pausa (no se detiene) para conservar el punto de reproducción.
			if _pista_activa != Pista.GENERAL:
				origen.stream_paused = true
		else:
			origen.stop()
			origen.volume_db = VOLUMEN_APAGADO_DB


func _Volumen_Destino(pista: Pista) -> float:
	match pista:
		Pista.MINIJUEGO:
			return VOLUMEN_MINIJUEGO_DB
		Pista.CORRER:
			return VOLUMEN_CORRER_DB
		_:
			return VOLUMEN_GENERAL_DB


# ----------------------------------------------------------------------------
# Reproductores y bus
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


# ----------------------------------------------------------------------------
# Seguridad de bucle y pausa de la aplicación
# ----------------------------------------------------------------------------

func _on_general_finished() -> void:
	if _pista_activa == Pista.GENERAL:
		_reproductor_general.play()


func _on_minijuego_finished() -> void:
	if _pista_activa == Pista.MINIJUEGO:
		_reproductor_minijuego.play()


func _on_correr_finished() -> void:
	if _pista_activa == Pista.CORRER:
		_reproductor_correr.play()


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
	if _reproductor_correr != null:
		_reproductor_correr.stream_paused = _app_pausada or _pista_activa != Pista.CORRER
