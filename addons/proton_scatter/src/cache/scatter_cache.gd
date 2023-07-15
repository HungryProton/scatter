@tool
extends Node

# ProtonScatterCacheNode
#
# Saves the transforms created by ProtonScatter nodes in an external resource
# and restore them when loading the scene.
#
# Use this node when you don't want to wait for scatter nodes to fully rebuild
# at start.
# You can also enable "Show output in tree" to get the same effect, but the
# cache makes it much more VCS friendly, and doesn't clutter your scene tree.

const DEFAULT_CACHE_FOLDER := "res://addons/proton_scatter/cache/"

const ProtonScatter := preload("res://addons/proton_scatter/src/scatter.gd")
const ProtonScatterTransformList := preload("../common/transform_list.gd")


@export_file("*.res", "*.tres") var cache_file := "":
	set(val):
		cache_file = val
		update_configuration_warnings()

# The resource where transforms are actually stored
var _local_cache: ProtonScatterCacheResource
var _scene_root: Node
var _scatter_nodes: Array[ProtonScatter]


func _ready() -> void:
	if not is_inside_tree():
		return

	_scene_root = _get_local_scene_root(self)

	# By default, set the cache path to the cache folder, with a unique recognizable name
	if cache_file.is_empty():
		var scene_path: String = _scene_root.get_scene_file_path()
		var scene_name: String

		# Set a random name if we can't find the current scene
		if scene_path.is_empty():
			scene_name = str(randi())
		else:
			scene_name = scene_path.get_file().get_basename()
			scene_name += "_" + str(scene_path.hash()) # Prevents name collisions

		cache_file = DEFAULT_CACHE_FOLDER.get_basename().path_join(scene_name + "_scatter_cache.tres")
		return

	restore_cache.call_deferred()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if cache_file.is_empty():
		warnings.push_back("No path set for the cache file. Select where to store the cache in the inspector.")

	return warnings


func _notification(what):
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		rebuild_cache()


func rebuild_cache() -> void:
	if cache_file.is_empty():
		printerr("Cache file path is empty.")
		return

	_scatter_nodes.clear()
	_discover_scatter_nodes(_scene_root)

	if not _local_cache:
		_local_cache = ProtonScatterCacheResource.new()

	_local_cache.clear()

	for s in _scatter_nodes:
		# If transforms are not available, try to rebuild once.
		if not s.transforms:
			s.rebuild.call_deferred()
			await s.build_completed

		if not s.transforms:
			continue # Move on to the next if still no results.

		# Store the transforms in the cache.
		_local_cache.store(s.name, s.transforms.list)

	ResourceSaver.save(_local_cache, cache_file)


func restore_cache(force_restore := false) -> void:
	# Load the cache file if it exists
	_local_cache = load(cache_file)
	if not _local_cache:
		printerr("Could not load cache: ", cache_file)
		return

	_scatter_nodes.clear()
	_discover_scatter_nodes(_scene_root)

	for s in _scatter_nodes:
		if s.force_rebuild_on_load and not force_restore:
			continue # Ignore the cache if the scatter node is about to rebuild anyway.

		# Send the cached transforms to the scatter node.
		var transforms = ProtonScatterTransformList.new()
		transforms.list = _local_cache.get_transforms(s.name)
		s._perform_sanity_check()
		s._on_transforms_ready(transforms)


# If the node comes from an instantiated scene, returns the root of that
# instance. Returns the tree root node otherwise.
func _get_local_scene_root(node: Node) -> Node:
	if not node.scene_file_path.is_empty():
		return node

	var parent: Node = node.get_parent()
	if not parent:
		return node

	return _get_local_scene_root(parent)


func _discover_scatter_nodes(root: Node) -> void:
	if root is ProtonScatter:
		_scatter_nodes.push_back(root)

	for c in root.get_children():
		_discover_scatter_nodes(c)
