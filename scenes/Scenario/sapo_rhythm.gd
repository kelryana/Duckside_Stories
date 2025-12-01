extends Node2D

@export var nota_scene: PackedScene 
@export var conductor: Node          
@export var texturas_moscas: Array[Texture2D] 

# --- AQUI ESTÁ A MUDANÇA ---
# Vamos usar essa lista agora! Arraste os SpawnPos para cá no Inspetor.
@export var spawn_positions: Array[Node2D] 

# As zonas de acerto continuam servindo para saber onde a nota MORRE (o alvo)
@export var hit_positions: Array[Node2D] 

func _ready():
	if conductor:
		conductor.beat.connect(_on_conductor_beat)

func _on_conductor_beat(beat_number):
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	if not nota_scene: return
	
	# Verificação de segurança: Precisamos ter certeza que configuramos o Inspetor
	if spawn_positions.size() <= indice_pista or hit_positions.size() <= indice_pista:
		print("ERRO: Faltou configurar os SpawnPos ou HitPositions no Inspetor!")
		return

	var nova_nota = nota_scene.instantiate()
	
	# IMPORTANTE: Adiciona como filho DESTE script (SapoRhythm) para manter coordenadas locais
	add_child(nova_nota) 
	
	# --- DEFININDO A POSIÇÃO DE NASCIMENTO (START) ---
	# Agora a nota nasce EXATAMENTE onde você colocou o nó SpawnPos correspondente
	nova_nota.position = spawn_positions[indice_pista].position
	
	# --- DEFININDO O ALVO (END) ---
	# A nota sabe que deve cair até o Y da zona de acerto
	# (Ela vai viajar da posição do SpawnPos até o Y do HitPos)
	nova_nota.target_y = hit_positions[indice_pista].position.y
	
	# Configurações visuais e de lógica
	if "lane_id" in nova_nota:
		nova_nota.lane_id = indice_pista
		
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	if sprite and texturas_moscas.size() > indice_pista:
		sprite.texture = texturas_moscas[indice_pista]
