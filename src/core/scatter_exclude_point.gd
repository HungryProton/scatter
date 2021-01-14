tool
extends Spatial


func _ready() -> void:
	set_notify_transform(true)


func _notification(what) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			update()


func update() -> void:
	var parent = get_parent()
	if parent and parent.has_method("update"):
		parent.update()
