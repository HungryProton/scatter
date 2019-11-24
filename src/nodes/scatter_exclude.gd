tool
extends PolygonPath

# --
# ScatterExclude
# --
# Defines an area where items can't be spawned.
# Add it as a direct child of a ScatterDuplicate or ScatterMultimesh to
# affect all the items.
# Add it as a direct child of a ScatterItem to affect this item only.
# --
#
# --

class_name ScatterExclude

## --
## Public methods
## --

func get_class():
	return "ScatterExclude"

## --
## Internal methods
## --

func _ready():
	connect("curve_updated", self, "_update")

func _update():
	var _parent = get_parent()
	if _parent:
		_parent.update()
