extends Area2D

# Sinal para avisar o MinigameManager que este item saiu de cena
signal collected

@export_group("Visual")
@export var float_amplitude: float = 10.0 # Altura da flutuação
@export var float_speed: float = 3.0      # Velocidade da flutuação

@export_group("Lifetime")
@export var lifetime: float = 15.0  # Tempo que o shield fica no mapa antes de sumir (0 = infinito)

# Variáveis internas
var start_y: float = 0.0
var time_passed: float = 0.0
var lifetime_timer: float = 0.0
var is_collected: bool = false # Trava para evitar coleta dupla

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null

func _ready():
	# Salva a altura inicial para flutuar em volta dela
	start_y = position.y
	lifetime_timer = lifetime
	
	# Conecta colisão (caso não tenha conectado pelo editor)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Animação de "Pop-up" ao nascer (cresce do zero)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta):
	# Se já foi pego, para de animar
	if is_collected:
		return
	
	# Animação de flutuação (Senoide)
	time_passed += delta
	var new_y = start_y + sin(time_passed * float_speed) * float_amplitude
	position.y = new_y
	
	# Sistema de tempo de vida (se configurado)
	if lifetime > 0:
		lifetime_timer -= delta
		
		# Pisca nos últimos 3 segundos
		if lifetime_timer <= 3.0:
			sprite.modulate.a = 0.5 if int(lifetime_timer * 5) % 2 == 0 else 1.0
		
		# Remove quando o tempo acabar
		if lifetime_timer <= 0:
			print("ShieldPowerUp: Tempo de vida esgotado, removendo...")
			emit_signal("collected")  # Avisa o manager que pode spawnar outro
			queue_free()

func _on_body_entered(body):
	if is_collected:
		return

	# Verifica se quem encostou é o Player
	if body.is_in_group("player"):
		
		# Verifica se o Player tem a função de inventário
		if body.has_method("collect_shield_item"):
			
			# Tenta entregar o item (sem passar duração - o player usa a própria configuração)
			var foi_coletado = body.collect_shield_item()
			
			if foi_coletado:
				_finalize_collection()
			else:
				print("ShieldPowerUp: Player encostou, mas inventário está cheio.")

func _finalize_collection():
	is_collected = true
	print("ShieldPowerUp: Coletado com sucesso!")
	
	# 1. Avisa o Manager para liberar o slot de spawn
	emit_signal("collected")
	
	# 2. Desativa colisão e visual imediatamente
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	
	# 3. Toca som e deleta
	if audio_player and audio_player.stream:
		audio_player.play()
		await audio_player.finished
		queue_free()
	else:
		queue_free()
