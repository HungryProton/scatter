@tool
extends Control

# Hides the loading screen when the scatter nodes are ready.
#
# Every Scatter nodes emit a signal called "build_completed" when they are done
# generating their multimeshes.

var _scatter_completed := false


func _ready() -> void:
	# Show the loading screen, unless scatter is already done.
	visible = not _scatter_completed


# In this example, the Grass is usually the last one to complete, so its
# 'build_completed' signal is connected to this method.
# You could also listen to multiple Scatter nodes and accumulate all the signals
# to be extra safe. How you handle this is up to you.
func _on_scatter_build_completed() -> void:
	visible = false
	_scatter_completed = true
