extends CharacterBody2D

@export var speed = 400.0

func _physics_process(_delta):
	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	print("Direção do Input: ", direction)

	velocity = direction * speed
	move_and_slide()
