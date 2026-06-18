extends Node


func Ejecutar_Actividad_Necesidades_Basicas_Array(efecto_necesidades_basicas, nombre_actividad: String = ""):
	var multiplicador = _Obtener_Multiplicador(nombre_actividad)
	Ejecutar_Actividad_Necesidades_Basicas(efecto_necesidades_basicas[0],0,30,multiplicador)
	Ejecutar_Actividad_Necesidades_Basicas(efecto_necesidades_basicas[1],1,30,multiplicador)
	Ejecutar_Actividad_Necesidades_Basicas(efecto_necesidades_basicas[2],2,12,multiplicador)
	Ejecutar_Actividad_Necesidades_Basicas(efecto_necesidades_basicas[3],3,15,multiplicador)
	Ejecutar_Actividad_Necesidades_Basicas(efecto_necesidades_basicas[4],4,20,multiplicador)


func _Obtener_Multiplicador(nombre_actividad: String) -> float:
	match nombre_actividad:
		"Dormir", "Comer", "Duchar":
			var objeto_clave = Variables_Dinamicas.Objeto_Seleccionado.get(nombre_actividad, "")
			if objeto_clave == "" or not Variables_Estaticas.Catalogo_Objetos.has(objeto_clave):
				return 1.0
			return Variables_Estaticas.Catalogo_Objetos[objeto_clave].multiplicador
		_:
			return 1.0


func Ejecutar_Actividad_Necesidades_Basicas(por_cuanto,indice,frecuencia,multiplicador:float=1.0):
	if (!Funciones_Globales.Es_Cero(por_cuanto)):
		var valor_maximo=floor(frecuencia/Funciones_Globales.Valor_Absoluto(por_cuanto))
		# El multiplicador solo aplica a efectos positivos (mejoras del objeto).
		# Así una cama premium acelera el descanso pero no acelera la caída de otras necesidades.
		if por_cuanto > 0 and multiplicador != 1.0:
			valor_maximo = max(1, floor(valor_maximo / multiplicador))
		if (Funciones_Globales.Generar_Numero_Aleatorio_Entero_Es_Cero(valor_maximo)):
			Cambiar_Necesidades_Basicas(Funciones_Globales.Es_Positivo_Int(por_cuanto),indice)



func Cambiar_Necesidades_Basicas(valor,indice):
	if(valor<0):
		if(Variables_Dinamicas.Necesidades_Basicas[indice] > 1):
			Variables_Dinamicas.Necesidades_Basicas[indice]=Variables_Dinamicas.Necesidades_Basicas[indice]-1
	if (valor>0):
		if (Variables_Dinamicas.Necesidades_Basicas[indice]!=100):
			Variables_Dinamicas.Necesidades_Basicas[indice]=Variables_Dinamicas.Necesidades_Basicas[indice]+1
	# En la calle o en bancarrota: cap máximo a BANCARROTA_MAX_NECESIDAD (20).
	# Si intentas subir por encima, se baja al cap.
	if (Variables_Dinamicas.En_La_Calle or Variables_Dinamicas.Dinero < 0):
		if Variables_Dinamicas.Necesidades_Basicas[indice] > Variables_Estaticas.BANCARROTA_MAX_NECESIDAD:
			Variables_Dinamicas.Necesidades_Basicas[indice] = Variables_Estaticas.BANCARROTA_MAX_NECESIDAD
