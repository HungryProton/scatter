@tool
@icon("../icons/scatter.svg")
class_name ProtonScatter
extends Node3D


signal build_completed


# Includes
const ProtonScatterDomain := preload("./common/domain.gd")
const ProtonScatterPhysicsHelper := preload("./common/physics_helper.gd")
const ProtonScatterTransformList := preload("./common/transform_list.gd")
const ProtonScatterUtil := preload('./common/scatter_util.gd')
const ProtonScatterColliders := preload('./common/colliders.gd')
const ProtonScatterParallel := preload('./common/parallel.gd')

const InstancingRender := preload('./render/render_instances.gd')
const CopiesRender := preload('./render/render_copies.gd')
const ParticlesRender := preload('./render/render_particles.gd')
 
const RENDER_MODE_INSTANCING: int = 0
const RENDER_MODE_COPIES: int = 1
const RENDER_MODE_PARTICLES: int = 2
const RENDER_MODE_CUSTOM: int = 3

@export_group("General")

## Controls whether the scatter system is active. When disabled, all scattered objects
## are removed from the scene. When enabled, the system rebuilds according to current settings.
@export var enabled := true:
	set(val):
		enabled = val
		if is_ready:
			rebuild()

## Used for random number generation across all modifiers.
## Using the same seed with the same settings will produce identical results.
@export var global_seed := 0:
	set(val):
		global_seed = val
		rebuild()

## scattered objects will be visible in the scene tree.
## Useful for debugging but may impact editor performance with large numbers of objects.
@export var show_output_in_tree := false:
	set(val):
		show_output_in_tree = val
		if output_root:
			ProtonScatterUtil.enforce_output_root_owner(self)

@export_group("Performance")


## Determines how scattered objects are rendered in the scene:
## Use Instancing (0): Uses MultiMesh instances for efficient rendering of identical objects.
## Create Copies (1): Creates individual node copies for each scattered object.
## Use Particles (2): Uses GPU particles system for very large numbers of objects.
@export_enum("Use Instancing:0",
			"Create Copies:1",
			"Use Particles:2",
			"Custom:3")\
		var render_mode := RENDER_MODE_INSTANCING:
	set(val):
		render_mode = val
		if is_ready:
			notify_property_list_changed()
			full_rebuild.call_deferred()


var use_chunks : bool = true:
	set(val):
		use_chunks = val
		if is_ready:
			notify_property_list_changed()
			full_rebuild.call_deferred()

var chunk_dimensions := Vector3.ONE * 15.0:
	set(val):
		chunk_dimensions.x = max(val.x, 1.0)
		chunk_dimensions.y = max(val.y, 1.0)
		chunk_dimensions.z = max(val.z, 1.0)
		if is_ready:
			notify_property_list_changed()
			rebuild.call_deferred()

## If enabled, creates static collision shapes for scattered objects.
## Uses the Physics server directly instead of creating actual collision nodes.[br][br]
## Optionally, overriding assigned collision layers can be set per-item on the item itself.
@export var keep_static_colliders := false

## If enabled, forces a complete rebuild of the scattered objects when the scene loads.
## Disable this if you want to restore the previously cached transforms instead of
## regenerating them, which can be useful for faster scene loading times.
@export var force_rebuild_on_load := true

## If enabled, allows the scatter node to rebuild its output during gameplay.
## Disable this in production to prevent unnecessary updates and improve performance,
## since scattered objects typically don't need to change after the scene is loaded.
@export var enable_updates_in_game := false

## If enabled, colliders are created while editing. This allows for raycasting
## to work for stacking or parenting items like the mushrooms in the demo.
## If not using that, but having large amounts of items (10k+ trees for example)
## editing performance can be greatly improved by disabling this.
@export var enable_colliders_in_editor := true

## Custom render script; only used when Render Mode is set to Custom.
## See the sample script in the demo folder.
var custom_render_script: Script:
	set(val):
		custom_render_script = val
		if is_ready:
			notify_property_list_changed()
			full_rebuild.call_deferred()

## Custom render resource that will be passed to the custom render script.
## This allows custom configuration parameters to be set/passed.
var custom_render_config: ScatterRenderConfig


@export_group("Compatibility")

@export var force_uniform_scale: bool = false:
	set(val):
		force_uniform_scale = val
		if is_ready:
			rebuild.call_deferred()

@export_group("Dependency")

## References another ProtonScatter node whose build completion should trigger this node to rebuild.
## Used to create dependency chains where scattered objects are generated in a specific order.
@export var scatter_parent: NodePath:
	set(val):
		if not is_inside_tree():
			scatter_parent = val
			return

		scatter_parent = NodePath()
		if is_instance_valid(_dependency_parent):
			_dependency_parent.build_completed.disconnect(rebuild)
			_dependency_parent = null

		var node = get_node_or_null(val)
		if not node:
			return

		var type = node.get_script()
		var scatter_type = get_script()
		if type != scatter_type:
			push_warning("ProtonScatter warning: Please select a ProtonScatter node as a parent dependency.")
			return

		# TODO: Check for cyclic dependency

		scatter_parent = val
		_dependency_parent = node
		_dependency_parent.build_completed.connect(rebuild, CONNECT_DEFERRED)


@export_group("Debug", "dbg_")

## Debug option to disable multithreading during scatter operations.
## When enabled, all scatter calculations run on the main thread, which is slower
## but easier to debug. Only use this during development.
@export var dbg_disable_thread := false

var undo_redo # EditorUndoRedoManager - Can't type this, class not available outside the editor
var modifier_stack: ProtonScatterModifierStack:
	set(val):
		if modifier_stack:
			if modifier_stack.value_changed.is_connected(rebuild):
				modifier_stack.value_changed.disconnect(rebuild)
			if modifier_stack.stack_changed.is_connected(rebuild):
				modifier_stack.stack_changed.disconnect(rebuild)
			if modifier_stack.transforms_ready.is_connected(_on_transforms_ready):
				modifier_stack.transforms_ready.disconnect(_on_transforms_ready)
		if not val:
			modifier_stack = null
			return
		# Enforce uniqueness if the stack is in used by another Scatter node
		if val.parent and val.parent != self:
			modifier_stack = val.get_copy()
		else:
			modifier_stack = val
		modifier_stack.parent = self
		modifier_stack.value_changed.connect(rebuild, CONNECT_DEFERRED)
		modifier_stack.stack_changed.connect(rebuild, CONNECT_DEFERRED)
		modifier_stack.transforms_ready.connect(_on_transforms_ready, CONNECT_DEFERRED)

var domain: ProtonScatterDomain:
	set(_val):
		domain = ProtonScatterDomain.new() # Enforce uniqueness

var items: Array = []
var total_item_proportion: int
var output_root: Marker3D
var transforms: ProtonScatterTransformList
var editor_plugin # Holds a reference to the EditorPlugin. Used by other parts.
var is_ready := false
var build_version := 0

# Internal variables
var _thread: Thread
var _rebuild_queued := false
var _dependency_parent
var _physics_helper: ProtonScatterPhysicsHelper

var _ignore_transform_notification = false
var _is_using_jolt: bool = false

var _colliders: ProtonScatterColliders = ProtonScatterColliders.new()

func _ready() -> void:
	if Engine.is_editor_hint() or enable_updates_in_game:
		set_notify_transform(true)
		child_exiting_tree.connect(_on_child_exiting_tree)

	_is_using_jolt = ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics"
	_perform_sanity_check()
	_discover_items()
	update_configuration_warnings.call_deferred()
	is_ready = true

	if force_rebuild_on_load and not is_instance_valid(_dependency_parent):
		full_rebuild.call_deferred()


func _exit_tree():
	if is_thread_running():
		modifier_stack.stop_update()
		_thread.wait_to_finish()
		_thread = null

	_colliders.clear()


func _get_property_list() -> Array:
	var list := []
	list.push_back({
		name = "modifier_stack",
		type = TYPE_OBJECT,
		hint_string = "ScatterModifierStack",
	})

	var custom_render_usage := PROPERTY_USAGE_NO_EDITOR
	if render_mode == RENDER_MODE_CUSTOM:
		custom_render_usage = PROPERTY_USAGE_DEFAULT

	list.push_back({
		name = "Performance/custom_render_script",
		type = TYPE_OBJECT,
		hint = PROPERTY_HINT_RESOURCE_TYPE,
		hint_string = "Script",
		usage = custom_render_usage
	})
	list.push_back({
		name = "Performance/custom_render_config",
		type = TYPE_OBJECT,
		hint = PROPERTY_HINT_RESOURCE_TYPE,
		hint_string = "ScatterRenderConfig",
		usage = custom_render_usage
	})
	
	var chunk_usage := PROPERTY_USAGE_NO_EDITOR
	var dimensions_usage := PROPERTY_USAGE_NO_EDITOR
	
	if render_mode == RENDER_MODE_INSTANCING or \
		render_mode == RENDER_MODE_PARTICLES or \
		render_mode == RENDER_MODE_CUSTOM:
			
		chunk_usage = PROPERTY_USAGE_DEFAULT
		if use_chunks:
			dimensions_usage = PROPERTY_USAGE_DEFAULT

	list.push_back({
		name = "Performance/use_chunks",
		type = TYPE_BOOL,
		usage = chunk_usage
	})

	list.push_back({
		name = "Performance/chunk_dimensions",
		type = TYPE_VECTOR3,
		usage = dimensions_usage
	})
	return list


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if items.is_empty():
		warnings.push_back("At least one ScatterItem node is required.")

	if modifier_stack and not modifier_stack.does_not_require_shapes():
		if domain and domain.is_empty():
			warnings.push_back("At least one ScatterShape node is required.")

	return warnings


func _notification(what):
	if not is_ready:
		return
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			if _ignore_transform_notification:
				_ignore_transform_notification = false
				return
			_perform_sanity_check()
			domain.compute_bounds()
			rebuild.call_deferred()
		NOTIFICATION_ENTER_WORLD:
			_ignore_transform_notification = true


func _set(property, value):
	# use_chunks and chunk_dimensions need to be updated regardless of being in-editor
	# or not, otherwise they will always use their defaults ingame (on, [15.0, 15.0, 15.0])
	if property == "Performance/use_chunks":
		use_chunks = value

	elif property == "Performance/chunk_dimensions":
		chunk_dimensions = value

	elif property == "Performance/custom_render_script":
		custom_render_script = value

	elif property == "Performance/custom_render_config":
		custom_render_config = value

	if not Engine.is_editor_hint():
		return false

	# Workaround to detect when the node was duplicated from the editor.
	if property == "transform":
		_on_node_duplicated.call_deferred()

	# Backward compatibility.
	# Convert the value of previous property "use_instancing" into the proper render_mode.
	elif property == "use_instancing":
		render_mode = 0 if value else 1
		return true

	return false


func _get(property):
	if property == "Performance/use_chunks":
		return use_chunks

	elif property == "Performance/chunk_dimensions":
		return chunk_dimensions

	elif property == "Performance/custom_render_script":
		return custom_render_script

	elif property == "Performance/custom_render_config":
		return custom_render_config

func is_thread_running() -> bool:
	return _thread != null and _thread.is_started()


# Used by some modifiers to retrieve a physics helper node
func get_physics_helper() -> ProtonScatterPhysicsHelper:
	return _physics_helper


# Deletes what the Scatter node generated.
func clear_output() -> void:
	if not output_root:
		output_root = get_node_or_null("ScatterOutput")

	if output_root:
		remove_child(output_root)
		output_root.queue_free()
		output_root = null

	ProtonScatterUtil.ensure_output_root_exists(self)

	_colliders.clear()



# Wrapper around the _rebuild function. Clears previous output and force
# a clean rebuild.
func full_rebuild():
	update_gizmos()

	if not is_inside_tree():
		return

	_rebuild_queued = false

	if is_thread_running():
		await _thread.wait_to_finish()
		_thread = null

	clear_output()
	_rebuild(true)


# A wrapper around the _rebuild function. Ensure it's not called more than once
# per frame. (Happens when the Scatter node is moved, which triggers the
# TRANSFORM_CHANGED notification in every children, which in turn notify the
# parent Scatter node back about the changes).
func rebuild(force_discover := false) -> void:
	update_gizmos()

	if not is_inside_tree() or not is_ready:
		return

	if is_thread_running():
		_rebuild_queued = true
		return

	force_discover = true # TMP while we fix the other issues
	_rebuild(force_discover)


# Re compute the desired output.
# This is the main function, scattering the objects in the scene.
# Scattered objects are stored under a Marker3D node called "ScatterOutput"
# DON'T call this function directly outside of the 'rebuild()' function above.
func _rebuild(force_discover) -> void:
	if not enabled:
		_colliders.clear()
		clear_output()
		build_completed.emit()
		return

	_perform_sanity_check()

	if force_discover:
		_discover_items()
		domain.discover_shapes(self)

	if items.is_empty() or (domain.is_empty() and not modifier_stack.does_not_require_shapes()):
		clear_output()
		push_warning("ProtonScatter warning: No items or shapes, abort")
		return

	if render_mode == 1:
		clear_output() # TMP, prevents raycasts in modifier to self intersect with previous output

	if keep_static_colliders:
		_colliders.clear()

	if dbg_disable_thread:
		modifier_stack.start_update(self, domain)
		return

	if is_thread_running():
		await _thread.wait_to_finish()

	_thread = Thread.new()
	_thread.start(_rebuild_threaded, Thread.PRIORITY_NORMAL)


func _rebuild_threaded() -> void:
	# Disable thread safety, but only after 4.1 beta 3
	if _thread.has_method("set_thread_safety_checks_enabled"):
		# Calls static method on instance, otherwise it crashes in 4.0.x
		@warning_ignore("static_called_on_instance")
		_thread.set_thread_safety_checks_enabled(false)

	modifier_stack.start_update(self, domain.get_copy())


func _discover_items() -> void:
	items.clear()
	total_item_proportion = 0

	for c in get_children():
		if is_instance_of(c, ProtonScatterItem):
			items.push_back(c)
			total_item_proportion += c.proportion

	update_configuration_warnings()




# Enforce the Scatter node has its required variables set.
func _perform_sanity_check() -> void:
	if not modifier_stack:
		modifier_stack = ProtonScatterModifierStack.new()
		modifier_stack.just_created = true

	if not domain:
		domain = ProtonScatterDomain.new()

	domain.discover_shapes(self)

	if not is_instance_valid(_physics_helper):
		_physics_helper = ProtonScatterPhysicsHelper.new()
		_physics_helper.name = "PhysicsHelper"
		add_child(_physics_helper, true, INTERNAL_MODE_BACK)

	# Retrigger the parent setter, in case the parent node no longer exists or changed type.
	scatter_parent = scatter_parent


# Remove output coming from the source node to avoid linked multimeshes or
# other unwanted side effects
func _on_node_duplicated() -> void:
	clear_output()


func _on_child_exiting_tree(node: Node) -> void:
	if node is ProtonScatterShape or node is ProtonScatterItem:
		rebuild.bind(true).call_deferred()


# Called when the modifier stack is done generating the full transform list
func _on_transforms_ready(new_transforms: ProtonScatterTransformList) -> void:
	if is_thread_running():
		await _thread.wait_to_finish()
		_thread = null

	_colliders.clear()

	if Engine.is_editor_hint() and not enable_colliders_in_editor:
		_colliders.enable = false
	else:
		_colliders.enable = keep_static_colliders and render_mode != 1

	if _rebuild_queued:
		_rebuild_queued = false
		rebuild.call_deferred()
		return

	transforms = new_transforms

	if force_uniform_scale or _is_using_jolt:
		transforms.enforce_uniform_scale()

	if not transforms or transforms.is_empty():
		clear_output()
		update_gizmos()
		return

	_invoke_render(_create_renderer_instance(render_mode))
	
	update_gizmos()
	build_version += 1

	if is_inside_tree():
		await get_tree().process_frame

	build_completed.emit()


func _create_renderer_instance(render_mode: int) -> ScatterRender:
	var renderer: ScatterRender
	match render_mode:
		0: renderer = InstancingRender.new()
		1: renderer = CopiesRender.new()
		2: renderer = ParticlesRender.new()
		3: renderer = _create_custom_renderer()
		_: assert(false)

	return renderer

func _create_custom_renderer() -> ScatterRender:
	if render_mode != RENDER_MODE_CUSTOM:
		return null
	
	if not custom_render_script:
		push_error("ProtonScatter: Render mode 'Custom' requires custom render script to be set.")
		return null

	var custom_render: Object = custom_render_script.new()
	
	if not custom_render.has_method("render"):
		push_error("ProtonScatter: Custom render script must have render(...) function.")
		return null

	if not custom_render.has_method("post_render"):
		push_error("ProtonScatter: Custom render script must have post_render(...) function.")
		return null
		
	return custom_render as ScatterRender


## Invoke a default renderer; this can be used to include a existing render mode's fuction as 
## a render pass from a custom renderer 
func default_render(mode: int, scatter: ProtonScatter, item: ProtonScatterItem, root: Node3D, transforms: ProtonScatterTransformList, merged: MeshInstance3D) -> void:
	if RENDER_MODE_CUSTOM == mode:
		push_warning("ProtonScatter: default_render(...) ignored because called with mode RENDER_MODE_CUSTOM; infinite recursion prevented")
		return

	var render: ScatterRender = _create_renderer_instance(mode)
	var want_merged_mesh: bool = _script_has_property(render, "merged_mesh_instance")
	if want_merged_mesh:
		render.merged_mesh_instance = merged
	
	render.render(scatter, item, root, transforms)
	

func _invoke_render(render: ScatterRender) -> void:
	clear_output()

	if not render:
		return
	
	if items.is_empty():
		_discover_items()
		
	var transforms_count: int = transforms.size()
	var transforms_list: Array[Transform3D] = transforms.list
	var t_offset: int = 0

	_colliders.clear()
	
	var want_merged_mesh: bool = _script_has_property(render, "merged_mesh_instance")
	
	for item: ProtonScatterItem in items:
		
		if not item.visible:
			continue
		
		var root: Node3D = ProtonScatterUtil.get_or_create_item_root(item)
		if not is_instance_valid(root):
			continue

		var shapes_template: Array = _colliders.get_collider_shapes_template(item)

		# Consume transforms for this item
		var count = int(round(float(item.proportion) / total_item_proportion * transforms_count))

		var item_transforms: ProtonScatterTransformList = ProtonScatterTransformList.new()
		item_transforms.list = transforms_list.slice(t_offset, t_offset + count)
		var item_transforms_list: Array[Transform3D] =  item_transforms.list
		t_offset += count

		# Process to final transform (parallel = not profitable)
		for i in item_transforms.size():
			var t: Transform3D = item.process_transform(item_transforms_list[i])
			item_transforms_list[i] = t

		# Colliders:
		# Having seperate loop saves 1 call stack frame, but costs the loop and lookup
		# However the save saves x count when colliders are not enabled.
		if _colliders.enable:
			for i in item_transforms.size():
				_colliders.create_collider_instance_from_template(self, shapes_template, item_transforms_list[i])
			_colliders.commit(self)
		
		var mesh_instance: MeshInstance3D
		
		if want_merged_mesh:
			render.merged_mesh_instance = ProtonScatterUtil.get_merged_meshes_from(item)
			assert(render.merged_mesh_instance)
		
		render.render(self, item, root, item_transforms)

		if want_merged_mesh:
			render.merged_mesh_instance.queue_free()
			render.merged_mesh_instance = null
	
	if render.has_method("post_render"):
		render.post_render(self, output_root)


func _script_has_property(obj: Object, name: String) -> bool:
	for p in obj.get_property_list():
		if p.name == name:
			return true
	return false
