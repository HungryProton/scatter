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
export(float) var min_resolution : float = 0.2 setget set_min_resolution
export(Vector2) var resolution : Vector2 = Vector2.ONE setget set_resolution
export(float) var height : float = 2.0 setget set_height
export(Curve) var height_curve : Curve = Curve.new() setget set_height_curve
export(Resource) var jitter_profile : Resource setget set_jitter_profile
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
var _parent : PolygonPath

## --
## Getters and Setters
## --

func set_distribution(val) -> void:
	if val is ScatterDistribution:
		distribution = val
		_listen_to_updates(val)

func set_min_resolution(val) -> void:
	if val > 0:
		min_resolution = val

func set_resolution(val) -> void:
	if val.x >= min_resolution and val.y >= min_resolution:
		resolution = val
		notify_update()

func set_height(val) -> void:
	height = val
	notify_update()

func set_jitter_profile(val) -> void:
	if val is ScatterProfile:
		jitter_profile = val
		_listen_to_updates(jitter_profile)
		notify_update()

func set_rotation_profile(val) -> void:
	if val is ScatterProfile:
		rotation_profile = val
		_listen_to_updates(rotation_profile)
		notify_update()

func set_scale_profile(val) -> void:
	if val is ScatterProfile:
		scale_profile = val
		_listen_to_updates(scale_profile)
		notify_update()

func set_height_curve(val) -> void:
	height_curve = val
	notify_update()
	ScatterCommon.safe_connect(height_curve, "changed", self, "notify_update")

## --
## Public methods
## --

func init(node : PolygonPath) -> void:
	.init(node)
	_ensure_resources_exists()
	_reset_initial_profiles_state()
	_define_total_instances_amount()
	distribution.set_range(Vector2(0, amount))
	distribution.reset()
	_item_offset = -1

func scatter_pre_hook(item : ScatterItem) -> void:
	_item_offset += 1

func get_next_transform(item : ScatterItem, index = -1) -> Transform:
	var t : Transform = Transform()
	var pos : Vector3 = _get_random_pos()
	pos += jitter_profile.get_result(pos)

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
	t.origin = pos
	if not item.ignore_initial_position:
		t.origin += item.initial_position
	return t

## --
## Internal methods
## --

func _listen_to_updates(val) -> void:
	ScatterCommon.safe_connect(val, "parameter_updated", self, "notify_update")

func _ensure_resources_exists() -> void:
	if not jitter_profile:
		self.jitter_profile = ProfileJitterSimple.new()
	if not rotation_profile:
		self.rotation_profile = ProfileRotationSimple.new()
	if not scale_profile:
		self.scale_profile = ProfileScaleSimple.new()
	if not distribution:
		self.distribution =  DistributionUnique.new()

func _reset_initial_profiles_state() -> void:
	jitter_profile.reset()
	rotation_profile.reset()
	scale_profile.reset()

func _define_total_instances_amount() -> void:
	var curve_length = _path.curve.get_baked_length()
	var x_count = int(round(curve_length / resolution.x))
	var y_count = int(round(height / resolution.y))
	x_count = clamp(x_count, 1, x_count)
	y_count = clamp(y_count, 1, y_count)
	amount = x_count * y_count

func _get_random_pos() -> Vector3:
	return _get_next_pos(distribution.get_int())

func _get_next_pos(index) -> Vector3:
	var instances_in_column = int(round(height / resolution.y))
	clamp(instances_in_column, 1, instances_in_column)
	var index2 = (index / instances_in_column)
	var path_length = _path.curve.get_baked_length()
	var offset = index2 * (path_length / (amount / instances_in_column))
	var relative_pos = (index % instances_in_column) * (height / instances_in_column)
	var pos = _path.curve.interpolate_baked(offset)
	pos.y += relative_pos

	var pos1
	var normal
	if offset + 0.15 < path_length:
		pos1 = _path.curve.interpolate_baked(offset + 0.15)
		normal = (pos1 - pos)
	else:
		pos1 = _path.curve.interpolate_baked(offset - 0.15)
		normal = (pos - pos1)

	normal.y = 0.0
	normal = normal.normalized().rotated(Vector3.UP, PI / 2.0)
	var ratio = relative_pos / height
	var mod = height_curve.interpolate_baked(ratio)
	normal *= mod
	return pos + normal
