extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():

	Guardar_Variables_Estaticas.load_game()
	Guardar_Variables_Dinamicas.load_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
