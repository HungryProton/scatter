tool
extends "base_modifier.gd"

export(int) var amount = 1
var local_offset := false
export(Vector3) var offset = Vector3.ZERO
var local_rotation := false
export(Vector3) var rotation = Vector3.ZERO
var local_rotation_offset := false
export(Vector3) var rotation_offset = Vector3.ZERO

func _init() -> void:
	display_name = "Array"

func _process_transforms(transforms, _global_seed : int) -> void:
	var trans := []
	#resize array to be proper size
	trans.resize(transforms.list.size() * amount)
	
	#for each existing object
	for t in transforms.list.size():
		#adds original transform to array
		trans[t * (amount)] = transforms.list[t]
		
		#for each iteration of the array
		for a in amount:
			#use original object's transform as base transform
			var transform : Transform = transforms.list[t]
			
			#rotation
			var basis := transform.basis
			
			#rotation offset
			#first move to rotation point
			transform.origin -= (float(local_rotation_offset) * basis.xform(rotation_offset) + float(!local_rotation_offset) * (rotation_offset))
			
			#then rotate
			#branchless local/global rotation
			basis = basis.rotated(float(local_rotation) * basis.x + float(!local_rotation) * Vector3(1, 0, 0), rotation.x * a)
			basis = basis.rotated(float(local_rotation) * basis.y + float(!local_rotation) * Vector3(0, 1, 0), rotation.y * a)
			basis = basis.rotated(float(local_rotation) * basis.z + float(!local_rotation) * Vector3(0, 0, 1), rotation.z * a)
			
			#then undo our move to the rotation point
			transform.origin += (float(local_rotation_offset) * basis.xform(rotation_offset) + float(!local_rotation_offset) * (rotation_offset))
			
			#offset
			transform.origin += (float(!local_offset) * offset * a) + (float(local_offset) * transform.xform(offset) * a)
			
			#set transform in array
			trans[t * (amount) + a] = transform
