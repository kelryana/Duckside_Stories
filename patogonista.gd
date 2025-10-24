extends CharacterBody2D

@export var speed = 400.0
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(_delta):
	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	print("Direção do Input: ", direction)

	velocity = direction * speed
	move_and_slide()
	
	if velocity.x < 0:
		sprite.flip_h = false
	elif velocity.x > 0:
		sprite.flip_h = true
	
