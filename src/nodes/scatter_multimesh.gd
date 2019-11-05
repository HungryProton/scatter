tool
extends ScatterBase

# --
# Scatter Multimesh
# --
# Create a new multimesh for each child ScatterItem nodes. This node
# only looks for the meshes in a given scene and create new multimesh
# instances to render them. It ignores all the other nodes and scripts
# attached. 
# This is useful for grass, but not to place dozen of random NPCs for
# example.
# --
#
# --

class_name ScatterMultimesh

## -- 
## Exported variables
## --

## --
## Internal variables
## --

## --
## Public methods
## --

# Called from any children when their exported parameters changes
func update():
	if not _is_ready():
		return
	_discover_items_info()
	_setup_distribution()
	_fill_area()

## --
## Internal methods
## --

func _ready():
	self.connect("curve_updated", self, "_on_curve_update")
	update()

func _on_curve_update():
	update()

func _setup_multimesh(item, count):
	var instance = item.get_node("MultiMeshInstance")
	if not instance:
		instance = MultiMeshInstance.new()
		instance.set_name("MultiMeshInstance")
		item.add_child(instance)
		instance.set_owner(get_tree().get_edited_scene_root())
	if not instance.multimesh:
		instance.multimesh = MultiMesh.new()
	
	var mesh_instance = _get_mesh_from_scene(item.item_path)
	instance.material_override = mesh_instance.get_surface_material(0)
	
	instance.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	instance.multimesh.mesh = mesh_instance.mesh
	instance.multimesh.transform_format = 1
	instance.multimesh.instance_count = count

	return instance

func _get_mesh_from_scene(node_path):
	var target = load(node_path).instance()
	for c in target.get_children():
		if c is MeshInstance:
			return c

func _fill_area():
	var count
	for i in _items:
		count = int(float(i.proportion) / _total_proportion * amount)
		_populate_multimesh(i, count)

func _populate_multimesh(item, amount):
	var mm = _setup_multimesh(item, amount)
	var placed_items = 0
	for i in range(0, amount):
		var coords = _distribution.get_vector3() * size * 0.5 + center
		if is_point_inside(coords):
			var t = Transform()
			
			# Update item scaling
			var s = 1 + abs(_distribution.get_float()) * scale_randomness
			t = t.scaled(Vector3(s, s, s) * global_scale * item.scale_modifier)
			
			# Update item location
			var pos_y = _get_ground_position(coords)
			t.origin = get_global_transform().origin + Vector3(coords.x, pos_y, coords.z)
			
			# Update item rotation
			#var rotation = _distribution.get_vector3() * rotation_randomness
			#t.rotation = rotation
			
			mm.multimesh.set_instance_transform(i, t)
