extends Node

@export var bpm: int = 120 # Batidas por minuto da sua música
@export var music_player: AudioStreamPlayer

var crotchet: float # Duração de uma batida em segundos (60 / bpm)
var song_position: float = 0.0
var offset: float = 0.0 # Ajuste se a música demorar pra começar

signal beat_signal(beat_number) # Avisa o jogo a cada batida

func _ready():
	crotchet = 60.0 / bpm

func _process(delta):
	if music_player.playing:
		song_position = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		
		# Calcula em qual batida estamos
		var current_beat = int(song_position / crotchet)
		emit_signal("beat_signal", current_beat)
