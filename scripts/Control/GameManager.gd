extends Node

# Caminhos das cenas
const MAIN_WORLD = "res://scenes/Main.tscn"
const CLOUD_WORLD = "res://scenes/Scenario/AngryCloud.tscn"

# Dados persistentes do player
var player_position: Vector2 = Vector2.ZERO
var player_velocity: Vector2 = Vector2.ZERO
var is_angry_cloud_game: bool = false
var player_health: int = 100  # Exemplo de dado adicional

func change_to_cloud_world():
	"""Muda para o mundo das nuvens"""
	is_angry_cloud_game = true
	_change_scene(CLOUD_WORLD)
	
	return true

func change_to_main_world():
	"""Volta para o mundo principal"""
	is_angry_cloud_game = false
	_change_scene(MAIN_WORLD)

func _change_scene(scene_path: String):
	"""Troca de cena de forma segura"""
	# Pode adicionar fade/transição aqui
	get_tree().call_deferred("change_scene_to_file", scene_path)

func save_player_state(player: CharacterBody2D):
	"""Salva todos os dados do player"""
	if not player:
		return
	
	player_position = player.global_position
	player_velocity = player.velocity
	
	# Salva dados adicionais se existirem
	if player.has_method("get_current_health"):
		player_health = player.get_current_health()
		
	print("GameManager: Estado salvo - Pos: %s, Cloud Mode: %s" % [player_position, is_angry_cloud_game])

func restore_player_state(player: CharacterBody2D):
	"""Restaura todos os dados do player"""
	if not player:
		return
	
	# Só restaura se houver dados salvos (não é o primeiro spawn)
	if player_position != Vector2.ZERO:
		player.global_position = player_position
		player.velocity = player_velocity
		player.is_angry_cloud_game = is_angry_cloud_game
		
		# Restaura dados adicionais
	if player.has_method("get_current_health"):
		player.current_health = player_health

	if player.has_signal("health_changed"):
		player.emit_signal("health_changed", player.current_health, player.max_health)
		print("GameManager: Estado restaurado")
		
func reset_game():
	"""Reseta o estado do jogo"""
	player_position = Vector2.ZERO
	player_velocity = Vector2.ZERO
	is_angry_cloud_game = false
	player_health = 100

func on_player_death():
	"""Chamado quando o player morre"""
	print("GameManager: Player morreu! Reiniciando minigame...")
	
	# Aguarda um pouco antes de reiniciar
	await get_tree().create_timer(2.0).timeout
	
	# Reseta estado e volta para o minigame
	reset_game()
	change_to_cloud_world()
