extends Node

# ============================================================================
# Ajustes globales del juego.
#
# De momento solo gestiona el audio:
# - Bus "Musica": volumen y silencio de la banda sonora.
# - Bus "SFX": volumen y silencio de los efectos de sonido.
#
# Los buses se crean aquí en tiempo de ejecución (antes que el autoload
# Musica), y las preferencias se guardan en user://configuracion_ajustes.cfg.
# El archivo antiguo user://configuracion_audio.cfg se migra una sola vez.
# ============================================================================

signal ajustes_cambiados
signal volumen_musica_cambiado(volumen: float)
signal volumen_sfx_cambiado(volumen: float)
signal silencio_musica_cambiado(silenciado: bool)
signal silencio_sfx_cambiado(silenciado: bool)

const RUTA_CONFIG := "user://configuracion_ajustes.cfg"
const RUTA_CONFIG_ANTIGUA := "user://configuracion_audio.cfg"

const BUS_MUSICA := "Musica"
const BUS_SFX := "SFX"

const VOLUMEN_MUSICA_PREDETERMINADO := 0.85
const VOLUMEN_SFX_PREDETERMINADO := 0.85
const VOLUMEN_MINIMO_DB := -60.0

const SFX_PRUEBA := preload("res://Sonidos/SFX/ding.wav")

var _volumen_musica: float = VOLUMEN_MUSICA_PREDETERMINADO
var _volumen_sfx: float = VOLUMEN_SFX_PREDETERMINADO
var _silencio_musica: bool = false
var _silencio_sfx: bool = false

var _reproductor_prueba: AudioStreamPlayer
var _timer_guardado: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Asegurar_Buses()
	_Cargar_Configuracion()
	_Aplicar_Todo()
	_Crear_Timer_Guardado()


func _exit_tree() -> void:
	_Guardar_Configuracion()


# ----------------------------------------------------------------------------
# API pública: música
# ----------------------------------------------------------------------------

func Obtener_Volumen_Musica() -> float:
	return _volumen_musica


func Esta_Silenciado_Musica() -> bool:
	return _silencio_musica


func Establecer_Volumen_Musica(volumen: float) -> void:
	var nuevo := clampf(volumen, 0.0, 1.0)
	if is_equal_approx(nuevo, _volumen_musica):
		return
	_volumen_musica = nuevo
	_Aplicar_Bus(BUS_MUSICA, _volumen_musica, _silencio_musica)
	_Programar_Guardado()
	volumen_musica_cambiado.emit(_volumen_musica)
	ajustes_cambiados.emit()


func Establecer_Silencio_Musica(valor: bool) -> void:
	if _silencio_musica == valor:
		return
	_silencio_musica = valor
	_Aplicar_Bus(BUS_MUSICA, _volumen_musica, _silencio_musica)
	_Guardar_Configuracion()
	silencio_musica_cambiado.emit(_silencio_musica)
	ajustes_cambiados.emit()


func Alternar_Silencio_Musica() -> void:
	Establecer_Silencio_Musica(not _silencio_musica)


# ----------------------------------------------------------------------------
# API pública: efectos de sonido
# ----------------------------------------------------------------------------

func Obtener_Volumen_SFX() -> float:
	return _volumen_sfx


func Esta_Silenciado_SFX() -> bool:
	return _silencio_sfx


func Establecer_Volumen_SFX(volumen: float) -> void:
	var nuevo := clampf(volumen, 0.0, 1.0)
	if is_equal_approx(nuevo, _volumen_sfx):
		return
	_volumen_sfx = nuevo
	_Aplicar_Bus(BUS_SFX, _volumen_sfx, _silencio_sfx)
	_Programar_Guardado()
	volumen_sfx_cambiado.emit(_volumen_sfx)
	ajustes_cambiados.emit()


func Establecer_Silencio_SFX(valor: bool) -> void:
	if _silencio_sfx == valor:
		return
	_silencio_sfx = valor
	_Aplicar_Bus(BUS_SFX, _volumen_sfx, _silencio_sfx)
	_Guardar_Configuracion()
	silencio_sfx_cambiado.emit(_silencio_sfx)
	ajustes_cambiados.emit()


func Alternar_Silencio_SFX() -> void:
	Establecer_Silencio_SFX(not _silencio_sfx)


# ----------------------------------------------------------------------------
# Utilidades de audio
# ----------------------------------------------------------------------------

# Reproduce un efecto corto para que el jugador escuche el volumen actual.
func Probar_Efecto_Sonido() -> void:
	if _reproductor_prueba == null:
		_reproductor_prueba = AudioStreamPlayer.new()
		_reproductor_prueba.name = "Reproductor_Prueba_SFX"
		_reproductor_prueba.stream = SFX_PRUEBA
		_reproductor_prueba.process_mode = Node.PROCESS_MODE_ALWAYS
		_reproductor_prueba.bus = BUS_SFX
		add_child(_reproductor_prueba)
	_reproductor_prueba.play()


func Restablecer_Audio() -> void:
	_volumen_musica = VOLUMEN_MUSICA_PREDETERMINADO
	_volumen_sfx = VOLUMEN_SFX_PREDETERMINADO
	_silencio_musica = false
	_silencio_sfx = false
	_Aplicar_Todo()
	_Guardar_Configuracion()
	volumen_musica_cambiado.emit(_volumen_musica)
	volumen_sfx_cambiado.emit(_volumen_sfx)
	silencio_musica_cambiado.emit(_silencio_musica)
	silencio_sfx_cambiado.emit(_silencio_sfx)
	ajustes_cambiados.emit()


func _Asegurar_Buses() -> void:
	_Asegurar_Bus(BUS_MUSICA)
	_Asegurar_Bus(BUS_SFX)


func _Asegurar_Bus(nombre: String) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	AudioServer.add_bus()
	var indice := AudioServer.bus_count - 1
	AudioServer.set_bus_name(indice, nombre)
	AudioServer.set_bus_send(indice, "Master")


func _Aplicar_Todo() -> void:
	_Aplicar_Bus(BUS_MUSICA, _volumen_musica, _silencio_musica)
	_Aplicar_Bus(BUS_SFX, _volumen_sfx, _silencio_sfx)


func _Aplicar_Bus(nombre: String, volumen: float, silenciado: bool) -> void:
	var indice := AudioServer.get_bus_index(nombre)
	if indice == -1:
		return
	var db := VOLUMEN_MINIMO_DB if volumen <= 0.001 else linear_to_db(volumen)
	AudioServer.set_bus_volume_db(indice, db)
	AudioServer.set_bus_mute(indice, silenciado or volumen <= 0.001)


# ----------------------------------------------------------------------------
# Persistencia
# ----------------------------------------------------------------------------

func _Crear_Timer_Guardado() -> void:
	_timer_guardado = Timer.new()
	_timer_guardado.name = "Timer_Guardado_Ajustes"
	_timer_guardado.one_shot = true
	_timer_guardado.wait_time = 0.35
	_timer_guardado.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer_guardado.timeout.connect(_Guardar_Configuracion)
	add_child(_timer_guardado)


# Evita escribir en disco en cada píxel del deslizador.
func _Programar_Guardado() -> void:
	if _timer_guardado == null:
		_Guardar_Configuracion()
		return
	_timer_guardado.start()


func _Cargar_Configuracion() -> void:
	var config := ConfigFile.new()
	if config.load(RUTA_CONFIG) == OK:
		_volumen_musica = clampf(
			float(config.get_value("audio", "volumen_musica", VOLUMEN_MUSICA_PREDETERMINADO)), 0.0, 1.0)
		_volumen_sfx = clampf(
			float(config.get_value("audio", "volumen_sfx", VOLUMEN_SFX_PREDETERMINADO)), 0.0, 1.0)
		_silencio_musica = bool(config.get_value("audio", "silencio_musica", false))
		_silencio_sfx = bool(config.get_value("audio", "silencio_sfx", false))
		return

	# Migración desde el archivo que usaba el autoload Musica antes de Ajustes.
	var antigua := ConfigFile.new()
	if antigua.load(RUTA_CONFIG_ANTIGUA) == OK:
		_volumen_musica = clampf(
			float(antigua.get_value("audio", "volumen", VOLUMEN_MUSICA_PREDETERMINADO)), 0.0, 1.0)
		_silencio_musica = bool(antigua.get_value("audio", "silenciado", false))


func _Guardar_Configuracion() -> void:
	if _timer_guardado != null:
		_timer_guardado.stop()
	var config := ConfigFile.new()
	config.set_value("audio", "volumen_musica", _volumen_musica)
	config.set_value("audio", "volumen_sfx", _volumen_sfx)
	config.set_value("audio", "silencio_musica", _silencio_musica)
	config.set_value("audio", "silencio_sfx", _silencio_sfx)
	config.save(RUTA_CONFIG)


func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			_Guardar_Configuracion()
