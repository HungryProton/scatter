tool
extends Reference

# DO NOT replace the load by a preload, this will cause a cyclic dependency
# with scatter.gd and prevent the plugin from loading.


var _root = _get_root_folder()

var ScatterPath = load(_root + "/src/core/scatter_path.gd")
var Scatter = load(_root + "/src/core/scatter.gd")
var ScatterItem = load(_root + "/src/core/scatter_item.gd")
var Transforms = load(_root + "/src/core/transforms.gd")
var ModifierStack = load(_root + "/src/core/modifier_stack.gd")
var UpdateGroup = load(_root + "/src/core/update_group.gd")
var Point = load(_root + "/src/core/scatter_exclude_point.gd")
var Util = load(_root + "/src/common/util.gd")


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]
