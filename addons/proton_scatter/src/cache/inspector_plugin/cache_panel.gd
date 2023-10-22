@tool
extends PanelContainer


const ScatterCache := preload("res://addons/proton_scatter/src/cache/scatter_cache.gd")


@onready var _rebuild_button: Button = %RebuildButton
@onready var _restore_button: Button = %RestoreButton
@onready var _clear_button: Button = %ClearButton
@onready var _enable_for_all_button: Button = %EnableForAllButton

var _cache: ScatterCache


func _ready() -> void:
	_rebuild_button.pressed.connect(_on_rebuild_pressed)
	_restore_button.pressed.connect(_on_restore_pressed)
	_clear_button.pressed.connect(_on_clear_pressed)
	_enable_for_all_button.pressed.connect(_on_enable_for_all_pressed)
	custom_minimum_size.y = size.y * 1.25


func set_object(cache: ScatterCache) -> void:
	_cache = cache


func _on_rebuild_pressed() -> void:
	if is_instance_valid(_cache):
		_cache.update_cache()


func _on_restore_pressed() -> void:
	if is_instance_valid(_cache):
		_cache.restore_cache()


func _on_clear_pressed() -> void:
	if is_instance_valid(_cache):
		_cache.clear_cache()


func _on_enable_for_all_pressed() -> void:
	if is_instance_valid(_cache):
		_cache.enable_for_all_nodes()
