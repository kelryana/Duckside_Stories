extends CharacterBody2D

@export var SPEED = 200
@export var JUMP_VELOCITY = -400
@export var GRAVITY = 900
@export var screen_margin: float = 20.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

const MUNDO_DA_NUVEM = "res://NuvemMinigame.tscn"
var is_cloud_game: bool = false

func get_input():
	
	velocity.x = 0
	var RIGHT = Input.is_action_pressed("RIGHT")
	var LEFT = Input.is_action_pressed("LEFT")
	var JUMP = Input.is_action_just_pressed("JUMP") if is_cloud_game else null
	var UP = Input.is_action_pressed("UP") if not is_cloud_game else null
	var DOWN = Input.is_action_pressed("DOWN") if not is_cloud_game else null
	
	if RIGHT: 
		velocity.x = SPEED
	elif LEFT:
		velocity.x = -SPEED
	
	sprite.flip_h = not velocity.x < 0
	
	if UP:
		velocity.y = -SPEED
	elif DOWN:
		velocity.y = SPEED
		
	if is_on_floor() and JUMP:
		velocity.y = JUMP_VELOCITY
		
func _physics_process(delta):
	
	get_input()
	
	if is_cloud_game:	
		move_and_slide()
		var bounds = get_screen_bounds()
		global_position = global_position.clamp(bounds.position, bounds.end)
		
		if not is_on_floor():
			velocity.y += GRAVITY * delta
			move_and_slide()
			
	else:
		
		move_and_slide()
		
func _on_porta_nuvem_trigger_body_entered(body):

	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", MUNDO_DA_NUVEM)
	
func get_screen_bounds() -> Rect2:
	# Busca a câmera ativa automaticamente
	var camera = get_viewport().get_camera_2d()
	
	if not camera:
		# Fallback: retorna bounds baseado na posição do player
		var viewport_size = get_viewport_rect().size
		return Rect2(
			global_position - viewport_size / 2 + Vector2(screen_margin, screen_margin),
			viewport_size - Vector2(screen_margin * 2, screen_margin * 2)
		)
	
	# Pega o retângulo visível da câmera em coordenadas globais
	var viewport_size = get_viewport_rect().size
	var camera_pos = camera.get_screen_center_position()
	
	# Calcula os limites considerando o zoom da câmera
	var zoom = camera.zoom
	var half_size = (viewport_size / zoom) / 2.0
	
	return Rect2(
		camera_pos - half_size + Vector2(screen_margin, screen_margin),
		viewport_size / zoom - Vector2(screen_margin * 2, screen_margin * 2)
	)
