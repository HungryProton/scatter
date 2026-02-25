extends ScatterRender

const ProtonScatterUtil := preload('./../common/scatter_util.gd')

func render(scatter: ProtonScatter, 
			config: Resource, 
			item: ProtonScatterItem, 
			root: Node3D, 
			mesh_instance: MeshInstance3D, 
			transforms: Array[Transform3D]
			):
				
	print("Instancing render")

	var domain := scatter.domain
	var chunk_dimensions := scatter.chunk_dimensions
	
	var size = domain.bounds_local.size

	var splits := Vector3i.ONE
	
	if scatter.use_chunks:
		splits.x = max(1, ceil(size.x / chunk_dimensions.x))
		splits.y = max(1, ceil(size.y / chunk_dimensions.y))
		splits.z = max(1, ceil(size.z / chunk_dimensions.z))
	else:
		chunk_dimensions = size

	# create 3d array with dimensions of split_size to store the chunks' transforms
	var transform_chunks : Array = []
	for xi in splits.x:
		transform_chunks.append([])
		for yi in splits.y:
			transform_chunks[xi].append([])
			for zi in splits.z:
				transform_chunks[xi][yi].append([])

	var aabb = ProtonScatterUtil.get_aabb_from_transforms(transforms)
	aabb = aabb.grow(0.1) # avoid degenerate cases
	
	for t in transforms:
		
		# If this fires, a modifier misbehaved
		assert(aabb.has_point(t.origin))
		
		var position_normalized_to_aabb = (t.origin - aabb.position) / aabb.size
		var chunk_index = (position_normalized_to_aabb * Vector3(splits)).floor()
		# Store the transform to the appropriate array
		transform_chunks[chunk_index.x][chunk_index.y][chunk_index.z].append(t)
		
	# The relevant transforms are now distributed in chunks
	for xi in splits.x:
		for yi in splits.y:
			for zi in splits.z:
				var chunk_elements = transform_chunks[xi][yi][zi].size()
				if chunk_elements == 0:
					continue
					
				var mmi = _get_or_create_multimesh_chunk(
												item, root,
												mesh_instance,
												Vector3i(xi, yi, zi),
												chunk_elements)
				if not mmi:
					continue

				if scatter.show_output_in_tree:
					mmi.owner = root.get_tree().edited_scene_root

				# Use the eventual aabb as origin
				# The multimeshinstance needs to be centered where the transforms are
				# This matters because otherwise the visibility range fading is messed up
				var center =  ProtonScatterUtil.get_aabb_from_transforms(transform_chunks[xi][yi][zi]).get_center()
				mmi.transform.origin = center

				var t: Transform3D
				for i in chunk_elements:
					t = transform_chunks[xi][yi][zi][i]
					t.origin -= center
					mmi.multimesh.set_instance_transform(i, t)
						
		mesh_instance.queue_free()

func _get_or_create_multimesh_chunk(item: ProtonScatterItem, item_root: Node3D,
										mesh_instance: MeshInstance3D,
										index: Vector3i,
										count: int)\
										 -> MultiMeshInstance3D:
											
	var chunk_name = "MultiMeshInstance3D" + "_%s_%s_%s_%s"%[index.x, index.y, index.z, mesh_instance.get_instance_id()]
	var mmi: MultiMeshInstance3D = item_root.get_node_or_null(chunk_name)
	if not mesh_instance:
		return

	if not mmi:
		mmi = MultiMeshInstance3D.new()
		# Dont use add_child for 'readable name' suffix, as (a) it requires costly defering
		# and (b) it 'potentionally' can cause the lookup above to fail due to the prefixes added.
		# The prefix should be const per set, and is now instance ID above.
		# This saves seconds on test with 50k and 100k items.
		mmi.set_name(chunk_name)
		item_root.add_child(mmi)

	if not mmi.multimesh:
		mmi.multimesh = MultiMesh.new()
		if item.custom_script:
			mmi.multimesh.use_colors = true
			mmi.multimesh.use_custom_data = true
			mmi.set_script(item.custom_script)
	elif not item.custom_script:
		# We should reset the use_* props of the multimesh, which fails if instance_count > 0. 
		mmi.multimesh.instance_count = 0
		mmi.multimesh.use_colors = false
		mmi.multimesh.use_custom_data = false

	mmi.position = Vector3.ZERO
	mmi.material_override = ProtonScatterUtil.get_final_material(item, mesh_instance)
	mmi.set_cast_shadows_setting(item.override_cast_shadow)

	mmi.multimesh.instance_count = 0 # Set this to zero or you can't change the other values
	mmi.multimesh.mesh = mesh_instance.mesh
	mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D

	mmi.visibility_range_begin 			= item.visibility_range_begin
	mmi.visibility_range_begin_margin 	= item.visibility_range_begin_margin
	mmi.visibility_range_end 			= item.visibility_range_end
	mmi.visibility_range_end_margin 	= item.visibility_range_end_margin
	mmi.visibility_range_fade_mode 		= item.visibility_range_fade_mode
	mmi.layers = item.visibility_layers

	mmi.multimesh.instance_count = count
	ProtonScatterUtil.copy_instance_shader_parameters(mesh_instance, mmi)

	return mmi
