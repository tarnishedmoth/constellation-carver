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
		if current_page_name.is_empty():
			return page_select.get_item_text(page_select.get_selected_id())
		else:
			return current_page_name
var current_page_filepath: String:
	get:
		return String(
			current_project_filepath +
			"/" + current_page_name + ".json"
			)
var project_contents: Dictionary = {}
var page_contents: Dictionary = {}

@onready var pd_display: Control = %PDDisplay
@onready var page_select: OptionButton = %PageSelect

@onready var project = ConstellationProject.new()
		
func load_page(filepath) -> void:
	page_contents = Particles.load_json_from_file(filepath)
	if page_contents.is_empty():
		print("Loaded page is empty!")
	else:
		print(page_contents)

func save_page(filepath) -> void:
	var formatted = Particles.stringify(page_contents)
	var result = Particles.save_json_to_file(formatted, filepath)
	
func new_page() -> void:
	project.new_page("test", "")

func _on_load_project_pressed() -> void: load_page(current_page_filepath)
func _on_save_project_pressed() -> void: save_page(current_page_filepath)

func _on_page_select_item_selected(index: int) -> void:
	# Load a new page
	current_page_name = page_select.get_item_text(index)
	load_page(current_page_filepath)

func _on_new_project_pressed() -> void: pass
func _on_new_page_pressed() -> void: new_page()
