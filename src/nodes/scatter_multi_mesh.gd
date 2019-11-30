# --
# ScatterMultiMesh
# --
# Create a new multimesh for each child ScatterItem nodes. This node
# only looks for the meshes in a given scene and create new multimesh
# instances to render them. It ignores all the other nodes and scripts
# attached.
# This is useful for grass, but not to place dozen of random NPCs for
# example.
# --

tool

extends ScatterBase

class_name ScatterMultiMesh

## --
## Exported variables
## --

## --
## Internal variables
## --

## --
## Public methods
## --

## --
## Internal methods
## --

func _scatter_instances_from_item(item, amount):
	var result = _setup_multi_mesh(item, amount)
	var mm = result[0]
	var src_node = result[1]
	for i in range(0, amount):
		var t = scatter_logic.get_next_transform(item, i + _offset)
		mm.multimesh.set_instance_transform(i, t)

func _setup_multi_mesh(item, count):
	var instance = item.get_node("MultiMeshInstance")
	if not instance:
		instance = MultiMeshInstance.new()
		instance.set_name("MultiMeshInstance")
		item.add_child(instance)
		instance.set_owner(get_tree().get_edited_scene_root())
	if not instance.multimesh:
		instance.multimesh = MultiMesh.new()
	instance.translation = Vector3.ZERO

	var mesh_instance = _get_mesh_from_scene(item.item_path)
	instance.material_override = mesh_instance.get_surface_material(0)
	instance.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	instance.multimesh.mesh = mesh_instance.mesh
	instance.multimesh.transform_format = 1
	instance.multimesh.instance_count = count

	return [instance, mesh_instance]

func _get_mesh_from_scene(node_path):
	var target = load(node_path).instance()
	for c in target.get_children():
		if c is MeshInstance:
			target.queue_free()
			return c
