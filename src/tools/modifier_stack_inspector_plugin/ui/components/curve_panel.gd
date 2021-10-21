# warning-ignore-all:return_value_discarded

tool
extends Control


signal curve_updated


export var grid_color := Color(1, 1, 1, 0.2)
export var grid_color_sub := Color(1, 1, 1, 0.1)
export var curve_color := Color(1, 1, 1, 0.9)
export var point_color := Color.white
export var selected_point_color := Color.orange
export var point_radius := 4.0
export var text_color := Color(0.9, 0.9, 0.9)
export var columns := 4
export var rows := 2
export var dynamic_row_count := true

var curve: Curve
var gt: Transform2D

var _hover_point := -1 setget set_hover
var _selected_point := -1 setget set_selected_point
var _selected_tangent := -1 setget set_selected_tangent
var _dragging := false
var _hover_radius := 50.0 # Squared
var _tangents_length := 30.0
var _font: Font


func _ready() -> void:
	#rect_min_size.y *= EditorUtil.get_editor_scale()
	var plugin := EditorPlugin.new()
	var theme := plugin.get_editor_interface().get_base_control().get_theme()
	_font = theme.get_font("Main", "EditorFonts")
	plugin.queue_free()

	update()
	connect("resized", self, "_on_resized")


func set_curve(c: Curve) -> void:
	curve = c
	update()


func get_curve() -> Curve:
	return curve


func _gui_input(event) -> void:
	if event is InputEventKey:
		if _selected_point != -1 and event.scancode == KEY_DELETE:
			remove_point(_selected_point)

	elif event is InputEventMouseButton:
		if event.doubleclick:
			add_point(_to_curve_space(event.position))

		elif event.pressed and event.button_index == BUTTON_MIDDLE:
			var i = get_point_at(event.position)
			if i != -1:
				remove_point(i)

		elif event.pressed and event.button_index == BUTTON_LEFT:
			set_selected_tangent(get_tangent_at(event.position))

			if _selected_tangent == -1:
				set_selected_point(get_point_at(event.position))
			if _selected_point != -1:
				_dragging = true

		elif _dragging and not event.pressed:
			_dragging = false
			emit_signal("curve_updated")

	elif event is InputEventMouseMotion:
		if _dragging:
			var curve_amplitude: float = curve.get_max_value() - curve.get_min_value()

			# Snap to "round" coordinates when holding Ctrl.
			# Be more precise when holding Shift as well.
			var snap_threshold: float
			if event.control:
				snap_threshold = 0.025 if event.shift else 0.1
			else:
				snap_threshold = 0.0

			if _selected_tangent == -1: # Drag point
				var point_pos: Vector2 = _to_curve_space(event.position).snapped(Vector2(snap_threshold, snap_threshold * curve_amplitude))

				# The index may change if the point is dragged across another one
				var i: int = curve.set_point_offset(_selected_point, point_pos.x)
				set_hover(i)
				set_selected_point(i)

				# This is to prevent the user from losing a point out of view.
				if point_pos.y < curve.get_min_value():
					point_pos.y = curve.get_min_value()
				elif point_pos.y > curve.get_max_value():
					point_pos.y = curve.get_max_value()

				curve.set_point_value(_selected_point, point_pos.y)

			else: # Drag tangent
				var point_pos: Vector2 = curve.get_point_position(_selected_point)
				var control_pos: Vector2 = _to_curve_space(event.position).snapped(Vector2(snap_threshold, snap_threshold * curve_amplitude))

				var dir: Vector2 = (control_pos - point_pos).normalized()

				var tangent: float
				if not is_zero_approx(dir.x):
					tangent = dir.y / dir.x
				else:
					tangent = 1 if dir.y >= 0 else -1
					tangent *= 9999

				var link: bool = not Input.is_key_pressed(KEY_SHIFT)

				if _selected_tangent == 0:
					curve.set_point_left_tangent(_selected_point, tangent)

					# Note: if a tangent is set to linear, it shouldn't be linked to the other
					if link and _selected_point != (curve.get_point_count() - 1) and curve.get_point_right_mode(_selected_point) != Curve.TANGENT_LINEAR:
						curve.set_point_right_tangent(_selected_point, tangent)

				else:
					curve.set_point_right_tangent(_selected_point, tangent)

					if link and _selected_point != 0 and curve.get_point_left_mode(_selected_point) != Curve.TANGENT_LINEAR:
						curve.set_point_left_tangent(_selected_point, tangent)
			update()
		else:
			set_hover(get_point_at(event.position))


func add_point(pos: Vector2) -> void:
	if not curve:
		return

	pos.y = clamp(pos.y, 0.0, 1.0)
	curve.add_point(pos)
	update()
	emit_signal("curve_updated")


func remove_point(idx: int) -> void:
	if not curve:
		return

	if idx == _selected_point:
		set_selected_point(-1)

	if idx == _hover_point:
		set_hover(-1)

	curve.remove_point(idx)
	update()
	emit_signal("curve_updated")


func get_point_at(pos: Vector2) -> int:
	if not curve:
		return -1

	for i in curve.get_point_count():
		var p := _to_view_space(curve.get_point_position(i))
		if p.distance_squared_to(pos) <= _hover_radius:
			return i

	return -1


func get_tangent_at(pos: Vector2) -> int:
	if not curve or _selected_point < 0:
		return -1

	if _selected_point != 0:
		var control_pos: Vector2 = _get_tangent_view_pos(_selected_point, 0)
		if control_pos.distance_squared_to(pos) < _hover_radius:
			return 0

	if _selected_point != curve.get_point_count() - 1:
		var control_pos = _get_tangent_view_pos(_selected_point, 1)
		if control_pos.distance_squared_to(pos) < _hover_radius:
			return 1

	return -1


func _draw() -> void:
	if not curve:
		return

	var text_height = _font.get_height()
	var min_outer := Vector2(0, rect_size.y)
	var max_outer := Vector2(rect_size.x, 0)
	var min_inner := Vector2(text_height, rect_size.y - text_height)
	var max_inner := Vector2(rect_size.x - text_height, text_height)

	var width: float = max_inner.x - min_inner.x
	var height: float = max_inner.y - min_inner.y

	var curve_min: float = curve.get_min_value()
	var curve_max: float = curve.get_max_value()


	# Main area
	draw_line(Vector2(0, max_inner.y), Vector2(max_outer.x, max_inner.y), grid_color)
	draw_line(Vector2(0, min_inner.y), Vector2(max_outer.x, min_inner.y), grid_color)
	draw_line(Vector2(min_inner.x, max_outer.y), Vector2(min_inner.x, min_outer.y), grid_color)
	draw_line(Vector2(max_inner.x, max_outer.y), Vector2(max_inner.x, min_outer.y), grid_color)

	# Grid and scale
	## Vertical lines
	var x_offset = 1.0 / columns
	var margin = 4

	for i in columns + 1:
		var x = width * (i * x_offset) + min_inner.x
		draw_line(Vector2(x, max_outer.y), Vector2(x, min_outer.y), grid_color_sub)
		draw_string(_font, Vector2(x + margin, min_outer.y - margin), String(stepify(i * x_offset, 0.01)), text_color)

	## Horizontal lines
	var y_offset = 1.0 / rows

	for i in rows + 1:
		var y = height * (i * y_offset) + min_inner.y
		draw_line(Vector2(min_outer.x, y), Vector2(max_outer.x, y), grid_color_sub)
		var y_value = i * ((curve_max - curve_min) / rows) + curve_min
		draw_string(_font, Vector2(min_inner.x + margin, y - margin), String(stepify(y_value, 0.01)), text_color)

	# Plot curve
	var steps = 100
	var offset = 1.0 / steps
	x_offset = width / steps

	var a: float
	var a_y: float
	var b: float
	var b_y: float

	a = curve.interpolate_baked(0.0)
	a_y = range_lerp(a, curve_min, curve_max, min_inner.y, max_inner.y)

	for i in steps - 1:
		b = curve.interpolate_baked((i + 1) * offset)
		b_y = range_lerp(b, curve_min, curve_max, min_inner.y, max_inner.y)
		draw_line(Vector2(min_inner.x + x_offset * i, a_y), Vector2(min_inner.x + x_offset * (i + 1), b_y), curve_color)
		a_y = b_y

	# Draw points
	for i in curve.get_point_count():
		var pos: Vector2 = _to_view_space(curve.get_point_position(i))
		if _selected_point == i:
			draw_circle(pos, point_radius, selected_point_color)
		else:
			draw_circle(pos, point_radius, point_color);

		if _hover_point == i:
			draw_arc(pos, point_radius + 4.0, 0.0, 2 * PI, 12, point_color, 1.0, true)

	# Draw tangents
	if _selected_point >= 0:
		var i: int = _selected_point
		var pos: Vector2 = _to_view_space(curve.get_point_position(i))

		if i != 0:
			var control_pos: Vector2 = _get_tangent_view_pos(i, 0)
			draw_line(pos, control_pos, selected_point_color)
			draw_rect(Rect2(control_pos, Vector2(1, 1)).grow(2), selected_point_color)

		if i != curve.get_point_count() - 1:
			var control_pos: Vector2 = _get_tangent_view_pos(i, 1)
			draw_line(pos, control_pos, selected_point_color)
			draw_rect(Rect2(control_pos, Vector2(1, 1)).grow(2), selected_point_color)


func _to_view_space(pos: Vector2) -> Vector2:
	var h = _font.get_height()
	pos.x = range_lerp(pos.x, 0.0, 1.0, h, rect_size.x - h)
	pos.y = range_lerp(pos.y, curve.get_min_value(), curve.get_max_value(), rect_size.y - h, h)
	return pos


func _to_curve_space(pos: Vector2) -> Vector2:
	var h = _font.get_height()
	pos.x = range_lerp(pos.x, h, rect_size.x - h, 0.0, 1.0)
	pos.y = range_lerp(pos.y, rect_size.y - h, h, curve.get_min_value(), curve.get_max_value())
	return pos


func _get_tangent_view_pos(i: int, tangent: int) -> Vector2:
	var dir: Vector2

	if tangent == 0:
		dir = -Vector2(1.0, curve.get_point_left_tangent(i))
	else:
		dir = Vector2(1.0, curve.get_point_right_tangent(i))

	var point_pos = _to_view_space(curve.get_point_position(i))
	var control_pos = _to_view_space(curve.get_point_position(i) + dir)

	return point_pos + _tangents_length * (control_pos - point_pos).normalized()


func set_hover(val: int) -> void:
	if val != _hover_point:
		_hover_point = val
		update()


func set_selected_point(val: int) -> void:
	if val != _selected_point:
		_selected_point = val
		update()


func set_selected_tangent(val: int) -> void:
	if val != _selected_tangent:
		_selected_tangent = val
		update()


func _on_resized() -> void:
	if dynamic_row_count:
		rows = (int(rect_size.y / rect_min_size.y) + 1) * 2
