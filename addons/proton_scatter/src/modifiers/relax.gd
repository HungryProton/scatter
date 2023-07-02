@tool
extends "base_modifier.gd"


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
		"This modifier is currently has an O(n²) complexity and will be slow with
		large amounts of points.
		It will be optimized in a later update.",
		1)


func _process_transforms(transforms, domain, _seed) -> void:
	# TODO this can benefit greatly from multithreading
	if use_computeshader:
		var rd := RenderingServer.create_local_rendering_device()
		var shader_file := load("res://compute_example.glsl")
		var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
		var shader := rd.shader_create_from_spirv(shader_spirv)
		# Prepare our data. We use floats in the shader, so we need 32 bit.
		var input := PackedFloat32Array()
		for i in transforms.size():
			input.append(transforms.list[i].origin.x)
			input.append(transforms.list[i].origin.y)
			input.append(transforms.list[i].origin.z)
			input.append(0)
		var input_bytes := input.to_byte_array()
		var output = input.duplicate()
		output.fill(0)
		var output_bytes := output.to_byte_array()
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
		var uniform_set_out := rd.uniform_set_create([uniform_in, uniform_out], shader, 0)
			
		# Create a compute pipeline
		var pipeline := rd.compute_pipeline_create(shader)
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_out, 0)
		rd.compute_list_dispatch(compute_list, 5, 1, 1)
		rd.compute_list_end()
		# Submit to GPU and wait for sync
		rd.submit()
		rd.sync()
		# Read back the data from the buffer
		var result_bytes := rd.buffer_get_data(buffer_out)
		var result := result_bytes.to_float32_array()
		print("Input: ", input)
		print("Result: ", result)
	
	else:
		if transforms.size() < 2:
			return

		var offset := offset_step

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
