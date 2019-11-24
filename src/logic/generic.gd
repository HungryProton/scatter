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
## Signals
## --

signal parameter_updated

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
	items_amount = val
	amount = val
	notify_parameter_update()

func set_position_profile(val):
	if val is ScatterProfile:
		position_profile = val
		_listen_to_updates(position_profile)
		notify_parameter_update()

func set_rotation_profile(val):
	if val is ScatterProfile:
		rotation_profile = val
		_listen_to_updates(rotation_profile)
		notify_parameter_update()

func set_scale_profile(val):
	if val is ScatterProfile:
		scale_profile = val
		_listen_to_updates(scale_profile)
		notify_parameter_update()

## --
## Public methods
## --

func init(node : PolygonPath) -> void:
	.init(node)
	if not position_profile:
		position_profile = ProfilePositionSimple.new()
	if not rotation_profile:
		rotation_profile = ProfileRotationSimple.new()
	if not scale_profile:
		scale_profile = ProfileScaleSimple.new()

func scatter_pre_hook(item : ScatterItem) -> void:
	position_profile.set_parameter("path", _path)
	position_profile.set_parameter("exclusion_areas", item.get_exclusion_areas())
	position_profile.reset()
	rotation_profile.reset()
	scale_profile.reset()

func get_next_transform(item : ScatterItem, index = -1) -> Transform:
	var t : Transform = Transform()
	var pos : Vector3 = position_profile.get_result(item)

	# Update item scaling
	var s : Vector3 = scale_profile.get_result(pos)
	if item.ignore_initial_scale:
		t = t.scaled(s * item.scale_modifier)
	else:
		t = t.scaled(s * item.scale_modifier * item.initial_scale)

	# Update item rotation
	var rotation = rotation_profile.get_result(pos)
	if item.ignore_initial_rotation:
		t = t.rotated(Vector3.RIGHT, rotation.x)
		t = t.rotated(Vector3.UP, rotation.y)
		t = t.rotated(Vector3.BACK, rotation.z)
	else:
		t = t.rotated(Vector3.RIGHT, rotation.x + item.initial_rotation.x)
		t = t.rotated(Vector3.UP, rotation.y + item.initial_rotation.y)
		t = t.rotated(Vector3.BACK, rotation.z + item.initial_rotation.z)

	# Update item location
	t.origin = pos
	if not item.ignore_initial_position:
		t.origin += item.initial_position
	return t

## --
## Internal methods
## --

func notify_parameter_update() -> void:
	emit_signal("parameter_updated")

func _listen_to_updates(val) -> void:
	ScatterCommon.safe_connect(val, "parameter_updated", self, "notify_parameter_update")

## --
## Callbacks
## --
