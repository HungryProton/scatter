@tool
extends Resource

# Modifiers place transforms. They create, edit or remove transforms in a list,
# before the next Modifier in the stack does the same.
# All Modifiers must inherit from this class.
# Transforms in the provided transforms list must be in global space.


signal warning_changed

const TransformList = preload("../common/transform_list.gd")
const Domain = preload("../common/domain.gd")
const Documentation = preload("../common/documentation.gd")

@export var enabled := true
@export var override_global_seed := false
@export var custom_seed := 0
@export var restrict_height := false # Tells the modifier to constrain new transforms to a plane or not
@export var use_local_space := false

var display_name: String = "Base Modifier Name"
var category: String = "None"
var documentation := Documentation.new()
var warning: String = ""
var warning_ignore_no_transforms := false
var warning_ignore_no_shape := false
var can_override_seed := false
var can_restrict_height := true
var is_transform_space_relevant := true
var expanded := false


func get_warning() -> String:
	return warning


func _clear_warning() -> void:
	warning = ""


func _notify_warning_changed() -> void:
	warning_changed.emit()


func process_transforms(transforms: TransformList, domain: Domain, global_seed: int) -> void:
	_clear_warning()

	if domain.is_empty() and not warning_ignore_no_shape:
		warning += """The Scatter node does not have a shape.
		Add at least one ScatterShape node as a child.\n"""

	if transforms.is_empty() and not warning_ignore_no_transforms:
		warning += """There's no transforms to act on.
		Make sure you have a Distribute or Create modifier before this one.\n
		"""

	var seed = global_seed
	if can_override_seed and override_global_seed:
		seed = custom_seed
	_process_transforms(transforms, domain, seed)
	_notify_warning_changed()


# Override in inherited class
func _process_transforms(_transforms: TransformList, _domain: Domain, _seed: int) -> void:
	pass
