@tool
extends RefCounted


static func get_position_and_normal_at(curve: Curve3D, offset: float) -> Array:
	if not curve:
		return []

	var pos: Vector3 = curve.sample_baked(offset)
	var normal := Vector3.ZERO

	var pos1
	if offset + curve.get_bake_interval() < curve.get_baked_length():
		pos1 = curve.sample_baked(offset + curve.get_bake_interval())
		normal = (pos1 - pos)
	else:
		pos1 = curve.sample_baked(offset - curve.get_bake_interval())
		normal = (pos - pos1)

	return [pos, normal]


static func remove_line_breaks(text: String) -> String:
	# Remove tabs
	text = text.replace("\t", "")
	# Remove line breaks
	text = text.replace("\n", " ")
	# Remove occasional double space caused by the line above
	return text.replace("  ", " ")
