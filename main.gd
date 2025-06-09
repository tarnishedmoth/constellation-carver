extends Control

@onready var pd_display: Control = %PDDisplay
@onready var page_select: OptionButton = %PageSelect


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


func load_page(new_content) -> void:
	page_contents = new_content
	if page_contents.is_empty():
		print("An empty page appears!")
	else:
		print(page_contents)


func _on_load_project_pressed() -> void:
	project_contents = Particles.load_json_from_file(current_page_filepath)
	if project_contents.is_empty():
		print("Loaded project is empty!")
	else:
		print(project_contents)


func _on_save_project_pressed() -> void:
	project_contents = page_contents
	var formatted = Particles.stringify(project_contents)
	var result = Particles.save_json_to_file(formatted, current_page_filepath)


func _on_page_select_item_selected(index: int) -> void:
	# Load a new page
	current_page_name = page_select.get_item_text(index)
	load_page(Particles.load_json_from_file(current_page_filepath))
