@tool
extends PopupPanel


# Formats and displays the DocumentationData provided by other parts of the addon
# TODO: Adjust title font size based on the editor font size / scaling


const DocumentationInfo = preload("./documentation_info.gd")


var _pages := {}
var _items := {}
var _roots := {}
var _modifiers = []

var _accent_color := "Cornflowerblue"
var _edited_text: String

@onready var tree: Tree = $HSplitContainer/Tree
@onready var label: RichTextLabel = $HSplitContainer/RichTextLabel


func _ready() -> void:
	tree.create_item() # Create tree root
	tree.hide_root = true
	tree.item_selected.connect(_on_item_selected)
	_accent_color = label.get_theme_color("font_pressed_color", "CheckBox").to_html(false)
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

	_begin_formatting()

	# Page title
	_format_title(info.get_title())

	# Paragraphs
	for p in info.get_paragraphs():
		_format_paragraph(p)

	# Parameters
	_format_subtitle("Parameters")

	for p in info.get_parameters():
		_format_parameter(p)

	# Warnings
	if not info.get_warnings().is_empty():
		_format_subtitle("Warnings")

		for w in info.get_warnings():
			_format_warning(w)

	_pages[item] = _get_formatted_text()
	_items[info.get_title()] = item


func set_accent_color(color: String) -> void:
	_accent_color = color


func _populate():
	var path = _get_root_folder() + "/src/modifiers/"
	_discover_modifiers(path)

	for modifier in _modifiers:
		var instance = modifier.new()
		var info: DocumentationInfo = instance.documentation
		info.set_title(instance.display_name)
		info.set_category(instance.category)

		if instance.use_edge_data:
			info.add_warning("The domain edge is represented by the blue lines
				on the Scatter node. These edges are usually locked to the
				Scatter local XZ plane, (except for the Path shape when they are
				NOT closed). If you can't see any result, make sure to have at
				least a Shape crossing the local XZ plane.",
				1
			)

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


func _begin_formatting() -> void:
	_edited_text = ""


func _get_formatted_text() -> String:
	return _edited_text


func _format_title(text: String) -> void:
	_edited_text += "[font_size=20]"
	_edited_text += "[color=" + _accent_color + "]"
	_edited_text += "[center][b]"
	_edited_text += text
	_edited_text += "[/b][/center]"
	_edited_text += "[/color]"
	_edited_text += "[/font_size]"
	_format_line_break(2)


func _format_subtitle(text: String) -> void:
	_edited_text += "[font_size=16]"
	_edited_text += "[color=" + _accent_color + "]"
	_edited_text += "[b]" + text + "[/b]"
	_edited_text += "[/color]"
	_edited_text += "[/font_size]"
	_format_line_break(2)


func _format_line_break(count := 1) -> void:
	for i in count:
		_edited_text += "\n"


func _format_paragraph(text: String) -> void:
	_edited_text += "[p]" + text + "[/p]"
	_format_line_break(2)


func _format_parameter(p) -> void:
	_edited_text += "[indent]"
	_edited_text += "[b]" + p.name + "[/b]  "
	match p.cost:
		1:
			_edited_text += "[img]res://addons/proton_scatter/icons/arrow_log.svg[/img]"
		2:
			_edited_text += "[img]res://addons/proton_scatter/icons/arrow_linear.svg[/img]"
		3:
			_edited_text += "[img]res://addons/proton_scatter/icons/arrow_exp.svg[/img]"

	_format_line_break(2)
	_edited_text += "[indent]" + p.description + "[/indent]"
	_format_line_break(2)

	if not p.warning.text.is_empty():
		_format_warning(p.warning)
		_format_line_break()

	_edited_text += "[/indent]"


func _format_warning(w, indent := true) -> void:
	if indent:
		_edited_text += "[indent]"

	var color := "Darkgray"
	match w.importance:
		1:
			color = "yellow"
		2:
			color = "red"

	_edited_text += "[color=" + color + "][i]" + w.text + "[/i][/color]\n"

	if indent:
		_edited_text += "[/indent]"


func _on_item_selected() -> void:
	var selected: TreeItem = tree.get_selected()
	var text: String = _pages[selected]
	label.set_text(text)
