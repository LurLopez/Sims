class_name Carrera
extends Resource

@export var nombre: String = ""
@export var años_totales: int = 4
@export var costo_matricula_anual: float = 500.0

@export var año_actual: int = 1
@export var progreso_actual: float = 0.0
@export var historial_notas: Array = []
@export var num_intentos: int = 0
@export var dinero_matricula_gastado: float = 0.0
@export var examen_realizado_esta_semana: bool = false
@export var nota_real_ultima: int = 0
@export var libros_desbloqueados: Array = []
@export var completada: bool = false

# Horario del examen (elegido al matricularse)
@export var hora_examen_dia: int = -1  # 0-6 (Lunes a Domingo), -1 = sin definir
@export var hora_examen_inicio: int = 0  # minutos desde medianoche (ej: 15*60 = 900 para las 3 PM)

# Control para procesar fin de semana solo una vez
@export var fin_de_semana_procesado: bool = false

# Última nota final calculada (para mostrar en la UI)
@export var ultima_nota_final: float = 0.0
@export var ultimo_resultado_aprobado: bool = false
