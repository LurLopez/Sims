class_name Runner_Texturas_3D
extends RefCounted

# ============================================================================
# CARGADOR DE TEXTURAS PBR ESTILIZADAS (ESTILO SUBWAY SURFERS) PARA RUNNER 3D
#
# Carga las texturas pre-horneadas de alta resolución (Albedo, Normal y
# Emission nocturna) generadas en Imagenes/Minijuego_Correr/Texturas3D/ por
# tools/generar_texturas_runner_3d.py, con respaldo instantáneo si faltara
# alguna textura.
# ============================================================================

const BASE_DIR := "res://Imagenes/Minijuego_Correr/Texturas3D/"

var balasto_albedo: Texture2D
var balasto_normal: Texture2D
var traviesa_albedo: Texture2D
var traviesa_normal: Texture2D
var anden_albedo: Texture2D
var anden_normal: Texture2D
var muro_graffiti_a: Texture2D
var muro_graffiti_b: Texture2D
var muro_normal: Texture2D

var tren_lateral: Array[Texture2D] = []
var tren_frente: Array[Texture2D] = []
var tren_lateral_normal: Texture2D
var tren_lateral_emission: Texture2D
var tren_frente_emission: Texture2D
var tren_techo_albedo: Texture2D
var tren_techo_normal: Texture2D

var vagon_bl_carroceria: Array[Texture2D] = []
var vagon_bl_letrero: Array[Texture2D] = []
var vagon_bl_cristal_em: Texture2D

var rampa_albedo: Texture2D
var rampa_emission: Texture2D
var valla_peligro_albedo: Texture2D
var arco_paso_albedo: Texture2D

var edificios: Array[Texture2D] = []
var edificio_normal: Texture2D
var edificio_emission: Texture2D

var carteles: Array[Texture2D] = []
var sombra_contacto: Texture2D


func _init() -> void:
	balasto_albedo = _cargar("balasto_albedo.png")
	balasto_normal = _cargar("balasto_normal.png")
	traviesa_albedo = _cargar("traviesa_albedo.png")
	traviesa_normal = _cargar("traviesa_normal.png")
	anden_albedo = _cargar("anden_albedo.png")
	anden_normal = _cargar("anden_normal.png")
	muro_graffiti_a = _cargar("muro_graffiti_a_albedo.png")
	muro_graffiti_b = _cargar("muro_graffiti_b_albedo.png")
	muro_normal = _cargar("muro_graffiti_normal.png")

	tren_lateral.clear()
	tren_frente.clear()
	for i in range(4):
		tren_lateral.append(_cargar("tren_lateral_%d.png" % i))
		tren_frente.append(_cargar("tren_frente_%d.png" % i))
	tren_lateral_normal = _cargar("tren_lateral_normal.png")
	tren_lateral_emission = _cargar("tren_lateral_emission.png")
	tren_frente_emission = _cargar("tren_frente_emission.png")
	tren_techo_albedo = _cargar("tren_techo_albedo.png")
	tren_techo_normal = _cargar("tren_techo_normal.png")

	vagon_bl_carroceria.clear()
	vagon_bl_letrero.clear()
	for i in range(4):
		vagon_bl_carroceria.append(_cargar("vagon_bl_carroceria_%d.png" % i))
		vagon_bl_letrero.append(_cargar("vagon_bl_letrero_%d.png" % i))
	vagon_bl_cristal_em = _cargar("vagon_bl_cristal_em.png")

	rampa_albedo = _cargar("rampa_albedo.png")
	rampa_emission = _cargar("rampa_emission.png")
	valla_peligro_albedo = _cargar("valla_peligro_albedo.png")
	arco_paso_albedo = _cargar("arco_paso_albedo.png")

	edificios.clear()
	for i in range(5):
		edificios.append(_cargar("edificio_%d.png" % i))
	edificio_normal = _cargar("edificio_normal.png")
	edificio_emission = _cargar("edificio_emission.png")

	carteles.clear()
	for i in range(3):
		carteles.append(_cargar("cartel_puente_%d.png" % i))

	sombra_contacto = _cargar("sombra_contacto.png")


static func _cargar(archivo: String) -> Texture2D:
	var ruta: String = BASE_DIR + archivo
	if ResourceLoader.exists(ruta):
		var res := ResourceLoader.load(ruta) as Texture2D
		if res != null:
			return res
	var abs_path: String = ProjectSettings.globalize_path(ruta)
	if FileAccess.file_exists(abs_path):
		var img := Image.new()
		if img.load(abs_path) == OK:
			img.generate_mipmaps()
			return ImageTexture.create_from_image(img)
	var fallback := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	fallback.fill(Color.MAGENTA)
	return ImageTexture.create_from_image(fallback)
