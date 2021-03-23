extends Node


signal warning_changed


export var enabled := true


var display_name: String = "Base Modifier Name"
var category: String = "None"
var warning: String = ""
var warning_ignore_no_transforms := false


func get_warning() -> String:
	return warning


func _clear_warning() -> void:
	warning = ""


func _notify_warning_changed() -> void:
	emit_signal("warning_changed")


func process_transforms(transforms, global_seed) -> void:
	_clear_warning()

	var path = transforms.path
	if path.curve.get_point_count() <= 1:
		warning += """The Scatter node 3D curve is empty.
		You can draw one using the controls on top of the viewport."""
		return

	if transforms.list.empty() and not warning_ignore_no_transforms:
		warning += """The list of transforms is empty.
		Make sure you have a Distribute modifier at the begining of the stack.
		"""

	_process_transforms(transforms, global_seed)
	_notify_warning_changed()


# Override in inherited class
func _process_transforms(transforms, global_seed) -> void:
	pass


func shuffle(array, random_seed := 0) -> void:
	var n = array.size()
	if n < 2:
		return

	var rng = RandomNumberGenerator.new()
	rng.set_seed(random_seed)

	var i = n - 1
	var j
	var tmp
	while i >= 1:
		j = rng.randi() % (i + 1)
		tmp = array[j]
		array[j] = array[i]
		array[i] = tmp
		i -= 1
