extends Control
# Caminho do Menu Principal
const MENU_INICIAL = "res://scenes/Scenario/main_menu.tscn"

# ==============================================================================
# REFERÊNCIAS VISUAIS (Arraste os nós aqui no Inspector)
# ==============================================================================
@export_group("Elementos de Tela")
@export var background_color: ColorRect
@export var titulo_label: Label
@export var botao_continuar: BaseButton # Aceita Button ou TextureButton
@export var botao_sair: BaseButton
@export var decoracao_esq: Sprite2D
@export var decoracao_dir: Sprite2D

func _ready():
	# Configurações iniciais
	_update_layout()
	get_tree().root.size_changed.connect(_update_layout)

# ==============================================================================
# ORGANIZAÇÃO DO LAYOUT
# ==============================================================================
func _update_layout():
	# 1. Ajusta o Fundo (ColorRect)
	if background_color:
		ScreenUtils.fit_background_to_screen(background_color)
	
	# Pega os dados da tela
	var screen_rect = ScreenUtils.get_full_viewport_rect()
	var centro = screen_rect.get_center()
	
	# 2. Centraliza o Título (Topo)
	if titulo_label:
		# Centraliza o pivô do texto (opcional, ajuda no alinhamento)
		titulo_label.pivot_offset = titulo_label.size / 2
		# Coloca no centro horizontal, e um pouco acima do meio vertical (ex: 30% da altura)
		titulo_label.global_position = Vector2(
			centro.x - (titulo_label.size.x / 2),
			screen_rect.position.y + (screen_rect.size.y * 0.3) 
		)

	# 3. Centraliza os Botões (Pilha Vertical)
	# Vamos colocar o 'Continuar' no meio e o 'Sair' logo abaixo
	if botao_continuar:
		botao_continuar.global_position = Vector2(
			centro.x - (botao_continuar.size.x / 2),
			centro.y # Exatamente no meio
		)
		
	if botao_sair:
		# Coloca 80 pixels abaixo do botão continuar (ajuste esse 80 como quiser)
		var y_pos = centro.y + 80 
		if botao_continuar:
			y_pos = botao_continuar.global_position.y + botao_continuar.size.y + 20
			
		botao_sair.global_position = Vector2(
			centro.x - (botao_sair.size.x / 2),
			y_pos
		)

	# 4. Decorações (Sprites nas laterais)
	if decoracao_esq:
		# Canto inferior esquerdo
		decoracao_esq.global_position = Vector2(
			screen_rect.position.x + 100, # 100px da esquerda
			screen_rect.end.y - 100       # 100px do fundo
		)
		
	if decoracao_dir:
		# Canto inferior direito
		decoracao_dir.global_position = Vector2(
			screen_rect.end.x - 100,      # 100px da direita
			screen_rect.end.y - 100
		)

# --- Botão "JOGAR DENOVO" (No teu editor chama-se BotaoContinuar) ---
func _on_botao_continuar_pressed() -> void:
	# 1. Reseta o progresso no Global (Importante!)
	if Global:
		Global.venceu_sapo = false
		Global.venceu_nuvem = false
	
	# 2. Volta para o Menu Inicial
	# (Assim o jogador vê a tela de título de novo e clica em JOGAR)
	get_tree().change_scene_to_file(MENU_INICIAL)


# --- Botão "SAIR" (No editor chama-se SAIRjogo) ---
func _on_sai_rjogo_pressed() -> void:
	# Fecha o jogo
	get_tree().quit()
	
