extends RefCounted
class_name ScatterRender

func render(scatter: ProtonScatter, 
			config: Resource, 
			item: ProtonScatterItem, 
			root: Node3D, 
			mesh_instance: MeshInstance3D, 
			transforms: Array[Transform3D]
			):
	pass

func wants_item_merged_mesh_instance() -> bool:
	return true
