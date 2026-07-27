extends SceneTree

func _init():
	var file = FileAccess.open("res://data/passive_skill_tree.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.data
	var raw_nodes = data.get("nodes", [])
	print("Total nodes in JSON: ", raw_nodes.size())
	# Find a notable node
	for n in raw_nodes:
		if n is Dictionary and n.get("size") in ["notable", "keystone"]:
			print("Sample notable node:")
			var k = n.keys()
			k.sort()
			print("  Keys: ", k)
			print("  out=", n.get("out", "MISSING"))
			print("  connects=", n.get("connects", "MISSING"))
			print("  id=", n.get("id", "MISSING"))
			var out_field = n.get("out", null)
			if out_field is Array:
				print("  out is Array, size=", out_field.size(), " sample=", out_field[0] if out_field.size() > 0 else "empty")
			break
	# Find a small node
	for n in raw_nodes:
		if n is Dictionary and n.get("size") == "small":
			print("Sample small node:")
			var k = n.keys()
			k.sort()
			print("  Keys: ", k)
			var out_field = n.get("out", null)
			if out_field is Array:
				print("  out is Array, size=", out_field.size(), " sample=", out_field[0] if out_field.size() > 0 else "empty")
			print("  connects=", n.get("connects", "MISSING"))
			break
	quit()
