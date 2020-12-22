tool
extends Button


signal load_preset
signal delete_preset


onready var _label: Label = $MarginContainer/HBoxContainer/Label


func set_preset_name(text) -> void:
	_label.text = text


func _on_pressed() -> void:
	emit_signal("load_preset")


func _on_delete() -> void:
	emit_signal("delete_preset")
