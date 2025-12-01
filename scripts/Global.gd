extends Node

# Variáveis para guardar se o jogador venceu cada minigame
var venceu_sapo = false
var venceu_nuvem = false

# Função para marcar vitória (usaremos isto nos minigames)
func registrar_vitoria_sapo():
	venceu_sapo = true
	print("Vitória no Sapo registada!")

func registrar_vitoria_nuvem():
	venceu_nuvem = true
	print("Vitória na Nuvem registada!")

# Verifica se os dois desafios foram completados
func jogo_completo():
	if venceu_sapo == true and venceu_nuvem == true:
		return true
	else:
		return false

# Reinicia tudo (para o botão "Jogar Novamente" no final)
func reiniciar_jogo():
	venceu_sapo = false
	venceu_nuvem = false
