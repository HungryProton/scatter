# --
# ScatterLogicWall
# --
# Place instances along the path
# --

tool

extends ScatterLogic

class_name ScatterLogicWall

## --
## Exported variables
## --

export(Resource) var distribution : Resource setget set_distribution
export(bool) var use_parent_path : bool = false setget set_use_parent_path
export(float) var height : float = 2.0 setget set_height
export(Vector2) var resolution : Vector2 = Vector2.ONE setget set_resolution
export(Curve) var height_profile : Curve = Curve.new() setget set_height_profile
export(Resource) var rotation_profile : Resource setget set_rotation_profile
export(Resource) var scale_profile : Resource setget set_scale_profile

## --
## Public variables
## --

## --
## Internal variables
## --

var _coords : Array
var _item_offset : int = -1

## --
## Getters and Setters
## --

func set_use_parent_path(val) -> void:
	use_parent_path = val
	notify_update()

func set_height(val) -> void:
	height = val
	notify_update()

func set_resolution(val) -> void:
	resolution = val
	notify_update()

func set_rotation_profile(val):
	if val is ScatterProfile:
		rotation_profile = val
		_listen_to_updates(rotation_profile)
		notify_update()

func set_scale_profile(val):
	if val is ScatterProfile:
		scale_profile = val
		_listen_to_updates(scale_profile)
		notify_update()

func set_distribution(val):
	if val is ScatterDistribution:
		distribution = val
		_listen_to_updates(val)

func set_height_profile(val):
	height_profile = val
	notify_update()

## --
## Public methods
## --

func init(node : PolygonPath) -> void:
	.init(node)
	if not rotation_profile:
		self.rotation_profile = ProfileRotationSimple.new()
	if not scale_profile:
		self.scale_profile = ProfileScaleSimple.new()
	if not distribution:
		self.distribution =  DistributionUnique.new()
	rotation_profile.reset()
	scale_profile.reset()
	_define_total_instances_amount()
	distribution.set_range(Vector2(0, amount))
	distribution.reset()
	_item_offset = -1

func scatter_pre_hook(item : ScatterItem) -> void:
	_item_offset += 1

func get_next_transform(item : ScatterItem, index = -1) -> Transform:
	var t : Transform = Transform()
	var res : Array = _get_random_data()
	var pos = res[0]
	var normal_displace = res[1]

	# Update item scaling
	var s : Vector3 = scale_profile.get_result(pos) * item.scale_modifier
	if not item.ignore_initial_scale:
		s *= item.initial_scale
	t = t.scaled(s)

	# Update item rotation
	var rotation = rotation_profile.get_result(pos)
	if not item.ignore_initial_rotation:
		rotation += item.initial_rotation
	t = t.rotated(Vector3.RIGHT, rotation.x)
	t = t.rotated(Vector3.UP, rotation.y)
	t = t.rotated(Vector3.BACK, rotation.z)

	# Update item location
	t.origin = pos + normal_displace
	if not item.ignore_initial_position:
		t.origin += item.initial_position
	return t

## --
## Internal methods
## --

func _listen_to_updates(val) -> void:
	ScatterCommon.safe_connect(val, "parameter_updated", self, "notify_update")

func _define_total_instances_amount() -> void:
	var curve_length = _path.curve.get_baked_length()
	var x_count = int(round(curve_length / resolution.x))
	var y_count = int(round(height / resolution.y))
	amount = x_count * y_count

func _get_next_data(index) -> Array:
	var instances_in_column = int(round(height / resolution.y))
	clamp(instances_in_column, 1, instances_in_column)

	var index2 = (index / instances_in_column)
	var offset = index2 * (_path.curve.get_baked_length() / (amount / instances_in_column))
	var pos = _path.curve.interpolate_baked(offset)
	var pos1 = _path.curve.interpolate_baked(offset + 0.15)
	var relative_pos = (index % instances_in_column) * (height / instances_in_column) * resolution.y
	pos.y += relative_pos
	var normal = (pos1 - pos)
	normal.y = 0.0
	normal = normal.normalized().rotated(Vector3.UP, PI / 2.0)
	var ratio = relative_pos / height
	var mod = height_profile.interpolate_baked(ratio)
	normal *= mod
	return [pos, normal]

func _get_random_data() -> Array:
	return _get_next_data(distribution.get_int())

## --
## Callbacks
## --
