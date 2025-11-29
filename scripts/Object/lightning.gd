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
# GERENCIAMENTO DE SIMULTANEIDADE (STATIC)
# ============================================================
# Estas variáveis são compartilhadas por TODOS os raios no jogo
static var is_parry_event_active: bool = false
static var pending_projectiles: Array = [] 

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
	# Se estivermos em evento de parry, ninguém se mexe
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
	# Se já fui refletido, ajo como projétil do player
	if is_reflected:
		if target.has_method("take_damage") and target.is_in_group("angry_cloud"):
			target.take_damage(1)
			create_hit_effect()
			queue_free()
		return

	# Colisão com PLAYER
	if target.is_in_group("player"):
		# 1. Se o player tem escudo, entramos na lógica de Parry
		if target.has_method("has_shield_active") and target.has_shield_active():
			_register_for_parry(target)
		else:
			# Sem escudo = Dano
			_deal_damage_and_destroy(target)
		return
	
	# Paredes/Chão
	if target is TileMap or target.is_in_group("terrain"):
		create_hit_effect()
		queue_free()

# ============================================================
# LÓGICA DE PARRY EM GRUPO (CORRIGIDA)
# ============================================================

func _register_for_parry(player_ref):
	# Adiciona este raio atual à lista de espera
	if not self in pending_projectiles:
		pending_projectiles.append(self)
	
	# Se JÁ existe um evento de parry rolando (iniciado por outro raio milissegundos antes),
	# eu não faço nada. Apenas fico na lista esperando o Líder resolver.
	if is_parry_event_active:
		return

	# Se não existe evento, EU sou o Líder. Eu inicio o loop.
	_start_parry_leader_logic(player_ref)

func _start_parry_leader_logic(player_ref):
	is_parry_event_active = true
	
	var window_duration_ms = 300 # Aumentei um pouco para ser justo com múltiplos raios
	var perfect_threshold_ms = 120
	var reaction_success = false
	var is_perfect = false
	
	# Congela o Jogo
	var old_scale = Engine.time_scale
	Engine.time_scale = 0.05
	
	# Feedback Visual em TODOS os raios que estão batendo agora
	for p in pending_projectiles:
		if is_instance_valid(p) and p.sprite:
			p.sprite.modulate = Color(3, 3, 3) # Todos piscam branco
	
	var start_time = Time.get_ticks_msec()
	
	# Loop de Input
	while Time.get_ticks_msec() - start_time < window_duration_ms:
		if Input.is_action_just_pressed("PARRY"):
			reaction_success = true
			if Time.get_ticks_msec() - start_time <= perfect_threshold_ms:
				is_perfect = true
			break
		
		await get_tree().process_frame
	
	# Restaura o Jogo
	Engine.time_scale = 1.0 # Força 1.0 sempre
	is_parry_event_active = false # Libera a trava para futuros eventos
	
	# Resolve o destino de TODOS os raios na lista
	_resolve_all_pending_projectiles(player_ref, reaction_success, is_perfect)

func _resolve_all_pending_projectiles(player_ref, success: bool, perfect: bool):
	var hit_count = 0
	
	for bolt in pending_projectiles:
		if is_instance_valid(bolt):
			if success:
				bolt._execute_reflection(player_ref, perfect)
				hit_count += 1
			else:
				bolt._deal_damage_and_destroy(player_ref)
	
	pending_projectiles.clear()
	
	# === LÓGICA DE QUEBRA DE ESCUDO ===
	# Se refletiu pelo menos 1 raio, o escudo sobrecarrega e quebra
	if success and hit_count > 0:
		print("🛡️ Escudo sobrecarregou e quebrou!")
		
		if player_ref and player_ref.has_method("deactivate_shield_buff"):
			player_ref.deactivate_shield_buff()
			
			# Feedback Visual Opcional: Tocar som de vidro quebrando
			# if AudioSystem: AudioSystem.play("shield_break")
# ============================================================
# EXECUÇÃO INDIVIDUAL (Chamada pelo Líder)
# ============================================================

func _execute_reflection(player_ref, is_perfect: bool):
	is_reflected = true
	
	# Só aplica Screen Shake uma vez (opcional, para não tremer demais se forem 5 raios)
	# Mas se quiser caos, deixe o shake aqui mesmo.
	
	var mouse_pos = get_global_mouse_position()
	# Pequena variação para eles não ficarem 100% sobrepostos visualmente
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	direction = (mouse_pos - (global_position + random_offset)).normalized()
	rotation = direction.angle() + PI/2
	
	set_collision_mask_value(1, false) 
	set_collision_mask_value(2, true)
	time_alive = 0.0
	
	if is_perfect:
		speed *= 2.5
		if sprite: 
			sprite.modulate = Color(2, 1.5, 0) # Dourado
			sprite.scale = Vector2(2.0, 2.0)
			create_tween().tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
	else:
		speed *= 1.5
		if sprite:
			sprite.modulate = Color(0, 1, 1) # Ciano
			sprite.scale = Vector2(1.5, 1.5)
			create_tween().tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
			create_tween().tween_property(sprite, "modulate", Color(0, 1, 1), 0.2)

func _deal_damage_and_destroy(target):
	# Para evitar que x raios dêem x de dano instantâneo (Hitkill injusto),
	# verificamos se o player já está invencível.
	# Seu script de Player já tem lógica de invencibilidade, então isso aqui é seguro:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	create_hit_effect()
	queue_free()

func create_hit_effect():
	pass
