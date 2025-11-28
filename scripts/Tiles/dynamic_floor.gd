extends StaticBody2D

@export var floor_thickness: float = 20.0 # Espessura reduzida conforme seu ajuste
@export var width_multiplier: float = 3.0

@onready var collision_shape = $CollisionShape2D

func _ready():
	scale = Vector2.ONE
	rotation = 0
	if collision_shape:
		collision_shape.position = Vector2.ZERO
	
	get_tree().root.size_changed.connect(_on_screen_resized)
	_adjust_floor()

func _on_screen_resized():
	await get_tree().process_frame
	_adjust_floor()

func _adjust_floor():
	if not collision_shape: return
	if not collision_shape.shape is RectangleShape2D:
		push_warning("ChaoAdaptativo: Shape incorreto!")
		return
	
	# 1. Obtém dados da Viewport e Câmera DIRETAMENTE (Ignorando ScreenUtils)
	var viewport = get_viewport()
	var visible_rect = viewport.get_visible_rect()
	var camera = viewport.get_camera_2d()
	
	var true_bottom_y = 0.0
	var center_x = 0.0
	var screen_width = visible_rect.size.x
	
	if camera:
		var zoom = camera.zoom
		var cam_pos = camera.get_screen_center_position()
		var viewport_half_height = (visible_rect.size.y / zoom.y) / 2.0
		
		# O Fundo Real é: Centro da Câmera + Metade da Altura da Tela (com Zoom)
		true_bottom_y = cam_pos.y + viewport_half_height
		center_x = cam_pos.x
		screen_width = visible_rect.size.x / zoom.x
	else:
		# Fallback sem câmera
		true_bottom_y = visible_rect.size.y
		center_x = visible_rect.size.x / 2.0
	
	# -----------------------------------------------------------
	# 2. APLICA TAMANHO E POSIÇÃO
	# -----------------------------------------------------------
	var rect_shape = collision_shape.shape as RectangleShape2D
	
	# Largura segura
	var safe_width = screen_width * width_multiplier
	rect_shape.size = Vector2(safe_width, floor_thickness)
	
	# O centro do corpo deve ser: Linha do Fundo REAL + Metade da Espessura
	var final_y = true_bottom_y + (floor_thickness / 2.0)
	
	global_position = Vector2(center_x, final_y)
	
	# print("Chão alinhado ao fundo absoluto: ", final_y)
