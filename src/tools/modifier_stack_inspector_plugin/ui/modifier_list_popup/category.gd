@tool
extends VBoxContainer


@onready var label: Label = $Header/Label


func set_category_name(text) -> void:
	label.text = text
