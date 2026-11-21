extends GutTest

# Tests de alineación del arte del Minijuego de Cocina:
# - Los iconos de la bandeja comparten línea de base y centro horizontal.
# - Las regiones de contenido ignoran el margen transparente de los PNG.
# - La pila de la hamburguesa mantiene proporciones compactas y coherentes.

const ANCHO_ICONO: float = 86.0
const ALTO_ICONO: float = 56.0
const CENTRO_X_ICONO: float = 49.0
const BASE_Y_ICONO: float = 70.0

var _texturas: Array[Texture2D] = []


func before_all() -> void:
	_texturas = [
		Arte_Cocina.TEX_PAN_SUP,
		Arte_Cocina.TEX_CARNE_HECHA,
		Arte_Cocina.TEX_QUESO,
		Arte_Cocina.TEX_LECHUGA,
		Arte_Cocina.TEX_TOMATE,
		Arte_Cocina.TEX_PATATAS,
	]


func test_01_regiones_de_contenido_sin_margen_transparente() -> void:
	for tex in _texturas:
		var region := Arte_Cocina.region_contenido(tex)
		assert_true(region.size.x > 0.0 and region.size.y > 0.0,
			"La región de %s no puede estar vacía" % tex.resource_path)
		assert_true(region.size.x <= float(tex.get_width()) and region.size.y <= float(tex.get_height()),
			"La región de %s no puede superar la textura" % tex.resource_path)
		assert_almost_eq(region.get_center().x, float(tex.get_width()) * 0.5, 0.6,
			"El contenido de %s debe estar centrado horizontalmente" % tex.resource_path)


func test_02_iconos_bandeja_comparten_base_y_centro() -> void:
	for tex in _texturas:
		var r := Arte_Cocina.rect_icono_alineado(tex, CENTRO_X_ICONO, BASE_Y_ICONO,
			ANCHO_ICONO, ALTO_ICONO)
		assert_almost_eq(r.end.y, BASE_Y_ICONO, 0.01,
			"El icono de %s debe apoyarse en la misma línea de base" % tex.resource_path)
		assert_almost_eq(r.get_center().x, CENTRO_X_ICONO, 0.01,
			"El icono de %s debe quedar centrado en su columna" % tex.resource_path)
		assert_true(r.size.x <= ANCHO_ICONO + 0.01 and r.size.y <= ALTO_ICONO + 0.01,
			"El icono de %s no debe desbordar su caja" % tex.resource_path)


func test_03_pan_de_la_bandeja_es_el_pan_superior() -> void:
	assert_eq(Arte_Cocina.textura_item("pan"), Arte_Cocina.TEX_PAN_SUP,
		"La bandeja debe mostrar el pan superior, igual que el fantasma del plato")


func test_04_hamburguesa_compacta_y_centrada() -> void:
	var alto_120 := Arte_Cocina.alto_hamburguesa(120.0, 1, true, true, true)
	assert_between(alto_120, 100.0, 130.0,
		"La hamburguesa completa debe ser compacta, no una torre desproporcionada")
	assert_almost_eq(Arte_Cocina.alto_hamburguesa(60.0, 1, true, true, true), alto_120 * 0.5, 0.01,
		"El alto debe escalar linealmente con el ancho")


func test_05_capas_en_orden_y_con_panes_iguales() -> void:
	var capas := Arte_Cocina._capas_hamburguesa(1, true, true, true)
	assert_true(capas.size() >= 6, "La hamburguesa completa debe tener todas sus capas")
	assert_eq(str(capas[0]["tex"].resource_path), str(Arte_Cocina.TEX_PAN_INF.resource_path),
		"La primera capa debe ser el pan inferior")
	assert_eq(str(capas[capas.size() - 1]["tex"].resource_path), str(Arte_Cocina.TEX_PAN_SUP.resource_path),
		"La última capa debe ser el pan superior")
	assert_almost_eq(float(capas[0]["ancho"]), float(capas[capas.size() - 1]["ancho"]), 0.01,
		"Los dos panes deben compartir el mismo ancho")
	var anterior: float = -1000.0
	for capa in capas:
		var abajo: float = float(capa["abajo"])
		assert_true(abajo >= anterior, "Las capas deben apilarse de abajo hacia arriba")
		anterior = abajo


func test_06_ancho_para_alto_inverso() -> void:
	var alto := Arte_Cocina.alto_hamburguesa(120.0, 2, true, false, false)
	assert_almost_eq(Arte_Cocina.ancho_para_alto(alto, 2, true, false, false), 120.0, 0.02,
		"ancho_para_alto debe ser la inversa de alto_hamburguesa")
