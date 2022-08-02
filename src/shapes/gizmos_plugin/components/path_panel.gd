@tool
extends Control


const ScatterShape = preload("../../../scatter_shape.gd")
const PathShape = preload("../../path_shape.gd")

var shape_node: ScatterShape

@onready var _options_button: Button = $%Options
@onready var _options_panel: Popup = $%OptionsPanel


func _ready() -> void:
	_options_button.toggled.connect(_on_options_button_toggled)
	_options_panel.popup_hide.connect(_on_options_panel_hide)
	$%SnapToColliders.toggled.connect(_on_snap_to_colliders_toggled)


# Called by the editor plugin when the node selection changes.
# Hides the panel when the selected node is not a path shape.
func selection_changed(selected: Array) -> void:
	if selected.is_empty():
		visible = false
		shape_node = null
		return

	var node = selected[0]
	visible = node is ScatterShape and node.shape is PathShape
	if visible:
		shape_node = node


func is_select_mode_enabled() -> bool:
	return $%Select.button_pressed


func is_create_mode_enabled() -> bool:
	return $%Create.button_pressed


func is_delete_mode_enabled() -> bool:
	return $%Delete.button_pressed


func _on_options_button_toggled(enabled: bool) -> void:
	if enabled:
		var popup_position := Vector2i(get_global_transform().origin)
		popup_position.y += size.y + 12
		_options_panel.popup(Rect2i(popup_position, Vector2i.ZERO))
	else:
		_options_panel.hide()


func _on_options_panel_hide() -> void:
	_options_button.button_pressed = false


func _on_snap_to_colliders_toggled(enabled: bool) -> void:
	$%LockToPlane.disabled = enabled
