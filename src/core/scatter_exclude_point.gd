tool
extends Spatial


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
