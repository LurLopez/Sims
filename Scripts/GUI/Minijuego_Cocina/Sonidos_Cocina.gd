class_name Sonidos_Cocina
extends Node

# ============================================================================
# Efectos de sonido originales del minijuego (sintetizados, sin samples
# externos). Pool de reproductores para solapar varios sonidos sin cortar.
# Se reproducen en el bus "SFX", cuyo volumen y silencio gestiona Ajustes.
# ============================================================================

const STREAMS: Dictionary = {
	"click": preload("res://Sonidos/SFX/click.wav"),
	"pop": preload("res://Sonidos/SFX/pop.wav"),
	"drop": preload("res://Sonidos/SFX/drop.wav"),
	"sizzle": preload("res://Sonidos/SFX/sizzle.wav"),
	"ding": preload("res://Sonidos/SFX/ding.wav"),
	"burn": preload("res://Sonidos/SFX/burn.wav"),
	"coin": preload("res://Sonidos/SFX/coin.wav"),
	"happy": preload("res://Sonidos/SFX/happy.wav"),
	"angry": preload("res://Sonidos/SFX/angry.wav"),
	"trash": preload("res://Sonidos/SFX/trash.wav"),
	"pour": preload("res://Sonidos/SFX/pour.wav"),
	"star": preload("res://Sonidos/SFX/star.wav"),
	"combo": preload("res://Sonidos/SFX/combo.wav"),
	"start": preload("res://Sonidos/SFX/start.wav"),
	"level_end": preload("res://Sonidos/SFX/level_end.wav"),
}

const VOCES: int = 12

var _players: Array[AudioStreamPlayer] = []
var _indice: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(VOCES):
		var p := AudioStreamPlayer.new()
		p.name = "Voz_%d" % i
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(p)
		_players.append(p)


func reproducir(nombre: String, volumen_db: float = -14.0, tono: float = 1.0) -> void:
	if not STREAMS.has(nombre) or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_indice]
	_indice = (_indice + 1) % _players.size()
	p.stream = STREAMS[nombre]
	p.volume_db = volumen_db
	p.pitch_scale = clampf(tono, 0.5, 2.0)
	p.play()


func parar_todo() -> void:
	for p in _players:
		if p != null and p.playing:
			p.stop()
