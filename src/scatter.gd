@tool
extends Node3D


signal updated


const ModifierStack := preload("./stack/modifier_stack.gd")

var modifier_stack: ModifierStack

var _shapes: Dictionary
var _items: Array


func _ready() -> void:
	_ensure_stack_exists()


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


# Enforce this node to always have a unique modifier_stack
# (This resource must never be null, or shared with other Scatter nodes)
func _ensure_stack_exists() -> void:
	if modifier_stack:
		if modifier_stack.owner != self:
			modifier_stack = _duplicate_modifier_stack()
			modifier_stack.owner = self
		return

	modifier_stack = ModifierStack.new()
	modifier_stack.owner = self


func _duplicate_modifier_stack() -> ModifierStack:
	var new_stack = ModifierStack.new()
	for m in modifier_stack.stack:
		new_stack.stack.push_back(m.duplicate())

	return new_stack
