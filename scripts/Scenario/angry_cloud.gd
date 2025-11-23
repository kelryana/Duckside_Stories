extends Node2D

# Configurações de divisão
@export_group("Sistema de Divisão")
@export var angry_cloud: CharacterBody2D  # Arraste AngryCloud aqui se não for detectada
@export var enable_split_system: bool = true
@export var split_interval: float = 30.0  # Divide a cada 20 segundos
@export var split_duration: float = 15.0  # Fica dividida por 10 segundos
@export var mini_cloud_count: int = 3
@export var mini_cloud_scale: float = 0.5  # 50% do tamanho original

# Configurações de Shield
@export_group("Sistema de Shield")
@export var shield_powerup_scene: PackedScene
@export var shield_spawn_interval: float = 60.0
@export var shield_duration: float = 5.0
@export var shield_spawn_positions: Array[Marker2D] = []  # Posições onde o shield pode aparecer

# Referências
var split_timer: float = 0.0
var is_split: bool = false
var split_cooldown: float = 0.0
var mini_clouds: Array[CharacterBody2D] = []

var shield_timer: float = 0.0
var current_shield: Node2D = null

func _ready():

	if not angry_cloud:
		push_warning("MinigameManager: AngryCloud não encontrada! Sistema de divisão desativado.")
		enable_split_system = false
	else:
		# Adiciona ao grupo para identificação
		if not angry_cloud.is_in_group("angry_cloud"):
			angry_cloud.add_to_group("angry_cloud")
		print("✅ AngryCloud configurada: %s" % angry_cloud.get_path())
	
	# Inicia timers
	split_cooldown = split_interval
	shield_timer = shield_spawn_interval
	
	print("Configuração:")
	print("  - Divisão ativa: %s (intervalo: %.1fs)" % [enable_split_system, split_interval])
	print("  - Shield ativo: %s" % (shield_powerup_scene != null))
	print("  - Split cooldown inicial: %.1fs" % split_cooldown)
	print("==================================")

func _physics_process(delta):
	# Debug periódico
	if int(Time.get_ticks_msec() / 1000) % 5 == 0 and Engine.get_physics_frames() % 60 == 0:
		print("Status: split_cooldown=%.1fs, is_split=%s" % [split_cooldown, is_split])
	
	if not is_split and enable_split_system:
		_update_split_system(delta)
	elif is_split:
		split_timer -= delta
		if split_timer <= 0:
			_merge_clouds()
	
	_update_shield_system(delta)

# ========================================
# SISTEMA DE DIVISÃO
# ========================================
func _update_split_system(delta):
	split_cooldown -= delta
	
	if split_cooldown <= 0:
		print("⏰ Timer de divisão atingido! Iniciando divisão...")
		_split_angry_cloud()
		split_cooldown = split_interval

func _split_angry_cloud():
	if not angry_cloud:
		push_error("_split_angry_cloud: angry_cloud é null!")
		return
	
	if is_split:
		print("_split_angry_cloud: Já está dividida, ignorando.")
		return
	
	if not is_instance_valid(angry_cloud):
		push_error("_split_angry_cloud: angry_cloud não é mais válida!")
		return
	
	print("=== DIVISÃO INICIADA ===")
	print("  AngryCloud válida: %s" % angry_cloud.name)
	print("  Posição: %s" % angry_cloud.global_position)
	
	is_split = true
	split_timer = split_duration
	
	# Salva dados da nuvem principal
	var original_position = angry_cloud.global_position
	var original_scale = angry_cloud.scale
	var init_lightning_scale = angry_cloud.lightning_scale
	
	print("  Escala original: %s" % original_scale)
	
	angry_cloud.visible = false
	angry_cloud.set_physics_process(false)
	print("  Nuvem principal escondida")
	
	var angle_step = TAU / mini_cloud_count
	var spawn_radius = 150.0
	
	print("  Criando %d mini nuvens..." % mini_cloud_count)
	
	var base_path_index = angry_cloud.current_path_index
	var total_paths = angry_cloud.paths.size()
	
	for i in range(mini_cloud_count):
		# Duplica a AngryCloud
		var mini_cloud: CharacterBody2D = angry_cloud.duplicate()
		add_child(mini_cloud)
		
		print("    Mini nuvem %d duplicada" % (i + 1))
		
		# Configura escala menor
		mini_cloud.scale = original_scale * mini_cloud_scale
		mini_cloud.lightning_scale = init_lightning_scale * mini_cloud_scale
		
		# Posiciona em círculo
		var angle = angle_step * i
		var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
		mini_cloud.global_position = original_position + offset
		
		# Torna visível e ativa
		mini_cloud.visible = true
		mini_cloud.set_physics_process(true)
		
		# Se tivermos mais de 1 caminho, distribuímos
		if total_paths > 1:
			# Calcula um índice diferente para cada mini nuvem.
			# (base + i + 1) garante que elas não peguem o mesmo da original de imediato
			var new_path_index = (base_path_index + i + 1) % total_paths
			
			# Chama a função que criamos no Passo 1
			mini_cloud.force_path_change(new_path_index)
			
			print("    Mini nuvem %d foi para o Path ID: %d" % [i, new_path_index])
		
		print("    Posição: %s, Escala: %s" % [mini_cloud.global_position, mini_cloud.scale])
		
		mini_cloud.speed *= 1.3
		print("    Velocidade ajustada: %.1f" % mini_cloud.speed)
		
		mini_cloud.lightning_spawn_interval *= 0.7
		print("    Intervalo de raios: %.1f" % mini_cloud.lightning_spawn_interval)
		
		mini_clouds.append(mini_cloud)
	
	print("✅ Mini nuvens ativas: %d" % mini_clouds.size())
	print("========================")

func _merge_clouds():
	if not is_split:
		return
	
	print("=== REUNINDO NUVENS ===")
	
	for mini_cloud in mini_clouds:
		if is_instance_valid(mini_cloud):
			mini_cloud.queue_free()
	
	mini_clouds.clear()
	
	if angry_cloud:
		angry_cloud.visible = true
		angry_cloud.set_physics_process(true)
		
		var original_scale = angry_cloud.scale
		angry_cloud.scale = original_scale * 0.5
		
		var tween = create_tween()
		tween.tween_property(angry_cloud, "scale", original_scale * 1.2, 0.3)
		tween.tween_property(angry_cloud, "scale", original_scale, 0.2)
	
	is_split = false
	print("Nuvem reunida!")

func _update_shield_system(delta):
	if not shield_powerup_scene:
		return
	
	shield_timer -= delta
	
	if shield_timer <= 0 and not current_shield:
		_spawn_shield()
		shield_timer = shield_spawn_interval

func _spawn_shield():
	if current_shield and is_instance_valid(current_shield):
		return
	
	var spawn_pos = _get_random_shield_position()
	
	current_shield = shield_powerup_scene.instantiate()
	add_child(current_shield)
	current_shield.global_position = spawn_pos
	
	# Configura duração do escudo
	# (pressupõe que o script do shield tem a variável `shield_duration`)
	current_shield.shield_duration = shield_duration
	
	# Conecta sinal de coleta
	if current_shield.has_signal("collected"):
		current_shield.collected.connect(_on_shield_collected)
	
	print("Shield spawnado em: %s" % spawn_pos)

func _get_random_shield_position() -> Vector2:
	#Se tem posições definidas, escolhe uma aleatória
	if shield_spawn_positions.size() > 0:
		var marker = shield_spawn_positions[randi() % shield_spawn_positions.size()]
		return marker.global_position
	
	# Senão, escolhe posição aleatória na tela
	if ScreenBoundsManager:
		var bounds = ScreenBoundsManager.get_screen_bounds()
		var screen_height = bounds.end.y - bounds.position.y
		
		# Define que o spawn só acontece nos 30% inferiores da tela
		var min_y = bounds.end.y - (screen_height * 0.3) # Começa em 70% da altura
		var max_y = bounds.end.y - 50                    # Termina 50px acima do chão (margem)
		
		return Vector2(
			randf_range(bounds.position.x + 100, bounds.end.x - 100), # X (Horizontal) continua igual
			randf_range(min_y, max_y)                                 # Y (Vertical) agora é só embaixo
		)
	
	# Fallback: posição aleatória próxima ao centro
	return global_position + Vector2(
		randf_range(-300, 300),
		randf_range(-200, 200)
	)

func _on_shield_collected():
	current_shield = null
	print("Shield coletado!")

# ========================================
# FUNÇÕES PÚBLICAS
# ========================================
func force_split():
	"""Força divisão imediatamente (para testes)"""
	if not is_split:
		_split_angry_cloud()

func force_merge():
	if is_split:
		split_timer = 0

func force_spawn_shield():
	_spawn_shield()
