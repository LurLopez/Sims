class_name Proveedor_Simulado_Anuncios
extends Proveedor_Anuncios

# ============================================================================
# Red de anuncios falsa para la demo.
#
# Preparar_Anuncio autoriza la reproducción; Confirmar_Anuncio simula la
# verificación de la red (con una latencia mínima) antes de conceder la
# recompensa. No se descarga ni se muestra ningún anuncio real.
# ============================================================================

var latencia_verificacion: float = 0.25
var forzar_proximo_fallo: bool = false


func Esta_Disponible() -> bool:
	return true


func Obtener_Canal() -> String:
	return "Red de anuncios simulada"


func Preparar_Anuncio(anuncio: Dictionary) -> Dictionary:
	if str(anuncio.get("id", "")) == "":
		return _resultado_error(CODIGO_SIN_RELLENO, "No hay creatividad disponible.")
	return {"ok": true, "codigo": CODIGO_OK, "mensaje": "Anuncio simulado preparado."}


func Confirmar_Anuncio(token: int, anuncio: Dictionary) -> Dictionary:
	if latencia_verificacion > 0.0:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			await tree.create_timer(latencia_verificacion).timeout

	if forzar_proximo_fallo:
		forzar_proximo_fallo = false
		return _resultado_error(CODIGO_NO_VERIFICADO, "La red simulada no pudo verificar el anuncio.")

	if token <= 0 or str(anuncio.get("id", "")) == "":
		return _resultado_error(CODIGO_NO_VERIFICADO, "El token de recompensa no es válido.")

	return {
		"ok": true,
		"codigo": CODIGO_OK,
		"mensaje": "Recompensa verificada.",
		"referencia": "AD-%d-%d" % [token, Time.get_ticks_msec() % 100000],
	}
