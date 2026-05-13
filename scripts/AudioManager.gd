extends Node

var bgm_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var sample_hz = 22050.0
var pulse_hz = 0.0
var phase = 0.0

# Secuencia de notas (Frecuencias) para una melodía oscura
var notes = [130.81, 146.83, 130.81, 164.81, 130.81, 196.00, 164.81, 146.83] # C3, D3, C3, E3, C3, G3, E3, D3
var current_note = 0
var time_passed = 0.0
var note_duration = 0.5

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Seguir sonando en pausa (opcional, o podemos pararlo)
	
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_hz
	stream.buffer_length = 0.1
	bgm_player.stream = stream
	bgm_player.play()
	bgm_player.volume_db = -10.0 # No muy alto
	
	playback = bgm_player.get_stream_playback()
	fill_buffer()

func _process(delta):
	time_passed += delta
	if time_passed >= note_duration:
		time_passed = 0.0
		current_note = (current_note + 1) % notes.size()
		pulse_hz = notes[current_note]
		
	fill_buffer()

func fill_buffer():
	var frames_available = playback.get_frames_available()
	if frames_available > 0:
		var increment = pulse_hz / sample_hz
		for i in range(frames_available):
			# Generar onda cuadrada suave para darle toque retro
			var sample = sign(sin(phase * TAU)) * 0.5
			# Aplicar un pequeño filtro/volumen envelope simulado
			var envelope = 1.0 - (time_passed / note_duration)
			sample *= envelope * 0.5
			
			playback.push_frame(Vector2.ONE * sample)
			phase = fmod(phase + increment, 1.0)
