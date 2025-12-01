extends Area2D

signal collected

@export var damage: int = 1
@export var reflect_speed_multiplier: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D if has_node("CollisionPolygon2D") else null

var direction: Vector2 = Vector2.DOWN
var speed: float = 500.0
var lifetime: float = 5.0
var time_alive: float = 0.0

var is_reflected: bool = false

# ============================================================
# GERENCIAMENTO DE SIMULTANEIDADE + CONTADOR DE ESCUDO
# ============================================================
static var is_parry_event_active: bool = false
static var pending_projectiles: Array = []

# NOVO: Sistema de contagem de reflexões por escudo
static var shield_reflection_count: int = 0
static var max_reflections_before_break: int = 3
static var current_shield_owner = null # Referência ao player com escudo ativo

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	if collision_shape:
		collision_shape.disabled = true
		await get_tree().process_frame
		await get_tree().process_frame
		if is_instance_valid(self) and collision_shape:
			collision_shape.disabled = false

func _physics_process(delta):
	if is_parry_event_active: return

	global_position += direction * speed * delta
	time_alive += delta
	
	if time_alive >= lifetime:
		queue_free()
	
	if ScreenUtils and not ScreenUtils.is_inside_screen(global_position):
		queue_free()

func _on_body_entered(body):
	_handle_collision(body)

func _on_area_entered(area):
	_handle_collision(area)

func _handle_collision(target):
	# Raios refletidos atacam nuvens
	if is_reflected:
		if target.has_method("take_damage") and target.is_in_group("angry_cloud"):
			target.take_damage(1)
			create_hit_effect()
			queue_free()
		return

	# Colisão com PLAYER
	if target.is_in_group("player"):
		if target.has_method("has_shield_active") and target.has_shield_active():
			_register_for_parry(target)
		else:
			_deal_damage_and_destroy(target)
		return
	
	# Terreno
	if target is TileMap or target.is_in_group("terrain"):
		create_hit_effect()
		queue_free()

# ============================================================
# LÓGICA DE PARRY EM GRUPO (CORRIGIDA)
# ============================================================

func _register_for_parry(player_ref):
	# Adiciona à fila
	if not self in pending_projectiles:
		pending_projectiles.append(self)
	
	# NOVO: Registra o dono do escudo se ainda não foi feito
	if current_shield_owner == null:
		current_shield_owner = player_ref
	
	# Se já existe evento rodando, apenas espera
	if is_parry_event_active:
		return

	# Sou o líder, inicio o evento
	_start_parry_leader_logic(player_ref)

func _start_parry_leader_logic(player_ref):
	is_parry_event_active = true
	
	var window_duration_ms = 300
	var perfect_threshold_ms = 120
	var reaction_success = false
	var is_perfect = false
	
	# Congela o jogo
	Engine.time_scale = 0.05
	
	# Feedback visual em TODOS os raios pendentes
	for p in pending_projectiles:
		if is_instance_valid(p) and p.sprite:
			p.sprite.modulate = Color(3, 3, 3)
	
	var start_time = Time.get_ticks_msec()
	
	# Loop de input
	while Time.get_ticks_msec() - start_time < window_duration_ms:
		if Input.is_action_just_pressed("PARRY"):
			reaction_success = true
			var reaction_time = Time.get_ticks_msec() - start_time
			if reaction_time <= perfect_threshold_ms:
				is_perfect = true
			print("⚡ PARRY! Tempo: %dms | Perfeito: %s | Raios: %d" % 
				[reaction_time, is_perfect, pending_projectiles.size()])
			break
		
		await get_tree().process_frame
	
	# Restaura o tempo
	Engine.time_scale = 1.0
	is_parry_event_active = false
	
	# Resolve TODOS os raios de uma vez
	_resolve_all_pending_projectiles(player_ref, reaction_success, is_perfect)

func _resolve_all_pending_projectiles(player_ref, success: bool, perfect: bool):
	var reflected_count = 0
	
	# IMPORTANTE: Faz uma cópia da lista antes de iterar
	# porque _execute_reflection pode modificar a lista original
	var projectiles_copy = pending_projectiles.duplicate()
	
	for bolt in projectiles_copy:
		if not is_instance_valid(bolt):
			continue
			
		if success:
			bolt._execute_reflection(player_ref, perfect)
			reflected_count += 1
		else:
			# CORREÇÃO: Projétil não refletido causa dano e é destruído
			bolt._deal_damage_and_destroy(player_ref)
	
	pending_projectiles.clear()
	
	# ============================================================
	# SISTEMA DE QUEBRA DE ESCUDO (CORRIGIDO)
	# ============================================================
	if success and reflected_count > 0:
		shield_reflection_count += 1
		
		print("🛡️ Reflexões: %d/%d | Raios refletidos neste turno: %d" % 
			[shield_reflection_count, max_reflections_before_break, reflected_count])
		
		# QUEBRA APÓS 3 REFLEXÕES BEM-SUCEDIDAS
		if shield_reflection_count >= max_reflections_before_break:
			print("💥 ESCUDO QUEBROU!")
			
			if is_instance_valid(current_shield_owner):
				if current_shield_owner.has_method("deactivate_shield_buff"):
					current_shield_owner.deactivate_shield_buff()
			
			# Reseta contadores
			shield_reflection_count = 0
			current_shield_owner = null
			
			# Opcional: Efeito visual/sonoro de quebra
			# AudioManager.play("shield_break")

# ============================================================
# FUNÇÃO PÚBLICA: Reseta contador ao ativar novo escudo
# ============================================================
# Chame isso do seu script de Player quando pegar um novo item de escudo
static func reset_shield_durability(new_owner):
	shield_reflection_count = 0
	current_shield_owner = new_owner
	print("🆕 Novo escudo ativado! Durabilidade resetada.")

# ============================================================
# EXECUÇÃO INDIVIDUAL
# ============================================================

func _execute_reflection(player_ref, is_perfect: bool):
	is_reflected = true
	
	var mouse_pos = get_global_mouse_position()
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	direction = (mouse_pos - (global_position + random_offset)).normalized()
	rotation = direction.angle() + PI/2
	
	# Muda camadas de colisão
	set_collision_mask_value(1, false) 
	set_collision_mask_value(2, true)
	time_alive = 0.0
	
	if is_perfect:
		speed *= 2.5
		damage = 2 # Dano bônus em perfect parry
		if sprite: 
			sprite.modulate = Color(2, 1.5, 0)
			sprite.scale = Vector2(2.0, 2.0)
			create_tween().tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
	else:
		speed *= 1.5
		if sprite:
			sprite.modulate = Color(0, 1, 1)
			sprite.scale = Vector2(1.5, 1.5)
			create_tween().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)

func _deal_damage_and_destroy(target):
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	create_hit_effect()
	queue_free()

func create_hit_effect():
	pass
