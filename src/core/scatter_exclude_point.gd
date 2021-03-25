tool
extends Spatial


signal parameter_changed


export var radius := 1.0 setget set_radius


func _ready():
	set_notify_transform(true)


func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			update()


func update():
	var parent = get_parent()
	if parent and parent.has_method("update"):
		parent.update()


func set_radius(val):
	radius = val
	emit_signal("parameter_changed")
	update()
