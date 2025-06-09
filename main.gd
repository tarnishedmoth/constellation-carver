extends Control

var current_project_name: String = "Project1"
var current_project_filepath: String:
	get:
		return String(
			Particles.file_saves_directory +
			"/" + current_project_name
			)
var current_page_name: String:
	get:
		if "title" in current_page:
			return current_page["title"]
		else:
			return "Empty"
var current_page_filepath: String
			
var pages: Array = []
var current_page: Dictionary = {}

@onready var pd_display: Control = %PDDisplay
@onready var page_line_edit: LineEdit = %PageLineEdit
@onready var page_select: OptionButton = %PageSelect


func load_page(filepath) -> void:
	var _filepath:String = current_project_filepath + "/" + filepath
	var payload = Particles.load_json_from_file(_filepath)
	
	if payload.is_empty():
		l("Loaded page is empty!")
	elif not "format" in payload:
		l("Loaded page has bad format!")
	elif payload["format"] != "particle":
		l("Loaded page has bad format!")
	else:
		current_page = payload
		for obj in current_page["content"]:
			render_content(obj)
				
func render_content(obj:Dictionary) -> void:
	match obj["type"]:
		"paragraph":
			l("Found a paragraph!")
			l(obj["text"])
			
		"list":
			l("Found a list!")
			l(obj["items"])
			
		"blockquote":
			l("Found a blockquote!")
			l(obj["text"])
			
		"button":
			l("Found a button!")
			l(obj["label"])
			
		"separator":
			l("Found a separator!")
			
		"image":
			l("Found an image!")
		
		_:
			push_error("Found an anomoly! Dafuq?")

func save_page(filepath) -> void:
	var formatted = Particles.stringify(current_page)
	var result = Particles.save_json_to_file(formatted, filepath)
	
func new_page() -> void:
	pass
	
func l(text) -> void: print(text)
func _on_load_project_pressed() -> void: load_page(current_page_filepath)
func _on_save_project_pressed() -> void: save_page(current_page_filepath)

func _on_page_select_item_selected(index: int) -> void:
	pass

func _on_new_project_pressed() -> void: pass
func _on_new_page_pressed() -> void: new_page()

func _on_load_page_pressed() -> void:
	load_page(page_line_edit.text)
