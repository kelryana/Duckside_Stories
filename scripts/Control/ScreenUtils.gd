extends Node

# Configurações
var screen_margin: float = 20.0
var debug_mode: bool = true

# ==============================================================================
# 1. CORE: LÓGICA DE CÂMERA E VIEWPORT (SEM MARGENS)
# ==============================================================================
# Retorna um Rect2 exato do que a câmera está vendo (Bordas Reais da tela)
func get_full_viewport_rect() -> Rect2:
	var viewport := get_viewport()
	if not viewport:
		return Rect2()

	var visible_rect := viewport.get_visible_rect()
	var camera := viewport.get_camera_2d()

	# Caso 1: Tem Câmera Ativa
	if camera:
		var camera_pos := camera.get_screen_center_position()
		var zoom := camera.zoom
		
		# Proteção contra zoom zero
		if zoom.x == 0: zoom.x = 1.0
		if zoom.y == 0: zoom.y = 1.0

		var size_zoomed := visible_rect.size / zoom
		var top_left := camera_pos - (size_zoomed / 2.0)
		
		return Rect2(top_left, size_zoomed)

	# Caso 2: Sem Câmera (UI ou Viewport padrão)
	return visible_rect

# ==============================================================================
# 2. UTILITÁRIOS DE JOGO (COM MARGENS)
# ==============================================================================
# Retorna a "Área Segura" de jogo (Tela Real - Margem)
func get_screen_bounds() -> Rect2:
	var full_rect := get_full_viewport_rect()
	
	# O método grow com valor negativo encolhe o retangulo
	return full_rect.grow(-screen_margin)

func clamp_position(pos: Vector2) -> Vector2:
	var bounds := get_screen_bounds()
	# clamp recebe (min, max), então passamos (position, end)
	return pos.clamp(bounds.position, bounds.end)

func is_inside_screen(pos: Vector2) -> bool:
	return get_screen_bounds().has_point(pos)

func get_screen_size() -> Vector2:
	return get_screen_bounds().size

# ==============================================================================
# 3. UTILITÁRIOS VISUAIS (NOVOS)
# ==============================================================================
# Ajusta qualquer TextureRect ou ColorRect para cobrir a tela inteira
func fit_background_to_screen(node: CanvasItem):
	if not node: return
	
	var full_rect := get_full_viewport_rect()
	
	# Posiciona no canto superior esquerdo absoluto
	node.global_position = full_rect.position
	
	# Lógica para TextureRect e Control
	if "size" in node:
		node.size = full_rect.size
		# Garante configurações ideais para TextureRect
		if node is TextureRect:
			# EXPAND_IGNORE_SIZE permite que alteremos o size livremente
			if node.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
				node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				
	# Lógica específica para Sprite2D (escala em vez de tamanho)
	elif node is Sprite2D:
		var tex_size = node.texture.get_size()
		var scale_x = full_rect.size.x / tex_size.x
		var scale_y = full_rect.size.y / tex_size.y
		
		# "Cover": Escolhe o maior fator de escala para cobrir tudo sem bordas pretas
		var final_scale = max(scale_x, scale_y)
		
		node.scale = Vector2(final_scale, final_scale)
		node.global_position = full_rect.get_center()

# ==============================================================================
# 4. CONFIGURAÇÃO
# ==============================================================================
func set_margin(value: float):
	screen_margin = value

func set_debug_mode(active: bool):
	debug_mode = active

# Recalcula e pode ser usado para emitir sinais globais se necessário
func update_bounds_after_scene_change():
	await get_tree().process_frame
	if debug_mode:
		print("ScreenUtils: Limites recalculados. Full Rect: ", get_full_viewport_rect())
