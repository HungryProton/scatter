@tool
extends MarginContainer

signal load_full
signal load_stack_only
signal delete


func _ready() -> void:
	$%LoadStackOnly.pressed.connect(func (): load_stack_only.emit())
	$%LoadFullPreset.pressed.connect(func (): load_full.emit())
	$%DeleteButton.pressed.connect(func (): delete.emit())


func set_preset_name(preset_name: String) -> void:
	$%Label.set_text(preset_name.capitalize())


func show_save_controls() -> void:
	$%SaveButtons.visible = true
	$%LoadButtons.visible = false


func show_load_controls() -> void:
	$%SaveButtons.visible = false
	$%LoadButtons.visible = true

