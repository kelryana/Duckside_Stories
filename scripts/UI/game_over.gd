extends CanvasLayer

func _ready():
	visible = false # Começa escondido
	process_mode = Node.PROCESS_MODE_ALWAYS # IMPORTANTE: Funciona mesmo com o jogo pausado

# Função que alguém de fora vai chamar para mostrar a tela
func exibir_game_over():
	visible = true
	get_tree().paused = true # Congela o jogo

func _on_restart_pressed():
	get_tree().paused = false # Despausa
	get_tree().reload_current_scene() # Reinicia a fase

func _on_quit_pressed():
	get_tree().paused = false # Despausa
	# VERIFICA SE O CAMINHO DO MENU ESTÁ CERTO
	get_tree().change_scene_to_file("res://scenes/Scenario/main_menu.tscn")
