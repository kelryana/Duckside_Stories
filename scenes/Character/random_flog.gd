extends CharacterBody2D

# --- CONFIGURAÇÕES (Ajuste no Inspector) ---
@export var speed = 60.0        # Velocidade do movimento
@export var distance = 200.0    # Distância que ele vai andar (em pixels)
@export var wait_time = 2.0     # Tempo que ele fica parado (idle)

# --- VARIÁVEIS INTERNAS ---
@onready var anim = $AnimatedSprite2D
var start_x = 0.0
var target_x = 0.0
var moving_right = true
var is_waiting = false

func _ready():
	# Guarda a posição inicial onde você colocou o sapo na cena
	start_x = position.x
	target_x = start_x + distance
	
	# Começa andando
	anim.play("walk")

func _physics_process(delta):
	
	print("Estou rodando!")
	# Se estiver esperando (Idle), não faz nada de movimento
	if is_waiting:
		return

	# Lógica de movimento
	if moving_right:
		position.x += speed * delta
		anim.flip_h = false # Sapo olhando para a direita
		
		# Chegou no limite da direita?
		if position.x >= target_x:
			start_idle_state()
	else:
		position.x -= speed * delta
		anim.flip_h = true  # Sapo olhando para a esquerda (espelhado)
		
		# Chegou no limite da esquerda (voltou pro início)?
		if position.x <= start_x:
			start_idle_state()

func start_idle_state():
	is_waiting = true
	anim.play("idle") # Toca a animação parado
	
	# Cria um temporizador simples
	await get_tree().create_timer(wait_time).timeout
	
	# Depois que o tempo acaba:
	change_direction()

func change_direction():
	moving_right = !moving_right # Inverte a direção (se era true vira false)
	is_waiting = false
	anim.play("walk") # Volta a andar
