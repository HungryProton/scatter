@tool
extends EditorInspectorPlugin


const CachePanel = preload("./cache_panel.tscn")
const ScatterCache = preload("../../cache/scatter_cache.gd")


func _can_handle(object):
	return is_instance_of(object, ScatterCache)


func _parse_category(object, category: String):
	if category == "ScatterCache" or category == "scatter_cache.gd":
		var ui = CachePanel.instantiate()
		ui.set_object(object)
		add_custom_control(ui)
