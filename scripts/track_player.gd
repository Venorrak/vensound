extends Node2D

signal finished

var notePlayers : Array[Dictionary]
#{
	#"player": AudioStreamPlayer.new(),
	#"playback": AudioStreamPlayback.new()
#}

var musicBuffersByNotes: Array[Array] = []
#{
	#"buffer": [],
	#"start_at": 0.0
	#"buffer_length": 0.0
#}

@export var musicTime : Timer
@export var testAudioStream : AudioStreamPlayer

var sample_hz : float = 22050.0
var playing : bool = false

var currentTrack : Dictionary = {}
var settings : Dictionary = {}

func _ready() -> void:
	for i in 84:
		musicBuffersByNotes.append([])
		var newAudioStreamPlayer = AudioStreamPlayer.new()
		var newAudioStream = AudioStreamGenerator.new()
		newAudioStream.mix_rate = sample_hz
		newAudioStreamPlayer.stream = newAudioStream
		newAudioStreamPlayer.volume_db = currentTrack["synth"]["volume"]
		add_child(newAudioStreamPlayer)
		newAudioStreamPlayer.play()
		var playback = newAudioStreamPlayer.get_stream_playback()
		newAudioStreamPlayer.stop()
		notePlayers.append({
			"player": newAudioStreamPlayer,
			"playback": playback
		})
	testAudioStream.play()
	preloadBuffers()
	play()

func _process(delta: float) -> void:
	if playing:
		var currentTime : float = musicTime.wait_time - musicTime.time_left
		for i in 84:
			if not musicBuffersByNotes[i].is_empty() && musicBuffersByNotes[i][0]["start_at"] <= currentTime:
				notePlayers[i]["player"].stop()
				notePlayers[i]["player"].stream.buffer_length = musicBuffersByNotes[i][0]["buffer_length"]
				notePlayers[i]["player"].play()
				notePlayers[i]["player"].get_stream_playback().push_buffer(musicBuffersByNotes[i][0]["buffer"])
				musicBuffersByNotes[i].remove_at(0)

func play() -> void:
	musicTime.start(getLength(settings["musicLength"], settings["tempo"]))
	playing = true

func preloadBuffers() -> void:
	for note in currentTrack["chart"]:
		var noteBuffer : PackedVector2Array = _fill_buffer(note["freq"], note["length"])
		musicBuffersByNotes[MusicRef.getLine(note["freq"])].append({
			"buffer": noteBuffer,
			"start_at": getLength(note["start_at"], settings["tempo"]),
			"buffer_length": getLength(note["length"], settings["tempo"])
		})
	for note in musicBuffersByNotes:
		note.sort_custom(sort_ascending_start)

func sort_ascending_start(a, b):
	if a["start_at"] < b["start_at"]:
		return true
	return false
	
func _fill_buffer(freq: float, length: int) -> PackedVector2Array:
	var phase : float = 0.0
	var increment : float = freq / sample_hz
	testAudioStream.stream.buffer_length = getLength(length, settings["tempo"])
	var to_fill : int = testAudioStream.get_stream_playback().get_frames_available()
	var fade_length : int = 150
	var fade_start : int = to_fill - fade_length
	var buffer : PackedVector2Array = []
	for i in to_fill:
		var amp : float = 1.0
		if i >= fade_start:
			amp = 1.0 - smoothstep(fade_start, to_fill, i)
		buffer.append(Vector2.ONE * sin(phase * TAU) * amp)
		phase = fmod(phase + increment, 1.0)
	return buffer
	
func getLength(duration : int, tempo: int) -> float:
	# 60 -> 60 beats per minute
	return ((60.0 / tempo) / 8) * duration 

func _on_timer_timeout() -> void:
	playing = false
	for player in notePlayers:
		if is_instance_valid(player):
			player["player"].free()
	finished.emit(self)
	print("delete")
