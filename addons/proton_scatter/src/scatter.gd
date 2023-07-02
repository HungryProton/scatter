@tool
extends Node3D


signal shape_changed
signal thread_completed
signal build_completed


# Includes
const ProtonScatterDomain := preload("./common/domain.gd")
const ProtonScatterItem := preload("./scatter_item.gd")
const ProtonScatterModifierStack := preload("./stack/modifier_stack.gd")
const ProtonScatterPhysicsHelper := preload("./common/physics_helper.gd")
const ProtonScatterShape := preload("./scatter_shape.gd")
const ProtonScatterTransformList := preload("./common/transform_list.gd")
const ProtonScatterUtil := preload('./common/scatter_util.gd')


@export_category("ProtonScatter")

@export_group("General")
@export var global_seed := 0:
	set(val):
		global_seed = val
		rebuild()
@export var show_output_in_tree := false:
	set(val):
		show_output_in_tree = val
		if output_root:
			ProtonScatterUtil.enforce_output_root_owner(self)

@export_group("Performance")
@export_enum(
	"Use Instancing:0",
	"Create Copies:1",
	"Use Particles:2") var render_mode := 0:
	set(val):
		render_mode = val
		full_rebuild.call_deferred()

@export var force_rebuild_on_load := true
@export var enable_updates_in_game := false

@export_group("Dependency")
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

		modifier_stack = val.get_copy() # Enfore uniqueness
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

# No longer exposed, but kept for backward compatiblity.
var use_instancing := true:
	set(val):
		use_instancing = val
		render_mode = 0 if val else 1

# Internal variables
var _thread: Thread
var _rebuild_queued := false
var _dependency_parent
var _physics_helper: ProtonScatterPhysicsHelper


func _ready() -> void:
	if Engine.is_editor_hint() or enable_updates_in_game:
		set_notify_transform(true)
		child_exiting_tree.connect(_on_child_exiting_tree)

	if not force_rebuild_on_load:
		return

	_perform_sanity_check()
	_discover_items()
	domain.discover_shapes(self)

	if not is_instance_valid(_dependency_parent):
		full_rebuild.call_deferred()

	update_configuration_warnings.call_deferred()


func _get_property_list() -> Array:
	var list := []
	list.push_back({
		name = "modifier_stack",
		type = TYPE_OBJECT,
		hint_string = "ScatterModifierStack",
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
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			_perform_sanity_check()
			domain.compute_bounds()
			rebuild.call_deferred()


func _set(property, _value):
	if not Engine.is_editor_hint():
		return false

	# Workaround to detect when the node was duplicated from the editor.
	if property == "transform":
		_on_node_duplicated.call_deferred()

	return false


func is_thread_running() -> bool:
	return _thread != null and _thread.is_started()


# Used by some modifiers to retrieve a physics helper node
func get_physics_helper() -> ProtonScatterPhysicsHelper:
	if not is_instance_valid(_physics_helper):
		_physics_helper = ProtonScatterPhysicsHelper.new()
		_physics_helper.name = "PhysicsHelper"
		add_child.bind(_physics_helper, true).call_deferred()
		await get_tree().process_frame

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


# Wrapper around the _rebuild function. Clears previous output and force
# a clean rebuild.
func full_rebuild():
	update_gizmos()

	if not is_inside_tree():
		return

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

	if not is_inside_tree():
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
	_perform_sanity_check()

	if force_discover:
		_discover_items()
		domain.discover_shapes(self)

	if items.is_empty() or (domain.is_empty() and not modifier_stack.does_not_require_shapes()):
		clear_output()
		push_warning("ProtonScatter warning: No items or shapes, abort")
		return

	if not use_instancing:
		clear_output() # TMP, prevents raycasts in modifier to self intersect with previous output

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


# Creates one MultimeshInstance3D for each ScatterItem node.
func _update_multimeshes() -> void:
	if items.is_empty():
		_discover_items()

	var offset := 0
	var transforms_count: int = transforms.size()

	for item in items:
		var count = int(round(float(item.proportion) / total_item_proportion * transforms_count))
		var mmi = ProtonScatterUtil.get_or_create_multimesh(item, count)
		if not mmi:
			continue

		var t: Transform3D
		for i in count:
			# Extra check because of how 'count' is calculated
			if (offset + i) >= transforms_count:
				mmi.multimesh.instance_count = i - 1
				return

			t = item.process_transform(transforms.list[offset + i])
			mmi.multimesh.set_instance_transform(i, t)

		offset += count


func _update_duplicates() -> void:
	var offset := 0
	var transforms_count: int = transforms.size()

	for item in items:
		var count := int(round(float(item.proportion) / total_item_proportion * transforms_count))
		var root: Node3D = ProtonScatterUtil.get_or_create_item_root(item)
		var child_count := root.get_child_count()

		for i in count:
			if (offset + i) >= transforms_count:
				return

			var instance
			if i < child_count: # Grab an instance from the pool if there's one available
				instance = root.get_child(i)
			else:
				instance = _create_instance(item, root)

			if not instance:
				break

			var t: Transform3D = item.process_transform(transforms.list[offset + i])
			instance.transform = t

		# Delete the unused instances left in the pool if any
		if count < child_count:
			for i in (child_count - count):
				root.get_child(-1).queue_free()

		offset += count


func _update_particles_system() -> void:
	var offset := 0
	var transforms_count: int = transforms.size()

	for item in items:
		var count := int(round(float(item.proportion) / total_item_proportion * transforms_count))
		var particles = ProtonScatterUtil.get_or_create_particles(item)
		if not particles:
			continue

		particles.visibility_aabb = AABB(domain.bounds_local.min, domain.bounds_local.size)
		particles.amount = count

		var t: Transform3D

		for i in count:
			if (offset + i) >= transforms_count:
				particles.amount = i - 1
				return

			t = item.process_transform(transforms.list[offset + i])
			particles.emit_particle(
				t,
				Vector3.ZERO,
				Color.WHITE,
				Color.BLACK,
				GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_ROTATION_SCALE)

		offset += count


func _create_instance(item: ProtonScatterItem, root: Node3D):
	if not item or not item.get_item():
		return null

	var instance = item.get_item().duplicate()
	instance.visible = true
	root.add_child.bind(instance, true).call_deferred()

	if show_output_in_tree:
		# We have to use a lambda here because ProtonScatterUtil isn't an
		# actual class_name, it's a const, which makes it impossible to reference
		# the callable, (but we can still call it)
		var defer_ownership := func(i, o):
			ProtonScatterUtil.set_owner_recursive(i, o)
		defer_ownership.bind(instance, get_tree().get_edited_scene_root()).call_deferred()

	return instance


# Enforce the Scatter node has its required variables set.
func _perform_sanity_check() -> void:
	if not modifier_stack:
		modifier_stack = ProtonScatterModifierStack.new()
		modifier_stack.just_created = true

	if not domain:
		domain = ProtonScatterDomain.new()

	# Retrigger the parent setter, in case the parent node no longer exists or changed type.
	scatter_parent = scatter_parent


func _on_node_duplicated() -> void:
	# Force a full rebuild (which clears the existing outputs), otherwise we get
	# linked multimeshes or other unwanted side effects
	full_rebuild.call_deferred()


func _on_child_exiting_tree(node: Node) -> void:
	if node is ProtonScatterShape or node is ProtonScatterItem:
		rebuild.bind(true).call_deferred()


# Called when the modifier stack is done generating the full transform list
func _on_transforms_ready(new_transforms: ProtonScatterTransformList) -> void:
	if is_thread_running():
		await _thread.wait_to_finish()
		_thread = null

	if _rebuild_queued:
		_rebuild_queued = false
		rebuild.call_deferred()
		return

	transforms = new_transforms

	if not transforms or transforms.is_empty():
		clear_output()
		update_gizmos()
		return

	match render_mode:
		0:
			_update_multimeshes()
		1:
			_update_duplicates()
		2:
			_update_particles_system()

	update_gizmos()
	await get_tree().process_frame
	build_completed.emit()
