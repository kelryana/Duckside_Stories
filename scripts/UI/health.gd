extends CanvasLayer

@export var heart_texture: Texture2D  # Sprite do coração cheio
@export var heart_empty_texture: Texture2D  # Sprite do coração vazio
@export var heart_spacing: float = 40.0  # Espaçamento entre corações
@export var heart_scale: Vector2 = Vector2(2.0, 2.0)  # Escala dos corações


@onready var hearts_container: HBoxContainer = $HBoxContainer

var player: CharacterBody2D
var heart_sprites: Array[TextureRect] = []

func _ready():
	# Busca o player
	await get_tree().process_frame  # Espera 1 frame para garantir que tudo foi instanciado
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		push_warning("HealthUI: Player não encontrado!")
		return
	
	# Conecta aos sinais do player
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	
	# Cria os corações iniciais
	_create_hearts(player.max_health)
	_update_hearts(player.current_health, player.max_health)
	
	player.health_changed.connect(
		func(c, m):
			_create_hearts(m)
			_update_hearts(c, m)
	)

func _create_hearts(count: int):
	"""Cria os sprites dos corações"""
	# Limpa corações existentes
	for heart in heart_sprites:
		heart.queue_free()
	heart_sprites.clear()
	
	# Cria novos corações
	for i in range(count):
		var heart = TextureRect.new()
		heart.texture = heart_texture if heart_texture else _create_default_heart_texture()
		heart.custom_minimum_size = Vector2(32, 32) * heart_scale
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		hearts_container.add_child(heart)
		heart_sprites.append(heart)

func _create_default_heart_texture() -> Texture2D:
	"""Cria uma textura padrão caso não tenha sprite"""
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	return ImageTexture.create_from_image(img)

func _update_hearts(current: int, maximum: int):
	"""Atualiza visual dos corações"""
	for i in range(heart_sprites.size()):
		if i < current:
			# Coração cheio
			heart_sprites[i].modulate = Color.WHITE
			if heart_texture:
				heart_sprites[i].texture = heart_texture
		else:
			# Coração vazio
			heart_sprites[i].modulate = Color(0.3, 0.3, 0.3)
			if heart_empty_texture:
				heart_sprites[i].texture = heart_empty_texture

func _on_health_changed(new_health: int, max_health: int):
	"""Chamado quando a vida do player muda"""

	_update_hearts(new_health, max_health)
	
	# Animação de pulso quando perde vida
	if new_health < heart_sprites.size():
		var lost_heart = heart_sprites[new_health]
		var tween = create_tween()
		tween.tween_property(lost_heart, "scale", Vector2.ONE * 1.5, 0.1)
		tween.tween_property(lost_heart, "scale", Vector2.ONE, 0.1)

func _on_player_died():
	"""Chamado quando o player morre"""
	print("HealthUI: Player morreu!")
