extends SceneTree
## Mide la instanciación completa de la escena principal (modo nuevo).
## Uso: godot --headless --path . --script res://Scripts/Otro/Herramientas/Perfil_Escena_Principal.gd

func _initialize() -> void:
	var ve = root.get_node_or_null("Variables_Estaticas")
	var vd = root.get_node_or_null("Variables_Dinamicas")
	if ve != null:
		ve.First_Time = true
		ve.Tutorial_Completado = true
		ve.Modo_Rapido = false
		ve.Apariencia = Apariencia_Personaje.por_defecto()
	if vd != null:
		vd.Matriz_Jugador = []
		vd.Progreso = []
		vd.Necesidades_Basicas = []

	var t0 := Time.get_ticks_usec()
	var packed: PackedScene = load("res://Escenas/Escena_Principal/Escena principal.tscn")
	var t_load := Time.get_ticks_usec()
	print("[PERFIL] load tscn: %.1f ms" % ((t_load - t0) / 1000.0))

	var inst = packed.instantiate()
	var t_inst := Time.get_ticks_usec()
	print("[PERFIL] instantiate: %.1f ms" % ((t_inst - t_load) / 1000.0))

	root.add_child(inst)
	await inst.ready
	var t_ready := Time.get_ticks_usec()
	print("[PERFIL] _ready completo: %.1f ms" % ((t_ready - t_inst) / 1000.0))
	print("[PERFIL] MEMORIA: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))

	for i in range(5):
		await process_frame
	var t_frames := Time.get_ticks_usec()
	print("[PERFIL] 5 frames: %.1f ms" % ((t_frames - t_ready) / 1000.0))
	print("[PERFIL] MEMORIA final: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	quit()
