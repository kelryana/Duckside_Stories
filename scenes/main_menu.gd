extends Control
const GAME_SCENE = "res://scenes/Main.tscn"

func _on_jogar_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_sair_pressed() -> void:
	pass # Replace with function body.
	get_tree().quit()
