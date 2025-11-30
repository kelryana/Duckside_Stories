extends Node2D

@export var nota_scene: PackedScene # Arraste a cena Note.tscn
@export var conductor: Node         # Arraste o nó Conductor

# --- POSIÇÕES ---
@export var spawn_positions: Array[Marker2D] # Os 4 Markers de cima
@export var hit_positions: Array[Node2D]     # Os 4 Sprites de baixo (botões)

# --- CORES DAS MOSCAS (NOVO) ---
# Arraste os arquivos .png das moscas coloridas aqui no Inspetor!
# Ordem sugerida: 0=Esq, 1=Baixo, 2=Cima, 3=Dir
@export var texturas_moscas: Array[Texture2D] 

func _ready():
	if conductor:
		conductor.beat.connect(_on_conductor_beat)

func _on_conductor_beat(beat_number):
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	if not nota_scene: return
	
	var nova_nota = nota_scene.instantiate()
	add_child(nova_nota)
	
	# 1. Posiciona na pista certa
	if spawn_positions.size() > indice_pista:
		nova_nota.global_position = spawn_positions[indice_pista].global_position
	
	# 2. Define o alvo Y
	if hit_positions.size() > indice_pista:
		nova_nota.target_y = hit_positions[indice_pista].global_position.y
		
	# 3. Avisa qual pista é
	if "lane_id" in nova_nota:
		nova_nota.lane_id = indice_pista

	# --- 4. TROCA A IMAGEM DA MOSCA (A MÁGICA) ---
	# Procura o Sprite2D dentro da nota e troca a textura
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	
	if sprite and texturas_moscas.size() > indice_pista:
		# Pega a imagem correspondente da lista e aplica
		sprite.texture = texturas_moscas[indice_pista]
	# ---------------------------------------------
