tool
extends "base_modifier.gd"


export(String, "Texture") var mask
export var mask_scale := Vector2.ONE
export var mask_offset := Vector2.ZERO
export var rotation := 0.0
export(float, 0.0, 1.0) var remove_below = 0.1


func _init() -> void:
	display_name = "Clusterize"
	category = "Edit"


func _process_transforms(transforms, _global_seed) -> void:
	if not ResourceLoader.exists(mask):
		warning += "The specified file " + mask + " could not be loaded"
		return

	var texture = load(mask)

	if not texture is Texture:
		warning += "The specified file is not a valid texture"
		return

	var image: Image = texture.get_data()
	var _err = image.decompress()
	image.lock()

	var width = image.get_width()
	var height = image.get_height()
	var i = 0
	var count = transforms.list.size()
	var angle = deg2rad(rotation)

	while i < count:
		var t = transforms.list[i]
		var origin = t.origin.rotated(Vector3.UP, angle)

		var x = origin.x * mask_scale.x + mask_offset.x
		x = fposmod(x, width - 1)
		var y = origin.z * mask_scale.y + mask_offset.y
		y = fposmod(y, height - 1)

		var level = _get_pixel(image, x, y)
		if level < remove_below:
			transforms.list.remove(i)
			count -= 1
			continue

		origin = t.origin
		t.origin = Vector3.ZERO
		t = t.scaled(Vector3(level, level, level))
		t.origin = origin

		transforms.list[i] = t
		i += 1

	image.unlock()


func _get_pixel(image: Image, x: float, y: float) -> float:
	var ix = int(x)
	var iy = int(y)
	x -= ix
	y -= iy

	var nw = image.get_pixel(ix, iy).v
	var ne = image.get_pixel(ix + 1, iy).v
	var sw = image.get_pixel(ix, iy + 1).v
	var se = image.get_pixel(ix + 1, iy + 1).v

	return nw * (1 - x) * (1 - y) + ne * x * (1 - y) + sw * (1 - x) * y + se * x * y
