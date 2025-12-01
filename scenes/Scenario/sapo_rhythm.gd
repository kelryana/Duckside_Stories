extends Node2D

@export var nota_scene: PackedScene 
@export var conductor: Node          
@export var texturas_moscas: Array[Texture2D] 

@export var spawn_positions: Array[Node2D] 
@export var hit_positions: Array[Area2D] 

# --- ADIÇÃO 1: Referência ao AudioPlayer ---
# (Certifique-se que o nome do nó na cena é exatamente AudioStreamPlayer)
@onready var audio_player = $AudioStreamPlayer

# --- AQUI ESTÁ A ATUALIZAÇÃO ---
# Mapeamento exato com o print que você mandou
# Ordem: 0=Cima, 1=Baixo, 2=Esquerda, 3=Direita
var input_map = ["UP", "DOWN", "LEFT", "RIGHT"]

func _ready():
	if conductor:
		conductor.beat.connect(_on_conductor_beat)
		
	# --- ADIÇÃO 2: Conectar o sinal de fim ---
	# Quando o áudio terminar de tocar, ele chama a função _on_fim_da_musica
	if audio_player:
		audio_player.finished.connect(_on_fim_da_musica)
	

func _on_conductor_beat(beat_number):
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	if not nota_scene: return
	
	if spawn_positions.size() <= indice_pista or hit_positions.size() <= indice_pista:
		return

	var nova_nota = nota_scene.instantiate()
	add_child(nova_nota) 
	
	# Posição de Spawn e Alvo
	nova_nota.position = spawn_positions[indice_pista].position
	nova_nota.target_y = hit_positions[indice_pista].position.y
	
	# Configurações visuais
	if "lane_id" in nova_nota:
		nova_nota.lane_id = indice_pista
		
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	if sprite and texturas_moscas.size() > indice_pista:
		sprite.texture = texturas_moscas[indice_pista]

# --- LÓGICA DE INPUT (TECLAS) ---
func _input(event):
	# Checa as 4 pistas
	for i in range(4):
		# Se apertou a tecla correspondente...
		if event.is_action_pressed(input_map[i]):
			checar_acerto(i)

func checar_acerto(indice_pista: int):
	var zona = hit_positions[indice_pista]
	
	# Pega as notas que estão tocando na zona AGORA
	var notas_na_zona = zona.get_overlapping_areas()
	
	if notas_na_zona.size() > 0:
		# --- ACERTOU! ---
		var nota_acertada = notas_na_zona[0]
		print("ACERTOU! Pista: ", input_map[indice_pista])
		
		# Tocar som de acerto, dar pontos, etc...
		
		nota_acertada.queue_free() # Remove a nota
	else:
		# --- ERROU! (Apertou sem nota) ---
		print("ERROU! (Apertou à toa): ", input_map[indice_pista])
		
# --- ADIÇÃO 3: O que acontece quando acaba? ---
func _on_fim_da_musica():
	print("Música acabou! Finalizando fase...")
	
	# É bom esperar uns 2 ou 3 segundos para as últimas notas caírem
	# 'await' pausa essa função por X segundos sem travar o jogo
	await get_tree().create_timer(3.0).timeout
	
	print("Fim de Jogo Real!")
	# AQUI VOCÊ ESCOLHE O QUE FAZER:
	
	# Opção A: Voltar para o menu / Mundo
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
	# Opção B: Mostrar uma tela de pontuação (se você tiver uma cena de UI)
	# get_tree().change_scene_to_file("res://tela_pontuacao.tscn")
