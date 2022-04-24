@tool
extends Node3D


@export var proportion := 100
@export var scale_modifier := 1.0
@export var ignore_source_position := true
@export var ignore_source_rotation := true
@export var ignore_source_scale := true
@export_enum("From current scene", "From disk") var source:
	set(val):
		print("in setter")
		source = val
		property_list_changed.emit()


var path: String
var test: int

func _get_property_list() -> Array:
	var list := []

	list.push_back({
		name = "ScatterItem",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE,
	})

	if source == 0:
		list.push_back({
			name = "path",
			type = TYPE_NODE_PATH,
		})
	else:
		list.push_back({
			name = "path",
			type = TYPE_STRING,
			hint = PROPERTY_HINT_FILE,
		})

	return list


func get_item() -> Node3D:
	if path.is_empty():
		return null

	if source == 0:
		return get_node_or_null(path)

	var scene = load(path)
	if scene:
		return scene.instantiate()

	return null
