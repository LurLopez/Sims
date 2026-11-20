extends Node

var t := 0.0

func _ready() -> void:
	print("CAPTURA DEBUG READY")
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	if t > 2.0:
		print("CAPTURANDO...")
		var img := get_viewport().get_texture().get_image()
		print("IMG ", img.get_width(), "x", img.get_height())
		img.save_png("/tmp/opencode/test_min.png")
		print("GUARDADO")
		get_tree().quit()
