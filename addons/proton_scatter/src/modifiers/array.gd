@tool
extends "base_modifier.gd"

# Takes existing objects and duplicates them recursively with given transforms


@export var amount := 1
@export var min_amount := -1
@export var local_offset := false
@export var offset := Vector3.ZERO
@export var local_rotation := false
@export var rotation := Vector3.ZERO
@export var individual_rotation_pivots := true
@export var rotation_pivot := Vector3.ZERO
@export var local_scale := true
@export var scale := Vector3.ONE
@export var randomize_indices := true

var _rng: RandomNumberGenerator


func _init() -> void:
	display_name = "Array"
	category = "Create"
	can_override_seed = true
	can_restrict_height = false
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false

	documentation.add_paragraph(
		"Recursively creates copies of the existing transforms, with each copy
		being offset from the previous one in any of a number of possible ways.")

	var p := documentation.add_parameter("Amount")
	p.set_type("int")
	p.set_cost(2)
	p.set_description(
		"The iteration count. If set to 1, each existing transforms are copied
		once.")
	p.add_warning("If set to 0, no copies are created.")

	p = documentation.add_parameter("Minimum amount")
	p.set_type("int")
	p.set_description(
		"Creates a random amount of copies for each transforms, between this
		value and the amount value.")
	p.add_warning("Ignored if set to a negative value.")

	p = documentation.add_parameter("Offset")
	p.set_type("Vector3")
	p.set_description(
		"Adds a constant offset between each copies and the previous one.")

	p = documentation.add_parameter("Local offset")
	p.set_type("bool")
	p.set_description(
		"If enabled, offset is relative to the previous copy orientation.
		Otherwise, the offset is in global space.")

	p = documentation.add_parameter("Rotation")
	p.set_type("Vector3")
	p.set_description(
		"The rotation offset (on each axes) to add on each copy.")

	p = documentation.add_parameter("Local rotation")
	p.set_type("bool")
	p.set_description(
		"If enabled, the rotation is applied in local space relative to each
		individual transforms. Otherwise, the rotation is applied in global
		space.")

	p = documentation.add_parameter("Rotation Pivot")
	p.set_type("Vector3")
	p.set_description(
		"The point around which each copies are rotated. By default, each
		transforms are rotated around their individual centers.")

	p = documentation.add_parameter("Individual Rotation Pivots")
	p.set_type("bool")
	p.set_description(
		"If enabled, each copies will use their own pivot relative to the
		previous copy. Otherwise, a single pivot point (defined in global space)
		will be used for the rotation of [b]all[/b] the copies.")

	p = documentation.add_parameter("Scale")
	p.set_type("Vector3")
	p.set_description(
		"Scales the copies relative to the transforms they are from.")

	p = documentation.add_parameter("Local Scale")
	p.set_type("bool")
	p.set_description(
		"If enabled, scaling is applied in local space relative to each
		individual transforms. Otherwise, global axes are used, resulting
		in skewed transforms in most cases.")

	p = documentation.add_parameter("Randomize Indices")
	p.set_type("bool")
	p.set_description(
		"Randomize the transform list order. This is only useful to break up the
		repetitive patterns if you're using multiple ScatterItem nodes.")


func _process_transforms(transforms, domain, random_seed: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.set_seed(random_seed)

	var new_transforms: Array[Transform3D] = []
	var rotation_rad := Vector3.ZERO

	rotation_rad.x = deg_to_rad(rotation.x)
	rotation_rad.y = deg_to_rad(rotation.y)
	rotation_rad.z = deg_to_rad(rotation.z)

	var axis_x := Vector3.RIGHT
	var axis_y := Vector3.UP
	var axis_z := Vector3.FORWARD

	for t in transforms.size():
		new_transforms.push_back(transforms.list[t])

		var steps = amount
		if min_amount >= 0:
			steps = _rng.randi_range(min_amount, amount)

		for a in steps:
			a += 1

			# use original object's transform as base transform
			var transform : Transform3D = transforms.list[t]
			var basis := transform.basis

			# first move to rotation point defined in rotation offset
			var rotation_pivot_offset = rotation_pivot
			if individual_rotation_pivots:
				rotation_pivot_offset = transform * rotation_pivot

			transform.origin -= rotation_pivot_offset

			# then rotate
			if local_rotation:
				axis_x = basis.x.normalized()
				axis_y = basis.y.normalized()
				axis_z = basis.z.normalized()

			transform = transform.rotated(axis_x, rotation_rad.x * a)
			transform = transform.rotated(axis_y, rotation_rad.y * a)
			transform = transform.rotated(axis_z, rotation_rad.z * a)

			# scale
			# If the scale is different than 1, each transform gets bigger or
			# smaller for each iteration.
			var s = scale
			s.x = pow(s.x, a)
			s.y = pow(s.y, a)
			s.z = pow(s.z, a)

			if local_scale:
				transform.basis.x *= s.x
				transform.basis.y *= s.y
				transform.basis.z *= s.z
			else:
				transform.basis = transform.basis.scaled(s)

			# apply changes back to the transform and undo the rotation pivot offset
			transform.origin += rotation_pivot_offset

			# offset
			if local_offset:
				transform.origin += offset * a
			else:
				transform.origin += (basis * offset) * a

			# store the final result if the position is valid
			if not domain.is_point_excluded(transform.origin):
				new_transforms.push_back(transform)

	transforms.list = new_transforms

	if randomize_indices:
		transforms.shuffle(random_seed)
