extends Control

# Caminho do Menu Principal
const MENU_INICIAL = "res://scenes/Scenario/main_menu.tscn"

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
