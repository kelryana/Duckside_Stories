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



# Sistema de Escudo (Consumível)

@export_group("Escudo")

@export var max_consumables: int = 3          # Máximo que pode carregar

@export var consumable_buff_duration: float = 5.0

@export var consumable_speed_multiplier: float = 1.5  # 50% mais rápido

@export var consumable_jump_multiplier: float = 1.2   # 20% mais alto



@onready var consumable_sprite: Node2D = $consumableSprite if has_node("consumableSprite") else null

@onready var sprite: Sprite2D = $Sprite2D

@onready var camera: Camera2D = $Camera2D



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



signal health_changed(new_health, max_health)

signal consumable_inventory_changed(current_count)

signal player_died



func _ready():

	add_to_group("player")

	

	# Salva valores originais de movimento

	default_speed = SPEED

	default_jump = JUMP_VELOCITY

	

	# Garante que o visual do escudo comece desligado

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

	# Atualiza cooldown do dash

	if dash_cooldown_timer > 0:

		dash_cooldown_timer -= delta



	# 3.Lógica do Buff do Escudo (Tempo de duração)

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

	

	# Limita posição na tela

	if ScreenUtils:

		global_position = ScreenUtils.clamp_position(global_position)

	

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

	

	if Input.is_action_just_pressed("USE_ITEM"):

		consume_consumable_item()

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



# ==========================================

# SISTEMA DE INVENTÁRIO DE ESCUDO (NOVO)

# ==========================================



func collect_consumable_item() -> bool:

	"""Chamado pelo consumablePowerUp quando colide."""

	if consumable_inventory < max_consumables:

		consumable_inventory += 1

		print("Item consumable coletado! Inventário: %d/%d" % [consumable_inventory, max_consumables])

		emit_signal("consumable_inventory_changed", consumable_inventory)

		return true # Retorna true para o item saber que pode sumir

	else:

		print("Inventário de consumables cheio!")

		return false # Retorna false e o item fica no chão



func consume_consumable_item():

	"""Chamado pelo Input do Jogador."""

	if consumable_inventory > 0:

		# 1. Remove do inventário

		consumable_inventory -= 1

		emit_signal("consumable_inventory_changed", consumable_inventory)

		

		print("Usou consumable! Restam: %d" % consumable_inventory)

		

		# 2. Recupera 1 de Vida

		heal(1)

		

		# 3. Ativa o Buff (Velocidade + Pulo)

		activate_consumable_buff(consumable_buff_duration)

	else:

		print("Nenhum consumable no inventário para usar.")



func activate_consumable_buff(duration: float):

	consumable_buff_active = true

	consumable_buff_timer = duration

	

	# Aplica multiplicadores (apenas se já não estiverem aplicados)

	if SPEED == default_speed:

		SPEED = default_speed * consumable_speed_multiplier

		JUMP_VELOCITY = default_jump * consumable_jump_multiplier

	

	print("BUFF ATIVO! Vel e Pulo aumentados por %.1fs" % duration)

	

	# Feedback Visual

	if consumable_sprite:

		consumable_sprite.visible = true

	if sprite:

		sprite.modulate = Color(0.6, 1.0, 1.0) # Ciano brilhante



func deactivate_consumable_buff():

	consumable_buff_active = false

	print("BUFF TERMINOU. Status normal.")

	

	# Reseta valores

	SPEED = default_speed

	JUMP_VELOCITY = default_jump

	

	# Desliga visual

	if consumable_sprite:

		consumable_sprite.visible = false

	if sprite:

		sprite.modulate = Color.WHITE



# ==========================================

# SISTEMA DE VIDA E DANO

# ==========================================



func take_damage(damage: int = 1):

	# 1. Se o Buff do Escudo estiver ativo, bloqueia o dano

	if consumable_buff_active:

		print("Player: Dano bloqueado pelo Buff do Escudo!")

		return

	

	# 2. Se estiver invencível ou no dash, ignora

	if is_invincible or is_dashing:

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

	if current_health < max_health:

		current_health = min(current_health + amount, max_health)

		emit_signal("health_changed", current_health, max_health)

		print("Player curado! Vida: %d/%d" % [current_health, max_health])

	else:

		print("Vida já está cheia.")



func _update_invincibility(delta):

	if not is_invincible:

		return

	

	invincibility_timer -= delta

	

	# Efeito visual de piscar

	if sprite:

		sprite.modulate.a = 0.5 if int(invincibility_timer * 10) % 2 == 0 else 1.0

	

	if invincibility_timer <= 0:

		is_invincible = false

		if sprite:

			sprite.modulate.a = 1.0



func _play_hit_effect():

	if sprite:

		sprite.modulate = Color.RED

		await get_tree().create_timer(0.1).timeout

		if is_instance_valid(sprite) and not consumable_buff_active:

			sprite.modulate = Color.WHITE

		elif is_instance_valid(sprite) and consumable_buff_active:

			sprite.modulate = Color(0.6, 1.0, 1.0) # Restaura a cor do buff se estiver ativo



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

	

	# Reseta inventário ou mantém? Geralmente reseta em Game Over:

	consumable_inventory = 0

	emit_signal("consumable_inventory_changed", consumable_inventory)

	

	# Desativa buff se estiver ativo

	if consumable_buff_active:

		deactivate_consumable_buff()

		

	emit_signal("health_changed", current_health, max_health)



func get_current_health() -> int:

	return current_health



func get_max_health() -> int:

	return max_health



func has_shield_active() -> bool:

	return shield_active



func activate_shield_buff():

	shield_active = true

	# Feedback Visual (Ex: Um círculo ao redor do player)

	if has_node("ShieldVisual"):

		$ShieldVisual.visible = true

	else:

		modulate = Color(0.5, 0.5, 1.0) # Azulado temporário



func deactivate_shield_buff():

	shield_active = false

	if has_node("ShieldVisual"):

		$ShieldVisual.visible = false

	else:

		modulate = Color.WHITE



func _on_porta_nuvem_trigger_body_entered(body):

	if body == self:

		GameManager.save_player_state(self)

		GameManager.change_to_cloud_world()
