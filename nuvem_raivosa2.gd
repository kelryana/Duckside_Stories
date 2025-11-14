extends CharacterBody2D

@onready var anim_player2 = $AnimationPlayer
@export var speed: float = 200.0

@export var patrol_range: float = 80.0

var direction_vector: Vector2 = Vector2.RIGHT
var start_position: Vector2

@export var pato: CharacterBody2D


@onready var sprite: Sprite2D = $Sprite2D

@export var curves_path: Array[Path2D]

var t: float = 0.0

func _ready():
	start_position = global_position
	anim_player2.play("idle_anim2")
	pato.scale = Vector2(1, 1)
	pato.is_cloud_game = true

func _physics_process(delta: float):

	#if global_position.x > start_position.x + patrol_range:
		#direction_vector = Vector2.LEFT
	#
	#elif global_position.x < start_position.x - patrol_range:
		#direction_vector = Vector2.RIGHT
#
	#velocity = direction_vector * speed
#
	#move_and_slide()
#
	#if velocity.x < 0:
		#sprite.flip_h = false
	#elif velocity.x > 0:
		#sprite.flip_h = true
#
	#if get_slide_collision_count() > 0:
		#var collision = get_slide_collision(0)
		#direction_vector = direction_vector.bounce(collision.get_normal())
		
	#var dir = global_position.direction_to(pato.global_position)
	#dir.y = 0
	#dir = dir.normalized()
	
	var curve = curves_path.get(0)
	var p = curve.curve.get_baked_points().get(int(t * curve.curve.get_baked_length()))
	
	t += 0.001
	
	if t >= 1.0:
		t = 0.0
	
		
	global_position = p
	
