@tool
extends "base_modifier.gd"


@export var spacing := Vector3(2.0, 2.0, 2.0)

var _min_spacing := 0.05


func _init() -> void:
	display_name = "Create Inside (Grid)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false


func _process_transforms(transforms, domain, seed) -> void:
	spacing.x = max(_min_spacing, spacing.x)
	spacing.y = max(_min_spacing, spacing.y)
	spacing.z = max(_min_spacing, spacing.z)

	var center = domain.bounds.center
	var size = domain.bounds.size
	var half_size = size * 0.5
	var baseline: float = 0.0

	var width := int(ceil(size.x / spacing.x))
	var height := int(ceil(size.y / spacing.y))
	var length := int(ceil(size.z / spacing.z))

	if restrict_height:
		height = 1
		baseline = domain.bounds.max.y

	var max_count: int = width * length * height
	var new_transforms: Array[Transform3D] = []
	new_transforms.resize(max_count)

	var t: Transform3D
	var t_index := 0
	for i in width * length:
		for j in height:
			var pos = Vector3.ZERO
			pos.x = (i % width) * spacing.x
			pos.y = (j * spacing.y) + baseline
			pos.z = (i / width) * spacing.z
			pos += (center - half_size)

			if domain.is_point_inside(pos):
				t = Transform3D()
				t.origin = pos
				new_transforms[t_index] = t
				t_index += 1

	if t_index != new_transforms.size():
		new_transforms.resize(t_index)

	transforms.append(new_transforms)
	transforms.shuffle(seed)
