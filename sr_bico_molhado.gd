extends CharacterBody2D

@export var speed: float = 50.0

@export var patrol_range: float = 80.0

var direction_vector: Vector2 = Vector2.RIGHT
var start_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	start_position = global_position

func _physics_process(delta: float):

	if global_position.x > start_position.x + patrol_range:
		direction_vector = Vector2.LEFT
	
	elif global_position.x < start_position.x - patrol_range:
		direction_vector = Vector2.RIGHT

	velocity = direction_vector * speed

	move_and_slide()

	if velocity.x < 0:
		sprite.flip_h = false
	elif velocity.x > 0:
		sprite.flip_h = true

	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		direction_vector = direction_vector.bounce(collision.get_normal())
