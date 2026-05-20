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
	


func Calcular_Max_Para_Numero_Aleatorio_Especifico(suma_habilidad,indice_progreso,por_cuanto_ecuacion):
	var potencia1=(30+Variables_Dinamicas.Progreso[indice_progreso])/100.0
	var potencia2=15000/float(5000+suma_habilidad)
	var resultado=floor(por_cuanto_ecuacion*(8**potencia1)**potencia2)
	return resultado


func Calcular_Max_Para_Numero_Aleatorio_No_Especifico(suma_habilidad,indice_progreso):
	return Calcular_Max_Para_Numero_Aleatorio_Especifico(suma_habilidad,indice_progreso,5)
