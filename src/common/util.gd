extends Node


static func curve_to_string(curve: Curve) -> String:
	if not curve:
		return ""

	var dict = {}
	dict.points = []
	for i in curve.get_point_count():
		var p := {}
		p["lm"] = curve.get_point_left_mode(i)
		p["lt"] = curve.get_point_left_tangent(i)
		var pos = curve.get_point_position(i)
		p["x"] = pos.x
		p["y"] = pos.y
		p["rm"] = curve.get_point_right_mode(i)
		p["rt"] = curve.get_point_right_tangent(i)
		dict.points.push_back(p)

	dict.parameters = {
		"min": curve.get_min_value(),
		"max": curve.get_max_value(),
		"res": curve.get_bake_resolution(),
	}

	return JSON.print(dict)


static func string_to_curve(string: String) -> Curve:
	var curve = Curve.new()
	if not string or string.empty():
		return curve

	var json_result = JSON.parse(string)
	if json_result.error != OK:
		return curve

	var dict: Dictionary = json_result.result

	curve.max_value = dict.parameters.max
	curve.min_value = dict.parameters.min
	curve.bake_resolution = dict.parameters.res

	for p in dict.points:
		curve.add_point(Vector2(p.x, p.y), p.lt, p.rt, p.lm, p.rm)

	return curve
