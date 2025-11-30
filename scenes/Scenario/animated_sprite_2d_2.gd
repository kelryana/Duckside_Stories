extends AnimatedSprite2D

func _ready():
	# Começa parado dançando (ou respirando)
	play("idle")
	# Garante que não está virado
	flip_h = false 

# NÃO TEM func _process. Se não tem process, ele não anda.
