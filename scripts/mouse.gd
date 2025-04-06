extends Node2D

var length : int = 1
@export var lengthLabel : Label
@export var labelTimer : Timer

func _physics_process(delta: float) -> void:
	global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.ctrl_pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					length += 1
					showLabel()
					GlobalVars.noteLength = length
				MOUSE_BUTTON_WHEEL_DOWN:
					if length > 1:
						length -= 1
					showLabel()
					GlobalVars.noteLength = length

func showLabel() -> void:
	labelTimer.start()
	lengthLabel.text = str(length)
	lengthLabel.visible = true

func _on_label_timer_timeout() -> void:
	lengthLabel.visible = false
