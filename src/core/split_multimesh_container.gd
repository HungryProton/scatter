extends Spatial

var visible_range_begin : float = 0
var visible_range_begin_hysteresis : float = 0.1
var visible_range_end : float   = 0
var visible_range_end_hysteresis : float = 0.1

func _ready():
	pass

func _process(delta):
	if visible_range_end == 0 and visible_range_end == 0:
		return
	var cam = get_viewport().get_camera()
	if cam != null:
		for child in get_children():
			if not child is MultiMeshInstance:
				continue
			var aabb : AABB = child.get_aabb()
			var center = aabb.position + aabb.size / 2.0
			center = child.global_transform * center
			var d = (cam.global_transform.origin - center).length()
			
			var hide = false
			var show = true
			
			if visible_range_begin != 0:
				if d <= visible_range_begin - visible_range_begin_hysteresis:
					# Too close, hide
					hide = true
				# if inside hysteresis band do not change visibility
				if abs(d-visible_range_begin) < visible_range_begin_hysteresis:
					show = false
			
			if visible_range_end != 0:
				if d >= visible_range_end + visible_range_end_hysteresis:
					# Too far, hide
					hide = true
				# if inside hysteresis band do not change visiblity
				if abs(d-visible_range_end) < visible_range_end_hysteresis:
					show = false
			
			if hide:
				child.visible = false
			elif show:
				child.visible = true
