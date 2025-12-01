extends Node2D

# ==============================================================================
# CONFIGURAÇÕES VISUAIS E DE LAYOUT
# ==============================================================================
@export_group("Layout Adaptativo")
@export var background_texture: TextureRect
@export var lane_labels: Array[Label]
@export var gameplay_width: float = 600.0

@export_subgroup("Ajustes de Posição")
@export var hit_line_offset: float = 100.0
@export var label_y_offset: float = 30.0

# ==============================================================================
# REFERÊNCIAS E LÓGICA DO JOGO
# ==============================================================================
@export_group("Lógica do Jogo")
# Nota: Removemos a variável game_over_ui daqui, pois buscaremos via código
@export var audio_player: AudioStreamPlayer
@export var maximo_erros_permitidos: int = 5

@export_subgroup("Cenas e Spawns")
@export var nota_scene: PackedScene
@export var conductor: Node
@export var texturas_moscas: Array[Texture2D]
@export var spawn_positions: Array[Node2D]
@export var hit_positions: Array[Area2D]

# Variáveis Internas
var erros_atuais: int = 0
var jogo_ativo: bool = true
var input_map: Array = ["UP", "DOWN", "LEFT", "RIGHT"]

func _ready():
	erros_atuais = 0
	jogo_ativo = true
	
	# Conexões
	if conductor:
		if not conductor.beat.is_connected(_on_conductor_beat):
			conductor.beat.connect(_on_conductor_beat)
	
	if audio_player:
		if not audio_player.finished.is_connected(_on_fim_da_musica):
			audio_player.finished.connect(_on_fim_da_musica)
	
	# Background
	if background_texture:
		background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# Configurações iniciais dos Labels (reset de âncoras)
	for lbl in lane_labels:
		if lbl:
			lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
			lbl.grow_horizontal = Control.GROW_DIRECTION_END
			lbl.grow_vertical = Control.GROW_DIRECTION_END
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Monitorar redimensionamento da tela
	get_tree().root.size_changed.connect(_on_screen_resized)
	
	# Ajusta layout no primeiro frame
	await get_tree().process_frame
	_adjust_layout()

func _on_screen_resized():
	await get_tree().process_frame
	_adjust_layout()

# ==============================================================================
# SISTEMA DE POSICIONAMENTO INTELIGENTE
# ==============================================================================
func _adjust_layout():
	if not background_texture: return

	# 1. Ajusta o Background
	ScreenUtils.fit_background_to_screen(background_texture)

	# 2. Pega os limites REAIS da tela
	var screen_rect = ScreenUtils.get_full_viewport_rect()
	
	var lane_width = gameplay_width / 4.0
	var start_lanes_x = screen_rect.get_center().x - (gameplay_width / 2.0)
	var hit_y_pos = screen_rect.end.y - hit_line_offset # end.y é o fundo da tela
	
	for i in range(4):
		var this_lane_center_x = start_lanes_x + (i * lane_width) + (lane_width / 2.0)
		
		# Spawner
		if spawn_positions.size() > i:
			spawn_positions[i].global_position = Vector2(this_lane_center_x, screen_rect.position.y - 50)
		
		# Hit Zone
		if hit_positions.size() > i:
			hit_positions[i].global_position = Vector2(this_lane_center_x, hit_y_pos)
		
		# --- CORREÇÃO DOS LABELS ---
		if lane_labels.size() > i and lane_labels[i]:
			var lbl = lane_labels[i]
			var hit_zone = hit_positions[i]
			
			# 1. Garante que o texto existe (pega do seu input_map: UP, DOWN...)
			if i < input_map.size():
				lbl.text = input_map[i]
			
			# 2. Garante que está visível e NA FRENTE de tudo
			lbl.visible = true
			lbl.z_index = 20 # Coloca numa camada bem alta
			lbl.modulate = Color.YELLOW # Garante cor branca
			
			# 3. Tamanho e Posição
			lbl.custom_minimum_size = Vector2(lane_width, 50)
			lbl.size = Vector2(lane_width, 50)
			
			# Centraliza o texto dentro da caixa do Label
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			var label_center_x = hit_zone.global_position.x
			var label_center_y = hit_zone.global_position.y + label_y_offset
			
			lbl.global_position = Vector2(
				label_center_x - (lane_width / 2.0),
				label_center_y - 25.0 
			)
# ==============================================================================
# LÓGICA DE JOGO E INPUT
# ==============================================================================
func _on_conductor_beat(_beat_number):
	if not jogo_ativo: return
	var pista_sorteada = randi() % 4
	spawnar_nota(pista_sorteada)

func spawnar_nota(indice_pista: int):
	if not nota_scene or spawn_positions.size() <= indice_pista: return
	
	var nova_nota = nota_scene.instantiate()
	add_child(nova_nota)
	
	nova_nota.global_position = spawn_positions[indice_pista].global_position
	nova_nota.target_y = hit_positions[indice_pista].global_position.y
	
	# Passa o ID da pista se a variável existir no script da nota
	if "lane_id" in nova_nota: 
		nova_nota.lane_id = indice_pista
	
	# Conecta o sinal de erro (nota passou da tela)
	if nova_nota.has_signal("note_missed"):
		nova_nota.note_missed.connect(_on_note_missed)
	
	var sprite = nova_nota.get_node_or_null("Sprite2D")
	if sprite and texturas_moscas.size() > indice_pista:
		sprite.texture = texturas_moscas[indice_pista]

func _input(event):
	if not jogo_ativo: return
	for i in range(4):
		if event.is_action_pressed(input_map[i]):
			checar_acerto(i)

func checar_acerto(indice_pista: int):
	var zona = hit_positions[indice_pista]
	var notas_na_zona = zona.get_overlapping_areas()
	
	if notas_na_zona.size() > 0:
		var nota = notas_na_zona[0]
		
		# Evita que a nota emita o sinal de erro ao ser destruída
		if nota.has_signal("note_missed") and nota.note_missed.is_connected(_on_note_missed):
			nota.note_missed.disconnect(_on_note_missed)
		
		nota.queue_free()
		# print("✓ Acerto na pista ", indice_pista)
	else:
		registrar_erro("Input errado na pista " + str(indice_pista))

func _on_note_missed():
	registrar_erro("Nota passou sem ser acertada")

func registrar_erro(motivo: String = ""):
	if not jogo_ativo: return # Não conta erros se o jogo já acabou

	erros_atuais += 1
	print("❌ Erro: %s | Total: %d/%d" % [motivo, erros_atuais, maximo_erros_permitidos])
	
	if erros_atuais >= maximo_erros_permitidos:
		game_over()

# ==============================================================================
# GAME OVER (INTEGRAÇÃO COM GRUPO)
# ==============================================================================
func game_over():
	if not jogo_ativo: return
	
	print("💀 GAME OVER - Chamando HUD...")
	jogo_ativo = false
	
	if audio_player:
		audio_player.stop()
	
	# 1. Procura na árvore o nó que está no grupo "GameOver"
	var hud_game_over = get_tree().get_first_node_in_group("GameOver")
	
	# 2. Verifica se encontrou e se tem o método correto
	if hud_game_over and hud_game_over.has_method("exibir_game_over"):
		hud_game_over.exibir_game_over()
	else:
		push_error("ERRO: Nó 'GameOver' não encontrado ou método 'exibir_game_over' inexistente!")
		# Fallback de emergência (opcional)
		if hud_game_over: hud_game_over.visible = true

func _on_fim_da_musica():
	# Só vence se a música acabar E o jogador não tiver perdido
	if erros_atuais < maximo_erros_permitidos and jogo_ativo:
		print("🎉 VITÓRIA - Música acabou!")
		jogo_ativo = false
		
		await get_tree().process_frame
		if is_inside_tree():
			get_tree().change_scene_to_file("res://ui/TelaVitoria.tscn")
