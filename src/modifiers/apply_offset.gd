tool
extends "base_modifier.gd"


export var local_space := false
export var position := Vector3.ZERO
export var rotation := Vector3(0.0, 0.0, 0.0)
export var scale := Vector3.ONE


func _init() -> void:
	display_name = "Offset Transform"
	category = "Offset"


func _process_transforms(transforms, _global_seed) -> void:
	var t: Transform
	var origin: Vector3

	var gt: Transform = transforms.path.get_global_transform()
	origin = gt.origin
	gt.origin = Vector3.ZERO
	var global_x: Vector3 = gt.xform_inv(Vector3.RIGHT).normalized()
	var global_y: Vector3 = gt.xform_inv(Vector3.UP).normalized()
	var global_z: Vector3 = gt.xform_inv(Vector3.DOWN).normalized()
	gt.origin = origin

	for i in transforms.list.size():
		t = transforms.list[i]
		origin = t.origin
		t.origin = Vector3.ZERO

		if local_space:
			t = t.rotated(t.basis.x.normalized(), deg2rad(rotation.x))
			t = t.rotated(t.basis.y.normalized(), deg2rad(rotation.y))
			t = t.rotated(t.basis.z.normalized(), deg2rad(rotation.z))
			t.basis.x *= scale.x
			t.basis.y *= scale.y
			t.basis.z *= scale.z
			t.origin = origin + t.xform(position)

		else:
			t = t.rotated(global_x, deg2rad(rotation.x))
			t = t.rotated(global_y, deg2rad(rotation.y))
			t = t.rotated(global_z, deg2rad(rotation.z))
			t.basis = t.basis.scaled(scale)
			t.origin = origin + position

		transforms.list[i] = t
