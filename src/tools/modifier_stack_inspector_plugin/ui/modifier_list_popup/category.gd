tool
extends VBoxContainer


onready var label: Label = $Label


func set_category_name(text) -> void:
	label.text = text
