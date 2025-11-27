extends Node2D

# ========================================
# CONFIGURAÇÕES GERAIS
# ========================================
@export_group("Sistema de Divisão")
@export var angry_cloud: CharacterBody2D
@export var enable_split_system: bool = true
@export var split_interval: float = 30.0 
@export var split_duration: float = 15.0 
@export var mini_cloud_count: int = 5   
@export var mini_cloud_scale: float = 0.5
@export var mini_cloud_hits_to_die: int = 3 # Quantos raios para matar uma mini

@export_group("Itens e PowerUps")
@export var consumable_powerup_scene: PackedScene # O item de cura/buff normal
@export var shield_item_scene: PackedScene        # O NOVO item de escudo (refletor)
@export var consumable_spawn_interval: float = 60.0
@export var consumable_lifetime: float = 15.0
@export var consumable_spawn_positions: Array[Marker2D] = []
@export var consumable_item_scale: Vector2 = Vector2(0.3, 0.3)
@export var shield_item_scale: Vector2 = Vector2(0.4, 0.4)
@export var force_items_visible: bool = true # Força visibilidade dos items ao spawnar
@export var debug_spawn_logs: bool = true # Ativa/desativa logs detalhados de spawn
@export var use_safe_spawn_fallback: bool = true # Se true, usa centro da tela em caso de erro
@export_range(0.1, 1.0) var jump_height_factor: float = 0.7 # Usa 70% da altura do pulo (Segurança)
@export var floor_margin_from_screen_bottom: float = 150.0 # Ignora chão se estiver a menos de X pixels do fundo
@export_range(0.0, 0.5) var viewport_spawn_y_min_percent: float = 0.3 # Spawn mínimo: 30% da tela de cima
@export_range(0.5, 1.0) var viewport_spawn_y_max_percent: float = 0.7 # Spawn máximo: 70% da tela de cima

# ========================================
# VARIÁVEIS INTERNAS
# ========================================
# Controle de Tempo e Estado
var split_timer: float = 0.0
var is_split: bool = false
var split_cooldown: float = 0.0
var mini_clouds: Array[CharacterBody2D] = []

# Controle de Itens
var consumable_timer: float = 0.0
var current_consumable: Node2D = null
var current_shield_item: Node2D = null # Referência para o item de escudo no chão
var first_frame_passed: bool = false # Flag para evitar spawn no primeiro frame

# Controle de Vitória
var total_clouds_to_win: int = 5
var clouds_defeated_count: int = 0

func _ready():
	# Validações iniciais (Mantidas do seu script)
	if not angry_cloud:
		push_warning("MinigameManager: AngryCloud não encontrada! Sistema de divisão desativado.")
		enable_split_system = false
	else:
		if not angry_cloud.is_in_group("angry_cloud"):
			angry_cloud.add_to_group("angry_cloud")
		print("✅ AngryCloud configurada.")
	
	# Garante que o número de nuvens seja 5 para a mecânica de vitória
	total_clouds_to_win = mini_cloud_count
	
	split_cooldown = split_interval
	consumable_timer = consumable_spawn_interval
	
	print("=== INICIANDO MINIGAME ===")
	print("Intervalo Divisão: %.1fs | Duração: %.1fs" % [split_interval, split_duration])

func _physics_process(delta):
	# Marca que passou pelo menos um frame (evita spawn com câmera não inicializada)
	if not first_frame_passed:
		first_frame_passed = true
		return
	
	# Debug periódico
	if int(Time.get_ticks_msec() / 1000) % 5 == 0 and Engine.get_physics_frames() % 60 == 0:
		print("Status: Cooldown=%.1fs | IsSplit=%s | Defeated=%d/%d" % [split_cooldown, is_split, clouds_defeated_count, total_clouds_to_win])
	
	# Lógica da Máquina de Estados
	if not is_split and enable_split_system:
		_update_waiting_phase(delta)
	elif is_split:
		_update_split_phase(delta)
	
	# O sistema de consumable (cura) roda independente da divisão
	_update_consumable_system(delta)

# ========================================
# FASE 1: ESPERANDO DIVISÃO (BOSS GRANDE)
# ========================================
func _update_waiting_phase(delta):
	split_cooldown -= delta
	
	if split_cooldown <= 0:
		print("⏰ Hora da divisão!")
		_split_angry_cloud()
		split_cooldown = split_interval

# ========================================
# FASE 2: DIVISÃO (ATAQUE/MINI CLOUDS)
# ========================================
func _update_split_phase(delta):
	split_timer -= delta
	
	# Se o tempo acabar, reúne as nuvens (se o jogador não tiver vencido ainda)
	if split_timer <= 0:
		_merge_clouds()

func _split_angry_cloud():
	if not angry_cloud or not is_instance_valid(angry_cloud): return
	if is_split: return
	
	print("=== INICIANDO FASE DE DIVISÃO ===")
	
	is_split = true
	split_timer = split_duration
	
	# 1. Esconde Boss Principal
	var original_position = angry_cloud.global_position
	var original_scale = angry_cloud.scale
	var init_lightning_scale = angry_cloud.lightning_scale
	
	angry_cloud.visible = false
	angry_cloud.set_physics_process(false)
	
	# 2. Spawna o Item de Escudo (Shield)
	_spawn_shield_item()
	
	# 3. Cria as Mini Nuvens
	var clouds_alive_spawned = 0
	var clouds_needed = total_clouds_to_win - clouds_defeated_count
	
	# Se já matamos todas (improvável cair aqui sem vencer, mas por segurança)
	if clouds_needed <= 0:
		_game_win()
		return
		
	# Lógica de distribuição circular
	var angle_step = TAU / mini_cloud_count # Mantém distribuição uniforme de 5 posições
	var spawn_radius = 150.0
	var base_path_index = angry_cloud.current_path_index
	var total_paths = angry_cloud.paths.size()
	
	# Loop fixo em mini_cloud_count para manter posições, mas só spawna as vivas
	for i in range(mini_cloud_count):
		# Se já spawnamos todas que faltam, as posições restantes ficam vazias
		if clouds_alive_spawned >= clouds_needed:
			break
			
		var mini_cloud = angry_cloud.duplicate()
		add_child(mini_cloud)
		
		# --- CONFIGURAÇÃO DE COMBATE (NOVO) ---
		mini_cloud.max_health = mini_cloud_hits_to_die
		mini_cloud.current_health = mini_cloud_hits_to_die
		
		# Conecta sinal de morte customizado
		if not mini_cloud.has_user_signal("cloud_died"):
			mini_cloud.add_user_signal("cloud_died")
		mini_cloud.connect("cloud_died", Callable(self, "_on_mini_cloud_defeated"))
		# --------------------------------------
		
		# Configuração Visual e de Movimento
		mini_cloud.scale = original_scale * mini_cloud_scale
		mini_cloud.lightning_scale = init_lightning_scale * mini_cloud_scale
		
		var angle = angle_step * i
		var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
		mini_cloud.global_position = original_position + offset
		
		mini_cloud.visible = true
		mini_cloud.set_physics_process(true)
		
		if total_paths > 1:
			var new_path_index = (base_path_index + i + 1) % total_paths
			mini_cloud.force_path_change(new_path_index)
		
		# Ajuste de dificuldade das minis
		mini_cloud.speed *= 1.3
		mini_cloud.lightning_spawn_interval *= 0.7
		
		mini_clouds.append(mini_cloud)
		clouds_alive_spawned += 1
	
	print("✅ %d Mini nuvens geradas. Restam %d para vencer." % [mini_clouds.size(), clouds_needed])

func _merge_clouds():
	if not is_split: return
	
	print("=== FIM DA DIVISÃO (Reunindo) ===")
	
	# 1. Remove Mini Nuvens restantes
	for mini_cloud in mini_clouds:
		if is_instance_valid(mini_cloud):
			mini_cloud.queue_free()
	mini_clouds.clear()
	
	# 2. Remove o Shield Item se ninguém pegou
	if is_instance_valid(current_shield_item):
		current_shield_item.queue_free()
		current_shield_item = null
	
	# 3. Remove o Buff do Player (O escudo só dura na divisão)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("deactivate_shield_buff"):
		player.deactivate_shield_buff()
		print("🛡️ Escudo do player desativado pela união das nuvens.")
	
	# 4. Restaura Boss Principal
	if angry_cloud and is_instance_valid(angry_cloud):
		angry_cloud.visible = true
		angry_cloud.set_physics_process(true)
		
		# Animaçãozinha visual (feedback)
		var original_scale = angry_cloud.scale # Atenção: certifique-se que angry_cloud.scale está em 1.0 ou valor base
		var tween = create_tween()
		tween.tween_property(angry_cloud, "scale", original_scale * 1.2, 0.3)
		tween.tween_property(angry_cloud, "scale", original_scale, 0.2)
	
	is_split = false

# ========================================
# LÓGICA DE COMBATE E VITÓRIA
# ========================================
func _spawn_shield_item():
	if not shield_item_scene:
		push_warning("⚠️ Shield Item Scene não configurada!")
		return
		
	var spawn_pos = _get_random_consumable_position()
	
	current_shield_item = shield_item_scene.instantiate()
	
	# 1. Adiciona à cena PRIMEIRO (para não perder propriedades)
	get_tree().current_scene.add_child(current_shield_item)
	
	# 2. DEPOIS configura posição e escala
	current_shield_item.global_position = spawn_pos
	
	# 3. Aplica escala de forma SEGURA
	if shield_item_scale != Vector2.ONE:
		# Aguarda um frame para garantir que o _ready() do item rodou
		await get_tree().process_frame
		current_shield_item.scale = shield_item_scale
		
		# APLICA ESCALA TAMBÉM NO SPRITE (CRÍTICO!)
		if current_shield_item.has_node("Sprite2D"):
			var sprite = current_shield_item.get_node("Sprite2D")
			sprite.scale = Vector2.ONE  # Reseta escala do sprite
		elif current_shield_item.has_node("AnimatedSprite2D"):
			var anim_sprite = current_shield_item.get_node("AnimatedSprite2D")
			anim_sprite.scale = Vector2.ONE  # Reseta escala do sprite
		
		if debug_spawn_logs:
			print("   ⚙️ Escala aplicada após 1 frame: %s" % current_shield_item.scale)
	
	# 4. FORÇA VISIBILIDADE
	current_shield_item.visible = true
	current_shield_item.show()
	
	# 5. LOG DE DEBUG COMPLETO
	if debug_spawn_logs:
		print("🛡️ Shield Item spawnado:")
		print("   Posição: %s" % spawn_pos)
		print("   Escala configurada: %s" % shield_item_scale)
		print("   Escala final: %s" % current_shield_item.scale)
		print("   Visible: %s" % current_shield_item.visible)
		
		# 6. Verifica se tem sprite
		if current_shield_item.has_node("Sprite2D"):
			var sprite = current_shield_item.get_node("Sprite2D")
			print("   Sprite - Visible: %s | Texture: %s | Scale: %s" % [sprite.visible, sprite.texture != null, sprite.scale])
		elif current_shield_item.has_node("AnimatedSprite2D"):
			var anim_sprite = current_shield_item.get_node("AnimatedSprite2D")
			print("   AnimatedSprite - Playing: %s | Scale: %s" % [anim_sprite.is_playing(), anim_sprite.scale])
			if not anim_sprite.is_playing():
				anim_sprite.play()
		else:
			push_warning("⚠️ Shield Item não tem Sprite2D nem AnimatedSprite2D!")
	else:
		print("🛡️ Shield Item spawnado em: %s" % spawn_pos)

func _on_mini_cloud_defeated(dead_cloud):
	# Remove da lista local
	mini_clouds.erase(dead_cloud)
	
	clouds_defeated_count += 1
	print("☠️ Mini Cloud destruída! Progresso: %d/%d" % [clouds_defeated_count, total_clouds_to_win])
	
	# Checa vitória
	if clouds_defeated_count >= total_clouds_to_win:
		_game_win()
	else:
		# Lógica de "Horda": As sobreviventes ficam mais fortes
		print("⚡ Aumentando dificuldade das restantes...")
		for cloud in mini_clouds:
			if is_instance_valid(cloud) and cloud.has_method("increase_difficulty"):
				cloud.increase_difficulty(1) # +1 raio por nuvem morta

func _game_win():
	print("🏆 VITÓRIA! TODAS AS NUVENS FORAM DERROTADAS!")
	is_split = false
	enable_split_system = false # Para o loop
	
	# Limpa tudo
	for cloud in mini_clouds:
		if is_instance_valid(cloud): cloud.queue_free()
	
	if is_instance_valid(angry_cloud):
		angry_cloud.queue_free()
		
	if is_instance_valid(current_shield_item):
		current_shield_item.queue_free()
		
	# AQUI VOCÊ CHAMA SEU GAMEMANAGER
	if GameManager and GameManager.has_method("level_complete"):
		GameManager.level_complete()

# ========================================
# SISTEMA DE CONSUMABLE
# ========================================
func _update_consumable_system(delta):
	if not consumable_powerup_scene: return
	
	consumable_timer -= delta
	if consumable_timer <= 0 and not current_consumable:
		_spawn_consumable()
		consumable_timer = consumable_spawn_interval

func _spawn_consumable():
	if current_consumable and is_instance_valid(current_consumable): return
	
	var spawn_pos = _get_random_consumable_position()
	
	current_consumable = consumable_powerup_scene.instantiate()
	
	# 1. Adiciona à cena PRIMEIRO
	get_tree().current_scene.add_child(current_consumable)
	
	# 2. DEPOIS configura posição
	current_consumable.global_position = spawn_pos
	
	# 3. Configura lifetime se existir
	if "lifetime" in current_consumable:
		current_consumable.lifetime = consumable_lifetime
	
	# 4. Conecta sinal
	if current_consumable.has_signal("collected"):
		current_consumable.collected.connect(func(): current_consumable = null)
	
	# 5. Aplica escala de forma SEGURA
	if consumable_item_scale != Vector2.ONE:
		await get_tree().process_frame
		current_consumable.scale = consumable_item_scale
		
		# APLICA ESCALA TAMBÉM NO SPRITE (CRÍTICO!)
		if current_consumable.has_node("Sprite2D"):
			var sprite = current_consumable.get_node("Sprite2D")
			sprite.scale = Vector2.ONE  # Reseta escala do sprite
		elif current_consumable.has_node("AnimatedSprite2D"):
			var anim_sprite = current_consumable.get_node("AnimatedSprite2D")
			anim_sprite.scale = Vector2.ONE  # Reseta escala do sprite
		
		if debug_spawn_logs:
			print("   ⚙️ Escala aplicada após 1 frame: %s" % current_consumable.scale)
	
	# 6. FORÇA VISIBILIDADE
	current_consumable.visible = true
	current_consumable.show()
	
	# 7. LOG DE DEBUG COMPLETO
	if debug_spawn_logs:
		print("🍎 Consumable spawnado:")
		print("   Posição: %s" % spawn_pos)
		print("   Escala configurada: %s" % consumable_item_scale)
		print("   Escala final: %s" % current_consumable.scale)
		print("   Visible: %s" % current_consumable.visible)
		
		# 8. Verifica sprite
		if current_consumable.has_node("Sprite2D"):
			var sprite = current_consumable.get_node("Sprite2D")
			print("   Sprite - Visible: %s | Texture: %s | Scale: %s" % [sprite.visible, sprite.texture != null, sprite.scale])
			if sprite.texture == null:
				push_warning("⚠️ Sprite2D SEM TEXTURE! Verifique a cena do consumable.")
		elif current_consumable.has_node("AnimatedSprite2D"):
			var anim_sprite = current_consumable.get_node("AnimatedSprite2D")
			print("   AnimatedSprite - Playing: %s | Scale: %s" % [anim_sprite.is_playing(), anim_sprite.scale])
			if not anim_sprite.is_playing():
				anim_sprite.play()
		else:
			push_warning("⚠️ Consumable não tem Sprite2D nem AnimatedSprite2D!")
		
		# 9. Verifica colisão
		if current_consumable.has_node("CollisionShape2D"):
			var collision = current_consumable.get_node("CollisionShape2D")
			print("   CollisionShape2D - Disabled: %s | Scale: %s" % [collision.disabled, collision.scale])
			if collision.shape:
				print("   Shape type: %s" % collision.shape.get_class())
		elif current_consumable.has_node("Area2D/CollisionShape2D"):
			var collision = current_consumable.get_node("Area2D/CollisionShape2D")
			print("   Area2D/CollisionShape2D - Disabled: %s" % collision.disabled)
	else:
		print("🍎 Consumable spawnado em: %s" % spawn_pos)

# ========================================
# SISTEMA DE SPAWN POSITION (COMPLETO)
# ========================================
func _get_safe_fallback_position() -> Vector2:
	"""Retorna uma posição segura no centro visível da tela"""
	var camera = get_viewport().get_camera_2d()
	if camera:
		var cam_pos = camera.global_position
		# Spawna ligeiramente acima do centro
		return cam_pos + Vector2(randf_range(-100, 100), -80)
	else:
		var viewport = get_viewport().get_visible_rect()
		return viewport.get_center() + Vector2(0, -100)

func _get_random_consumable_position() -> Vector2:
	# 1. Se tiver Marker2D, usa (Prioridade máxima)
	if consumable_spawn_positions.size() > 0:
		var marker = consumable_spawn_positions[randi() % consumable_spawn_positions.size()]
		return marker.global_position
	
	# ---------------------------------------------------------
	# 2. OBTER ÁREA VISÍVEL DA CÂMERA (CORRIGIDO)
	# ---------------------------------------------------------
	var camera = get_viewport().get_camera_2d()
	
	if not camera:
		push_warning("⚠️ Câmera não encontrada! Usando fallback.")
		return _get_safe_fallback_position()
	
	# Obtém a área REAL visível na tela em coordenadas globais
	var cam_pos = camera.global_position
	var zoom = camera.zoom
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Calcula o retângulo visível em world coordinates
	var visible_size = viewport_size / zoom
	var viewport_rect = Rect2(
		cam_pos - (visible_size / 2.0),
		visible_size
	)
	
	# DEBUG: Imprime informações da câmera
	if debug_spawn_logs:
		print("🎥 Câmera - Pos: %s | Zoom: %s | VisibleRect: %s" % [cam_pos, zoom, viewport_rect])
	
	# ---------------------------------------------------------
	# 3. ESCOLHER X ALEATÓRIO COM VALIDAÇÃO (DENTRO DA TELA VISÍVEL)
	# ---------------------------------------------------------
	# Garante que spawna apenas na área REALMENTE visível
	var margin = 100.0
	
	# Calcula limites REAIS da tela (apenas área positiva visível)
	var screen_left = max(viewport_rect.position.x, 0.0) + margin
	var screen_right = min(viewport_rect.end.x, viewport_rect.size.x) - margin
	
	# Se viewport está com coordenadas estranhas, usa valores absolutos seguros
	if screen_left < 0 or screen_right <= screen_left:
		push_warning("⚠️ Viewport com coordenadas inválidas! Usando valores seguros.")
		screen_left = margin
		screen_right = 1280.0 - margin  # Resolução padrão
	
	var x_pos = randf_range(screen_left, screen_right)
	
	# LOG de debug do X
	if debug_spawn_logs:
		print("🎯 X escolhido: %.1f (Limites SEGUROS: %.1f a %.1f)" % [x_pos, screen_left, screen_right])
	
	# ---------------------------------------------------------
	# 4. RAYCAST: ENCONTRAR O CHÃO DENTRO DA ÁREA VISÍVEL
	# ---------------------------------------------------------
	var space_state = get_world_2d().direct_space_state
	
	# IMPORTANTE: Raycast só dentro da área visível + pequena margem
	var ray_origin = Vector2(x_pos, viewport_rect.position.y - 50)
	var ray_end = Vector2(x_pos, viewport_rect.end.y + 50)
	
	var query = PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	var floor_y_real = 0.0
	var use_floor_reference = false
	
	if result:
		floor_y_real = result.position.y
		if debug_spawn_logs:
			print("✅ Chão encontrado em Y: %.1f" % floor_y_real)
		
		# VALIDAÇÃO CRÍTICA: O chão está BEM DENTRO da área visível?
		# Se o chão está muito próximo do fundo da tela, ignora ele
		if floor_y_real > (viewport_rect.end.y - floor_margin_from_screen_bottom):
			push_warning("⚠️ Chão muito próximo do fundo (%.1f > %.1f)! Usando viewport como referência." % 
				[floor_y_real, viewport_rect.end.y - floor_margin_from_screen_bottom])
			use_floor_reference = false
		elif floor_y_real < viewport_rect.position.y:
			push_warning("⚠️ Chão acima da viewport! Usando viewport como referência.")
			use_floor_reference = false
		else:
			use_floor_reference = true
	else:
		push_warning("❌ Raycast não encontrou chão! Usando viewport como referência.")
		use_floor_reference = false

	# ---------------------------------------------------------
	# 5. CÁLCULO DA ALTURA DO PULO (BASEADO NO PLAYER)
	# ---------------------------------------------------------
	var calculated_jump_height = 150.0 # Valor padrão conservador
	var player = get_tree().get_first_node_in_group("player")
	
	if player and "JUMP_VELOCITY" in player:
		var gravity = 980.0
		# Tenta pegar gravidade exata
		if player.has_method("get_gravity"): 
			gravity = player.get_gravity().y
		elif ProjectSettings.has_setting("physics/2d/default_gravity"):
			gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
			
		if gravity > 0:
			var jump_v = abs(player.JUMP_VELOCITY)
			# Fórmula física: Altura = V² / 2g
			calculated_jump_height = (jump_v * jump_v) / (2.0 * gravity)
			if debug_spawn_logs:
				print("🎯 Jump calculado: %.1f px (Velocity: %.1f | Gravity: %.1f)" % [calculated_jump_height, jump_v, gravity])
	
	# TRAVA DE SEGURANÇA 1: Fator de porcentagem (ex: 70% do pulo máximo)
	calculated_jump_height *= jump_height_factor
	
	# TRAVA DE SEGURANÇA 2: Limite absoluto em pixels
	var max_pixel_limit = 200.0 
	if calculated_jump_height > max_pixel_limit:
		calculated_jump_height = max_pixel_limit
	
	# Define altura mínima do chão (para não spawnar colado no pé)
	var min_height_from_floor = 40.0
	
	# Garante que min < max
	if calculated_jump_height < min_height_from_floor:
		calculated_jump_height = min_height_from_floor + 10.0

	# ---------------------------------------------------------
	# 6. POSIÇÃO FINAL - BASEADA NA VIEWPORT OU NO CHÃO
	# ---------------------------------------------------------
	var final_pos: Vector2
	
	if use_floor_reference:
		# Caso 1: Chão está bem posicionado, spawna relativo a ele
		var random_height = randf_range(min_height_from_floor, calculated_jump_height)
		final_pos = Vector2(x_pos, floor_y_real - random_height)
		
		# Garante que não passou do topo da viewport
		if final_pos.y < viewport_rect.position.y:
			final_pos.y = viewport_rect.position.y + 50
		
		if debug_spawn_logs:
			print("✅ Spawn (relativo ao chão): %s (Chão: %.1f | Altura: %.1f)" % [final_pos, floor_y_real, random_height])
	else:
		# Caso 2: Chão inútil, spawna dentro da viewport
		# Define área segura usando as porcentagens configuradas
		var safe_y_min = viewport_rect.position.y + (viewport_rect.size.y * viewport_spawn_y_min_percent)
		var safe_y_max = viewport_rect.position.y + (viewport_rect.size.y * viewport_spawn_y_max_percent)
		
		final_pos = Vector2(x_pos, randf_range(safe_y_min, safe_y_max))
		if debug_spawn_logs:
			print("✅ Spawn (baseado na viewport): %s | Área segura: %.1f a %.1f" % [final_pos, safe_y_min, safe_y_max])
	
	return final_pos

# ========================================
# FUNÇÕES DEBUG
# ========================================
func force_split():
	if not is_split: _split_angry_cloud()

func force_merge():
	if is_split: split_timer = 0
