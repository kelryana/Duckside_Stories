extends Control

func _on_botao_continuar_pressed():
	# Verifica no Global se já ganhamos OS DOIS jogos
	if Global.venceu_sapo == true and Global.venceu_nuvem == true:
		# Se já ganhou tudo, vai para a tela de Fim de Demo
		get_tree().change_scene_to_file("res://ui/TelaFinal.tscn")
	else:
		# Se ainda falta algum, volta para a Vila para procurar o outro NPC
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
