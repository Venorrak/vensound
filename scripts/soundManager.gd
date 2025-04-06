extends Node2D

@export var musicTime : Timer

var currentPlayingNote = null
#{
	#"player": AudioStreamPlayer.new()
	#"playback": AudioStreamPlayback.new(),
	#"freq": 123132.0
	#"phase": 0.0
	#"bufferFilled": false
#}

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

var playing : bool = false
var sample_hz : float = 22050.0

func _ready() -> void:
	for i in 84:
		musicBuffersByNotes.append([])
		var newAudioStreamPlayer = AudioStreamPlayer.new()
		var newAudioStream = AudioStreamGenerator.new()
		newAudioStream.mix_rate = sample_hz
		newAudioStreamPlayer.stream = newAudioStream
		newAudioStreamPlayer.volume_db = -20.0
		add_child(newAudioStreamPlayer)
		newAudioStreamPlayer.play()
		var playback = newAudioStreamPlayer.get_stream_playback()
		newAudioStreamPlayer.stop()
		notePlayers.append({
			"player": newAudioStreamPlayer,
			"playback": playback
		})

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

func playNote(freq: float, duration: int, tempo: int) -> void:
	if currentPlayingNote:
		handleNoteEnd()
	var newAudioStreamPlayer = AudioStreamPlayer.new()
	var newAudioStream = AudioStreamGenerator.new()
	newAudioStream.buffer_length = getLength(duration, tempo)
	newAudioStream.mix_rate = sample_hz
	newAudioStreamPlayer.stream = newAudioStream
	newAudioStreamPlayer.volume_db = -20.0
	add_child(newAudioStreamPlayer)
	currentPlayingNote = {
		"player": newAudioStreamPlayer,
		"playback": null,
		"freq": freq,
		"phase": 0.0,
		"bufferFilled": false
	}
	_fill_note_buffer(currentPlayingNote)

func playSound(music : Dictionary) -> void:
	clearMusic()
	preloadBuffers(music)
	startMusic(music)

func clearMusic() -> void:
	musicBuffersByNotes = []
	for i in 84:
		musicBuffersByNotes.append([])
	print("music cleared")

func startMusic(music: Dictionary) -> void:
	playing = true
	musicTime.wait_time = getLength(music["settings"]["musciLength"], music["settings"]["tempo"])
	musicTime.start()
	print("music started")

func preloadBuffers(music : Dictionary) -> void:
	for note in music["music"][0]["chart"]:
		var noteBuffer : PackedVector2Array = _fill_buffer(note["freq"], note["length"])
		musicBuffersByNotes[MusicRef.getLine(note["freq"])].append({
			"buffer": noteBuffer,
			"start_at": getLength(note["start_at"], music["settings"]["tempo"]),
			"buffer_length": getLength(note["length"], music["settings"]["tempo"])
		})
	for note in musicBuffersByNotes:
		note.sort_custom(sort_ascending_start)
	print("buffers loaded")

func sort_ascending_start(a, b):
	if a["start_at"] < b["start_at"]:
		return true
	return false

func _fill_note_buffer(playInfo : Dictionary) -> void:
	if playInfo["playback"] == null:
		playInfo["player"].play()
		playInfo["playback"] = playInfo["player"].get_stream_playback()
	var increment : float = playInfo["freq"] / sample_hz

	var to_fill: int = playInfo["playback"].get_frames_available()
	var fade_length : int = 150
	var fade_start : int = to_fill - fade_length
	for i in to_fill:
		var amp : float = 1.0
		if i >= fade_start:
			amp = 1.0 - smoothstep(fade_start, to_fill, i)
		playInfo["playback"].push_frame(Vector2.ONE * sin(playInfo["phase"] * TAU) * amp)
		playInfo["phase"] = fmod(playInfo["phase"] + increment, 1.0)
	playInfo["bufferFilled"] = true

func _fill_buffer(freq: float, length: int) -> PackedVector2Array:
	var phase : float = 0.0
	var increment : float = freq / sample_hz
	var to_fill: int = 2047 * length
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

func handleNoteEnd() -> void:
	currentPlayingNote["player"].queue_free()
	currentPlayingNote = null

func _on_timer_timeout() -> void:
	print("music stopped")
	playing = false
