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

export(Resource) var positioning_logic setget set_positioning_logic

## --
## Internal variables
## --

var _items : Array = Array()
var _exclusion_areas : Array = Array()
var _total_proportion : int

## --
## Getters and Setters
## --

func get_exclusion_areas () -> Array:
	return _exclusion_areas

func set_positioning_logic (val : Resource) -> void:
	if val is BasePositioning:
		positioning_logic = val
		positioning_logic.connect("parameter_updated", self, "update")
		update()

## --
## Public methods
## --

func update() -> void:
	if not _is_ready():
		return
	positioning_logic.init(self)
	_discover_items_info()
	_scatter_instances()

## --
## Internal methods
## --

func _ready() -> void:
	if not positioning_logic:
		positioning_logic = GenericPositioning.new()
	if not self.is_connected("curve_updated", self, "_on_curve_update"):
		self.connect("curve_updated", self, "_on_curve_update")
	update()

func _on_curve_update() -> void:
	update()

func _scatter_instances() -> void:
	var count = 0
	for i in _items:
		i.translation = Vector3.ZERO
		count = int(float(i.proportion) / _total_proportion * positioning_logic.amount)
		_scatter_instances_from_item(i, count)

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

# Avoid some errors during tool developpement
func _is_ready():
	set_process(true)
	return get_tree() and positioning_logic

func _process(_delta) -> void:
	pass
