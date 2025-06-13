extends Node

var log_console:RichTextLabel

func l(item) -> void:
	print(item)
	if log_console:
		log_console.newline()
		if item is String:
			log_console.append_text(item)
		elif item is Dictionary:
			var s:String = ""
			for key in item:
				s += key as String
				s += ": "
				s += item[key]
				s += "\n"
				log_console.append_text(s)
				log_console.newline()
		elif item is Array:
			for subitem in item:
				var s:String = ""
				s += subitem as String
				log_console.append_text(s)
				log_console.newline()

static func bold(text:String) -> String: return "[b]" + text + "[/b]"
static func ital(text:String) -> String: return "[i]" + text + "[/i]"
static func center(text:String) -> String: return "[center]" + text + "[/center]"
static func underl(text:String) -> String: return "[u]" + text + "[/u]"

static func endify(path:String, end_with:String = "/") -> String:
	if path.ends_with(end_with): return path
	else: return (path + end_with)
