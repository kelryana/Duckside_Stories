extends CharacterBody2D

@export var speed: float = 150.0
@export var paths: Array[Path2D] = []
@export var start_path_index: int = 0
@export var constrain_to_screen: bool = true

@export var lightning_scene: PackedScene
@export var lightning_spawn_interval: float = 2.0
@export var lightning_angle_range: float = 45.0
@export var lightning_scale: Vector2 = Vector2(1.0, 1.0)
@export var show_debug_cone: bool = false

@export_group("Randomização")
@export var min_lightning_count: int = 1
@export var max_lightning_count: int = 5
@export var min_lightning_speed: float = 300.0
@export var max_lightning_speed: float = 700.0
@export var lightning_lifetime: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var lightning_spawn_point: Marker2D = $LightningSpawnPoint if has_node("LightningSpawnPoint") else null

var current_path: Path2D
var current_path_index: int = 0
var path_follow: PathFollow2D
var lightning_timer: float = 0.0
var visited_paths: Array[int] = []
var scene_bounds: Rect2

func _ready():
	# Adiciona ao grupo de objetos limitados
	add_to_group("bounded_objects")
	
	# Busca bounds da cena
	var bounds_limiter = get_tree().get_first_node_in_group("scene_bounds")
	if bounds_limiter and bounds_limiter.has_method("get_bounds"):
		scene_bounds = bounds_limiter.get_bounds()
	
	# Detecta paths automaticamente se não foram atribuídos
	if paths.is_empty():
		_auto_detect_paths()
	
	if paths.is_empty():
		push_error("AngryCloud: Nenhuma Path2D encontrada!")
		set_physics_process(false)
		return
	
	# Verifica configuração de raios
	if not lightning_scene:
		push_warning("AngryCloud: lightning_scene não atribuída! Raios não serão spawnados.")
	
	if not lightning_spawn_point:
		push_warning("AngryCloud: LightningSpawnPoint não encontrado! Adicione um Marker2D com esse nome.")
	
	# Configura path inicial
	current_path_index = clampi(start_path_index, 0, paths.size() - 1)
	_setup_path(current_path_index)
	
	lightning_timer = lightning_spawn_interval
	
	print("AngryCloud inicializado: %d paths, raios %s" % [paths.size(), "OK" if (lightning_scene and lightning_spawn_point) else "ERRO"])

func apply_bounds(bounds: Rect2):
	"""Chamado pelo SceneBoundsLimiter"""
	scene_bounds = bounds

func _auto_detect_paths():
	var parent = get_parent()
	if not parent:
		return
	
	for child in parent.get_children():
		if child is Path2D:
			paths.append(child)
	
	if paths.size() > 0:
		print("AngryCloud: %d path(s) detectada(s)" % paths.size())

func _setup_path(path_index: int):
	if path_index < 0 or path_index >= paths.size():
		return
	
	current_path = paths[path_index]
	
	if path_follow:
		path_follow.queue_free()
	
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	current_path.add_child(path_follow)
	
	if visited_paths.size() > 0:
		var closest_offset = _find_closest_offset_to_position(global_position)
		path_follow.progress = closest_offset
	else:
		path_follow.progress = 0
	
	visited_paths.append(path_index)

func _find_closest_offset_to_position(pos: Vector2) -> float:
	if not current_path or not current_path.curve:
		return 0.0
	
	var curve = current_path.curve
	var min_distance = INF
	var best_offset = 0.0
	
	for i in range(0, 101, 5):
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
	
	# Movimento ao longo da path
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	
	# Limita posição na tela
	if constrain_to_screen:
		if scene_bounds != Rect2():
			global_position = global_position.clamp(scene_bounds.position, scene_bounds.end)
		elif ScreenBoundsManager:
			global_position = ScreenBoundsManager.clamp_position(global_position)
	
	# Verifica fim da path
	if path_follow.progress_ratio >= 1.0:
		_choose_next_path()
	
	# Sistema de raios
	lightning_timer -= delta
	if lightning_timer <= 0:
		_spawn_lightning_wave()
		lightning_timer = lightning_spawn_interval

func _choose_next_path():
	if paths.size() <= 1:
		if path_follow:
			path_follow.progress = 0
		return
	
	var available_paths: Array[int] = []
	for i in range(paths.size()):
		if i != current_path_index:
			available_paths.append(i)
	
	if available_paths.size() > 0:
		var next_index = available_paths[randi() % available_paths.size()]
		current_path_index = next_index
		_setup_path(current_path_index)

func _spawn_lightning_wave():
	# Validações críticas
	if not lightning_scene:
		push_warning("AngryCloud: lightning_scene é null!")
		return
	
	if not lightning_spawn_point:
		push_warning("AngryCloud: lightning_spawn_point é null!")
		return
	
	# Determina quantidade de raios
	var lightning_count = randi_range(min_lightning_count, max_lightning_count)
	
	print("AngryCloud: Spawnando %d raios de %s" % [lightning_count, lightning_spawn_point.global_position])
	
	# Spawna cada raio
	for i in range(lightning_count):
		_spawn_single_lightning()

func _spawn_single_lightning():
	# Calcula ângulo aleatório
	var angle_degrees = randf_range(-lightning_angle_range, lightning_angle_range)
	var angle_radians = deg_to_rad(angle_degrees + 90)
	
	# Velocidade aleatória
	var random_speed = randf_range(min_lightning_speed, max_lightning_speed)
	
	print("  DEBUG: angle_degrees=%.1f, angle_radians=%.3f, speed=%.1f" % [angle_degrees, angle_radians, random_speed])
	
	# Instancia o raio
	var lightning = lightning_scene.instantiate()
	get_parent().add_child(lightning)
	
	# IMPORTANTE: Configura ANTES de posicionar
	var direction = Vector2.DOWN.rotated(angle_radians - PI/2)
	
	# Configura velocidade PRIMEIRO
	lightning.speed = random_speed
	lightning.lifetime = lightning_lifetime
	lightning.direction = direction
	
	# Depois posiciona e rotaciona
	lightning.global_position = lightning_spawn_point.global_position
	lightning.rotation = angle_radians
	lightning.scale = lightning_scale
	
	# Exclui da colisão com AngryCloud
	if lightning.has_method("add_collision_exception_with"):
		lightning.add_collision_exception_with(self)
	
	print("  Raio configurado: pos=%s, dir=%s, speed=%.1f, angle=%.1f°" % [
		lightning.global_position, 
		direction, 
		lightning.speed,
		angle_degrees
	])

func add_path(path: Path2D):
	if path and not paths.has(path):
		paths.append(path)

func _draw():
	if not show_debug_cone or not lightning_spawn_point:
		return
	
	if not (Engine.is_editor_hint() or OS.is_debug_build()):
		return
	
	var spawn_pos = lightning_spawn_point.position
	var cone_length = 100
	var left_angle = deg_to_rad(-lightning_angle_range + 90)
	var right_angle = deg_to_rad(lightning_angle_range + 90)
	
	draw_line(spawn_pos, spawn_pos + Vector2(cos(left_angle), sin(left_angle)) * cone_length, Color.YELLOW, 2.0)
	draw_line(spawn_pos, spawn_pos + Vector2(cos(right_angle), sin(right_angle)) * cone_length, Color.YELLOW, 2.0)
	draw_circle(spawn_pos, 5, Color.RED)
