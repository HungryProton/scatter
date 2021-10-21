tool
extends "scatter_path.gd"


func _ready():
	# warning-ignore:return_value_discarded
	connect("curve_updated", self, "update")


func update():
	var parent = get_parent()
	if parent and parent.has_method("update"):
		parent.update()
