extends AnimatedSprite2D

@export var speed: float = 150.0
var chegou_no_meio: bool = false
var centro_da_tela: float = 640.0 # Metade da tela (se sua largura for 1280)

func _ready():
	# Começa fora da tela na esquerda (opcional) ou onde você colocou
	play("walk") # Começa andando

func _process(delta):
	if not chegou_no_meio:
		# Anda em direção ao centro
		position.x = move_toward(position.x, centro_da_tela, speed * delta)
		
		# Se chegou no alvo (centro)
		if position.x == centro_da_tela:
			chegou_no_meio = true
			print("Sapo chegou no palco!")
			# Toca a animação de dança (se não tiver 'dance', use 'idle')
			if sprite_frames.has_animation("walf"):
				play("walk") 
			else:
				play("idle")
