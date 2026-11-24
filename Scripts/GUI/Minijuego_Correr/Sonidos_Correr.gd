class_name Sonidos_Correr
extends Node

# Pool de voces para los efectos del minijuego de correr. Reutiliza los SFX
# originales del proyecto y respeta el bus "SFX" configurado en Ajustes.

const STREAMS: Dictionary = {
	"click": preload("res://Sonidos/SFX/click.wav"),
	"pop": preload("res://Sonidos/SFX/pop.wav"),
	"coin": preload("res://Sonidos/SFX/coin.wav"),
	"star": preload("res://Sonidos/SFX/star.wav"),
	"start": preload("res://Sonidos/SFX/start.wav"),
	"level_end": preload("res://Sonidos/SFX/level_end.wav"),
	"trash": preload("res://Sonidos/SFX/trash.wav"),
	"angry": preload("res://Sonidos/SFX/angry.wav"),
	"ding": preload("res://Sonidos/SFX/ding.wav"),
	"whoosh": preload("res://Sonidos/SFX/drop.wav"),
}

const VOCES: int = 10

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


func reproducir(nombre: String, volumen_db: float = -13.0, tono: float = 1.0) -> void:
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
