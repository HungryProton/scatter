tool
extends PopupPanel


signal add_modifier


onready var _category_root: Control = $MarginContainer/CategoryRoot


func _ready() -> void:
	_rebuild_ui()


func _rebuild_ui():
	for c in _category_root.get_children():
		c.queue_free()

	var folder = _get_root_folder() + "/src/modifiers/"
	for script in _get_all_modifier_scripts(folder):
		var modifier = load(script)
		var instance = modifier.new()
		if instance.enabled:
			var category = _get_or_create_category(instance.category)
			var button = _create_button(instance.display_name)
			category.add_child(button)
			button.connect("pressed", self, "_on_pressed", [modifier])

		instance.queue_free()

	for category in _category_root.get_children():
		var header = category.get_child(0)
		_sort_children_by_name(category)
		category.move_child(header, 0)


func _create_button(display_name) -> Button:
	var button = Button.new()
	button.name = display_name
	button.text = display_name
	button.align = Button.ALIGN_LEFT
	return button


func _sort_children_by_name(node: Node) -> void:
	var children = node.get_children()
	var total_passes = len(children) - 1
	for i in range(total_passes):
		for j in range(total_passes - i):
			var k = j + 1
			if children[j].name > children[k].name:
				node.move_child(children[j], k)
				children = node.get_children()


func _get_or_create_category(text: String) -> Control:
	if _category_root.has_node(text):
		return _category_root.get_node(text) as Control

	var c = preload("category.tscn").instance()
	c.name = text
	_category_root.add_child(c, true)
	c.set_category_name(text)
	return c


func _get_all_modifier_scripts(path) -> Array:
	var res := []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	var path_root = dir.get_current_dir() + "/"

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file == "base_modifier.gd":
			continue
		if dir.current_is_dir():
			_get_all_modifier_scripts(path_root + file)
			continue
		if not file.ends_with(".gd") and not file.ends_with(".gdc"):
			continue

		var full_path = path_root + file
		var script = load(full_path)
		if not script or not script.can_instance():
			print("Error: Failed to load script ", file)
			continue

		res.append(path_root + file)

	dir.list_dir_end()
	return res


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_pressed(modifier) -> void:
	emit_signal("add_modifier", modifier.new())
	visible = false
