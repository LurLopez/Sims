extends Node



func Ejecutar_Actividad_Progreso_Array(efecto_progreso):
	var deporte=Variables_Estaticas.Habilidades[0]
	var inteligencia=Variables_Estaticas.Habilidades[1]
	var destreza_manual=Variables_Estaticas.Habilidades[2]
	var memoria=Variables_Estaticas.Habilidades[3]
	var liderazgo=Variables_Estaticas.Habilidades[4]
	var paciencia=Variables_Estaticas.Habilidades[5]
	
	var sum_habilidades_deportivo=(50*deporte+40*liderazgo+10*memoria)
	Ejecutar_Actividad_Progreso(sum_habilidades_deportivo,0,5,efecto_progreso[0])
	
	var sum_habilidades_academico=(50*inteligencia+20*paciencia+30*memoria)
	Ejecutar_Actividad_Progreso(sum_habilidades_academico,1,5,efecto_progreso[1])
	
	var sum_habilidades_manualidades=(50*destreza_manual+30*paciencia+10*memoria+10*liderazgo)
	Ejecutar_Actividad_Progreso(sum_habilidades_manualidades,2,5,efecto_progreso[2])
	
func Ejecutar_Actividad_Progreso(sum_habilidades,indice_progreso,por_cuanto_ecuacion,por_cuanto_efecto):
	if(por_cuanto_efecto!=0):
		var max= Calcular_Max_Para_Numero_Aleatorio_Especifico(sum_habilidades,indice_progreso,por_cuanto_ecuacion)
		var max_ajustado= floor(max/por_cuanto_efecto)
		if(Funciones_Globales.Generar_Numero_Aleatorio_Entero_Es_Cero(max_ajustado)):
			Cambiar_Progreso(indice_progreso)



func Cambiar_Progreso(indice):
	if(Variables_Dinamicas.Progreso[indice]!=100):
		Variables_Dinamicas.Progreso[indice]=Variables_Dinamicas.Progreso[indice]+1
	


func Calcular_Max_Numero_Aleatorio(valor_actual, suma_habilidad, por_cuanto_ecuacion):
	var potencia1=(30+valor_actual)/100.0
	var potencia2=15000/float(5000+suma_habilidad)
	var resultado=floor(por_cuanto_ecuacion*(8**potencia1)**potencia2)
	return resultado

func Calcular_Max_Para_Numero_Aleatorio_Especifico(suma_habilidad,indice_progreso,por_cuanto_ecuacion):
	return Calcular_Max_Numero_Aleatorio(Variables_Dinamicas.Progreso[indice_progreso], suma_habilidad, por_cuanto_ecuacion)


func Calcular_Max_Para_Numero_Aleatorio_No_Especifico(suma_habilidad,indice_progreso):
	return Calcular_Max_Para_Numero_Aleatorio_Especifico(suma_habilidad,indice_progreso,5)


# Descubrimiento progresivo: usa la MISMA fórmula que Progreso, pero:
#   - valor_actual = Habilidades_Mostradas[i] (en vez de Progreso[indice])
#   - suma_habilidad = 50 constante (en vez de la combo ponderada de innatas)
# Resultado: al principio descubres rápido, conforme el valor mostrado sube
# se vuelve cada vez más lento (igual que la curva de Progreso).
# El cap es Variables_Estaticas.Habilidades[i] — al alcanzarlo se detiene.
const SUMA_HABILIDAD_DESCUBRIMIENTO: int = 5000
const POR_CUANTO_ECUACION_DESCUBRIMIENTO: int = 5

func Ejecutar_Actividad_Mostrar_Habilidad_Array(efecto_progreso):
	if efecto_progreso[0] != 0:
		_Intentar_Incrementar_Habilidad_Mostrada(0)  # Deporte
		_Intentar_Incrementar_Habilidad_Mostrada(4)  # Liderazgo
		_Intentar_Incrementar_Habilidad_Mostrada(3)  # Memoria
	if efecto_progreso[1] != 0:
		_Intentar_Incrementar_Habilidad_Mostrada(1)  # Inteligencia
		_Intentar_Incrementar_Habilidad_Mostrada(5)  # Paciencia
		_Intentar_Incrementar_Habilidad_Mostrada(3)  # Memoria
	if efecto_progreso[2] != 0:
		_Intentar_Incrementar_Habilidad_Mostrada(2)  # Destreza manual
		_Intentar_Incrementar_Habilidad_Mostrada(5)  # Paciencia
		_Intentar_Incrementar_Habilidad_Mostrada(3)  # Memoria
		_Intentar_Incrementar_Habilidad_Mostrada(4)  # Liderazgo

func _Intentar_Incrementar_Habilidad_Mostrada(indice):
	if Variables_Dinamicas.Habilidades_Mostradas[indice] < Variables_Estaticas.Habilidades[indice]:
		var max_val = Calcular_Max_Numero_Aleatorio(
			Variables_Dinamicas.Habilidades_Mostradas[indice],
			SUMA_HABILIDAD_DESCUBRIMIENTO,
			POR_CUANTO_ECUACION_DESCUBRIMIENTO
		)
		if max_val < 1:
			max_val = 1
		if Funciones_Globales.Generar_Numero_Aleatorio_Entero_Es_Cero(int(max_val)):
			Variables_Dinamicas.Habilidades_Mostradas[indice] += 1
