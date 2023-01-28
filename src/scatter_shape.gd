@tool
extends Node3D


const ScatterUtil := preload('./common/scatter_util.gd')


@export_category("ScatterShape")
@export var negative = false:
	set(val):
		negative = val
		update_gizmos()
		ScatterUtil.request_parent_to_rebuild(self)

@export var shape: ProtonScatterBaseShape:
	set(val):
		# Disconnect the previous shape if any
		if shape and shape.changed.is_connected(_on_shape_changed):
			shape.changed.disconnect(_on_shape_changed)

		shape = val
		if shape:
			shape.changed.connect(_on_shape_changed)

		update_gizmos()
		ScatterUtil.request_parent_to_rebuild(self)


func _ready() -> void:
	set_notify_transform(true)


func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			ScatterUtil.request_parent_to_rebuild(self)


func _set(property, _value):
	if not Engine.is_editor_hint():
		return false

	# Workaround to detect when the node was duplicated from the editor.
	if property == "transform":
		call_deferred("_on_node_duplicated")

	return false


func _on_shape_changed() -> void:
	update_gizmos()
	ScatterUtil.request_parent_to_rebuild(self)


func _on_node_duplicated() -> void:
	shape = shape.get_copy() # Enfore uniqueness on duplicate, could be an option
