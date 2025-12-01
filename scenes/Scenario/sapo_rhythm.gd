extends Node2D

# Referência à tela de Game Over (arrasta a cena para dentro do Sapo)
@onready var game_over_ui = $GameOver 
@onready var audio_player = $AudioStreamPlayer

# Configurações do Jogo
@export var maximo_erros_permitidos: int = 5 # Ajusta aqui! Se errar 5, perde.
var erros_atuais: int = 0
var jogo_ativo = true 

# Variáveis que já tinhas
@export var nota_scene: PackedScene 
@export var conductor: Node           
@export var texturas_moscas: Array[Texture2D] 
@export var spawn_positions: Array[Node2D] 
@export var hit_positions: Array[Area2D] 
var input_map = ["UP", "DOWN", "LEFT", "RIGHT"]

func _ready():
	# Zera os erros ao começar
	erros_atuais = 0
	
	# Conexões
	if conductor: conductor.beat.connect(_on_conductor_beat)
	if audio_player: audio_player.finished.connect(_on_fim_da_musica)
	
	# Garante que o Game Over começa escondido e funciona pausado
	if game_over_ui:
		game_over_ui.visible = false
		game_over_ui.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_conductor_beat(beat_number):
	if not jogo_ativo: return 
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	# (O teu código de spawn mantém-se igual)
	if not nota_scene or spawn_positions.size() <= indice_pista: return
	var nova_nota = nota_scene.instantiate()
	add_child(nova_nota) 
	nova_nota.position = spawn_positions[indice_pista].position
	nova_nota.target_y = hit_positions[indice_pista].position.y
	if "lane_id" in nova_nota: nova_nota.lane_id = indice_pista
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	if sprite and texturas_moscas.size() > indice_pista: sprite.texture = texturas_moscas[indice_pista]

func _input(event):
	if not jogo_ativo: return 
	for i in range(4):
		if event.is_action_pressed(input_map[i]):
			checar_acerto(i)

func checar_acerto(indice_pista: int):
	var zona = hit_positions[indice_pista]
	var notas_na_zona = zona.get_overlapping_areas()
	
	if notas_na_zona.size() > 0:
		var nota_acertada = notas_na_zona[0]
		nota_acertada.queue_free() # Acertou!
	else:
		registrar_erro() # Errou (apertou sem nota)

# --- NOVA LÓGICA DE ERRO ---
func registrar_erro():
	erros_atuais += 1
	print("Erros: ", erros_atuais, "/", maximo_erros_permitidos)
	
	if erros_atuais >= maximo_erros_permitidos:
		game_over()

func game_over():
	print("GAME OVER - Errou demais!")
	jogo_ativo = false
	audio_player.stop()
	
	if game_over_ui:
		game_over_ui.exibir_game_over()

func _on_fim_da_musica():
	# Se a música acabou e não atingiu o limite de erros, Ganhou!
	if erros_atuais < maximo_erros_permitidos and jogo_ativo:
		Global.registrar_vitoria_sapo()
		get_tree().change_scene_to_file("res://ui/TelaVitoria.tscn")
