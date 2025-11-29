extends CharacterBody2D

# --- Configurações de Movimento ---
@export var SPEED: float = 300.0  
@export var JUMP_VELOCITY: float = -600.0
@export var screen_margin: float = 20.0
@export var anim: AnimatedSprite2D

@export_group("Dash")
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

@export_group("Planar")
@export var glide_gravity_scale: float = 0.3
@export var glide_horizontal_speed: float = 250.0
@export var glide_fall_speed: float = 100.0

# --- Sistemas de Vida e Escudo ---
@export_group("Vida")
@export var max_health: int = 5
@export var invincibility_duration: float = 1.0

@export_group("Buff")
@export var max_consumables: int = 3           # Máximo que pode carregar
@export var consumable_buff_duration: float = 5.0
@export var consumable_speed_multiplier: float = 1.5  # 50% mais rápido
@export var consumable_jump_multiplier: float = 1.2   # 20% mais alto

@export_group("Game Feel")
@export var shake_decay: float = 10.0  # Quão rápido o tremor para (maior = para mais rápido)
# --- Nós ---
@onready var consumable_sprite: Node2D = $consumableSprite if has_node("consumableSprite") else null
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

# --- Variáveis de Estado ---
var default_speed: float
var default_jump: float

# Estados de Jogo
var is_angry_cloud_game: bool = false
var current_health: int = 5
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var shield_active: bool = false

# Estados de Inventário e Buff
var consumable_inventory: int = 0
var consumable_buff_active: bool = false
var consumable_buff_timer: float = 0.0

# Estados de movimento
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var is_gliding: bool = false

# Game feel
var shake_strength: float = 0.0        # Força atual do tremor

# --- Sinais ---
signal health_changed(new_health, max_health)
signal consumable_inventory_changed(current_count)
signal player_died


func _ready():
	add_to_group("player")
	
	# Salva valores originais
	default_speed = SPEED
	default_jump = JUMP_VELOCITY
	
	# Visual do escudo desligado
	if consumable_sprite:
		consumable_sprite.visible = false
	
	# Inicializa vida e inventário
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	emit_signal("consumable_inventory_changed", consumable_inventory)
	
	# Integrações externas
	if GameManager:
		GameManager.restore_player_state(self)
	if ScreenUtils:
		ScreenUtils.set_margin(screen_margin)

func _physics_process(delta):
	# Cooldown do dash
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Buff do Escudo
	if consumable_buff_active:
		consumable_buff_timer -= delta
		if consumable_buff_timer <= 0:
			deactivate_consumable_buff()
			
	# Escolhe modo de movimento
	if is_dashing:
		_dash_move(delta)
	elif is_angry_cloud_game:
		_minigame_move(delta)
	else:
		_normal_move(delta)
	
	# Limita posição
	if ScreenUtils:
		global_position = ScreenUtils.clamp_position(global_position)
	
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		# Treme a câmera se ela existir
		if camera:
			camera.offset = _get_random_offset()
	
	_update_invincibility(delta)
	animation_logic()

# --- Lógica de Movimento ---

func _normal_move(_delta):
	var direction := Vector2.ZERO
	if Input.is_action_pressed("RIGHT"): direction.x = 1
	if Input.is_action_pressed("LEFT"): direction.x = -1
	if Input.is_action_pressed("UP"): direction.y = -1
	if Input.is_action_pressed("DOWN"): direction.y = 1
	
	if Input.is_action_just_pressed("DASH") and dash_cooldown_timer <= 0 and direction != Vector2.ZERO:
		_start_dash(direction)
		return
	
	velocity = direction.normalized() * SPEED
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0
	
	move_and_slide()

func _minigame_move(delta):
	var horizontal_input := Input.get_axis("LEFT", "RIGHT")
	
	if Input.is_action_just_pressed("USE_ITEM"):
		consume_consumable_item()

	# Gravidade e Planar
	if not is_on_floor():
		if Input.is_action_pressed("DOWN") and velocity.y > 0:
			if not is_gliding:
				is_gliding = true
				print("Planando ativado!")
			
			velocity.y += get_gravity().y * glide_gravity_scale * delta
			velocity.y = min(velocity.y, glide_fall_speed)
			
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
	
	# Dash no ar
	if Input.is_action_just_pressed("DASH") and dash_cooldown_timer <= 0:
		var dash_dir = Vector2(horizontal_input, 0)
		if dash_dir != Vector2.ZERO:
			_start_dash(dash_dir)
			return
	
	# Movimento horizontal
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

# --- Lógica de Dash ---

func _start_dash(direction: Vector2):
	is_dashing = true
	dash_timer = 0.0
	dash_direction = direction.normalized()
	dash_cooldown_timer = dash_cooldown
	
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 2.0)
	print("Dash iniciado! Direção: %s" % dash_direction)

func _dash_move(delta):
	dash_timer += delta
	if dash_timer >= dash_duration:
		_end_dash()
		return
	
	velocity = dash_direction * dash_speed
	move_and_slide()

func _end_dash():
	is_dashing = false
	dash_timer = 0.0
	
	if sprite:
		sprite.modulate = Color.WHITE
	velocity *= 0.5
	print("Dash finalizado!")

# --- Sistema de Inventário (Consumível) ---

func collect_consumable_item() -> bool:
	if consumable_inventory < max_consumables:
		consumable_inventory += 1
		print("Item coletado! Inv: %d/%d" % [consumable_inventory, max_consumables])
		emit_signal("consumable_inventory_changed", consumable_inventory)
		return true
	else:
		print("Inventário cheio!")
		return false

func consume_consumable_item():
	if consumable_inventory > 0:
		consumable_inventory -= 1
		emit_signal("consumable_inventory_changed", consumable_inventory)
		print("Usou consumable! Restam: %d" % consumable_inventory)
		
		heal(1)
		activate_consumable_buff(consumable_buff_duration)
	else:
		print("Nenhum item para usar.")

func activate_consumable_buff(duration: float):
	consumable_buff_active = true
	consumable_buff_timer = duration
	
	if SPEED == default_speed:
		SPEED = default_speed * consumable_speed_multiplier
		JUMP_VELOCITY = default_jump * consumable_jump_multiplier
	
	print("BUFF ATIVO! %.1fs" % duration)
	
	if consumable_sprite:
		consumable_sprite.visible = true
	if sprite:
		sprite.modulate = Color(0.6, 1.0, 1.0)

func deactivate_consumable_buff():
	consumable_buff_active = false
	print("BUFF TERMINOU.")
	
	SPEED = default_speed
	JUMP_VELOCITY = default_jump
	
	if consumable_sprite:
		consumable_sprite.visible = false
	if sprite:
		sprite.modulate = Color.WHITE

# --- Sistema de Vida e Dano ---

func take_damage(damage: int = 1):
	if consumable_buff_active:
		print("Dano bloqueado pelo Buff!")
		return
	if is_invincible or is_dashing:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	print("Dano! Vida: %d/%d" % [current_health, max_health])
	emit_signal("health_changed", current_health, max_health)
	
	is_invincible = true
	invincibility_timer = invincibility_duration
	_play_hit_effect()
	
	if current_health <= 0:
		_die()

func heal(amount: int = 1):
	if current_health < max_health:
		current_health = min(current_health + amount, max_health)
		emit_signal("health_changed", current_health, max_health)
		print("Curado! Vida: %d/%d" % [current_health, max_health])
	else:
		print("Vida cheia.")

func _update_invincibility(delta):
	if not is_invincible: return
	
	invincibility_timer -= delta
	if sprite:
		sprite.modulate.a = 0.5 if int(invincibility_timer * 10) % 2 == 0 else 1.0
	
	if invincibility_timer <= 0:
		is_invincible = false
		if sprite: sprite.modulate.a = 1.0

func _play_hit_effect():
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			if consumable_buff_active:
				sprite.modulate = Color(0.6, 1.0, 1.0)
			else:
				sprite.modulate = Color.WHITE

func _die():
	print("Game Over")
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
	consumable_inventory = 0
	emit_signal("consumable_inventory_changed", consumable_inventory)
	
	if consumable_buff_active:
		deactivate_consumable_buff()
		
	emit_signal("health_changed", current_health, max_health)

# --- Getters e Utilitários ---

func get_current_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func has_shield_active() -> bool:
	return shield_active

func activate_shield_buff():
	shield_active = true
	if has_node("ShieldVisual"):
		$ShieldVisual.visible = true
	else:
		modulate = Color(0.5, 0.5, 1.0)

func deactivate_shield_buff():
	shield_active = false
	if has_node("ShieldVisual"):
		$ShieldVisual.visible = false
	else:
		modulate = Color.WHITE

func _get_random_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)

func apply_screen_shake(amount: float):
	shake_strength = amount

func _on_porta_nuvem_trigger_body_entered(body):
	if body == self:
		GameManager.save_player_state(self)
		GameManager.change_to_cloud_world()
