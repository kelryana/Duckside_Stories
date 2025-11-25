extends CanvasLayer

# Arraste suas imagens para aqui no Inspector
@export var texture_full: Texture2D
@export var texture_empty: Texture2D

# Referências aos nós TextureRect na cena
@onready var icons: Array[TextureRect] = [
	$HBoxContainer/ShieldIcon1,
	$HBoxContainer/ShieldIcon2,
	$HBoxContainer/ShieldIcon3
]

func _ready():
	# Busca o player e conecta o sinal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Conecta o sinal do inventário à nossa função de atualizar
		player.shield_inventory_changed.connect(update_shield_display)
		
		# Atualiza a primeira vez para garantir que começa certo
		update_shield_display(player.shield_inventory)

func update_shield_display(count: int):
	# Percorre os 3 ícones
	for i in range(icons.size()):
		if i < count:
			# Se o índice for menor que a quantidade, mostra CHEIO
			icons[i].texture = texture_full
		else:
			# Se não, mostra VAZIO
			icons[i].texture = texture_empty
