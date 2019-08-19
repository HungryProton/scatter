tool
extends EditorPlugin

# /!\ This plugin depends on the GM_Path plugin. They must be both active for
# this plugin to work

# --
# EditorPlugin overrides
# --

func get_name(): 
	return "GM Fill area"

func _enter_tree():
	add_custom_type(
		"GM_FillArea", 
		"GM_Path",
		load("res://addons/gm_fill_area/gm_fill_area.gd"),
		load("res://addons/gm_fill_area/icons/fill.svg")
	)
	add_custom_type(
		"GM_ItemArea", 
		"Node",
		load("res://addons/gm_fill_area/gm_item_area.gd"),
		load("res://addons/gm_fill_area/icons/item.svg")
	)

func _exit_tree():
	remove_custom_type("GM_FillArea")
	remove_custom_type("GM_ItemArea")

# --
# Internal methods
# --