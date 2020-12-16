tool
extends Node


var display_name := "Distribute Random"

var rng: RandomNumberGenerator


func process_transforms(transforms, random_seed) -> void:
	rng = RandomNumberGenerator.new()
	rng.set_seed(random_seed)
	
	for i in transforms.list.size():
		transforms.list[i].origin = _random_vec3()


func _random_vec3() -> Vector3:
	var vec3 = Vector3.ZERO
	vec3.x = rng.randf_range(-1.0, 1.0)
	vec3.y = rng.randf_range(-1.0, 1.0)
	vec3.z = rng.randf_range(-1.0, 1.0)
	return vec3
