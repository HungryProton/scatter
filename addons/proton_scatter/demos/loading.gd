extends Control

# Hides the loading screen when the scatter nodes are ready.
#
# Every Scatter nodes emit a signal called "build_completed" when they are done
# generating their multimeshes.

# In this example, the Grass is usually the last one to complete, so its
# 'build_completed' signal is connected to this method.
func _on_scatter_build_completed() -> void:
	visible = false
