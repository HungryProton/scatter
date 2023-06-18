@tool
extends "base_modifier.gd"


@export var spacing := Vector3(2.0, 2.0, 2.0)

var _min_spacing := 0.05


func _init() -> void:
	display_name = "Create Inside (Grid)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_restrict_height = true
	restrict_height = true
	global_reference_frame_available = true
	local_reference_frame_available = true
	individual_instances_reference_frame_available = false

	documentation.add_paragraph(
		"Place transforms along the edges of the ScatterShapes")

	documentation.add_paragraph(
		"When [b]Local Space[/b] is enabled, the grid is aligned with the
		Scatter root node. Otherwise, the grid is aligned with the global
		axes."
	)

	var p = documentation.add_parameter("Spacing")
	p.set_type("vector3")
	p.set_description(
		"Defines the grid size along the 3 axes. A spacing of 1 means 1 unit
		of space between each transform on this axis.")
	p.set_cost(3)
	p.add_warning(
		"The smaller the value, the denser the resulting transforms list.
		Use with care as the performance impact will go up quickly.", 1)
	p.add_warning(
		"A value of 0 would result in infinite transforms, so it's capped to 0.05
		at least.")


func _process_transforms(transforms, domain, seed) -> void:
	spacing.x = max(_min_spacing, spacing.x)
	spacing.y = max(_min_spacing, spacing.y)
	spacing.z = max(_min_spacing, spacing.z)

	var gt: Transform3D = domain.get_local_transform()
	var center: Vector3 = domain.bounds_local.center
	var size: Vector3 = domain.bounds_local.size

	var half_size := size * 0.5
	var start_corner := center - half_size
	var baseline: float = 0.0

	var width := int(ceil(size.x / spacing.x))
	var height := int(ceil(size.y / spacing.y))
	var length := int(ceil(size.z / spacing.z))

	if restrict_height:
		height = 1
		baseline = domain.bounds_local.max.y
	else:
		height = max(1, height) # Make sure height never gets below 1 or else nothing happens

	var max_count: int = width * length * height
	var new_transforms: Array[Transform3D] = []
	new_transforms.resize(max_count)

	var t: Transform3D
	var pos: Vector3
	var t_index := 0

	for i in width * length:
		for j in height:
			t = Transform3D()
			pos = Vector3.ZERO
			pos.x = (i % width) * spacing.x
			pos.y = (j * spacing.y) + baseline
			pos.z = (i / width) * spacing.z
			pos += start_corner

			if is_using_global_space():
				t.basis = gt.affine_inverse().basis
				pos = t * pos

			if domain.is_point_inside(pos):
				t.origin = pos
				new_transforms[t_index] = t
				t_index += 1

	if t_index != new_transforms.size():
		new_transforms.resize(t_index)

	transforms.append(new_transforms)
	transforms.shuffle(seed)
