extends RefCounted
class_name ScatterRender

const TransformList := preload("res://addons/proton_scatter/src/common/transform_list.gd")

# NOTE: Use this in custom renderer if need to have merged mesh; it will be set automagilly
#var merged_mesh_instance: MeshInstance3D
# NOTE: *Do NOT* uncomment the line above here; it will cause merging in cases where it isnt needed


func render(scatter: ProtonScatter, 
			item: ProtonScatterItem, 
			root: Node3D, 
			transforms: TransformList):
	pass


## Called after all render(...) calls for each item completed
## Note that root here is the top-level root (under which the item-roots reside)
func post_render(scatter: ProtonScatter, root: Node3D) -> void:
	pass
