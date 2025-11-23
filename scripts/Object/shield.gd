extends Area2D

# Sinal necessário para o MinigameManager saber que o slot está livre
signal collected

# Variável que o Manager vai preencher (tempo de duração do escudo)
var shield_duration: float = 5.0

@export_group("Configurações Visuais")
@export var float_amplitude: float = 10.0 # Altura da flutuação
@export var float_speed: float = 3.0      # Velocidade da flutuação
@export var rotation_speed: float = 1.0   # Velocidade de giro (opcional)

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null

var start_y: float = 0.0
var time_passed: float = 0.0
var is_collected: bool = false

func _ready():
	# Salva a posição Y inicial para a animação
	start_y = position.y
	
	# Conecta o sinal de entrada de corpo (se o player entrar na área)
	body_entered.connect(_on_body_entered)
	
	# Efeito visual de surgir (Pop-up)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta):
	if is_collected:
		return
		
	# Animação de flutuação e rotação suave
	time_passed += delta
	
	# Flutuar para cima e para baixo (Senoide)
	var new_y = start_y + sin(time_passed * float_speed) * float_amplitude
	position.y = new_y
	
	# Rotação suave (opcional)
	if rotation_speed > 0:
		rotation += rotation_speed * delta

func _on_body_entered(body: Node2D):
	if is_collected:
		return
		
	# Verifica se é o Player
	# DICA: Certifique-se que seu Player está no grupo "player" ou mude a verificação
	if body.is_in_group("player") or body.name == "Player":
		_collect(body)

func _collect(player):
	is_collected = true
	
	print("Shield PowerUp: Coletado! Duração: %.1fs" % shield_duration)
	
	# 1. Aplica o escudo no Player
	if player.has_method("activate_shield"):
		player.activate_shield(shield_duration)
	else:
		push_warning("ShieldPowerUp: O Player não tem a função 'activate_shield'!")
	
	# 2. Avisa o Manager (IMPORTANTE)
	emit_signal("collected")
	
	# 3. Feedback visual/sonoro antes de sumir
	collision_shape.set_deferred("disabled", true) # Desativa colisão
	sprite.visible = false # Esconde sprite
	
	if audio_player and audio_player.stream:
		audio_player.play()
		# Aguarda o som terminar antes de deletar
		await audio_player.finished
		queue_free()
	else:
		# Se não tiver som, deleta imediatamente com uma pequena animação de saída
		queue_free()
