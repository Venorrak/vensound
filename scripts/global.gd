extends Control
@export var minimumCellSize : Vector2
@export var baseCellColor : Color = Color.DIM_GRAY
@export var tempoSpinBox : SpinBox

@export var grid : GridContainer
@export var lineNameContainer : VBoxContainer
@export var synthRoot : HBoxContainer

@onready var noteScript = load("res://scripts/note.gd")
@export var synthScene : PackedScene

var notes : Array[Array] = []
var jsonDataMirror : Dictionary = {}
var selectedTrack : int = 0

func _ready() -> void:
	var json = JSON.new()
	var json_string = FileAccess.get_file_as_string("res://data/music.json")
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		jsonDataMirror = data_received
		tempoSpinBox.value = data_received["settings"]["tempo"]
		generate()
		fill()
		createSynths()
		print("ready")
	else:
		print("parse error")

func generate() -> void:
	var musicLength : int = jsonDataMirror["settings"]["musicLength"]
	grid.columns = musicLength / 8
	for octave in 8:
		for note in MusicRef.refSheet.keys().size():
			var newNotesArray : Array = []
			var newLineLabel = Label.new()
			newLineLabel.set("theme_override_font_sizes/font_size", 12)
			newLineLabel.text = MusicRef.refSheet.keys()[note] + str(octave)
			lineNameContainer.add_child(newLineLabel)
			var newCell
			for i in musicLength:
				if i % 8 == 0:
					newCell = HBoxContainer.new()
					newCell.set("theme_override_constants/separation", 0)
					grid.add_child(newCell)
				var newNote = ColorRect.new()
				newNote.set_script(noteScript)
				newNote.color = baseCellColor
				newNote.custom_minimum_size = minimumCellSize
				newNote.y = notes.size()
				newNote.x = newNotesArray.size()
				newNote.createNote.connect(handleNewNote)
				newNote.deleteNote.connect(handleDeleteNote)
				newCell.add_child(newNote)
				newNotesArray.append(newNote)
			notes.append(newNotesArray)

func fill() -> void:
	for newNote in jsonDataMirror["music"][selectedTrack]["chart"]:
		var newNoteLine : int = MusicRef.getLine(newNote["freq"])
		for i in newNote["length"]:
			if newNote["start_at"] + newNote["length"] - 1 == i + newNote["start_at"]:
				notes[newNoteLine][i + newNote["start_at"]].handle_enabled(true)
			else:
				notes[newNoteLine][i + newNote["start_at"]].handle_enabled()
			notes[newNoteLine][i + newNote["start_at"]].currentNote = newNote

func createSynths() -> void:
	for i in jsonDataMirror["music"].size():
		var newSynth = synthScene.instantiate()
		newSynth.id = i
		newSynth.selectSynth.connect(setSelectedTrack)
		synthRoot.add_child(newSynth)

func setSelectedTrack(id : int) -> void:
	clearGrid()
	selectedTrack = id
	fill()

func handleNewNote(line: int, start_at: int, length: int, freq: float) -> void:
	var newData : Dictionary = {
		"length": length,
		"start_at": start_at,
		"freq": freq,
		"id": randId(10)
	}
	SoundManager.playNote(freq, length, jsonDataMirror["settings"]["tempo"])
	jsonDataMirror["music"][selectedTrack]["chart"].append(newData)
	for i in length:
		if i == length - 1:
			notes[line][start_at + i].handle_enabled(true)
		else: 
			notes[line][start_at + i].handle_enabled()
		notes[line][start_at + i].currentNote = newData
	print(jsonDataMirror["music"][selectedTrack]["chart"])

func handleDeleteNote(id: String) -> void:
	for oldnote in jsonDataMirror["music"][selectedTrack]["chart"]:
		if oldnote["id"] == id:
			jsonDataMirror["music"][selectedTrack]["chart"].erase(oldnote)
			var line : int = MusicRef.getLine(oldnote["freq"])
			for i in oldnote["length"]:
				notes[line][oldnote["start_at"] + i].handle_enabled()
				notes[line][oldnote["start_at"] + i].currentNote = {}
	print(jsonDataMirror["music"][selectedTrack]["chart"])
	
func randId(length: int) -> String:
	var id : String = ""
	var characters : Array = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	for i in length:
		id += characters[randi_range(0, 35)]
	return id

func clearGrid() -> void:
	for noteToClear in jsonDataMirror["music"][selectedTrack]["chart"]:
		var line : int = MusicRef.getLine(noteToClear["freq"])
		for i in noteToClear["length"]:
			notes[line][noteToClear["start_at"] + i].handle_enabled()
			notes[line][noteToClear["start_at"] + i].currentNote = {}

func _on_clear_button_button_up() -> void:
	clearGrid()
	jsonDataMirror["music"][selectedTrack]["chart"] = []

func _on_save_button_button_up() -> void:
	var json = JSON.new()
	var json_string = json.stringify(jsonDataMirror)
	var file = FileAccess.open("res://data/music.json", FileAccess.WRITE)
	file.store_string(json_string)

func _on_play_button_button_up() -> void:
	SoundManager.playSound(jsonDataMirror)

func _on_spin_box_value_changed(value: float) -> void:
	jsonDataMirror["settings"]["tempo"] = value
