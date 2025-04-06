extends ColorRect
var isHovering : bool = false
var enabled : bool = false
var enabledColor : Color = Color.BLUE
var lastEnabledColor : Color = Color.ROYAL_BLUE
var disabledColor : Color = Color.DIM_GRAY

var freq : float = 0.0
var x : int = -1
var y : int = -1
var currentNote : Dictionary = {}

signal createNote #line, start, length, freq
signal deleteNote #id

func _ready() -> void:
	gui_input.connect(_on_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	freq = MusicRef.getFreq(y)
	
func _draw() -> void:
	if isHovering:
		draw_polyline(getSquareFromNbOfNotes(GlobalVars.noteLength), Color.WHITE, 2)

func _on_mouse_entered() -> void:
	isHovering = true
	queue_redraw()
	
func _on_mouse_exited() -> void:
	isHovering = false
	queue_redraw()

func _on_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			handle_click()
		pass

func handle_enabled(lastNote : bool = false) -> void:
	if enabled:
		color = disabledColor
	else:
		color = enabledColor
		if lastNote:
			color = lastEnabledColor
	enabled = !enabled

func handle_click() -> void:
	if currentNote != {}:
		deleteNote.emit(currentNote["id"])
	else:
		createNote.emit(y, x, GlobalVars.noteLength, freq)

func getSquareFromNbOfNotes(nbOfNotes: int) -> PackedVector2Array:
	var square : PackedVector2Array = []
	square.append(Vector2(0, 0))
	square.append(Vector2(custom_minimum_size.x * nbOfNotes, 0))
	square.append(Vector2(custom_minimum_size.x * nbOfNotes, custom_minimum_size.y))
	square.append(Vector2(0, custom_minimum_size.y))
	square.append(Vector2(0, 0))
	return square
