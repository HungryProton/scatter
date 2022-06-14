@tool
extends Node3D


signal updated

const ScatterUtil := preload('./common/scatter_util.gd')
const ModifierStack := preload("./stack/modifier_stack.gd")
const TransformList := preload("./common/transform_list.gd")
const ScatterItem := preload("./scatter_item.gd")
const ScatterShape := preload("./scatter_shape.gd")
const Domain := preload("./common/domain.gd")


@export var global_seed := 0

var undo_redo: UndoRedo
var modifier_stack: ModifierStack:
	set(val):
		modifier_stack = val
		if not modifier_stack.value_changed.is_connected(_rebuild):
			modifier_stack.value_changed.connect(_rebuild)
var domain: Domain = Domain.new()
var items: Array

var _total_item_proportion: int
var _output: Node3D


func _ready() -> void:
	ScatterUtil.ensure_stack_exists(self)


func _get_property_list() -> Array:
	var list := []
	list.push_back({
		name = "ProtonScatter",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE,
	})
	list.push_back({
		name = "modifier_stack",
		type = TYPE_OBJECT,
		hint_string = "ScatterModifierStack",
	})
	return list


func _get_configuration_warning() -> String:
	var warning = ""
	if items.is_empty():
		warning += "At least one ScatterItem node is required.\n"
	if domain.is_empty():
		warning += "At least one ScatterShape node in inclusive mode is required.\n"
	return warning


func _ensure_output_root_exists() -> void:
	if not _output or not is_instance_valid(_output):
		_output = get_node_or_null("./ScatterOutput")

	if not _output:
		_output = Position3D.new()
		add_child(_output)


func _clear_output() -> void:
	_ensure_output_root_exists()
	for c in _output.get_children():
		c.queue_free()


func _rebuild() -> void:
	ScatterUtil.discover_items(self)
	domain.discover_shapes(self)
	if items.is_empty() or domain.is_empty():
		return

	var transforms: TransformList = modifier_stack.update()
	print(transforms.list.size())

