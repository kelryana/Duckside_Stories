extends CanvasLayer

func _ready():
	visible = false 
	process_mode = Node.PROCESS_MODE_ALWAYS 

func exibir_game_over():
	visible = true
	get_tree().paused = true 

# --- AQUI ESTÁ A CORREÇÃO ---
# O Godot conectou a estas funções com "button" no nome.
# Movi o código para cá.

func _on_restart_button_pressed() -> void:
	get_tree().paused = false 
	get_tree().reload_current_scene() 

func _on_quit_button_pressed() -> void:
	get_tree().paused = false 
	# Mudei de main_menu.tscn para Main.tscn (que é a sua Vila)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
