@tool
extends PopupPanel


# Formats and displays the DocumentationData provided by other parts of the addon


const DocumentationInfo = preload("./documentation_info.gd")


var _pages := {}
var _items := {}
var _roots := {}
var _modifiers = []

@onready var tree: Tree = $HSplitContainer/Tree
@onready var label: RichTextLabel = $HSplitContainer/RichTextLabel


func _ready() -> void:
	tree.create_item() # Create tree root
	tree.hide_root = true
	tree.item_selected.connect(_on_item_selected)
	_populate()


func show_page(page_name: String) -> void:
	if not page_name in _items:
		return

	var item: TreeItem = _items[page_name]
	item.select(0)
	popup_centered(Vector2i(900, 600))


# Generate a formatted string from the DocumentationInfo input.
# This string will be stored and later displayed in the RichTextLabel so we
# we don't have to regenerate it everytime we look at another page.
func add_page(info: DocumentationInfo) -> void:
	var root: TreeItem = _get_or_create_tree_root(info.get_category())
	var item: TreeItem = tree.create_item(root)
	item.set_text(0, info.get_title())

	var formatted_text := ""

	# Page title
	formatted_text += "[center][b]" + info.get_title() + "[/b][/center]\n\n"

	# Paragraphs
	for p in info.get_paragraphs():
		formatted_text += p + "\n\n"

	# Parameters
	for p in info.get_parameters():
		formatted_text += "[b]" + p.name + "[/b]\n"
		formatted_text += p.description + "\n"
		formatted_text += "[yellow]" + p.warning.text + "[/yellow]"

	_pages[item] = formatted_text
	_items[info.get_title()] = item


func _populate():
	var path = _get_root_folder() + "/src/modifiers/"
	_discover_modifiers(path)

	for modifier in _modifiers:
		var instance = modifier.new()
		var info: DocumentationInfo = instance.documentation
		info.set_title(instance.display_name)
		info.set_category(instance.category)
		add_page(info)


func _discover_modifiers(path) -> void:
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
			_discover_modifiers(path_root + file)
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


func _get_or_create_tree_root(root_name: String) -> TreeItem:
	if root_name in _roots:
		return _roots[root_name]

	var root = tree.create_item()
	root.set_text(0, root_name)
	_roots[root_name] = root
	return root


func _on_item_selected() -> void:
	print("on item selected")
	var selected: TreeItem = tree.get_selected()
	var text: String = _pages[selected]
	label.set_text(text)
