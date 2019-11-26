# --
# Scatter Duplicates
# --
# Creates full duplicates of a scene and place them randomly inside a path.
# This node only defines the shape and some parameters like total item count.
# You need to add a child ScatterItem node to define the actual scene that will
# be duplicated. You can add multiple ScatterItems to a single ScatterDuplicate
# node.
# Do NOT use this node to place thousands of simple items like grass for example,
# use a ScatterMultimesh instead.
# --

tool

extends ScatterBase

class_name ScatterDuplicates

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
	var root = _get_or_create_instances_root(item)
	# Store the instances already in the tree to reuse them later
	var instances = root.get_children()
	var child_count = instances.size()
	for i in range(0, amount):
		var instance
		if i < child_count:
			# Grab an instance from the pool if there's one available
			instance = instances[i]
		else:
			# If not, create one
			instance = _create_instance(item, root)
		var t = scatter_logic.get_next_transform(item, i + _offset)
		instance.transform = t
	# Delete the unused instances left in the pool if any
	if amount < child_count:
		for i in range(amount, child_count):
			instances[i].queue_free()

func _get_or_create_instances_root(item):
	var root = item.get_node("Duplicates")
	if not root:
		root = Spatial.new()
		root.set_name("Duplicates")
		item.add_child(root)
		root.set_owner(get_tree().get_edited_scene_root())
	root.translation = Vector3.ZERO
	return root

func _create_instance(item, root):
	# Create item and add it to the scene
	var instance = load(item.item_path).instance()
	root.add_child(instance)
	instance.set_owner(get_tree().get_edited_scene_root())
	return instance
