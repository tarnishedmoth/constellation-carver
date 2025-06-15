class_name MainScreen extends Control

#region MEMORY
const APP_NAME:String = "[i]Constellation Carver v0.1[/i]"
const TILE_0233 = preload("res://assets/tile_0233.png") # New project icon

const BUTTON_ACTION_EMPTY = {
	DISPLAY = "(No Action)",
	VALUE = "."
}

enum TOP_TABS {
	PROJECT_T = 0,
	PAGE_T = 1,
	OBJECTS_T = 2,
	DEBUG_T = 3
}
enum BOTTOM_TABS {
	CONTENT_T = 0,
	STYLE_T = 1,
	JSON_T = 2
}


const PAGE_TEMPLATE:Array = [
	ConstellationImage.TEMPLATE,
	ConstellationParagraph.TEMPLATE,
	ConstellationSeparator.TEMPLATE,
	ConstellationButton.TEMPLATE,
]

var pages: Dictionary[String,Dictionary] = {} # Key is absolute filepath, value is json dictionary
var is_pages_cached:bool = false

var current_project_name: String = "" ## Manually set, name of subfolder in Project directory
var current_project_filepath: String: ## Abstract
	get:
		return U.cat([Particles.file_saves_directory, current_project_name])
var current_page_name: String: ## Abstract
	get:
		if "title" in current_page_json:
			return current_page_json["title"]
		else:
			return "Empty"
var current_page_filepath: String ## Absolute path.
var current_page_json: Dictionary = {}
var current_page_content: Array = []

var selected_editable:Control

var is_initialized:bool = false
var page_content_modified:bool = false:
	set(value):
		page_content_modified = value
		if value:
			application_name["text"] = APP_NAME + "  -  [b]unsaved page changes[/b] 💔"
		else:
			application_name["text"] = APP_NAME

@onready var application_name: RichTextLabel = %ApplicationName
# SPACES
@onready var special_popup_window: SpecialPopupWindow = $SpecialPopupWindow
@onready var log_console: RichTextLabel = %LogConsole:
	set(value):
		log_console = value
		U.log_console = log_console

@onready var top_tab_container: TabContainer = %TopTabContainer
@onready var pd_display: Control = %PDDisplay
@onready var bottom_tab_container: TabContainer = %BottomTabContainer
# PROJECT
@onready var project_option_button: OptionButton = %ProjectOptionButton

# PAGE
@onready var page_filename_edit: LineEdit = %PageFilenameEdit
@onready var page_title_edit: LineEdit = %PageTitleEdit
@onready var page_select: OptionButton = %PageSelect
# OBJECT
@onready var new_object_menu: MenuButton = %NewObjectMenu
@onready var selected_object_type: Label = %ObjectType
@onready var object_tree: Tree = %ObjectTree
# CONTENT
@onready var content_text_edit: TextEdit = %ContentTextEdit

@onready var button_edit_container: VBoxContainer = %ButtonEditContainer
@onready var button_prelabel_line_edit: LineEdit = %ButtonPrelabelLineEdit
@onready var button_label_line_edit: LineEdit = %ButtonLabelLineEdit
@onready var button_action_menu: MenuButton = %ActionMenuButton

@onready var content_tree: Tree = %ContentTree
@onready var content_empty_label: Label = %ContentEmptyLabel
# JSON
@onready var json_edit: CodeEdit = %JSONEdit
var json_edit_is_word_wrap:bool = false

#endregion
#region VIRTUALS

func _ready() -> void:
	U.log_console = log_console
	application_name.text = APP_NAME

	# CONTENT edit tab
	button_action_menu.get_popup().id_pressed.connect(_on_button_action_menu_pressed)

	# JSON edit tab
	var context_menu:PopupMenu = json_edit.get_menu()
	var id:int = context_menu.item_count + 1
	context_menu.add_check_item("Word Wrap", id)
	context_menu.id_pressed.connect(_on_json_edit_context_menu_pressed.bind(id))

	# PROJECT tab
	project_option_button.get_popup().id_pressed.connect(_on_project_option_button_popup_id_pressed)

	set_starting_ui_state()
	l("Application initialized.")
	is_initialized = true

func set_starting_ui_state() -> void:
	# Menu initial states
	top_tab_container.current_tab = TOP_TABS.PROJECT_T # Project tab
	bottom_tab_container.current_tab = BOTTOM_TABS.CONTENT_T # Content tab

	repopulate_project_list()

#endregion
#region PROJECT

func repopulate_project_list() -> void:
	# Initialization
	project_option_button.clear()
	project_option_button.add_icon_item(
		TILE_0233,
		"New Project",
		0
	)
	project_option_button.add_item("~~~~~ ~ ~ ~  ~  ~  ~   ~   ~    ~-.   ~      ~-`       ~    .       `  .", 1)

	# Scanning for files
	var id_index:int = 2
	var directories:PackedStringArray = DirAccess.get_directories_at(Particles.file_saves_directory)
	var current_project_index:int = -1
	for dir:String in directories:
		if not FileAccess.file_exists(U.cat([Particles.file_saves_directory, dir, "index"], "/", ".json")):
			U.l("Directory %s has no 'index.json.'" % [dir])
			continue
		project_option_button.add_item(dir, id_index)

		if current_project_name == dir:
			current_project_index = id_index

		var dirpath:String = U.cat([Particles.file_saves_directory, dir])
		project_option_button.set_item_metadata(id_index, dirpath)
		id_index += 1

	if current_project_index > -1:
		project_option_button.select(current_project_index)
	else:
		project_option_button.select(1)


func load_project(project_dir_path:String) -> void:
	var _filepath = U.cat([project_dir_path, "index"], "/", ".json")
	if FileAccess.file_exists(_filepath):
		# this "rsplit" method is cool because it automatically discards a trailing delimiter when "allow_empty"=false
		var load_project_name:String = project_dir_path.rsplit("/", false, 1)[1]
		current_project_name = load_project_name
		set_starting_ui_state()
		#pages.clear()
		_refresh_project_pages(true)
		load_page(_filepath, false)
	else:
		special_popup_window.popup(
			"Project is missing!\n%s" % [_filepath],
			"Load Project  -  Index Doesn't Exist"
		)
		return

func new_project(project_name:String) -> void:
	current_project_name = project_name
	new_page("index")
	_refresh_project_pages(true)
	set_starting_ui_state()
	top_tab_container.current_tab = TOP_TABS.PROJECT_T

#endregion
#region PAGES
func _refresh_project_pages(force_refresh:bool = false, reload_current:bool = true) -> void:
	if !is_pages_cached or force_refresh:
		is_pages_cached = false
		pages.clear()

		for json_filepath:String in ParticleParser.find_json_files_in(current_project_filepath):
			var json_file:Dictionary = ParticleParser.load_json_from_file(json_filepath)
			if ParticleParser.is_valid_page(json_file):
				pages[json_filepath] = {}
		is_pages_cached = true
	if reload_current:
		if current_page_filepath in pages:
			pages[current_page_filepath] = ParticleParser.load_json_from_file(current_page_filepath)

func reset_page_tab() -> void:
	if not is_initialized: await get_tree().process_frame

	if current_page_filepath:
		page_filename_edit.text = current_page_filepath.get_file()
	else:
		page_filename_edit.text = ""
	page_title_edit.text = current_page_name if current_page_name != "Empty" else ""

	# Page select menu
	page_select.clear()
	if not is_current_project_valid():
		page_select.add_item("No Current Project")
		page_select.disabled = true
		return
	else:
		page_select.disabled = false
		page_select.add_item("Create New Page", 0) # Always id 0
		page_select.add_separator(current_project_name)

		var id_index:int = 2
		for page:String in pages:
			page_select.add_item(page.trim_prefix(U.endify(current_project_filepath)), id_index)
			page_select.set_item_metadata(id_index, page)
			if page == current_page_filepath:
				page_select.select(id_index)
			id_index += 1


		#for json_filepath in ParticleParser.find_json_files_in(current_project_filepath):
			#var json_file = ParticleParser.load_json_from_file(json_filepath)
			#if ParticleParser.is_valid_page(json_file):
				#id_index += 1
				#page_select.add_item(json_filepath, id_index)
				#if current_page_filepath.is_absolute_path():
					#if json_filepath == current_page_filepath:
						#page_select.select(id_index)


func load_page(filepath, relative:bool = true) -> void:
	if page_content_modified:
		var discard:bool = await special_popup_window.popup(
			"Page content modified!\n\nDiscard changes?",
			"Load Page  -  Page Modified",
			true
		)
		if not discard:
			## User Cancel
			return

	var _filepath:String
	if relative:
		_filepath = U.endify(current_project_filepath) + U.endify(filepath, ".json")
	else:
		_filepath = U.endify(filepath, ".json")

	if not FileAccess.file_exists(_filepath):
		l("Tried to load page--file not found!")
		var overwrite:bool = await special_popup_window.popup(
			"File does not exist!\nWould you like to create a new Page?\n%s" % [_filepath],
			"Load Page  -  File Not Found",
			true
		)
		if overwrite:
			new_page(_filepath, true, "")
			load_page(_filepath, false)
		else:
			return

	var payload = Particles.load_json_from_file(_filepath)

	if payload.is_empty():
		l("Loaded page is empty!")
		var overwrite:bool = await special_popup_window.popup(
			"File is empty!\nWould you like to format the file into a New Page?\n%s" % [_filepath],
			"Load Page  -  Empty File",
			true
		)
		if overwrite:
			new_page(_filepath, true, "")
			load_page(_filepath, false)
		return
	elif not "format" in payload:
		l("Loaded page has bad format!")
		var overwrite:bool = await special_popup_window.popup(
			"File has formatting errors!\nWould you like to format the file into a Page?\n%s" % [_filepath],
			"Load Page  -  Corrupt File",
			true
		)
		if overwrite:
			new_page(_filepath, false, "")
			load_page(_filepath, false)
		return
	elif payload["format"] != "particle":
		l("Loaded page has bad format!")
		var result:bool = await special_popup_window.popup(
			"File has formatting errors!\nWould you like to format the file into a Page?\n%s" % [_filepath],
			"Load Page  -  Corrupt File",
			true
		)
		if result:
			new_page(_filepath, false, "")
			load_page(_filepath, false)
		return
	else:
		l("Loading page...")
		page_content_modified = false
		current_page_json = payload
		current_page_filepath = _filepath
		pages[_filepath] = current_page_json ## Lazy loading. Set the keys on project load
		set_starting_ui_state()
		reset_page_tab()
		render_current_page_content()
		return

func render_current_page_content() -> void:
	object_tree.clear()
	reset_editables()

	for child in pd_display.get_children():
		child.queue_free()

	current_page_content.clear()

	l("Rendering page: [b]"+current_page_json["title"]+"[/b]")
	page_title_edit.text = current_page_json["title"]
	page_filename_edit.text = current_page_filepath.get_file()

	var tree_root:TreeItem = object_tree.create_item()
	tree_root.set_text(0, current_page_json["title"])
	tree_root.set_metadata(0, "title")
	for obj in current_page_json["content"]:
		var instance = _render_content(obj)
		current_page_content.append(instance)

		var tree_item:TreeItem = tree_root.create_child()
		tree_item.set_text(0, obj["type"])
		tree_item.set_metadata(0, obj["type"])

func _render_content(obj:Dictionary) -> Control:
	var instance:Control
	match obj["type"]:
		"paragraph":
			l("[b]New paragraph![/b]")
			var _len:int = obj["text"].length()
			l(str(_len) + " characters inside.")
			instance = ConstellationParagraph.new(obj["text"])

		"list":
			l("[b]New list![/b]")
			var count:int = obj["items"].size()
			l(str(count) + " items listed.")
			instance = ConstellationList.new(obj["items"])

		"blockquote":
			l("[b]New blockquote![/b]")
			var _len:int = obj["text"].length()
			l(str(_len) + " characters inside.")
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

func save_page(filepath) -> void:
	cache_changes()
	var _filepath = U.endify(current_project_filepath) + U.endify(filepath, ".json")

	if _filepath != current_page_filepath:
		# Overwriting a different filename
		var duplicate = await special_popup_window.popup(
			"Saving location has changed.\n\nAre you sure you want to save to a new location?\n%s" % [_filepath],
			"Save Page  -  Changed filepath",
			true
		)
		if not duplicate:
			l("User cancelled save.")
			return

		if FileAccess.file_exists(_filepath):
			var overwrite = await special_popup_window.popup(
				"The file you're trying to save to already exists, and isn't the file you loaded for editing.\n\nOverwrite? This file's data will be lost:\n%s" % [_filepath],
				"Save Page  -  Name conflict",
				true
			)
			if not overwrite:
				l("User cancelled save.")
				return


	l("Saving page...")
	var formatted = ParticleParser.stringify(current_page_json)
	var result = ParticleParser.save_json_to_file(formatted, _filepath)

	if result == true:
		l("--Saved page to " + _filepath)
		page_content_modified = false
		reset_page_tab()
	else:
		l(U.bold("--Failed to save page to " + _filepath))

func cache_changes(refresh:bool = false):
	var index:int = 0
	for item:Control in current_page_content:
		if not item == null:
			if item.has_method("to_dict"):
				current_page_json.content[index] = item.to_dict()
		index += 1

	l("Cached %s items." % [index])

	page_content_modified = true

	if refresh: render_current_page_content()

func new_page(filename:String, overwrite:bool = false, dirpath:String = current_project_filepath) -> void:
	if current_project_name.is_empty():
		special_popup_window.popup(
			"No project!\n\nLoad or create a Project to edit pages.",
			"New Page  -  No Project Loaded"
		)
		return

	var _filepath:String
	if not filename.is_absolute_path():
		if dirpath.is_absolute_path():
			# Dir path is a good path
			_filepath = U.endify(dirpath) + U.endify(filename, ".json")
		else:
			push_error("Bad dirpath given to new_page()")
			return
	else:
		push_warning("Gave absolute file path to new_page(). Confirm this is intended behavior.")
		_filepath = U.endify(filename, ".json")

	var file_exists:bool = FileAccess.file_exists(_filepath)
	if file_exists:
		if not overwrite:
			# Warn the user
			var result = await special_popup_window.popup(
				"File already exists.\nErase and overwrite?\n\n(You will permanently lose this data!)\n%s" % [_filepath],
				"New Page - Warning",
				true
			)
			if not result: # Cancel
				return

	var new_page_json:String = ParticleParser.pagify(PAGE_TEMPLATE)
	var did_save:bool = ParticleParser.save_json_to_file(new_page_json, _filepath)
	if did_save:
		l(U.bold("New page created and saved!"))
		_refresh_project_pages(true)
		await get_tree().process_frame
		load_page(_filepath, false)
	else:
		l(U.bold("Failed to save new page JSON!"))

func add_content(content:Dictionary, index:int = -1) -> void:
	if not current_page_json:
		U.l(U.ital("--Can't make a new object without a page selected!"))
		return

	cache_changes()

	var arr:Array = current_page_json["content"]
	if index >= 0:
		arr.insert(index, content)
	else:
		index = arr.size()
		arr.append(content)
	U.l(U.ital("Object inserted at index " + str(index) + ", refreshing..."))

	render_current_page_content()

func remove_content_at(index:int) -> void:
	pass

#endregion
#region EDITING

func reset_editables() -> void: ## Called typically by changing focus with mouse click, or saving and loading.
	if check_editable(): l("Deselected.")
	selected_editable = null

	selected_object_type.text = "No object selected."
	content_empty_label.show()

	button_edit_container.hide()
	button_prelabel_line_edit.clear()
	button_label_line_edit.clear()

	content_text_edit.hide()
	content_text_edit.clear()

	content_tree.hide()
	content_tree.clear()

func open_edit_content(instance:Object) -> void:
	reset_editables()
	# Top: Show Objects tab
	top_tab_container.current_tab = TOP_TABS.OBJECTS_T

	selected_editable = instance
	json_edit.text = str(selected_editable) # Uses _to_string() of instance


	if "_type" in selected_editable:
		var index = current_page_content.find(selected_editable)
		l("Selected %s to edit at index %s" % [selected_editable._type, index])
		selected_object_type.text = "Now editing: " + selected_editable._type + "  -  "
		selected_object_type.text += "Indexed at %s / %s." % [index, current_page_content.size()-1]


	if selected_editable is ConstellationButton:
		content_empty_label.hide()
		button_edit_container.show()

		var action_display_text:String = selected_editable["_action"]
		if action_display_text.is_empty() or action_display_text == BUTTON_ACTION_EMPTY.VALUE:
			action_display_text = BUTTON_ACTION_EMPTY.DISPLAY
		button_action_menu.text = action_display_text

		button_prelabel_line_edit.text = selected_editable["_prelabel"]
		button_label_line_edit.text = selected_editable["_label"]


	if selected_editable is ConstellationList:
		content_empty_label.hide()
		content_text_edit.show()
		content_tree.show()
		content_tree.clear()

		var root:TreeItem = content_tree.create_item()
		root.set_text(0, "List")
		var index:int = 0
		for item in selected_editable._items:
			var tree_item:TreeItem = content_tree.create_item(root, index)
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

#endregion
#region HELPERS

func l(item) -> void: U.l(item)

func is_current_project_valid() -> bool:
	if current_project_name.is_empty(): return false
	else: return true

func is_current_page_valid() -> bool:
	if current_page_name == "Empty": return false
	if current_page_name.is_empty(): return false
	if not current_page_json: return false
	if current_page_json.is_empty(): return false
	if not "title" in current_page_json: return false
	if not "format" in current_page_json: return false
	elif current_page_json["format"] != "particle": return false
	return true

func get_index_of(content:Object) -> int: ## Returns -1 for bad value
	return current_page_content.find(content)

## Returns instance from [member current_page_content]
func get_content_at(index:int) -> Object:
	return current_page_content[index]

func check_editable(type = null) -> bool:
	if selected_editable != null:
		if is_instance_valid(selected_editable):
			if type != null:
				# Classes must match argument object's class
				var matches = is_instance_of(selected_editable, type)
				if matches:
					return true
			else:
				# Any class
				return true
	return false

#endregion
#region SIGNAL HANDLERS

## TOP TAB
func _on_top_tab_container_tab_selected(tab: int) -> void:
	if tab == TOP_TABS.PROJECT_T:
		repopulate_project_list()
	elif tab == TOP_TABS.PAGE_T:
		reset_page_tab()

func _on_project_option_button_popup_id_pressed(id:int) -> void:
	if id == 0:
		# New project
		var project_name:String = await special_popup_window.popup_text_entry(
			"Name your project:",
			"New Project",
			true,
			SpecialPopupWindow.TEXT_FORMAT.NONE # TODO check is valid as folder name
		)
		if project_name.is_empty():
			l("User cancelled new project.")
			return
		else:
			new_project(project_name)

	elif id != 1:
		# Load project
		var selected_project_path:String = project_option_button.get_item_metadata(project_option_button.get_item_index(id))
		load_project(selected_project_path)

func _on_open_user_folder_button_pressed() -> void:
	#OS.shell_show_in_file_manager(OS.get_user_data_dir())
	var d:String = U.cat([OS.get_user_data_dir(), current_project_filepath.lstrip("user://")])
	OS.shell_show_in_file_manager(d)

#func _on_load_project_pressed() -> void: load_project(current_project_filepath)
#func _on_save_project_pressed() -> void: pass
#func _on_new_project_pressed() -> void: new_project()

func _on_page_select_item_selected(index: int) -> void:
	var id = page_select.get_item_id(index)
	if id == 0:
		_on_new_page_pressed()
	else:
		var _filepath:String = page_select.get_item_metadata(index)
		if _filepath.is_absolute_path():
			load_page(_filepath, false)
			reset_page_tab()

func _on_new_page_pressed() -> void:
	var text_input:String = await special_popup_window.popup_text_entry(
		"Enter a file name for your New Page:",
		"Create a New Page",
		true,
		SpecialPopupWindow.TEXT_FORMAT.FILE
	)
	new_page(text_input, false, current_page_filepath.get_base_dir())

func _on_load_page_pressed() -> void:
	load_page(page_filename_edit.text, true)

func _on_save_page_pressed() -> void:
	save_page(page_filename_edit.text)

func _on_force_refresh_pressed() -> void: render_current_page_content()

## Deletes selected editable object
func _on_delete_selected_pressed() -> void:
	if not is_current_project_valid():
		special_popup_window.popup(
			"No Project loaded!\n\nPlease load or create a Project to edit content.",
			"Delete Selected Content  -  Invalid Project"
		)
		return
	elif not is_current_page_valid():
		special_popup_window.popup(
			"No Page loaded!\n\nPlease load or create a Page to edit content.",
			"Delete Selected Content  -  Invalid Page"
		)
		return
	elif not check_editable():
		special_popup_window.popup(
			"No content selected!\n\nSelect a piece of Content by clicking on it in the display, or from the tree in the Objects tab.",
			"Delete Selected Content  -  Invalid Selection"
		)
		return
	else:
		var result = await special_popup_window.popup(
			"Are you sure you want to delete this content?",
			"Delete Selected Content",
			true
		)
		if not result: # Cancel
			return

		current_page_content.erase(selected_editable)
		selected_editable.queue_free()
		reset_editables()
		await get_tree().process_frame
		cache_changes()

func _on_page_title_edit_text_changed(new_text: String) -> void:
	current_page_json["title"] = new_text
	l("Page title modified.")
	cache_changes()
	render_current_page_content() # Might not be necessary

func _on_save_edits_button_pressed() -> void:
	if not check_editable():
		l("Failed to save content edits: no selection.")
		return

	if selected_editable is ConstellationParagraph:
		selected_editable._text = content_text_edit.text

	elif selected_editable is ConstellationBlockquote:
		selected_editable._text = content_text_edit.text

	elif selected_editable is ConstellationList:
		var tree_item = content_tree.get_selected()
		tree_item.set_text(0, content_text_edit.text)
		selected_editable._items[tree_item.get_index()] = tree_item.get_text(0)

	elif selected_editable is ConstellationButton:
		var _action:String = button_action_menu.text
		if _action == BUTTON_ACTION_EMPTY.DISPLAY: _action == BUTTON_ACTION_EMPTY.VALUE

		selected_editable["_action"] = _action
		selected_editable["_prelabel"] = button_prelabel_line_edit.text
		selected_editable["_label"] = button_label_line_edit.text

	#selected_editable._text = content_text_edit.text
	cache_changes(true)

func _on_cancel_edits_button_pressed() -> void:
	reset_editables()

func _on_object_tree_cell_selected() -> void:
	var tree_item:TreeItem = object_tree.get_selected()
	match tree_item.get_metadata(0):
		"title":
			top_tab_container.current_tab = TOP_TABS.PAGE_T
			page_title_edit.grab_focus()
			return
		_:
			var i:int = tree_item.get_index()
			open_edit_content(get_content_at(i))

## BOTTOM TAB
func _on_button_action_menu_about_to_popup() -> void:
	# Populate the list
	var popup = button_action_menu.get_popup()
	popup.clear(true)

	popup.add_icon_radio_check_item(TILE_0233, "URL / Enter Manually", 0)
	var _current_action_value:String = selected_editable["_action"]
	if not _current_action_value.is_empty():
		popup.set_item_checked(0, true)
		popup.set_item_text(0, _current_action_value)

	popup.add_separator("Project Pages:", 1)
	var index_id = 2
	for page:String in pages:
		var formatted_path:String = page.trim_prefix(current_project_filepath).rstrip(".json")
		if formatted_path == _current_action_value:
			popup.set_item_checked(0, false) # Action links to existing page in project
			popup.set_item_checked(index_id, true)
		popup.add_radio_check_item(formatted_path, index_id) # Button shows whatever looks nice // vv These are one in the same for now. vv
		popup.set_item_metadata(index_id, formatted_path) # Metadata contains formatted filepath
		index_id += 1

func _on_button_action_menu_pressed(id:int) -> void:
	# Selected an action for this button
	if not check_editable(ConstellationButton):
		push_error("Pressed edit button action menu without Button selected.")
		return
	## Selected editable is a ConstellationButton

	# HERE WE GO FINALLY
	var _result_action:String = selected_editable["_action"]

	var popup:PopupMenu = button_action_menu.get_popup()
	if id == 0:
		## Manual entry / existing action
		var custom_action:String = await special_popup_window.popup_text_entry(
			"Type a value to assign to this button's action field. You don't need to include the file extension.\
			This should begin with a forward slash '/' for local paths.\
			If the path ends in a slash, it's treated as a directory, within Constellation will try to load 'index.json'.",
			"Manual Button 'Action'",
			true, 0,
			selected_editable["_action"]
		)
		if custom_action.is_empty():
			## User canceled
			return
		else:
			_result_action = custom_action
	else:
		_result_action = str(popup.get_item_metadata(id))
	# Set the UI
	if not ParticleParser.is_valid_webpath(_result_action):
		special_popup_window.popup("Invalid webpath, canceling.")
	else:
		button_action_menu.text = _result_action

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
