class_name MainScreen extends Control

const APP_NAME:String = "Constellation Carver v0.1"

const PAGE_TEMPLATE:Array = [
	ConstellationParagraph.TEMPLATE
]

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
var pages: Dictionary = {} # Key is filepath, value is json dictionary
var current_page_json: Dictionary = {}
var current_page_content: Array = []

var selected_editable:Control

@onready var special_popup_window: SpecialPopupWindow = $SpecialPopupWindow
@onready var log_console: RichTextLabel = %LogConsole:
	set(value):
		log_console = value
		Utils.log_console = log_console
@onready var pd_display: Control = %PDDisplay
# PAGE
@onready var page_line_edit: LineEdit = %PageLineEdit
@onready var page_select: OptionButton = %PageSelect
# OBJECT
@onready var new_object_menu: MenuButton = %NewObjectMenu
@onready var selected_object_type: Label = %ObjectType
@onready var object_tree: Tree = %ObjectTree
# CONTENT
@onready var content_text_edit: TextEdit = %ContentTextEdit
@onready var content_line_edit: LineEdit = %ContentLineEdit
@onready var content_tree: Tree = %ContentTree
@onready var content_empty_label: Label = %ContentEmptyLabel
# JSON
@onready var json_edit: CodeEdit = %JSONEdit
var json_edit_is_word_wrap:bool = false

func _ready() -> void:
	%ApplicationName.text = APP_NAME
	# Menu initial states
	%TopTabContainer.current_tab = 1 # Page tab
	%BottomTabContainer.current_tab = 2 # JSON tab
	
	Utils.log_console = log_console
	
	var context_menu:PopupMenu = json_edit.get_menu()
	var id:int = context_menu.item_count + 1
	context_menu.add_check_item("Word Wrap", id)
	context_menu.id_pressed.connect(_on_json_edit_context_menu_pressed.bind(id))
	
	l("Application initialized.")

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
		pages[current_page_filepath] = current_page_json
		render_current_page_content()
				
func render_current_page_content() -> void:
	object_tree.clear()
	reset_editables()
	
	for child in pd_display.get_children():
		child.queue_free()
	
	current_page_content.clear()
	
	l("Rendering page: [b]"+current_page_json["title"]+"[/b]")
	%PageTitleEdit.text = current_page_json["title"]
	
	var tree_root = object_tree.create_item()
	tree_root.set_text(0, current_page_json["title"])
	for obj in current_page_json["content"]:
		var instance = _render_content(obj)
		current_page_content.append(instance)
		var tree_item = object_tree.create_item(tree_root)
		tree_item.set_text(0, obj["type"])

func _render_content(obj:Dictionary) -> Control:
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
			instance = ConstellationList.new(obj["items"])
			
		"blockquote":
			l("[b]New blockquote![/b]")
			var len:int = obj["text"].length()
			l(str(len) + " characters inside.")
			instance = ConstellationBlockquote.new(obj["text"])
			
		"button":
			l("[b]New button![/b]")
			l("Label reads " + obj["label"])
			instance = ConstellationButton.new(obj["label"], obj["action"])
			if "prelabel" in obj: instance._prelabel = obj["prelabel"]
			
		"separator":
			l("[b]New separator![/b]")
			instance = ConstellationSeparator.new()
			
		"image":
			l("[b]New image![/b]")
			instance = ConstellationImage.new(
				obj["width"],
				obj["height"],
				obj["pixels"]
			)
		
		"reel":
			l("[b]New reel![/b]")
			instance = ConstellationReel.new(
				obj["width"],
				obj["height"],
				obj["frames"]
			)
			if "frame-duration" in obj:
				instance._frame_duration = obj["frame-duration"]
				
		_:
			push_error("[b]Found an anomoly! Dafuq?[/b]")
	if not is_instance_valid(instance): return null
	
	instance.focus_entered.connect(open_edit_content.bind(instance))
	
	pd_display.add_child(instance)
		
	if "style" in obj:
		if "style" in instance:
			instance.style = Particles.read_style(obj["style"])
	return instance
	
func reset_editables() -> void:
	if selected_editable: l("Deselected.")
	selected_editable = null
	
	selected_object_type.text = "No object selected."
	content_empty_label.show()
	
	content_line_edit.hide()
	content_line_edit.clear()
	
	content_text_edit.hide()
	content_text_edit.clear()
	
	content_tree.hide()
	content_tree.clear()

func save_page(filepath) -> void:
	cache_changes()
	l("Saving page...")
	var formatted = Particles.stringify(current_page_json)
	var result = Particles.save_json_to_file(formatted, filepath)
	
	if result == true:
		l("Save success!")
		%ApplicationName.text = APP_NAME
	else:
		l(Utils.bold("Save failed!"))
	
func cache_changes(refresh:bool = false):
	var index:int = 0
	for item:Control in current_page_content:
		if not item == null:
			if item.has_method("to_dict"):
				current_page_json.content[index] = item.to_dict()
		index += 1
	
	l("Cached %s items." % [index])
	
	%ApplicationName.text = APP_NAME + " - unsaved changes"
	
	if refresh: render_current_page_content()
	
func new_page(title:String, dirpath:String, overwrite:bool = false) -> void:
	var new_page_json:String = ParticleParser.pagify(PAGE_TEMPLATE)
	var filepath = Utils.endify(dirpath) + Utils.endify(title, ".json")
	var file_exists:bool = FileAccess.file_exists(filepath)
	if not overwrite:
		if file_exists:
			# Warn the user
			var result = await special_popup_window.popup(
				"File already exists.\nErase and overwrite?\n\n(You will permanently lose this data!)",
				"New Page - Warning",
				true
			)
			if not result: # Cancel
				return
	
	ParticleParser.save_json_to_file(new_page_json, filepath)
	l(Utils.bold("New page created and saved!"))
	await  get_tree().process_frame
	load_page(filepath)
	
func add_content(content:Dictionary, index:int = -1) -> void:
	if not current_page_json:
		Utils.l(Utils.ital("--Can't make a new object without a page selected!"))
		return
		
	cache_changes()
	
	var arr:Array = current_page_json["content"]
	if index >= 0:
		arr.insert(index, content)
	else:
		index = arr.size()
		arr.append(content)
	Utils.l(Utils.ital("Object inserted at index " + str(index) + ", refreshing..."))
	
	render_current_page_content()

func remove_content_at(index:int) -> void:
	pass
	
func open_edit_content(instance:Control) -> void:
	reset_editables()
	# Show Objects tab
	%TopTabContainer.current_tab = 2
	
	selected_editable = instance
	json_edit.text = str(selected_editable) # Uses _to_string() of instance
	if "_type" in selected_editable:
		var index = current_page_content.find(selected_editable)
		l("Selected %s to edit at index %s" % [selected_editable._type, index])
		selected_object_type.text = "Now editing: " + selected_editable._type + "  -  "
		selected_object_type.text += "Indexed at %s / %s." % [index, current_page_content.size()-1]
	
	if selected_editable is ConstellationButton:
		content_empty_label.hide()
		content_line_edit.text = selected_editable["_label"]
		content_line_edit.show()
	
	if selected_editable is ConstellationList:
		content_empty_label.hide()
		content_text_edit.show()
		content_tree.show()
		content_tree.clear()
		var root = content_tree.create_item()
		root.set_text(0, "List")
		var index:int = 0
		for item in selected_editable._items:
			var tree_item = content_tree.create_item(root, index)
			tree_item.set_text(0, item)
			index += 1
	
	if "_text" in selected_editable:
		content_empty_label.hide()
		content_text_edit.text = selected_editable["_text"]
		content_text_edit.show()
	
	if "style" in selected_editable:
		if is_instance_valid(selected_editable.style):
			%StyleEmptyLabel.hide()
			%StyleTextAlignContainer.show()
			%StyleTextAlign.select(selected_editable.style.get_align_int())
			
func _on_json_edit_context_menu_pressed(id:int, trigger_id:int) -> void:
	if id == trigger_id:
		json_edit_is_word_wrap = !json_edit_is_word_wrap
		var index:int = json_edit.get_menu().get_item_index(trigger_id)
		json_edit.get_menu().set_item_checked(index, json_edit_is_word_wrap)
		
		if json_edit_is_word_wrap:
			json_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		else:
			json_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	
func _on_content_tree_item_selected() -> void:
	content_text_edit.text = content_tree.get_selected().get_text(0)
	
func l(item) -> void: Utils.l(item)

func _on_load_project_pressed() -> void: pass
func _on_save_project_pressed() -> void: pass
func _on_new_project_pressed() -> void: pass ## TODO

func _on_page_select_item_selected(index: int) -> void:
	## TODO
	pass

func _on_new_page_pressed() -> void: new_page(page_line_edit.text, current_project_filepath)

func _on_load_page_pressed() -> void:
	page_line_edit.text = Utils.endify(page_line_edit.text, ".json")
	load_page(page_line_edit.text)
	

func _on_save_page_pressed() -> void: save_page(current_page_filepath)


func _on_force_refresh_pressed() -> void: render_current_page_content()


func _on_save_text_edits_pressed() -> void:
	if selected_editable is ConstellationParagraph:
		selected_editable._text = content_text_edit.text
	elif selected_editable is ConstellationBlockquote:
		selected_editable._text = content_text_edit.text
		
	elif selected_editable is ConstellationList:
		var tree_item = content_tree.get_selected()
		tree_item.set_text(0, content_text_edit.text)
		selected_editable._items[tree_item.get_index()] = tree_item.get_text(0)
	
	#selected_editable._text = content_text_edit.text
	cache_changes(true)

func _on_delete_selected_pressed() -> void:
	current_page_content.erase(selected_editable)
	selected_editable.queue_free()
	await get_tree().process_frame
	cache_changes()


func _on_page_title_edit_text_changed(new_text: String) -> void:
	current_page_json["title"] = new_text
	l("Page title modified.")
	cache_changes()
