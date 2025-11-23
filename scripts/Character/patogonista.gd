extends CharacterBody2D

# Movimento básico
@export var SPEED: float = 300.0  
@export var JUMP_VELOCITY: float = -600.0
@export var screen_margin: float = 20.0

@export var anim: AnimatedSprite2D


# Dash
@export_group("Dash")
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

# Planar (Glide)
@export_group("Planar")
@export var glide_gravity_scale: float = 0.3
@export var glide_horizontal_speed: float = 250.0
@export var glide_fall_speed: float = 100.0

# Sistema de vida
@export_group("Vida")
@export var max_health: int = 5
@export var invincibility_duration: float = 1.0

@export_group("Bonus do Shield")
@export var shield_speed_multiplier: float = 1.5  # 50% mais rápido
@export var shield_jump_multiplier: float = 1.2   # 20% mais alto

# Variáveis internas para guardar os valores originais
var default_speed: float
var default_jump: float

@onready var shield_sprite: Node2D = $ShieldSprite if has_node("ShieldSprite") else null
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D


var is_angry_cloud_game: bool = false
var current_health: int = 5
var is_invincible: bool = false
var invincibility_timer: float = 0.0

var has_shield: bool = false
var shield_timer: float = 0.0

# Estados de movimento
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

var is_gliding: bool = false


signal health_changed(new_health, max_health)
signal player_died

func _ready():
	add_to_group("player")
	
	default_speed = SPEED
	default_jump = JUMP_VELOCITY
	
	if shield_sprite:
		shield_sprite.visible = false
	
	if GameManager:
		GameManager.restore_player_state(self)
	
	if ScreenBoundsManager:
		ScreenBoundsManager.set_margin(screen_margin)
	
	if is_angry_cloud_game:
		current_health = max_health
		emit_signal("health_changed", current_health, max_health)

func _physics_process(delta):
	# Atualiza cooldown do dash
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	if has_shield:
		shield_timer -= delta
		if shield_timer <= 0:
			deactivate_shield()
	
	# Escolhe modo de movimento
	if is_dashing:
		_dash_move(delta)
	elif is_angry_cloud_game:
		_minigame_move(delta)
	else:
		_normal_move(delta)
	
	# Limita posição na tela
	if ScreenBoundsManager:
		global_position = ScreenBoundsManager.clamp_position(global_position)
	
	# Sistema de invencibilidade
	_update_invincibility(delta)
	animation_logic()

func _normal_move(delta):
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("RIGHT"):
		direction.x = 1
	if Input.is_action_pressed("LEFT"):
		direction.x = -1
	if Input.is_action_pressed("UP"):
		direction.y = -1
	if Input.is_action_pressed("DOWN"):
		direction.y = 1
	
	# Dash (pressione Shift ou tecla de dash)
	if Input.is_action_just_pressed("DASH") and dash_cooldown_timer <= 0 and direction != Vector2.ZERO:
		_start_dash(direction)
		return
	
	velocity = direction.normalized() * SPEED
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0
	
	move_and_slide()

func _minigame_move(delta):
	var horizontal_input := Input.get_axis("LEFT", "RIGHT")
	
	# Aplicar gravidade
	if not is_on_floor():
		# Verifica se está planando
		if Input.is_action_pressed("DOWN") and velocity.y > 0:
			if not is_gliding:
				is_gliding = true
				print("Planando ativado!")
			
			# Gravidade reduzida durante planar
			velocity.y += get_gravity().y * glide_gravity_scale * delta
			velocity.y = min(velocity.y, glide_fall_speed)
			
			# Controle horizontal enquanto plana
			if horizontal_input:
				velocity.x = horizontal_input * glide_horizontal_speed
		else:
			is_gliding = false
			velocity.y += get_gravity().y * delta
	else:
		is_gliding = false
	
	# Pulo
	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_gliding = false
	
	# Dash no ar (opcional)
	if Input.is_action_just_pressed("DASH") and dash_cooldown_timer <= 0:
		var dash_dir = Vector2(horizontal_input, 0)
		if dash_dir != Vector2.ZERO:
			_start_dash(dash_dir)
			return
	
	# Movimento horizontal normal
	if not is_gliding:
		if horizontal_input:
			velocity.x = horizontal_input * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0
	
	move_and_slide()

func animation_logic():
	
	if velocity != Vector2.ZERO:
		anim.play("walk")
	else:
		anim.play("idle")
		
	if velocity.x != 0:
		anim.flip_h = velocity.x > 0

func _start_dash(direction: Vector2):
	is_dashing = true
	dash_timer = 0.0
	dash_direction = direction.normalized()
	dash_cooldown_timer = dash_cooldown
	
	# Efeito visual de dash
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 2.0)  # Azulado
	
	print("Dash iniciado! Direção: %s" % dash_direction)

func _dash_move(delta):
	dash_timer += delta
	
	if dash_timer >= dash_duration:
		_end_dash()
		return
	
	# Movimento rápido na direção do dash
	velocity = dash_direction * dash_speed
	
	# Durante o dash, ignora gravidade
	move_and_slide()

func _end_dash():
	is_dashing = false
	dash_timer = 0.0
	
	# Remove efeito visual
	if sprite:
		sprite.modulate = Color.WHITE
	
	# Reduz velocidade após o dash
	velocity *= 0.5
	
	print("Dash finalizado!")


func _update_invincibility(delta):
	if not is_invincible:
		return
	
	invincibility_timer -= delta
	
	# Efeito de piscada
	if sprite:
		sprite.modulate.a = 0.5 if int(invincibility_timer * 10) % 2 == 0 else 1.0
	
	if invincibility_timer <= 0:
		is_invincible = false
		if sprite:
			sprite.modulate.a = 1.0

func take_damage(damage: int = 1):
	if has_shield:
		print("Player: Dano bloqueado pelo Escudo!")
		return
	
	if is_invincible or is_dashing:  # Invencível durante dash
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	print("Player levou dano! Vida: %d/%d" % [current_health, max_health])
	emit_signal("health_changed", current_health, max_health)
	
	is_invincible = true
	invincibility_timer = invincibility_duration
	
	_play_hit_effect()
	
	if current_health <= 0:
		_die()

func heal(amount: int = 1):
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)
	print("Player curado! Vida: %d/%d" % [current_health, max_health])

func _play_hit_effect():
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE

func _die():
	print("Player morreu! Game Over")
	emit_signal("player_died")
	
	set_physics_process(false)
	set_process_input(false)
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(_on_death_animation_complete)

func _on_death_animation_complete():
	if GameManager:
		GameManager.on_player_death()

func reset_health():
	current_health = max_health
	is_invincible = false
	
	if has_shield:
		deactivate_shield()
	
	emit_signal("health_changed", current_health, max_health)

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func _on_porta_nuvem_trigger_body_entered(body):
	if body == self:
		GameManager.save_player_state(self)
		GameManager.change_to_cloud_world()

func activate_shield(duration: float):
	has_shield = true
	shield_timer = duration
	
	# Aplica Super Velocidade e Pulo
	SPEED = default_speed * shield_speed_multiplier
	JUMP_VELOCITY = default_jump * shield_jump_multiplier
	
	print("Shield ON! Speed: %.0f, Jump: %.0f" % [SPEED, JUMP_VELOCITY])
	
	# Ativa visual do escudo
	if shield_sprite:
		shield_sprite.visible = true
	
	# Opcional: Muda a cor do personagem para indicar poder (ex: azul claro)
	if sprite:
		sprite.modulate = Color(0.6, 1.0, 1.0) 

func deactivate_shield():
	has_shield = false
	print("Shield OFF. Valores restaurados.")
	
	# Restaura os valores originais
	SPEED = default_speed
	JUMP_VELOCITY = default_jump
	
	# Desativa visual
	if shield_sprite:
		shield_sprite.visible = false
	
	# Restaura a cor original
	if sprite:
		sprite.modulate = Color.WHITE
