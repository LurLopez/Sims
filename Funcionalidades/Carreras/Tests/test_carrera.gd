extends Node
# Tests para el sistema de Carreras Universitarias

func _ready():
	print("=== TESTS DE CARRERA UNIVERSITARIA ===\n")
	_Test_Crear_Carrera()
	_Test_Matricular_Con_Dinero()
	_Test_Matricular_Sin_Dinero()
	_Test_Doble_Matricula_Bloqueada()
	_Test_Procesar_Aprobado()
	_Test_Procesar_Suspendido()
	_Test_Carrera_Completada()
	_Test_Habilidades_Academicas()
	_Test_Necesidades_Examen()
	_Test_Distribucion_Normal_En_Rango()
	print("\n=== FIN DE TESTS ===")

func _Reset_Estado():
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Carreras_Completadas = []
	Variables_Dinamicas.Inicio_Semana_Carrera = -1
	Variables_Dinamicas.Dinero = 1000
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	while Variables_Estaticas.Habilidades.size() < 7:
		Variables_Estaticas.Habilidades.append(50)
	for i in range(7):
		Variables_Estaticas.Habilidades[i] = 50

func _Aprobar_O_Fallar(condicion: bool, nombre: String, detalle: String = ""):
	if condicion:
		print("✅ %s" % nombre)
	else:
		print("❌ %s — %s" % [nombre, detalle])

func _Test_Crear_Carrera():
	var c = Carrera_Ingenieria_Informatica.new()
	_Aprobar_O_Fallar(c.nombre == "Ingenieria_Informatica", "Crear_Carrera_Nombre")
	_Aprobar_O_Fallar(c.años_totales == 4, "Crear_Carrera_Años")
	_Aprobar_O_Fallar(c.año_actual == 1, "Crear_Carrera_AñoInicial")
	_Aprobar_O_Fallar(c.progreso_actual == 0.0, "Crear_Carrera_Progreso")
	_Aprobar_O_Fallar(c.costo_matricula_anual == 500.0, "Crear_Carrera_Matricula")
	_Aprobar_O_Fallar(c.libros_desbloqueados == ["Anio_1"], "Crear_Carrera_LibroInicial")

func _Test_Matricular_Con_Dinero():
	_Reset_Estado()
	var c = Carrera_Ingenieria_Informatica.new()
	var ok = Sistema_Examenes.Matricular(c)
	_Aprobar_O_Fallar(ok, "Matricular_OK", "matricularse con 1000€ debería funcionar")
	_Aprobar_O_Fallar(Variables_Dinamicas.Dinero == 500, "Matricular_RestaDinero")
	_Aprobar_O_Fallar(Variables_Dinamicas.Carrera_Actual == c, "Matricular_SeAsigna")

func _Test_Matricular_Sin_Dinero():
	_Reset_Estado()
	Variables_Dinamicas.Dinero = 100
	var c = Carrera_Ingenieria_Informatica.new()
	var ok = Sistema_Examenes.Matricular(c)
	_Aprobar_O_Fallar(not ok, "Matricular_SinDinero_Falla")
	_Aprobar_O_Fallar(Variables_Dinamicas.Carrera_Actual == null, "Matricular_SinDinero_NoAsigna")

func _Test_Doble_Matricula_Bloqueada():
	_Reset_Estado()
	var c1 = Carrera_Ingenieria_Informatica.new()
	Sistema_Examenes.Matricular(c1)
	var c2 = Carrera_Ingenieria_Informatica.new()
	var ok = Sistema_Examenes.Matricular(c2)
	_Aprobar_O_Fallar(not ok, "Doble_Matricula_Falla")
	_Aprobar_O_Fallar(Variables_Dinamicas.Carrera_Actual == c1, "Doble_Matricula_MantieneOriginal")

func _Test_Procesar_Aprobado():
	_Reset_Estado()
	var c = Carrera_Ingenieria_Informatica.new()
	c.progreso_actual = 100.0
	c.nota_real_ultima = 100
	# Forzar habilidades y necesidades al máximo para garantizar nota alta
	for i in range(7):
		Variables_Estaticas.Habilidades[i] = 100
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	var resultado = Sistema_Examenes.Procesar_Fin_De_Semana(c)
	_Aprobar_O_Fallar(resultado["aprobado"], "Aprobar_Con_Maximos", "nota_final = %f" % resultado["nota_final"])
	_Aprobar_O_Fallar(c.año_actual == 2, "Aprobar_AvanzaAño")
	_Aprobar_O_Fallar(c.progreso_actual == 0.0, "Aprobar_ReseteaProgreso")
	_Aprobar_O_Fallar(c.libros_desbloqueados.has("Anio_2"), "Aprobar_DesbloqueaLibro")

func _Test_Procesar_Suspendido():
	_Reset_Estado()
	var c = Carrera_Ingenieria_Informatica.new()
	c.progreso_actual = 0.0
	c.nota_real_ultima = 0
	# Forzar habilidades y necesidades al mínimo para garantizar suspensión
	for i in range(7):
		Variables_Estaticas.Habilidades[i] = 1
	Variables_Dinamicas.Necesidades_Basicas = [1, 1, 1, 1, 1]
	var resultado = Sistema_Examenes.Procesar_Fin_De_Semana(c)
	_Aprobar_O_Fallar(not resultado["aprobado"], "Suspender_Con_Minimos", "nota_final = %f" % resultado["nota_final"])
	_Aprobar_O_Fallar(c.año_actual == 1, "Suspender_NoAvanzaAño")
	_Aprobar_O_Fallar(c.num_intentos == 1, "Suspender_IncrementaIntento")

func _Test_Carrera_Completada():
	_Reset_Estado()
	var c = Carrera_Ingenieria_Informatica.new()
	c.año_actual = 4
	c.progreso_actual = 100.0
	c.nota_real_ultima = 100
	for i in range(7):
		Variables_Estaticas.Habilidades[i] = 100
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	var dinero_antes = Variables_Dinamicas.Dinero
	var resultado = Sistema_Examenes.Procesar_Fin_De_Semana(c)
	_Aprobar_O_Fallar(resultado["aprobado"], "Completar_Aprobar")
	_Aprobar_O_Fallar(c.completada, "Completar_Marcada")
	_Aprobar_O_Fallar(resultado["carrera_completada"], "Completar_Flag")
	_Aprobar_O_Fallar(Variables_Dinamicas.Dinero == dinero_antes + Sistema_Examenes.BONUS_DINERO_CARRERA_COMPLETADA, "Completar_BonusDinero")

func _Test_Habilidades_Academicas():
	_Reset_Estado()
	# Inteligencia=80, Memoria=60, Sangre_Fria=70
	Variables_Estaticas.Habilidades[1] = 80
	Variables_Estaticas.Habilidades[3] = 60
	Variables_Estaticas.Habilidades[6] = 70
	# Esperado: 80*0.35 + 60*0.15 + 70*0.50 = 28 + 9 + 35 = 72
	var resultado = Sistema_Examenes.Calcular_Habilidades_Academicas()
	_Aprobar_O_Fallar(abs(resultado - 72.0) < 0.001, "Habilidades_Calculo", "resultado=%f esperado=72" % resultado)

func _Test_Necesidades_Examen():
	_Reset_Estado()
	# Salud_Mental[1]=80, Hambre[2]=60, Descanso[3]=70
	Variables_Dinamicas.Necesidades_Basicas[1] = 80
	Variables_Dinamicas.Necesidades_Basicas[2] = 60
	Variables_Dinamicas.Necesidades_Basicas[3] = 70
	# Esperado: 70*0.40 + 80*0.40 + 60*0.20 = 28 + 32 + 12 = 72
	var resultado = Sistema_Examenes.Calcular_Necesidades_Examen()
	_Aprobar_O_Fallar(abs(resultado - 72.0) < 0.001, "Necesidades_Calculo", "resultado=%f esperado=72" % resultado)

func _Test_Distribucion_Normal_En_Rango():
	_Reset_Estado()
	var fuera_rango = 0
	for i in range(1000):
		var v = Sistema_Examenes.Distribucion_Normal(50.0)
		if v < 0.0 or v > 100.0:
			fuera_rango += 1
	_Aprobar_O_Fallar(fuera_rango == 0, "Distribucion_Normal_Rango", "fuera_rango=%d" % fuera_rango)
