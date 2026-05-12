extends Node

var barra_salud_fisica
var barra_salud_mental
var barra_hambre
var barra_descanso
var barra_higiene


func Inicializar(raiz):
	barra_salud_fisica=raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Salud_Fisica")
	barra_salud_mental=raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Salud_Mental")
	barra_hambre=raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Hambre")
	barra_descanso=raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Descanso")
	barra_higiene=raiz.get_node("Necesidades_Basicas/Necesidades_Basicas_Barra/Higiene")
	



func Cambiar_Fondo_Barra_Progreso():
	if (Variables_Dinamicas.Necesidades_Basicas[0]<30):
		barra_salud_fisica.get("theme_override_styles/fill").bg_color=Color.RED
	elif (Variables_Dinamicas.Necesidades_Basicas[0]<50):
		barra_salud_fisica.get("theme_override_styles/fill").bg_color=Color.ORANGE
	else:
		barra_salud_fisica.get("theme_override_styles/fill").bg_color=Color.GREEN
	
	
	if (Variables_Dinamicas.Necesidades_Basicas[1]<30):
		barra_salud_mental.get("theme_override_styles/fill").bg_color=Color.RED
	elif (Variables_Dinamicas.Necesidades_Basicas[1]<50):
		barra_salud_mental.get("theme_override_styles/fill").bg_color=Color.ORANGE
	else:
		barra_salud_mental.get("theme_override_styles/fill").bg_color=Color.GREEN
	
	if (Variables_Dinamicas.Necesidades_Basicas[2]<30):
		barra_hambre.get("theme_override_styles/fill").bg_color=Color.RED
	elif (Variables_Dinamicas.Necesidades_Basicas[2]<50):
		barra_hambre.get("theme_override_styles/fill").bg_color=Color.ORANGE
	else:
		barra_hambre.get("theme_override_styles/fill").bg_color=Color.GREEN
	
	if (Variables_Dinamicas.Necesidades_Basicas[3]<30):
		barra_descanso.get("theme_override_styles/fill").bg_color=Color.RED
	elif (Variables_Dinamicas.Necesidades_Basicas[3]<50):
		barra_descanso.get("theme_override_styles/fill").bg_color=Color.ORANGE
	else:
		barra_descanso.get("theme_override_styles/fill").bg_color=Color.GREEN
	
	if (Variables_Dinamicas.Necesidades_Basicas[4]<30):
		barra_higiene.get("theme_override_styles/fill").bg_color=Color.RED
	elif (Variables_Dinamicas.Necesidades_Basicas[4]<50):
		barra_higiene.get("theme_override_styles/fill").bg_color=Color.ORANGE
	else:
		barra_higiene.get("theme_override_styles/fill").bg_color=Color.GREEN

func Actualizar_Necesidades_Basicas(raiz):
	Inicializar(raiz)
	Cambiar_Fondo_Barra_Progreso()
	barra_salud_fisica.value=Variables_Dinamicas.Necesidades_Basicas[0]
	barra_salud_mental.value=Variables_Dinamicas.Necesidades_Basicas[1]
	barra_hambre.value=Variables_Dinamicas.Necesidades_Basicas[2]
	barra_descanso.value=Variables_Dinamicas.Necesidades_Basicas[3]
	barra_higiene.value=Variables_Dinamicas.Necesidades_Basicas[4]
