tool
extends Control


signal move_up
signal move_down
signal remove_modifier


export var parameters: NodePath
export var display_name: NodePath

var _parameters: Control
var _name: Label
var _margin_container: MarginContainer


func _ready() -> void:
	_parameters = get_node(parameters)
	_name = get_node(display_name)
	_margin_container = get_child(1)
	_margin_container.connect("resized", self, "_on_child_resized")


func set_modifier_name(text: String) -> void:
	_name.text = text


func _on_expand_toggled(toggled: bool) -> void:
	_parameters.visible = toggled


func _on_move_up_pressed() -> void:
	emit_signal("move_up")


func _on_move_down_pressed() -> void:
	emit_signal("move_down")


func _on_remove_pressed() -> void:
	emit_signal("remove_modifier")


func _on_child_resized() -> void:
	rect_min_size.y = _margin_container.rect_size.y
