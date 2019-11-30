# --
# Scatter Base
# --
# The common variables shared by ScatterMultimesh and ScatterDuplicate
# are defined here.
# --

tool

extends PolygonPath

class_name ScatterBase

## --
## Signals
## --

signal parameter_updated

## --
## Exported variables
## --

export(bool) var copy_parent_curve = false setget set_copy_parent_curve
export(bool) var continuous_update = false
export(Resource) var scatter_logic setget set_scatter_logic

## --
## Internal variables
## --

var _items : Array = Array()
var _exclusion_areas : Array = Array()
var _total_proportion : int = 0
var _offset : int = 0

## --
## Getters and Setters
## --

func get_exclusion_areas () -> Array:
	return _exclusion_areas

func set_copy_parent_curve(val: bool) -> void:
	var parent = get_parent()
	if not val or not parent is PolygonPath:
		copy_parent_curve = false
		update()
		return
	copy_parent_curve = true
	_align_scatter_node_with_parent()
	ScatterCommon.safe_connect(parent, "curve_updated", self, "update")
	update()

func set_scatter_logic (val : Resource) -> void:
	if val is ScatterLogic:
		scatter_logic = val
		ScatterCommon.safe_connect(scatter_logic, "parameter_updated", self, "update")
		update()

## --
## Public methods
## --

func update() -> void:
	if not _is_ready():
		return
	_discover_items_info()
	_scatter_instances()

## --
## Internal methods
## --

func _ready() -> void:
	if not scatter_logic:
		scatter_logic = ScatterLogicGeneric.new()
	ScatterCommon.safe_connect(self, "curve_updated", self, "_on_curve_update")
	update()

func _on_curve_update() -> void:
	update()

func _align_scatter_node_with_parent() -> void:
	var origin = Vector3.ZERO
	origin.y = transform.origin.y
	transform.origin = origin
	rotation = Vector3.ZERO

func _scatter_instances() -> void:
	_init_scatter_logic()
	_offset = 0
	var count = 0
	for i in range(_items.size()):
		var item = _items[i]
		item.translation = Vector3.ZERO
		scatter_logic.scatter_pre_hook(item)
		if i == _items.size() - 1:
			count = scatter_logic.amount - _offset
		else:
			count = int(round(float(item.proportion) / _total_proportion * scatter_logic.amount))
		_scatter_instances_from_item(item, count)
		scatter_logic.scatter_post_hook(item)
		_offset += count

func _scatter_instances_from_item(_scatter_item, _instances_count) -> void:
	pass

# Loop through children to find all the ScatterItem and ScatterExclude nodes within
func _discover_items_info() -> void:
	_items.clear()
	_exclusion_areas.clear()
	_total_proportion = 0

	for c in get_children():
		if c.get_class() == "ScatterItem":
			_items.append(c)
			_total_proportion += c.proportion
		elif c.get_class() == "ScatterExclude":
			_exclusion_areas.append(c)

func _init_scatter_logic() -> void:
	if copy_parent_curve:
		scatter_logic.init(get_parent())
	else:
		scatter_logic.init(self)
	scatter_logic.scatter_items_count = _items.size()

# Avoid some errors during tool developpement
func _is_ready():
	var c = curve
	if copy_parent_curve:
		c = get_parent().curve
	if not c:
		return false
	if c.get_point_count() < 2:
		return false
	if not scatter_logic:
		return false
	set_process(true)
	return get_tree()

func _process(_delta) -> void:
	if continuous_update:
		update()
