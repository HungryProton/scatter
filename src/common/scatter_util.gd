extends Node

# To prevent the main scatter.gd script from becoming too large, some of its
# utility functions are written here.

const ModifierStack := preload("../stack/modifier_stack.gd")
const ScatterItem := preload("../scatter_item.gd")


# Enforce the Scatter node to always have a unique modifier_stack
# (This resource must never be null, nor shared with another Scatter node)
static func ensure_stack_exists(s) -> void:
	if not s.modifier_stack:
		s.modifier_stack = ModifierStack.new()
		s.modifier_stack.owner = s

	if s.modifier_stack.owner != s:
		s.modifier_stack = duplicate_modifier_stack(s)
		s.modifier_stack.owner = s


# A modifier stack has nested resources that apparently don't play well
# with the built-in duplicate(true) method, so we recreate an empty stack and
# duplicate modifiers into it one by one.
static func duplicate_modifier_stack(s) -> ModifierStack:
	var new_stack = ModifierStack.new()
	for modifier in s.modifier_stack.stack:
		new_stack.stack.push_back(modifier.duplicate())
	return new_stack


# Find all ScatterItems nodes among first level children.
static func discover_items(s) -> void:
	s.items.clear()
	s.total_item_proportion = 0

	for c in s.get_children():
		if c is ScatterItem:
			s.items.append(c)
			s.total_item_proportion += c.proportion

	if s.is_inside_tree():
		s.get_tree().node_configuration_warning_changed.emit(s)
