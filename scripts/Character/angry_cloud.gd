extends CharacterBody2D

# ==========================================
# MOVIMENTO E PATH 
# ==========================================
@export var speed: float = 150.0
@export var paths: Array[Path2D] = []
@export var start_path_index: int = 0
@export var constrain_to_screen: bool = true

# ==========================================
# SISTEMA DE RAIOS
# ==========================================
@export var lightning_scene: PackedScene
@export var lightning_spawn_interval: float = 2.0
@export var lightning_angle_range: float = 45.0
@export var lightning_scale: Vector2 = Vector2(1.0, 1.0)
@export var show_debug_cone: bool = false

@export_group("Randomização dos Raios")
@export var min_lightning_count: int = 1
@export var max_lightning_count: int = 5
@export var min_lightning_speed: float = 300.0
@export var max_lightning_speed: float = 700.0
@export var lightning_lifetime: float = 3.0

# ==========================================
# NOVO: SISTEMA DE VIDA E COMBATE
# ==========================================
@export_group("Combate")
@export var max_health: int = 3  # <--- A variável que faltava!
var current_health: int

# Sinal para avisar o Manager que esta nuvem morreu
signal cloud_died(cloud_ref)

# ==========================================
# VARIÁVEIS INTERNAS
# ==========================================
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var lightning_spawn_point: Marker2D = $LightningSpawnPoint if has_node("LightningSpawnPoint") else null

var current_path: Path2D
var current_path_index: int = 0
var path_follow: PathFollow2D
var lightning_timer: float = 0.0
var visited_paths: Array[int] = []
var scene_bounds: Rect2

func _ready():
	# Inicializa a vida
	current_health = max_health 
	
	add_to_group("bounded_objects")
	add_to_group("angry_cloud") # Garante que está no grupo para o Raio detectar
	
	# Busca bounds da cena
	var bounds_limiter = get_tree().get_first_node_in_group("scene_bounds")
	if bounds_limiter and bounds_limiter.has_method("get_bounds"):
		scene_bounds = bounds_limiter.get_bounds()
	
	# Detecta paths automaticamente
	if paths.is_empty():
		_auto_detect_paths()
	
	if not paths.is_empty():
		current_path_index = clampi(start_path_index, 0, paths.size() - 1)
		_setup_path(current_path_index)
	
	lightning_timer = lightning_spawn_interval

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
		elif ScreenUtils:
			global_position = ScreenUtils.clamp_position(global_position)
	
	# Verifica fim da path
	if path_follow.progress_ratio >= 1.0:
		_choose_next_path()
	
	# Sistema de raios
	lightning_timer -= delta
	if lightning_timer <= 0:
		_spawn_lightning_wave()
		lightning_timer = lightning_spawn_interval

# ==========================================
# FUNÇÕES DE COMBATE 
# ==========================================

func take_damage(amount: int = 1):
	"""Chamado pelo Raio Refletido"""
	current_health -= amount
	print("☁️ Nuvem atingida! Vida: %d/%d" % [current_health, max_health])
	
	# Feedback Visual (Piscar vermelho)
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color(10, 0, 0) # Vermelho estourado
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.15)
		
		# Feedback de escala (tremida)
		var tween_scale = create_tween()
		tween_scale.tween_property(self, "scale", scale * 0.9, 0.05)
		tween_scale.tween_property(self, "scale", scale, 0.05)
	
	if current_health <= 0:
		die()

func die():
	emit_signal("cloud_died", self)
	
	# Som de morte ou partículas aqui
	# ...
	
	queue_free()

func increase_difficulty(amount: int):
	"""Chamado pelo Manager quando outras nuvens morrem"""
	min_lightning_count += amount
	max_lightning_count += amount
	
	# Feedback visual de "Power Up"
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.15, 0.2).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "scale", scale * 1.0, 0.2)
	
	if sprite:
		sprite.modulate = Color(1.0, 0.5, 0.5) # Fica levemente avermelhada de raiva

# ==========================================
# FUNÇÕES AUXILIARES DE PATH
# ==========================================
func apply_bounds(bounds: Rect2):
	scene_bounds = bounds

func _auto_detect_paths():
	var parent = get_parent()
	if not parent: return
	for child in parent.get_children():
		if child is Path2D: paths.append(child)

func _setup_path(path_index: int):
	if path_index < 0 or path_index >= paths.size(): return
	current_path = paths[path_index]
	if path_follow: path_follow.queue_free()
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	current_path.add_child(path_follow)
	path_follow.progress = 0

func _choose_next_path():
	if paths.size() <= 1:
		if path_follow: path_follow.progress = 0
		return
	var next_index = (current_path_index + 1) % paths.size()
	# Pequena lógica aleatória simples se tiver muitos paths
	if paths.size() > 2:
		next_index = randi() % paths.size()
		while next_index == current_path_index:
			next_index = randi() % paths.size()
	
	current_path_index = next_index
	_setup_path(current_path_index)

func force_path_change(target_index: int):
	if paths.is_empty(): return
	current_path_index = target_index % paths.size()
	_setup_path(current_path_index)

# ==========================================
# SPAWN DE RAIOS
# ==========================================
func _spawn_lightning_wave():
	if not lightning_scene or not lightning_spawn_point: return
	
	var count = randi_range(min_lightning_count, max_lightning_count)
	for i in range(count):
		_spawn_single_lightning()

func _spawn_single_lightning():
	var angle_degrees = randf_range(-lightning_angle_range, lightning_angle_range)
	var angle_radians = deg_to_rad(angle_degrees + 90)
	var random_speed = randf_range(min_lightning_speed, max_lightning_speed)
	
	var lightning = lightning_scene.instantiate()
	get_parent().add_child(lightning)
	
	var direction = Vector2.DOWN.rotated(angle_radians - PI/2)
	
	lightning.speed = random_speed
	lightning.lifetime = lightning_lifetime
	lightning.direction = direction
	lightning.global_position = lightning_spawn_point.global_position
	lightning.rotation = angle_radians
	lightning.scale = lightning_scale
	
	if lightning.has_method("add_collision_exception_with"):
		lightning.add_collision_exception_with(self)
