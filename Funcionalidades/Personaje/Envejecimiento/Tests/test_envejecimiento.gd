extends Node
# Tests del sistema de envejecimiento progresivo del personaje.
# Para ejecutar: adjunta este script a un nodo en una escena vacía y lánzala.
#
# Comprueba la lógica pura de Envejecimiento_Personaje: factores por edad,
# monotonía, orden de aparición de los rasgos, colores y etiquetas de etapa.

func _ready():
	print("=== TESTS DE ENVEJECIMIENTO DEL PERSONAJE ===\n")
	_Test_Edad18_Sin_Rasgos()
	_Test_Monotonia()
	_Test_Topes_Alcanzados()
	_Test_Orden_De_Aparicion()
	_Test_Color_Pelo()
	_Test_Color_Piel()
	_Test_Etapas()
	_Test_Porcentaje()
	_Test_Claves_Completas()
	print("\n=== FIN DE TESTS ===")


# ─────────────────────────────────────────────────────────────────────────────
# Helpers

func _OK(cond: bool, nombre: String, detalle: String = "") -> void:
	if cond:
		print("  ✅ %s" % nombre)
	else:
		print("  ❌ %s%s" % [nombre, (" — " + detalle) if detalle != "" else ""])


func _Edad_Con_Factor(clave: String, umbral: float = 0.05) -> int:
	for edad in range(Envejecimiento_Personaje.EDAD_MIN, Envejecimiento_Personaje.EDAD_MAX + 1):
		if Envejecimiento_Personaje.factor(edad, clave) >= umbral:
			return edad
	return -1


# ─────────────────────────────────────────────────────────────────────────────
# Tests

func _Test_Edad18_Sin_Rasgos() -> void:
	print("TEST 1 — A los 18 años no hay ningún rasgo de envejecimiento activo")
	var r := Envejecimiento_Personaje.rasgos(18)
	var fallos: Array[String] = []
	for clave: String in Envejecimiento_Personaje.CURVAS:
		if float(r[clave]) > 0.0001:
			fallos.append("%s=%.4f" % [clave, float(r[clave])])
	_OK(fallos.is_empty(), "Todos los factores valen 0 a los 18",
		", ".join(fallos))


func _Test_Monotonia() -> void:
	print("TEST 2 — Cada rasgo crece de forma monótona con la edad")
	var fallos: Array[String] = []
	for clave: String in Envejecimiento_Personaje.CURVAS:
		var anterior := -1.0
		for edad in range(Envejecimiento_Personaje.EDAD_MIN, Envejecimiento_Personaje.EDAD_MAX + 1):
			var v := Envejecimiento_Personaje.factor(edad, clave)
			if v < anterior - 0.000001:
				fallos.append("%s baja a los %d" % [clave, edad])
				break
			anterior = v
	_OK(fallos.is_empty(), "Ningún rasgo retrocede con los años", ", ".join(fallos))


func _Test_Topes_Alcanzados() -> void:
	print("TEST 3 — A los 100 años todos los rasgos están al 100 %")
	var r := Envejecimiento_Personaje.rasgos(Envejecimiento_Personaje.EDAD_MAX)
	var fallos: Array[String] = []
	for clave: String in Envejecimiento_Personaje.CURVAS:
		if absf(float(r[clave]) - 1.0) > 0.0001:
			fallos.append("%s=%.3f" % [clave, float(r[clave])])
	_OK(fallos.is_empty(), "Todos los factores llegan a 1 a los 100", ", ".join(fallos))


func _Test_Orden_De_Aparicion() -> void:
	print("TEST 4 — Los rasgos aparecen en orden natural de envejecimiento")
	var surcos := _Edad_Con_Factor("surcos")
	var canas := _Edad_Con_Factor("canas")
	var manchas := _Edad_Con_Factor("manchas")
	var postura := _Edad_Con_Factor("postura")
	_OK(surcos > 0 and surcos < canas,
		"Surcos antes que canas", "surcos=%d canas=%d" % [surcos, canas])
	_OK(canas < manchas,
		"Canas antes que manchas", "canas=%d manchas=%d" % [canas, manchas])
	_OK(manchas < postura,
		"Manchas antes que postura encorvada", "manchas=%d postura=%d" % [manchas, postura])
	_OK(canas <= 40, "Las primeras canas llegan a los 40 como máximo",
		"primera cana visible a los %d" % canas)


func _Test_Color_Pelo() -> void:
	print("TEST 5 — El pelo se aclara y pierde brillo con las canas")
	var base := Color("#432818")
	var joven := Envejecimiento_Personaje.color_pelo(base, 0.0)
	var medio := Envejecimiento_Personaje.color_pelo(base, 0.5)
	var viejo := Envejecimiento_Personaje.color_pelo(base, 1.0)
	_OK(joven.is_equal_approx(base), "Sin canas el color no cambia")
	_OK(viejo.v > medio.v and medio.v > joven.v,
		"La luminosidad crece con las canas",
		"v: %.3f < %.3f < %.3f" % [joven.v, medio.v, viejo.v])
	_OK(viejo.s < joven.s, "El pelo blanco está desaturado",
		"s: %.3f → %.3f" % [joven.s, viejo.s])
	var claro := Envejecimiento_Personaje.color_pelo(Color("#ead9b0"), 1.0)
	_OK(_Color_Valido(viejo) and _Color_Valido(claro),
		"Los colores resultantes son válidos (0..1)")
	_OK(claro.v >= 0.85, "Un pelo rubio también termina blanco",
		"v=%.3f" % claro.v)


func _Test_Color_Piel() -> void:
	print("TEST 6 — La piel se apaga sin cambiar de tono")
	var base := Color("#c68255")
	var joven := Envejecimiento_Personaje.color_piel(base, 0.0)
	var viejo := Envejecimiento_Personaje.color_piel(base, 1.0)
	_OK(joven.is_equal_approx(base), "Sin envejecimiento el color no cambia")
	_OK(viejo.s < joven.s, "La piel pierde saturación",
		"s: %.3f → %.3f" % [joven.s, viejo.s])
	_OK(viejo.h > 0.0 and absf(viejo.h - joven.h) < 0.02,
		"El tono (hue) se conserva", "h: %.3f → %.3f" % [joven.h, viejo.h])
	_OK(_Color_Valido(viejo), "El color de piel resultante es válido")


func _Test_Etapas() -> void:
	print("TEST 7 — Etapas de vida legibles")
	var casos := [
		[18, "Joven adulto"], [29, "Joven adulto"], [30, "Adulto"],
		[44, "Adulto"], [45, "Madurez"], [59, "Madurez"],
		[60, "Madurez tardía"], [74, "Madurez tardía"], [75, "Vejez"], [100, "Vejez"],
	]
	var fallos: Array[String] = []
	for caso: Array in casos:
		var edad: int = caso[0]
		var esperado: String = caso[1]
		if Envejecimiento_Personaje.etapa(edad) != esperado:
			fallos.append("%d→%s" % [edad, Envejecimiento_Personaje.etapa(edad)])
	_OK(fallos.is_empty(), "Los límites de etapa son correctos", ", ".join(fallos))


func _Test_Porcentaje() -> void:
	print("TEST 8 — Porcentaje global de envejecimiento")
	_OK(Envejecimiento_Personaje.porcentaje_envejecimiento(18) == 0, "18 años → 0 %")
	_OK(Envejecimiento_Personaje.porcentaje_envejecimiento(100) == 100, "100 años → 100 %")
	var p50 := Envejecimiento_Personaje.porcentaje_envejecimiento(59)
	_OK(p50 > 40 and p50 < 60, "59 años → en torno a la mitad",
		"%d %%" % p50)


func _Test_Claves_Completas() -> void:
	print("TEST 9 — El diccionario de rasgos incluye todas las claves")
	var r := Envejecimiento_Personaje.rasgos(50)
	var faltan: Array[String] = []
	for clave: String in Envejecimiento_Personaje.RASGOS:
		if not r.has(clave):
			faltan.append(clave)
	_OK(faltan.is_empty(), "Todas las claves documentadas existen", ", ".join(faltan))
	_OK(r.size() == Envejecimiento_Personaje.CURVAS.size(), "No sobran claves",
		"%d claves para %d curvas" % [r.size(), Envejecimiento_Personaje.CURVAS.size()])


func _Color_Valido(c: Color) -> bool:
	var valores := [c.r, c.g, c.b, c.a]
	for v: float in valores:
		if v < -0.0001 or v > 1.0001:
			return false
	return true
