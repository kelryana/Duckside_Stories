extends Node

# Dados persistentes do player
var player_position: Vector2 = Vector2.ZERO
var player_velocity: Vector2 = Vector2.ZERO
var is_angry_cloud_game: bool = false

func change_to_cloud_world():
	is_angry_cloud_game = true
	get_tree().change_scene_to_file("res://NuvemMinigame.tscn")

func change_to_main_world():
	is_angry_cloud_game = false
	get_tree().change_scene_to_file("res://Main.tscn")  # Ajuste o nome da sua cena principal

func save_player_state(player: CharacterBody2D):
	player_position = player.global_position
	player_velocity = player.velocity

func restore_player_state(player: CharacterBody2D):
	player.global_position = player_position
	player.velocity = player_velocity
	player.is_angry_cloud_game = is_angry_cloud_game
