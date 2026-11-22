extends Node
## Herramienta de QA visual para revisar todas las poses del escenario de Inicio.
## Uso:
##   godot --path . --resolution 720x1280 res://Escenas/Herramientas/Captura_Poses_Inicio.tscn
## Guarda una lámina por pose (estado base + micro-acción) en
## user://capturas_poses_inicio/.

const DIR_SALIDA := "user://capturas_poses_inicio"
const TAM := Vector2(640.0, 219.0)
const TAM_HOME := Vector2(664.0, 184.0)
const TAM_MENU := Vector2(450.0, 184.0)

const ACTIVIDADES: Dictionary = {
	"idle": "",
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
		await _capturar_pose(clave, str(ACTIVIDADES[clave]), TAM, "base")
	await get_tree().process_frame
	for clave in ACTIVIDADES.keys():
		await _capturar_pose(clave, str(ACTIVIDADES[clave]), TAM_HOME, "home")
	await get_tree().process_frame
	for clave in ACTIVIDADES.keys():
		await _capturar_pose(clave, str(ACTIVIDADES[clave]), TAM_MENU, "menu")
	print("Capturas de poses guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _capturar_pose(clave: String, actividad: String, tam: Vector2, sufijo: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(tam.x) + 32, int(tam.y) + 32)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var fondo := ColorRect.new()
	fondo.color = Color("#dbe4ee")
	fondo.size = Vector2(vp.size)
	vp.add_child(fondo)

	var escenario := Escenario_Actividad.new()
	escenario.position = Vector2(16.0, 16.0)
	escenario.size = tam
	escenario.custom_minimum_size = tam
	vp.add_child(escenario)
	escenario.actualizar_estado(actividad, false, Apariencia_Personaje.por_defecto(), 780, "Mesa_Premium", "Deportista")
	await get_tree().create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	_guardar(vp, "%s_%s_base.png" % [clave, sufijo])

	escenario._disparar_variacion_aleatoria()
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	_guardar(vp, "%s_%s_variacion.png" % [clave, sufijo])

	vp.queue_free()
	await get_tree().process_frame


func _guardar(vp: SubViewport, nombre: String) -> void:
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta)
