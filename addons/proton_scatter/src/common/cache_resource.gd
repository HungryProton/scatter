@tool
class_name ProtonScatterCacheResource
extends Resource


@export var data = {}


func clear() -> void:
	data.clear()


func store(node_name: String, transforms: Array[Transform3D]) -> void:
	data[node_name] = transforms


func get_transforms(node_name: String) -> Array[Transform3D]:
	var res: Array[Transform3D]

	if node_name in data:
		res.assign(data[node_name])

	return res
