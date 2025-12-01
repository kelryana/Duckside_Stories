extends Control

# IMPORTANTE: Confirma se "res://scenes/Main.tscn" é mesmo a cena da VILA/JOGO.
# Se o nome do arquivo da vila for diferente, altera aqui.
const GAME_SCENE = "res://scenes/Main.tscn"

func _on_jogar_pressed() -> void:
	# Muda para a cena do jogo (Vila)
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_sair_pressed() -> void:
	print("Cliquei em Sair!")
	# Fecha o jogo
	get_tree().quit()
