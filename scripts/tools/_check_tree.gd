extends SceneTree

func _init():
	var tree = load("res://yggdrasil_data/trees/main_tree.tres")
	print("Tree loaded: ", tree)
	print("Nodes count: ", tree.nodes.size())
	var conn_count := 0
	for n in tree.nodes:
		if n.out_nodes != null:
			conn_count += n.out_nodes.size()
	print("Total out_nodes references: ", conn_count)
	print("First 3 nodes:")
	for i in range(min(3, tree.nodes.size())):
		var n = tree.nodes[i]
		print("  Node %d: type=%s out_nodes=%s in_nodes=%s" % [i, str(n.type), str(n.out_nodes), str(n.in_nodes)])
	quit()
