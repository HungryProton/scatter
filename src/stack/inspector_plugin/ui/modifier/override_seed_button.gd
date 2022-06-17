@tool
extends Control


@onready var _button: Button = $OverrideGlobalSeed/Button
@onready var _spinbox_root: Control = $SpinBoxRoot


func _ready():
	_button.toggled.connect(_on_toggled)


func _on_toggled(enabled: bool) -> void:
	_spinbox_root.visible = enabled
