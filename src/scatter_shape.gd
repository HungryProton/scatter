@tool
extends Node3D


const BaseShape := preload("./shapes/base_shape.gd")
const PathShape := preload("./shapes/path_shape.gd")
const PointShape := preload("./shapes/point_shape.gd")
const ScatterUtil := preload('./common/scatter_util.gd')


@export var exclusive = false
@export_enum("Path", "Point") var shape_type:
	set(val):
		if val == shape_type:
			return

		shape_type = val
		match shape_type:
			0:
				shape = PathShape.new()
			1:
				shape = PointShape.new()


var shape: BaseShape:
	set(val):
		print("in shape setter")
		shape = val
		shape.changed.connect(_on_shape_changed)
		shape.owner = self
		print("new shape ", shape)


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


func is_point_inside(point: Vector3) -> bool:
	if not shape:
		return false

	return shape.is_point_inside(point)


func _on_shape_changed() -> void:
	update_gizmos()


func _on_node_duplicated() -> void:
	print("shape: ", shape)
	var duplicate = shape.duplicate(true)
	print("duplicate", duplicate)
	shape = duplicate

