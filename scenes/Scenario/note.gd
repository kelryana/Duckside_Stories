extends Node

# CONFIGURAÇÕES DA MÚSICA (Ajuste no Inspetor)
@export var bpm: int = 120  # Batidas por minuto da música
@export var music_player: AudioStreamPlayer # Arraste o AudioStreamPlayer aqui

# VARIÁVEIS INTERNAS
var sec_per_beat: float = 0.0
var song_position: float = 0.0
var song_position_in_beats: int = 0
var last_reported_beat: int = 0

# SINAL (Avisa o jogo quando tem batida)
signal beat(position)

func _ready():
	sec_per_beat = 60.0 / bpm

func _process(delta):
	if music_player and music_player.playing:
		# Calcula onde estamos na música (em segundos)
		song_position = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		
		# Calcula em qual batida estamos
		song_position_in_beats = int(song_position / sec_per_beat)
		
		# Se mudou de batida, avisa o jogo!
		if song_position_in_beats > last_reported_beat:
			last_reported_beat = song_position_in_beats
			emit_signal("beat", last_reported_beat)
			print("🥁 Batida: ", last_reported_beat)
