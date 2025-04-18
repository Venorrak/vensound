extends Node2D

var currentPlayingNote = null
#{
	#"player": AudioStreamPlayer.new()
	#"playback": AudioStreamPlayback.new(),
	#"freq": 123132.0
	#"phase": 0.0
	#"bufferFilled": false
#}

@export var trackPlayerScene : PackedScene
@export var deleteDelay : Timer
signal tracksEmpty
var trackNodes : Array = []

var sample_hz : float = 22050.0

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
	if not trackNodes.is_empty():
		await tracksEmpty
	for i in music["music"].size():
		var newTrackPlayer = trackPlayerScene.instantiate()
		newTrackPlayer.currentTrack = music["music"][i]
		newTrackPlayer.settings = music["settings"]
		newTrackPlayer.finished.connect(clearTrack)
		trackNodes.append(newTrackPlayer)
		add_child(newTrackPlayer)
	print("playing now")

func clearMusic() -> void:
	for track in trackNodes:
		track._on_timer_timeout()
	print("music cleared")

func clearTrack(track) -> void:
	trackNodes.erase(track)
	deleteDelay.start()
	await deleteDelay.timeout
	track.queue_free()
	if trackNodes.size() == 0:
		tracksEmpty.emit()
		print("music finished")

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

func getLength(duration : int, tempo: int) -> float:
	# 60 -> 60 beats per minute
	return ((60.0 / tempo) / 8) * duration 

func handleNoteEnd() -> void:
	currentPlayingNote["player"].queue_free()
	currentPlayingNote = null
