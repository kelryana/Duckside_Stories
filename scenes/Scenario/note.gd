extends Area2D

@export var speed: float = 300.0
var target_y: float = 0.0
var lane_id: int = 0 # Guarda qual pista ela é (0=Esq, 1=Baixo, 2=Cima, 3=Dir)

func _process(delta):
	# Cai para baixo
	position.y += speed * delta
	
	# Se passar muito do alvo, se destrói (Errou)
	if position.y > target_y + 100:
		queue_free()
		print("Errou mosca da pista ", lane_id)
