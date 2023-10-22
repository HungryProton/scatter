@tool
class_name ProtonScatterCacheResource
extends Resource


@export var data = {}


func clear() -> void:
	data.clear()


func store(node_path: String, transforms: Array[Transform3D]) -> void:
	data[node_path] = transforms


func erase(node_path: String) -> void:
	data.erase(node_path)


func get_transforms(node_path: String) -> Array[Transform3D]:
	var res: Array[Transform3D]

	if node_path in data:
		res.assign(data[node_path])

	return res
