# --
# Scatter Profile
# --
# Abstract class to define small blocs that can be reused accross multiple
# positioning resources.
# --

tool

extends Resource

class_name ScatterProfile

## --
## Signals
## --

signal parameter_updated

## --
## Exported variables
## --

## --
## Public variables
## --

## --
## Internal variables
## --

## --
## Getters and Setters
## --

## --
## Public methods
## --

func reset() -> void:
	pass

func set_parameter(variant1, variant2) -> void:
	pass

func get_result(variant):
	return null

## --
## Protected methods
## --

func notify_parameter_update() -> void:
	emit_signal("parameter_updated")

## --
## Internal methods
## --


## --
## Callbacks
## --
