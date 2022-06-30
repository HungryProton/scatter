@tool
extends "base_modifier.gd"


# Poisson disc sampling based on Sebastian Lague implementation, modified to
# support both 2D and 3D space.
# Reference: https://www.youtube.com/watch?v=7WcmyxyFO7o


const Bounds := preload("../common/bounds.gd")

@export var radius := 1.0
@export var samples_before_rejection := 15


var rng: RandomNumberGenerator
var squared_radius: float
var domain
var bounds: Bounds

var points: Array[Transform3D] # Stores the generated points
var grid: Array[int] = [] # Flattened array
var grid_size := Vector3i.ZERO
var cell_size: float


func _init() -> void:
	display_name = "Create Inside (Poisson)"
	category = "Create"
	warning_ignore_no_transforms = true
	warning_ignore_no_shape = false
	can_restrict_height = true
	can_override_seed = true


func _process_transforms(transforms, d, seed) -> void:
	rng = RandomNumberGenerator.new()
	rng.set_seed(seed)
	domain = d
	bounds = domain.bounds

	_sample_poisson()

	transforms.append(points)
	#transforms.shuffle(seed)


func _sample_poisson() -> Array[Transform3D]:
	# Initialization
	_init_grid()
	points = []

	# Stores the possible starting points from where we run the sampling.
	# This array will progressively be emptied as the algorithm progresses.
	var spawn_points: Array[Transform3D]

	# Create a starting point
	var starting_point := Transform3D()
	starting_point.origin = bounds.center
	spawn_points.push_back(starting_point)

	# Sampler main loop
	while not spawn_points.is_empty():
		# Pick a starting point at random from the existing list
		var spawn_index: int = rng.randi_range(0, spawn_points.size() - 1)
		var spawn_center := spawn_points[spawn_index]

		print("----- BEGIN ----")
		print("Spawn index: ", spawn_index)

		var tries := 0
		var candidate_accepted := false

		while tries < samples_before_rejection:
			tries += 1

			# Generate a random point in space, outside the radius of the spawn point
			var angle: float = rng.randf() * TAU
			var dir: Vector3 = Vector3(sin(angle), 0.0, cos(angle))
			var candidate: Vector3 = spawn_center.origin + dir * rng.randf_range(radius, radius * 2.0)

			if _is_valid(candidate):
				candidate_accepted = true

				# Add new points to the lists
				var t = Transform3D()
				t.origin = candidate
				points.push_back(t)
				spawn_points.push_back(t)

				# Stores the point index in the grid
				var t_candidate = candidate - bounds.min
				var cell_x: int = round(t_candidate.x / cell_size)
				var cell_y: int = round(t_candidate.y / cell_size)
				var cell_z: int = round(t_candidate.z / cell_size)

				var id = cell_x + cell_z * grid_size.z
				print("Accepting point, cell ", cell_x, ",", cell_z, ", id ", id, ", total ", points.size())
				if (id < grid.size()):
					grid[cell_x + cell_z * grid_size.z] = points.size() - 1
				else:
					print("size ", grid.size(), " id: ", id)
				break

		# Failed to find a point after too many tries. The space around this
		# spawn point is probably full, discard it.
		if not candidate_accepted:
			print("REMOVING ", spawn_index, " remaining: ", spawn_points.size())
			spawn_points.remove_at(spawn_index)

	return points


func _init_grid() -> void:
	squared_radius = radius * radius
	cell_size = radius / sqrt(2)
	grid_size.x = ceil(bounds.size.x / cell_size)
	grid_size.y = ceil(bounds.size.y / cell_size)
	grid_size.z = ceil(bounds.size.z / cell_size)
	print("Grid size: ", grid_size)
	grid = []
	grid.resize(grid_size.x * grid_size.z)
	return
	if restrict_height:
		grid.resize(grid_size.x * grid_size.z)
	else:
		grid.resize(grid_size.x * grid_size.y * grid_size.z)


func _is_valid(candidate: Vector3) -> bool:
	if not domain.is_point_inside(candidate):
		return false

	var t_candidate = candidate - bounds.min

	# Search the surrounding cells for other points
	var cell_x: int = round(t_candidate.x / cell_size)
	var cell_y: int = round(t_candidate.y / cell_size)
	var cell_z: int = round(t_candidate.z / cell_size)

	var search_start_x: int = max(0, cell_x - 2)
	var search_end_x: int = min(cell_x + 2, grid_size.x - 1)
	var search_start_y: int = max(0, cell_y - 2)
	var search_end_y: int = min(cell_y + 2, grid_size.y - 1)
	var search_start_z: int = max(0, cell_z - 2)
	var search_end_z: int = min(cell_z + 2, grid_size.z - 1)

	print("x:", search_start_x, "-", search_end_x, ", y: ", search_start_z, "-", search_end_z )

	for x in range(search_start_x, search_end_x + 1):
		for z in range(search_start_z, search_end_z + 1):
			var point_index = grid[x + z * grid_size.z]
			print(x, ",", z, "point index: ", point_index)
			if point_index != null:
				var other_point := points[point_index]
				var squared_dist: float = candidate.distance_squared_to(other_point.origin)
				print("Point in cell ", x, "," ,z, " id ", x + z * grid_size.z, " dist ", sqrt(squared_dist))
				if squared_dist < squared_radius:
					return false

	return true
