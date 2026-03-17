@tool
@icon("../../icons/cache.svg")
class_name ProtonScatterCache
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

const ProtonScatterTransformList := preload("../common/transform_list.gd")


signal cache_restored
signal cache_load_threaded_finished


@export var cache_resource: ProtonScatterCacheResource:
	set(val):
		cache_resource = val
		if is_inside_tree():
			update_configuration_warnings()

@export_storage var cache_file := ""


## Determines whether the cache should be automatically updated when the scene is saved.
## If this is set to off, you will need to manually use the Update Cache button to ensure the
## cache is up-to-date.
@export var auto_rebuild_cache_when_saving := true

@export_group("Debug", "dbg_")

## This parameter is primarily intended for debugging purposes, as saving/loading
## large cache files on the main thread will cause the editor to become unresponsive.
@export var dbg_disable_thread := false

# The resource where transforms are actually stored
var _local_cache: ProtonScatterCacheResource
var _scene_root: Node
var _scatter_nodes: Dictionary # Key: ProtonScatter, Value: cached version
var _local_cache_changed := false
var _cache_load_threaded_in_progress := false

var _save_thread = Thread.new()


func _ready() -> void:
	set_process(false)
	if not is_inside_tree():
		return

	_scene_root = _get_local_scene_root(self)
	_migrate_legacy_cache_file()

	restore_cache.call_deferred()


func _process(_delta: float) -> void:
	if _cache_load_threaded_in_progress:
		match ResourceLoader.load_threaded_get_status(_get_cache_path()):
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
				return

			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE, \
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED, \
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				_cache_load_threaded_in_progress = false
				cache_load_threaded_finished.emit()
				set_process(false)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not cache_resource:
		warnings.push_back("No cache resource assigned. Create or load a ProtonScatterCacheResource in the inspector.")
	elif cache_resource.resource_path.is_empty():
		warnings.push_back("The cache resource is embedded in the scene. Save it as an external resource to persist cache data across sessions.")

	return warnings


func _notification(what):
	if what == NOTIFICATION_EDITOR_PRE_SAVE and auto_rebuild_cache_when_saving:
		update_cache()


func clear_cache() -> void:
	_scatter_nodes.clear()
	_ensure_cache_resource_exists()
	_local_cache = cache_resource
	_local_cache.clear()
	_request_save_cache()


func update_cache() -> void:
	_ensure_cache_resource_exists()

	_purge_outdated_nodes()
	_discover_scatter_nodes(_scene_root)

	if not _local_cache:
		_local_cache = cache_resource

	for s in _scatter_nodes:
		# Ignore this node if its cache is already up to date
		var cached_version: int = _scatter_nodes[s]
		if s.build_version == cached_version:
			continue

		# If transforms are not available, try to rebuild once.
		if not s.transforms:
			s.rebuild.call_deferred()
			await s.build_completed

		if not s.transforms:
			continue # Move on to the next if still no results.

		# Store the transforms in the cache.
		_local_cache.store(str(_scene_root.get_path_to(s)), s.transforms.list)
		_scatter_nodes[s] = s.build_version
		_local_cache_changed = true

	# Only save the cache on disk if there's something new to save
	if not _local_cache_changed:
		return

	_request_save_cache()

	_local_cache_changed = false


func restore_cache() -> void:
	_scatter_nodes.clear()
	_discover_scatter_nodes(_scene_root)

	var cache_loaded := false
	var cache_path := _get_cache_path()
	if cache_resource:
		_local_cache = cache_resource
		cache_loaded = true

	# Load the cache file if it exists
	if not cache_loaded and ResourceLoader.exists(cache_path):
		if is_inside_tree():
			if dbg_disable_thread:
				_load_cache(cache_path)
			else:
				await _load_cache_threaded(cache_path)
		else:
			_local_cache = load(cache_path)

		if not _local_cache:
			printerr("Could not load cache: ", cache_path)
		else:
			cache_resource = _local_cache
			cache_loaded = true
	elif not cache_loaded and not cache_path.is_empty():
		push_warning("ProtonScatter warning: Could not find cache file %s. Falling back to rebuilding scatter nodes." % cache_path)

	for s in _scatter_nodes:
		if s.force_rebuild_on_load:
			continue # Ignore the cache if the scatter node is about to rebuild anyway.

		var node_path := str(_scene_root.get_path_to(s))

		if cache_loaded and _local_cache.has_transforms(node_path):
			# Send the cached transforms to the scatter node.
			var transforms = ProtonScatterTransformList.new()
			transforms.list = _local_cache.get_transforms(node_path)
			s._perform_sanity_check()
			s._on_transforms_ready(transforms)
			s.build_version = 0
			_scatter_nodes[s] = 0
			continue

		if cache_loaded:
			push_warning("ProtonScatter warning: Cache miss for node %s. Rebuilding node output." % node_path)

		s.rebuild.call_deferred()
		await s.build_completed
		_scatter_nodes[s] = s.build_version

	cache_restored.emit()


func enable_for_all_nodes() -> void:
	_purge_outdated_nodes()
	_discover_scatter_nodes(_scene_root)
	for s in _scatter_nodes:
		s.force_rebuild_on_load = false


# If the node comes from an instantiated scene, returns the root of that
# instance. Returns the tree root node otherwise.
func _get_local_scene_root(node: Node) -> Node:
	if not node.scene_file_path.is_empty():
		return node

	var parent: Node = node.get_parent()
	if not parent:
		return node

	return _get_local_scene_root(parent)


func _migrate_legacy_cache_file() -> void:
	if cache_resource:
		return

	if cache_file.is_empty():
		return

	if ResourceLoader.exists(cache_file):
		var loaded_resource = load(cache_file)
		if loaded_resource is ProtonScatterCacheResource:
			cache_resource = loaded_resource
			return

	cache_resource = ProtonScatterCacheResource.new()


func _ensure_cache_resource_exists() -> void:
	if cache_resource:
		return

	cache_resource = ProtonScatterCacheResource.new()
	update_configuration_warnings()


func _request_save_cache() -> void:
	_ensure_cache_resource_exists()
	var save_path := _get_cache_path()
	if save_path.is_empty():
		printerr("ProtonScatter error: Cache resource has no save path.")
		return

	var cache_dir := save_path.get_base_dir()
	if not _ensure_cache_directory_exists(cache_dir):
		return

	if dbg_disable_thread or not ResourceLoader.exists(save_path):
		save_cache()
		return

	if !_save_thread.is_alive():
		if _save_thread.is_started():
			_save_thread.wait_to_finish()
		_save_thread.start(save_cache)


func _get_default_cache_path() -> String:
	if not is_instance_valid(_scene_root):
		return ""

	_ensure_cache_folder_exists()

	var scene_path: String = _scene_root.get_scene_file_path()
	var scene_name: String

	if scene_path.is_empty():
		scene_name = str(randi())
	else:
		scene_name = scene_path.get_file().get_basename()
		scene_name += "_" + str(scene_path.hash())

	return DEFAULT_CACHE_FOLDER.get_basename().path_join(scene_name + "_scatter_cache.res")


func _get_cache_path() -> String:
	if cache_resource and not cache_resource.resource_path.is_empty():
		return cache_resource.resource_path

	if not cache_file.is_empty():
		return cache_file

	return _get_default_cache_path()


func _discover_scatter_nodes(node: Node) -> void:
	if node is ProtonScatter and not _scatter_nodes.has(node):
		_scatter_nodes[node] = -1

	for c in node.get_children():
		_discover_scatter_nodes(c)


func _purge_outdated_nodes() -> void:
	var nodes_to_remove: Array[ProtonScatter] = []
	for node in _scatter_nodes:
		if not is_instance_valid(node):
			nodes_to_remove.push_back(node)
			if _local_cache:
				_local_cache.erase(str(_scene_root.get_path_to(node)))
			_local_cache_changed = true

	for node in nodes_to_remove:
		_scatter_nodes.erase(node)


func _ensure_cache_folder_exists() -> void:
	_ensure_cache_directory_exists(DEFAULT_CACHE_FOLDER)


func _ensure_cache_directory_exists(dir_path: String) -> bool:
	if dir_path.is_empty():
		return false

	var absolute_dir := ProjectSettings.globalize_path(dir_path)
	if DirAccess.dir_exists_absolute(absolute_dir):
		return true

	var err := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if err != OK:
		printerr("ProtonScatter error: Failed to create cache directory ", dir_path, ". Code: ", err)
		return false

	return true


func _load_cache(cache_file_path: String) -> void:
	_local_cache = ResourceLoader.load(cache_file_path)


func _load_cache_threaded(cache_file: String) -> void:
	if cache_file.is_empty():
		printerr("Cache file path is empty.")
		return

	ResourceLoader.load_threaded_request(cache_file)
	set_process(true)
	_cache_load_threaded_in_progress = true
	await cache_load_threaded_finished
	_local_cache = ResourceLoader.load_threaded_get(cache_file)


func save_cache() -> void:
	_ensure_cache_resource_exists()
	_local_cache = cache_resource

	var save_path := _get_cache_path()
	if save_path.is_empty():
		printerr("ProtonScatter error: Cache resource has no save path.")
		return

	var cache_dir := save_path.get_base_dir()
	if not _ensure_cache_directory_exists(cache_dir):
		return

	var err = ResourceSaver.save(_local_cache, save_path)

	if err != OK:
		printerr("ProtonScatter error: Failed to save the cache file ", save_path, ". Code: ", err)
		return

	cache_file = save_path
	if cache_resource.resource_path.is_empty() and ResourceLoader.exists(save_path):
		var saved_resource = load(save_path)
		if saved_resource is ProtonScatterCacheResource:
			cache_resource = saved_resource


func _exit_tree():
	if _save_thread.is_started():
		_save_thread.wait_to_finish()
