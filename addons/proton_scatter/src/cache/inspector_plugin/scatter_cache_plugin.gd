@tool
extends EditorInspectorPlugin


const CachePanel: GDScript = preload("./cache_panel.gd")
const CachePanelScene: PackedScene = preload("./cache_panel.tscn")


func _can_handle(object: Object) -> bool:
	return is_instance_of(object, ProtonScatterCache)


func _parse_category(object: Object, category: String) -> void:
	var cache: ProtonScatterCache = object
	if not cache:
		return
	if category == "ScatterCache" or category == "scatter_cache.gd":
		var ui: CachePanel = CachePanelScene.instantiate()
		ui.set_object(cache)
		add_custom_control(ui)
