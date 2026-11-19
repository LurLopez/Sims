extends Node

const NOMBRES := ["Salud física", "Salud mental", "Hambre", "Descanso", "Higiene"]

var barra_salud_fisica: ProgressBar
var barra_salud_mental: ProgressBar
var barra_hambre: ProgressBar
var barra_descanso: ProgressBar
var barra_higiene: ProgressBar
var barras: Array = []
var etiquetas: Array = []
var pct_labels: Array = []
var _ultimos_valores: Array[int] = [-1, -1, -1, -1, -1]
var _inicializado: bool = false
var _estado_label: Label = null
var _ultima_firma_estado: String = ""


func Inicializar(raiz) -> void:
	if _inicializado and barra_salud_fisica != null and is_instance_valid(barra_salud_fisica):
		return
	barra_salud_fisica = raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Salud_Fisica")
	barra_salud_mental = raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Salud_Mental")
	barra_hambre = raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Hambre")
	barra_descanso = raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Descanso")
	barra_higiene = raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Higiene")
	barras = [barra_salud_fisica, barra_salud_mental, barra_hambre, barra_descanso, barra_higiene]
	var contenedor = raiz.get_node_or_null("Necesidades_Basicas/Necesidades_Basicas_Texto")
	if contenedor != null:
		etiquetas = contenedor.get_children()
	pct_labels.clear()
	for i in range(barras.size()):
		if i < etiquetas.size() and is_instance_valid(etiquetas[i]):
			etiquetas[i].text = NOMBRES[i]
		pct_labels.append(raiz.get_node_or_null("Necesidades_Basicas/Pct_%d" % i) as Label)
	_ultimos_valores = [-1, -1, -1, -1, -1]
	_inicializado = true


func Actualizar_Necesidades_Basicas(raiz) -> void:
	if not _inicializado:
		Inicializar(raiz)
	for i in range(barras.size()):
		var val: int = Variables_Dinamicas.Necesidades_Basicas[i]
		if val == _ultimos_valores[i]:
			continue
		_ultimos_valores[i] = val
		_Actualizar_Barra(barras[i], val)
		var pct = pct_labels[i] if i < pct_labels.size() else null
		if pct != null and is_instance_valid(pct):
			pct.text = "%d%%" % val
			pct.add_theme_color_override("font_color", Estilos_UI.color_valor(val))


func _Actualizar_Barra(barra: ProgressBar, valor: int) -> void:
	if barra == null or not is_instance_valid(barra):
		return
	var color := Estilos_UI.color_valor(valor)
	Estilos_UI.animar_barra(barra, float(valor), color)


func _Formatear_Duracion_Estado(minutos_restantes: int) -> String:
	var minutos: int = clampi(minutos_restantes, 0, 1440)
	return "%dh %02dm" % [minutos / 60, minutos % 60]


func _Firma_Estados(estados: Dictionary) -> String:
	var claves: Array = estados.keys()
	claves.sort()
	var partes: Array[String] = []
	for clave in claves:
		partes.append("%s=%d" % [str(clave), int(estados[clave])])
	return "|".join(partes)


func Construir_Texto_Estado(estados: Dictionary, cap_resacon: int) -> String:
	var lineas: Array[String] = []
	if estados.has("Euforia"):
		lineas.append("Euforia · %s" % _Formatear_Duracion_Estado(int(estados["Euforia"])))
	if estados.has("Resacon"):
		lineas.append("Resacón · %s · límite %d" % [
			_Formatear_Duracion_Estado(int(estados["Resacon"])), cap_resacon])
	return "\n".join(lineas)


# Se llama desde Script_Principal con la misma cadencia que el resto del panel
# (0,5 s), pero solo toca la UI cuando cambia la firma de los estados.
func Actualizar_Estado_Temporal(raiz) -> void:
	if _estado_label == null or not is_instance_valid(_estado_label):
		_estado_label = raiz.find_child("Estado_Temporal_Label", true, false) as Label
	if _estado_label == null:
		return
	var estados: Dictionary = Variables_Dinamicas.Estados_Temporales
	var firma: String = _Firma_Estados(estados)
	var debe_estar_visible: bool = not estados.is_empty()
	if firma == _ultima_firma_estado and _estado_label.visible == debe_estar_visible:
		return
	_ultima_firma_estado = firma
	if not debe_estar_visible:
		_estado_label.text = ""
		_estado_label.visible = false
		return
	_estado_label.text = Construir_Texto_Estado(estados, Actividades.Obtener_Cap_Resacon())
	_estado_label.add_theme_color_override("font_color",
		Estilos_UI.PELIGRO if estados.has("Resacon") else Estilos_UI.EXITO)
	_estado_label.visible = true
