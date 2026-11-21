#!/usr/bin/env python3
"""Exporta la mascota base del logo (Sim por defecto) a PNG transparente.

Uso:
  godot --path . --script res://Scripts/Otro/Herramientas/Exportar_Mascota_Logo.gd

El PNG resultante lo consume `Arte_Fuente/Marca/generar_logo.py`.
"""
extends SceneTree

const RUTA_SALIDA := "res://Arte_Fuente/Marca/mascota_logo.png"
const TAMANO := 2048


func _initialize() -> void:
	call_deferred("_exportar")


func _exportar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUTA_SALIDA.get_base_dir()))
	var vp := SubViewport.new()
	vp.size = Vector2i(TAMANO, TAMANO)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var retrato := Personaje_Visual.new()
	retrato.apariencia = Apariencia_Personaje.por_defecto()
	retrato.modo = "retrato"
	retrato.margen_retrato = 12.0
	retrato.expresion = "sonrisa"
	retrato.animar_idle = false
	retrato.dibujar_fondo_sunburst = true
	retrato.color_fondo_base = Color("#fde3c8")
	retrato.color_fondo_rayo = Color("#f8c795")
	retrato.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(retrato)

	for i in range(8):
		await process_frame
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("No se pudo renderizar la mascota del logo")
		quit(1)
		return
	var error := img.save_png(ProjectSettings.globalize_path(RUTA_SALIDA))
	if error != OK:
		push_error("No se pudo guardar la mascota del logo (error %d)" % error)
		quit(1)
		return
	print("Mascota del logo exportada: ", RUTA_SALIDA)
	quit()
