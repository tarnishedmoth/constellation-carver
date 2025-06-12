class_name ParticleParser extends Node

const HEADER:Dictionary = {
	"format": "particle",
	"title": "My Site",
	"content": []
}

var file_saves_directory:String = "user://projects"
var file_assets_directory:String = "user://assets"

func _ready() -> void:
	pass
	
static func load_json_from_file(filepath:String) -> Dictionary:
	if FileAccess.file_exists(filepath):
		var file:FileAccess = FileAccess.open(filepath, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			return parsed
		else:
			push_error("JSON file is corrupt!")
	# No file or corrupt
	return {}

## Returns true for successful save, false otherwise.
static func save_json_to_file(formatted_data:String, filepath:String) -> bool:
	var dirpath = filepath.get_base_dir()
	if not dirpath.is_empty():
		if DirAccess.open(dirpath) == null:
			DirAccess.make_dir_recursive_absolute(dirpath)
			print_debug("Made a new directory!")
		var file = FileAccess.open(filepath, FileAccess.WRITE)
		file.store_string(formatted_data)
		file.close()
		print("Saved")
		return true
	return false
	
func read_style(style:Dictionary) -> Style:
	var parsed = Style.new()
	if "text-align" in style:
		parsed.text_align = style["text-align"]
	if "margin-top" in style:
		parsed.margin_top = style["margin-top"]
	if "margin-bottom" in style:
		parsed.margin_bottom = style["margin-bottom"]
	if "scale" in style:
		parsed.scale = style["scale"]
	return parsed
	
static func pagify(content:Dictionary) -> String:
	var new_dict:Dictionary = HEADER.duplicate()
	new_dict["content"] = content
	return stringify(new_dict)
	
static func stringify(data:Dictionary) -> String:
	return JSON.stringify(data, "\t", false, true)
