extends AnimatedSprite2D # Ou Sprite2D

@export var speed: float = 100.0
@export var left_limit: float = 100.0
@export var right_limit: float = 1000.0
var direction: int = 1

func _process(delta):
	# Anda para a direita ou esquerda
	position.x += speed * direction * delta
	
	# Vira ao bater na borda
	if position.x > right_limit:
		direction = -1
		flip_h = true # Vira o sprite
	elif position.x < left_limit:
		direction = 1
		flip_h = false
		
	# Toca animação (se tiver)
	if has_method("play"):
		play("walk")
