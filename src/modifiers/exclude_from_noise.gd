tool
extends "base_modifier.gd"



export var override_global_seed := false
export var custom_seed := 0

export var threshold := 0.0
export var invert := false
export var local := false

export var octaves := 3
export var period := 64.0
export var persistence := 0.5
export var lacunarity := 2.0


func _init() -> void:
	display_name = "Remove From noise"
	category = "Remove"


func _process_transforms(transforms, global_seed) -> void:
	var noise := OpenSimplexNoise.new()
	noise.seed = custom_seed if override_global_seed else global_seed
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistence
	noise.lacunarity = lacunarity

	var global_transform = transforms.path.get_global_transform()
	var list := []
	var n := 0.0
	for transform in transforms.list:
		if local:
			n = noise.get_noise_3dv(transform.origin)
		else:
			n = noise.get_noise_3dv(global_transform.xform(transform.origin))

		if (invert and n < threshold) or (not invert and n >= threshold):
			list.push_back(transform)

	transforms.list = list
