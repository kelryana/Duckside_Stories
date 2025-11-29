extends CharacterBody2D

# --- CONFIGURAÇÕES ---
@export var speed = 60.0        # Velocidade
@export var distance = 200.0    # Distância da patrulha
@export var wait_time = 2.0     # Tempo de espera

# --- VARIÁVEIS ---
@onready var anim = $AnimatedSprite2D
var start_x = 0.0
var target_x = 0.0
var moving_right = true
var is_waiting = false

func _ready():
	start_x = position.x
	target_x = start_x + distance
	
	# IMPORTANTE: Garanta que você criou uma animação chamada "walk" no AnimatedSprite2D
	anim.play("walk")

func _physics_process(delta):
	if is_waiting:
		return

	if moving_right:
		position.x += speed * delta
		anim.flip_h = true # Olha para a direita
		if position.x >= target_x:
			start_idle_state()
	else:
		position.x -= speed * delta
		anim.flip_h = false  # Olha para a esquerda
		if position.x <= start_x:
			start_idle_state()

func start_idle_state():
	is_waiting = true
	# IMPORTANTE: Garanta que existe a animação "idle"
	anim.play("idle") 
	
	await get_tree().create_timer(wait_time).timeout
	change_direction()

func change_direction():
	moving_right = !moving_right
	is_waiting = false
	anim.play("walk")
