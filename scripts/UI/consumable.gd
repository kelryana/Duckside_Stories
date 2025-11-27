extends CanvasLayer

# Arraste suas imagens para aqui no Inspector
@export var texture_full: Texture2D
@export var texture_empty: Texture2D

# NOVO: Define o tamanho desejado dos ícones (ex: 64x64 pixels)
@export var icon_size: Vector2 = Vector2(64, 64)

# Referências aos nós TextureRect na cena
@onready var icons: Array[TextureRect] = [
	$HBoxContainer/ConsumableIcon1,
	$HBoxContainer/ConsumableIcon2,
	$HBoxContainer/ConsumableIcon3
]

func _ready():
	# 1. Aplica a configuração de tamanho em todos os ícones
	for icon in icons:
		# "IGNORE_SIZE" diz para o TextureRect não forçar o tamanho da imagem original
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
		
		# "KEEP_ASPECT_CENTERED" faz a imagem caber no quadrado sem distorcer
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
		
		# Define o tamanho forçado que o HBoxContainer vai respeitar
		icon.custom_minimum_size = icon_size

	# 2. Busca o player e conecta o sinal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Conecta o sinal do inventário à nossa função de atualizar
		player.consumable_inventory_changed.connect(update_consumable_display)
		
		# Atualiza a primeira vez para garantir que começa certo
		update_consumable_display(player.consumable_inventory)

func update_consumable_display(count: int):
	# Percorre os 3 ícones
	for i in range(icons.size()):
		if i < count:
			# Se o índice for menor que a quantidade, mostra CHEIO
			icons[i].texture = texture_full
		else:
			# Se não, mostra VAZIO
			icons[i].texture = texture_empty
