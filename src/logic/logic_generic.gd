# --
# ScatterLogicGeneric
# --
# The most generic ScatterLogic node. It is composed of three different profiles
# for position, rotation and scale. For each instance it construct a new
# transform based on the three profiles.
# Then it adds the initial position / rotation / scale depending on the flags
# on the ScatterItem node.
# --

tool

extends ScatterLogic

class_name ScatterLogicGeneric

## --
## Exported variables
## --

export(int) var items_amount : int = 10 setget set_items_amount
export(Resource) var position_profile : Resource setget set_position_profile
export(Resource) var rotation_profile : Resource setget set_rotation_profile
export(Resource) var scale_profile : Resource setget set_scale_profile

## --
## Public variables
## --

## --
## Internal variables
## --

## --
## Getters and Setters
## --

func set_items_amount(val) -> void:
	if val > 0:
		items_amount = val
		amount = val
		notify_update()

func set_position_profile(val):
	if val is ScatterProfile:
		position_profile = val
		_listen_to_updates(position_profile)
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

## --
## Public methods
## --

func init(node : PolygonPath) -> void:
	.init(node)
	amount = items_amount
	_ensure_profiles_exists()
	position_profile.reset()
	rotation_profile.reset()
	scale_profile.reset()

func scatter_pre_hook(item : ScatterItem) -> void:
	position_profile.set_parameter("path", _path)
	position_profile.set_parameter("exclusion_areas", item.get_exclusion_areas())

func get_next_transform(item : ScatterItem, index = -1) -> Transform:
	var t : Transform = Transform()
	var pos : Vector3 = position_profile.get_result(item)

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

func _ensure_profiles_exists() -> void:
	if not position_profile:
		self.position_profile = ProfilePositionSimple.new()
	if not rotation_profile:
		self.rotation_profile = ProfileRotationSimple.new()
	if not scale_profile:
		self.scale_profile = ProfileScaleSimple.new()

## --
## Callbacks
## --
