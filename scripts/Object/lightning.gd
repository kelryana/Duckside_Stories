extends Area2D

@export var damage: int = 1

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D if has_node("CollisionPolygon2D") else null

var direction: Vector2 = Vector2.DOWN
var speed: float = 500.0
var lifetime: float = 3.0
var time_alive: float = 0.0

func _ready():
	print("Lightning _ready(): speed=%.1f, direction=%s, pos=%s" % [speed, direction, global_position])
	
	# Conecta sinal de colisão
	body_entered.connect(_on_body_entered)
	
	# Desabilita colisão temporariamente para não colidir com a nuvem
	if collision_shape:
		collision_shape.disabled = true
		# Aguarda 2 frames antes de habilitar colisão
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(self) and collision_shape:
			collision_shape.disabled = false
			print("Lightning: Colisão habilitada após delay")

func _physics_process(delta):
	# Move o raio
	global_position += direction * speed * delta
	
	# Conta tempo de vida
	time_alive += delta
	
	# Efeito de fade no final da vida (últimos 0.5 segundos)
	if sprite and lifetime > 0.5:
		var fade_start = lifetime - 0.5
		if time_alive >= fade_start:
			var fade_progress = (time_alive - fade_start) / 0.5
			sprite.modulate.a = 1.0 - fade_progress
	
	# Destroi após lifetime (como segurança)
	if time_alive >= lifetime:
		print("Lightning destruído por timeout após %.1fs" % time_alive)
		queue_free()
		return
	
	# Destroi se sair da tela
	if ScreenBoundsManager and not ScreenBoundsManager.is_inside_screen(global_position):
		print("Lightning destruído por sair da tela em %s" % global_position)
		queue_free()

func _on_body_entered(body):
	"""Detecta colisão com o player ou outros objetos"""
	print("Lightning colidiu com: %s (grupos: %s)" % [body.name, body.get_groups()])
	
	# IGNORA colisão com a própria AngryCloud
	if body.is_in_group("bounded_objects"):
		print("Lightning ignorou colisão com bounded_object")
		return
	
	if body.is_in_group("player"):
		# Causa dano ao player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		print("Lightning atingiu player!")
		queue_free()
		return
	
	# Destrói ao colidir com superfícies físicas
	if body is TileMap or body is StaticBody2D or body.is_in_group("terrain"):
		print("Lightning atingiu terreno: %s" % body.name)
		queue_free()
		return
	
	# Também destrói ao colidir com qualquer corpo físico (exceto CharacterBody2D que pode ser AngryCloud)
	if body is PhysicsBody2D and not body is CharacterBody2D:
		print("Lightning atingiu PhysicsBody2D: %s" % body.name)
		queue_free()
