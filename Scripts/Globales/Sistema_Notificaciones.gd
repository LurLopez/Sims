extends Node

const DIAS_RECORDATORIO_INACTIVIDAD: int = 2
const ID_RECORDATORIO_INACTIVIDAD: int = 90001

var _plugin: Object = null
var _notificaciones_programadas: Dictionary = {}


func _ready() -> void:
	_Detectar_Plugin()
	if OS.get_name() == "Android":
		_Solicitar_Permiso_Android()
	Reprogramar_Recordatorio_Inactividad()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		Reprogramar_Recordatorio_Inactividad()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		Reprogramar_Recordatorio_Inactividad()


func _Detectar_Plugin() -> void:
	for nombre in ["NotificationScheduler", "LocalNotification", "GodotLocalNotification"]:
		if Engine.has_singleton(nombre):
			_plugin = Engine.get_singleton(nombre)
			break


func _Solicitar_Permiso_Android() -> void:
	if _plugin != null and _plugin.has_method("request_post_notifications_permission"):
		_plugin.call("request_post_notifications_permission")
	elif OS.has_method("request_permission"):
		OS.request_permission("android.permission.POST_NOTIFICATIONS")


func Calcular_Segundos_Hasta_Celda(semana: int, dia: int, hora: int, minuto: int) -> int:
	if Variables_Estaticas.First_Time_Minute <= 0:
		return -1
	var minuto_objetivo_rel: int = (semana * 7 + dia) * 1440 + hora * 60 + minuto
	var minuto_inicio_rel: int = Variables_Estaticas.First_Time_Minute_Day * 1440 + Variables_Estaticas.First_Time_Minute_Minute
	var unix_objetivo: int = (Variables_Estaticas.First_Time_Minute + (minuto_objetivo_rel - minuto_inicio_rel)) * 60
	var ahora_unix: int = int(Time.get_unix_time_from_system())
	return unix_objetivo - ahora_unix


func Programar_Notificacion_Actividad(nombre_actividad: String, semana: int, dia: int, hora: int, minuto: int) -> void:
	if nombre_actividad == "" or nombre_actividad == "Actividad_Aleatoria":
		return
	var delay_seg: int = Calcular_Segundos_Hasta_Celda(semana, dia, hora, minuto)
	if delay_seg <= 60:
		return
	var id_notif: int = _Generar_Id_Actividad(semana, dia, hora, minuto)
	var nombre_legible: String = nombre_actividad.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
	var titulo: String = "Actividad programada"
	var cuerpo: String = "Es hora de: %s" % nombre_legible
	_Programar_Local(id_notif, titulo, cuerpo, delay_seg)


func Cancelar_Notificacion_Actividad(semana: int, dia: int, hora: int, minuto: int) -> void:
	var id_notif: int = _Generar_Id_Actividad(semana, dia, hora, minuto)
	_Cancelar_Local(id_notif)


func Reprogramar_Recordatorio_Inactividad() -> void:
	_Cancelar_Local(ID_RECORDATORIO_INACTIVIDAD)
	var delay_seg: int = DIAS_RECORDATORIO_INACTIVIDAD * 86400
	_Programar_Local(
		ID_RECORDATORIO_INACTIVIDAD,
		"¡Tu personaje te echa de menos!",
		"Llevas %d días sin entrar. Revisa sus necesidades y actividades." % DIAS_RECORDATORIO_INACTIVIDAD,
		delay_seg
	)


func _Generar_Id_Actividad(semana: int, dia: int, hora: int, minuto: int) -> int:
	return 10000 + (semana * 7 + dia) * 1440 + hora * 60 + minuto


func _Programar_Local(id_notif: int, titulo: String, cuerpo: String, delay_segundos: int) -> void:
	_notificaciones_programadas[id_notif] = {
		"titulo": titulo,
		"cuerpo": cuerpo,
		"delay": delay_segundos
	}
	if _plugin == null:
		return
	if _plugin.has_method("schedule"):
		_plugin.call("schedule", id_notif, titulo, cuerpo, delay_segundos)
	elif _plugin.has_method("show"):
		_plugin.call("show", cuerpo, titulo, delay_segundos, id_notif)


func _Cancelar_Local(id_notif: int) -> void:
	_notificaciones_programadas.erase(id_notif)
	if _plugin == null:
		return
	if _plugin.has_method("cancel"):
		_plugin.call("cancel", id_notif)
