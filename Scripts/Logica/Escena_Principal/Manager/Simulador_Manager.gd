class_name Simulador_Manager
extends RefCounted

# Motor matemático puro de «El Mánager» (Fase 2 — Modo Club Top Eleven).
# Genera el ecosistema de 16 clubes y 288 futbolistas, calcula calidad y
# estrellas, simula los 90 minutos minuto a minuto, aplica cansancio,
# entrenamientos, ascensos/descensos, envejecimiento y regeneraciones.
# Ninguna función lee Variables_Dinamicas ni escribe en disco: todo entra y
# sale por parámetro para poder testearse con GUT.

const BLOQUE_DE_ATRIBUTO: Dictionary = {
	"entradas": "defensa", "marcaje": "defensa", "posicion": "defensa",
	"cabeceo": "defensa", "valentia": "defensa",
	"pase": "ataque", "regate": "ataque", "centros": "ataque",
	"disparo": "ataque", "definicion": "ataque",
	"condicion": "fisico_mental", "fuerza": "fisico_mental",
	"agresividad": "fisico_mental", "velocidad": "fisico_mental",
	"creatividad": "fisico_mental"
}


# ------------------------------------------------------------------
# Utilidades internas
# ------------------------------------------------------------------

static func _Rng(rng: RandomNumberGenerator = null) -> RandomNumberGenerator:
	if rng != null:
		return rng
	var nuevo := RandomNumberGenerator.new()
	nuevo.randomize()
	return nuevo


static func _Atributo(jugador: Dictionary, nombre: String) -> float:
	var bloque: String = str(BLOQUE_DE_ATRIBUTO.get(nombre, "defensa"))
	var datos = jugador.get(bloque, {})
	if not (datos is Dictionary):
		return 50.0
	var valor = datos.get(nombre, 50)
	if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
		return 50.0
	return float(valor)


static func _Rol_Principal(jugador: Dictionary) -> String:
	var roles = jugador.get("roles", [])
	if roles is Array and not roles.is_empty():
		return str(roles[0])
	return "MC"


static func _Dorsal_Libre(plantilla: Array) -> int:
	var usados: Dictionary = {}
	for j in plantilla:
		if j is Dictionary:
			usados[int(j.get("dorsal", 0))] = true
	for dorsal in range(1, 40):
		if not usados.has(dorsal):
			return dorsal
	return plantilla.size() + 1


# ------------------------------------------------------------------
# Calidad, estrellas y valor
# ------------------------------------------------------------------

static func Calcular_Calidad(jugador: Dictionary) -> float:
	var planos: Dictionary = Datos_Manager.Atributos_Planos(jugador)
	if planos.is_empty():
		return 1.0
	var suma: float = 0.0
	for valor in planos.values():
		suma += float(valor)
	return clampf(suma / float(planos.size()), 1.0, 120.0)


static func Calcular_Estrellas(calidad: float) -> int:
	# Top Eleven: una estrella por cada 20 puntos de calidad, de 1 a 7.
	return clampi(int(floor(maxf(calidad, 0.0) / 20.0)) + 1, 1, 7)


static func Calcular_Valor_Mercado(calidad: float, edad: int) -> int:
	var base: float = pow(clampf(calidad, 1.0, 120.0), 2.0) * 3.4 + calidad * 90.0
	var factor: float = 1.0
	if edad <= 20:
		factor = 1.30
	elif edad <= 22:
		factor = 1.22
	elif edad <= 24:
		factor = 1.14
	elif edad <= 28:
		factor = 1.05
	elif edad <= 31:
		factor = 0.90
	elif edad <= 34:
		factor = 0.65
	elif edad <= 37:
		factor = 0.40
	else:
		factor = 0.22
	return maxi(500, int(round(base * factor / 100.0)) * 100)


static func Calcular_Salario(calidad: float, valor_mercado: int) -> int:
	return maxi(50, int(round(float(valor_mercado) * 0.014 + calidad)))


static func Calcular_Clausula(valor_mercado: int, rng: RandomNumberGenerator = null) -> int:
	var generador: RandomNumberGenerator = _Rng(rng)
	var factor: float = generador.randf_range(1.5, 2.0)
	return maxi(1000, int(round(float(valor_mercado) * factor / 100.0)) * 100)


static func Recalcular_Jugador(jugador: Dictionary) -> Dictionary:
	var calidad: float = Calcular_Calidad(jugador)
	var edad: int = int(jugador.get("edad", 18))
	var valor: int = Calcular_Valor_Mercado(calidad, edad)
	jugador["calidad"] = round(calidad * 10.0) / 10.0
	jugador["estrellas"] = Calcular_Estrellas(calidad)
	jugador["valor_mercado"] = valor
	jugador["salario_semanal"] = Calcular_Salario(calidad, valor)
	if not jugador.has("clausula_rescision") or int(jugador.get("clausula_rescision", 0)) <= 0:
		jugador["clausula_rescision"] = maxi(1000, int(round(float(valor) * 1.75 / 100.0)) * 100)
	return jugador


# ------------------------------------------------------------------
# Generación de jugadores y clubes
# ------------------------------------------------------------------

static func Crear_Jugador(id: String, rol: String, division: int, rng: RandomNumberGenerator = null,
		edad: int = -1, calidad_objetivo: float = -1.0,
		usado_nombres: Dictionary = {}) -> Dictionary:
	var generador: RandomNumberGenerator = _Rng(rng)
	var rol_final: String = rol if Datos_Manager.ROLES.has(rol) else "MC"
	var div: int = clampi(division, 1, 4)
	var base: float = float(Datos_Manager.BASE_ATRIBUTOS_DIVISION.get(div, 40.0))
	var bonus_rol: Dictionary = Datos_Manager.BONUS_ROL.get(rol_final, {})
	var planos: Dictionary = {}
	for atributo in Datos_Manager.ATRIBUTOS:
		var bonus: float = float(bonus_rol.get(atributo, 0))
		var valor: float = base + bonus + generador.randf_range(-7.0, 7.0)
		planos[atributo] = clampf(valor, 25.0, 95.0)

	var jugador: Dictionary = {
		"id": id,
		"nombre": "",
		"dorsal": 1,
		"edad": 18,
		"roles": [rol_final],
		"pie": ["derecho", "izquierdo", "ambidiestro"][generador.randi_range(0, 2)],
		"altura": generador.randi_range(166, 198),
		"peso": generador.randi_range(62, 92),
		"calidad": 50.0,
		"estrellas": 3,
		"defensa": {},
		"ataque": {},
		"fisico_mental": {},
		"energia": 100.0,
		"salario_semanal": 200,
		"valor_mercado": 5000,
		"clausula_rescision": 9000,
		"contrato_temporadas": generador.randi_range(1, 4),
		"partidos_jugados": 0,
		"goles": 0,
		"asistencias": 0,
		"entrenado_dia": -1
	}
	var nombre_generado: String = Datos_Manager.Generar_Nombre(generador, usado_nombres)
	jugador["nombre"] = nombre_generado
	if usado_nombres is Dictionary:
		usado_nombres[nombre_generado] = true

	if edad >= 0:
		jugador["edad"] = clampi(edad, Datos_Manager.EDAD_MINIMA, Datos_Manager.EDAD_MAXIMA)
	else:
		# Plantillas iniciales: mayoría jóvenes con algún veterano.
		var tirada: float = generador.randf()
		if tirada < 0.45:
			jugador["edad"] = generador.randi_range(16, 22)
		elif tirada < 0.78:
			jugador["edad"] = generador.randi_range(23, 28)
		elif tirada < 0.94:
			jugador["edad"] = generador.randi_range(29, 34)
		else:
			jugador["edad"] = generador.randi_range(35, 39)

	# Rol secundario ocasional (polivalencia Top Eleven).
	if generador.randf() < 0.35:
		var afinidades: Dictionary = Datos_Manager.AFINIDAD_ROL.get(rol_final, {})
		var candidatos: Array = []
		for otro in afinidades.keys():
			if otro != rol_final and float(afinidades[otro]) >= 0.7:
				candidatos.append(str(otro))
		if not candidatos.is_empty():
			jugador["roles"].append(str(candidatos[generador.randi_range(0, candidatos.size() - 1)]))

	jugador["defensa"] = Datos_Manager.Construir_Atributos(planos)["defensa"]
	jugador["ataque"] = Datos_Manager.Construir_Atributos(planos)["ataque"]
	jugador["fisico_mental"] = Datos_Manager.Construir_Atributos(planos)["fisico_mental"]

	if calidad_objetivo > 0.0:
		var actual: float = Calcular_Calidad(jugador)
		if actual > 0.01:
			var factor: float = calidad_objetivo / actual
			for atributo in Datos_Manager.ATRIBUTOS:
				var bloque: String = str(BLOQUE_DE_ATRIBUTO.get(atributo, "defensa"))
				var nuevo: float = clampf(_Atributo(jugador, atributo) * factor,
					float(Datos_Manager.ATRIBUTO_MINIMO), float(Datos_Manager.ATRIBUTO_MAXIMO))
				jugador[bloque][atributo] = int(round(nuevo))

	Recalcular_Jugador(jugador)
	jugador["clausula_rescision"] = Calcular_Clausula(int(jugador["valor_mercado"]), generador)
	return jugador


static func Crear_Plantilla(prefijo: String, division: int, rng: RandomNumberGenerator = null,
		usado_nombres: Dictionary = {}) -> Array:
	var generador: RandomNumberGenerator = _Rng(rng)
	var plantilla: Array = []
	for i in range(Datos_Manager.PLANTILLA_ROLES.size()):
		var rol: String = str(Datos_Manager.PLANTILLA_ROLES[i])
		var jugador: Dictionary = Crear_Jugador(
			"%s_p%02d" % [prefijo, i + 1], rol, division, generador,
			-1, -1.0, usado_nombres)
		jugador["dorsal"] = i + 1
		plantilla.append(jugador)
	return plantilla


static func _Puntuacion_Ranura(jugador: Dictionary, ranura: String) -> float:
	var roles = jugador.get("roles", [])
	var afinidad: float = Datos_Manager.AFINIDAD_MINIMA
	if roles is Array:
		for rol in roles:
			var valor: float = float(Datos_Manager.AFINIDAD_ROL.get(
				str(ranura), {}).get(str(rol), Datos_Manager.AFINIDAD_MINIMA))
			afinidad = maxf(afinidad, valor)
	return Calcular_Calidad(jugador) * afinidad


static func Elegir_Alineacion_Automatica(plantilla: Array, formacion: String) -> Array:
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(
		formacion, Datos_Manager.ROLES_FORMACION["4-4-2"])
	var usados: Dictionary = {}
	var alineacion: Array = []
	for ranura in slots:
		var mejor_id: String = ""
		var mejor_puntuacion: float = -1.0
		for jugador in plantilla:
			if not (jugador is Dictionary):
				continue
			var jugador_id: String = str(jugador.get("id", ""))
			if jugador_id == "" or usados.has(jugador_id):
				continue
			var puntuacion: float = _Puntuacion_Ranura(jugador, str(ranura))
			# La energía también cuenta: un titular agotado rinde menos.
			puntuacion *= 0.85 + 0.15 * clampf(float(jugador.get("energia", 100.0)) / 100.0, 0.0, 1.0)
			if puntuacion > mejor_puntuacion:
				mejor_puntuacion = puntuacion
				mejor_id = jugador_id
		if mejor_id == "":
			# Sin jugadores disponibles: completar con cualquier no usado.
			for jugador in plantilla:
				if jugador is Dictionary:
					var otro_id: String = str(jugador.get("id", ""))
					if otro_id != "" and not usados.has(otro_id):
						mejor_id = otro_id
						break
		if mejor_id != "":
			usados[mejor_id] = true
			alineacion.append(mejor_id)
	return alineacion


static func Crear_Club(id: String, nombre: String, ciudad: String, colores: Array,
		patron: int, division: int, es_usuario: bool, rng: RandomNumberGenerator = null,
		usado_nombres: Dictionary = {}) -> Dictionary:
	var generador: RandomNumberGenerator = _Rng(rng)
	var div: int = clampi(division, 1, 4)
	var colores_finales: Array = []
	for color in colores:
		colores_finales.append(str(color))
	while colores_finales.size() < 2:
		colores_finales.append("#ffffff")
	var plantilla: Array = Crear_Plantilla(id, div, generador, usado_nombres)
	var presupuesto: int = Datos_Manager.PRESUPUESTO_INICIAL_USUARIO if es_usuario \
		else int(Datos_Manager.PRESUPUESTO_INICIAL_IA.get(div, 60000))
	var tactica: Dictionary = Datos_Manager.TACTICA_BASE.duplicate(true)
	var club: Dictionary = {
		"id": id,
		"nombre": nombre,
		"ciudad": ciudad,
		"es_usuario": es_usuario,
		"division": div,
		"colores": colores_finales,
		"escudo_patron": clampi(patron, 0, Datos_Manager.PATRONES_ESCUDO.size() - 1),
		"presupuesto": presupuesto,
		"aficion": int(Datos_Manager.AFICION_POR_DIVISION.get(div, 1500)),
		"confianza_directiva": 70.0,
		"tactica": tactica,
		"instalaciones": Datos_Manager.INSTALACIONES_BASE.duplicate(true),
		"capitan_id": "",
		"plantilla": plantilla,
		"alineacion": [],
		"puntos": 0,
		"victorias": 0,
		"empates": 0,
		"derrotas": 0,
		"racha": [],
		"goles_favor": 0,
		"goles_contra": 0,
		"entreno_grupal_dia": -1,
		"cantera_dia": -1,
		"cantera_candidatos": [],
		"amistoso_dia": -1
	}
	club["alineacion"] = Elegir_Alineacion_Automatica(plantilla, str(tactica["formacion"]))
	club["capitan_id"] = Elegir_Capitan_Automatico(plantilla, club["alineacion"])
	return club


static func Elegir_Capitan_Automatico(plantilla: Array, alineacion: Array = []) -> String:
	var mejor_id: String = ""
	var mejor_punt: float = -1.0
	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var jid: String = str(jugador.get("id", ""))
		var punt: float = float(jugador.get("calidad", 0.0)) + float(jugador.get("edad", 18)) * 0.45
		if alineacion.has(jid):
			punt += 12.0
		if punt > mejor_punt:
			mejor_punt = punt
			mejor_id = jid
	return mejor_id


static func Crear_Ecosistema(nombre_usuario: String, colores_usuario: Array,
		patron_usuario: int, rng: RandomNumberGenerator = null,
		ciudad_usuario: String = "") -> Dictionary:
	var generador: RandomNumberGenerator = _Rng(rng)
	var usado_nombres: Dictionary = {}
	var clubes: Dictionary = {}
	var divisiones: Dictionary = {"1": [], "2": [], "3": [], "4": []}

	for i in range(Datos_Manager.CLUBES_IA.size()):
		var datos: Dictionary = Datos_Manager.CLUBES_IA[i]
		var division: int = 1 + int(i / 4)
		if division > 4:
			division = 4
		var club_id: String = "c%02d" % (i + 1)
		var club: Dictionary = Crear_Club(
			club_id, str(datos["nombre"]), str(datos["ciudad"]),
			datos["colores"], int(datos["patron"]), division, false,
			generador, usado_nombres)
		clubes[club_id] = club
		divisiones[str(division)].append(club_id)

	var ciudad_final: String = ciudad_usuario.strip_edges()
	if ciudad_final == "":
		ciudad_final = Datos_Manager.CIUDAD_CLUB_POR_DEFECTO
	var club_usuario: Dictionary = Crear_Club(
		"club_usr", nombre_usuario, ciudad_final,
		colores_usuario, patron_usuario, 4, true, generador, usado_nombres)
	clubes["club_usr"] = club_usuario
	divisiones["4"].append("club_usr")

	return {
		"Clubes": clubes,
		"Divisiones": divisiones
	}


# ------------------------------------------------------------------
# Ascensos, descensos, envejecimiento y canteranos
# ------------------------------------------------------------------

static func Aplicar_Multiplicador_Calidad(plantilla: Array, factor: float) -> Array:
	var resultado: Array = []
	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var copia: Dictionary = jugador.duplicate(true)
		for atributo in Datos_Manager.ATRIBUTOS:
			var bloque: String = str(BLOQUE_DE_ATRIBUTO.get(atributo, "defensa"))
			var valor: float = _Atributo(copia, atributo) * factor
			copia[bloque][atributo] = int(round(clampf(valor,
				float(Datos_Manager.ATRIBUTO_MINIMO), float(Datos_Manager.ATRIBUTO_MAXIMO))))
		Recalcular_Jugador(copia)
		copia["clausula_rescision"] = maxi(1000, int(round(
			float(copia["valor_mercado"]) * 1.75 / 100.0)) * 100)
		resultado.append(copia)
	return resultado


static func Aplicar_Ascenso(plantilla: Array) -> Array:
	return Aplicar_Multiplicador_Calidad(plantilla, 0.80)


static func Aplicar_Descenso(plantilla: Array) -> Array:
	return Aplicar_Multiplicador_Calidad(plantilla, 1.20)


static func Generar_Canterano(club_id: String, rol: String, division: int,
		rng: RandomNumberGenerator = null, usado_nombres: Dictionary = {},
		dorsal_usado: Dictionary = {}) -> Dictionary:
	var generador: RandomNumberGenerator = _Rng(rng)
	var edad: int = generador.randi_range(16, 22)
	var base: float = float(Datos_Manager.BASE_ATRIBUTOS_DIVISION.get(
		clampi(division, 1, 4), 40.0))
	var calidad: float = clampf(base + generador.randf_range(-7.0, 7.0), 25.0, 85.0)
	var id: String = "%s_r%06d" % [club_id, generador.randi_range(100000, 999999)]
	var jugador: Dictionary = Crear_Jugador(
		id, rol, division, generador, edad, calidad, usado_nombres)
	jugador["dorsal"] = _Dorsal_Libre_Desde(dorsal_usado)
	jugador["entrenado_dia"] = -1
	return jugador


static func _Dorsal_Libre_Desde(usados: Dictionary) -> int:
	for dorsal in range(1, 40):
		if not usados.has(dorsal):
			return dorsal
	return usados.size() + 1


static func Envejecer_Plantilla(plantilla: Array, club_id: String, division: int,
		rng: RandomNumberGenerator = null) -> Dictionary:
	# +1 año a todos. Al cumplir 40 se retiran y se regeneran como canteranos
	# de 16–22 años en el mismo club y con el mismo rol posicional.
	var generador: RandomNumberGenerator = _Rng(rng)
	var resultado: Array = []
	var retirados: Array = []
	var canteranos: Array = []
	var dorsales: Dictionary = {}
	for jugador in plantilla:
		if jugador is Dictionary:
			dorsales[int(jugador.get("dorsal", 0))] = true
	var nombres_usados: Dictionary = {}

	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var copia: Dictionary = jugador.duplicate(true)
		copia["edad"] = int(copia.get("edad", 18)) + 1
		if int(copia["edad"]) >= Datos_Manager.EDAD_MAXIMA:
			retirados.append({
				"id": str(copia.get("id", "")),
				"nombre": str(copia.get("nombre", "")),
				"rol": _Rol_Principal(copia),
				"edad": int(copia["edad"])
			})
			var rol: String = _Rol_Principal(copia)
			var canterano: Dictionary = Generar_Canterano(
				club_id, rol, division, generador, nombres_usados, dorsales)
			dorsales[int(canterano["dorsal"])] = true
			canteranos.append(canterano)
			resultado.append(canterano)
		else:
			Recalcular_Jugador(copia)
			resultado.append(copia)

	# Salvaguarda: una plantilla nunca debe quedar por debajo del mínimo.
	while resultado.size() < Datos_Manager.PLANTILLA_MINIMA:
		var rol_extra: String = str(Datos_Manager.PLANTILLA_ROLES[
			resultado.size() % Datos_Manager.PLANTILLA_ROLES.size()])
		var extra: Dictionary = Generar_Canterano(
			club_id, rol_extra, division, generador, nombres_usados, dorsales)
		dorsales[int(extra["dorsal"])] = true
		canteranos.append(extra)
		resultado.append(extra)

	return {
		"plantilla": resultado,
		"retirados": retirados,
		"canteranos": canteranos
	}


# ------------------------------------------------------------------
# Fuerzas, alineaciones y partido en vivo
# ------------------------------------------------------------------

static func _Factor_Energia(energia: float) -> float:
	if energia >= Datos_Manager.ENERGIA_MINIMA_EFECTIVA:
		return 1.0
	return 0.55 + 0.45 * (maxf(energia, 0.0) / Datos_Manager.ENERGIA_MINIMA_EFECTIVA)


static func _Valor_Porteria(jugador: Dictionary) -> float:
	return (_Atributo(jugador, "posicion") * 0.55
		+ _Atributo(jugador, "valentia") * 0.25
		+ _Atributo(jugador, "cabeceo") * 0.20)


static func _Valor_Defensa(jugador: Dictionary) -> float:
	return (_Atributo(jugador, "entradas") * 0.30
		+ _Atributo(jugador, "marcaje") * 0.30
		+ _Atributo(jugador, "posicion") * 0.22
		+ _Atributo(jugador, "cabeceo") * 0.10
		+ _Atributo(jugador, "fuerza") * 0.08)


static func _Valor_Medio(jugador: Dictionary) -> float:
	return (_Atributo(jugador, "pase") * 0.26
		+ _Atributo(jugador, "creatividad") * 0.22
		+ _Atributo(jugador, "condicion") * 0.16
		+ _Atributo(jugador, "regate") * 0.14
		+ _Atributo(jugador, "entradas") * 0.10
		+ _Atributo(jugador, "velocidad") * 0.12)


static func _Valor_Ataque(jugador: Dictionary) -> float:
	return (_Atributo(jugador, "disparo") * 0.26
		+ _Atributo(jugador, "definicion") * 0.24
		+ _Atributo(jugador, "velocidad") * 0.16
		+ _Atributo(jugador, "regate") * 0.12
		+ _Atributo(jugador, "cabeceo") * 0.12
		+ _Atributo(jugador, "centros") * 0.10)


static func _Afinidad_Ranura(jugador: Dictionary, ranura: String) -> float:
	var afinidad: float = Datos_Manager.AFINIDAD_MINIMA
	var roles = jugador.get("roles", [])
	if roles is Array:
		for rol in roles:
			afinidad = maxf(afinidad, float(Datos_Manager.AFINIDAD_ROL.get(
				ranura, {}).get(str(rol), Datos_Manager.AFINIDAD_MINIMA)))
	return afinidad


static func Fuerza_Desde_Estado(estado: Dictionary, lado: String) -> Dictionary:
	var es_local: bool = lado == "local"
	var jugadores = estado.get("jugadores_%s" % lado, {})
	var alineacion = estado.get("alineacion_%s" % lado, [])
	var energia = estado.get("energia", {})
	var tactica = estado.get("tactica_%s" % lado, Datos_Manager.TACTICA_BASE)
	if not (jugadores is Dictionary):
		jugadores = {}
	if not (alineacion is Array):
		alineacion = []
	if not (energia is Dictionary):
		energia = {}
	if not (tactica is Dictionary):
		tactica = Datos_Manager.TACTICA_BASE

	var formacion: String = str(tactica.get("formacion", "4-4-2"))
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(
		formacion, Datos_Manager.ROLES_FORMACION["4-4-2"])

	var valores_porteria: Array = []
	var valores_defensa: Array = []
	var valores_medio: Array = []
	var valores_ataque: Array = []

	for i in range(mini(slots.size(), alineacion.size())):
		var jugador_id: String = str(alineacion[i])
		var jugador = jugadores.get(jugador_id, null)
		if not (jugador is Dictionary):
			continue
		var ranura: String = str(slots[i])
		var e: float = float(energia.get(jugador_id, jugador.get("energia", 100.0)))
		var factor: float = _Factor_Energia(e) * _Afinidad_Ranura(jugador, ranura)
		if ranura == "POR":
			valores_porteria.append(_Valor_Porteria(jugador) * factor)
		elif Datos_Manager.ROLES_DEFENSA.has(ranura):
			valores_defensa.append(_Valor_Defensa(jugador) * factor)
		elif Datos_Manager.ROLES_MEDIO.has(ranura):
			valores_medio.append(_Valor_Medio(jugador) * factor)
		else:
			valores_ataque.append(_Valor_Ataque(jugador) * factor)

	var porteria: float = _Media(valores_porteria, 35.0)
	var defensa: float = _Media(valores_defensa, 35.0)
	var medio: float = _Media(valores_medio, 35.0)
	var ataque: float = _Media(valores_ataque, 35.0)

	defensa = defensa * 0.82 + porteria * 0.18

	var mentalidad: String = str(tactica.get("mentalidad", "equilibrada"))
	match mentalidad:
		"defensiva":
			defensa *= 1.07
			ataque *= 0.93
			medio *= 0.98
		"ofensiva":
			ataque *= 1.07
			defensa *= 0.93
			medio *= 1.01

	var presion: String = str(tactica.get("presion", "media"))
	match presion:
		"alta":
			medio *= 1.05
			defensa *= 0.97
		"baja":
			medio *= 0.96
			defensa *= 1.03

	if es_local:
		defensa *= 1.02
		medio *= 1.03
		ataque *= 1.02

	var media: float = (porteria + defensa + medio + ataque) / 4.0
	return {
		"porteria": clampf(porteria, 1.0, 120.0),
		"defensa": clampf(defensa, 1.0, 120.0),
		"medio": clampf(medio, 1.0, 120.0),
		"ataque": clampf(ataque, 1.0, 120.0),
		"media": clampf(media, 1.0, 120.0)
	}


static func Calcular_Fuerza_Club(club: Dictionary, es_local: bool = false) -> Dictionary:
	if club.is_empty():
		return {"porteria": 35.0, "defensa": 35.0, "medio": 35.0, "ataque": 35.0, "media": 35.0, "quimica": 100.0}
	var tactica = club.get("tactica", Datos_Manager.TACTICA_BASE)
	var formacion: String = str(tactica.get("formacion", "4-4-2")) if tactica is Dictionary else "4-4-2"
	var alineacion: Array = _Alinear_Valida(club, formacion)
	var jugadores: Dictionary = _Copiar_Plantilla(club.get("plantilla", []))
	var energia: Dictionary = {}
	for jid in jugadores.keys():
		energia[jid] = float(jugadores[jid].get("energia", 100.0))
	var estado_tmp: Dictionary = {
		"jugadores_local": jugadores,
		"alineacion_local": alineacion,
		"tactica_local": tactica,
		"jugadores_visitante": jugadores,
		"alineacion_visitante": alineacion,
		"tactica_visitante": tactica,
		"energia": energia
	}
	var fuerza: Dictionary = Fuerza_Desde_Estado(estado_tmp, "local" if es_local else "visitante")
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(formacion, Datos_Manager.ROLES_FORMACION["4-4-2"])
	var suma_afinidad: float = 0.0
	var count_af: int = 0
	for i in range(mini(slots.size(), alineacion.size())):
		var j = jugadores.get(str(alineacion[i]), null)
		if j is Dictionary:
			suma_afinidad += _Afinidad_Ranura(j, str(slots[i]))
			count_af += 1
	fuerza["quimica"] = round((suma_afinidad / float(maxi(1, count_af))) * 100.0)
	return fuerza


static func Evaluar_Alineacion_Slots(club: Dictionary) -> Array:
	var salida: Array = []
	if club.is_empty():
		return salida
	var tactica = club.get("tactica", Datos_Manager.TACTICA_BASE)
	var formacion: String = str(tactica.get("formacion", "4-4-2")) if tactica is Dictionary else "4-4-2"
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(formacion, Datos_Manager.ROLES_FORMACION["4-4-2"])
	var alineacion: Array = _Alinear_Valida(club, formacion)
	var mapa: Dictionary = _Copiar_Plantilla(club.get("plantilla", []))
	for i in range(mini(slots.size(), alineacion.size())):
		var jid: String = str(alineacion[i])
		var jugador: Dictionary = mapa.get(jid, {})
		var ranura: String = str(slots[i])
		var afinidad: float = _Afinidad_Ranura(jugador, ranura) if not jugador.is_empty() else 1.0
		salida.append({
			"slot": i,
			"ranura": ranura,
			"jugador_id": jid,
			"jugador": jugador,
			"afinidad": afinidad,
			"energia": float(jugador.get("energia", 100.0)) if not jugador.is_empty() else 100.0
		})
	return salida


static func _Media(valores: Array, defecto: float) -> float:
	if valores.is_empty():
		return defecto
	var suma: float = 0.0
	for v in valores:
		suma += float(v)
	return suma / float(valores.size())


static func _Copiar_Plantilla(plantilla: Array) -> Dictionary:
	var mapa: Dictionary = {}
	for jugador in plantilla:
		if jugador is Dictionary:
			mapa[str(jugador.get("id", ""))] = jugador.duplicate(true)
	return mapa


static func _Alinear_Valida(club: Dictionary, formacion: String) -> Array:
	var plantilla = club.get("plantilla", [])
	if not (plantilla is Array):
		return []
	var ids: Dictionary = {}
	for jugador in plantilla:
		if jugador is Dictionary:
			ids[str(jugador.get("id", ""))] = true
	var alineacion = club.get("alineacion", [])
	var valida: bool = alineacion is Array and alineacion.size() == 11
	if valida:
		for jugador_id in alineacion:
			if not ids.has(str(jugador_id)):
				valida = false
				break
	if valida:
		var unicos: Dictionary = {}
		for jugador_id in alineacion:
			if unicos.has(str(jugador_id)):
				valida = false
				break
			unicos[str(jugador_id)] = true
	if not valida:
		return Elegir_Alineacion_Automatica(plantilla, formacion)
	return alineacion.duplicate()


static func Crear_Estado_Partido(club_local: Dictionary, club_visitante: Dictionary) -> Dictionary:
	var local: Dictionary = club_local.duplicate(true)
	var visitante: Dictionary = club_visitante.duplicate(true)
	var tactica_local: Dictionary = local.get("tactica", Datos_Manager.TACTICA_BASE).duplicate(true)
	var tactica_visitante: Dictionary = visitante.get("tactica", Datos_Manager.TACTICA_BASE).duplicate(true)
	var formacion_local: String = str(tactica_local.get("formacion", "4-4-2"))
	var formacion_visitante: String = str(tactica_visitante.get("formacion", "4-4-2"))
	var alineacion_local: Array = _Alinear_Valida(local, formacion_local)
	var alineacion_visitante: Array = _Alinear_Valida(visitante, formacion_visitante)

	var jugadores_local: Dictionary = _Copiar_Plantilla(local.get("plantilla", []))
	var jugadores_visitante: Dictionary = _Copiar_Plantilla(visitante.get("plantilla", []))
	var banquillo_local: Array = []
	var banquillo_visitante: Array = []
	for jugador_id in jugadores_local.keys():
		if not alineacion_local.has(jugador_id):
			banquillo_local.append(jugador_id)
	for jugador_id in jugadores_visitante.keys():
		if not alineacion_visitante.has(jugador_id):
			banquillo_visitante.append(jugador_id)

	var energia: Dictionary = {}
	for jugador_id in jugadores_local.keys():
		energia[jugador_id] = float(jugadores_local[jugador_id].get("energia", 100.0))
	for jugador_id in jugadores_visitante.keys():
		energia[jugador_id] = float(jugadores_visitante[jugador_id].get("energia", 100.0))

	return {
		"local_id": str(local.get("id", "")),
		"visitante_id": str(visitante.get("id", "")),
		"local_nombre": str(local.get("nombre", "")),
		"visitante_nombre": str(visitante.get("nombre", "")),
		"minuto": 0,
		"goles_local": 0,
		"goles_visitante": 0,
		"tiros_local": 0,
		"tiros_visitante": 0,
		"tiros_puerta_local": 0,
		"tiros_puerta_visitante": 0,
		"corners_local": 0,
		"corners_visitante": 0,
		"posesion_acumulada": 0.0,
		"posesion_muestras": 0,
		"eventos": [],
		"goleadores_local": [],
		"goleadores_visitante": [],
		"asistencias_local": [],
		"asistencias_visitante": [],
		"jugadores_local": jugadores_local,
		"jugadores_visitante": jugadores_visitante,
		"alineacion_local": alineacion_local,
		"alineacion_visitante": alineacion_visitante,
		"banquillo_local": banquillo_local,
		"banquillo_visitante": banquillo_visitante,
		"energia": energia,
		"cambios_local": 0,
		"cambios_visitante": 0,
		"tactica_local": tactica_local,
		"tactica_visitante": tactica_visitante,
		"lado_usuario": "",
		"finalizado": false
	}


static func _Jugador_Estado(estado: Dictionary, lado: String, jugador_id: String) -> Dictionary:
	var mapa = estado.get("jugadores_%s" % lado, {})
	if mapa is Dictionary and mapa.get(jugador_id, null) is Dictionary:
		return mapa[jugador_id]
	return {}


static func _Elegir_Goleador(estado: Dictionary, lado: String, rng: RandomNumberGenerator) -> Dictionary:
	var alineacion: Array = estado.get("alineacion_%s" % lado, [])
	var pesos: Array = []
	var total: float = 0.0
	for jugador_id in alineacion:
		var jugador: Dictionary = _Jugador_Estado(estado, lado, str(jugador_id))
		if jugador.is_empty():
			continue
		var rol: String = _Rol_Principal(jugador)
		var peso: float = 1.0
		match rol:
			"DEL":
				peso = 6.0
			"ED", "EI", "MCO":
				peso = 3.2
			"MC", "MD", "MI":
				peso = 1.8
			"MCD", "DFC", "LD", "LI":
				peso = 0.7
			"POR":
				peso = 0.03
		total += peso
		pesos.append({"id": str(jugador_id), "peso": peso})
	if pesos.is_empty():
		return {}
	var tirada: float = rng.randf() * maxf(total, 0.01)
	var acumulado: float = 0.0
	for entrada in pesos:
		acumulado += float(entrada["peso"])
		if tirada <= acumulado:
			return _Jugador_Estado(estado, lado, str(entrada["id"]))
	return _Jugador_Estado(estado, lado, str(pesos[0]["id"]))


static func _Elegir_Asistente(estado: Dictionary, lado: String, goleador_id: String,
		rng: RandomNumberGenerator) -> Dictionary:
	var alineacion: Array = estado.get("alineacion_%s" % lado, [])
	var candidatos: Array = []
	var total: float = 0.0
	for jugador_id in alineacion:
		if str(jugador_id) == goleador_id:
			continue
		var jugador: Dictionary = _Jugador_Estado(estado, lado, str(jugador_id))
		if jugador.is_empty():
			continue
		var peso: float = 0.4 + _Atributo(jugador, "pase") * 0.012 \
			+ _Atributo(jugador, "creatividad") * 0.010
		total += peso
		candidatos.append({"id": str(jugador_id), "peso": peso})
	if candidatos.is_empty() or rng.randf() > 0.72:
		return {}
	var tirada: float = rng.randf() * maxf(total, 0.01)
	var acumulado: float = 0.0
	for entrada in candidatos:
		acumulado += float(entrada["peso"])
		if tirada <= acumulado:
			return _Jugador_Estado(estado, lado, str(entrada["id"]))
	return {}


static func _Anadir_Evento(estado: Dictionary, tipo: String, equipo: String,
		texto: String) -> void:
	var eventos: Array = estado.get("eventos", [])
	if not (eventos is Array):
		eventos = []
	eventos.append({
		"minuto": int(estado.get("minuto", 0)),
		"tipo": tipo,
		"equipo": equipo,
		"texto": texto,
		"marcador": "%d-%d" % [int(estado.get("goles_local", 0)),
			int(estado.get("goles_visitante", 0))]
	})
	estado["eventos"] = eventos


static func _Drenar_Energia(estado: Dictionary, lado: String, presion: String) -> void:
	var factor: float = 1.0
	match presion:
		"alta":
			factor = 1.15
		"baja":
			factor = 0.90
	var energia = estado.get("energia", {})
	if not (energia is Dictionary):
		return
	var alineacion: Array = estado.get("alineacion_%s" % lado, [])
	for jugador_id in alineacion:
		var clave: String = str(jugador_id)
		energia[clave] = maxf(0.0, float(energia.get(clave, 100.0)) - 0.30 * factor)
	estado["energia"] = energia


static func _Sustitucion_Interna(estado: Dictionary, lado: String,
		sale_id: String, entra_id: String, motivo_ia: bool = false) -> bool:
	var alineacion_key: String = "alineacion_%s" % lado
	var banquillo_key: String = "banquillo_%s" % lado
	var cambios_key: String = "cambios_%s" % lado
	var alineacion: Array = estado.get(alineacion_key, [])
	var banquillo: Array = estado.get(banquillo_key, [])
	if not (alineacion is Array) or not (banquillo is Array):
		return false
	var indice: int = alineacion.find(sale_id)
	if indice < 0:
		return false
	var indice_banquillo: int = banquillo.find(entra_id)
	if indice_banquillo < 0:
		return false
	if int(estado.get(cambios_key, 0)) >= Datos_Manager.CAMBIOS_MAXIMOS:
		return false

	alineacion[indice] = entra_id
	banquillo.remove_at(indice_banquillo)
	banquillo.append(sale_id)
	estado[alineacion_key] = alineacion
	estado[banquillo_key] = banquillo
	estado[cambios_key] = int(estado.get(cambios_key, 0)) + 1
	var utilizados_key: String = "utilizados_%s" % lado
	var utilizados = estado.get(utilizados_key, [])
	if not (utilizados is Array):
		utilizados = []
	if not utilizados.has(entra_id):
		utilizados.append(entra_id)
	estado[utilizados_key] = utilizados

	var jugadores = estado.get("jugadores_%s" % lado, {})
	var nombre_sale: String = "jugador"
	var nombre_entra: String = "jugador"
	if jugadores is Dictionary:
		if jugadores.get(sale_id, null) is Dictionary:
			nombre_sale = str(jugadores[sale_id].get("nombre", sale_id))
		if jugadores.get(entra_id, null) is Dictionary:
			nombre_entra = str(jugadores[entra_id].get("nombre", entra_id))
	var nombre_equipo: String = str(estado.get("%s_nombre" % lado, ""))
	var texto: String = "Cambio%s en %s: sale %s y entra %s." % [
		" (IA)" if motivo_ia else "", nombre_equipo, nombre_sale, nombre_entra]
	_Anadir_Evento(estado, "cambio", lado, texto)
	return true


static func Sustituir(estado: Dictionary, lado: String, sale_id: String,
		entra_id: String) -> Dictionary:
	if bool(estado.get("finalizado", false)):
		return {"ok": false, "motivo": "El partido ya ha terminado."}
	if lado != "local" and lado != "visitante":
		return {"ok": false, "motivo": "Equipo no válido."}
	if int(estado.get("cambios_%s" % lado, 0)) >= Datos_Manager.CAMBIOS_MAXIMOS:
		return {"ok": false, "motivo": "Has agotado los %d cambios." % Datos_Manager.CAMBIOS_MAXIMOS}
	var alineacion: Array = estado.get("alineacion_%s" % lado, [])
	var banquillo: Array = estado.get("banquillo_%s" % lado, [])
	if not alineacion.has(sale_id):
		return {"ok": false, "motivo": "El jugador que sale no está en el once."}
	if not banquillo.has(entra_id):
		return {"ok": false, "motivo": "El jugador que entra no está en el banquillo."}
	var ok: bool = _Sustitucion_Interna(estado, lado, sale_id, entra_id, false)
	return {"ok": ok, "motivo": "" if ok else "No se pudo realizar el cambio."}


static func Cambiar_Mentalidad(estado: Dictionary, lado: String, mentalidad: String) -> bool:
	if not Datos_Manager.MENTALIDADES.has(mentalidad):
		return false
	var clave: String = "tactica_%s" % lado
	var tactica = estado.get(clave, {})
	if not (tactica is Dictionary):
		tactica = Datos_Manager.TACTICA_BASE.duplicate(true)
	tactica["mentalidad"] = mentalidad
	estado[clave] = tactica
	_Anadir_Evento(estado, "tactica", lado, "%s cambia a mentalidad %s." % [
		str(estado.get("%s_nombre" % lado, "")), mentalidad])
	return true


static func _Intentar_Cambio_IA(estado: Dictionary, lado: String,
		rng: RandomNumberGenerator) -> void:
	if int(estado.get("cambios_%s" % lado, 0)) >= Datos_Manager.CAMBIOS_MAXIMOS:
		return
	var alineacion: Array = estado.get("alineacion_%s" % lado, [])
	var banquillo: Array = estado.get("banquillo_%s" % lado, [])
	var energia = estado.get("energia", {})
	if banquillo.is_empty() or not (energia is Dictionary):
		return

	# Buscar el titular más cansado (nunca el portero salvo emergencia).
	var indice_cansado: int = -1
	var energia_minima: float = 1000.0
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(
		str(estado.get("tactica_%s" % lado, {}).get("formacion", "4-4-2")),
		Datos_Manager.ROLES_FORMACION["4-4-2"])
	for i in range(alineacion.size()):
		if i < slots.size() and str(slots[i]) == "POR":
			continue
		var e: float = float(energia.get(str(alineacion[i]), 100.0))
		if e < energia_minima:
			energia_minima = e
			indice_cansado = i
	if indice_cansado < 0 or energia_minima >= 45.0:
		return

	var sale_id: String = str(alineacion[indice_cansado])
	var ranura: String = str(slots[indice_cansado]) if indice_cansado < slots.size() else "MC"
	var mejor_id: String = ""
	var mejor_puntuacion: float = -1.0
	for jugador_id in banquillo:
		var jugador: Dictionary = _Jugador_Estado(estado, lado, str(jugador_id))
		if jugador.is_empty():
			continue
		var puntuacion: float = Calcular_Calidad(jugador) * _Afinidad_Ranura(jugador, ranura)
		if puntuacion > mejor_puntuacion:
			mejor_puntuacion = puntuacion
			mejor_id = str(jugador_id)
	if mejor_id != "":
		_Sustitucion_Interna(estado, lado, sale_id, mejor_id, true)


static func Simular_Minuto(estado: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var generador: RandomNumberGenerator = _Rng(rng)
	if bool(estado.get("finalizado", false)):
		return estado
	if int(estado.get("minuto", 0)) >= Datos_Manager.DURACION_PARTIDO_MINUTOS:
		_Finalizar_Estado(estado)
		return estado

	estado["minuto"] = int(estado.get("minuto", 0)) + 1
	var minuto: int = int(estado["minuto"])

	var fuerza_local: Dictionary = Fuerza_Desde_Estado(estado, "local")
	var fuerza_visitante: Dictionary = Fuerza_Desde_Estado(estado, "visitante")

	var medio_l: float = maxf(float(fuerza_local["medio"]), 1.0)
	var medio_v: float = maxf(float(fuerza_visitante["medio"]), 1.0)
	var p_local: float = (medio_l * medio_l) / (medio_l * medio_l + medio_v * medio_v)
	p_local = clampf(p_local, 0.25, 0.75)
	estado["posesion_acumulada"] = float(estado.get("posesion_acumulada", 0.0)) + p_local * 100.0
	estado["posesion_muestras"] = int(estado.get("posesion_muestras", 0)) + 1

	_Resolver_Ataque(estado, "local", fuerza_local, fuerza_visitante, generador)
	_Resolver_Ataque(estado, "visitante", fuerza_visitante, fuerza_local, generador)

	# Faltas y tarjetas: ruido narrativo sin lesiones (regla del modo).
	if generador.randf() < 0.035:
		var equipo_falta: String = "local" if generador.randf() < 0.5 else "visitante"
		var nombre_falta: String = str(estado.get("%s_nombre" % equipo_falta, ""))
		if generador.randf() < 0.22:
			_Anadir_Evento(estado, "tarjeta", equipo_falta,
				"Tarjeta amarilla para un jugador de %s por una entrada tardía." % nombre_falta)
		elif generador.randf() < 0.30:
			_Anadir_Evento(estado, "falta", equipo_falta,
				"Falta de %s en el centro del campo." % nombre_falta)

	_Drenar_Energia(estado, "local", str(estado.get("tactica_local", {}).get("presion", "media")))
	_Drenar_Energia(estado, "visitante", str(estado.get("tactica_visitante", {}).get("presion", "media")))

	# La IA mueve el banquillo a partir del minuto 55. El equipo del usuario
	# solo cambia si él mismo lo ordena desde el panel del partido.
	if minuto >= 55 and minuto % 7 == 0:
		var lado_usuario: String = str(estado.get("lado_usuario", ""))
		if lado_usuario != "local":
			_Intentar_Cambio_IA(estado, "local", generador)
		if lado_usuario != "visitante":
			_Intentar_Cambio_IA(estado, "visitante", generador)

	if minuto >= Datos_Manager.DURACION_PARTIDO_MINUTOS:
		_Finalizar_Estado(estado)
	return estado


static func _Resolver_Ataque(estado: Dictionary, atacante: String,
		fuerza_ataque: Dictionary, fuerza_defensa: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var ataque: float = maxf(float(fuerza_ataque["ataque"]), 1.0)
	var defensa: float = maxf(float(fuerza_defensa["defensa"]), 1.0)
	var probabilidad: float = clampf(0.045 * (ataque / defensa) * 2.0, 0.02, 0.14)
	if rng.randf() >= probabilidad:
		return

	var es_local: bool = atacante == "local"
	var clave_tiros: String = "tiros_%s" % atacante
	var clave_puerta: String = "tiros_puerta_%s" % atacante
	var clave_corners: String = "corners_%s" % atacante
	estado[clave_tiros] = int(estado.get(clave_tiros, 0)) + 1

	var prob_gol: float = clampf(0.10 + (ataque - defensa) / 400.0, 0.04, 0.30)
	var tirada: float = rng.randf()
	if tirada < prob_gol:
		_Anadir_Gol(estado, atacante, rng)
	elif tirada < prob_gol + 0.34:
		estado[clave_puerta] = int(estado.get(clave_puerta, 0)) + 1
		if rng.randf() < 0.35:
			var nombre_equipo: String = str(estado.get("%s_nombre" % atacante, ""))
			_Anadir_Evento(estado, "ocasion", atacante,
				"Gran ocasión de %s: el portero salva con una mano firme." % nombre_equipo)
	elif tirada < prob_gol + 0.55:
		if rng.randf() < 0.25:
			var nombre_equipo2: String = str(estado.get("%s_nombre" % atacante, ""))
			_Anadir_Evento(estado, "ocasion", atacante,
				"Disparo desviado de %s desde la frontal." % nombre_equipo2)
	else:
		estado[clave_corners] = int(estado.get(clave_corners, 0)) + 1
		if rng.randf() < 0.20:
			var nombre_equipo3: String = str(estado.get("%s_nombre" % atacante, ""))
			_Anadir_Evento(estado, "corner", atacante,
				"Saque de esquina para %s." % nombre_equipo3)


static func _Anadir_Gol(estado: Dictionary, atacante: String,
		rng: RandomNumberGenerator) -> void:
	var es_local: bool = atacante == "local"
	var clave_puerta: String = "tiros_puerta_%s" % atacante
	estado[clave_puerta] = int(estado.get(clave_puerta, 0)) + 1
	if es_local:
		estado["goles_local"] = int(estado.get("goles_local", 0)) + 1
	else:
		estado["goles_visitante"] = int(estado.get("goles_visitante", 0)) + 1
	var goleador: Dictionary = _Elegir_Goleador(estado, atacante, rng)
	var asistente: Dictionary = {}
	if not goleador.is_empty():
		asistente = _Elegir_Asistente(estado, atacante, str(goleador.get("id", "")), rng)
	var nombre_goleador: String = str(goleador.get("nombre", "un jugador"))
	var nombre_equipo: String = str(estado.get("%s_nombre" % atacante, ""))
	var texto: String = "¡GOL de %s! %s (%d-%d)" % [
		nombre_equipo, nombre_goleador,
		int(estado.get("goles_local", 0)), int(estado.get("goles_visitante", 0))]
	if not asistente.is_empty():
		texto += " · Asistencia de %s" % str(asistente.get("nombre", ""))
		var lista_asistencias: Array = estado.get("asistencias_%s" % atacante, [])
		lista_asistencias.append({
			"id": str(asistente.get("id", "")),
			"nombre": str(asistente.get("nombre", "")),
			"minuto": int(estado.get("minuto", 0))
		})
		estado["asistencias_%s" % atacante] = lista_asistencias
	if not goleador.is_empty():
		var lista_goles: Array = estado.get("goleadores_%s" % atacante, [])
		lista_goles.append({
			"id": str(goleador.get("id", "")),
			"nombre": nombre_goleador,
			"minuto": int(estado.get("minuto", 0))
		})
		estado["goleadores_%s" % atacante] = lista_goles
	_Anadir_Evento(estado, "gol", atacante, texto)


static func _Finalizar_Estado(estado: Dictionary) -> void:
	if bool(estado.get("finalizado", false)):
		return
	estado["finalizado"] = true
	_Anadir_Evento(estado, "final", "",
		"Final del partido: %s %d-%d %s" % [
			str(estado.get("local_nombre", "")),
			int(estado.get("goles_local", 0)),
			int(estado.get("goles_visitante", 0)),
			str(estado.get("visitante_nombre", ""))])


static func Simular_Partido_Completo(estado: Dictionary,
		rng: RandomNumberGenerator = null) -> Dictionary:
	var generador: RandomNumberGenerator = _Rng(rng)
	var seguridad: int = 0
	while not bool(estado.get("finalizado", false)) and seguridad < 200:
		Simular_Minuto(estado, generador)
		seguridad += 1
	return estado


static func Posesion_Local(estado: Dictionary) -> float:
	var muestras: int = int(estado.get("posesion_muestras", 0))
	if muestras <= 0:
		return 50.0
	return clampf(float(estado.get("posesion_acumulada", 0.0)) / float(muestras), 0.0, 100.0)


# ------------------------------------------------------------------
# Cansancio y entrenamiento
# ------------------------------------------------------------------

static func Recuperacion_Por_Minuto(modo_rapido: bool) -> float:
	var base: float = Datos_Manager.RECUPERACION_POR_MINUTO_NORMAL
	return base * (Datos_Manager.MULTIPLICADOR_RECUPERACION_RAPIDA if modo_rapido else 1.0)


static func Recuperar_Energia_Plantilla(plantilla: Array, minutos: float,
		modo_rapido: bool) -> int:
	var ganancia: float = Recuperacion_Por_Minuto(modo_rapido) * maxf(minutos, 0.0)
	var recuperados: int = 0
	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var energia: float = float(jugador.get("energia", 100.0))
		if energia >= 100.0:
			continue
		jugador["energia"] = clampf(energia + ganancia, 0.0, 100.0)
		recuperados += 1
	return recuperados


static func Entrenar_Jugador(jugador: Dictionary, atributo: String,
		rng: RandomNumberGenerator = null) -> Dictionary:
	if not Datos_Manager.ATRIBUTOS.has(atributo):
		return {"ok": false, "motivo": "Atributo no válido.", "mejora": 0}
	var energia: float = float(jugador.get("energia", 100.0))
	if energia < Datos_Manager.COSTE_ENERGIA_ENTRENAMIENTO:
		return {"ok": false, "motivo": "El jugador no tiene energía suficiente.", "mejora": 0}
	var edad: int = int(jugador.get("edad", 18))
	var factor: float = 0.4
	if edad <= 21:
		factor = 1.0
	elif edad <= 25:
		factor = 0.8
	elif edad <= 29:
		factor = 0.55
	elif edad <= 33:
		factor = 0.3
	var generador: RandomNumberGenerator = _Rng(rng)
	var tirada: float = generador.randf()
	var mejora: int = 1
	if tirada < factor * 0.45:
		mejora = 2
	if edad > 33 and tirada > 0.6:
		mejora = 0
	var bloque: String = str(BLOQUE_DE_ATRIBUTO.get(atributo, "defensa"))
	var actual: int = int(jugador.get(bloque, {}).get(atributo, 50))
	var nuevo: int = clampi(actual + mejora, Datos_Manager.ATRIBUTO_MINIMO,
		Datos_Manager.ATRIBUTO_MAXIMO)
	jugador[bloque][atributo] = nuevo
	jugador["energia"] = maxf(0.0, energia - Datos_Manager.COSTE_ENERGIA_ENTRENAMIENTO)
	Recalcular_Jugador(jugador)
	return {
		"ok": true,
		"motivo": "",
		"mejora": nuevo - actual,
		"atributo": atributo,
		"valor": nuevo,
		"energia": float(jugador["energia"])
	}


# ------------------------------------------------------------------
# Mercado
# ------------------------------------------------------------------

static func Calcular_Nomina(plantilla: Array) -> int:
	var total: int = 0
	for jugador in plantilla:
		if jugador is Dictionary:
			total += maxi(0, int(jugador.get("salario_semanal", 0)))
	return total


static func Contar_Rol(plantilla: Array, rol: String) -> int:
	var total: int = 0
	for jugador in plantilla:
		if jugador is Dictionary and _Rol_Principal(jugador) == rol:
			total += 1
	return total


static func Puede_Comprar(club: Dictionary) -> Dictionary:
	var plantilla = club.get("plantilla", [])
	var tamano: int = plantilla.size() if plantilla is Array else 0
	if tamano >= Datos_Manager.PLANTILLA_MAXIMA:
		return {"ok": false, "motivo": "plantilla_completa",
			"texto": "Tu plantilla ya tiene %d futbolistas. Vende antes de fichar." % tamano}
	return {"ok": true, "motivo": "", "texto": ""}


static func Puede_Vender(club: Dictionary) -> Dictionary:
	var plantilla = club.get("plantilla", [])
	var tamano: int = plantilla.size() if plantilla is Array else 0
	if tamano <= Datos_Manager.PLANTILLA_MINIMA:
		return {"ok": false, "motivo": "plantilla_insuficiente",
			"texto": "No puedes vender: te quedarías con menos de %d futbolistas." \
				% Datos_Manager.PLANTILLA_MINIMA}
	return {"ok": true, "motivo": "", "texto": ""}


static func Evaluar_Oferta_Estandar(club_vendedor: Dictionary, jugador: Dictionary,
		oferta: int, club_comprador: Dictionary) -> Dictionary:
	var compra: Dictionary = Puede_Comprar(club_comprador)
	if not bool(compra.get("ok", false)):
		return {"aceptada": false, "motivo": str(compra.get("motivo", "")),
			"texto": str(compra.get("texto", ""))}
	if int(club_comprador.get("presupuesto", 0)) < oferta:
		return {"aceptada": false, "motivo": "sin_presupuesto",
			"texto": "Tu club no tiene presupuesto suficiente para esa oferta."}

	var plantilla_vendedor = club_vendedor.get("plantilla", [])
	var tamano_vendedor: int = plantilla_vendedor.size() if plantilla_vendedor is Array else 0
	if tamano_vendedor <= Datos_Manager.PLANTILLA_MINIMA:
		return {"aceptada": false, "motivo": "vendedor_sin_plantilla",
			"texto": "El club vendedor no puede quedarse sin efectivos."}

	var valor: int = int(jugador.get("valor_mercado", 0))
	if oferta <= valor:
		return {"aceptada": false, "motivo": "oferta_baja",
			"texto": "La oferta debe superar el valor de mercado (%d €)." % valor}

	var rol: String = _Rol_Principal(jugador)
	if Contar_Rol(plantilla_vendedor, rol) <= 1:
		return {"aceptada": false, "motivo": "unico_especialista",
			"texto": "El club no venderá a su único %s." % str(
				Datos_Manager.NOMBRES_ROLES.get(rol, rol))}

	return {"aceptada": true, "motivo": "", "texto": "Oferta aceptada."}


static func Calcular_Ingresos_Partido(division: int, goles_favor: int, goles_contra: int,
		es_local: bool, aficion: int, nivel_estadio: int = 1) -> int:
	var div: int = clampi(division, 1, 4)
	var factor: float = 0.15
	if goles_favor > goles_contra:
		factor = 1.0
	elif goles_favor == goles_contra:
		factor = 0.40
	var ingreso: float = float(Datos_Manager.INGRESOS_VICTORIA.get(div, 800)) * factor
	if es_local:
		var bonus_estadio: float = 1.0 + 0.20 * float(maxi(0, nivel_estadio - 1))
		var asistencia: float = float(maxi(aficion, 0)) * float(
			Datos_Manager.PRECIO_ENTRADA.get(div, 3)) * maxf(factor, 0.45) * bonus_estadio
		ingreso += asistencia * 0.60
	return maxi(0, int(round(ingreso)))


# ------------------------------------------------------------------
# Clasificaciones, ascensos y descensos
# ------------------------------------------------------------------

static func Ordenar_Clasificacion(clubes: Dictionary, ids: Array) -> Array:
	var entradas: Array = []
	for club_id in ids:
		var club = clubes.get(str(club_id), null)
		if not (club is Dictionary):
			continue
		entradas.append({
			"id": str(club_id),
			"puntos": int(club.get("puntos", 0)),
			"goles_favor": int(club.get("goles_favor", 0)),
			"goles_contra": int(club.get("goles_contra", 0)),
			"diferencia": int(club.get("goles_favor", 0)) - int(club.get("goles_contra", 0))
		})
	entradas.sort_custom(func(a, b):
		if int(a["puntos"]) != int(b["puntos"]):
			return int(a["puntos"]) > int(b["puntos"])
		if int(a["diferencia"]) != int(b["diferencia"]):
			return int(a["diferencia"]) > int(b["diferencia"])
		if int(a["goles_favor"]) != int(b["goles_favor"]):
			return int(a["goles_favor"]) > int(b["goles_favor"])
		return str(a["id"]) < str(b["id"]))
	return entradas


static func Resolver_Ascensos_Descensos(clubes: Dictionary, clasificaciones: Dictionary) -> Dictionary:
	# Con 4 clubes por división el ecosistema se mantiene estable moviendo
	# exactamente 2 arriba y 2 abajo en cada frontera.
	var nuevos: Dictionary = {}
	for club_id in clubes.keys():
		nuevos[str(club_id)] = int(clubes[club_id].get("division", 4))

	var movimientos: Array = []
	var ascendidos: Array = []
	var descendidos: Array = []
	var campeones: Dictionary = {}

	for division in range(1, 5):
		var orden: Array = clasificaciones.get(str(division), [])
		if orden.is_empty():
			continue
		campeones[str(division)] = str(orden[0])
		if division < 4:
			# Los dos primeros de la división inferior suben.
			var inferiores: Array = clasificaciones.get(str(division + 1), [])
			for i in range(mini(2, inferiores.size())):
				var club_id: String = str(inferiores[i])
				if nuevos.has(club_id):
					nuevos[club_id] = division
					ascendidos.append(club_id)
					movimientos.append({"club_id": club_id, "de": division + 1,
						"a": division, "tipo": "ascenso"})
		if division < 4:
			# Los dos últimos de esta división bajan.
			for i in range(maxi(0, orden.size() - 2), orden.size()):
				var club_id2: String = str(orden[i])
				if nuevos.has(club_id2):
					nuevos[club_id2] = division + 1
					descendidos.append(club_id2)
					movimientos.append({"club_id": club_id2, "de": division,
						"a": division + 1, "tipo": "descenso"})

	return {
		"divisiones_finales": nuevos,
		"movimientos": movimientos,
		"ascendidos": ascendidos,
		"descendidos": descendidos,
		"campeones": campeones
	}


# ------------------------------------------------------------------
# Humanización, cantera y emparejamientos
# ------------------------------------------------------------------

static func Parejas_Jornada_Division(jornada: int, ids: Array) -> Array:
	if ids.size() < 4:
		var parejas_cortas: Array = []
		if ids.size() >= 2:
			parejas_cortas.append([str(ids[0]), str(ids[1])])
		return parejas_cortas
	match clampi(jornada, 0, 3):
		0:
			return [[str(ids[0]), str(ids[3])], [str(ids[1]), str(ids[2])]]
		1:
			return [[str(ids[0]), str(ids[2])], [str(ids[3]), str(ids[1])]]
		2:
			return [[str(ids[0]), str(ids[1])], [str(ids[2]), str(ids[3])]]
		_:
			return [[str(ids[0]), str(ids[1])], [str(ids[2]), str(ids[3])]]


static func Generar_Canteranos_Ojeo(club_id: String, division: int, nivel_cantera: int = 1,
		rng: RandomNumberGenerator = null, usado_nombres: Dictionary = {},
		dorsales_usados: Dictionary = {}) -> Array:
	var generador: RandomNumberGenerator = _Rng(rng)
	var roles_pool: Array = ["POR", "DFC", "LD", "LI", "MCD", "MC", "MCO", "ED", "EI", "DEL"]
	var candidatos: Array = []
	var dorsales_copia: Dictionary = dorsales_usados.duplicate()
	var bonus_academia: float = float(maxi(0, nivel_cantera - 1)) * 2.4
	var base: float = float(Datos_Manager.BASE_ATRIBUTOS_DIVISION.get(clampi(division, 1, 4), 40.0))
	for i in range(3):
		var rol: String = str(roles_pool[generador.randi_range(0, roles_pool.size() - 1)])
		var edad: int = generador.randi_range(16, 20)
		var calidad: float = clampf(base - 3.0 + bonus_academia + generador.randf_range(-4.0, 7.5),
			28.0, 90.0)
		var id_cand: String = "%s_can_%06d" % [club_id, generador.randi_range(100000, 999999)]
		var jugador: Dictionary = Crear_Jugador(
			id_cand, rol, division, generador, edad, calidad, usado_nombres)
		jugador["dorsal"] = _Dorsal_Libre_Desde(dorsales_copia)
		dorsales_copia[int(jugador["dorsal"])] = true
		jugador["entrenado_dia"] = -1
		candidatos.append(jugador)
	return candidatos


static func Apariencia_De_Jugador(jugador: Dictionary, colores_club: Array = [],
		patron_club: int = 1) -> Dictionary:
	var jid: String = str(jugador.get("id", "p01"))
	var nombre: String = str(jugador.get("nombre", ""))
	var es_fem: bool = Datos_Manager.Es_Nombre_Femenino(nombre)
	var semilla: int = abs((jid + "|" + nombre).hash())
	var rng := RandomNumberGenerator.new()
	rng.seed = int(semilla) if semilla != 0 else 12345

	var genero: String = "mujer" if es_fem else "hombre"
	var piel: Dictionary = Apariencia_Personaje.COLORES_PIEL[
		rng.randi_range(0, Apariencia_Personaje.COLORES_PIEL.size() - 1)]
	var ojo: Dictionary = Apariencia_Personaje.COLORES_OJOS[
		rng.randi_range(0, Apariencia_Personaje.COLORES_OJOS.size() - 1)]
	var pelo_idx: int = rng.randi_range(0, 8)
	var pelo_col: Dictionary = Apariencia_Personaje.COLORES_PELO[pelo_idx]

	var pelos_compatibles: Array = []
	for item in Apariencia_Personaje.ESTILOS_PELO:
		var sug: String = str(item.get("sugerido", "ambos"))
		if sug == genero or sug == "ambos":
			pelos_compatibles.append(str(item.get("id", "corto")))
	if pelos_compatibles.is_empty():
		pelos_compatibles = ["corto"]
	var estilo_pelo: String = str(pelos_compatibles[rng.randi_range(0, pelos_compatibles.size() - 1)])

	var edad_j: int = int(jugador.get("edad", 22))
	var vello: String = "ninguno"
	if not es_fem and edad_j >= 20 and rng.randf() < 0.42:
		var vellos: Array = ["sombra", "barba_corta", "perilla", "candado"]
		vello = str(vellos[rng.randi_range(0, vellos.size() - 1)])

	var col_pri: String = str(colores_club[0]) if colores_club.size() >= 1 else "#0f766e"
	var col_sec: String = str(colores_club[1]) if colores_club.size() >= 2 else "#ffffff"
	var dorsal: int = clampi(int(jugador.get("dorsal", 10)), 1, 99)
	var rol_p: String = _Rol_Principal(jugador)
	# Portero con color contrastado sobre la camiseta del club.
	if rol_p == "POR":
		col_pri = "#f59e0b" if col_pri.to_lower() != "#f59e0b" else "#1e293b"
		col_sec = "#111827"

	return Apariencia_Personaje.normalizar({
		"nombre": nombre,
		"genero": genero,
		"complexion": "atletico" if int(jugador.get("peso", 75)) < 82 else "robusto",
		"color_piel": str(piel.get("hex", "#f8cfb4")),
		"forma_cara": str(Apariencia_Personaje.FORMAS_CARA[
			rng.randi_range(0, Apariencia_Personaje.FORMAS_CARA.size() - 1)]["id"]),
		"forma_ojos": str(Apariencia_Personaje.FORMAS_OJOS[
			rng.randi_range(0, Apariencia_Personaje.FORMAS_OJOS.size() - 1)]["id"]),
		"color_ojos": str(ojo.get("hex", "#6b4226")),
		"estilo_cejas": str(Apariencia_Personaje.ESTILOS_CEJAS[
			rng.randi_range(0, Apariencia_Personaje.ESTILOS_CEJAS.size() - 1)]["id"]),
		"forma_nariz": str(Apariencia_Personaje.FORMAS_NARIZ[
			rng.randi_range(0, Apariencia_Personaje.FORMAS_NARIZ.size() - 1)]["id"]),
		"forma_boca": str(Apariencia_Personaje.FORMAS_BOCA[
			rng.randi_range(0, Apariencia_Personaje.FORMAS_BOCA.size() - 1)]["id"]),
		"color_pelo": str(pelo_col.get("hex", "#7c4728")),
		"estilo_pelo": estilo_pelo,
		"vello_facial": vello,
		"pecas": rng.randf() < 0.14,
		"rubor": "suave",
		"delineado": es_fem and rng.randf() < 0.6,
		"estilo_ropa": "futbol",
		"ropa_superior": "camiseta",
		"ropa_inferior": "shorts",
		"calzado": "zapatillas",
		"color_ropa": col_pri,
		"color_ropa_secundario": col_sec,
		"color_ropa_detalle": "#fbbf24" if col_pri.to_lower() != "#ca8a04" else "#ffffff",
		"color_pantalon": col_sec,
		"color_calzado": "#111827",
		"detalle_ropa": "club_%d_%d" % [clampi(patron_club, 0, 4), dorsal]
	})


static func Rasgo_Humano_Jugador(jugador: Dictionary) -> String:
	var edad: int = int(jugador.get("edad", 22))
	var roles = jugador.get("roles", [])
	if int(jugador.get("goles", 0)) >= 3:
		return "En racha goleadora"
	if int(jugador.get("asistencias", 0)) >= 3:
		return "Asistente clave"
	if edad <= 19:
		return "Joven promesa"
	if edad >= 34:
		return "Veterano con oficio"
	if roles is Array and roles.size() >= 2:
		return "Polivalente (%s/%s)" % [str(roles[0]), str(roles[1])]
	var mejor_attr: String = ""
	var mejor_val: float = -1.0
	for attr in Datos_Manager.ATRIBUTOS:
		var v: float = _Atributo(jugador, str(attr))
		if v > mejor_val:
			mejor_val = v
			mejor_attr = str(attr)
	return "Fuerte en %s" % str(Datos_Manager.NOMBRES_ATRIBUTOS.get(mejor_attr, "juego"))


static func Frase_Vestuario_Jugador(jugador: Dictionary) -> String:
	var energia: float = float(jugador.get("energia", 100.0))
	var edad: int = int(jugador.get("edad", 22))
	var goles: int = int(jugador.get("goles", 0))
	if energia < 45.0:
		return "«Estoy bastante cargado, míster. Un respiro me vendría bien antes del próximo choque.»"
	if goles >= 2:
		return "«Me encuentro con mucha confianza de cara a puerta. ¡Dame balones y lo intento!»"
	if edad <= 20:
		return "«Con ganas de aprender y aprovechar cada minuto que me des en el campo.»"
	if edad >= 34:
		return "«He vivido mil partidos como este. Cuenta conmigo para ordenar al grupo.»"
	return "«Al 100 % y listo para lo que necesite el equipo, míster.»"
