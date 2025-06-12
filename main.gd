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

@onready var log_console: RichTextLabel = %LogConsole:
	set(value):
		log_console = value
		Utils.log_console = log_console
@onready var pd_display: Control = %PDDisplay
@onready var page_line_edit: LineEdit = %PageLineEdit
@onready var page_select: OptionButton = %PageSelect
@onready var new_object_menu: MenuButton = %NewObjectMenu

func _ready() -> void: Utils.log_console = log_console

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
		l("Loading page...")
		current_page_json = payload
		l("Page name: [b]"+current_page_json["title"]+"[/b]")
		for obj in current_page_json["content"]:
			render_content(obj)
				
func render_content(obj:Dictionary) -> void:
	var instance:Control
	match obj["type"]:
		"paragraph":
			l("[b]New paragraph![/b]")
			var len:int = obj["text"].length()
			l(str(len) + " characters inside.")
			instance = ConstellationParagraph.new(obj["text"])
			
		"list":
			l("[b]New list![/b]")
			var count:int = obj["items"].size()
			l(str(count) + " items listed.")
			
		"blockquote":
			l("[b]New blockquote![/b]")
			var len:int = obj["text"].length()
			l(str(len) + " characters inside.")
			
		"button":
			l("[b]New button![/b]")
			l("Label reads " + obj["label"])
			
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
	
func l(item) -> void: Utils.l(item)

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
