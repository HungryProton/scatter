tool
extends PopupPanel


signal add_modifier


onready var _inside_random = $MarginContainer/HBoxContainer/VBoxContainer/InsideRandom
onready var _inside_grid = $MarginContainer/HBoxContainer/VBoxContainer/InsideGrid
onready var _along_random = $MarginContainer/HBoxContainer/VBoxContainer/AlongRandom
onready var _along_even = $MarginContainer/HBoxContainer/VBoxContainer/AlongEven

onready var _randomize_all = $MarginContainer/HBoxContainer/VBoxContainer2/RandomizeAll
onready var _scale_noise = $MarginContainer/HBoxContainer/VBoxContainer2/ScaleNoise
onready var _project = $MarginContainer/HBoxContainer/VBoxContainer2/Project
onready var _offset = $MarginContainer/HBoxContainer/VBoxContainer2/ApplyOffset

onready var _exclude_from_path = $MarginContainer/HBoxContainer/VBoxContainer3/ExcludeFromPath
onready var _exclude_along_path = $MarginContainer/HBoxContainer/VBoxContainer3/ExcludeAlongPath
onready var _exclude_around_point = $MarginContainer/HBoxContainer/VBoxContainer3/ExcludeAroundPoint

onready var _root = _get_root_folder() + "/src/modifiers/"


func _ready():
	_connect(_inside_random, "distribute_inside_random.gd")
	_connect(_inside_grid, "distribute_inside_grid.gd")
	_connect(_along_random, "distribute_along_random.gd")
	_connect(_along_even, "distribute_along_even.gd")
	_connect(_randomize_all, "randomize_transforms.gd")
	_connect(_scale_noise, "randomize_scale_noise.gd")
	_connect(_project, "project_on_floor.gd")
	_connect(_offset, "apply_offset.gd")
	_connect(_exclude_from_path, "exclude_from_path.gd")
	_connect(_exclude_along_path, "exclude_along_path.gd")
	_connect(_exclude_around_point, "exclude_around_point.gd")


func _connect(button, script_path) -> void:
	button.connect("pressed", self, "_on_pressed", [load(_root + script_path)])


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]


func _on_pressed(modifier) -> void:
	emit_signal("add_modifier", modifier.new())
	visible = false
