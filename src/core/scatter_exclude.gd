tool
extends "scatter_path.gd"


func _ready():
	connect("curve_updated", self, "update")


func update():
	var _parent = get_parent()
	if _parent:
		_parent.update()
