@tool
extends Node3D


const BaseShape := preload("./shapes/base_shape.gd")
const PathShape := preload("./shapes/path_shape.gd")
const SphereShape := preload("./shapes/sphere_shape.gd")
const ScatterUtil := preload('./common/scatter_util.gd')


@export var exclusive = false
@export_enum("Path", "Sphere") var shape_type: #TODO: Remove this once the custom resource export works
	set(val):
		if val == shape_type:
			return

		shape_type = val
		match shape_type:
			0:
				shape = PathShape.new()
			1:
				shape = SphereShape.new()

var shape: BaseShape:
	set(val):
		# Disconnect the previous shape if any
		if shape and shape.changed.is_connected(_on_shape_changed):
			shape.changed.disconnect(_on_shape_changed)

		shape = val
		shape.changed.connect(_on_shape_changed)


func _ready() -> void:
	set_notify_transform(true)


func _get_property_list() -> Array:
	var list := []
	list.push_back({
		name = "ScatterShape",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE,
	})
	list.push_back({
		name = "shape",
		type = TYPE_OBJECT,
	})
	return list


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
