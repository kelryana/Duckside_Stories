extends CharacterBody2D

# Configurações de Movimento
@export var speed: float = 150.0
@export var paths: Array[Path2D] = []
@export var start_path_index: int = 0

# Configurações de Raios
@export var lightning_scene: PackedScene  # Arraste a cena do raio aqui
@export var lightning_spawn_interval: float = 2.0  # Tempo entre raios
@export var lightning_angle_range: float = 45.0  # Ângulo máximo (45° para cada lado = 90° total)
@export var lightning_spawn_offset: Vector2 = Vector2(0, 20)  # Offset do ponto de spawn (usado se não houver Marker2D)
@export var lightning_scale: Vector2 = Vector2(1.0, 1.0)  # Escala do raio ao instanciar
@export var inherit_cloud_scale: bool = false  # Se true, raio herda escala da nuvem

@onready var sprite: Sprite2D = $Sprite2D  # Ajuste o caminho se necessário
@onready var lightning_spawn_point: Marker2D = $LightningSpawnPoint if has_node("LightningSpawnPoint") else null

@export var show_debug_cone: bool = false  # Mostrar cone de debug (só no editor)

# Variáveis internas
var current_path: Path2D
var current_path_index: int = 0
var path_follow: PathFollow2D
var lightning_timer: float = 0.0
var visited_paths: Array[int] = []

func _ready():
	# Se não tem paths atribuídos, tenta buscar automaticamente
	if paths.is_empty():
		_auto_detect_paths()
	
	if paths.is_empty():
		push_error("AngryCloud: Nenhuma Path2D foi encontrada!")
		return
	
	# Inicia na primeira path
	current_path_index = start_path_index
	_setup_path(current_path_index)
	
	# Dispara primeiro raio após um delay
	lightning_timer = lightning_spawn_interval

func _auto_detect_paths():
	"""Busca automaticamente todas as Path2D na cena pai"""
	var parent = get_parent()
	if not parent:
		return
	
	for child in parent.get_children():
		if child is Path2D:
			paths.append(child)
	
	if paths.size() > 0:
		print("AngryCloud: %d path(s) detectada(s) automaticamente" % paths.size())

func _setup_path(path_index: int):
	"""Configura a path atual e cria o PathFollow2D"""
	if path_index < 0 or path_index >= paths.size():
		push_error("AngryCloud: Índice de path inválido: %d" % path_index)
		return
	
	current_path = paths[path_index]
	
	# Se já existe um PathFollow2D antigo, remove
	if path_follow:
		path_follow.queue_free()
	
	# Cria novo PathFollow2D
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	current_path.add_child(path_follow)
	
	# Se não é a primeira path, começa do ponto mais próximo
	if visited_paths.size() > 0:
		var closest_offset = _find_closest_offset_to_position(global_position)
		path_follow.progress = closest_offset
	else:
		path_follow.progress = 0
	
	visited_paths.append(path_index)

func _find_closest_offset_to_position(pos: Vector2) -> float:
	"""Encontra o offset mais próximo da posição atual na path"""
	var curve = current_path.curve
	var min_distance = INF
	var best_offset = 0.0
	
	# Testa vários pontos ao longo da curva
	for i in range(0, 101, 5):  # Testa a cada 5%
		var test_offset = (curve.get_baked_length() * i) / 100.0
		var point = curve.sample_baked(test_offset)
		var world_point = current_path.global_position + point
		var distance = pos.distance_to(world_point)
		
		if distance < min_distance:
			min_distance = distance
			best_offset = test_offset
	
	return best_offset

func _physics_process(delta):
	if not current_path or not path_follow:
		return
	
	# Move ao longo da path
	path_follow.progress += speed * delta
	
	# Atualiza posição da nuvem
	global_position = path_follow.global_position
	
	# Verifica se chegou ao fim da path
	if path_follow.progress_ratio >= 1.0:
		_choose_next_path()
	
	# Sistema de raios
	lightning_timer -= delta
	if lightning_timer <= 0:
		spawn_lightning()
		lightning_timer = lightning_spawn_interval

func _choose_next_path():
	"""Escolhe a próxima path aleatoriamente"""
	if paths.size() <= 1:
		# Se só tem uma path, reinicia ela
		path_follow.progress = 0
		return
	
	# Cria lista de paths disponíveis (exceto a atual)
	var available_paths: Array[int] = []
	for i in range(paths.size()):
		if i != current_path_index:
			available_paths.append(i)
	
	# Escolhe aleatoriamente
	if available_paths.size() > 0:
		var next_index = available_paths[randi() % available_paths.size()]
		current_path_index = next_index
		_setup_path(current_path_index)

func spawn_lightning():
	"""Instancia um raio em ângulo aleatório"""
	if not lightning_scene:
		push_warning("AngryCloud: Cena de raio não atribuída!")
		return
	
	# Calcula ângulo aleatório dentro do range (em radianos)
	var angle_degrees = randf_range(-lightning_angle_range, lightning_angle_range)
	var angle_radians = deg_to_rad(angle_degrees + 90)  # +90 para apontar para baixo
	
	# Instancia o raio
	var lightning = lightning_scene.instantiate()
	get_parent().add_child(lightning)
	
	# Posiciona o raio (usa Marker2D se existir, senão usa offset)
	var spawn_pos = global_position
	if lightning_spawn_point:
		spawn_pos = lightning_spawn_point.global_position
	else:
		spawn_pos += lightning_spawn_offset
	
	lightning.global_position = spawn_pos
	lightning.rotation = angle_radians
	
	# Aplica a escala configurada
	if inherit_cloud_scale:
		lightning.scale = scale * lightning_scale  # Multiplica pela escala da nuvem
	else:
		lightning.scale = lightning_scale
	
	# Se o raio tiver um método de inicialização, chame aqui
	if lightning.has_method("set_direction"):
		var direction = Vector2.DOWN.rotated(angle_radians - PI/2)
		lightning.set_direction(direction)

# Função para adicionar paths via código (opcional)
func add_path(path: Path2D):
	if path and not paths.has(path):
		paths.append(path)

# Função para visualizar no editor (debug)
func _draw():
	if Engine.is_editor_hint() or OS.is_debug_build():
		# Desenha o cone de 45°
		var cone_length = 100
		var left_angle = deg_to_rad(-lightning_angle_range + 90)
		var right_angle = deg_to_rad(lightning_angle_range + 90)
		
		draw_line(
			lightning_spawn_offset,
			lightning_spawn_offset + Vector2(cos(left_angle), sin(left_angle)) * cone_length,
			Color.YELLOW,
			2.0
		)
		draw_line(
			lightning_spawn_offset,
			lightning_spawn_offset + Vector2(cos(right_angle), sin(right_angle)) * cone_length,
			Color.YELLOW,
			2.0
		)
		draw_circle(lightning_spawn_offset, 5, Color.RED)
