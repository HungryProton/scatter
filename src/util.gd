extends Node


static func get_node_by_class_path(node: Node, class_path: Array) -> Node:
	var res: Node

	var stack := []
	var depths := []

	var first = class_path[0]
	for c in node.get_children():
		if c.get_class() == first:
			stack.push_back(c)
			depths.push_back(0)

	if not stack: return res

	var max_ = class_path.size()-1

	while stack:
		var d = depths.pop_front()
		var n = stack.pop_front()

		if d > max_:
			continue
		if n.get_class() == class_path[d]:
			if d == max_:
				res = n
				return res
			for c in n.get_children():
				stack.push_back(c)
				depths.push_back(d+1)

	return res
