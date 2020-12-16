tool
extends Node


var list := []
var size: Vector3
var path: Path


func set_count(count: int) -> void:
	for i in count:
		var t := Transform()
		list.push_back(t)
