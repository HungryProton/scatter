extends Spatial

# These variables need to be exported to be able to save them to the scene
# Do not modify them directly, modify the options in the scatter instance
export var visible_range_begin : float = 0
export var visible_range_begin_hysteresis : float = 0.1
export var visible_range_end : float   = 0
export var visible_range_end_hysteresis : float = 0.1

export var is_split_multimesh_container = true

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
			var mmi_aabb : AABB = child.get_aabb()
			var center = child.global_transform * mmi_aabb.get_center()
			var d = cam.global_transform.origin.distance_to(center)
			# subtract the half size of the aabb to get the distance to the edge of the mmi
			d -= mmi_aabb.size.length() / 2.0
			d = max(0, d) # if inside sphere make distance 0
			
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
