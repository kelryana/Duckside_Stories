extends Area2D

@export var damage: int = 1
@export var reflect_speed_multiplier: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D if has_node("CollisionPolygon2D") else null

var direction: Vector2 = Vector2.DOWN
var speed: float = 500.0
var lifetime: float = 5.0
var time_alive: float = 0.0

# Estado
var is_reflected: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered) # Necessário para acertar a MiniCloud (se ela for Area2D ou tiver hitbox)
	
	# Delay inicial de colisão (mantido do original)
	if collision_shape:
		collision_shape.disabled = true
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(self) and collision_shape:
			collision_shape.disabled = false

func _physics_process(delta):
	global_position += direction * speed * delta
	time_alive += delta
	
	if time_alive >= lifetime:
		queue_free()
	
	if ScreenBoundsManager and not ScreenBoundsManager.is_inside_screen(global_position):
		queue_free()

func _on_body_entered(body):
	_handle_collision(body)

func _on_area_entered(area):
	_handle_collision(area)

func _handle_collision(target):
	# 1. Se já foi refletido, ele busca INIMIGOS (Mini Clouds)
	if is_reflected:
		if target.has_method("take_damage") and target.is_in_group("angry_cloud"):
			target.take_damage(1) # Dano fixo de 1 raio
			create_hit_effect()
			queue_free()
		return

	# 2. Se é um raio normal (Inimigo), ele busca o PLAYER
	if target.is_in_group("player"):
		# Verifica se o player tem o escudo ativo
		if target.has_method("has_shield_active") and target.has_shield_active():
			reflect_projectile()
		else:
			if target.has_method("take_damage"):
				target.take_damage(damage)
			queue_free()
		return
	
	# Destroi em paredes/chão
	if target is TileMap or target.is_in_group("terrain"):
		create_hit_effect()
		queue_free()

func reflect_projectile():
	if is_reflected: return
	
	is_reflected = true
	
	# Toca som de rebate (opcional)
	# AudioSystem.play("reflect") 
	
	# Calcula direção baseada no MOUSE
	var mouse_pos = get_global_mouse_position()
	direction = (mouse_pos - global_position).normalized()
	
	# Atualiza velocidade e rotação
	speed *= reflect_speed_multiplier
	rotation = direction.angle() + PI/2
	
	# Visual: Muda cor para indicar que é "Amigo"
	if sprite:
		sprite.modulate = Color(0, 1, 1) # Ciano/Azul Neon
		sprite.scale *= 1.2

	# Lógica de Colisão:
	# Ignora o Player e foca nos inimigos.
	# A maneira mais simples via código sem mexer em bits complexos:
	set_collision_mask_value(1, false) # Desliga colisão com Player (Assumindo Layer 1)
	set_collision_mask_value(2, true)  # Liga colisão com Inimigos (Assumindo Layer 2) ou similar
	
	# Reseta timer de vida para dar tempo de chegar no alvo
	time_alive = 0.0
	
	print("⚡ Raio Refletido para %s!" % mouse_pos)

func create_hit_effect():
	# Aqui você instanciaria uma partícula de explosão
	pass
