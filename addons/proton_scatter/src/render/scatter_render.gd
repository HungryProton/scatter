extends RefCounted
class_name ScatterRender

const TransformList := preload("res://addons/proton_scatter/src/common/transform_list.gd")

func render(scatter: ProtonScatter, 
			config: Resource, 
			item: ProtonScatterItem, 
			root: Node3D, 
			mesh_instance: MeshInstance3D, 
			transforms: TransformList
			):
	pass

func wants_item_merged_mesh_instance() -> bool:
	return true
