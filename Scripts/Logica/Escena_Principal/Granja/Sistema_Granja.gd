extends Node

# ============================================================================
# Autoload de «La Granja» (Versión 3 — Lienzo libre 24×24 con huellas reales).
#
# Estado persistente en Variables_Dinamicas.Granja_Estado.
# Cada objeto colocado tiene posición (x, y) y tamaño real en celdas de rejilla
# (cultivo 2×2, gallina 2×2, vaca 3×3, quesería 3×3, panadería 4×3 rotable a
# 3×4, molino 4×4). Sin límites por tipo: solo importa el terreno desbloqueado.
# Todo elemento puede moverse gratis en el mapa o venderse al 50 % de su coste.
# ============================================================================

const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")

# QA: durante las pruebas la granja se compra gratis. Poner en false para
# publicar con el precio real de Datos_Granja.PRECIO_COMPRA.
const GRANJA_GRATIS_QA: bool = true

var Ahora_Forzado: int = -1
var _tabla_conversion: Array[float] = [0.0]


func _ready() -> void:
	if Variables_Dinamicas.Granja_Estado.is_empty():
		Variables_Dinamicas.Granja_Estado = Estado_Por_Defecto()


func Ahora() -> int:
	if Ahora_Forzado >= 0:
		return Ahora_Forzado
	return int(Time.get_unix_time_from_system())


# ------------------------------------------------------------------
# Estado y normalización (con migración automática desde v1 y v2)
# ------------------------------------------------------------------

func Estado_Por_Defecto() -> Dictionary:
	return {
		"Version": Datos.VERSION_ESTADO,
		"Comprada": false,
		"Monedas": 0,
		"Convertido_Hoy": 0,
		"Dia_Conversion": "",
		"Nivel_Terreno": 0,
		"Siguiente_Id": 1,
		"Objetos": [],
		"Almacen": {},
		"Velocidad": 0,
	}


func Estado() -> Dictionary:
	var estado = Variables_Dinamicas.Granja_Estado
	if not (estado is Dictionary) or estado.is_empty() or not estado.has("Objetos"):
		estado = Normalizar_Estado(estado)
		Variables_Dinamicas.Granja_Estado = estado
	return estado


func Normalizar_Estado(datos) -> Dictionary:
	var estado: Dictionary = Estado_Por_Defecto()
	if not (datos is Dictionary):
		estado["Dia_Conversion"] = Dia_Granja()
		return estado

	estado["Comprada"] = bool(datos.get("Comprada", false))
	estado["Monedas"] = maxi(0, int(datos.get("Monedas", 0)))
	estado["Velocidad"] = clampi(int(datos.get("Velocidad", 0)), 0, 3)

	var almacen = datos.get("Almacen", {})
	if almacen is Dictionary:
		for clave in almacen.keys():
			var k: String = str(clave)
			if not Datos.es_vendible(k):
				continue
			var cantidad: int = maxi(0, int(almacen[clave]))
			if cantidad > 0:
				estado["Almacen"][k] = cantidad

	if datos.has("Objetos") and datos["Objetos"] is Array:
		estado["Nivel_Terreno"] = clampi(int(datos.get("Nivel_Terreno", 0)), 0, Datos.NIVEL_TERRENO_MAX)
		var max_id: int = 0
		var ocupadas: Dictionary = {}
		for item in datos["Objetos"]:
			if not (item is Dictionary):
				continue
			var norm: Dictionary = _Normalizar_Objeto(item)
			if norm.is_empty():
				continue
			if int(norm["id"]) <= 0:
				max_id += 1
				norm["id"] = max_id
			else:
				max_id = maxi(max_id, int(norm["id"]))
			# Validar posición dentro del terreno y sin solape; si falla, recolocar.
			var x: int = int(norm["x"])
			var y: int = int(norm["y"])
			var w: int = int(norm["ancho"])
			var h: int = int(norm["alto"])
			if not _Rect_Valido_En_Estado(x, y, w, h, int(estado["Nivel_Terreno"]), ocupadas):
				var hueco := _Buscar_Hueco_En_Estado(w, h, estado, ocupadas)
				if hueco.x < 0:
					continue
				norm["x"] = hueco.x
				norm["y"] = hueco.y
			_Marcar_Ocupadas(int(norm["x"]), int(norm["y"]), w, h, ocupadas)
			estado["Objetos"].append(norm)
		estado["Siguiente_Id"] = maxi(max_id + 1, int(datos.get("Siguiente_Id", max_id + 1)))
	elif datos.has("Celdas") and datos["Celdas"] is Array:
		_Migrar_Desde_V2(datos, estado)
	else:
		_Migrar_Desde_V1(datos, estado)

	estado["Dia_Conversion"] = Dia_Granja()
	estado["Convertido_Hoy"] = 0
	if bool(estado.get("Comprada", false)):
		if str(datos.get("Dia_Conversion", "")) == Dia_Granja():
			estado["Convertido_Hoy"] = maxi(0, int(datos.get("Convertido_Hoy", 0)))
	_Asegurar_Dia(estado)
	return estado


func _Normalizar_Objeto(o: Dictionary) -> Dictionary:
	var cat: String = str(o.get("categoria", ""))
	var tipo: String = str(o.get("tipo", ""))
	var rotado: bool = bool(o.get("rotado", false))
	var volteado: bool = bool(o.get("volteado", false))
	var id: int = maxi(0, int(o.get("id", 0)))
	var x: int = int(o.get("x", 0))
	var y: int = int(o.get("y", 0))

	if cat == "tierra":
		tipo = "tierra"
		rotado = false
		var tam_t := Datos.tamano_objeto("tierra", "tierra", false)
		var cultivo: String = str(o.get("cultivo", ""))
		if not Datos.CULTIVOS.has(cultivo):
			cultivo = ""
		var fin: int = int(o.get("fin_en", 0)) if cultivo != "" else 0
		var inicio: int = int(o.get("inicio_en", 0)) if cultivo != "" else 0
		if fin > 0 and inicio <= 0:
			inicio = fin - Duracion_Segundos(float(Datos.cultivo(cultivo).get("horas", 1.0)))
		var coste: int = int(o.get("coste_pagado", Datos.PRECIO_PARCELA_TIERRA))
		if coste <= 0:
			coste = Datos.PRECIO_PARCELA_TIERRA
		return {
			"id": id, "categoria": "tierra", "tipo": "tierra",
			"x": x, "y": y, "ancho": tam_t.x, "alto": tam_t.y,
			"rotado": false, "volteado": volteado,
			"cultivo": cultivo, "alimentado": false,
			"inicio_en": inicio, "fin_en": fin, "coste_pagado": coste,
		}
	if cat == "animal":
		if not Datos.ANIMALES.has(tipo):
			return {}
		rotado = rotado and Datos.es_rotable("animal", tipo)
		var tam_a := Datos.tamano_objeto("animal", tipo, rotado)
		var coste_a: int = int(o.get("coste_pagado", Datos.precio_construccion("animal", tipo)))
		if coste_a <= 0:
			coste_a = Datos.precio_construccion("animal", tipo)
		return {
			"id": id, "categoria": "animal", "tipo": tipo,
			"x": x, "y": y, "ancho": tam_a.x, "alto": tam_a.y,
			"rotado": rotado, "volteado": volteado,
			"cultivo": "", "alimentado": bool(o.get("alimentado", false)),
			"inicio_en": int(o.get("inicio_en", 0)), "fin_en": int(o.get("fin_en", 0)),
			"coste_pagado": coste_a,
		}
	if cat == "maquina":
		if not Datos.MAQUINAS.has(tipo):
			return {}
		rotado = rotado and Datos.es_rotable("maquina", tipo)
		var tam_m := Datos.tamano_objeto("maquina", tipo, rotado)
		var coste_m: int = int(o.get("coste_pagado", Datos.precio_construccion("maquina", tipo)))
		if coste_m <= 0:
			coste_m = Datos.precio_construccion("maquina", tipo)
		return {
			"id": id, "categoria": "maquina", "tipo": tipo,
			"x": x, "y": y, "ancho": tam_m.x, "alto": tam_m.y,
			"rotado": rotado, "volteado": volteado,
			"cultivo": "", "alimentado": false,
			"inicio_en": int(o.get("inicio_en", 0)), "fin_en": int(o.get("fin_en", 0)),
			"coste_pagado": coste_m,
		}
	return {}


func _Rect_Valido_En_Estado(x: int, y: int, w: int, h: int, nivel: int, ocupadas: Dictionary) -> bool:
	var rect_t := Datos.rect_terreno(nivel)
	for dy in range(h):
		for dx in range(w):
			var p := Vector2i(x + dx, y + dy)
			if not Datos.celda_en_mapa(p.x, p.y) or not rect_t.has_point(p):
				return false
			if ocupadas.has(p):
				return false
	return true


func _Marcar_Ocupadas(x: int, y: int, w: int, h: int, ocupadas: Dictionary) -> void:
	for dy in range(h):
		for dx in range(w):
			ocupadas[Vector2i(x + dx, y + dy)] = true


func _Buscar_Hueco_En_Estado(w: int, h: int, estado: Dictionary, ocupadas: Dictionary) -> Vector2i:
	var nivel: int = clampi(int(estado.get("Nivel_Terreno", 0)), 0, Datos.NIVEL_TERRENO_MAX)
	var rect_t := Datos.rect_terreno(nivel)
	for gy in range(rect_t.position.y, rect_t.end.y - h + 1):
		for gx in range(rect_t.position.x, rect_t.end.x - w + 1):
			if _Rect_Valido_En_Estado(gx, gy, w, h, nivel, ocupadas):
				return Vector2i(gx, gy)
	return Vector2i(-1, -1)


func _Colocar_Lista_Migrada(objetos_raw: Array[Dictionary], nivel_inicial: int, estado: Dictionary) -> void:
	var nivel: int = clampi(nivel_inicial, 0, Datos.NIVEL_TERRENO_MAX)
	estado["Nivel_Terreno"] = nivel
	var ocupadas: Dictionary = {}
	var next_id: int = 1
	# Ordenar grandes primero para empaquetar bien.
	objetos_raw.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["ancho"]) * int(a["alto"]) > int(b["ancho"]) * int(b["alto"])
	)
	for obj in objetos_raw:
		var w: int = int(obj["ancho"])
		var h: int = int(obj["alto"])
		var pos := _Buscar_Hueco_En_Estado(w, h, estado, ocupadas)
		while pos.x < 0 and int(estado["Nivel_Terreno"]) < Datos.NIVEL_TERRENO_MAX:
			estado["Nivel_Terreno"] = int(estado["Nivel_Terreno"]) + 1
			pos = _Buscar_Hueco_En_Estado(w, h, estado, ocupadas)
		if pos.x < 0:
			continue
		obj["id"] = next_id
		next_id += 1
		obj["x"] = pos.x
		obj["y"] = pos.y
		_Marcar_Ocupadas(pos.x, pos.y, w, h, ocupadas)
		estado["Objetos"].append(obj)
	estado["Siguiente_Id"] = next_id


func _Migrar_Desde_V2(datos: Dictionary, estado: Dictionary) -> void:
	if not bool(datos.get("Comprada", false)):
		return
	var objetos: Array[Dictionary] = []
	for c in datos.get("Celdas", []):
		if not (c is Dictionary):
			continue
		var norm: Dictionary = _Normalizar_Objeto(c)
		if not norm.is_empty():
			objetos.append(norm)
	_Colocar_Lista_Migrada(objetos, int(datos.get("Nivel_Terreno", 0)), estado)


func _Migrar_Desde_V1(datos: Dictionary, estado: Dictionary) -> void:
	if not bool(datos.get("Comprada", false)):
		return
	var objetos: Array[Dictionary] = []
	var maquinas = datos.get("Maquinas", [])
	if maquinas is Array:
		for m in maquinas:
			if m is Dictionary and Datos.MAQUINAS.has(str(m.get("tipo", ""))):
				var t: String = str(m["tipo"])
				objetos.append(_Normalizar_Objeto({
					"categoria": "maquina", "tipo": t,
					"inicio_en": int(m.get("inicio_en", 0)), "fin_en": int(m.get("fin_en", 0)),
					"coste_pagado": Datos.precio_construccion("maquina", t),
				}))
	var animales = datos.get("Animales", [])
	if animales is Array:
		for a in animales:
			if a is Dictionary and Datos.ANIMALES.has(str(a.get("tipo", ""))):
				var t: String = str(a["tipo"])
				objetos.append(_Normalizar_Objeto({
					"categoria": "animal", "tipo": t,
					"alimentado": bool(a.get("alimentado", false)),
					"inicio_en": int(a.get("inicio_en", 0)), "fin_en": int(a.get("fin_en", 0)),
					"coste_pagado": Datos.precio_construccion("animal", t),
				}))
	var parcelas = datos.get("Parcelas", [])
	var n_parcelas: int = clampi(int(datos.get("Parcelas_Compradas", 4)), 0, 6)
	if parcelas is Array:
		for i in range(mini(parcelas.size(), n_parcelas)):
			var p = parcelas[i]
			var cultivo: String = str(p.get("cultivo", "")) if p is Dictionary else ""
			if not Datos.CULTIVOS.has(cultivo):
				cultivo = ""
			var fin: int = int(p.get("fin_en", 0)) if (p is Dictionary and cultivo != "") else 0
			var ini: int = int(p.get("inicio_en", 0)) if (p is Dictionary and cultivo != "") else 0
			objetos.append(_Normalizar_Objeto({
				"categoria": "tierra", "tipo": "tierra", "cultivo": cultivo,
				"inicio_en": ini, "fin_en": fin,
				"coste_pagado": Datos.PRECIO_PARCELA_TIERRA,
			}))
	_Colocar_Lista_Migrada(objetos, 0, estado)


# ------------------------------------------------------------------
# Compra de la propiedad
# ------------------------------------------------------------------

func Precio_Compra() -> int:
	if GRANJA_GRATIS_QA:
		return 0
	return int(round(float(Datos.PRECIO_COMPRA) * Variables_Estaticas.Multiplicador_Precios()))


func Comprada() -> bool:
	return bool(Estado().get("Comprada", false))


func Puede_Comprar() -> Dictionary:
	if Comprada():
		return {"ok": false, "motivo": "Ya tienes una granja."}
	var precio: int = Precio_Compra()
	if precio > 0 and int(Variables_Dinamicas.Dinero) < precio:
		return {"ok": false, "motivo": "Te faltan %d € para comprar la granja." % (precio - int(Variables_Dinamicas.Dinero))}
	return {"ok": true, "motivo": "", "precio": precio}


func Comprar() -> Dictionary:
	var validacion: Dictionary = Puede_Comprar()
	if not bool(validacion.get("ok", false)):
		return validacion
	var precio: int = int(validacion.get("precio", 0))
	if precio > 0:
		Variables_Dinamicas.Dinero -= precio

	var estado: Dictionary = Estado_Por_Defecto()
	estado["Comprada"] = true
	estado["Monedas"] = Datos.MONEDAS_INICIALES
	estado["Dia_Conversion"] = Dia_Granja()
	estado["Convertido_Hoy"] = 0
	estado["Nivel_Terreno"] = 0

	# Distribución inicial cuidada en el prado 12×12 (x: 6..17, y: 6..17):
	# - Molino (4×4) en (6, 6)
	# - Gallina (2×2) en (6, 11)
	# - 4 Parcelas de cultivo (2×2) formando un huerto ordenado con camino
	var iniciales: Array[Dictionary] = [
		{
			"id": 1, "categoria": "maquina", "tipo": "molino",
			"x": 6, "y": 6, "ancho": 4, "alto": 4, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false, "inicio_en": 0, "fin_en": 0,
			"coste_pagado": Datos.precio_construccion("maquina", "molino"),
		},
		{
			"id": 2, "categoria": "animal", "tipo": "gallina",
			"x": 6, "y": 11, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false, "inicio_en": 0, "fin_en": 0,
			"coste_pagado": Datos.precio_construccion("animal", "gallina"),
		},
		{
			"id": 3, "categoria": "tierra", "tipo": "tierra",
			"x": 11, "y": 7, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false, "inicio_en": 0, "fin_en": 0,
			"coste_pagado": Datos.PRECIO_PARCELA_TIERRA,
		},
		{
			"id": 4, "categoria": "tierra", "tipo": "tierra",
			"x": 13, "y": 7, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false, "inicio_en": 0, "fin_en": 0,
			"coste_pagado": Datos.PRECIO_PARCELA_TIERRA,
		},
		{
			"id": 5, "categoria": "tierra", "tipo": "tierra",
			"x": 11, "y": 9, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false, "inicio_en": 0, "fin_en": 0,
			"coste_pagado": Datos.PRECIO_PARCELA_TIERRA,
		},
		{
			"id": 6, "categoria": "tierra", "tipo": "tierra",
			"x": 13, "y": 9, "ancho": 2, "alto": 2, "rotado": false, "volteado": false,
			"cultivo": "", "alimentado": false, "inicio_en": 0, "fin_en": 0,
			"coste_pagado": Datos.PRECIO_PARCELA_TIERRA,
		},
	]
	estado["Objetos"] = iniciales
	estado["Siguiente_Id"] = 7

	# Kit de bienvenida: permite alimentar a la gallina y cargar el molino en la primera visita.
	estado["Almacen"] = {"maiz": 1, "trigo": 2}
	Variables_Dinamicas.Granja_Estado = estado
	return {"ok": true, "motivo": "", "precio": precio}


# ------------------------------------------------------------------
# Tiempo
# ------------------------------------------------------------------

func Factor_Tiempo() -> float:
	var factor: float = 1.0
	if Variables_Estaticas.Modo_Rapido:
		factor = 1.0 / 7.0
	var velocidad: int = clampi(int(Estado().get("Velocidad", 0)), 0, 3)
	return factor * (1.0 - 0.10 * float(velocidad))


func Duracion_Segundos(horas: float) -> int:
	return maxi(1, int(round(horas * 3600.0 * Factor_Tiempo())))


func Tiempo_Restante(fin_en: int) -> int:
	return maxi(0, fin_en - Ahora())


func Formatear_Tiempo(segundos: int) -> String:
	if segundos <= 0:
		return "Listo"
	if segundos < 60:
		return "%ds" % segundos
	var minutos: int = int(segundos / 60)
	if minutos < 60:
		return "%dm" % minutos
	var horas: int = int(minutos / 60)
	var resto: int = minutos % 60
	if resto == 0:
		return "%dh" % horas
	return "%dh %02dm" % [horas, resto]


func Dia_Granja() -> String:
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var local: int = Ahora() + bias * 60 - Datos.HORA_RESET * 3600
	var fecha: Dictionary = Time.get_datetime_dict_from_unix_time(local)
	return "%04d-%02d-%02d" % [int(fecha.get("year", 0)), int(fecha.get("month", 1)), int(fecha.get("day", 1))]


func _Asegurar_Dia(estado: Dictionary) -> void:
	var dia: String = Dia_Granja()
	if str(estado.get("Dia_Conversion", "")) != dia:
		estado["Dia_Conversion"] = dia
		estado["Convertido_Hoy"] = 0


# ------------------------------------------------------------------
# Terreno libre 24×24 y consultas espaciales
# ------------------------------------------------------------------

func Nivel_Terreno() -> int:
	return clampi(int(Estado().get("Nivel_Terreno", 0)), 0, Datos.NIVEL_TERRENO_MAX)


func Rect_Terreno() -> Rect2i:
	return Datos.rect_terreno(Nivel_Terreno())


func Rect_Siguiente_Ampliacion() -> Rect2i:
	var nivel: int = Nivel_Terreno()
	if nivel >= Datos.NIVEL_TERRENO_MAX:
		return Rect2i()
	return Datos.rect_terreno(nivel + 1)


func Area_Total() -> int:
	return Datos.area_por_nivel(Nivel_Terreno())


func Area_Ocupada() -> int:
	var total: int = 0
	for obj in Objetos():
		total += int(obj.get("ancho", 0)) * int(obj.get("alto", 0))
	return total


func Area_Libre() -> int:
	return maxi(0, Area_Total() - Area_Ocupada())


# Alias descriptivos para compatibilidad y lectura clara.
func Espacios_Totales() -> int:
	return Area_Total()


func Espacios_Ocupados() -> int:
	return Area_Ocupada()


func Espacios_Libres() -> int:
	return Area_Libre()


func Celda_Desbloqueada(gx: int, gy: int) -> bool:
	return Datos.celda_desbloqueada_xy(gx, gy, Nivel_Terreno())


func Celda_En_Siguiente_Ampliacion(gx: int, gy: int) -> bool:
	return Datos.celda_en_siguiente_ampliacion_xy(gx, gy, Nivel_Terreno())


func Objetos() -> Array:
	var lista = Estado().get("Objetos", [])
	return lista if lista is Array else []


func Obtener_Objeto(id: int) -> Dictionary:
	for obj in Objetos():
		if int(obj.get("id", -1)) == id:
			return obj
	return {}


func Objeto_En(gx: int, gy: int) -> Dictionary:
	for obj in Objetos():
		var ox: int = int(obj.get("x", 0))
		var oy: int = int(obj.get("y", 0))
		var ow: int = int(obj.get("ancho", 1))
		var oh: int = int(obj.get("alto", 1))
		if gx >= ox and gx < ox + ow and gy >= oy and gy < oy + oh:
			return obj
	return {}


func Contar_Categoria(categoria: String) -> int:
	var total: int = 0
	for obj in Objetos():
		if str(obj.get("categoria", "")) == categoria:
			total += 1
	return total


func Contar_Tipo(tipo: String) -> int:
	var total: int = 0
	for obj in Objetos():
		if str(obj.get("tipo", "")) == tipo:
			total += 1
	return total


func Puede_Colocar(x: int, y: int, ancho: int, alto: int, ignorar_id: int = -1) -> Dictionary:
	var celdas_bloqueadas: Array[Vector2i] = []
	var celdas_ocupadas: Array[Vector2i] = []
	if ancho <= 0 or alto <= 0:
		return {"ok": false, "motivo": "Tamaño no válido.", "celdas_bloqueadas": celdas_bloqueadas, "celdas_ocupadas": celdas_ocupadas}

	var rect_terreno := Rect_Terreno()
	var rect_nuevo := Rect2i(x, y, ancho, alto)

	for dy in range(alto):
		for dx in range(ancho):
			var p := Vector2i(x + dx, y + dy)
			if not Datos.celda_en_mapa(p.x, p.y) or not rect_terreno.has_point(p):
				celdas_bloqueadas.append(p)

	for obj in Objetos():
		if int(obj.get("id", -1)) == ignorar_id:
			continue
		var rect_o := Rect2i(
			int(obj.get("x", 0)), int(obj.get("y", 0)),
			int(obj.get("ancho", 1)), int(obj.get("alto", 1)))
		if not rect_nuevo.intersects(rect_o):
			continue
		var inter := rect_nuevo.intersection(rect_o)
		for dy in range(inter.size.y):
			for dx in range(inter.size.x):
				celdas_ocupadas.append(Vector2i(inter.position.x + dx, inter.position.y + dy))

	if not celdas_bloqueadas.is_empty():
		return {
			"ok": false,
			"motivo": "Esa zona está fuera del terreno desbloqueado. Amplía la granja en Mejoras.",
			"celdas_bloqueadas": celdas_bloqueadas,
			"celdas_ocupadas": celdas_ocupadas,
		}
	if not celdas_ocupadas.is_empty():
		return {
			"ok": false,
			"motivo": "Ya hay otro elemento ocupando parte de esa zona.",
			"celdas_bloqueadas": celdas_bloqueadas,
			"celdas_ocupadas": celdas_ocupadas,
		}
	return {
		"ok": true,
		"motivo": "",
		"celdas_bloqueadas": celdas_bloqueadas,
		"celdas_ocupadas": celdas_ocupadas,
	}


func Buscar_Hueco_Libre(ancho: int, alto: int, ignorar_id: int = -1) -> Vector2i:
	var rect_t := Rect_Terreno()
	for gy in range(rect_t.position.y, rect_t.end.y - alto + 1):
		for gx in range(rect_t.position.x, rect_t.end.x - ancho + 1):
			if bool(Puede_Colocar(gx, gy, ancho, alto, ignorar_id).get("ok", false)):
				return Vector2i(gx, gy)
	return Vector2i(-1, -1)


func Estado_Objeto(id: int) -> Dictionary:
	var info: Dictionary = {
		"id": id,
		"valida": false,
		"categoria": "",
		"tipo": "",
		"x": 0,
		"y": 0,
		"ancho": 0,
		"alto": 0,
		"rotado": false,
		"volteado": false,
		"cultivo": "",
		"nombre": "Vacío",
		"alimentado": false,
		"trabajando": false,
		"listo": false,
		"restante": 0,
		"progreso": 0.0,
		"producto": "",
		"cantidad_producto": 0,
		"coste_pagado": 0,
		"reembolso": 0,
		"puede_accion": false,
		"pista_falta": "",
	}
	var obj: Dictionary = Obtener_Objeto(id)
	if obj.is_empty():
		return info

	var cat: String = str(obj.get("categoria", ""))
	var ahora: int = Ahora()
	var fin: int = int(obj.get("fin_en", 0))
	var inicio: int = int(obj.get("inicio_en", 0))
	var coste: int = int(obj.get("coste_pagado", 0))

	info["valida"] = true
	info["categoria"] = cat
	info["x"] = int(obj.get("x", 0))
	info["y"] = int(obj.get("y", 0))
	info["ancho"] = int(obj.get("ancho", 2))
	info["alto"] = int(obj.get("alto", 2))
	info["rotado"] = bool(obj.get("rotado", false))
	info["volteado"] = bool(obj.get("volteado", false))
	info["coste_pagado"] = coste
	info["reembolso"] = Datos.reembolso_venta(coste)

	if cat == "tierra":
		info["tipo"] = "tierra"
		var cultivo: String = str(obj.get("cultivo", ""))
		if Datos.CULTIVOS.has(cultivo):
			var dur: int = maxi(1, fin - inicio)
			info["cultivo"] = cultivo
			info["nombre"] = Datos.nombre(cultivo)
			info["listo"] = fin > 0 and ahora >= fin
			info["restante"] = Tiempo_Restante(fin)
			info["progreso"] = clampf(float(ahora - inicio) / float(dur), 0.0, 1.0)
			info["trabajando"] = fin > 0 and ahora < fin
		else:
			info["nombre"] = "Parcela de cultivo"
	elif cat == "animal":
		var tipo_a: String = str(obj.get("tipo", ""))
		var datos_a: Dictionary = Datos.animal(tipo_a)
		var come: String = str(datos_a.get("come", ""))
		var cant: int = int(datos_a.get("cantidad_come", 1))
		info["tipo"] = tipo_a
		info["nombre"] = str(datos_a.get("nombre", tipo_a.capitalize()))
		info["alimentado"] = bool(obj.get("alimentado", false))
		info["producto"] = str(datos_a.get("producto", ""))
		info["cantidad_producto"] = int(datos_a.get("cantidad_producto", 1))
		info["listo"] = bool(info["alimentado"]) and fin > 0 and ahora >= fin
		info["trabajando"] = bool(info["alimentado"]) and fin > 0 and ahora < fin
		info["restante"] = Tiempo_Restante(fin) if bool(info["alimentado"]) else 0
		info["puede_accion"] = Cantidad_Almacen(come) >= cant
		info["pista_falta"] = "%d %s" % [cant, Datos.nombre(come)]
		if bool(info["alimentado"]) and fin > 0:
			var dur_a: int = maxi(1, fin - inicio)
			info["progreso"] = clampf(float(ahora - inicio) / float(dur_a), 0.0, 1.0)
	elif cat == "maquina":
		var tipo_m: String = str(obj.get("tipo", ""))
		var datos_m: Dictionary = Datos.maquina(tipo_m)
		var ing: Dictionary = datos_m.get("ingredientes", {})
		var puede: bool = true
		var falta: String = ""
		for clave_i in ing.keys():
			var k_i: String = str(clave_i)
			var req: int = int(ing[clave_i])
			if Cantidad_Almacen(k_i) < req:
				puede = false
				if falta == "":
					falta = "%d %s" % [req, Datos.nombre(k_i)]
		info["tipo"] = tipo_m
		info["nombre"] = str(datos_m.get("nombre", tipo_m.capitalize()))
		info["producto"] = str(datos_m.get("producto", ""))
		info["cantidad_producto"] = int(datos_m.get("cantidad_producto", 1))
		info["puede_accion"] = puede
		info["pista_falta"] = falta
		if fin > 0:
			info["trabajando"] = ahora < fin
			info["listo"] = ahora >= fin
			info["restante"] = Tiempo_Restante(fin)
			var dur_m: int = maxi(1, fin - inicio)
			info["progreso"] = clampf(float(ahora - inicio) / float(dur_m), 0.0, 1.0)

	return info


# ------------------------------------------------------------------
# Construcción libre multi-celda, movimiento gratis y venta al 50 %
# ------------------------------------------------------------------

func Construir_En(x: int, y: int, categoria: String, tipo: String = "",
		rotado: bool = false, volteado: bool = false) -> Dictionary:
	if categoria == "tierra":
		tipo = "tierra"
		rotado = false
	elif categoria == "animal":
		if not Datos.ANIMALES.has(tipo):
			return {"ok": false, "motivo": "Ese animal no existe."}
		rotado = rotado and Datos.es_rotable("animal", tipo)
	elif categoria == "maquina":
		if not Datos.MAQUINAS.has(tipo):
			return {"ok": false, "motivo": "Esa máquina no existe."}
		rotado = rotado and Datos.es_rotable("maquina", tipo)
	else:
		return {"ok": false, "motivo": "Categoría no válida."}

	var tam := Datos.tamano_objeto(categoria, tipo, rotado)
	var chequeo := Puede_Colocar(x, y, tam.x, tam.y)
	if not bool(chequeo.get("ok", false)):
		return chequeo

	var coste: int = Datos.precio_construccion(categoria, tipo)
	var estado: Dictionary = Estado()
	if int(estado.get("Monedas", 0)) < coste:
		return {"ok": false, "motivo": "Necesitas %d MG." % coste}

	var nuevo_id: int = int(estado.get("Siguiente_Id", 1))
	estado["Siguiente_Id"] = nuevo_id + 1
	estado["Monedas"] = int(estado.get("Monedas", 0)) - coste
	var obj := {
		"id": nuevo_id,
		"categoria": categoria,
		"tipo": tipo,
		"x": x,
		"y": y,
		"ancho": tam.x,
		"alto": tam.y,
		"rotado": rotado,
		"volteado": volteado,
		"cultivo": "",
		"alimentado": false,
		"inicio_en": 0,
		"fin_en": 0,
		"coste_pagado": coste,
	}
	estado["Objetos"].append(obj)
	return {
		"ok": true,
		"motivo": "",
		"id": nuevo_id,
		"x": x,
		"y": y,
		"ancho": tam.x,
		"alto": tam.y,
		"categoria": categoria,
		"tipo": tipo,
		"coste": coste,
		"reembolso": Datos.reembolso_venta(coste),
	}


func Construir_En_Libre(categoria: String, tipo: String = "") -> Dictionary:
	var tipo_real: String = "tierra" if categoria == "tierra" else tipo
	var tam := Datos.tamano_objeto(categoria, tipo_real, false)
	var pos := Buscar_Hueco_Libre(tam.x, tam.y)
	var rotado: bool = false
	if pos.x < 0 and Datos.es_rotable(categoria, tipo_real):
		var tam_r := Datos.tamano_objeto(categoria, tipo_real, true)
		pos = Buscar_Hueco_Libre(tam_r.x, tam_r.y)
		rotado = pos.x >= 0
	if pos.x < 0:
		return {"ok": false, "motivo": "No cabe un elemento de %d×%d en el terreno libre. Amplía la granja o reorganiza." % [tam.x, tam.y]}
	return Construir_En(pos.x, pos.y, categoria, tipo_real, rotado)


func Mover_Objeto(id: int, nuevo_x: int, nuevo_y: int, rotado: bool = false, volteado: bool = false) -> Dictionary:
	var obj: Dictionary = Obtener_Objeto(id)
	if obj.is_empty():
		return {"ok": false, "motivo": "Ese objeto no existe."}
	var cat: String = str(obj.get("categoria", ""))
	var tipo: String = str(obj.get("tipo", ""))
	var rot_real: bool = rotado and Datos.es_rotable(cat, tipo)
	var tam := Datos.tamano_objeto(cat, tipo, rot_real)
	var chequeo := Puede_Colocar(nuevo_x, nuevo_y, tam.x, tam.y, id)
	if not bool(chequeo.get("ok", false)):
		return chequeo
	obj["x"] = nuevo_x
	obj["y"] = nuevo_y
	obj["ancho"] = tam.x
	obj["alto"] = tam.y
	obj["rotado"] = rot_real
	obj["volteado"] = volteado
	return {"ok": true, "motivo": "", "id": id, "x": nuevo_x, "y": nuevo_y, "ancho": tam.x, "alto": tam.y}


func Vender_Objeto(id: int) -> Dictionary:
	var estado: Dictionary = Estado()
	var lista: Array = estado["Objetos"]
	for i in range(lista.size()):
		var obj: Dictionary = lista[i]
		if int(obj.get("id", -1)) == id:
			var coste: int = int(obj.get("coste_pagado", 0))
			var reembolso: int = Datos.reembolso_venta(coste)
			var cat: String = str(obj.get("categoria", ""))
			var nombre_obj: String = Datos.nombre(str(obj.get("tipo", "")))
			estado["Monedas"] = int(estado.get("Monedas", 0)) + reembolso
			lista.remove_at(i)
			return {
				"ok": true,
				"motivo": "",
				"id": id,
				"categoria": cat,
				"nombre": nombre_obj,
				"coste_pagado": coste,
				"reembolso": reembolso,
			}
	return {"ok": false, "motivo": "No se encontró ese elemento en la granja."}


func Comprar_Parcela_Tierra(x: int = -1, y: int = -1) -> Dictionary:
	return Construir_En(x, y, "tierra", "tierra") if (x >= 0 and y >= 0) else Construir_En_Libre("tierra", "tierra")


func Comprar_Animal(tipo: String, x: int = -1, y: int = -1) -> Dictionary:
	return Construir_En(x, y, "animal", tipo) if (x >= 0 and y >= 0) else Construir_En_Libre("animal", tipo)


func Comprar_Maquina(tipo: String, x: int = -1, y: int = -1) -> Dictionary:
	return Construir_En(x, y, "maquina", tipo) if (x >= 0 and y >= 0) else Construir_En_Libre("maquina", tipo)


# ------------------------------------------------------------------
# Acciones sobre parcelas de cultivo, animales y máquinas (por ID)
# ------------------------------------------------------------------

func Sembrar(id: int, clave: String) -> Dictionary:
	var obj: Dictionary = Obtener_Objeto(id)
	if obj.is_empty() or str(obj.get("categoria", "")) != "tierra":
		return {"ok": false, "motivo": "Primero coloca una parcela de cultivo."}
	if str(obj.get("cultivo", "")) != "":
		return {"ok": false, "motivo": "La parcela ya tiene un cultivo."}
	var datos: Dictionary = Datos.cultivo(clave)
	if datos.is_empty():
		return {"ok": false, "motivo": "Ese cultivo no existe."}
	var coste: int = int(datos.get("coste", 0))
	var estado: Dictionary = Estado()
	if int(estado.get("Monedas", 0)) < coste:
		return {"ok": false, "motivo": "Necesitas %d MG." % coste}
	var ahora: int = Ahora()
	var duracion: int = Duracion_Segundos(float(datos.get("horas", 1.0)))
	estado["Monedas"] = int(estado.get("Monedas", 0)) - coste
	obj["cultivo"] = clave
	obj["inicio_en"] = ahora
	obj["fin_en"] = ahora + duracion
	return {"ok": true, "motivo": "", "id": id, "coste": coste, "duracion": duracion}


func Cosechar(id: int) -> Dictionary:
	var info: Dictionary = Estado_Objeto(id)
	if str(info.get("categoria", "")) != "tierra" or not bool(info.get("listo", false)):
		return {"ok": false, "motivo": "El cultivo todavía no está listo."}
	var cultivo: String = str(info.get("cultivo", ""))
	var estado: Dictionary = Estado()
	estado["Almacen"][cultivo] = int(estado["Almacen"].get(cultivo, 0)) + 1
	var obj: Dictionary = Obtener_Objeto(id)
	obj["cultivo"] = ""
	obj["inicio_en"] = 0
	obj["fin_en"] = 0
	return {"ok": true, "motivo": "", "id": id, "cultivo": cultivo, "cantidad": 1}


func Alimentar(id: int) -> Dictionary:
	var info: Dictionary = Estado_Objeto(id)
	if str(info.get("categoria", "")) != "animal":
		return {"ok": false, "motivo": "No hay ningún animal ahí."}
	if bool(info.get("alimentado", false)):
		return {"ok": false, "motivo": "El animal ya está alimentado."}
	var tipo: String = str(info.get("tipo", ""))
	var datos: Dictionary = Datos.ANIMALES[tipo]
	var come: String = str(datos.get("come", ""))
	var cantidad: int = int(datos.get("cantidad_come", 1))
	var estado: Dictionary = Estado()
	if int(estado["Almacen"].get(come, 0)) < cantidad:
		return {"ok": false, "motivo": "Necesitas %d %s." % [cantidad, Datos.nombre(come)]}
	var ahora: int = Ahora()
	var duracion: int = Duracion_Segundos(float(datos.get("horas", 1.0)))
	estado["Almacen"][come] = int(estado["Almacen"].get(come, 0)) - cantidad
	if int(estado["Almacen"][come]) <= 0:
		estado["Almacen"].erase(come)
	var obj: Dictionary = Obtener_Objeto(id)
	obj["alimentado"] = true
	obj["inicio_en"] = ahora
	obj["fin_en"] = ahora + duracion
	return {"ok": true, "motivo": "", "id": id, "duracion": duracion, "come": come}


func Recoger_Animal(id: int) -> Dictionary:
	var info: Dictionary = Estado_Objeto(id)
	if str(info.get("categoria", "")) != "animal" or not bool(info.get("listo", false)):
		return {"ok": false, "motivo": "El animal todavía no tiene producto."}
	var tipo: String = str(info.get("tipo", ""))
	var datos: Dictionary = Datos.ANIMALES[tipo]
	var producto: String = str(datos.get("producto", ""))
	var cantidad: int = int(datos.get("cantidad_producto", 1))
	var estado: Dictionary = Estado()
	estado["Almacen"][producto] = int(estado["Almacen"].get(producto, 0)) + cantidad
	var obj: Dictionary = Obtener_Objeto(id)
	obj["alimentado"] = false
	obj["inicio_en"] = 0
	obj["fin_en"] = 0
	return {"ok": true, "motivo": "", "id": id, "producto": producto, "cantidad": cantidad}


func Cargar_Maquina(id: int) -> Dictionary:
	var info: Dictionary = Estado_Objeto(id)
	if str(info.get("categoria", "")) != "maquina":
		return {"ok": false, "motivo": "No hay ninguna máquina ahí."}
	if bool(info.get("trabajando", false)) or bool(info.get("listo", false)):
		return {"ok": false, "motivo": "La máquina ya está ocupada."}
	var tipo: String = str(info.get("tipo", ""))
	var datos: Dictionary = Datos.MAQUINAS[tipo]
	var ingredientes: Dictionary = datos.get("ingredientes", {})
	var estado: Dictionary = Estado()
	for clave in ingredientes.keys():
		if int(estado["Almacen"].get(str(clave), 0)) < int(ingredientes[clave]):
			return {"ok": false, "motivo": "Necesitas %d %s." % [
				int(ingredientes[clave]), Datos.nombre(str(clave))]}
	for clave in ingredientes.keys():
		estado["Almacen"][str(clave)] = int(estado["Almacen"].get(str(clave), 0)) - int(ingredientes[clave])
		if int(estado["Almacen"][str(clave)]) <= 0:
			estado["Almacen"].erase(str(clave))
	var ahora: int = Ahora()
	var duracion: int = Duracion_Segundos(float(datos.get("horas", 1.0)))
	var obj: Dictionary = Obtener_Objeto(id)
	obj["inicio_en"] = ahora
	obj["fin_en"] = ahora + duracion
	return {"ok": true, "motivo": "", "id": id, "duracion": duracion}


func Recoger_Maquina(id: int) -> Dictionary:
	var info: Dictionary = Estado_Objeto(id)
	if str(info.get("categoria", "")) != "maquina" or not bool(info.get("listo", false)):
		return {"ok": false, "motivo": "La máquina todavía no ha terminado."}
	var tipo: String = str(info.get("tipo", ""))
	var datos: Dictionary = Datos.MAQUINAS[tipo]
	var producto: String = str(datos.get("producto", ""))
	var cantidad: int = int(datos.get("cantidad_producto", 1))
	var estado: Dictionary = Estado()
	estado["Almacen"][producto] = int(estado["Almacen"].get(producto, 0)) + cantidad
	var obj: Dictionary = Obtener_Objeto(id)
	obj["inicio_en"] = 0
	obj["fin_en"] = 0
	return {"ok": true, "motivo": "", "id": id, "producto": producto, "cantidad": cantidad}


# ------------------------------------------------------------------
# Inventario y ventas de productos
# ------------------------------------------------------------------

func Almacen() -> Dictionary:
	var almacen = Estado().get("Almacen", {})
	return almacen if almacen is Dictionary else {}


func Cantidad_Almacen(clave: String) -> int:
	return maxi(0, int(Almacen().get(clave, 0)))


func Vender(clave: String, cantidad: int) -> Dictionary:
	if not Datos.es_vendible(clave):
		return {"ok": false, "motivo": "Ese producto no se puede vender."}
	var estado: Dictionary = Estado()
	var disponible: int = Cantidad_Almacen(clave)
	cantidad = mini(maxi(0, cantidad), disponible)
	if cantidad <= 0:
		return {"ok": false, "motivo": "No tienes ese producto."}
	var total: int = Datos.precio_venta(clave) * cantidad
	estado["Almacen"][clave] = disponible - cantidad
	if int(estado["Almacen"][clave]) <= 0:
		estado["Almacen"].erase(clave)
	estado["Monedas"] = int(estado.get("Monedas", 0)) + total
	return {"ok": true, "motivo": "", "total": total, "cantidad": cantidad}


func Vender_Todo() -> Dictionary:
	var total: int = 0
	var unidades: int = 0
	for clave in Almacen().keys():
		if not Datos.es_vendible(str(clave)):
			continue
		var r: Dictionary = Vender(str(clave), Cantidad_Almacen(str(clave)))
		if bool(r.get("ok", false)):
			total += int(r.get("total", 0))
			unidades += int(r.get("cantidad", 0))
	return {"ok": unidades > 0, "total": total, "unidades": unidades,
		"motivo": "" if unidades > 0 else "El almacén está vacío."}


# ------------------------------------------------------------------
# Mejoras (ampliación de terreno + velocidad)
# ------------------------------------------------------------------

func Mejora_Disponible(clave: String) -> bool:
	if not Datos.MEJORAS.has(clave):
		return false
	var datos: Dictionary = Datos.MEJORAS[clave]
	var estado: Dictionary = Estado()
	return int(estado.get(str(datos.get("campo", "")), 0)) < int(datos.get("valor", 0))


func Siguiente_Ampliacion() -> String:
	for clave in ["ampliar_1", "ampliar_2", "ampliar_3", "ampliar_4"]:
		if Mejora_Disponible(clave):
			return clave
	return ""


func Siguiente_Mejora() -> String:
	var disponibles: Array = Mejoras_Disponibles()
	return str(disponibles[0]) if not disponibles.is_empty() else ""


func Mejoras_Disponibles() -> Array:
	var salida: Array = []
	var categorias: Dictionary = {
		"terreno": ["ampliar_1", "ampliar_2", "ampliar_3", "ampliar_4"],
		"velocidad": ["velocidad_1", "velocidad_2", "velocidad_3"],
	}
	for categoria in categorias.keys():
		for clave in categorias[categoria]:
			if Mejora_Disponible(str(clave)):
				salida.append(str(clave))
				break
	return salida


func Comprar_Mejora(clave: String) -> Dictionary:
	if not Mejoras_Disponibles().has(clave):
		return {"ok": false, "motivo": "Esa mejora ya no está disponible."}
	var datos: Dictionary = Datos.MEJORAS[clave]
	var estado: Dictionary = Estado()
	var coste: int = int(datos.get("coste", 0))
	if int(estado.get("Monedas", 0)) < coste:
		return {"ok": false, "motivo": "Necesitas %d MG." % coste}
	estado["Monedas"] = int(estado.get("Monedas", 0)) - coste
	var campo: String = str(datos.get("campo", ""))
	estado[campo] = int(datos.get("valor", 0))
	return {"ok": true, "motivo": "", "coste": coste, "mejora": clave}


# ------------------------------------------------------------------
# Conversión diaria MG -> euros
# ------------------------------------------------------------------

func Convertido_Hoy() -> int:
	var estado: Dictionary = Estado()
	_Asegurar_Dia(estado)
	return maxi(0, int(estado.get("Convertido_Hoy", 0)))


func Tasa_Marginal() -> float:
	return Datos.tasa_conversion(float(Convertido_Hoy()))


func _Asegurar_Tabla(hasta: int) -> void:
	while _tabla_conversion.size() <= hasta:
		var x: int = _tabla_conversion.size() - 1
		_tabla_conversion.append(_tabla_conversion[x] + Datos.tasa_conversion(float(x) + 0.5))


func Euros_Por_Cambio(cantidad: int) -> float:
	var desde: int = Convertido_Hoy()
	var hasta: int = desde + maxi(0, cantidad)
	_Asegurar_Tabla(hasta)
	return _tabla_conversion[hasta] - _tabla_conversion[desde]


func Previsualizar_Cambio(cantidad: int) -> Dictionary:
	var estado: Dictionary = Estado()
	_Asegurar_Dia(estado)
	var disponible: int = int(estado.get("Monedas", 0))
	cantidad = clampi(cantidad, 0, disponible)
	var euros: float = Euros_Por_Cambio(cantidad)
	return {
		"cantidad": cantidad,
		"disponible": disponible,
		"euros": round(euros * 100.0) / 100.0,
		"tasa_marginal": Tasa_Marginal(),
		"tasa_media": (euros / float(cantidad)) if cantidad > 0 else 1.0,
		"convertido_hoy": Convertido_Hoy(),
	}


func Cambiar(cantidad: int) -> Dictionary:
	var estado: Dictionary = Estado()
	_Asegurar_Dia(estado)
	var disponible: int = int(estado.get("Monedas", 0))
	cantidad = clampi(cantidad, 0, disponible)
	if cantidad <= 0:
		return {"ok": false, "motivo": "No tienes Monedas de Granja para cambiar."}
	var euros: float = round(Euros_Por_Cambio(cantidad) * 100.0) / 100.0
	estado["Monedas"] = disponible - cantidad
	estado["Convertido_Hoy"] = int(estado.get("Convertido_Hoy", 0)) + cantidad
	Variables_Dinamicas.Dinero += euros
	return {"ok": true, "motivo": "", "cantidad": cantidad, "euros": euros}


func Previsualizar_Ingreso(cantidad_euros: int) -> Dictionary:
	var disponible_eur: int = maxi(0, int(floor(float(Variables_Dinamicas.Dinero))))
	var cantidad: int = clampi(cantidad_euros, 0, disponible_eur)
	return {
		"euros": cantidad,
		"monedas": cantidad,  # Relación fija 1:1 (1 € -> 1 MG)
		"disponible_euros": disponible_eur,
		"tasa": 1.0,
	}


func Ingresar(cantidad_euros: int) -> Dictionary:
	var estado: Dictionary = Estado()
	var disponible_eur: int = maxi(0, int(floor(float(Variables_Dinamicas.Dinero))))
	var cantidad: int = clampi(cantidad_euros, 0, disponible_eur)
	if cantidad <= 0:
		return {"ok": false, "motivo": "No tienes suficientes euros para trasladar a la granja."}
	Variables_Dinamicas.Dinero -= float(cantidad)
	estado["Monedas"] = int(estado.get("Monedas", 0)) + cantidad
	return {"ok": true, "motivo": "", "euros": cantidad, "monedas": cantidad}


# ------------------------------------------------------------------
# Resumen para el hub y cabecera
# ------------------------------------------------------------------

func Contar_Listos() -> int:
	var total: int = 0
	for obj in Objetos():
		if bool(Estado_Objeto(int(obj.get("id", -1))).get("listo", false)):
			total += 1
	return total


func Resumen() -> Dictionary:
	var estado: Dictionary = Estado()
	return {
		"comprada": bool(estado.get("Comprada", false)),
		"monedas": int(estado.get("Monedas", 0)),
		"area_total": Area_Total(),
		"area_ocupada": Area_Ocupada(),
		"area_libre": Area_Libre(),
		"espacios": Area_Total(),
		"ocupados": Area_Ocupada(),
		"libres": Area_Libre(),
		"parcelas": Contar_Categoria("tierra"),
		"animales": Contar_Categoria("animal"),
		"maquinas": Contar_Categoria("maquina"),
		"listos": Contar_Listos(),
		"convertido_hoy": Convertido_Hoy(),
		"tasa": Tasa_Marginal(),
		"precio": Precio_Compra(),
	}
