extends Node2D

@export var nota_scene: PackedScene 
@export var conductor: Node         
@export var texturas_moscas: Array[Texture2D] 

# --- AQUI ESTÁ A CORREÇÃO: COLOQUEI O @EXPORT DE VOLTA ---
# Assim as caixinhas vão reaparecer no Inspetor para você arrastar
@export var spawn_positions: Array[Marker2D] 
@export var hit_positions: Array[Node2D] 
# ---------------------------------------------------------

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
	if spawn_positions.size() > indice_pista and spawn_positions[indice_pista]:
		nova_nota.global_position = spawn_positions[indice_pista].global_position
	
	# 2. Define o alvo Y
	if hit_positions.size() > indice_pista and hit_positions[indice_pista]:
		nova_nota.target_y = hit_positions[indice_pista].global_position.y
	else:
		nova_nota.target_y = 600.0
		
	# 3. Avisa qual pista é
	if "lane_id" in nova_nota:
		nova_nota.lane_id = indice_pista

	# 4. Troca a imagem
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	if sprite and texturas_moscas.size() > indice_pista:
		sprite.texture = texturas_moscas[indice_pista]
