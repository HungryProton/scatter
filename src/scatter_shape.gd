@tool
extends Node3D


const BaseShape = preload("./shapes/base_shape.gd")
const PathShape = preload("./shapes/path_shape.gd")
const PointShape = preload("./shapes/point_shape.gd")

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
		shape = val
		shape.changed.connect(_on_shape_changed)
		shape.owner = self


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


func is_point_inside(point: Vector3) -> bool:
	if not shape:
		return false

	return shape.is_point_inside(point)


func _on_shape_changed() -> void:
	update_gizmos()
