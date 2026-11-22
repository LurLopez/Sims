extends Node

# ============================================================================
# SISTEMA DE INVERSIÓN PASIVA (BOLSA)
# ----------------------------------------------------------------------------
# Motor único de la inversión pasiva: aportes, retiradas parciales, eventos de
# mercado, auto-venta por pánico, historial para el gráfico y estadísticas.
#
# La UI vive en `Scripts/GUI/Escena_Principal/Bolsa/Panel_Bolsa.gd`. Este nodo
# no crea controles para poder probarlo en headless con GUT.
# ============================================================================

const PROBABILIDAD_EVENTO := 480             # 1 evento cada ~480 minutos de juego
const MAX_HISTORIAL := 600
const MAX_OPERACIONES := 40
const MAX_EVENTOS := 30
const UMBRAL_PANICO := 0.15                  # -15 % con Sangre Fría < 30
const SANGRE_FRIA_MINIMA := 30
const MAGNITUD_MINIMA := 0.005               # 0,5 %
const MAGNITUD_MAXIMA := 0.030               # 3,0 %
const PROBABILIDAD_SHOCK := 0.06
const MAGNITUD_SHOCK_MINIMA := 0.030         # 3,0 %
const MAGNITUD_SHOCK_MAXIMA := 0.065         # 6,5 %

const TITULARES_ALCISTAS := [
	"Buenos resultados: el mercado cierra en verde",
	"El banco central mantiene los tipos y calma al mercado",
	"Entrada de capital extranjero en la bolsa",
	"Temporada de resultados mejor de lo esperado",
	"Optimismo comprador en el parqué",
	"El empleo resiste y empuja a las acciones",
	"Rebote técnico tras las últimas caídas",
]

const TITULARES_BAJISTAS := [
	"La inflación sorprende y presiona a la baja",
	"Corrección técnica: recogida de beneficios",
	"Turbulencias en el sector energético",
	"Malos resultados trimestrales en la banca",
	"Los inversores optan por la prudencia",
	"Subida de tipos: el mercado descuenta riesgo",
	"Ventas masivas en las tecnológicas",
]

const TITULARES_SHOCK_ALCISTA := [
	"Rally histórico: euforia compradora en el parqué",
	"Acuerdo inesperado: la bolsa se dispara",
	"Los fondos entran en tromba y rompen máximos",
]

const TITULARES_SHOCK_BAJISTA := [
	"Pánico vendedor: el mercado se desploma",
	"Guerra comercial: caída global de las bolsas",
	"Crisis de confianza: los índices se hunden",
]


# ----------------------------------------------------------------------------
# Consultas básicas
# ----------------------------------------------------------------------------

func Esta_Activa() -> bool:
	return bool(Variables_Dinamicas.Esta_Invirtiendo) \
		and float(Variables_Dinamicas.Valor_Inversion) > 0.0


func Minuto_Actual() -> int:
	return int(Variables_Dinamicas.Minute_Day) * 1440 + int(Variables_Dinamicas.Minute_Minute)


func Beneficio_No_Realizado() -> float:
	if not Esta_Activa():
		return 0.0
	return float(Variables_Dinamicas.Valor_Inversion) - float(Variables_Dinamicas.Dinero_Invertido)


func Beneficio_Acumulado() -> float:
	return float(Variables_Dinamicas.Inversion_Beneficio_Realizado) + Beneficio_No_Realizado()


func Porcentaje_Posicion() -> float:
	if not Esta_Activa():
		return 0.0
	var invertido := float(Variables_Dinamicas.Dinero_Invertido)
	if invertido <= 0.0:
		return 0.0
	return Beneficio_No_Realizado() / invertido * 100.0


func Progreso_Nivel() -> int:
	return clampi(int(Variables_Dinamicas.Progreso_Inversion), 1, 100)


func Estado_Mercado() -> Dictionary:
	var tendencia := float(Variables_Dinamicas.Inversion_Tendencia)
	if tendencia >= 0.25:
		return {"texto": "Mercado alcista", "color": "exito", "icono": "trending-up"}
	if tendencia <= -0.25:
		return {"texto": "Mercado bajista", "color": "peligro", "icono": "triangle-alert"}
	return {"texto": "Mercado lateral", "color": "aviso", "icono": "activity"}


func Debe_Auto_Vender() -> bool:
	if not Esta_Activa():
		return false
	var sangre_fria := int(Variables_Estaticas.Habilidades[6])
	if sangre_fria >= SANGRE_FRIA_MINIMA:
		return false
	var invertido := float(Variables_Dinamicas.Dinero_Invertido)
	if invertido <= 0.0:
		return false
	var pct := (float(Variables_Dinamicas.Valor_Inversion) - invertido) / invertido
	return pct < -UMBRAL_PANICO


func Avance_Nivel_Texto() -> String:
	if Progreso_Nivel() >= 100:
		return "Nivel máximo"
	return "Nivel %d/100" % Progreso_Nivel()


func Formatear_Tiempo(minutos: int) -> String:
	var minutos_por_anio := maxi(1, int(Variables_Estaticas.Dias_Por_Anio())) * 1440
	var anios := int(minutos / minutos_por_anio)
	var resto := int(minutos % minutos_por_anio)
	var dias := int(resto / 1440)
	if anios <= 0 and dias <= 0:
		return "Menos de un día"
	if anios <= 0:
		return "%d día%s" % [dias, "" if dias == 1 else "s"]
	if dias <= 0:
		return "%d año%s" % [anios, "" if anios == 1 else "s"]
	return "%d año%s y %d día%s" % [
		anios, "" if anios == 1 else "s", dias, "" if dias == 1 else "s"]


func Hace_Texto(minuto: int) -> String:
	var diferencia := maxi(0, Minuto_Actual() - int(minuto))
	if diferencia < 60:
		return "Ahora mismo"
	if diferencia < 1440:
		var horas := int(diferencia / 60)
		return "Hace %d h" % horas
	var dias := int(diferencia / 1440)
	if dias < int(Variables_Estaticas.Dias_Por_Anio()):
		return "Hace %d día%s" % [dias, "" if dias == 1 else "s"]
	var anios := int(diferencia / (maxi(1, int(Variables_Estaticas.Dias_Por_Anio())) * 1440))
	return "Hace %d año%s" % [anios, "" if anios == 1 else "s"]


# ----------------------------------------------------------------------------
# Operaciones del jugador
# ----------------------------------------------------------------------------

func Invertir(cantidad: float, minuto: int = -1) -> Dictionary:
	if minuto < 0:
		minuto = Minuto_Actual()
	cantidad = _Redondear_Centimos(cantidad)
	if cantidad <= 0.0:
		return {"ok": false, "mensaje": "Introduce una cantidad mayor que 0 €."}
	if cantidad > float(Variables_Dinamicas.Dinero) + 0.001:
		return {"ok": false, "mensaje": "No tienes suficiente efectivo."}

	var era_nueva := not Esta_Activa()
	if era_nueva:
		Variables_Dinamicas.Dinero_Invertido = 0.0
		Variables_Dinamicas.Valor_Inversion = 0.0
		Variables_Dinamicas.Salud_Mental_Al_Invertir = int(Variables_Dinamicas.Necesidades_Basicas[1])
		Variables_Dinamicas.Inversion_Minuto_Inicio = minuto

	Variables_Dinamicas.Dinero -= cantidad
	Variables_Dinamicas.Dinero_Invertido = maxf(0.0, float(Variables_Dinamicas.Dinero_Invertido) + cantidad)
	Variables_Dinamicas.Valor_Inversion = maxf(0.0, float(Variables_Dinamicas.Valor_Inversion) + cantidad)
	Variables_Dinamicas.Esta_Invirtiendo = true
	Variables_Dinamicas.Inversion_Aportado_Total += cantidad
	Variables_Dinamicas.Inversion_Num_Aportes += 1

	_Registrar_Operacion("aporte", cantidad, 0.0, minuto, false)
	_Registrar_Punto_Historial(minuto)
	_Actualizar_Pico_Y_Caida()
	return {
		"ok": true,
		"mensaje": "Inversión realizada.",
		"nueva": era_nueva,
	}


func Retirar(cantidad: float, motivo: String = "manual", minuto: int = -1) -> Dictionary:
	if minuto < 0:
		minuto = Minuto_Actual()
	cantidad = _Redondear_Centimos(cantidad)
	if not Esta_Activa():
		return {"ok": false, "mensaje": "No hay ninguna inversión activa."}
	if cantidad <= 0.0:
		return {"ok": false, "mensaje": "Introduce una cantidad mayor que 0 €."}

	var valor := float(Variables_Dinamicas.Valor_Inversion)
	var es_total := cantidad >= valor - 0.01
	if es_total:
		cantidad = valor
	if cantidad > valor + 0.001:
		return {"ok": false, "mensaje": "No puedes retirar más de lo que vale tu cartera."}

	var fraccion := cantidad / valor if valor > 0.0 else 1.0
	var coste_liberado := float(Variables_Dinamicas.Dinero_Invertido) * fraccion
	var beneficio := cantidad - coste_liberado

	Variables_Dinamicas.Dinero += cantidad
	Variables_Dinamicas.Valor_Inversion = maxf(0.0, valor - cantidad)
	Variables_Dinamicas.Dinero_Invertido = maxf(0.0, float(Variables_Dinamicas.Dinero_Invertido) - coste_liberado)
	Variables_Dinamicas.Inversion_Retirado_Total += cantidad
	Variables_Dinamicas.Inversion_Beneficio_Realizado += beneficio
	Variables_Dinamicas.Inversion_Num_Retiradas += 1

	if beneficio > 0.01:
		Variables_Dinamicas.Inversion_Cierres_Ganadores += 1
		Variables_Dinamicas.Inversion_Mejor_Operacion = maxf(
			float(Variables_Dinamicas.Inversion_Mejor_Operacion), beneficio)
		Variables_Dinamicas.Inversion_Racha_Operaciones += 1
		Variables_Dinamicas.Inversion_Mejor_Racha_Operaciones = maxi(
			int(Variables_Dinamicas.Inversion_Mejor_Racha_Operaciones),
			int(Variables_Dinamicas.Inversion_Racha_Operaciones))
	elif beneficio < -0.01:
		Variables_Dinamicas.Inversion_Cierres_Perdedores += 1
		Variables_Dinamicas.Inversion_Peor_Operacion = minf(
			float(Variables_Dinamicas.Inversion_Peor_Operacion), beneficio)
		Variables_Dinamicas.Inversion_Racha_Operaciones = 0
	else:
		Variables_Dinamicas.Inversion_Racha_Operaciones = 0

	if es_total:
		Variables_Dinamicas.Esta_Invirtiendo = false
		Variables_Dinamicas.Valor_Inversion = 0.0
		Variables_Dinamicas.Dinero_Invertido = 0.0
		# Cerrar una posición en positivo enseña: pequeño empujón de progreso.
		if beneficio > 0.01 and Progreso_Nivel() < 100:
			Variables_Dinamicas.Progreso_Inversion = Progreso_Nivel() + 1

	var tipo := "retirada" if motivo == "manual" else "auto_venta"
	_Registrar_Operacion(tipo, cantidad, beneficio, minuto, es_total)
	_Registrar_Punto_Historial(minuto)
	_Actualizar_Pico_Y_Caida()
	return {
		"ok": true,
		"cerrado": es_total,
		"beneficio": beneficio,
		"cantidad": cantidad,
	}


func Retirar_Todo(motivo: String = "manual", minuto: int = -1) -> Dictionary:
	if not Esta_Activa():
		return {"ok": false, "mensaje": "No hay ninguna inversión activa."}
	return Retirar(float(Variables_Dinamicas.Valor_Inversion), motivo, minuto)


func Auto_Vender_Por_Panico(minuto: int = -1) -> Dictionary:
	if minuto < 0:
		minuto = Minuto_Actual()
	var invertido := float(Variables_Dinamicas.Dinero_Invertido)
	var valor_actual := float(Variables_Dinamicas.Valor_Inversion)
	var pct_perdida := 0.0
	if invertido > 0.0:
		pct_perdida = (invertido - valor_actual) / invertido * 100.0

	var resultado := Retirar_Todo("auto_venta", minuto)
	if not bool(resultado.get("ok", false)):
		return resultado

	Variables_Dinamicas.Inversion_Panicos += 1

	var msg = Mensaje.new()
	msg.titulo = "Inversión retirada automáticamente"
	msg.descripcion = "Tu sangre fría es baja. Al alcanzar un %.0f%% de pérdidas has entrado en pánico y has retirado la inversión (%.0f€ recuperados)." % [pct_perdida, valor_actual]
	msg.leido = false
	msg.minuto = int(Variables_Dinamicas.Minute)
	Variables_Dinamicas.Mensajes.append(msg)
	return resultado


# ----------------------------------------------------------------------------
# Motor de mercado
# ----------------------------------------------------------------------------

func Procesar_Minuto(minuto: int = -1) -> bool:
	if not Esta_Activa():
		return false
	if minuto < 0:
		minuto = Minuto_Actual()
	Variables_Dinamicas.Inversion_Minutos_Activos += 1
	if randi() % PROBABILIDAD_EVENTO != 0:
		return false
	return Generar_Evento(minuto)


func Generar_Evento(minuto: int = -1) -> bool:
	if not Esta_Activa():
		return false
	if minuto < 0:
		minuto = Minuto_Actual()

	var progreso := Progreso_Nivel()
	var mental := int(Variables_Dinamicas.Salud_Mental_Al_Invertir)
	var tendencia_actual := _Actualizar_Tendencia_Mercado()

	# La tendencia de mercado añade un pequeño sesgo, nunca decide sola.
	var tendencia_habilidad := (progreso - 1.0) / 99.0
	var factor_mental := (mental - 50.0) / 300.0
	var prob_subida := clampf(
		0.15 + tendencia_habilidad * 0.70 + factor_mental + tendencia_actual * 0.05,
		0.05, 0.95)
	var sube := randf() < prob_subida
	var shock := randf() < PROBABILIDAD_SHOCK
	var magnitud := 0.0
	if shock:
		magnitud = randf_range(MAGNITUD_SHOCK_MINIMA, MAGNITUD_SHOCK_MAXIMA)
	else:
		magnitud = randf_range(MAGNITUD_MINIMA, MAGNITUD_MAXIMA)
	var delta := magnitud if sube else -magnitud
	var titular := _Elegir_Titular(sube, shock)
	var tipo := "shock" if shock else "normal"
	return Realizar_Evento(minuto, delta, titular, tipo)


func Realizar_Evento(minuto: int, delta: float, titular: String, tipo: String = "normal") -> bool:
	if not Esta_Activa():
		return false
	var valor_anterior := float(Variables_Dinamicas.Valor_Inversion)
	var valor_nuevo := maxf(0.01, valor_anterior * (1.0 + delta))
	Variables_Dinamicas.Valor_Inversion = valor_nuevo
	var importe := valor_nuevo - valor_anterior

	if delta >= 0.0:
		Variables_Dinamicas.Inversion_Eventos_Subida += 1
		Variables_Dinamicas.Inversion_Racha_Actual = maxi(1, int(Variables_Dinamicas.Inversion_Racha_Actual) + 1)
		Variables_Dinamicas.Inversion_Mejor_Racha = maxi(
			int(Variables_Dinamicas.Inversion_Mejor_Racha),
			int(Variables_Dinamicas.Inversion_Racha_Actual))
	else:
		Variables_Dinamicas.Inversion_Eventos_Bajada += 1
		Variables_Dinamicas.Inversion_Racha_Actual = mini(-1, int(Variables_Dinamicas.Inversion_Racha_Actual) - 1)
		Variables_Dinamicas.Inversion_Peor_Racha = mini(
			int(Variables_Dinamicas.Inversion_Peor_Racha),
			int(Variables_Dinamicas.Inversion_Racha_Actual))

	Variables_Dinamicas.Inversion_Ultimo_Evento_Minuto = minuto
	var evento := {
		"minuto": minuto,
		"titulo": titular,
		"delta_pct": delta * 100.0,
		"importe": importe,
		"tipo": tipo,
	}
	_Anadir_Con_Cap(Variables_Dinamicas.Inversion_Eventos, evento, MAX_EVENTOS)

	# Aprender invirtiendo: misma probabilidad que el sistema original.
	if Progreso_Nivel() < 100 and randi() % 20 == 0:
		Variables_Dinamicas.Progreso_Inversion = Progreso_Nivel() + 1

	_Actualizar_Pico_Y_Caida()

	if Debe_Auto_Vender():
		Auto_Vender_Por_Panico(minuto)
		return true

	_Registrar_Punto_Historial(minuto)
	_Actualizar_Pico_Y_Caida()
	return true


func _Actualizar_Tendencia_Mercado() -> float:
	# Paseo aleatorio con reversión suave: el mercado tiene ciclos, pero no
	# arrastra la rentabilidad hasta el infinito.
	var tendencia := float(Variables_Dinamicas.Inversion_Tendencia)
	tendencia = tendencia * 0.90 + randfn(0.0, 0.20)
	tendencia = clampf(tendencia, -1.0, 1.0)
	Variables_Dinamicas.Inversion_Tendencia = tendencia
	return tendencia


func _Elegir_Titular(sube: bool, shock: bool) -> String:
	var lista: Array
	if shock:
		lista = TITULARES_SHOCK_ALCISTA if sube else TITULARES_SHOCK_BAJISTA
	else:
		lista = TITULARES_ALCISTAS if sube else TITULARES_BAJISTAS
	return str(lista[randi() % lista.size()])


# ----------------------------------------------------------------------------
# Historial y estadísticas
# ----------------------------------------------------------------------------

func Registrar_Punto_Actual() -> void:
	_Registrar_Punto_Historial(Minuto_Actual())


func Obtener_Historial(desde_minuto: int = -1, hasta_minuto: int = -1) -> Array:
	var origen: Array = Variables_Dinamicas.Inversion_Historial
	if origen.is_empty():
		return []
	if hasta_minuto < 0:
		hasta_minuto = Minuto_Actual()
	var resultado: Array = []
	var punto_anterior: Dictionary = {}
	for p in origen:
		if not (p is Dictionary):
			continue
		var m := int(p.get("minuto", 0))
		if m <= desde_minuto:
			punto_anterior = p
			continue
		if m > hasta_minuto:
			break
		if resultado.is_empty() and not punto_anterior.is_empty() and desde_minuto >= 0:
			resultado.append(punto_anterior.duplicate(true))
		resultado.append(p.duplicate(true))
	if resultado.is_empty() and not origen.is_empty():
		resultado.append(origen[-1].duplicate(true))
	return resultado


func Obtener_Estadisticas() -> Dictionary:
	var activa := Esta_Activa()
	var valor := float(Variables_Dinamicas.Valor_Inversion) if activa else 0.0
	var coste := float(Variables_Dinamicas.Dinero_Invertido) if activa else 0.0
	var no_realizado := valor - coste if activa else 0.0
	var beneficio_total := float(Variables_Dinamicas.Inversion_Beneficio_Realizado) + no_realizado
	var aportado := float(Variables_Dinamicas.Inversion_Aportado_Total)
	var retirado := float(Variables_Dinamicas.Inversion_Retirado_Total)
	var rentabilidad := (beneficio_total / aportado * 100.0) if aportado > 0.0 else 0.0
	var ganadoras := int(Variables_Dinamicas.Inversion_Cierres_Ganadores)
	var perdedoras := int(Variables_Dinamicas.Inversion_Cierres_Perdedores)
	var decisiones := ganadoras + perdedoras
	var acierto := (float(ganadoras) / float(decisiones) * 100.0) if decisiones > 0 else 0.0
	var eventos := int(Variables_Dinamicas.Inversion_Eventos_Subida) \
		+ int(Variables_Dinamicas.Inversion_Eventos_Bajada)
	var subidas := int(Variables_Dinamicas.Inversion_Eventos_Subida)

	return {
		"activa": activa,
		"valor": valor,
		"invertido": coste,
		"beneficio_no_realizado": no_realizado,
		"beneficio_realizado": float(Variables_Dinamicas.Inversion_Beneficio_Realizado),
		"beneficio_total": beneficio_total,
		"aportado_total": aportado,
		"retirado_total": retirado,
		"rentabilidad": rentabilidad,
		"num_aportes": int(Variables_Dinamicas.Inversion_Num_Aportes),
		"num_retiradas": int(Variables_Dinamicas.Inversion_Num_Retiradas),
		"operaciones": int(Variables_Dinamicas.Inversion_Num_Aportes) + int(Variables_Dinamicas.Inversion_Num_Retiradas),
		"ganadoras": ganadoras,
		"perdedoras": perdedoras,
		"acierto": acierto,
		"mejor_operacion": float(Variables_Dinamicas.Inversion_Mejor_Operacion),
		"peor_operacion": float(Variables_Dinamicas.Inversion_Peor_Operacion),
		"eventos": eventos,
		"subidas": subidas,
		"bajadas": int(Variables_Dinamicas.Inversion_Eventos_Bajada),
		"tasa_subida": (float(subidas) / float(eventos) * 100.0) if eventos > 0 else 0.0,
		"racha_actual": int(Variables_Dinamicas.Inversion_Racha_Actual),
		"mejor_racha": int(Variables_Dinamicas.Inversion_Mejor_Racha),
		"peor_racha": int(Variables_Dinamicas.Inversion_Peor_Racha),
		"racha_operaciones": int(Variables_Dinamicas.Inversion_Racha_Operaciones),
		"mejor_racha_operaciones": int(Variables_Dinamicas.Inversion_Mejor_Racha_Operaciones),
		"max_caida": float(Variables_Dinamicas.Inversion_Max_Caida),
		"panicos": int(Variables_Dinamicas.Inversion_Panicos),
		"minutos_activos": int(Variables_Dinamicas.Inversion_Minutos_Activos),
		"nivel": Progreso_Nivel(),
		"tendencia": float(Variables_Dinamicas.Inversion_Tendencia),
	}


func Obtener_Eventos() -> Array:
	return Variables_Dinamicas.Inversion_Eventos.duplicate(true)


func Obtener_Operaciones() -> Array:
	return Variables_Dinamicas.Inversion_Operaciones.duplicate(true)


# ----------------------------------------------------------------------------
# Persistencia / compatibilidad
# ----------------------------------------------------------------------------

func Reiniciar_Estado() -> void:
	Variables_Dinamicas.Inversion_Historial = []
	Variables_Dinamicas.Inversion_Operaciones = []
	Variables_Dinamicas.Inversion_Eventos = []
	Variables_Dinamicas.Inversion_Tendencia = 0.0
	Variables_Dinamicas.Inversion_Ultimo_Evento_Minuto = -1
	Variables_Dinamicas.Inversion_Minuto_Inicio = -1
	Variables_Dinamicas.Inversion_Aportado_Total = 0.0
	Variables_Dinamicas.Inversion_Retirado_Total = 0.0
	Variables_Dinamicas.Inversion_Beneficio_Realizado = 0.0
	Variables_Dinamicas.Inversion_Num_Aportes = 0
	Variables_Dinamicas.Inversion_Num_Retiradas = 0
	Variables_Dinamicas.Inversion_Cierres_Ganadores = 0
	Variables_Dinamicas.Inversion_Cierres_Perdedores = 0
	Variables_Dinamicas.Inversion_Mejor_Operacion = 0.0
	Variables_Dinamicas.Inversion_Peor_Operacion = 0.0
	Variables_Dinamicas.Inversion_Eventos_Subida = 0
	Variables_Dinamicas.Inversion_Eventos_Bajada = 0
	Variables_Dinamicas.Inversion_Panicos = 0
	Variables_Dinamicas.Inversion_Minutos_Activos = 0
	Variables_Dinamicas.Inversion_Racha_Actual = 0
	Variables_Dinamicas.Inversion_Mejor_Racha = 0
	Variables_Dinamicas.Inversion_Peor_Racha = 0
	Variables_Dinamicas.Inversion_Racha_Operaciones = 0
	Variables_Dinamicas.Inversion_Mejor_Racha_Operaciones = 0
	Variables_Dinamicas.Inversion_Pico_Beneficio = 0.0
	Variables_Dinamicas.Inversion_Max_Caida = 0.0


# Se llama después de cargar un guardado. Sanea tipos, recorta arrays y
# siembra el historial cuando la partida viene de una versión anterior.
func Asegurar_Estado() -> void:
	Variables_Dinamicas.Progreso_Inversion = Progreso_Nivel()
	Variables_Dinamicas.Inversion_Tendencia = clampf(
		float(Variables_Dinamicas.Inversion_Tendencia), -1.0, 1.0)
	Variables_Dinamicas.Inversion_Aportado_Total = maxf(0.0, float(Variables_Dinamicas.Inversion_Aportado_Total))
	Variables_Dinamicas.Inversion_Retirado_Total = maxf(0.0, float(Variables_Dinamicas.Inversion_Retirado_Total))
	Variables_Dinamicas.Inversion_Beneficio_Realizado = float(Variables_Dinamicas.Inversion_Beneficio_Realizado)
	Variables_Dinamicas.Inversion_Num_Aportes = maxi(0, int(Variables_Dinamicas.Inversion_Num_Aportes))
	Variables_Dinamicas.Inversion_Num_Retiradas = maxi(0, int(Variables_Dinamicas.Inversion_Num_Retiradas))
	Variables_Dinamicas.Inversion_Cierres_Ganadores = maxi(0, int(Variables_Dinamicas.Inversion_Cierres_Ganadores))
	Variables_Dinamicas.Inversion_Cierres_Perdedores = maxi(0, int(Variables_Dinamicas.Inversion_Cierres_Perdedores))
	Variables_Dinamicas.Inversion_Eventos_Subida = maxi(0, int(Variables_Dinamicas.Inversion_Eventos_Subida))
	Variables_Dinamicas.Inversion_Eventos_Bajada = maxi(0, int(Variables_Dinamicas.Inversion_Eventos_Bajada))
	Variables_Dinamicas.Inversion_Panicos = maxi(0, int(Variables_Dinamicas.Inversion_Panicos))
	Variables_Dinamicas.Inversion_Minutos_Activos = maxi(0, int(Variables_Dinamicas.Inversion_Minutos_Activos))
	Variables_Dinamicas.Inversion_Pico_Beneficio = float(Variables_Dinamicas.Inversion_Pico_Beneficio)
	Variables_Dinamicas.Inversion_Max_Caida = maxf(0.0, float(Variables_Dinamicas.Inversion_Max_Caida))

	Variables_Dinamicas.Inversion_Historial = _Sanear_Historial(Variables_Dinamicas.Inversion_Historial)
	Variables_Dinamicas.Inversion_Operaciones = _Sanear_Operaciones(Variables_Dinamicas.Inversion_Operaciones)
	Variables_Dinamicas.Inversion_Eventos = _Sanear_Eventos(Variables_Dinamicas.Inversion_Eventos)

	if float(Variables_Dinamicas.Dinero_Invertido) < 0.0:
		Variables_Dinamicas.Dinero_Invertido = 0.0
	if float(Variables_Dinamicas.Valor_Inversion) < 0.0:
		Variables_Dinamicas.Valor_Inversion = 0.0
	if Variables_Dinamicas.Esta_Invirtiendo and float(Variables_Dinamicas.Valor_Inversion) <= 0.0:
		Variables_Dinamicas.Esta_Invirtiendo = false
		Variables_Dinamicas.Dinero_Invertido = 0.0
	if not Variables_Dinamicas.Esta_Invirtiendo:
		Variables_Dinamicas.Valor_Inversion = 0.0
		Variables_Dinamicas.Dinero_Invertido = 0.0

	# Saves anteriores al historial: reconstruimos lo mínimo para que el
	# gráfico y la rentabilidad no aparezcan a cero.
	if Variables_Dinamicas.Inversion_Aportado_Total <= 0.0 \
			and Variables_Dinamicas.Esta_Invirtiendo:
		Variables_Dinamicas.Inversion_Aportado_Total = float(Variables_Dinamicas.Dinero_Invertido)
	if Variables_Dinamicas.Inversion_Minuto_Inicio < 0 \
			and Variables_Dinamicas.Esta_Invirtiendo:
		Variables_Dinamicas.Inversion_Minuto_Inicio = Minuto_Actual()
	if Variables_Dinamicas.Inversion_Historial.is_empty() \
			and (Variables_Dinamicas.Esta_Invirtiendo or absf(Beneficio_Acumulado()) > 0.01):
		_Registrar_Punto_Historial(Minuto_Actual())

	_Actualizar_Pico_Y_Caida()


# ----------------------------------------------------------------------------
# Internos
# ----------------------------------------------------------------------------

func _Registrar_Punto_Historial(minuto: int) -> void:
	var punto := {
		"minuto": int(minuto),
		"beneficio": Beneficio_Acumulado(),
		"valor": float(Variables_Dinamicas.Valor_Inversion) if Esta_Activa() else 0.0,
		"invertido": float(Variables_Dinamicas.Dinero_Invertido) if Esta_Activa() else 0.0,
	}
	var historial: Array = Variables_Dinamicas.Inversion_Historial
	if not historial.is_empty():
		var ultimo = historial[-1]
		if ultimo is Dictionary and int(ultimo.get("minuto", -1)) == int(minuto):
			historial[-1] = punto
			return
	historial.append(punto)
	if historial.size() > MAX_HISTORIAL:
		_Compactar_Historial(historial)
	Variables_Dinamicas.Inversion_Historial = historial


func _Compactar_Historial(historial: Array) -> void:
	# Reduce la resolución a la mitad conservando primero y último para no
	# perder la forma de la curva en partidas muy largas.
	var compactado: Array = []
	var total := historial.size()
	for i in range(total):
		if i == 0 or i == total - 1 or i % 2 == 0:
			compactado.append(historial[i])
	historial.clear()
	historial.append_array(compactado)


func _Registrar_Operacion(tipo: String, cantidad: float, beneficio: float,
		minuto: int, cerrado: bool) -> void:
	var op := {
		"minuto": int(minuto),
		"tipo": tipo,
		"cantidad": cantidad,
		"beneficio": beneficio,
		"cerrado": cerrado,
		"acumulado": Beneficio_Acumulado(),
	}
	_Anadir_Con_Cap(Variables_Dinamicas.Inversion_Operaciones, op, MAX_OPERACIONES)


func _Anadir_Con_Cap(lista: Array, elemento: Dictionary, maximo: int) -> void:
	lista.append(elemento)
	while lista.size() > maximo:
		lista.pop_front()


func _Actualizar_Pico_Y_Caida() -> void:
	var beneficio := Beneficio_Acumulado()
	Variables_Dinamicas.Inversion_Pico_Beneficio = maxf(
		float(Variables_Dinamicas.Inversion_Pico_Beneficio), beneficio)
	var caida := float(Variables_Dinamicas.Inversion_Pico_Beneficio) - beneficio
	Variables_Dinamicas.Inversion_Max_Caida = maxf(
		float(Variables_Dinamicas.Inversion_Max_Caida), maxf(0.0, caida))


func _Redondear_Centimos(valor: float) -> float:
	return snappedf(maxf(0.0, valor), 0.01)


func _Sanear_Historial(crudo) -> Array:
	var resultado: Array = []
	if not (crudo is Array):
		return resultado
	for p in crudo:
		if not (p is Dictionary):
			continue
		var minuto := int(p.get("minuto", 0))
		var beneficio := float(p.get("beneficio", 0.0))
		var valor := maxf(0.0, float(p.get("valor", 0.0)))
		var invertido := maxf(0.0, float(p.get("invertido", 0.0)))
		resultado.append({
			"minuto": minuto,
			"beneficio": beneficio,
			"valor": valor,
			"invertido": invertido,
		})
	resultado.sort_custom(func(a, b): return int(a["minuto"]) < int(b["minuto"]))
	while resultado.size() > MAX_HISTORIAL:
		_Compactar_Historial(resultado)
	return resultado


func _Sanear_Operaciones(crudo) -> Array:
	var resultado: Array = []
	if not (crudo is Array):
		return resultado
	for o in crudo:
		if not (o is Dictionary):
			continue
		var tipo := str(o.get("tipo", "aporte"))
		if tipo not in ["aporte", "retirada", "auto_venta"]:
			tipo = "aporte"
		resultado.append({
			"minuto": int(o.get("minuto", 0)),
			"tipo": tipo,
			"cantidad": float(o.get("cantidad", 0.0)),
			"beneficio": float(o.get("beneficio", 0.0)),
			"cerrado": bool(o.get("cerrado", false)),
			"acumulado": float(o.get("acumulado", 0.0)),
		})
	while resultado.size() > MAX_OPERACIONES:
		resultado.pop_front()
	return resultado


func _Sanear_Eventos(crudo) -> Array:
	var resultado: Array = []
	if not (crudo is Array):
		return resultado
	for e in crudo:
		if not (e is Dictionary):
			continue
		resultado.append({
			"minuto": int(e.get("minuto", 0)),
			"titulo": str(e.get("titulo", "Movimiento del mercado")),
			"delta_pct": float(e.get("delta_pct", 0.0)),
			"importe": float(e.get("importe", 0.0)),
			"tipo": str(e.get("tipo", "normal")),
		})
	while resultado.size() > MAX_EVENTOS:
		resultado.pop_front()
	return resultado
