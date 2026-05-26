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
var Trabajo=false

var Minute_Day=0
var Minute_Minute=0
var Minute=0
