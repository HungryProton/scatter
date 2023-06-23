@tool
extends PanelContainer


const ScatterCache := preload("res://addons/proton_scatter/src/cache/scatter_cache.gd")


@onready var _rebuild_button: Button = %RebuildButton
@onready var _restore_button: Button = %RestoreButton

var _cache: ScatterCache


func _ready() -> void:
	_rebuild_button.pressed.connect(_on_rebuild_pressed)
	_restore_button.pressed.connect(_on_restore_pressed)
	custom_minimum_size.y = size.y * 1.25


func set_object(cache: ScatterCache) -> void:
	_cache = cache


func _on_rebuild_pressed() -> void:
	if _cache:
		_cache.rebuild_cache()


func _on_restore_pressed() -> void:
	if _cache:
		_cache.restore_cache()
