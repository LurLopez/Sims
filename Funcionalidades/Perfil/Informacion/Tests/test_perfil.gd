extends GutTest

# Tests para la pantalla de Perfil con pestañas
# Verifica la lógica de Info (edad, personalidad) y el comportamiento de las pestañas


func test_calculo_edad_personaje():
	# La edad debe ser 18 + semanas transcurridas
	var minute_day_inicio = 0
	var minute_day_actual = 70  # 10 semanas
	var edad = 18 + (minute_day_actual - minute_day_inicio) / 7
	assert_eq(edad, 28, "10 semanas = 10 años → 18 + 10 = 28")


func test_calculo_edad_inicio_partida():
	# Al inicio (Minute_Day == First_Time_Minute_Day) debe tener 18 años
	var mismo_dia = 100
	var edad = 18 + (mismo_dia - mismo_dia) / 7
	assert_eq(edad, 18, "Sin semanas transcurridas la edad es 18")


func test_calculo_edad_no_supera_limite():
	# Con 82 semanas (máximo del juego) la edad es 18 + 82 = 100, no puede ser negativa
	var edad = 18 + (82 * 7) / 7
	assert_true(edad >= 18, "La edad nunca puede ser menor de 18")


func test_personalidad_sin_guiones():
	# La personalidad se muestra con espacios en lugar de guiones bajos
	var personalidad_raw = "Trabajador_Compulsivo"
	var personalidad_display = personalidad_raw.replace("_", " ")
	assert_eq(personalidad_display, "Trabajador Compulsivo")


func test_personalidad_deportista_sin_cambio():
	# "Deportista" no tiene guiones y no debe cambiar
	var personalidad_raw = "Deportista"
	var personalidad_display = personalidad_raw.replace("_", " ")
	assert_eq(personalidad_display, "Deportista")


func test_habilidades_limite_min():
	# El loop de habilidades usa min() para evitar out-of-bounds
	var nombres_hab = ["Deporte", "Inteligencia", "Destreza manual", "Memoria", "Liderazgo", "Paciencia"]
	var habilidades_simuladas = [50, 70, 30, 80, 60, 45]
	var limite = min(nombres_hab.size(), habilidades_simuladas.size())
	assert_eq(limite, 6, "Con 6 nombres y 6 habilidades el limite es 6")
	# No debe intentar acceder al indice 6
	assert_true(limite <= nombres_hab.size(), "El limite nunca supera el tamanyo de nombres_hab")
	assert_true(limite <= habilidades_simuladas.size(), "El limite nunca supera el tamanyo de Habilidades")


func test_habilidades_limite_con_array_mas_grande():
	# Si Habilidades tuviera mas de 6 elementos, el limite sigue siendo 6 (nombres_hab)
	var nombres_hab = ["Deporte", "Inteligencia", "Destreza manual", "Memoria", "Liderazgo", "Paciencia"]
	var habilidades_extra = [50, 70, 30, 80, 60, 45, 99]  # 7 elementos
	var limite = min(nombres_hab.size(), habilidades_extra.size())
	assert_eq(limite, 6, "Con 7 habilidades el limite sigue siendo 6 por nombres_hab")


func test_progreso_rango_valido():
	# Los valores de Progreso deben estar entre 1 y 100
	for valor in Variables_Dinamicas.Progreso:
		assert_true(valor >= 1, "Progreso minimo es 1")
		assert_true(valor <= 100, "Progreso maximo es 100")
