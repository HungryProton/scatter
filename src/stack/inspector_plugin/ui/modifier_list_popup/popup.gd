@tool
extends PopupPanel


signal add_modifier

var _modifiers := []

@onready var _category_root: Control = $MarginContainer/CategoryRoot


func _ready() -> void:
	_rebuild_ui()


func _rebuild_ui():
	for c in _category_root.get_children():
		c.queue_free()

	_discover_modifiers()
	for modifier in _modifiers:
		var instance = modifier.new()
		if instance.enabled:
			var category = _get_or_create_category(instance.category)
			var button = _create_button(instance.display_name)
			category.add_child(button, true)
			button.pressed.connect(_on_pressed.bind(modifier))

	for category in _category_root.get_children():
		var header = category.get_child(0)
		_sort_children_by_name(category)
		category.move_child(header, 0)


func _create_button(display_name) -> Button:
	var button = Button.new()
	button.name = display_name
	button.text = display_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


func _sort_children_by_name(node: Node) -> void:
	var dict := {}
	var names := []

	for child in node.get_children():
		names.push_back(child.name)
		dict[child.name] = child

	names.sort_custom(func(a, b): return String(a) < String(b))

	for i in names.size():
		var n = names[i]
		node.move_child(dict[n], i)


func _get_or_create_category(text: String) -> Control:
	if _category_root.has_node(text):
		return _category_root.get_node(text) as Control

	var c = preload("category.tscn").instantiate()
	c.name = text
	_category_root.add_child(c, true)
	c.set_category_name(text)
	return c


func _discover_modifiers() -> void:
	if _modifiers.is_empty():
		var path = _get_root_folder() + "/src/modifiers/"
		_discover_modifiers_recursive(path)


func _discover_modifiers_recursive(path) -> void:
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var path_root = dir.get_current_dir() + "/"

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file == "base_modifier.gd":
			continue
		if dir.current_is_dir():
			_discover_modifiers_recursive(path_root + file)
			continue
		if not file.ends_with(".gd") and not file.ends_with(".gdc"):
			continue

		var full_path = path_root + file
		var script = load(full_path)
		if not script or not script.can_instantiate():
			print("Error: Failed to load script ", file)
			continue

		_modifiers.push_back(script)

	dir.list_dir_end()


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(-6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_pressed(modifier) -> void:
	add_modifier.emit(modifier.new())
	visible = false
