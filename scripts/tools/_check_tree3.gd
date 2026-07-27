extends SceneTree

func _init():
	var tree = load("res://yggdrasil_data/trees/main_tree.tres")
	print("Nodes: ", tree.nodes.size())
	print("Tree size: ", tree.size)
	
	# Find min/max positions
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for n in tree.nodes:
		var p = n.position
		min_pos = Vector2(min(min_pos.x, p.x), min(min_pos.y, p.y))
		max_pos = Vector2(max(max_pos.x, p.x), max(max_pos.y, p.y))
	print("Content: ", min_pos, " to ", max_pos)
	
	# Count root nodes
	var roots = 0
	for n in tree.nodes:
		if n.is_root: roots += 1
	print("Root nodes: ", roots)
	
	# Check a location - root node
	for n in tree.nodes:
		if n.is_root:
			print("Root node: id=", n.id, " name=", n.name, " pos=", n.position, " type=", str(n.type))
			if n.out_nodes.size() > 0:
				print("  Out nodes: ", n.out_nodes)
				for out_id in n.out_nodes:
					var found = false
					for n2 in tree.nodes:
						if n2.id == out_id:
							print("  -> Node ", out_id, " at ", n2.position)
							found = true
							break
					if not found:
						print("  -> Node ", out_id, " NOT FOUND in tree!")
			break
	quit()