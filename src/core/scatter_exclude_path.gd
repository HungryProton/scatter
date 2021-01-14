tool
extends "scatter_path.gd"


func _ready() -> void:
	connect("curve_updated", self, "update")


func update() -> void:
	var parent = get_parent()
	if parent and parent.has_method("update"):
		parent.update()
