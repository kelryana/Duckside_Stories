extends Node2D

# ========================================
# CONFIGURAÇÕES
# ========================================
@export_group("Sistema de Divisão")
@export var angry_cloud: CharacterBody2D
@export var enable_split_system: bool = true
@export var split_interval: float = 30.0 
@export var split_duration: float = 15.0 
@export var mini_cloud_count: int = 5    
@export var mini_cloud_scale: float = 0.5
@export var mini_cloud_hits_to_die: int = 10

@export_group("Itens e PowerUps")
@export var consumable_powerup_scene: PackedScene
@export var shield_item_scene: PackedScene
@export var consumable_spawn_interval: float = 60.0
@export var consumable_lifetime: float = 15.0
@export var consumable_item_scale: Vector2 = Vector2(1.0, 1.0)
@export var shield_item_scale: Vector2 = Vector2(1.0, 1.0)

@export_group("Respawn de Escudos")
@export var min_shields_per_round: int = 1
@export var max_shields_per_round: int = 3
@export var shield_respawn_delay: float = 3.0 # Tempo que demora pro próximo aparecer


# Configuração de Altura baseada no Pulo do Player
@export_group("Física de Spawn")
#Defina isso no Inspector para a Layer do seu Chão (geralmente Layer 1)
@export_flags_2d_physics var floor_collision_mask: int = 1 
@export_range(0.70, 0.90) var jump_percent_min: float = 0.85
@export_range(0.90, 1.0) var jump_percent_max: float = 0.95
# ========================================
# VARIÁVEIS INTERNAS
# ========================================
var split_timer: float = 0.0
var split_cooldown: float = 0.0
var is_split: bool = false
var mini_clouds: Array[CharacterBody2D] = []

var consumable_timer: float = 0.0
var current_consumable: Node2D = null
var current_shield_item: Node2D = null 

var total_clouds_to_win: int = 5
var clouds_defeated_count: int = 0
var player_ref: CharacterBody2D = null

# Variáveis de Controle Interno
var current_shields_spawned: int = 0
var max_shields_this_round: int = 0
var shield_respawn_timer: float = 0.0

func _ready():
	# Busca referência do player para cálculos de física
	player_ref = get_tree().get_first_node_in_group("player")
	
	if not angry_cloud:
		push_warning("Minigame: AngryCloud não encontrada.")
		enable_split_system = false
	else:
		if not angry_cloud.is_in_group("angry_cloud"):
			angry_cloud.add_to_group("angry_cloud")

	total_clouds_to_win = mini_cloud_count
	split_cooldown = split_interval
	consumable_timer = consumable_spawn_interval

func _physics_process(delta):
	# Debug simplificado (roda a cada 3s aprox)
	if Engine.get_physics_frames() % 180 == 0:
		print("MiniGame Status: Split=%s | Defeated=%d/%d" % [is_split, clouds_defeated_count, total_clouds_to_win])
	
	if not is_split and enable_split_system:
		split_cooldown -= delta
		if split_cooldown <= 0:
			_split_angry_cloud()
			split_cooldown = split_interval
			
	elif is_split:
		split_timer -= delta
		_update_shield_respawn_logic(delta)
		if split_timer <= 0:
			_merge_clouds()
	
	_update_consumable_system(delta)

# ========================================
# LÓGICA DE DIVISÃO (BOSS)
# ========================================
func _split_angry_cloud():
	if not is_instance_valid(angry_cloud) or is_split: return
	
	print("=== DIVISÃO INICIADA ===")
	is_split = true
	split_timer = split_duration
	
	# Esconde Boss
	var original_pos = angry_cloud.global_position
	var original_scale = angry_cloud.scale
	var lightning_scale = angry_cloud.lightning_scale
	
	angry_cloud.visible = false
	angry_cloud.set_physics_process(false)
	
	# --- CONFIGURAÇÃO DO RESPAWN ---
	current_shields_spawned = 0
	max_shields_this_round = randi_range(min_shields_per_round, max_shields_per_round)
	shield_respawn_timer = 0.0 # O primeiro spawna instantâneo
	print("Esta rodada terá %d escudos!" % max_shields_this_round)
	
	# Spawna Mini Nuvens
	var clouds_needed = total_clouds_to_win - clouds_defeated_count
	if clouds_needed <= 0:
		_game_win()
		return
		
	var angle_step = TAU / mini_cloud_count
	var clouds_spawned = 0
	
	for i in range(mini_cloud_count):
		if clouds_spawned >= clouds_needed: break
			
		var mini = angry_cloud.duplicate()
		add_child(mini)
		
		mini.max_health = mini_cloud_hits_to_die
		mini.current_health = mini_cloud_hits_to_die
		
		if not mini.has_user_signal("cloud_died"):
			mini.add_user_signal("cloud_died")
		mini.connect("cloud_died", Callable(self, "_on_mini_cloud_defeated"))
		
		mini.scale = original_scale * mini_cloud_scale
		mini.lightning_scale = lightning_scale * mini_cloud_scale
		
		# Distribuição circular
		var angle = angle_step * i
		var offset = Vector2(cos(angle), sin(angle)) * 150.0
		mini.global_position = original_pos + offset
		
		mini.visible = true
		mini.set_physics_process(true)
		
		# Ajuste path
		if angry_cloud.paths.size() > 1:
			mini.force_path_change((angry_cloud.current_path_index + i + 1) % angry_cloud.paths.size())
		
		mini_clouds.append(mini)
		clouds_spawned += 1

func _merge_clouds():
	if not is_split: return
	print("=== FIM DA DIVISÃO ===")
	
	for mini in mini_clouds:
		if is_instance_valid(mini): mini.queue_free()
	mini_clouds.clear()
	
	if is_instance_valid(current_shield_item):
		current_shield_item.queue_free()
	
	if player_ref and player_ref.has_method("deactivate_shield_buff"):
		player_ref.deactivate_shield_buff()
	
	if is_instance_valid(angry_cloud):
		angry_cloud.visible = true
		angry_cloud.set_physics_process(true)
		
		var tw = create_tween()
		tw.tween_property(angry_cloud, "scale", angry_cloud.scale * 1.2, 0.3)
		tw.tween_property(angry_cloud, "scale", angry_cloud.scale, 0.2)
	
	is_split = false

func _on_mini_cloud_defeated(dead_cloud):
	mini_clouds.erase(dead_cloud)
	clouds_defeated_count += 1
	
	if clouds_defeated_count >= total_clouds_to_win:
		_game_win()
	else:
		for cloud in mini_clouds:
			if is_instance_valid(cloud) and cloud.has_method("increase_difficulty"):
				cloud.increase_difficulty(1)

func _game_win():
	print("🏆 VITÓRIA!")
	is_split = false
	enable_split_system = false
	
	for c in mini_clouds: if is_instance_valid(c): c.queue_free()
	if is_instance_valid(angry_cloud): angry_cloud.queue_free()
	if is_instance_valid(current_shield_item): current_shield_item.queue_free()
		
	if GameManager and GameManager.has_method("level_complete"):
		GameManager.level_complete()

# ========================================
# SISTEMA DE ITENS GENÉRICO
# ========================================
func _update_consumable_system(delta):
	if not consumable_powerup_scene: return
	
	consumable_timer -= delta
	if consumable_timer <= 0 and not is_instance_valid(current_consumable):
		_spawn_item(consumable_powerup_scene, consumable_item_scale, false)
		consumable_timer = consumable_spawn_interval

func _spawn_item(scene: PackedScene, scale_vec: Vector2, is_shield: bool):
	var pos = _calculate_reachable_position()
	var item = scene.instantiate()
	
	item.global_position = pos
	item.scale = scale_vec
	
	if not is_shield and "lifetime" in item:
		item.lifetime = consumable_lifetime
		
	get_tree().current_scene.add_child(item)
	
	if is_shield:
		current_shield_item = item
	else:
		current_consumable = item
		if item.has_signal("collected"):
			item.collected.connect(func(): current_consumable = null)
			
	print("Item spawnado em: %s (Is Shield: %s)" % [pos, is_shield])

func _update_shield_respawn_logic(delta):
	# 1. Verifica se já atingimos o limite de escudos desta rodada
	if current_shields_spawned >= max_shields_this_round:
		return

	# 2. Verifica se JÁ existe um item de escudo no chão (não spawna outro)
	if is_instance_valid(current_shield_item):
		return
		
	# 3. Verifica se o PLAYER já está com o buff ativo (não spawna se ele já tem)
	if player_ref and player_ref.has_method("has_shield_active"):
		if player_ref.has_shield_active():
			# Reseta o timer para garantir que haja um delay APÓS perder o escudo
			shield_respawn_timer = shield_respawn_delay 
			return

	# 4. Contagem regressiva para spawnar
	shield_respawn_timer -= delta
	
	if shield_respawn_timer <= 0:
		_spawn_next_shield()

func _spawn_next_shield():
	_spawn_item(shield_item_scene, shield_item_scale, true)
	current_shields_spawned += 1
	print("🛡️ Escudo %d/%d spawnado!" % [current_shields_spawned, max_shields_this_round])
	
	# Reseta timer para o próximo
	shield_respawn_timer = shield_respawn_delay
# ========================================
# DEBUG E VISUALIZAÇÃO
# ========================================
func _process(delta):
	if OS.has_feature("editor"):
		queue_redraw()

func _draw():
	if OS.has_feature("editor"):
		# Usamos to_local para garantir que o desenho alinhe com o Node atual
		var global_bounds = _get_active_camera_rect()
		var local_pos = to_local(global_bounds.position)
		var draw_bounds = Rect2(local_pos, global_bounds.size)
		
		# 1. Vermelho: Câmera Real
		draw_rect(draw_bounds, Color(1, 0, 0), false, 4.0)
		
		# 2. Verde: Zona Segura de Pulo (Visualização Ideal)
		# Essa área representa onde o item DEVE ficar após o clamp
		var max_h = _get_player_jump_height()
		var min_spawn_h = max_h * jump_percent_min
		var max_spawn_h = max_h * jump_percent_max
		
		var safe_rect = draw_bounds
		safe_rect.position.x += 80
		safe_rect.size.x -= 160
		
		# A zona verde começa do fundo da tela subindo
		# Nota: Isso é visual. Se tiver um buraco, o item não nasce aí, mas a altura será respeitada.
		safe_rect.position.y = draw_bounds.end.y - max_spawn_h - 50 # 50 de margem do chão
		safe_rect.size.y = (max_spawn_h - min_spawn_h)
		
		draw_rect(safe_rect, Color(0, 1, 0, 0.5), true)

# ========================================
# CÁLCULO DE POSIÇÃO (CORRIGIDO)
# ========================================
func _calculate_reachable_position() -> Vector2:
	var bounds = _get_active_camera_rect()
	
	# TRAVA DE SEGURANÇA 1: Se a tela ainda não carregou (size pequeno), aborta para evitar X=28
	if bounds.size.x < 200:
		return Vector2.ZERO 

	# 1. X (Horizontal)
	var margin_x = 80.0
	var min_x = bounds.position.x + margin_x
	var max_x = bounds.end.x - margin_x
	
	# Se a tela for muito estreita, centraliza
	if min_x >= max_x:
		min_x = bounds.position.x + (bounds.size.x * 0.5)
		max_x = min_x
		
	var x_pos = randf_range(min_x, max_x)
	
	# 2. Y (Vertical) - Buscando o Chão Físico
	var space_state = get_world_2d().direct_space_state
	
	# Lança o raio de cima para baixo
	var query = PhysicsRayQueryParameters2D.create(
		Vector2(x_pos, bounds.position.y), 
		Vector2(x_pos, bounds.end.y + 200) # Busca até um pouco abaixo da tela
	)
	query.collision_mask = floor_collision_mask # Importante: Só colide com o chão!
	
	var result = space_state.intersect_ray(query)
	
	var floor_y_real = bounds.end.y # Fallback: Se não achar chão, usa o fundo da tela
	if result:
		floor_y_real = result.position.y
		
	# 3. Calcula Altura do Pulo
	var max_jump_h = _get_player_jump_height()
	var jump_percent = randf_range(jump_percent_min, jump_percent_max)
	var spawn_height = max_jump_h * jump_percent
	
	var y_pos = floor_y_real - spawn_height
	
	# 4. CLAMP RIGOROSO (O Segredo para consertar o Y=723)
	# Forçamos o item a ficar DENTRO da zona verde visualizada, não importa o que o Raycast diga.
	
	var screen_bottom_limit = bounds.end.y - 50.0 # Nunca nasce colado no fundo (HUD/Chão)
	var screen_top_limit = bounds.position.y + (bounds.size.y * 0.15) # Nunca nasce no teto absoluto
	
	# Se o Raycast achou um buraco fundo, o item vai tentar nascer lá embaixo.
	# O Clamp vai puxá-lo de volta para a tela visível.
	y_pos = clamp(y_pos, screen_top_limit, screen_bottom_limit)

	return Vector2(x_pos, y_pos)

# Função Auxiliar de Câmera (Mantida igual pois funcionou bem)
func _get_active_camera_rect() -> Rect2:
	var viewport_rect = get_viewport_rect()
	var transform = get_canvas_transform().affine_inverse()
	var top_left = transform * Vector2.ZERO
	var bottom_right = transform * viewport_rect.size
	return Rect2(top_left, bottom_right - top_left)

func _get_player_jump_height() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return 0.0

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	# Se o player tiver gravidade customizada, usamos ela
	if "gravity" in player:
		gravity = player.gravity
	
	if gravity == 0:
		return 0.0
	
	# 1. Obtemos a Velocidade de Pulo definida no script do Player
	var raw_jump_vel = 600.0 # Valor default de segurança
	if "JUMP_VELOCITY" in player:
		raw_jump_vel = abs(player.JUMP_VELOCITY)
	
	# 2. LIMPEZA DE BUFFS (A lógica crítica para o Spawn)
	
	if "consumable_jump_multiplier" in player and player.consumable_jump_multiplier > 0.0:
		raw_jump_vel = raw_jump_vel / player.consumable_jump_multiplier
		pass 

	# 3. Cálculo da Altura Escalar Padrão (Física: h = v² / 2g)
	# Isso retorna a distância em pixels que o player consegue subir sem buffs.
	var clean_jump_height = (raw_jump_vel * raw_jump_vel) / (2.0 * gravity)
	
	return clean_jump_height
