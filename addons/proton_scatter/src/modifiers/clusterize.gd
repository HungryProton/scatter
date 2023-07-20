@tool
extends "base_modifier.gd"


@export_file("Texture") var mask: String
@export var mask_rotation := 0.0
@export var mask_offset := Vector2.ZERO
@export var mask_scale := Vector2.ONE
@export var pixel_to_unit_ratio := 64.0
@export_range(0.0, 1.0) var remove_below = 0.1
@export_range(0.0, 1.0) var remove_above = 1.0
@export var scale_transforms := true


func _init() -> void:
	display_name = "Clusterize"
	category = "Edit"
	global_reference_frame_available = true
	local_reference_frame_available = false # TODO, enable this and handle this case
	individual_instances_reference_frame_available = false

	documentation.add_paragraph(
		"Clump transforms together based on a mask.
		Sampling the mask returns values between 0 and 1. The transforms are
		scaled against these values which means, bright areas don't affect their
		scale while dark area scales them down. Transforms are then removed
		below a threshold, leaving clumps behind.")

	var p := documentation.add_parameter("Mask")
	p.set_type("Texture")
	p.set_description("The texture used as a mask.")
	p.add_warning(
		"The amount of texture fetch depends on the amount of transforms
		generated in the previous modifiers (4 reads for each transform).
		In theory, the texture size shouldn't affect performances in a
		noticeable way.")

	p = documentation.add_parameter("Mask scale")
	p.set_type("Vector2")
	p.set_description(
		"Depending on the mask resolution, the perceived scale will change.
		Use this parameter to increase or decrease the area covered by the mask.")

	p = documentation.add_parameter("Mask offset")
	p.set_type("Vector2")
	p.set_description("Moves the mask XZ position in 3D space")

	p = documentation.add_parameter("Mask rotation")
	p.set_type("Float")
	p.set_description("Rotates the mask around the Y axis. (Angle in degrees)")

	p = documentation.add_parameter("Remove below")
	p.set_type("Float")
	p.set_description("Threshold below which the transforms are removed.")

	p = documentation.add_parameter("Remove above")
	p.set_type("Float")
	p.set_description("Threshold above which the transforms are removed.")

func _process_transforms(transforms, domain, _seed) -> void:
	if not ResourceLoader.exists(mask):
		warning += "The specified file " + mask + " could not be loaded."
		return

	var texture: Texture = load(mask)

	if not texture is Texture:
		warning += "The specified file is not a valid texture."
		return

	var image: Image

	# Wait for a frame or risk the whole editor to freeze because of get_image()
	# TODO: Check if more safe guards are required here.
	await domain.get_root().get_tree().process_frame

	if texture is Texture2D:
		image = texture.get_image()

	elif texture is Texture3D:
		image = texture.get_data()[0] # TMP, this should depends on the transforms Y coordinates

	elif texture is TextureLayered:
		image = texture.get_layer_data(0) # TMP

	image.decompress()

	var width := image.get_width()
	var height := image.get_height()
	var i := 0
	var angle := deg_to_rad(mask_rotation)

	while i < transforms.list.size():
		var t: Transform3D = transforms.list[i]
		var origin := t.origin.rotated(Vector3.UP, angle)

		var x := origin.x * (pixel_to_unit_ratio / mask_scale.x) + mask_offset.x
		x = fposmod(x, width - 1)
		var y := origin.z * (pixel_to_unit_ratio / mask_scale.y) + mask_offset.y
		y = fposmod(y, height - 1)

		var level := _get_pixel(image, x, y)
		if level < remove_below:
			transforms.list.remove_at(i)
			continue

		if level > remove_above:
			transforms.list.remove_at(i)
			continue

		if scale_transforms:
			t.basis = t.basis.scaled(Vector3(level, level, level))

		transforms.list[i] = t
		i += 1


# x and y don't always match an exact pixel, so we sample the neighboring
# pixels as well and return a weighted value based on the input coords.
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
