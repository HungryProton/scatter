extends Node

static func get_node_by_class_path(node: Node, class_path: Array) -> Node:
	var res: Node

	var stack := []
	var depths := []
	
	#find the SpatialEditor root node
	var first = class_path[0]
	for c in node.get_children():
		if c.get_class() == first:
			stack.push_back(c)
			depths.push_back(0)
	
	#SpatialEditor not found
	if not stack: return res
	
	#maximum navigable depth
	var max_ = class_path.size()-1
	
	while stack:
		#remove first entry from array
		var d = depths.pop_front()
		var n = stack.pop_front()
		
		#if past maximum navigable depth
		if d > max_:
			continue
		
		#selects only the next node in the list
		if n.get_class() == class_path[d]:
			#if final node in the list
			if d == max_:
				res = n
				return res
			#add new children to stack
			for c in n.get_children():
				stack.push_back(c)
				depths.push_back(d+1)
	
	return res
