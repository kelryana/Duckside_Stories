extends Node

# CONFIGURAÇÕES
@export var bpm: int = 124
@export var music_player: AudioStreamPlayer

# SINAL IMPORTANTE (O erro é porque isso aqui sumiu!)
signal beat(position)

# VARIÁVEIS
var sec_per_beat: float = 0.0
var song_position: float = 0.0
var song_position_in_beats: int = 0
var last_reported_beat: int = 0

func _ready():
	sec_per_beat = 60.0 / bpm

func _process(delta):
	if music_player and music_player.playing:
		song_position = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		song_position_in_beats = int(song_position / sec_per_beat)
		
		if song_position_in_beats > last_reported_beat:
			last_reported_beat = song_position_in_beats
			emit_signal("beat", last_reported_beat)
