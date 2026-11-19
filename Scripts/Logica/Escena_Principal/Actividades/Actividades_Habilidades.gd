extends Node



const POR_CUANTO_ECUACION_PROGRESO: int = 20

const NOMBRES_HABILIDADES: Array = [
	"Deporte", "Inteligencia", "Destreza manual", "Memoria", "Liderazgo", "Paciencia", "Sangre fría"
]
const NOMBRES_PROGRESO: Array = ["Deporte", "Académico", "Manualidades"]

func Ejecutar_Actividad_Progreso_Array(efecto_progreso):
	var deporte=Variables_Estaticas.Habilidades[0]
	var inteligencia=Variables_Estaticas.Habilidades[1]
	var destreza_manual=Variables_Estaticas.Habilidades[2]
	var memoria=Variables_Estaticas.Habilidades[3]
	var liderazgo=Variables_Estaticas.Habilidades[4]
	var paciencia=Variables_Estaticas.Habilidades[5]

	for i in range(3):
		if i < efecto_progreso.size() and efecto_progreso[i] > 0:
			while Variables_Dinamicas.Ultimo_Uso_Progreso.size() <= i:
				Variables_Dinamicas.Ultimo_Uso_Progreso.append(-1)
			while Variables_Dinamicas.Ultimo_Check_Decadencia.size() <= i:
				Variables_Dinamicas.Ultimo_Check_Decadencia.append(-1)
			Variables_Dinamicas.Ultimo_Uso_Progreso[i] = Variables_Dinamicas.Minute
			Variables_Dinamicas.Ultimo_Check_Decadencia[i] = Variables_Dinamicas.Minute

	var sum_habilidades_deportivo=(50*deporte+40*liderazgo+10*memoria)
	Ejecutar_Actividad_Progreso(sum_habilidades_deportivo,0,POR_CUANTO_ECUACION_PROGRESO,efecto_progreso[0])

	var sum_habilidades_academico=(50*inteligencia+20*paciencia+30*memoria)
	Ejecutar_Actividad_Progreso(sum_habilidades_academico,1,POR_CUANTO_ECUACION_PROGRESO,efecto_progreso[1])

	var sum_habilidades_manualidades=(50*destreza_manual+30*paciencia+10*memoria+10*liderazgo)
	Ejecutar_Actividad_Progreso(sum_habilidades_manualidades,2,POR_CUANTO_ECUACION_PROGRESO,efecto_progreso[2])
	
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


# Progreso de cocina: fórmula exponencial propia con Destreza (2), Paciencia (5),
# Sangre fría (6) y Memoria (3). El nivel vive en Progreso_Cocina (1..100).
func Calcular_Max_Progreso_Cocina() -> int:
	if Variables_Estaticas.Habilidades.size() < 7:
		return 1
	var destreza: int = int(Variables_Estaticas.Habilidades[2])
	var paciencia: int = int(Variables_Estaticas.Habilidades[5])
	var sangre_fria: int = int(Variables_Estaticas.Habilidades[6])
	var memoria: int = int(Variables_Estaticas.Habilidades[3])
	var suma_habilidad: int = 40 * destreza + 25 * paciencia + 20 * sangre_fria + 15 * memoria
	var maximo: int = Calcular_Max_Numero_Aleatorio(
		Variables_Dinamicas.Progreso_Cocina, suma_habilidad, POR_CUANTO_ECUACION_PROGRESO)
	return maxi(1, maximo)


func Ejecutar_Progreso_Cocina() -> bool:
	if Variables_Dinamicas.Progreso_Cocina >= 100:
		return false
	if Funciones_Globales.Generar_Numero_Aleatorio_Entero_Es_Cero(Calcular_Max_Progreso_Cocina()):
		Variables_Dinamicas.Progreso_Cocina += 1
		return true
	return false


# Descubrimiento de las habilidades innatas que influyen en cocinar.
# Pesos: Destreza 40, Paciencia 25, Sangre fría 20, Memoria 15.
func Ejecutar_Descubrimiento_Cocina() -> void:
	_Intentar_Incrementar_Habilidad_Mostrada(2, 4, 40)
	_Intentar_Incrementar_Habilidad_Mostrada(5, 4, 25)
	_Intentar_Incrementar_Habilidad_Mostrada(6, 4, 20)
	_Intentar_Incrementar_Habilidad_Mostrada(3, 4, 15)


# Descubrimiento progresivo: usa la MISMA fórmula que Progreso, pero:
#   - valor_actual = Habilidades_Mostradas[i] (en vez de Progreso[indice])
#   - suma_habilidad = 5000 constante (en vez de la combo ponderada de innatas)
#   - ecuacion = 10 (Progreso usa 20)
# Sí usa por_cuanto_efecto igual que Progreso: actividades más eficaces
# también revelan más rápido la habilidad.
# El cap es Variables_Estaticas.Habilidades[i] — al alcanzarlo se detiene.
const SUMA_HABILIDAD_DESCUBRIMIENTO: int = 5000
const POR_CUANTO_ECUACION_DESCUBRIMIENTO: int = 8

func Ejecutar_Actividad_Mostrar_Habilidad_Array(efecto_progreso):
	# Los pesos coinciden con los de sum_habilidades_* del cálculo de Progreso.
	# Cada habilidad se descubre con probabilidad proporcional a su peso (%).
	if efecto_progreso[0] != 0:  # Deportivo
		_Intentar_Incrementar_Habilidad_Mostrada(0, efecto_progreso[0], 50)  # Deporte
		_Intentar_Incrementar_Habilidad_Mostrada(4, efecto_progreso[0], 40)  # Liderazgo
		_Intentar_Incrementar_Habilidad_Mostrada(3, efecto_progreso[0], 10)  # Memoria
	if efecto_progreso[1] != 0:  # Academico
		_Intentar_Incrementar_Habilidad_Mostrada(1, efecto_progreso[1], 50)  # Inteligencia
		_Intentar_Incrementar_Habilidad_Mostrada(5, efecto_progreso[1], 20)  # Paciencia
		_Intentar_Incrementar_Habilidad_Mostrada(3, efecto_progreso[1], 30)  # Memoria
	if efecto_progreso[2] != 0:  # Manualidades
		_Intentar_Incrementar_Habilidad_Mostrada(2, efecto_progreso[2], 50)  # Destreza manual
		_Intentar_Incrementar_Habilidad_Mostrada(5, efecto_progreso[2], 30)  # Paciencia
		_Intentar_Incrementar_Habilidad_Mostrada(3, efecto_progreso[2], 10)  # Memoria
		_Intentar_Incrementar_Habilidad_Mostrada(4, efecto_progreso[2], 10)  # Liderazgo

func _Intentar_Incrementar_Habilidad_Mostrada(indice, por_cuanto_efecto, peso_porcentaje):
	if por_cuanto_efecto == 0 or peso_porcentaje == 0:
		return
	if Variables_Dinamicas.Habilidades_Mostradas[indice] < Variables_Estaticas.Habilidades[indice]:
		var max_val = Calcular_Max_Numero_Aleatorio(
			Variables_Dinamicas.Habilidades_Mostradas[indice],
			SUMA_HABILIDAD_DESCUBRIMIENTO,
			POR_CUANTO_ECUACION_DESCUBRIMIENTO
		)
		# prob = (efecto · peso/100) / max_val ⇔ max_ajustado = max_val · 100 / (efecto · peso)
		var max_ajustado = floor(max_val * 100.0 / (por_cuanto_efecto * peso_porcentaje))
		if max_ajustado < 1:
			max_ajustado = 1
		if Funciones_Globales.Generar_Numero_Aleatorio_Entero_Es_Cero(int(max_ajustado)):
			Variables_Dinamicas.Habilidades_Mostradas[indice] += 1
			if Variables_Dinamicas.Habilidades_Mostradas[indice] >= Variables_Estaticas.Habilidades[indice]:
				_Notificar_Limite_Natural(indice)


func _Notificar_Limite_Natural(indice: int) -> void:
	while Variables_Dinamicas.Habilidades_Cap_Notificado.size() <= indice:
		Variables_Dinamicas.Habilidades_Cap_Notificado.append(false)
	if Variables_Dinamicas.Habilidades_Cap_Notificado[indice]:
		return
	Variables_Dinamicas.Habilidades_Cap_Notificado[indice] = true
	var nombre_hab: String = NOMBRES_HABILIDADES[indice] if indice < NOMBRES_HABILIDADES.size() else "Habilidad"
	var limite: int = int(Variables_Estaticas.Habilidades[indice])
	var msg := Mensaje.new()
	msg.titulo = "Límite natural: %s" % nombre_hab
	msg.descripcion = "Has descubierto tu límite natural en %s: %d.\nTu talento innato no dará para más en esta habilidad, aunque puedes seguir subiendo tu Progreso con esfuerzo." % [nombre_hab, limite]
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)


func Comprobar_Decadencia_Progreso() -> void:
	if Variables_Dinamicas.Progreso.size() < 3:
		return
	var escala: float = (1.0 / 7.0) if Variables_Estaticas.Modo_Rapido else 1.0
	var umbral: int = maxi(1, int(round(5 * 1440 * escala)))
	var intervalo: int = maxi(1, int(round(3 * 1440 * escala)))
	var ahora: int = Variables_Dinamicas.Minute
	for i in range(3):
		if i >= Variables_Dinamicas.Ultimo_Uso_Progreso.size():
			break
		var ultimo_uso: int = int(Variables_Dinamicas.Ultimo_Uso_Progreso[i])
		if ultimo_uso < 0:
			continue
		if (ahora - ultimo_uso) < umbral:
			continue
		while Variables_Dinamicas.Ultimo_Check_Decadencia.size() <= i:
			Variables_Dinamicas.Ultimo_Check_Decadencia.append(ultimo_uso + umbral)
		var ultimo_check: int = int(Variables_Dinamicas.Ultimo_Check_Decadencia[i])
		if ultimo_check < ultimo_uso + umbral:
			ultimo_check = ultimo_uso + umbral - intervalo
		if (ahora - ultimo_check) >= intervalo:
			if Variables_Dinamicas.Progreso[i] > 1:
				Variables_Dinamicas.Progreso[i] -= 1
			Variables_Dinamicas.Ultimo_Check_Decadencia[i] = ahora


func Registrar_Pista_Contextual(actividad: Actividad) -> void:
	if actividad == null or actividad.efectos_progreso.size() < 3:
		return
	var ef := actividad.efectos_progreso
	if ef[0] <= 0 and ef[1] <= 0 and ef[2] <= 0:
		return
	if Variables_Estaticas.Habilidades.size() < 6:
		return
	var hab: Array = Variables_Estaticas.Habilidades
	var indice_area := 0
	if ef[1] >= ef[0] and ef[1] >= ef[2]:
		indice_area = 1
	elif ef[2] >= ef[0] and ef[2] >= ef[1]:
		indice_area = 2

	var sum_habilidades: int = 0
	if indice_area == 0:
		sum_habilidades = 50 * hab[0] + 40 * hab[4] + 10 * hab[3]
	elif indice_area == 1:
		sum_habilidades = 50 * hab[1] + 20 * hab[5] + 30 * hab[3]
	else:
		sum_habilidades = 50 * hab[2] + 30 * hab[5] + 10 * hab[3] + 10 * hab[4]

	var area_nombre: String = NOMBRES_PROGRESO[indice_area]
	var texto: String
	if sum_habilidades >= 6500:
		texto = "Lo has bordado (%s): sientes facilidad natural para esta área." % area_nombre
	elif sum_habilidades >= 3500:
		texto = "Bien (%s): progresas a un ritmo constante." % area_nombre
	else:
		texto = "Te ha costado bastante (%s): esta área te exige más esfuerzo." % area_nombre

	if Variables_Dinamicas.Ultimas_Pistas_Progreso.is_empty() or Variables_Dinamicas.Ultimas_Pistas_Progreso[0] != texto:
		Variables_Dinamicas.Ultimas_Pistas_Progreso.push_front(texto)
		if Variables_Dinamicas.Ultimas_Pistas_Progreso.size() > 5:
			Variables_Dinamicas.Ultimas_Pistas_Progreso.resize(5)
