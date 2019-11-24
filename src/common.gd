class_name ScatterCommon

# Prevents some warning if the node is already connected
static func safe_connect (source : Object, signal_name : String, target : Object, method : String) -> void:
	if not source.is_connected(signal_name, target, method):
		source.connect(signal_name, target, method)

# For every PolygonPath object in paths
# + Returns true if the given point is inside at least one of them
# + Returns false if the given point is outside all of them
static func is_point_in_paths(point : Vector3, paths : Array, parent : Spatial) -> bool:
	var inside = false
	for i in range(0, paths.size()):
		var a : PolygonPath = paths[i]
		if a.is_point_inside(a.to_local(parent.to_global(point))):
			inside = true
	return inside
