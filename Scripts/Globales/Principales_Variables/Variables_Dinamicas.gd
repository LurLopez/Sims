extends Node
#Variables Principales
var Matriz_Jugador=[]
var Progreso=[]
var Necesidades_Basicas=[]
# Conocimiento descubierto sobre cada habilidad innata (6 ints, 0-100).
# Solo sube. Capped at Variables_Estaticas.Habilidades[i].
# Cuando alcanza el valor innato, se "revela" el cap al jugador.
var Habilidades_Mostradas=[]

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

# Sistema de Objetos/Muebles
# Objetos_Poseidos: Dictionary {clave_objeto: bool} indicando qué objetos del catálogo posee el jugador.
var Objetos_Poseidos: Dictionary = {}
# Objeto_Seleccionado: Dictionary {nombre_actividad: clave_objeto} indicando qué objeto está usando el jugador para cada actividad.
var Objeto_Seleccionado: Dictionary = {}

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

# Sistema de Mensajes/Notificaciones
var Mensajes: Array = []

# Estado de muerte del personaje
var Muerto: bool = false
var Edad_Muerte: int = 0
# Probabilidad de supervivencia acumulada desde el inicio de la partida (producto de (1 - p_minuto)).
# Solo se usa para el log de debug; no afecta a la jugabilidad.
var Prob_Supervivencia_Acumulada: float = 1.0
