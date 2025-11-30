extends Node2D

@export var nota_scene: PackedScene 
@export var conductor: Node         
@export var texturas_moscas: Array[Texture2D] 

# --- A GENTE SÓ PRECISA SABER ONDE ESTÃO AS DE BAIXO ---
@export var hit_positions: Array[Node2D] 
# (O spawn_positions a gente ignora pq ele ta bugado)

func _ready():
	if conductor:
		conductor.beat.connect(_on_conductor_beat)

func _on_conductor_beat(beat_number):
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	if not nota_scene: return
	
	# 1. Cria a nota
	var nova_nota = nota_scene.instantiate()
	# Adiciona NA RAIZ DO JOGO (Isso impede que ela nasça torta por causa da câmera)
	get_tree().current_scene.add_child(nova_nota)
	
	# 2. ALINHAMENTO MAGNÉTICO (A Correção)
	# Se a lista de moscas de baixo estiver certa...
	if hit_positions.size() > indice_pista and hit_positions[indice_pista]:
		# Pega o X da mosca de baixo
		var x_alvo = hit_positions[indice_pista].global_position.x
		
		# Força a nota a nascer NESSE X, mas lá no alto (Y = -50)
		nova_nota.global_position = Vector2(x_alvo, -50)
		
		# Define o alvo pra ela saber quando morre
		nova_nota.target_y = hit_positions[indice_pista].global_position.y
	
	# 3. Configurações visuais
	if "lane_id" in nova_nota:
		nova_nota.lane_id = indice_pista
		
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	if sprite and texturas_moscas.size() > indice_pista:
		sprite.texture = texturas_moscas[indice_pista]
