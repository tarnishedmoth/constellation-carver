class_name Utils extends Node

var log_console:RichTextLabel

const TRANSPARENT:Color = Color(Color.WHITE, 0.0)

func l(item) -> void:
	print(item)
	if log_console:
		log_console.newline()
		if item is String:
			log_console.append_text(str(item))
		elif item is Dictionary:
			var s:String = ""
			for key in item:
				s += str(key)
				s += ": "
				s += item[key]
				s += "\n"
				log_console.append_text(s)
				log_console.newline()
		elif item is Array:
			for subitem in item:
				var s:String = ""
				s += str(subitem)
				log_console.append_text(s)
				log_console.newline()

func bold(text:String) -> String: return "[b]" + text + "[/b]"
func ital(text:String) -> String: return "[i]" + text + "[/i]"
func center(text:String) -> String: return "[center]" + text + "[/center]"
func underl(text:String) -> String: return "[u]" + text + "[/u]"

func endify(path:String, end_with:String = "/") -> String:
	if path.ends_with(end_with): return path
	else: return (path + end_with)

func cat(strings:Array[String], knot:String = "/", tail:String = "", check_knots:bool = true) -> String:
	var yarn:String = ""
	var i:int = 0
	var max_index:int = strings.size() - 1
	for strand in strings:
		if i == max_index and not tail.is_empty():
			strand = U.endify(strand, tail)
		elif i < max_index:
			if check_knots:
				strand = U.endify(strand, knot)
			elif i > 0:
				yarn += knot
		yarn += strand
		i+=1
	return yarn

func is_relative_path(path:String) -> bool:
	if path.trim_prefix("/").is_relative_path(): return true
	else: return false
