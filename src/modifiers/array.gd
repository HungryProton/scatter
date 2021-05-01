tool
extends "base_modifier.gd"

# Takes existing objects and duplicates them recursively with given transforms

export var amount := 1
export var local_offset := false
export var offset := Vector3.ZERO
export var local_rotation := false
export var rotation := Vector3.ZERO
export var individual_rotation_pivots := true
export var rotation_pivot := Vector3.ZERO
export var local_scale := true
export var scale := Vector3.ONE


func _init() -> void:
	display_name = "Array"
	category = "Edit"


func _process_transforms(transforms, global_seed: int) -> void:
	var new_transforms := []
	var rotation_rad := Vector3.ZERO

	# Convert rotation in radians
	rotation_rad.x = deg2rad(rotation.x)
	rotation_rad.y = deg2rad(rotation.y)
	rotation_rad.z = deg2rad(rotation.z)

	# for each existing object
	for t in transforms.list.size():
		# add original transform to array
		new_transforms.push_back(transforms.list[t])

		# for each iteration of the array
		for a in amount:
			a += 1

			# use original object's transform as base transform
			var transform : Transform = transforms.list[t]
			var basis := transform.basis

			# first move to rotation point defined in rotation offset
			var rotation_pivot_offset = (float(individual_rotation_pivots) * transform.xform(rotation_pivot) + float(!individual_rotation_pivots) * (rotation_pivot))
			transform.origin -= rotation_pivot_offset

			# then rotate
			transform = transform.rotated(float(local_rotation) * basis.x + float(!local_rotation) * Vector3(1, 0, 0), rotation_rad.x * a)
			transform = transform.rotated(float(local_rotation) * basis.y + float(!local_rotation) * Vector3(0, 1, 0), rotation_rad.y * a)
			transform = transform.rotated(float(local_rotation) * basis.z + float(!local_rotation) * Vector3(0, 0, 1), rotation_rad.z * a)

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
			transform.origin += (float(!local_offset) * offset * a) + (float(local_offset) * basis.xform(offset) * a)

			# store the final result
			new_transforms.push_back(transform)

	shuffle(new_transforms, global_seed)
	transforms.list = new_transforms
