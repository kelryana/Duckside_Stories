extends CharacterBody2D

@export var speed: float = 80.0
@export var direction: Vector2 = Vector2.RIGHT
@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float):
	velocity = direction * speed
	move_and_slide()
	
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		direction = direction.bounce(collision.get_normal())

	
