extends Node

var horario: SeleccionarHorarioReloj
var horariobloque: HorarioDesdeBloque

var _ultimo_ini_abs: int = -1
var _ultimo_fin_abs: int = -1
var _raiz_ref: Node = null


func Comprobar_Visibilidad(raiz, horarioblquee):
	_raiz_ref = raiz
	if horario == null or not is_instance_valid(horario):
		horario = SeleccionarHorarioReloj.new()
	horario.inicializar(raiz)

	var es_nuevo_bloque: bool = (horariobloque != horarioblquee)
	horariobloque = horarioblquee

	var min_abs: int = _Min_Bloque_Abs()
	var max_abs: int = _Max_Bloque_Abs()

	if es_nuevo_bloque or Comprobar_Negativos():
		_Aplicar_Abs_A_Horario(min_abs, max_abs)
	else:
		var ini_abs: int = _Leer_Inicio_Abs()
		var fin_abs: int = _Leer_Final_Abs()

		var ini_cambio: bool = (ini_abs != _ultimo_ini_abs)
		var fin_cambio: bool = (fin_abs != _ultimo_fin_abs)

		ini_abs = clampi(ini_abs, min_abs, max_abs - 5)
		fin_abs = clampi(fin_abs, min_abs + 5, max_abs)

		if ini_abs + 5 > fin_abs:
			if fin_cambio and not ini_cambio:
				fin_abs = clampi(ini_abs + 5, min_abs + 5, max_abs)
				if ini_abs + 5 > fin_abs:
					ini_abs = clampi(fin_abs - 5, min_abs, max_abs - 5)
			else:
				ini_abs = clampi(fin_abs - 5, min_abs, max_abs - 5)
				if ini_abs + 5 > fin_abs:
					fin_abs = clampi(ini_abs + 5, min_abs + 5, max_abs)

		_Aplicar_Abs_A_Horario(ini_abs, fin_abs)

	var ini_actual: int = _Leer_Inicio_Abs()
	var fin_actual: int = _Leer_Final_Abs()
	_ultimo_ini_abs = ini_actual
	_ultimo_fin_abs = fin_actual

	_Actualizar_Visibilidad_Botones(min_abs, max_abs, ini_actual, fin_actual)
	horario.Actualizar_Todo_Contexto()
	_Actualizar_Resumen_UI(raiz, min_abs, max_abs, ini_actual, fin_actual)


func _Min_Bloque_Abs() -> int:
	if horariobloque == null:
		return 0
	var d: int = clampi(horariobloque.dia_inicio_int(), 0, 6)
	var h: int = clampi(int(horariobloque.hora_inicio), 0, 23)
	var m: int = clampi(int(horariobloque.minuto_inicio), 0, 55)
	return d * 1440 + h * 60 + m


func _Max_Bloque_Abs() -> int:
	if horariobloque == null:
		return 10080
	var d: int = clampi(horariobloque.dia_final_int(), 0, 6)
	var h: int = clampi(int(horariobloque.hora_final), 0, 24)
	var m: int = 0 if h == 24 else clampi(int(horariobloque.minuto_final), 0, 55)
	return maxi(_Min_Bloque_Abs() + 5, mini(10080, d * 1440 + h * 60 + m))


func _Leer_Inicio_Abs() -> int:
	var d: int = horario.dia_inicio_a_int()
	if d < 0:
		return -1
	var h: int = horario.hora_inicio_texto.text.to_int()
	var m: int = horario.minuto_inicio_texto.text.to_int()
	return d * 1440 + h * 60 + m


func _Leer_Final_Abs() -> int:
	var d: int = horario.dia_final_a_int()
	if d < 0:
		return -1
	var h: int = horario.hora_final_texto.text.to_int()
	var m: int = horario.minuto_final_texto.text.to_int()
	return d * 1440 + h * 60 + m


func _Aplicar_Abs_A_Horario(ini_abs: int, fin_abs: int) -> void:
	ini_abs = clampi(ini_abs, 0, 10075)
	fin_abs = clampi(fin_abs, 5, 10080)

	var d_ini: int = clampi(int(ini_abs / 1440), 0, 6)
	var rem_ini: int = ini_abs - d_ini * 1440
	var h_ini: int = int(rem_ini / 60)
	var m_ini: int = rem_ini % 60

	var d_fin: int
	var h_fin: int
	var m_fin: int
	if fin_abs >= 10080:
		d_fin = 6
		h_fin = 24
		m_fin = 0
	else:
		d_fin = clampi(int(fin_abs / 1440), 0, 6)
		var rem_fin: int = fin_abs - d_fin * 1440
		h_fin = int(rem_fin / 60)
		m_fin = rem_fin % 60

	horario.dia_inicio_texto.text = Funciones_Globales.Devolver_Dia_Reducido(d_ini)
	horario.hora_inicio_texto.text = "%02d" % h_ini
	horario.minuto_inicio_texto.text = "%02d" % m_ini

	horario.dia_final_texto.text = Funciones_Globales.Devolver_Dia_Reducido(d_fin)
	horario.hora_final_texto.text = "%02d" % h_fin
	horario.minuto_final_texto.text = "%02d" % m_fin


func _Set_Boton_Activo(boton: Button, activo: bool) -> void:
	if boton == null:
		return
	if activo:
		Funciones_Globales.Visibilizar_Objeto([boton])
	else:
		Funciones_Globales.Desvisibilizar_Objeto([boton])


func _Actualizar_Visibilidad_Botones(min_abs: int, max_abs: int, ini_abs: int, fin_abs: int) -> void:
	var max_ini: int = fin_abs - 5
	var min_fin: int = ini_abs + 5

	var d_ini: int = clampi(int(ini_abs / 1440), 0, 6)
	var d_min_abs: int = clampi(int(min_abs / 1440), 0, 6)
	var d_max_ini: int = clampi(int(max_ini / 1440), 0, 6)

	var h_abs_ini: int = int(ini_abs / 60)
	var h_abs_min: int = int(min_abs / 60)
	var h_abs_max_ini: int = int(max_ini / 60)

	_Set_Boton_Activo(horario.minuto_inicio_arriba, ini_abs < max_ini)
	_Set_Boton_Activo(horario.minuto_inicio_abajo, ini_abs > min_abs)
	_Set_Boton_Activo(horario.hora_inicio_arriba, h_abs_ini < h_abs_max_ini)
	_Set_Boton_Activo(horario.hora_inicio_abajo, h_abs_ini > h_abs_min)
	_Set_Boton_Activo(horario.dia_inicio_arriba, d_ini < d_max_ini)
	_Set_Boton_Activo(horario.dia_inicio_abajo, d_ini > d_min_abs)

	var d_fin: int = 6 if fin_abs >= 10080 else clampi(int(fin_abs / 1440), 0, 6)
	var d_max_abs: int = 6 if max_abs >= 10080 else clampi(int(max_abs / 1440), 0, 6)
	var d_min_fin: int = 6 if min_fin >= 10080 else clampi(int(min_fin / 1440), 0, 6)

	var h_abs_fin: int = int(fin_abs / 60)
	var h_abs_max: int = int(max_abs / 60)
	var h_abs_min_fin: int = int(min_fin / 60)

	var es_domingo_24: bool = (fin_abs >= 10080)
	_Set_Boton_Activo(horario.minuto_final_arriba, (not es_domingo_24) and (fin_abs < max_abs))
	_Set_Boton_Activo(horario.minuto_final_abajo, fin_abs > min_fin)
	_Set_Boton_Activo(horario.hora_final_arriba, (not es_domingo_24) and (h_abs_fin < h_abs_max))
	_Set_Boton_Activo(horario.hora_final_abajo, h_abs_fin > h_abs_min_fin)
	_Set_Boton_Activo(horario.dia_final_arriba, (not es_domingo_24) and (d_fin < d_max_abs))
	_Set_Boton_Activo(horario.dia_final_abajo, d_fin > d_min_fin)


func _Formatear_Abs_Legible(val_abs: int) -> String:
	var nombres_dias := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
	if val_abs >= 10080:
		return "Domingo · 24:00"
	var d: int = clampi(int(val_abs / 1440), 0, 6)
	var rem: int = val_abs - d * 1440
	var h: int = int(rem / 60)
	var m: int = rem % 60
	return "%s · %02d:%02d" % [nombres_dias[d], h, m]


func _Actualizar_Resumen_UI(raiz: Node, min_abs: int, max_abs: int, ini_abs: int, fin_abs: int) -> void:
	if raiz == null:
		return
	var sel := raiz.get_node_or_null("Actividades/Seleccionar_Horario")
	if sel == null:
		return

	var lbl_res_ini := sel.get_node_or_null("Inicio/Resumen_Inicio_Label") as Label
	if lbl_res_ini != null:
		lbl_res_ini.text = _Formatear_Abs_Legible(ini_abs)

	var lbl_res_fin := sel.get_node_or_null("Final/Resumen_Final_Label") as Label
	if lbl_res_fin != null:
		lbl_res_fin.text = _Formatear_Abs_Legible(fin_abs)

	var dur_min: int = maxi(0, fin_abs - ini_abs)
	var dur_txt: String
	if dur_min >= 60:
		var dh: int = dur_min / 60
		var dm: int = dur_min % 60
		dur_txt = "%dh %02dm" % [dh, dm]
	else:
		dur_txt = "%d min" % dur_min

	var lbl_dur := sel.get_node_or_null("Pill_Duracion_Seleccion/Duracion_Label") as Label
	if lbl_dur != null:
		lbl_dur.text = "⏱  Duración: %s" % dur_txt

	var sub_disp := sel.get_node_or_null("Subtitulo_Disponible") as Label
	if sub_disp != null:
		sub_disp.text = "Disponible: %s  →  %s" % [
			_Formatear_Abs_Legible(min_abs).replace(" · ", " "),
			_Formatear_Abs_Legible(max_abs).replace(" · ", " ")
		]


func Comprobar_Visibilidad_Abajo_Inicio():
	var min_abs := _Min_Bloque_Abs()
	var max_abs := _Max_Bloque_Abs()
	_Actualizar_Visibilidad_Botones(min_abs, max_abs, _Leer_Inicio_Abs(), _Leer_Final_Abs())


func Comprobar_Visibilidad_Arriba_Final():
	var min_abs := _Min_Bloque_Abs()
	var max_abs := _Max_Bloque_Abs()
	_Actualizar_Visibilidad_Botones(min_abs, max_abs, _Leer_Inicio_Abs(), _Leer_Final_Abs())


func Comprobar_Visibilidad_Medio():
	var min_abs := _Min_Bloque_Abs()
	var max_abs := _Max_Bloque_Abs()
	_Actualizar_Visibilidad_Botones(min_abs, max_abs, _Leer_Inicio_Abs(), _Leer_Final_Abs())


func UltimaComprobacion():
	if Comprobar_Negativos():
		Restart()
		return
	var min_abs := _Min_Bloque_Abs()
	var max_abs := _Max_Bloque_Abs()
	var ini_abs := _Leer_Inicio_Abs()
	var fin_abs := _Leer_Final_Abs()
	if ini_abs < min_abs or fin_abs > max_abs or ini_abs + 5 > fin_abs:
		Restart()


func Restart():
	var min_abs := _Min_Bloque_Abs()
	var max_abs := _Max_Bloque_Abs()
	_Aplicar_Abs_A_Horario(min_abs, max_abs)
	_ultimo_ini_abs = min_abs
	_ultimo_fin_abs = max_abs
	_Actualizar_Visibilidad_Botones(min_abs, max_abs, min_abs, max_abs)
	horario.Actualizar_Todo_Contexto()
	if _raiz_ref != null and is_instance_valid(_raiz_ref):
		_Actualizar_Resumen_UI(_raiz_ref, min_abs, max_abs, min_abs, max_abs)


func Comparar_Horas_Ini(dia_ini, hora_ini, min_ini, dia_fin, hora_fin, min_fin, comprobacion_medio):
	if dia_ini > dia_fin:
		return true
	elif dia_ini < dia_fin:
		return false
	elif hora_ini > hora_fin:
		return true
	elif hora_ini < hora_fin:
		return false
	elif min_ini >= min_fin and comprobacion_medio:
		return true
	elif min_ini > min_fin and not comprobacion_medio:
		return true
	else:
		return false


func Comprobar_Negativos():
	if horario.dia_inicio_texto.text == "" or horario.hora_inicio_texto.text == "" or horario.minuto_inicio_texto.text == "":
		return true
	if horario.dia_final_texto.text == "" or horario.hora_final_texto.text == "" or horario.minuto_final_texto.text == "":
		return true
	if horario.dia_inicio_a_int() == -1 or horario.dia_final_a_int() == -1:
		return true
	if horario.hora_inicio_texto.text.to_int() < 0 or horario.hora_inicio_texto.text.to_int() >= 24:
		return true
	if horario.minuto_inicio_texto.text.to_int() < 0 or horario.minuto_inicio_texto.text.to_int() >= 60:
		return true
	if horario.dia_final_a_int() == 6:
		if horario.hora_final_texto.text.to_int() > 24 or horario.hora_final_texto.text.to_int() < 0:
			return true
		if horario.hora_final_texto.text.to_int() == 24 and horario.minuto_final_texto.text.to_int() != 0:
			return true
	else:
		if horario.hora_final_texto.text.to_int() >= 24 or horario.hora_final_texto.text.to_int() < 0:
			return true
	if horario.minuto_final_texto.text.to_int() < 0 or horario.minuto_final_texto.text.to_int() >= 60:
		return true
	return false
