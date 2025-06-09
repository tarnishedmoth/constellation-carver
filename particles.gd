class_name ParticleParser extends Node

var file_saves_directory:String = "user://projects"
var file_assets_directory:String = "user://assets"

func _ready() -> void:
	pass
	
static func load_json_from_file(filepath:String) -> Dictionary:
	if FileAccess.file_exists(filepath):
		var load = FileAccess.open(filepath, FileAccess.READ)
		var parsed = JSON.parse_string(load.get_as_text())
		load.close()
		if parsed is Dictionary:
			return parsed
		else:
			push_error("JSON file is corrupt!")
	# No file or corrupt
	return {}

## Returns true for successful save, false otherwise.
static func save_json_to_file(formatted_data:String, filepath:String) -> bool:
	var dirpath = filepath.get_base_dir()
	if DirAccess.open(dirpath) == null:
		DirAccess.make_dir_recursive_absolute(dirpath)
		print_debug("Made a new directory!")
	var file = FileAccess.open(filepath, FileAccess.WRITE) ## Doing this so I don't accidentally erase files
	file.store_string(formatted_data)
	file.close()
	print("Saved")
	return true
	
static func stringify(data:Dictionary) -> String:
	return JSON.stringify(data, "\t", false)
