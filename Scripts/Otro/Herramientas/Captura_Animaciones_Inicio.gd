extends Node
## QA visual de movimiento: captura una tira de fotogramas por pose para
## comprobar el ciclo base y la transición hacia una micro-acción.
## Uso:
##   godot --path . --resolution 720x1280 res://Escenas/Herramientas/Captura_Animaciones_Inicio.tscn

const DIR_SALIDA := "user://capturas_animaciones_inicio"
const TAM := Vector2(560.0, 191.0)
const FOTOGRAMAS := 10
const INTERVALO := 0.24

const ACTIVIDADES: Dictionary = {
	"correr": "Salir_A_Correr",
	"dormir": "Dormir",
	"comer": "Comer_Tupper",
	"duchar": "Duchar",
	"estudiar": "Estudiar",
	"tv": "Ver_La_Television",
	"manualidades": "Practicar_Manualidades",
	"cocinar": "Cocinar",
	"fiesta": "Salir_De_Fiesta",
	"futbol": "Partido_Futbol",
	"trabajar": "Trabajar_En_Comida_Rapida",
}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	for clave in ACTIVIDADES.keys():
		await _capturar_tira(clave, str(ACTIVIDADES[clave]))
	print("Tiras guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _capturar_tira(clave: String, actividad: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(TAM.x) + 24, int(TAM.y) + 24)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var fondo := ColorRect.new()
	fondo.color = Color("#dbe4ee")
	fondo.size = Vector2(vp.size)
	vp.add_child(fondo)
	var escenario := Escenario_Actividad.new()
	escenario.position = Vector2(12.0, 12.0)
	escenario.size = TAM
	escenario.custom_minimum_size = TAM
	vp.add_child(escenario)
	escenario.actualizar_estado(actividad, false, Apariencia_Personaje.por_defecto(), 780, "Mesa_Premium", "Deportista")
	await get_tree().create_timer(0.5).timeout
	for i in range(FOTOGRAMAS):
		if i == 3:
			escenario._disparar_variacion_aleatoria()
		await RenderingServer.frame_post_draw
		var imagen := vp.get_texture().get_image()
		if imagen != null and not imagen.is_empty():
			imagen.save_png(DIR_SALIDA.path_join("%s_%02d.png" % [clave, i]))
		await get_tree().create_timer(INTERVALO).timeout
	vp.queue_free()
	await get_tree().process_frame
