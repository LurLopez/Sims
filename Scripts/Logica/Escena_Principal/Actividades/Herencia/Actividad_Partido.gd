class_name Actividad_Partido
extends Actividad

# Bloque de partido: prioridad máxima (P3) para que ningún trabajo ni
# actividad temporal pueda pisarlo. No se usa para actividades aleatorias.
func Obtener_Prioridad() -> int:
	return 3
