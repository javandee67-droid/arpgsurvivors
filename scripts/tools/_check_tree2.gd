extends SceneTree

func _init():
	var tree = load("res://yggdrasil_data/trees/main_tree.tres")
	print("Nodes count: ", tree.nodes.size())
	var conn_count := 0
	for n in tree.nodes:
		if n.out_nodes != null:
			conn_count += n.out_nodes.size()
	print("Total out_nodes references: ", conn_count)
	print("Total connections (bidirectional / 2 approx): ", conn_count / 2 if conn_count > 1 else 0)
	# Sample a few nodes with connections
	var found = 0
	for n in tree.nodes:
		if n.out_nodes != null and n.out_nodes.size() > 0:
			print("Node %d: type=%s out_nodes=%s name=%s" % [n.id, str(n.type), str(n.out_nodes), n.name])
			found += 1
			if found >= 5: break
	quit()