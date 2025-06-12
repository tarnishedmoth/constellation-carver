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
		if "title" in current_page_json:
			return current_page_json["title"]
		else:
			return "Empty"
var current_page_filepath: String
			
var pages: Array = []
var current_page_json: Dictionary = {}

@onready var log_console: RichTextLabel = %LogConsole
@onready var pd_display: Control = %PDDisplay
@onready var page_line_edit: LineEdit = %PageLineEdit
@onready var page_select: OptionButton = %PageSelect


func load_page(filepath) -> void:
	var _filepath:String = current_project_filepath + "/" + filepath
	current_page_filepath = _filepath
	var payload = Particles.load_json_from_file(_filepath)
	
	if payload.is_empty():
		l("Loaded page is empty!")
	elif not "format" in payload:
		l("Loaded page has bad format!")
	elif payload["format"] != "particle":
		l("Loaded page has bad format!")
	else:
		current_page_json = payload
		for obj in current_page_json["content"]:
			render_content(obj)
				
func render_content(obj:Dictionary) -> void:
	var instance:Control
	match obj["type"]:
		"paragraph":
			l("[b]New paragraph![/b]")
			l(obj["text"])
			instance = ConstellationParagraph.new(obj["text"])
			
		"list":
			l("[b]New list![/b]")
			l(obj["items"])
			
		"blockquote":
			l("[b]New blockquote![/b]")
			l(obj["text"])
			
		"button":
			l("[b]New button![/b]")
			l(obj["label"])
			
		"separator":
			l("[b]New separator![/b]")
			
		"image":
			l("[b]New image![/b]")
			instance = ConstellationImage.new()
		_:
			push_error("[b]Found an anomoly! Dafuq?[/b]")
	if instance == null: return
	pd_display.add_child(instance)
		
	if "style" in obj:
		if "style" in instance:
			instance.style = Particles.read_style(obj["style"])

func save_page(filepath) -> void:
	var formatted = Particles.stringify(current_page_json)
	var result = Particles.save_json_to_file(formatted, filepath)
	
func new_page() -> void:
	pass
	
func l(item) -> void:
	print(item)
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
			
	log_console.newline()
		
func _on_load_project_pressed() -> void: load_page(current_page_filepath)
func _on_save_project_pressed() -> void: save_page(current_page_filepath) ## TODO

func _on_page_select_item_selected(index: int) -> void:
	## TODO
	pass

func _on_new_project_pressed() -> void: pass ## TODO
func _on_new_page_pressed() -> void: new_page()

func _on_load_page_pressed() -> void:
	load_page(page_line_edit.text)


func _on_save_page_pressed() -> void: save_page(current_page_filepath)
