extends Node
#Variables Principales
var Matriz_Jugador=[]
var Matriz_Sucia: bool = true
var Progreso=[]
var Necesidades_Basicas=[]
# Nivel de destreza culinaria (rango 1..100). Se sube cocinando y no decae.
var Progreso_Cocina: int = 1
# Inventario individualizado de raciones caseras.
# Cada elemento: {id:int, porcentaje_restante:float, calidad:int,
#                 minuto_creacion:int, minuto_caducidad:int}
var Tuppers: Array = []
# Índice del tupper elegido manualmente por el jugador (-1 = automático).
var Tupper_Seleccionado_Idx: int = -1
# Contador volátil de minutos consecutivos cocinados (no se guarda).
var Minutos_Cocinando_Actuales: int = 0
# Conocimiento descubierto sobre cada habilidad innata (6 ints, 0-100).
# Solo sube. Capped at Variables_Estaticas.Habilidades[i].
# Cuando alcanza el valor innato, se "revela" el cap al jugador.
var Habilidades_Mostradas=[]
var Habilidades_Cap_Notificado: Array = [false, false, false, false, false, false, false]

# Decadencia del Progreso y pistas contextuales
# Timestamps en minutos (Variables_Dinamicas.Minute) por área: [Deporte, Académico, Manualidades]
var Ultimo_Uso_Progreso: Array = [-1, -1, -1]
var Ultimo_Check_Decadencia: Array = [-1, -1, -1]
var Ultimas_Pistas_Progreso: Array = []

#Variables Relacionadas con la gestion del dinero
var Dinero=0
# Estado de la vivienda: true si vive en la calle (sin alquiler), false si está alquilando.
var En_La_Calle=false
# Minuto absoluto (Minute_Day*1440 + Minute_Minute) en que se pagó el último alquiler.
# Cuando current_minuto >= Ultima_Fecha_Alquiler + 7*1440 se cobra el siguiente alquiler.
# Valor -1 = sentinel "no aplica" (estás en la calle, no hay timer activo).
var Ultima_Fecha_Alquiler=-1

#Variable relacionada con el trabajo
var Trabajo_Actual: Actividad_Fija_Trabajo = null

# Sistema de Objetos/Muebles y Ropa
# Objetos_Poseidos: Dictionary {clave_objeto: bool} indicando qué objetos del catálogo posee el jugador.
var Objetos_Poseidos: Dictionary = {"Ropa_Calle": true}
# Objeto_Seleccionado: Dictionary {nombre_actividad: clave_objeto} indicando qué objeto está usando el jugador para cada actividad.
var Objeto_Seleccionado: Dictionary = {"Ropa": "Ropa_Calle"}

var Minute_Day=0
var Minute_Minute=0
var Minute=0

# Sistema de Carreras Universitarias
# Carrera_Actual: instancia de Carrera (o null si el personaje no está estudiando ninguna).
var Carrera_Actual: Carrera = null
# Carreras_Completadas: Array de Carrera (histórico de carreras terminadas).
var Carreras_Completadas: Array = []
# Minuto absoluto del inicio de la semana actual de carrera. Se usa para detectar
# el fin de semana y procesar el examen (cada 7*1440 minutos desde matriculación).
var Inicio_Semana_Carrera: int = -1

# Sistema de Carreras Deportivas
var Carrera_Deportiva_Pendiente: Dictionary = {
	"inscrito": false,
	"dia": -1,
	"hora_inicio": -1,
	"semana_inscripcion": -1,
	"total_inscritos": 0,
	"resultado_puesto": -1,
	"resultado_procesado": false
}

# Sistema de Carrera de Futbolista (Fase 1 — Modo Jugador).
# La base se duplica siempre para no compartir referencias entre partidas.
const CARRERA_FUTBOL_BASE: Dictionary = {
	"Activo": false,
	"Division": 4, # 4: 3ª División Regional, 3: 2ª División, 2: 1ª División, 1: Superliga
	"Relacion_Entrenador": 50.0, # [0.0, 100.0]
	"Entrenamientos_Cancelados_Seguidos": 0,
	"Partidos_Jugados": 0,
	"Goles_Totales": 0,
	"Asistencias_Totales": 0,
	"Temporadas_Jugadas": 0,
	"Titulos_Superliga": 0,
	"Salario_Semanal": 150,
	"Estado_Temporada": "En_Curso", # En_Curso, Ascendido, Mantiene, Descendido, Campeon, Despedido
	"Entrenamientos_Asistencia": {
		"Martes": true,
		"Jueves": true,
		"Diario": true # Usado en Modo_Rapido
	},
	# Estado de la mini-liga dominical en Modo Normal (4 equipos, 3 jornadas + playoff)
	"Liga_Domingo": {
		"Jornada_Actual": 0, # 0..3 (0-2 fase regular, 3 playoff); 4 = temporada completada
		"Puntos_Jugador": 0,
		"Puntos_Rivales": [0, 0, 0],
		"Medias_Rivales": [45.0, 45.0, 45.0],
		"Posicion_Regular": 1
	},
	# Estado interno de bloques en curso (se persiste para sobrevivir cierres de app).
	"Entrenamiento_En_Curso": false,
	"Entrenamiento_Fin_Abs": -1,
	"Partido_En_Curso": false,
	"Partido_Jornada": -1,
	"Partido_Convocado": false,
	"Partido_Decisivo": false,
	"Partido_Fin_Abs": -1,
	"Ultimo_Dia_Salario": -1,
	"Conflicto_Ascenso_Pendiente": false,
	"Division_Ascenso_Pendiente": 0
}
var Carrera_Futbol: Dictionary = CARRERA_FUTBOL_BASE.duplicate(true)


func Carrera_Futbol_Por_Defecto() -> Dictionary:
	return CARRERA_FUTBOL_BASE.duplicate(true)

# Sistema «El Mánager» (Fase 2 — Modo Club tipo Top Eleven).
# Ecosistema cerrado de 16 clubes en 4 divisiones; el club del usuario se
# funda en la 3ª Regional. La base se duplica siempre para no compartir
# referencias entre partidas.
const MANAGER_ESTADO_BASE: Dictionary = {
	"Version": 1,
	"Desbloqueado": false,
	"Titulo_Entrenador": false,
	"Retirado_Como_Jugador": false,
	"Activo": false,
	"Reputacion": 25,
	"Club_Usuario_Id": "club_usr",
	"Temporada": 1,
	"Semana_Tick": -1,
	"Dia_Tick": -1,
	"Partido_Pendiente": false,
	"Jornada_Actual": 0,
	"Partido_Local_Id": "",
	"Partido_Visitante_Id": "",
	"Partido_Es_Local": false,
	"Partido_Jornada": 0,
	"Ultima_Jornada_Iniciada": -1,
	"Ultimo_Dia_Nomina": -1,
	"Ultimos_Resultados": [],
	"Clubes": {},
	"Divisiones": {
		"1": [],
		"2": [],
		"3": [],
		"4": []
	},
	"Historial": []
}
var Manager_Estado: Dictionary = MANAGER_ESTADO_BASE.duplicate(true)


func Manager_Estado_Por_Defecto() -> Dictionary:
	return MANAGER_ESTADO_BASE.duplicate(true)

# Sistema de Minijuego de Cocina (gestión de pedidos).
const COCINA_ESTADO_BASE: Dictionary = {
	"restaurantes_desbloqueados": [],
	"fondos_cocina": 0,
	"estrellas_nivel": {},
	"mejoras": {
		"burger_street": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1},
		"bistro_tradicional": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1},
		"cocina_mercado": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1},
		"alta_cocina": {"plancha": 1, "emplatado": 1, "termostato": 1, "ingredientes": 1, "ambiente": 1}
	},
	"rango_logro": 0,
	"servicios_remunerados_hoy": 0,
	"ultimo_dia_remunerado": -1,
	"plus_nomina_turno_hoy": false
}
var Cocina_Estado: Dictionary = COCINA_ESTADO_BASE.duplicate(true)


func Cocina_Estado_Por_Defecto() -> Dictionary:
	return COCINA_ESTADO_BASE.duplicate(true)

# Sistema de Mensajes/Notificaciones
var Mensajes: Array = []

# Sistema de estados temporales (Euforia / Resacon)
# Dictionary {nombre_estado: minutos_restantes}. Los estados duran 1440 min.
var Estados_Temporales: Dictionary = {}
# True si ya ha ocurrido un evento (ligar o resacón) en el bloque de fiesta actual.
# Se resetea en el primer minuto de cada bloque nuevo de Salir_De_Fiesta.
var Fiesta_Evento_Ocurrido: bool = false

# Sistema de Inversiones en Bolsa
var Esta_Invirtiendo: bool = false
var Dinero_Invertido: float = 0.0
var Valor_Inversion: float = 0.0
# Snapshot de salud mental (Necesidades_Basicas[1]) en el momento de invertir.
# Solo importa el valor al inicio, no cambia mientras la inversión sigue activa.
var Salud_Mental_Al_Invertir: int = 50
var Progreso_Inversion: int = 1

# Historial y estadísticas de la bolsa (persistentes).
# Inversion_Historial: [{minuto, beneficio, valor, invertido}]
#   beneficio = ganancias realizadas + variación no realizada de la posición.
var Inversion_Historial: Array = []
# Inversion_Operaciones: [{minuto, tipo, cantidad, beneficio, cerrado, acumulado}]
var Inversion_Operaciones: Array = []
# Inversion_Eventos: [{minuto, titulo, delta_pct, importe, tipo}]
var Inversion_Eventos: Array = []
var Inversion_Tendencia: float = 0.0          # Régimen de mercado [-1, 1]
var Inversion_Ultimo_Evento_Minuto: int = -1
var Inversion_Minuto_Inicio: int = -1
var Inversion_Aportado_Total: float = 0.0
var Inversion_Retirado_Total: float = 0.0
var Inversion_Beneficio_Realizado: float = 0.0
var Inversion_Num_Aportes: int = 0
var Inversion_Num_Retiradas: int = 0
var Inversion_Cierres_Ganadores: int = 0
var Inversion_Cierres_Perdedores: int = 0
var Inversion_Mejor_Operacion: float = 0.0
var Inversion_Peor_Operacion: float = 0.0
var Inversion_Eventos_Subida: int = 0
var Inversion_Eventos_Bajada: int = 0
var Inversion_Panicos: int = 0
var Inversion_Minutos_Activos: int = 0
var Inversion_Racha_Actual: int = 0
var Inversion_Mejor_Racha: int = 0
var Inversion_Peor_Racha: int = 0
var Inversion_Racha_Operaciones: int = 0
var Inversion_Mejor_Racha_Operaciones: int = 0
var Inversion_Pico_Beneficio: float = 0.0
var Inversion_Max_Caida: float = 0.0

# Sistema de Eventos Aleatorios
# Cooldown_Trabajos: Dictionary {nombre_trabajo: minuto_fin_cooldown}
# Cuando te echan de un trabajo, no puedes volver a ese mismo durante 5 días.
var Cooldown_Trabajos: Dictionary = {}

# Estado de muerte del personaje
var Muerto: bool = false
var Edad_Muerte: int = 0
# Rejuvenecimiento comprado en Tienda > Bienestar.
# Rejuvenecimiento_Anios resta años a la edad calculada (suelo de 18 años);
# Tratamientos_Rejuvenecimiento hace subir el precio de las siguientes sesiones.
var Rejuvenecimiento_Anios: int = 0
var Tratamientos_Rejuvenecimiento: int = 0
# Probabilidad de supervivencia acumulada desde el inicio de la partida (producto de (1 - p_minuto)).
# Solo se usa para el log de debug; no afecta a la jugabilidad.
var Prob_Supervivencia_Acumulada: float = 1.0
