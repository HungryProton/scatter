@tool
extends Resource

# Modifiers place transforms. They create, edit or remove transforms in a list,
# before the next Modifier in the stack does the same.
# All Modifiers must inherit from this class.
# Transforms in the provided transforms list must be in global space.


signal warning_changed
signal modifier_changed

const TransformList = preload("../common/transform_list.gd")
const Domain = preload("../common/domain.gd")
const DocumentationInfo = preload("../documentation/documentation_info.gd")

@export var enabled := true
@export var override_global_seed := false
@export var custom_seed := 0
@export var restrict_height := false # Tells the modifier whether to constrain transforms to the local XY plane or not
@export var reference_frame := 0

var display_name: String = "Base Modifier Name"
var category: String = "None"
var documentation := DocumentationInfo.new()
var warning: String = ""
var warning_ignore_no_transforms := false
var warning_ignore_no_shape := true
var expanded := false
var can_override_seed := false
var can_restrict_height := true
var global_reference_frame_available := true
var local_reference_frame_available := false
var individual_instances_reference_frame_available := false
var use_edge_data := false
var deprecated := false
var deprecation_message: String


func get_warning() -> String:
	return warning


func process_transforms(transforms: TransformList, domain: Domain, global_seed: int) -> void:
	_clear_warning()

	if deprecated:
		warning += "This modifier is deprecated.\n"
		warning += deprecation_message + "\n"

	if not enabled:
		warning_changed.emit()
		return

	if domain.is_empty() and not warning_ignore_no_shape:
		warning += """The Scatter node does not have a shape.
		Add at least one ScatterShape node as a child.\n"""

	if transforms.is_empty() and not warning_ignore_no_transforms:
		warning += """There's no transforms to act on.
		Make sure you have a Create modifier before this one.\n
		"""

	var random_seed = global_seed
	if can_override_seed and override_global_seed:
		random_seed = custom_seed

	@warning_ignore("redundant_await") # Not redundant as child classes could use the await keyword here.
	await _process_transforms(transforms, domain, random_seed)

	warning_changed.emit()


func get_copy():
	var script = get_script()
	var copy = script.new()
	for p in get_property_list():
		var value = get(p.name)
		copy.set(p.name, value)
	return copy


func is_using_global_space() -> bool:
	return reference_frame == 0


func is_using_local_space() -> bool:
	return reference_frame == 1


func is_using_individual_instances_space() -> bool:
	return reference_frame == 2


func use_global_space_by_default() -> void:
	reference_frame = 0


func use_local_space_by_default() -> void:
	reference_frame = 1


func use_individual_instances_space_by_default() -> void:
	reference_frame = 2


func _clear_warning() -> void:
	warning = ""
	warning_changed.emit()


# Override in inherited class
func _process_transforms(_transforms: TransformList, _domain: Domain, _seed: int) -> void:
	pass
