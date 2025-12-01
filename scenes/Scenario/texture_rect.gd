extends TextureRect

@export var height: float = 20.0 
@export var width_multiplier: float = 3.0

func _ready():
	# Configurações visuais do TextureRect
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_TILE 
	
	# Conecta ao redimensionamento
	get_tree().root.size_changed.connect(_on_screen_resized)
	
	# Configura alinhamento interno de todos os Labels filhos uma única vez
	for child in get_children():
		if child is Label:
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			child.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_adjust_visuals()

func _on_screen_resized():
	await get_tree().process_frame
	_adjust_visuals()

func _adjust_visuals():
	# 1. DADOS DA CÂMERA (Cálculo do mundo visível)
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
		
		true_bottom_y = cam_pos.y + viewport_half_height
		center_x = cam_pos.x
		screen_width = visible_rect.size.x / zoom.x
	else:
		true_bottom_y = visible_rect.size.y
		center_x = visible_rect.size.x / 2.0
	
	# 2. APLICAÇÃO NO TEXTURE RECT (Pai)
	var final_width = screen_width * width_multiplier
	
	# Aplica tamanho e posição
	size = Vector2(final_width, height)
	var pos_x = center_x - (final_width / 2.0)
	global_position = Vector2(pos_x, true_bottom_y) # Coloca no fundo da tela
	
	# 3. ORGANIZAÇÃO DOS 4 LABELS (Filhos)
	_organize_labels(final_width)

func _organize_labels(parent_width: float):
	# Filtra apenas os filhos que são Label
	var labels = []
	for child in get_children():
		if child is Label:
			labels.append(child)
	
	var count = labels.size()
	if count == 0: return

	# Divide a largura total pelo número de labels (ex: largura 1000 / 4 = 250 por fatia)
	var segment_width = parent_width / count
	
	for i in range(count):
		var lbl = labels[i]
		
		# Define o tamanho do label para ocupar exatamente 1/4 da largura
		# e a altura total da barra
		lbl.size = Vector2(segment_width, height)
		
		# Posiciona o label:
		# Posição X = (índice * largura_da_fatia)
		# Posição Y = 0 (topo do TextureRect)
		lbl.position = Vector2(i * segment_width, 0)
