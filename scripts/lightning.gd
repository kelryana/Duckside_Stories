extends Area2D

@export var speed: float = 500.0
@export var damage: int = 1
@export var lifetime: float = 3.0  # Tempo de vida do raio
@export var lightning_length: float = 200.0  # Comprimento visual do raio

@onready var sprite: Sprite2D = $Sprite2D  # Ajuste conforme sua estrutura
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

var direction: Vector2 = Vector2.DOWN
var time_alive: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	if sprite:
		sprite.scale.y = lightning_length / sprite.texture.get_height()

func set_direction(new_direction: Vector2):
	"""Define a direção do raio"""
	direction = new_direction.normalized()

func _physics_process(delta):
	global_position += direction * speed * delta
	
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body):
	"""Detecta colisão com o player ou outros objetos"""
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	
	elif body is TileMap or body.is_in_group("terrain"):
		queue_free()

func _exit_tree():
	pass
