@tool
extends PopupPanel


# Formats and displays the DocumentationData provided by other parts of the addon
# TODO: Adjust title font size based on the editor font size / scaling


const DocumentationInfo = preload("./documentation_info.gd")
const SpecialPages = preload("./pages/special_pages.gd")

var _pages := {}
var _items := {}
var _categories_roots := {}

var _modifiers_root: TreeItem

var _edited_text: String
var _accent_color := Color.CORNFLOWER_BLUE
var _editor_scale := 1.0
var _header_size := 20
var _sub_header_size := 16

var _populated := false


@onready var tree: Tree = $HSplitContainer/Tree
@onready var label: RichTextLabel = $HSplitContainer/RichTextLabel


func _ready() -> void:
	tree.create_item() # Create tree root
	tree.hide_root = true
	tree.item_selected.connect(_on_item_selected)

	add_page(SpecialPages.get_scatter_documentation(), tree.create_item())
	add_page(SpecialPages.get_item_documentation(), tree.create_item())
	add_page(SpecialPages.get_shape_documentation(), tree.create_item())
	add_page(SpecialPages.get_cache_documentation(), tree.create_item())

	_modifiers_root = tree.create_item()
	add_page(SpecialPages.get_modifiers_documentation(), _modifiers_root)

	_populate()


# Fed from the StackPanel scene, before the ready function
func set_editor_plugin(editor_plugin: EditorPlugin) -> void:
	if not editor_plugin:
		return

	var editor_interface := editor_plugin.get_editor_interface()
	var editor_settings := editor_interface.get_editor_settings()

	_accent_color = editor_settings.get("interface/theme/accent_color")
	_editor_scale = editor_interface.get_editor_scale()


func show_page(page_name: String) -> void:
	if not page_name in _items:
		return

	var item: TreeItem = _items[page_name]
	item.select(0)
	popup_centered(Vector2i(900, 600))


# Generate a formatted string from the DocumentationInfo input.
# This string will be stored and later displayed in the RichTextLabel so we
# we don't have to regenerate it everytime we look at another page.
func add_page(info: DocumentationInfo, item: TreeItem = null) -> void:
	if not item:
		var root: TreeItem = _get_or_create_tree_root(info.get_category())
		item = tree.create_item(root)

	item.set_text(0, info.get_title())

	_begin_formatting()

	# Page title
	_format_title(info.get_title())

	# Paragraphs
	for p in info.get_paragraphs():
		_format_paragraph(p)

	# Parameters
	if not info.get_parameters().is_empty():
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


func _populate():
	if _populated: # Already generated the documentation pages
		return

	var path = _get_root_folder() + "/src/modifiers/"
	var result := {}
	_discover_modifiers_recursive(path, result)

	var names := result.keys()
	names.sort()

	for n in names:
		var info = result[n]
		add_page(info)

	_populated = true


func _discover_modifiers_recursive(path, result) -> void:
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
			_discover_modifiers_recursive(path_root + file, result)
			continue
		if not file.ends_with(".gd") and not file.ends_with(".gdc"):
			continue

		var full_path = path_root + file
		var script = load(full_path)
		if not script or not script.can_instantiate():
			print("Error: Failed to load script ", file)
			continue

		var modifier = script.new()

		var info: DocumentationInfo = modifier.documentation
		info.set_title(modifier.display_name)
		info.set_category(modifier.category)
		if modifier.use_edge_data:
			info.add_warning(
				"This modifier uses edge data (represented by the blue lines
				on the Scatter node). These edges are usually locked to the
				local XZ plane, (except for the Path shape when they are
				NOT closed). If you can't see these lines, make sure to have at
				least one Shape crossing the ProtonScatter local XZ plane.",
				1)

		if modifier.deprecated:
			info.add_warning(
				"This modifier has been deprecated. It won't receive any updates
				and will be deleted in a future update.",
				2)

		result[modifier.display_name] = info

	dir.list_dir_end()


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(-6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _get_or_create_tree_root(root_name: String) -> TreeItem:
	if root_name in _categories_roots:
		return _categories_roots[root_name]

	var root = tree.create_item(_modifiers_root)
	root.set_text(0, root_name)
	root.set_selectable(0, false)
	_categories_roots[root_name] = root
	return root


func _begin_formatting() -> void:
	_edited_text = ""


func _get_formatted_text() -> String:
	return _edited_text


func _format_title(text: String) -> void:
	_edited_text += "[font_size=" + var_to_str(_header_size * _editor_scale) + "]"
	_edited_text += "[color=" + _accent_color.to_html() + "]"
	_edited_text += "[center][b]"
	_edited_text += text
	_edited_text += "[/b][/center]"
	_edited_text += "[/color]"
	_edited_text += "[/font_size]"
	_format_line_break(2)


func _format_subtitle(text: String) -> void:
	_edited_text += "[font_size=" + var_to_str(_header_size * _editor_scale) + "]"
	_edited_text += "[color=" + _accent_color.to_html() + "]"
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
	var root_folder = _get_root_folder()

	_edited_text += "[indent]"

	if not p.type.is_empty():
		var file_name = p.type.to_lower() + ".svg"
		_edited_text += "[img]" + root_folder + "/icons/types/" + file_name + "[/img] "

	_edited_text += "[b]" + p.name + "[/b]  "

	match p.cost:
		1:
			_edited_text += "[img]" + root_folder + "/icons/arrow_log.svg[/img]"
		2:
			_edited_text += "[img]" + root_folder + "/icons/arrow_linear.svg[/img]"
		3:
			_edited_text += "[img]" + root_folder + "/icons/arrow_exp.svg[/img]"

	_format_line_break(2)
	_edited_text += "[indent]" + p.description + "[/indent]"
	_format_line_break(2)

	for warning in p.warnings:
		if not warning.text.is_empty():
			_format_warning(warning)

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

	_format_line_break(1)


func _on_item_selected() -> void:
	var selected: TreeItem = tree.get_selected()

	if _pages.has(selected):
		var text: String = _pages[selected]
		label.set_text(text)
	else:
		label.set_text("[center] Under construction [/center]")
