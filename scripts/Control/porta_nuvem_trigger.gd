extends Area2D

# Configuração da porta
@export var destination_scene: String = "res://scenes/Scenario/AngryCloud.tscn"  # Cena de destino
@export var is_cloud_world_entrance: bool = true  # Se true, ativa modo cloud; se false, desativa

# Visual/Feedback (opcional)
@export var portal_sprite: Sprite2D
@export var enable_visual_feedback: bool = true

var player_nearby: bool = false

func _ready():
	# Conecta sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Adiciona feedback visual (opcional)
	if enable_visual_feedback and portal_sprite:
		_setup_visual_feedback()

func _setup_visual_feedback():
	"""Configura animação visual da porta"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(portal_sprite, "modulate:a", 0.5, 1.0)
	tween.tween_property(portal_sprite, "modulate:a", 1.0, 1.0)

func _on_body_entered(body):
	"""Detecta quando o player entra na área"""
	if body.is_in_group("player"):
		player_nearby = true
		_show_prompt()  # Mostra dica "Pressione E para entrar" (opcional)

func _on_body_exited(body):
	"""Detecta quando o player sai da área"""
	if body.is_in_group("player"):
		player_nearby = false
		_hide_prompt()

func _physics_process(_delta):
	"""Verifica se o player quer entrar na porta"""
	if player_nearby and Input.is_action_just_pressed("ui_accept"):  # Tecla Enter/Espaço
		_use_portal()

func _use_portal():
	"""Ativa a transição de cena"""
	var player = _get_player()
	if not player:
		return
	
	# Salva estado do player
	if GameManager:
		GameManager.save_player_state(player)
		
		# Troca de cena
		if is_cloud_world_entrance:
			GameManager.change_to_cloud_world()
		else:
			GameManager.change_to_main_world()

func _get_player() -> CharacterBody2D:
	"""Busca o player na cena"""
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			return body
	return null

# Funções de feedback visual (opcional - implemente conforme necessário)
func _show_prompt():
	"""Mostra indicação visual que pode usar a porta"""
	# Exemplo: mostrar Label "Pressione E"
	pass

func _hide_prompt():
	"""Esconde indicação visual"""
	pass
