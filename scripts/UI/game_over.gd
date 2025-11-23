extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/VBoxContainer/Label
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@export var player: CharacterBody2D

func _ready():
	visible = false

	# Detecta quando qualquer nó entra na cena
	get_tree().connect("node_added", _on_node_added)

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		
	player.player_died.connect(_on_player_died)


func _on_node_added(node):
	if node.is_in_group("player"):
		# Conecta ao sinal de morte do player
		node.player_died.connect(_on_player_died)


func _on_player_died():
	visible = true
	get_tree().paused = true
	
	if panel:
		panel.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.5)


func _on_restart_pressed():
	get_tree().paused = false
	
	if GameManager:
		GameManager.reset_game()
		GameManager.change_to_cloud_world()
	else:
		get_tree().reload_current_scene()
		

func _on_quit_pressed():
	get_tree().paused = false

	if GameManager:
		GameManager.reset_game()
		GameManager.change_to_main_world()
	else:
		get_tree().change_scene_to_file("res://Main.tscn")
