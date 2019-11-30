tool
extends "base_modifier.gd"

#changes rotation of objects

export(bool) var local = false
export(Vector3) var rotation = Vector3.ZERO


func _init() -> void:
	display_name = "Apply Rotation"


func _process_transforms(transforms, _global_seed : int) -> void:
	for t in transforms.list.size():
		#branchless local/global rotation
		transforms.list[t].basis = transforms.list[t].basis.rotated(float(local) * transforms.list[t].basis.x + float(!local) * Vector3(1, 0, 0), rotation.x)
		transforms.list[t].basis = transforms.list[t].basis.rotated(float(local) * transforms.list[t].basis.y + float(!local) * Vector3(0, 1, 0), rotation.y)
		transforms.list[t].basis = transforms.list[t].basis.rotated(float(local) * transforms.list[t].basis.z + float(!local) * Vector3(0, 0, 1), rotation.z)
