extends PanelContainer

signal selectSynth

var id : int = -1

func _ready() -> void:
	pass

func _on_select_button_up() -> void:
	selectSynth.emit(id)
