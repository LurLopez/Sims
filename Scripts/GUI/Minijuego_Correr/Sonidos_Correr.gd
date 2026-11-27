class_name Sonidos_Correr
extends Node

# Pool de voces para los efectos del minijuego de correr (PARK RUSH 3D).
# Usa SFX dedicados (swipe, salto, súper salto, rodar, aterrizaje, pasos,
# tropiezo, choque, moneda, power-ups, jetpack, pogo, tabla, escudo, llave y
# silbato del guardia) respetando el bus "SFX" configurado en Ajustes.

const STREAMS: Dictionary = {
	"click": preload("res://Sonidos/SFX/click.wav"),
	"star": preload("res://Sonidos/SFX/star.wav"),
	"start": preload("res://Sonidos/SFX/start.wav"),
	"level_end": preload("res://Sonidos/SFX/level_end.wav"),
	"ding": preload("res://Sonidos/SFX/ding.wav"),
	"swipe": preload("res://Sonidos/SFX/runner_swipe.wav"),
	"jump": preload("res://Sonidos/SFX/runner_jump.wav"),
	"super_jump": preload("res://Sonidos/SFX/runner_super_jump.wav"),
	"roll": preload("res://Sonidos/SFX/runner_roll.wav"),
	"land": preload("res://Sonidos/SFX/runner_land.wav"),
	"step": preload("res://Sonidos/SFX/runner_step.wav"),
	"stumble": preload("res://Sonidos/SFX/runner_stumble.wav"),
	"crash": preload("res://Sonidos/SFX/runner_crash.wav"),
	"coin": preload("res://Sonidos/SFX/runner_coin.wav"),
	"powerup": preload("res://Sonidos/SFX/runner_powerup.wav"),
	"jetpack": preload("res://Sonidos/SFX/runner_jetpack.wav"),
	"pogo": preload("res://Sonidos/SFX/runner_pogo.wav"),
	"hoverboard": preload("res://Sonidos/SFX/runner_hoverboard.wav"),
	"shield_break": preload("res://Sonidos/SFX/runner_shield_break.wav"),
	"key": preload("res://Sonidos/SFX/runner_key.wav"),
	"whistle": preload("res://Sonidos/SFX/runner_whistle.wav"),
}

const VOCES: int = 12

var _players: Array[AudioStreamPlayer] = []
var _player_pasos: AudioStreamPlayer
var _indice: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus_destino := "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	for i in range(VOCES):
		var p := AudioStreamPlayer.new()
		p.name = "Voz_%d" % i
		p.bus = bus_destino
		add_child(p)
		_players.append(p)

	_player_pasos = AudioStreamPlayer.new()
	_player_pasos.name = "Voz_Pasos"
	_player_pasos.bus = bus_destino
	_player_pasos.stream = STREAMS["step"]
	add_child(_player_pasos)


func reproducir(nombre: String, volumen_db: float = -9.0, tono: float = 1.0) -> void:
	if not STREAMS.has(nombre) or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_indice]
	_indice = (_indice + 1) % _players.size()
	p.stream = STREAMS[nombre]
	p.volume_db = volumen_db
	p.pitch_scale = clampf(tono, 0.5, 2.0)
	p.play()


func reproducir_paso(en_techo: bool = false) -> void:
	if _player_pasos == null:
		return
	var base_pitch: float = 1.22 if en_techo else 1.0
	_player_pasos.volume_db = -17.5 if en_techo else -19.0
	_player_pasos.pitch_scale = base_pitch * _rng.randf_range(0.92, 1.09)
	_player_pasos.play()


func parar_todo() -> void:
	for p in _players:
		if p != null and p.playing:
			p.stop()
	if _player_pasos != null and _player_pasos.playing:
		_player_pasos.stop()
