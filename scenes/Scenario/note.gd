extends Area2D

@export var speed: float = 300.0 # Velocidade de queda
var target_y: float # A posição Y da Zona de Acerto
var hit_time: float # O momento exato que ela deve ser acertada (na música)

func _process(delta):
	# Move para baixo
	position.y += speed * delta
	
	# Se passar muito da zona de acerto, conta como erro (Miss)
	if position.y > target_y + 100:
		queue_free() # Destroi a nota
		# Aqui você avisaria o GameManager que errou
