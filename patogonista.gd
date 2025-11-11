extends CharacterBody2D

@export var speed = 600.0
@onready var sprite: Sprite2D = $Sprite2D
const MUNDO_DA_NUVEM = "res://NuvemMinigame.tscn"

func _physics_process(_delta):
	var direction = Input.get_vector("esquerda", "direita", "cima", "baixo")
	
	print("Direção do Input: ", direction)

	velocity = direction * speed
	move_and_slide()
	
	if velocity.x < 0:
		sprite.flip_h = false
	elif velocity.x > 0:
		sprite.flip_h = true
	
func _on_porta_nuvem_trigger_body_entered(body):

	if body.is_in_group("player"):
		get_tree().change_scene_to_file(MUNDO_DA_NUVEM)
