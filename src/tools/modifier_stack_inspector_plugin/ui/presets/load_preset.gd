tool
extends WindowDialog


signal load_preset
signal delete_preset


onready var _no_presets: Label = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/NoPresets
onready var _root: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/PresetsRoot
onready var _confirmation_dialog: ConfirmationDialog = $ConfirmationDialog

var _selected: String
var _selected_ui: Node


func _ready():
	_rebuild_ui()
	connect("about_to_show", self, "_rebuild_ui")


func _rebuild_ui():
	for c in _root.get_children():
		c.queue_free()
	_root.visible = false

	var presets = _find_all_presets()
	if presets.empty():
		_no_presets.visible = true
		return

	_no_presets.visible = false
	_root.visible = true
	for p in presets:
		var ui = preload("./preset.tscn").instance()
		_root.add_child(ui)
		ui.set_preset_name(p)
		ui.connect("load_preset", self, "_on_load_preset", [p])
		ui.connect("delete_preset", self, "_on_delete_preset", [p, ui])


func _find_all_presets() -> Array:
	var root := _get_root_folder() + "/presets/"
	var res := []
	var dir = Directory.new()
	dir.open(root)
	dir.list_dir_begin(true, true)

	while true:
		var file = dir.get_next()
		if file == "":
			break

		if file.ends_with(".tscn"):
			res.push_back(file.get_basename())

	dir.list_dir_end()
	res.sort()
	return res


func _get_root_folder() -> String:
	var path: String = get_script().get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_load_preset(preset_name) -> void:
	emit_signal("load_preset", preset_name)
	visible = false


func _on_delete_preset(preset_name, ui) -> void:
	_selected = preset_name
	_selected_ui = ui
	_confirmation_dialog.popup_centered()


func _on_delete_preset_confirmed():
	var dir = Directory.new()
	dir.remove(_get_root_folder() + "/presets/" + _selected + ".tscn")
	_selected_ui.queue_free()


func _on_cancel_pressed():
	visible = false
