extends Node

var bgm_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback

@export var sample_hz: float = 22050.0
@export var note_duration: float = 0.5
@export var volume_db: float = -12.0

var pulse_hz: float = 0.0
var phase: float = 0.0
var time_passed: float = 0.0
var current_note: int = 0

var notes: Array[float] = [
	130.81, 146.83, 130.81, 164.81, 
	130.81, 196.00, 164.81, 146.83
] # C3, D3, C3, E3, C3, G3, E3, D3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_player()

func _setup_audio_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = sample_hz
	stream.buffer_length = 0.1
	
	bgm_player.stream = stream
	bgm_player.volume_db = volume_db
	bgm_player.play()
	
	playback = bgm_player.get_stream_playback()
	_fill_buffer()

func _process(delta: float) -> void:
	time_passed += delta
	if time_passed >= note_duration:
		time_passed = 0.0
		current_note = (current_note + 1) % notes.size()
		pulse_hz = notes[current_note]
		
	_fill_buffer()

func _fill_buffer() -> void:
	var frames_available := playback.get_frames_available()
	if frames_available > 0:
		var increment := pulse_hz / sample_hz
		for i in range(frames_available):
			# Retro square wave with envelope
			var sample: float = sign(sin(phase * TAU)) * 0.5
			var envelope: float = 1.0 - (time_passed / note_duration)
			sample *= envelope * 0.4
			
			playback.push_frame(Vector2.ONE * sample)
			phase = fmod(phase + increment, 1.0)
