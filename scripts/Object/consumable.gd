extends Area2D

signal collected

@export_group("Visual")
@export var float_amplitude: float = 10.0
@export var float_speed: float = 3.0

@export_group("Lifetime")
@export var lifetime: float = 15.0

var start_y: float = 0.0
var time_passed: float = 0.0
var lifetime_timer: float = 0.0
var is_collected: bool = false

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null

func _ready():
	start_y = position.y
	lifetime_timer = lifetime
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	var target_scale = scale  # 1. Salva a escala definida pelo Manager
	scale = Vector2.ZERO      # 2. Zera para fazer o efeito de pop-up
	
	var tween = create_tween()
	# 3. Anima até o target_scale que salvamos
	tween.tween_property(self, "scale", target_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta):
	if is_collected: return
	
	time_passed += delta
	position.y = start_y + sin(time_passed * float_speed) * float_amplitude
	
	if lifetime > 0:
		lifetime_timer -= delta
		if lifetime_timer <= 3.0:
			sprite.modulate.a = 0.5 if int(lifetime_timer * 5) % 2 == 0 else 1.0
		if lifetime_timer <= 0:
			emit_signal("collected")
			queue_free()

func _on_body_entered(body):
	if is_collected: return
	if body.is_in_group("player"):
		if body.has_method("collect_consumable_item"):
			var foi_coletado = body.collect_consumable_item()
			if foi_coletado: _finalize_collection()

func _finalize_collection():
	is_collected = true
	emit_signal("collected")
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	if audio_player and audio_player.stream:
		audio_player.play()
		await audio_player.finished
	queue_free()
