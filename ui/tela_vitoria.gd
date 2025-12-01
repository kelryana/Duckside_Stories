extends Control

# 1. Arraste sua TextureRect de fundo para cá no Inspector
@export var background_texture: TextureRect

func _ready():
	# Ajusta o tamanho assim que a tela abre
	_update_layout()
	
	# Garante que ajuste de novo se a janela mudar de tamanho
	get_tree().root.size_changed.connect(_update_layout)

func _update_layout():
	# Chama o seu ScreenUtils mágico
	if background_texture:
		ScreenUtils.fit_background_to_screen(background_texture)

func _on_botao_continuar_pressed():
	# Verifica no Global se já ganhamos OS DOIS jogos
	if Global.venceu_sapo == true and Global.venceu_nuvem == true:
		# Se já ganhou tudo, vai para a tela de Fim de Demo
		get_tree().change_scene_to_file("res://ui/TelaFinal.tscn")
	else:
		# Se ainda falta algum, volta para a Vila para procurar o outro NPC
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
