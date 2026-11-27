extends GutTest

# Tests de lógica pura de «La Granja» (Versión 3: lienzo libre 24×24 con
# huellas reales multi-celda: 2×2, 3×3, 4×3/3×4 y 4×4, colisiones, movimiento
# gratis, venta al 50 %, ampliaciones de terreno, migración v1/v2 -> v3 y
# conversión diaria MG -> euros).

const AHORA_BASE := 1760000000
const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")


func before_each() -> void:
	Sistema_Granja.Ahora_Forzado = AHORA_BASE
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Granja_Estado = Sistema_Granja.Estado_Por_Defecto()
	Sistema_Granja._tabla_conversion.clear()
	Sistema_Granja._tabla_conversion.append(0.0)


func after_each() -> void:
	Sistema_Granja.Ahora_Forzado = -1
	Variables_Estaticas.Modo_Rapido = false


func _comprar() -> void:
	var r: Dictionary = Sistema_Granja.Comprar()
	assert_true(bool(r.get("ok", false)), str(r))


func _dar_monedas(cantidad: int) -> void:
	Sistema_Granja.Estado()["Monedas"] = cantidad


func _limpiar_almacen() -> void:
	Sistema_Granja.Estado()["Almacen"] = {}


func _avanzar(segundos: int) -> void:
	Sistema_Granja.Ahora_Forzado += segundos


# ------------------------------------------------------------------
# Compra, estado inicial y migraciones v1 / v2 -> v3
# ------------------------------------------------------------------

func test_01_estado_por_defecto() -> void:
	var e: Dictionary = Sistema_Granja.Estado_Por_Defecto()
	assert_false(bool(e.get("Comprada", true)))
	assert_eq(int(e.get("Version", 0)), 3)
	assert_eq(int(e.get("Monedas", -1)), 0)
	assert_eq(int(e.get("Nivel_Terreno", -1)), 0)
	assert_eq(Sistema_Granja.Area_Total(), 144)  # 12×12 inicial


func test_02_compra_inicial_y_huellas_reales() -> void:
	var dinero_antes: float = Variables_Dinamicas.Dinero
	_comprar()
	assert_eq(Sistema_Granja.Precio_Compra(), 0)
	assert_eq(Variables_Dinamicas.Dinero, dinero_antes)
	assert_true(Sistema_Granja.Comprada())
	assert_eq(int(Sistema_Granja.Estado().get("Monedas", 0)), 100)
	# Molino (4×4=16) + Gallina (2×2=4) + 4 Parcelas (4×4=16) = 36 u² de 144 u²
	assert_eq(Sistema_Granja.Area_Total(), 144)
	assert_eq(Sistema_Granja.Area_Ocupada(), 36)
	assert_eq(Sistema_Granja.Area_Libre(), 108)
	assert_eq(Sistema_Granja.Contar_Categoria("tierra"), 4)
	assert_eq(Sistema_Granja.Contar_Categoria("animal"), 1)
	assert_eq(Sistema_Granja.Contar_Categoria("maquina"), 1)
	assert_eq(Sistema_Granja.Cantidad_Almacen("maiz"), 1)
	assert_eq(Sistema_Granja.Cantidad_Almacen("trigo"), 2)
	assert_false(bool(Sistema_Granja.Comprar().get("ok", true)))


func test_03_migra_desde_v1_y_v2() -> void:
	# Migración desde v1 (Parcelas + Animales + Maquinas)
	var e1: Dictionary = Sistema_Granja.Normalizar_Estado({
		"Comprada": true,
		"Monedas": -4,
		"Parcelas_Compradas": 6,
		"Almacen": {"trigo": 3, "inventado": 8},
		"Parcelas": [
			{"cultivo": "trigo", "fin_en": AHORA_BASE + 10},
			{"cultivo": "", "fin_en": 0},
		],
		"Animales": [{"tipo": "gallina", "alimentado": false, "inicio_en": 0, "fin_en": 0}],
		"Maquinas": [{"tipo": "molino", "inicio_en": 0, "fin_en": 0}],
	})
	assert_eq(int(e1.get("Monedas", -1)), 0)
	assert_eq(int(e1["Almacen"].get("trigo", 0)), 3)
	assert_false(e1["Almacen"].has("inventado"))
	Variables_Dinamicas.Granja_Estado = e1
	assert_eq(Sistema_Granja.Contar_Categoria("tierra"), 2)
	assert_eq(Sistema_Granja.Contar_Categoria("animal"), 1)
	assert_eq(Sistema_Granja.Contar_Categoria("maquina"), 1)

	# Migración desde v2 (Celdas 5×5)
	var celdas_v2: Array = []
	for _i in range(25):
		celdas_v2.append({"categoria": ""})
	celdas_v2[6] = {"categoria": "maquina", "tipo": "panaderia", "coste_pagado": 500}
	celdas_v2[7] = {"categoria": "animal", "tipo": "vaca", "coste_pagado": 350}
	celdas_v2[8] = {"categoria": "tierra", "tipo": "tierra", "cultivo": "maiz", "inicio_en": AHORA_BASE - 10, "fin_en": AHORA_BASE + 100, "coste_pagado": 40}
	var e2: Dictionary = Sistema_Granja.Normalizar_Estado({
		"Version": 2,
		"Comprada": true,
		"Monedas": 200,
		"Nivel_Terreno": 0,
		"Celdas": celdas_v2,
	})
	Variables_Dinamicas.Granja_Estado = e2
	assert_eq(Sistema_Granja.Contar_Tipo("panaderia"), 1)
	assert_eq(Sistema_Granja.Contar_Tipo("vaca"), 1)
	assert_eq(Sistema_Granja.Contar_Categoria("tierra"), 1)
	# 12 + 9 + 4 = 25 u² sin solapes
	assert_eq(Sistema_Granja.Area_Ocupada(), 25)


# ------------------------------------------------------------------
# Colocación multi-celda, colisiones, rotación, movimiento y venta 50 %
# ------------------------------------------------------------------

func test_04_huellas_multi_celda_y_colisiones() -> void:
	_comprar()
	_dar_monedas(5000)

	# Molino inicial está en (6, 6) ocupando 4×4 -> (6..9, 6..9).
	# Intentar colocar una vaca (3×3) en (8, 8) debe fallar por solape parcial!
	var ch_solape: Dictionary = Sistema_Granja.Construir_En(8, 8, "animal", "vaca")
	assert_false(bool(ch_solape.get("ok", true)))
	assert_gt(ch_solape.get("celdas_ocupadas", []).size(), 0)

	# Intentar colocar fuera del terreno desbloqueado (Nivel 0 es 6..17 × 6..17) debe fallar!
	var ch_fuera: Dictionary = Sistema_Granja.Construir_En(4, 6, "tierra")
	assert_false(bool(ch_fuera.get("ok", true)))
	assert_gt(ch_fuera.get("celdas_bloqueadas", []).size(), 0)

	# Colocar una Panadería (4×3) en (12, 12) dentro del terreno libre -> OK!
	var r_pan: Dictionary = Sistema_Granja.Construir_En(12, 12, "maquina", "panaderia", false)
	assert_true(bool(r_pan.get("ok", false)), str(r_pan))
	assert_eq(int(r_pan.get("ancho", 0)), 4)
	assert_eq(int(r_pan.get("alto", 0)), 3)

	# Colocar una Panadería ROTADA (3×4) en (8, 12) -> ocupa (8..10, 12..15), sin solape!
	var r_pan_rot: Dictionary = Sistema_Granja.Construir_En(8, 12, "maquina", "panaderia", true)
	assert_true(bool(r_pan_rot.get("ok", false)), str(r_pan_rot))
	assert_eq(int(r_pan_rot.get("ancho", 0)), 3)
	assert_eq(int(r_pan_rot.get("alto", 0)), 4)


func test_05_mover_objeto_gratis_conservando_produccion() -> void:
	_comprar()
	# Sembrar en parcela id=3 (en 11, 7)
	var rs: Dictionary = Sistema_Granja.Sembrar(3, "trigo")
	assert_true(bool(rs.get("ok", false)), str(rs))
	var monedas_antes: int = int(Sistema_Granja.Estado()["Monedas"])
	var fin_antes: int = int(Sistema_Granja.Obtener_Objeto(3)["fin_en"])

	# Mover la parcela a (15, 14) gratis
	var rm: Dictionary = Sistema_Granja.Mover_Objeto(3, 15, 14)
	assert_true(bool(rm.get("ok", false)), str(rm))
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), monedas_antes)
	var obj: Dictionary = Sistema_Granja.Obtener_Objeto(3)
	assert_eq(int(obj["x"]), 15)
	assert_eq(int(obj["y"]), 14)
	assert_eq(str(obj["cultivo"]), "trigo")
	assert_eq(int(obj["fin_en"]), fin_antes)

	# No puede moverse encima del Molino (6..9, 6..9)
	var rm_bad: Dictionary = Sistema_Granja.Mover_Objeto(3, 7, 7)
	assert_false(bool(rm_bad.get("ok", true)))


func test_06_ampliar_terreno_hasta_24x24() -> void:
	_comprar()
	_dar_monedas(10000)
	assert_eq(Sistema_Granja.Area_Total(), 144)
	assert_true(bool(Sistema_Granja.Comprar_Mejora("ampliar_1").get("ok", false)))
	assert_eq(Sistema_Granja.Area_Total(), 224)
	assert_true(bool(Sistema_Granja.Comprar_Mejora("ampliar_2").get("ok", false)))
	assert_eq(Sistema_Granja.Area_Total(), 324)
	assert_true(bool(Sistema_Granja.Comprar_Mejora("ampliar_3").get("ok", false)))
	assert_eq(Sistema_Granja.Area_Total(), 440)
	assert_true(bool(Sistema_Granja.Comprar_Mejora("ampliar_4").get("ok", false)))
	assert_eq(Sistema_Granja.Area_Total(), 576)
	# Ahora (0, 0) está desbloqueado y acepta un molino 4×4!
	var r0: Dictionary = Sistema_Granja.Construir_En(0, 0, "maquina", "molino")
	assert_true(bool(r0.get("ok", false)), str(r0))
	assert_false(bool(Sistema_Granja.Comprar_Mejora("ampliar_4").get("ok", true)))


func test_07_coste_y_reembolso_exacto_50_por_ciento() -> void:
	_comprar()
	_dar_monedas(2000)

	# Parcela (40 -> vende 20)
	var m0: int = int(Sistema_Granja.Estado()["Monedas"])
	var c1: Dictionary = Sistema_Granja.Construir_En_Libre("tierra")
	assert_true(bool(c1.get("ok", false)), str(c1))
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), m0 - 40)
	var v1: Dictionary = Sistema_Granja.Vender_Objeto(int(c1["id"]))
	assert_true(bool(v1.get("ok", false)), str(v1))
	assert_eq(int(v1.get("reembolso", 0)), 20)
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), m0 - 20)

	# Vaca (350 -> vende 175)
	var m1: int = int(Sistema_Granja.Estado()["Monedas"])
	var c2: Dictionary = Sistema_Granja.Construir_En_Libre("animal", "vaca")
	assert_true(bool(c2.get("ok", false)), str(c2))
	var v2: Dictionary = Sistema_Granja.Vender_Objeto(int(c2["id"]))
	assert_eq(int(v2.get("reembolso", 0)), 175)
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), m1 - 175)

	# Quesería (700 -> vende 350)
	var m2: int = int(Sistema_Granja.Estado()["Monedas"])
	var c3: Dictionary = Sistema_Granja.Construir_En_Libre("maquina", "queseria")
	assert_true(bool(c3.get("ok", false)), str(c3))
	var v3: Dictionary = Sistema_Granja.Vender_Objeto(int(c3["id"]))
	assert_eq(int(v3.get("reembolso", 0)), 350)
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), m2 - 350)


# ------------------------------------------------------------------
# Cultivos, animales y máquinas
# ------------------------------------------------------------------

func test_08_plantar_y_cosechar() -> void:
	_comprar()
	_limpiar_almacen()
	var r: Dictionary = Sistema_Granja.Sembrar(3, "trigo")
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), 95)
	assert_false(bool(Sistema_Granja.Estado_Objeto(3).get("listo", true)))
	assert_false(bool(Sistema_Granja.Cosechar(3).get("ok", true)))
	_avanzar(2 * 3600 + 1)
	assert_true(bool(Sistema_Granja.Estado_Objeto(3).get("listo", false)))
	var c: Dictionary = Sistema_Granja.Cosechar(3)
	assert_true(bool(c.get("ok", false)), str(c))
	assert_eq(Sistema_Granja.Cantidad_Almacen("trigo"), 1)
	assert_eq(str(Sistema_Granja.Estado_Objeto(3).get("cultivo", "")), "")


func test_09_modo_rapido_divide_entre_siete() -> void:
	_comprar()
	Variables_Estaticas.Modo_Rapido = true
	var r: Dictionary = Sistema_Granja.Sembrar(3, "trigo")
	assert_true(bool(r.get("ok", false)), str(r))
	assert_between(int(r.get("duracion", 0)), 1020, 1035)
	_avanzar(1030)
	assert_true(bool(Sistema_Granja.Estado_Objeto(3).get("listo", false)))


func test_10_alimentar_y_recoger_gallina() -> void:
	_comprar()
	# Gallina inicial es id=2
	Sistema_Granja.Estado()["Almacen"]["maiz"] = 1
	var r: Dictionary = Sistema_Granja.Alimentar(2)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(Sistema_Granja.Cantidad_Almacen("maiz"), 0)
	assert_false(bool(Sistema_Granja.Recoger_Animal(2).get("ok", true)))
	_avanzar(4 * 3600 + 1)
	var c: Dictionary = Sistema_Granja.Recoger_Animal(2)
	assert_true(bool(c.get("ok", false)), str(c))
	assert_eq(Sistema_Granja.Cantidad_Almacen("huevo"), 2)
	assert_false(bool(Sistema_Granja.Estado_Objeto(2).get("alimentado", true)))


func test_11_cadena_molino_y_panaderia() -> void:
	_comprar()
	_dar_monedas(2000)
	# Molino inicial es id=1
	Sistema_Granja.Estado()["Almacen"]["trigo"] = 2
	assert_true(bool(Sistema_Granja.Cargar_Maquina(1).get("ok", false)))
	_avanzar(2 * 3600 + 1)
	assert_true(bool(Sistema_Granja.Recoger_Maquina(1).get("ok", false)))
	assert_eq(Sistema_Granja.Cantidad_Almacen("harina"), 1)

	var r_pan: Dictionary = Sistema_Granja.Comprar_Maquina("panaderia")
	assert_true(bool(r_pan.get("ok", false)), str(r_pan))
	var id_pan: int = int(r_pan.get("id", -1))
	Sistema_Granja.Estado()["Almacen"]["huevo"] = 1
	assert_true(bool(Sistema_Granja.Cargar_Maquina(id_pan).get("ok", false)))
	_avanzar(3 * 3600 + 1)
	assert_true(bool(Sistema_Granja.Recoger_Maquina(id_pan).get("ok", false)))
	assert_eq(Sistema_Granja.Cantidad_Almacen("pan"), 1)


func test_12_maquina_sin_ingredientes() -> void:
	_comprar()
	_limpiar_almacen()
	var r: Dictionary = Sistema_Granja.Cargar_Maquina(1)
	assert_false(bool(r.get("ok", true)))
	assert_true(str(r.get("motivo", "")).contains("Necesitas"))


# ------------------------------------------------------------------
# Ventas de almacén, velocidad y conversión diaria
# ------------------------------------------------------------------

func test_13_vender_todo_almacen() -> void:
	_comprar()
	_limpiar_almacen()
	Sistema_Granja.Estado()["Almacen"]["trigo"] = 2
	Sistema_Granja.Estado()["Almacen"]["queso"] = 1
	var monedas_antes: int = int(Sistema_Granja.Estado()["Monedas"])
	var r: Dictionary = Sistema_Granja.Vender_Todo()
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(int(r.get("total", 0)), 12 * 2 + 65)
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), monedas_antes + 89)
	assert_true(Sistema_Granja.Almacen().is_empty())


func test_14_mejora_de_velocidad() -> void:
	_comprar()
	_dar_monedas(3000)
	assert_true(bool(Sistema_Granja.Comprar_Mejora("velocidad_1").get("ok", false)))
	assert_between(Sistema_Granja.Duracion_Segundos(2.0), 6400, 6500)
	assert_true(bool(Sistema_Granja.Comprar_Mejora("velocidad_2").get("ok", false)))
	assert_between(Sistema_Granja.Duracion_Segundos(2.0), 5700, 5800)


func test_15_conversion_diaria_curva_y_reset() -> void:
	_comprar()
	var r1: Dictionary = Sistema_Granja.Cambiar(10)
	assert_true(bool(r1.get("ok", false)), str(r1))
	assert_almost_eq(float(r1.get("euros", 0.0)), 10.0, 0.01)
	assert_eq(int(Sistema_Granja.Convertido_Hoy()), 10)
	assert_almost_eq(Variables_Dinamicas.Dinero, 1010.0, 0.01)

	var r2: Dictionary = Sistema_Granja.Cambiar(10)
	assert_almost_eq(float(r2.get("euros", 0.0)), 4.40, 0.02)

	# Cambiar en trozos no mejora la tasa
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Granja_Estado = Sistema_Granja.Estado_Por_Defecto()
	_comprar()
	Sistema_Granja.Cambiar(25)
	Sistema_Granja.Cambiar(25)
	var troceado: float = Variables_Dinamicas.Dinero - 1000.0
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Granja_Estado = Sistema_Granja.Estado_Por_Defecto()
	_comprar()
	Sistema_Granja.Cambiar(50)
	assert_almost_eq(troceado, Variables_Dinamicas.Dinero - 1000.0, 0.02)

	# Reset diario + suelo 0,10
	_avanzar(2 * 86400)
	assert_eq(int(Sistema_Granja.Convertido_Hoy()), 0)
	Sistema_Granja.Estado()["Monedas"] = 3000
	Sistema_Granja.Estado()["Convertido_Hoy"] = 2000
	Sistema_Granja.Estado()["Dia_Conversion"] = Sistema_Granja.Dia_Granja()
	assert_almost_eq(float(Sistema_Granja.Tasa_Marginal()), 0.10, 0.001)


func test_16_offline_cosecha() -> void:
	_comprar()
	_limpiar_almacen()
	var obj: Dictionary = Sistema_Granja.Obtener_Objeto(3)
	obj["cultivo"] = "trigo"
	obj["inicio_en"] = AHORA_BASE - 10000
	obj["fin_en"] = AHORA_BASE - 100
	assert_true(bool(Sistema_Granja.Estado_Objeto(3).get("listo", false)))
	var c: Dictionary = Sistema_Granja.Cosechar(3)
	assert_true(bool(c.get("ok", false)), str(c))
	assert_eq(Sistema_Granja.Cantidad_Almacen("trigo"), 1)


func test_17_ingresar_euros_a_mg_uno_a_uno() -> void:
	_comprar()
	Variables_Dinamicas.Dinero = 500.0
	var mg_antes: int = int(Sistema_Granja.Estado()["Monedas"])
	var prev: Dictionary = Sistema_Granja.Previsualizar_Ingreso(250)
	assert_eq(int(prev.get("euros", 0)), 250)
	assert_eq(int(prev.get("monedas", 0)), 250)

	var r: Dictionary = Sistema_Granja.Ingresar(250)
	assert_true(bool(r.get("ok", false)), str(r))
	assert_eq(int(r.get("euros", 0)), 250)
	assert_eq(int(r.get("monedas", 0)), 250)
	assert_almost_eq(Variables_Dinamicas.Dinero, 250.0, 0.01)
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), mg_antes + 250)
	# Ingresar no altera el contador diario de cobro (MG -> €).
	assert_eq(Sistema_Granja.Convertido_Hoy(), 0)

	# Intentar ingresar más de lo disponible se recorta al saldo real y si es 0 falla.
	var r2: Dictionary = Sistema_Granja.Ingresar(1000)
	assert_true(bool(r2.get("ok", false)))
	assert_eq(int(r2.get("monedas", 0)), 250)
	assert_almost_eq(Variables_Dinamicas.Dinero, 0.0, 0.01)
	assert_false(bool(Sistema_Granja.Ingresar(10).get("ok", true)))
