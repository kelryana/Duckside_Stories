extends Node2D

@export var nota_scene: PackedScene # Arraste a cena Note.tscn aqui
@export var conductor: Node         # Arraste o nó Conductor aqui

# --- LISTAS DE POSIÇÕES (Arraste os nós da cena para cá) ---
@export var spawn_positions: Array[Marker2D] # Os 4 Markers de cima
@export var hit_positions: Array[Node2D]     # Os 4 Sprites de baixo (botões)

func _ready():
	# Conecta o sinal do Maestro
	if conductor:
		conductor.beat.connect(_on_conductor_beat)

func _on_conductor_beat(beat_number):
	# A cada batida, escolhe uma pista aleatória (0, 1, 2 ou 3)
	# (Futuramente você pode criar um "mapa" fixo aqui)
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	if not nota_scene: return
	
	var nova_nota = nota_scene.instantiate()
	add_child(nova_nota)
	
	# 1. Posiciona na pista certa lá em cima
	if spawn_positions.size() > indice_pista:
		nova_nota.global_position = spawn_positions[indice_pista].global_position
	
	# 2. Configura a nota
	# Avisa a nota qual é o alvo Y dela (a posição do botão de baixo)
	if hit_positions.size() > indice_pista:
		nova_nota.target_y = hit_positions[indice_pista].global_position.y
		
	# Avisa a nota qual pista ela pertence (0, 1, 2 ou 3)
	nova_nota.lane_id = indice_pista
