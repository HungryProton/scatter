extends RefCounted

var enable: bool = false


var _layers_bodies: Dictionary[int, LayerBodies] = {}
var _shapes: Array[RID] = []


# Reuse shapes over instances, reducing memory and RID set footprints
class ShapeData extends RefCounted:
	var layers_bin: LayerBodies
	var rid: RID
	
	# NOTE: this is the local transform within the body instance, not the scatter-instance transform
	var trans: Transform3D


# Keep colliders at their appropriate layers & prevent exponential load times
class LayerBodies extends RefCounted:
	var _bodies: Array[RID] = []
	var _shape_bin_count = 0
	var _layers: int
	
	func _init(layers: int) -> void:
		_layers = layers
	
	func commit(scatter: Node3D) -> void:
		for body_rid: RID in _bodies:
			PhysicsServer3D.body_set_space(body_rid, scatter.get_world_3d().space)
	
	func clear() -> void:
		for body: RID in _bodies:
			if body.is_valid():
				PhysicsServer3D.free_rid(body)
		_bodies.clear()			
	
	func add_shape_instance(scatter: Node3D, shape, t: Transform3D) -> void:
		PhysicsServer3D.body_add_shape(_get_body_RID(scatter), shape.rid, t * shape.trans)
		pass

	func _get_body_RID(owner: Node3D) -> RID:
		
		# Now that succeeded in preventing the update-on-insert on the server side
		# its not really needed to aggregate anymore; but it saves in used RID's
		# I expected decreased (raycast) performance due to spatial not coherent
		# but so far with moderate scenes (100k trees), did not see any performance issue
		# with raycasts or physics. (kodus to Jolt!)
		 
		const MAX_SHAPES_PER_BODY: int = 500
		
		if not _bodies.is_empty() and _shape_bin_count < MAX_SHAPES_PER_BODY:
			_shape_bin_count += 1
			return _bodies[-1]
		
		_shape_bin_count = 0;
		var body_rid: RID = PhysicsServer3D.body_create()
		PhysicsServer3D.body_set_mode(body_rid, PhysicsServer3D.BODY_MODE_STATIC)
		PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, owner.global_transform)
		PhysicsServer3D.body_set_collision_layer(body_rid, _layers)
		
		# NOTE: Postpone setting space until commit; this prevents PhysicsServer
		#       from updating on each shape add; which caused exponential insert time increase.
		
		_bodies.append(body_rid)
		return body_rid


# Creates collision data with the Physics server directly.
# This does not create new nodes in the scene tree. This also means you can't
# see these colliders, even when enabling "Debug > Visible collision shapes".
func create_collider_instance_from_template(scatter: Node3D, shapes: Array[ShapeData], t: Transform3D) -> void:
	for shape: ShapeData in shapes:
		shape.layers_bin.add_shape_instance(scatter, shape, t)


func _get_or_create_layer_body_bin(layers: int) -> LayerBodies:
	var bin: LayerBodies = _layers_bodies.get(layers)
	if not bin:
		bin = LayerBodies.new(layers)
		_layers_bodies.set(layers, bin)
	return bin


func get_collider_shapes_template(item: ProtonScatterItem) -> Array[ShapeData]:
	if not enable:
		return []	
	
	var aggregate_template: Array[ShapeData] = []
		
	for body: StaticBody3D in _get_item_static_colliders(item):
		aggregate_template.append_array(_static_body_node_to_shapes_template(body))
	
	return aggregate_template


func clear() -> void:
	for bin: LayerBodies in _layers_bodies.values():
		bin.clear()
	_layers_bodies.clear()

	for shape in _shapes:
		if shape.is_valid():
			PhysicsServer3D.free_rid(shape)

	_shapes.clear()


func commit(scatter: Node3D) -> void:
	for bin: LayerBodies in _layers_bodies.values():
		bin.commit(scatter)


# Grab every static bodies from the source item with local transforms for the shapes
# Do this per-body as the layers might be different and without override, need to be kept
func _get_item_static_colliders(item: ProtonScatterItem) -> Array[StaticBody3D]:
	var source: Node3D = item.get_item()
	if not is_instance_valid(source):
		return []

	source.transform = Transform3D()

	var result: Array[StaticBody3D] = []

	for body in source.find_children("", "StaticBody3D"):
		var static_body := StaticBody3D.new()
		
		static_body.collision_layer = item.override_static_collision_layers \
			if item.override_static_collision_layers != 0 else body.collision_layer
			
		for child in body.get_children():
			# Don't use reparent() here or the child transform gets reset.
			body.remove_child(child)
			child.owner = null
			static_body.add_child(child)
			result.append(static_body)

	source.queue_free()
	return result


func _static_body_node_to_shapes_template(static_body: StaticBody3D) -> Array:
	var shapes: Array[ShapeData] =[]

	for c in static_body.get_children():
		var shape = _node_to_shape(c)
		if not shape:
			continue
			
		shape.layers_bin = _get_or_create_layer_body_bin(static_body.collision_layer)
		shapes.append(shape)
		
	return shapes
	

func _node_to_shape(node: CollisionShape3D) -> ShapeData:
	if not node is CollisionShape3D:
		return null

	# Note that the same thing as below could be done with about 5 lines
	# of code using PhysicsServer API, unfortunatly then the source
	# item must be part of tree and be processed, which wouldnt be very nice
	# Create a shape once, use it for all instances of that shape.

	var shape_rid: RID
	var data: Variant

	var node_shape: Shape3D = node.shape

	if node_shape is SphereShape3D:
		shape_rid = PhysicsServer3D.sphere_shape_create()
		data = node_shape.radius

	elif node_shape is BoxShape3D:
		shape_rid = PhysicsServer3D.box_shape_create()
		data = node_shape.size / 2.0

	elif node_shape is CapsuleShape3D:
		shape_rid = PhysicsServer3D.capsule_shape_create()
		data = {
			"radius": node_shape.radius,
			"height": node_shape.height,
		}

	elif node_shape is CylinderShape3D:
		shape_rid = PhysicsServer3D.cylinder_shape_create()
		data = {
			"radius": node_shape.radius,
			"height": node_shape.height,
		}

	elif node_shape is ConcavePolygonShape3D:
		shape_rid = PhysicsServer3D.concave_polygon_shape_create()
		data = {
			"faces": node_shape.get_faces(),
			"backface_collision": node_shape.backface_collision,
		}

	elif node_shape is ConvexPolygonShape3D:
		shape_rid = PhysicsServer3D.convex_polygon_shape_create()
		data = node_shape.points

	elif node_shape is HeightMapShape3D:
		shape_rid = PhysicsServer3D.heightmap_shape_create()
		var min_height := 9999999.0
		var max_height := -9999999.0
		for v in node_shape.map_data:
			min_height = v if v < min_height else min_height
			max_height = v if v > max_height else max_height
		data = {
			"width": node_shape.map_width,
			"depth": node_shape.map_depth,
			"heights": node_shape.map_data,
			"min_height": min_height,
			"max_height": max_height,
		}

	elif node_shape is SeparationRayShape3D:
		shape_rid = PhysicsServer3D.separation_ray_shape_create()
		data = {
			"length": node_shape.length,
			"slide_on_slope": node_shape.slide_on_slope,
		}
	else:
		print_debug("Scatter - Unsupported collision shape: ", node_shape)
		return null

	_shapes.append(shape_rid)
	
	var shape: ShapeData = ShapeData.new()
	shape.rid = shape_rid
	shape.trans = node.transform

	PhysicsServer3D.shape_set_data(shape.rid, data)
	
	return shape
