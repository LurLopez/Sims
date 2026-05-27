extends Node

var ultimo_minuto = -1
var mostradas_estaticas = false

func _process(_delta):
	if not mostradas_estaticas:
		if Variables_Estaticas.First_Time != true or Variables_Estaticas.Personalidad != "":
			mostradas_estaticas = true
			print("\n========== VARIABLES ESTÁTICAS ==========")
			print("First_Time: %s" % Variables_Estaticas.First_Time)
			print("Personalidad: %s" % Variables_Estaticas.Personalidad)
			print("Habilidades [Deporte, Inteligencia, Destreza, Memoria, Liderazgo, Paciencia]: %s" % str(Variables_Estaticas.Habilidades))
			print("First_Time_Minute (Unix): %d" % Variables_Estaticas.First_Time_Minute)
			print("Fecha inicio (día/mes/año): %d/%d/%d" % [Variables_Estaticas.First_Time_Day_Of_Month, Variables_Estaticas.First_Time_Month, Variables_Estaticas.First_Time_Year])
			print("First_Time_Minute_Day: %d" % Variables_Estaticas.First_Time_Minute_Day)
			print("First_Time_Minute_Minute: %d" % Variables_Estaticas.First_Time_Minute_Minute)
			print("\n========== VARIABLES DINÁMICAS (carga inicial) ==========")
			mostrar_variables_dinamicas()
			return

	var minuto_actual = floor(Time.get_unix_time_from_system() / 60)
	if minuto_actual != ultimo_minuto:
		ultimo_minuto = minuto_actual
		print("\n========== VARIABLES DINÁMICAS (minuto %d) ==========" % minuto_actual)
		mostrar_variables_dinamicas()

func mostrar_variables_dinamicas():
	print("Progreso [Deporte, Académico, Manualidades]: %s" % str(Variables_Dinamicas.Progreso))
	print("Necesidades Básicas [Salud_Fis, Salud_Men, Hambre, Descanso, Higiene]: %s" % str(Variables_Dinamicas.Necesidades_Basicas))
	print("Dinero: %.2f" % Variables_Dinamicas.Dinero)
	print("Minute (Unix): %d" % Variables_Dinamicas.Minute)
	print("Minute_Day (día): %d" % Variables_Dinamicas.Minute_Day)
	print("Minute_Minute (minuto del día): %d" % Variables_Dinamicas.Minute_Minute)
