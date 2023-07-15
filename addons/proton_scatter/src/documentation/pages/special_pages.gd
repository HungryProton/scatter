@tool
extends RefCounted

const DocumentationInfo = preload("../documentation_info.gd")


static func get_scatter_documentation() -> DocumentationInfo:
	var info := DocumentationInfo.new()

	info.set_title("ProtonScatter")
	info.add_paragraph(
		"ProtonScatter is a content positioning add-on. It is suited to place
		a large amount of objects in a procedural way.")
	info.add_paragraph(
		"This add-on is [color=red][b]IN BETA[/b][/color] which means breaking
		changes may happen. It is not recommended to use in production yet."
	)
	info.add_paragraph(
		"First, define [i]what[/i] you want to place using [b]ScatterItems[/b]
		nodes.")
	info.add_paragraph(
		"Then, define [i]where[/i] to place them using [b]ScatterShapes[/b]
		nodes.")
	info.add_paragraph(
		"Finaly, define [i]how[/i] the content should be placed using the
		[b]Modifier stack[/b] that's on the [b]ProtonScatter[/b] node.")
	info.add_paragraph(
		"Each of these components have their dedicated documenation page, but
		first, you should check out the example scenes in the demo folder.")

	var p := info.add_parameter("General / Global seed")
	p.set_type("int")
	p.set_description(
		"The random seed to use on this node. Modifiers using random components
		can access this value and use it accordingly. You can also specify
		a custom seed for specific modifiers as well.")

	p = info.add_parameter("General / Show output in tree")
	p.set_type("bool")
	p.set_description(
		"Show the generated items in the editor scene tree. By default this
		option is disabled as it creates quite a bit of clutter when instancing
		is disabled. It also increases the scene file size significantly.")

	p = info.add_parameter("Performance / Use instancing")
	p.set_type("bool")
	p.set_description(
		"When enabled, ProtonScatter will use MultiMeshInstance3D nodes
		instead of duplicating the source nodes. This allows the GPU to render
		thousands of meshes in a single draw call.")
	p.add_warning("Collisions and attached scripts are ignored when this
		option is enabled.", 1)

	return info


static func get_item_documentation() -> DocumentationInfo:
	var info := DocumentationInfo.new()

	info.set_title("ScatterItems")

	info.add_paragraph("TODO: Write this page")

	return info


static func get_shape_documentation() -> DocumentationInfo:
	var info := DocumentationInfo.new()

	info.set_title("ScatterShapes")

	info.add_paragraph("TODO: Write this page")

	return info


static func get_cache_documentation() -> DocumentationInfo:
	var info := DocumentationInfo.new()

	info.set_title("ScatterCache")

	info.add_paragraph(
		"By default, Scatter nodes will recalculate their output on load,
		which can be slow in really complex scenes. The cache allows you to
		store these results in a file on your disk, and load these instead.")
	info.add_paragraph(
		"This can significantly speed up loading times, while also being VCS
		friendly since the transforms are stored in their own files, rather
		than your scenes files.")
	info.add_paragraph("[b]How to use:[/b]")
	info.add_paragraph(
		"[p]+ Disable the [code]Force rebuild on load[code] on every Scatter item you want to cache.[/p]
		[p]+ Add a ScatterCache node anywhere in your scene.[/p]
		[p]+ Press the 'Rebuild' button to scan for other ProtonScatter nodes
		and store their results in the cache.[/p]")
	info.add_paragraph("[i]A single cache per scene is enough.[/i]")

	var p := info.add_parameter("Cache File")
	p.set_cost(0)
	p.set_description("Path to the cache file. By default they are store in the
	add-on folder. Their name has a random component to avoid naming collisions
	with scenes sharing the same file name. You are free to place this file
	anywhere, using any name you would like.")

	return info


static func get_modifiers_documentation() -> DocumentationInfo:
	var info := DocumentationInfo.new()

	info.set_title("Modifiers")
	info.add_paragraph(
		"A modifier takes in a Transform3D list, create, modify or delete
		transforms, then pass it down to the next modifier. Remember that
		[b] modifiers are processed from top to bottom [/b]. A modifier
		down the stack will recieve a list processed by the modifiers above.")
	info.add_paragraph(
		"The initial transform list is empty, so it's necessary to start the
		stack with a [b] Create [/b] modifier.")
	info.add_paragraph(
		"When clicking the [b] Expand button [/b] (the little arrow on the left)
		you get access to this modifier's parameters. This is where you can
		adjust its behavior according to your needs.")
	info.add_paragraph(
		"Three common options might be found on these modifiers. (They may
		not appear if they are irrelevant). They are defined as follow:")

	var p := info.add_parameter("Use local seed")
	p.set_type("bool")
	p.set_description(
		"The dice icon on the left allows you to force a specific seed for the
		modifier. If this option is not used then the Global seed from the
		ProtonScatter node will be used instead.")

	p = info.add_parameter("Restrict height")
	p.set_type("bool")
	p.set_description(
		"When applicable, the modifier will remain within the local XZ plane
		instead of using the full volume described by the ScatterShape nodes.")

	p = info.add_parameter("Reference frame")
	p.set_type("int")
	p.set_description(
		"[p]+ [b]Global[/b]: Modifier operates in Global space. [/p]
		[p]+ [b]Local[/b]: Modifier operates in local space, relative to the ProtonScatter node.[/p]
		[p]+ [b]Individual[/b]: Modifier operates on local space, relative to each
		individual transforms.[/p]"
		)

	return info
