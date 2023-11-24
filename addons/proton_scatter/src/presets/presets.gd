@tool
extends Popup


const PRESETS_PATH = "res://addons/proton_scatter/presets"
const PresetEntry := preload("./preset_entry.tscn")
const ProtonScatterUtil := preload('../common/scatter_util.gd')
const ProtonScatterItem := preload('../scatter_item.gd')
const ProtonScatterShape := preload('../scatter_shape.gd')

var _scatter_node
var _ideal_popup_size: Vector2i
var _editor_file_system: EditorFileSystem


func _ready():
	$%NewPresetButton.pressed.connect(_show_preset_dialog)
	$%NewPresetDialog.confirmed.connect(_on_new_preset_name_confirmed)


func save_preset(scatter_node: Node3D) -> void:
	if not scatter_node:
		return

	_populate()
	_scatter_node = scatter_node
	$%NewPresetButton.visible = true

	for c in $%PresetsRoot.get_children():
		c.show_save_controls()

	popup_centered(_ideal_popup_size)


func load_preset(scatter_node: Node3D) -> void:
	if not scatter_node:
		return

	_populate()
	_scatter_node = scatter_node
	$%NewPresetButton.visible = false

	for c in $%PresetsRoot.get_children():
		c.show_load_controls()

	popup_centered(_ideal_popup_size)


func load_default(scatter_node: Node3D) -> void:
	_scatter_node = scatter_node
	_on_load_full_preset(PRESETS_PATH.path_join("scatter_default.tscn"))


func set_editor_plugin(editor_plugin: EditorPlugin) -> void:
	if not editor_plugin:
		return

	_editor_file_system = editor_plugin.get_editor_interface().get_resource_filesystem()


func _clear():
	for c in $%PresetsRoot.get_children():
		c.queue_free()


func _populate() -> void:
	_clear()
	var dir = DirAccess.open(PRESETS_PATH)
	if not dir:
		print_debug("ProtonScatter error: Could not open folder ", PRESETS_PATH)
		return

	dir.include_hidden = false
	dir.include_navigational = false
	dir.list_dir_begin()

	while true:
		var file := dir.get_next()
		if file == "":
			break

		if dir.current_is_dir():
			continue

		if not file.ends_with(".tscn") and not file.ends_with(".scn"):
			continue

		# Preset found, create an entry
		var full_path = PRESETS_PATH.path_join(file)
		var entry := PresetEntry.instantiate()
		entry.set_preset_name(file.get_basename())
		entry.load_full.connect(_on_load_full_preset.bind(full_path))
		entry.load_stack_only.connect(_on_load_stack_only.bind(full_path))
		entry.delete.connect(_on_delete_preset.bind(full_path, entry))

		$%PresetsRoot.add_child(entry)

	dir.list_dir_end()
	var full_height = $%PresetsRoot.get_child_count() * 120
	_ideal_popup_size = Vector2i(450, clamp(full_height, 120, 500))


func _show_preset_dialog() -> void:
	$%NewPresetName.set_text("")
	$%NewPresetDialog.popup_centered()


func _on_new_preset_name_confirmed() -> void:
	var file_name: String = $%NewPresetName.text.to_lower().strip_edges() + ".tscn"
	var full_path := PRESETS_PATH.path_join(file_name)
	_on_save_preset(full_path)
	hide()


func _on_save_preset(path) -> void:
	var preset = _scatter_node.duplicate(7)
	preset.clear_output()
	ProtonScatterUtil.set_owner_recursive(preset, preset)
	preset.global_transform.origin = Vector3.ZERO

	var packed_scene = PackedScene.new()
	if packed_scene.pack(preset) != OK:
		print_debug("ProtonScatter error: Failed to save preset")
		return

	var err = ResourceSaver.save(packed_scene, path)
	if err:
		print_debug("ProtonScatter error: Failed to save preset. Code: ", err)


func _on_load_full_preset(path: String) -> void:
	var preset_scene: PackedScene = load(path)
	if not preset_scene:
		print("Could not find preset ", path)
		return

	var preset = preset_scene.instantiate()

	if preset:
		_scatter_node.modifier_stack = preset.modifier_stack.get_copy()
		preset.global_transform = _scatter_node.get_global_transform()

		for c in _scatter_node.get_children():
			if c is ProtonScatterItem or c is ProtonScatterShape:
				_scatter_node.remove_child(c)
				c.queue_free()

		for c in preset.get_children():
			if c is Marker3D or c.name == "ScatterOutput":
				continue
			preset.remove_child(c)
			_scatter_node.add_child(c, true)

		ProtonScatterUtil.set_owner_recursive(_scatter_node, get_tree().get_edited_scene_root())
		preset.queue_free()
	
	_scatter_node.rebuild.call_deferred()
	hide()


func _on_load_stack_only(path: String) -> void:
	var preset = load(path).instantiate()
	if preset:
		_scatter_node.modifier_stack = preset.modifier_stack.get_copy()
		_scatter_node.rebuild.call_deferred()
		preset.queue_free()

	hide()


func _on_delete_preset(path: String, entry: Control) -> void:
	DirAccess.remove_absolute(path)
	$%PresetsRoot.remove_child(entry)
	entry.queue_free()
	_editor_file_system.scan() # Refresh the filesystem view
