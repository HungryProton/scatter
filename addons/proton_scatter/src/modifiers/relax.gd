@tool
extends "base_modifier.gd"


const shader_file := preload("./compute_shaders/compute_relax.glsl")


@export var iterations : int = 3
@export var offset_step : float = 0.01
@export var consecutive_step_multiplier : float = 0.5
@export var use_computeshader : bool = true


func _init() -> void:
	display_name = "Relax Position"
	category = "Edit"
	global_reference_frame_available = false
	local_reference_frame_available = false
	individual_instances_reference_frame_available = false
	can_restrict_height = true
	restrict_height = true

	documentation.add_warning(
		"This modifier is has an O(n²) complexity and will be slow with
		large amounts of points, unless your device supports compute shaders.",
		1)

	var p := documentation.add_parameter("iterations")
	p.set_type("int")
	p.set_cost(2)
	p.set_description(
		"How many times the relax algorithm will run. Increasing this value will
		generally improves the result, at the cost of execution speed."
		)

	p = documentation.add_parameter("Offset step")
	p.set_type("float")
	p.set_cost(0)
	p.set_description("How far the transform will be pushed away each iteration.")

	p = documentation.add_parameter("Consecutive step multiplier")
	p.set_type("float")
	p.set_cost(0)
	p.set_description(
		"On each iteration, multiply the offset step by this value. This value
		is usually set between 0 and 1, to make the effect less pronounced on
		successive iterations.")

	p = documentation.add_parameter("Use compute shader")
	p.set_cost(0)
	p.set_type("bool")
	p.set_description(
		"Run the calculations on the GPU instead of the CPU. This provides
		a significant speed boost and should be enabled when possible.")
	p.add_warning(
		"This parameter can't be enabled when using the OpenGL backend or running
		in headless mode.", 2)


func _process_transforms(transforms, _domain, _seed) -> void:
	var offset := offset_step
	if transforms.size() < 2:
		return

	# Disable the use of compute shader, if we cannot create a RenderingDevice
	if use_computeshader:
		var rd := RenderingServer.create_local_rendering_device()
		if rd == null:
			use_computeshader = false
		else:
			rd.free()
			rd = null

	if use_computeshader:
		for iteration in iterations:
			var movedir: PackedVector3Array = compute_closest(transforms)
			for i in transforms.size():
				var dir = movedir[i]
				if restrict_height:
					dir.y = 0.0
				# move away from closest point
				transforms.list[i].origin += dir.normalized() * offset

			offset *= consecutive_step_multiplier

	else:
		# calculate the relax transforms on the cpu
		for iteration in iterations:
			for i in transforms.size():
				var min_vector = Vector3.ONE * 99999.0
				var threshold := 99999.0
				var distance := 0.0
				var diff: Vector3

				# Find the closest point
				for j in transforms.size():
					if i == j:
						continue

					diff = transforms.list[i].origin - transforms.list[j].origin
					distance = diff.length_squared()

					if distance < threshold:
						min_vector = diff
						threshold = distance

				if restrict_height:
					min_vector.y = 0.0

				# move away from closest point
				transforms.list[i].origin += min_vector.normalized() * offset

			offset *= consecutive_step_multiplier


# compute the closest points to each other using a compute shader
# return a vector for each point that points away from the closest neighbour
func compute_closest(transforms) -> PackedVector3Array:
	var padded_num_vecs = ceil(float(transforms.size()) / 64.0) * 64
	var padded_num_floats = padded_num_vecs * 4
	var rd := RenderingServer.create_local_rendering_device()
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	# Prepare our data. We use vec4 floats in the shader, so we need 32 bit.
	var input := PackedFloat32Array()
	for i in transforms.size():
		input.append(transforms.list[i].origin.x)
		input.append(transforms.list[i].origin.y)
		input.append(transforms.list[i].origin.z)
		input.append(0) # needed to use vec4, necessary for byte alignment in the shader code
	# buffer size, number of vectors sent to the gpu
	input.resize(padded_num_floats) # indexing in the compute shader requires padding
	var input_bytes := input.to_byte_array()
	var output_bytes := input_bytes.duplicate()
	# Create a storage buffer that can hold our float values.
	var buffer_in := rd.storage_buffer_create(input_bytes.size(), input_bytes)
	var buffer_out := rd.storage_buffer_create(output_bytes.size(), output_bytes)

	# Create a uniform to assign the buffer to the rendering device
	var uniform_in := RDUniform.new()
	uniform_in.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_in.binding = 0 # this needs to match the "binding" in our shader file
	uniform_in.add_id(buffer_in)
	# Create a uniform to assign the buffer to the rendering device
	var uniform_out := RDUniform.new()
	uniform_out.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_out.binding = 1 # this needs to match the "binding" in our shader file
	uniform_out.add_id(buffer_out)
	# the last parameter (the 0) needs to match the "set" in our shader file
	var uniform_set := rd.uniform_set_create([uniform_in, uniform_out], shader, 0)

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# each workgroup computes 64 vectors
#	print("Dispatching workgroups: ", padded_num_vecs/64)
	rd.compute_list_dispatch(compute_list, padded_num_vecs/64, 1, 1)
	rd.compute_list_end()
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	# Read back the data from the buffer
	var result_bytes := rd.buffer_get_data(buffer_out)
	var result := result_bytes.to_float32_array()
	var retval = PackedVector3Array()
	for i in transforms.size():
		retval.append(Vector3(result[i*4], result[i*4+1], result[i*4+2]))

	# Free the allocated objects.
	# All resources must be freed after use to avoid memory leaks.
	if rd != null:
		rd.free_rid(pipeline)
		rd.free_rid(uniform_set)
		rd.free_rid(shader)
		rd.free_rid(buffer_in)
		rd.free_rid(buffer_out)
		rd.free()
		rd = null
	return retval
