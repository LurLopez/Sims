class_name Proveedor_Anuncios
extends RefCounted

# ============================================================================
# Interfaz de proveedor de anuncios recompensados.
#
# El prototipo usa Proveedor_Simulado_Anuncios. Un adaptador real (AdMob,
# AppLovin...) implementaría:
#   - Preparar_Anuncio(): cargar el anuncio y devolver ok/no_disponible.
#   - Confirmar_Anuncio(): validar el callback de recompensa del SDK.
#
# Recompensas es la única clase que decide si se concede una recompensa.
# La UI solo reproduce la creatividad simulada y avisa al terminar.
# ============================================================================

const CODIGO_OK := "ok"
const CODIGO_SIN_RELLENO := "sin_relleno"
const CODIGO_CANCELADO := "cancelado"
const CODIGO_NO_DISPONIBLE := "proveedor_no_disponible"
const CODIGO_NO_VERIFICADO := "recompensa_no_verificada"


func Esta_Disponible() -> bool:
	return false


func Obtener_Canal() -> String:
	return "Sin proveedor"


func Preparar_Anuncio(_anuncio: Dictionary) -> Dictionary:
	return _resultado_error(CODIGO_NO_DISPONIBLE, "No hay un proveedor de anuncios configurado.")


func Confirmar_Anuncio(_token: int, _anuncio: Dictionary) -> Dictionary:
	return _resultado_error(CODIGO_NO_DISPONIBLE, "No hay un proveedor de anuncios configurado.")


func _resultado_error(codigo: String, mensaje: String) -> Dictionary:
	return {"ok": false, "codigo": codigo, "mensaje": mensaje}
