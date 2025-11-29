extends Node2D

@export var note_scene: PackedScene
@onready var spawn_point = $Pista/SpawnPoint
@onready var hit_zone = $Pista/ZonaDeAcerto

func _on_conductor_beat(beat_number):
	# Exemplo: Spawna uma nota a cada batida par
	if beat_number % 2 == 0:
		spawn_note()

func spawn_note():
	var note = note_scene.instantiate()
	$Pista/NotasContainer.add_child(note)
	note.global_position = spawn_point.global_position
	
	# Configura a nota
	note.target_y = hit_zone.global_position.y
	# A velocidade tem que ser calculada para a nota chegar na zona EXATAMENTE na batida
	# (Isso é matemática avançada, o tutorial explica a fórmula "Distância / Tempo")
