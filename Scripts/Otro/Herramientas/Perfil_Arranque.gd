extends SceneTree
## Diagnóstico de arranque: mide la carga de recursos pesados y la instancia
## de la escena principal. Uso:
##   godot --headless --path . --script res://Scripts/Otro/Herramientas/Perfil_Arranque.gd

func _initialize() -> void:
	_medir("Menu.tscn", func(): return load("res://Escenas/Menu/Menu.tscn"))
	_medir("Arte_Cocina.gd", func(): return load("res://Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd"))
	_medir("Minijuego_Cocina.tscn", func(): return load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn"))
	_medir("Escena principal.tscn", func(): return load("res://Escenas/Escena_Principal/Escena principal.tscn"))
	print("MEMORIA estática tras cargas: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	quit()


func _medir(nombre: String, fn: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	var r = fn.call()
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	print("[PERFIL] %-28s %8.1f ms  -> %s" % [nombre, ms, str(r)])
