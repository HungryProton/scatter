# --
# ScatterLogicWall
# --
# Place instances along the path
# --

tool

extends ScatterLogic

class_name ScatterLogicWall

## --
## Signals
## --

signal parameter_updated

## --
## Exported variables
## --

export(bool) var use_parent_path : bool = false setget set_use_parent_path
export(float) var height : float = 2.0 setget set_height
export(Vector2) var resolution : Vector2 = Vector2.ONE setget set_resolution
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

func set_use_parent_path(val) -> void:
	use_parent_path = val
	notify_parameter_update()

func set_height(val) -> void:
	height = val
	notify_parameter_update()

func set_resolution(val) -> void:
	resolution = val
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
	if not rotation_profile:
		rotation_profile = ProfileRotationSimple.new()
	if not scale_profile:
		scale_profile = ProfileScaleSimple.new()
	rotation_profile.reset()
	scale_profile.reset()

func scatter_pre_hook(item : ScatterItem) -> void:
	pass

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
