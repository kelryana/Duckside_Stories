extends CharacterBody2D

@onready var anim_player2 = $AnimationPlayer

func _ready() -> void:
	anim_player2.play("idle_anim")
