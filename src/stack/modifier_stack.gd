@tool
extends Resource


@export var stack: Array[Resource] = []

var owner: Node
var just_created := false
var undo_redo: UndoRedo


func update(transforms, random_seed) -> void:
	for modifier in stack:
		if modifier.enabled:
			modifier.process_transforms(transforms, random_seed)

