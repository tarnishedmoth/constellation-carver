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
		var jason = JSON.new()
		var err:int = jason.parse(file.get_as_text(), true)

		if err != OK:
			push_warning("Issue parsing JSON file.")
			U.l("JSON file is corrupt at line %s!\n--%s" % [jason.get_error_line(), filepath])
			return {}

		var parsed = JSON.parse_string(jason.get_parsed_text())
		file.close()

		if parsed is Dictionary:
			return parsed
		else:
			push_error("JSON file is corrupt!")
			U.l("JSON file is corrupt at line %s!\n--%s" % [jason.get_error_line(), filepath])
	# No file or corrupt
	return {}

## Returns true for successful save, false otherwise.
static func save_json_to_file(formatted_data:String, filepath:String) -> bool:
	var dirpath:String = filepath.get_base_dir()
	if not dirpath.is_empty():
		if not DirAccess.dir_exists_absolute(dirpath):
			var err:int = DirAccess.make_dir_recursive_absolute(dirpath)

			if err != OK:
				print_debug(DirAccess.get_open_error())
				return false
			U.l("Made a new directory!\n%s" % [dirpath])

		var file = FileAccess.open(filepath, FileAccess.WRITE)
		if file == null:
			var err = FileAccess.get_open_error()
			U.l("Error accessing file to save JSON data:\n--%s" % [error_string(err)])
			return false
		file.store_string(formatted_data)
		file.close()
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

static func pagify(content:Array) -> String:
	var new_dict:Dictionary = HEADER.duplicate(true)
	new_dict["content"] = content.duplicate(true)
	return stringify(new_dict)

static func stringify(data:Dictionary) -> String:
	return JSON.stringify(data, "\t", false, true)


static func find_json_files_in(directory:String) -> Array[String]:
	if directory.is_absolute_path():
		if DirAccess.dir_exists_absolute(directory):
			var _filepaths:Array[String] = []
			var diraccess = DirAccess.open(directory)

			var total_directories:int = 1
			for file in diraccess.get_files():
				if file.get_extension() == "json":
					_filepaths.append(directory.path_join(file))

			for subfolder in diraccess.get_directories():
				total_directories += 1
				var subfolder_files:Array = find_json_files_in(directory.path_join(subfolder))
				_filepaths.append_array(subfolder_files)

			U.l("Found %s JSON files recursively in %s directories from %s." % [_filepaths.size(), total_directories, directory])
			return _filepaths
	push_error("Bad directory given to find_json_files_in")
	return []

static func is_valid_page(page:Dictionary) -> bool:
	if page.is_empty(): return false
	if not "format" in page: return false
	if not page["format"] == "particle": return false
	if not "title" in page: return false
	if not "content" in page: return false
	return true

static func is_valid_webpath(path:String) -> bool:
	return true

static func grab_json_from_clipboard() -> Dictionary:
	var clipboard_data:String = DisplayServer.clipboard_get()
	if not clipboard_data.is_empty():
		var parse_result:Dictionary = JSON.parse_string(clipboard_data)
		if not parse_result == null:
			return parse_result
	return {}
