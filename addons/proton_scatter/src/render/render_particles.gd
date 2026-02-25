extends ScatterRender

const ProtonScatterUtil := preload('./../common/scatter_util.gd')

func render(scatter: ProtonScatter, 
			config: Resource, 
			item: ProtonScatterItem, 
			root: Node3D, 
			mesh_instance: MeshInstance3D, 
			transforms: Array[Transform3D]
			):

	var transforms_count: int = transforms.size()
	var domain := scatter.domain

	var particles = _get_or_create_particles(item, root, mesh_instance)
	if not particles:
		return

	particles.visibility_aabb = AABB(domain.bounds_local.min, domain.bounds_local.size)
	particles.amount = transforms_count

	for t in transforms:
		particles.emit_particle(
			t,
			Vector3.ZERO,
			Color.WHITE,
			Color.BLACK,
			GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_ROTATION_SCALE)


func _get_or_create_particles(item: ProtonScatterItem, item_root: Node3D, mesh_instance: MeshInstance3D) -> GPUParticles3D:

	if not mesh_instance:
		return

	var particles: GPUParticles3D = item_root.get_node_or_null("GPUParticles3D")

	if not particles:
		particles = GPUParticles3D.new()
		particles.set_name("GPUParticles3D")
		item_root.add_child(particles)

		particles.set_owner(item_root.owner)


	particles.material_override = ProtonScatterUtil.get_final_material(item, mesh_instance)
	particles.set_draw_pass_mesh(0, mesh_instance.mesh)
	particles.position = Vector3.ZERO
	particles.local_coords = true
	particles.layers = item.visibility_layers

	# Use the user provided material if it exists.
	var process_material: Material = item.override_process_material

	# Or load the default one if there's nothing.
	if not process_material:
		process_material = ShaderMaterial.new()
		process_material.shader = preload("../particles/static.gdshader")

	if process_material is ShaderMaterial:
		process_material.set_shader_parameter("global_transform", item_root.get_global_transform())

	particles.set_process_material(process_material)

	# TMP: Workaround to get infinite life time.
	# Should be fine, but extensive testing is required.
	# I can't get particles to restart when using emit_particle() from a script, so it's either
	# that, or encoding the transform array in a texture an read that data from the particle
	# shader, which is significantly harder.
	particles.lifetime = 1.79769e308

	# Kill previous particles or new ones will not spawn.
	particles.restart()

	return particles
