extends YggdrasilNodeButton
class_name PoENodeButton

func _ready():
	super._ready()
	custom_minimum_size = Vector2(28, 28)

func format_tooltip() -> String:
	var str := ""
	var type_icon := ""
	match type:
		YggdrasilNode.NodeType.LARGE:
			type_icon = "[color=#e6b800]>[/color] "
		YggdrasilNode.NodeType.MEDIUM:
			type_icon = "[color=#8ab8ff]-[/color] "
		YggdrasilNode.NodeType.SMALL:
			type_icon = "[color=#6a6a7a]o[/color] "
	var name_color := "#f9e6ca"
	var type_tag := ""
	if type == YggdrasilNode.NodeType.LARGE:
		name_color = "#e6b800"
		type_tag = " [color=#e6b800](Keystone)[/color]"
	elif type == YggdrasilNode.NodeType.MEDIUM:
		type_tag = " [color=#8ab8ff](Notable)[/color]"
	str = "[b][color=%s]%s%s[/color][/b]%s" % [name_color, type_icon, node_name, type_tag]
	if not description.is_empty():
		str += "\n[color=#444455]----------------[/color]"
		var lines := description.split("|")
		for line in lines:
			var t := line.strip_edges()
			if t.is_empty(): continue
			str += "\n  " + t
	str += "\n[color=#444455]----------------[/color]"
	if allocated:
		str += "\n[color=#55cc55][b]v AKTIF[/b][/color]"
	elif preallocated:
		str += "\n[color=#e6b800][b]o BEKLIYOR[/b][/color]"
	elif is_root:
		str += "\n[color=#888888]Baslangic Noktasi[/color]"
	else:
		str += "\n[color=#888888][b]Kilitli[/b] - Acmak icin tikla[/color]"
	return str.strip_edges()
