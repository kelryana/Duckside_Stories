extends Area2D

@export var float_amplitude: float = 5.0
@export var float_speed: float = 4.0

var start_y: float = 0.0
var time: float = 0.0

func _ready():
	start_y = position.y
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	var target_scale = scale  # 1. Salva a escala definida pelo Manager
	scale = Vector2.ZERO      # 2. Zera para fazer o efeito de pop-up
	
	var tween = create_tween()
	# 3. Anima até o target_scale que salvamos
	tween.tween_property(self, "scale", target_scale, 0.4).set_trans(Tween.TRANS_BACK)

func _process(delta):
	time += delta
	position.y = start_y + sin(time * float_speed) * float_amplitude

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("activate_shield_buff"):
			body.activate_shield_buff()
			print("🛡️ Escudo Coletado!")
			queue_free()
