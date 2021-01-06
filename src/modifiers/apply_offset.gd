tool
extends "base_modifier.gd"


export(bool) var local_space = false
export(Vector3) var position = Vector3.ZERO
export(Vector3) var rotation = Vector3(0.0, 0.0, 0.0)
export(Vector3) var scale = Vector3.ONE


func _init() -> void:
	display_name = "Apply Offset"


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
		
		t = t.scaled(scale)
		
		if local_space:
			t = t.rotated(t.basis.x.normalized(), deg2rad(rotation.x))
			t = t.rotated(t.basis.y.normalized(), deg2rad(rotation.y))
			t = t.rotated(t.basis.z.normalized(), deg2rad(rotation.z))
			t.origin = origin + t.xform(position)

		else:
			t = t.rotated(global_x, deg2rad(rotation.x))
			t = t.rotated(global_y, deg2rad(rotation.y))
			t = t.rotated(global_z, deg2rad(rotation.z))
			t.origin = origin + position
		
		transforms.list[i] = t
