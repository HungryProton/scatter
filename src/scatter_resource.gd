# --
# ScatterResource
# --
# Default resource type for the Scatter addon
# --

extends Resource

class_name ScatterResource

## --
## Signals
## --

signal parameter_updated

## --
## Protected methods
## --

func notify_update() -> void:
	emit_signal("parameter_updated")
