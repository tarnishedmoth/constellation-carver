class_name MainScreen extends Control

#region ROADMAP
##----0.6.9|
## WORKING Fully functional project/page/object/load/edit/save, all objects.
## WORKING Finish list editing functionality.
## WORKING Export Web build.
## WORKING Publish on itch.io.
## WORKING File menu (export/import page as JSON in popup code edit box)
## WORKING Provide entire page JSON for easy copy.
## WORKING Delete page button in memory, TODO doesn't delete files yet
## BUG FIXED Editing Page Title causes caret to go to beginning (reworked instant update+refresh)
## BUG FIXED Creating a new Button breaks things
## BUG FIXED Open project folder? Show filepath at least? Doesn't do anything on Web
## WORKING Delete files. "Deleted" pages are moved to a special folder for safe keeping.
## BUG FIXED Can't set a Button to No Action
##----0.7--|
## WORKING Images encoding/decoding and rendering
## WORKING Import images from file
## TODO Select from any page in page export as json popup.
## BUG FIXED Deleting content objects isn't updating the content tree correctly.
## BUG Investigate if Clipboard access works at all or if TODO we should provide a text box popup to capture it.
## BUG FIXED Image display should auto-scale images to largest scale possible
## BUG FIXED App header doesn't update automatically with project settings.
## BUG Image file import dialog shows on Web where it's useless for now.
## BUG FIXED Images scale larger than max scale.
##----0.8--|
## FEATURE Margins implemented for all objects
## FEATURE Editable content highlighting/frame while editing;
## WORKING Object tree matches/follows selected editable object.
##----0.9--|
## FEATURE Reels basic support following images.
## TASK Import project from external folder.
## TASK Import page data from clipboard.
## TODO Boot splash icon, background image, branding images, etc.
##----1.0--|
## FEATURE Rename projects & pages.
## FEATURE User configurable content templates.
## FEATURE Duplicate content on page.
## FEATURE Copy/paste content across pages.
## TODO File exports don't work on Web.
## TODO Double clicking a Button (or something) takes you to the page it points to?
##----1.1--|
## FEATURE User editor options?
## FEATURE Use alternate fonts and render to image on page.
##----1.5--|
## FEATURE Asset Browser: Import images/etc; link to page objects?
## FEATURE Dual page viewer--upper tab with a configurable page--copy/paste content?
##----2.0--|
## FEATURE WYSIWYG
## FEATURE Full-screen viewer (~3x vertical space).
## FEATURE Drag selection in viewer.
## FEATURE Image transform & compositing.
## FEATURE Inline text with images.
##
#endregion

signal initialized

#region MEMORY
var APP_NAME:String = "[i]Constellation Carver v" + str(ProjectSettings.get_setting("application/config/version"))
const TILE_0233 = preload("res://assets/tile_0233.png") # New project icon

const BUTTON_ACTION_EMPTY = {
	DISPLAY = "(No Action)",
	VALUE = "."
}
const BUTTON_ACTION_MENU_ID_INDEX = {
	MANUAL_ENTRY = 0,
	NO_ACTION = 1,
	SEPARATOR = 2
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

enum STYLE_MENU_ID_INDEX {
	TEXT_ALIGN = 0,
	MARGIN_TOP = 1,
	MARGIN_BOTTOM = 2,
	SCALE = 3
}
enum IMAGE_IMPORT_MENU_ID_INDEX {
	CLIPBOARD = 0,
	FILE = 1,
	PAGE = 2,
	SEPARATOR = 3,
	TEXTBOX = 4
}

const PAGE_TEMPLATE:Array = [
	ConstellationImage.TEMPLATE,
	ConstellationParagraph.TEMPLATE,
	ConstellationSeparator.TEMPLATE,
	ConstellationButton.TEMPLATE,
]

var flag_fs_not_persistent:bool = false
var flag_user_no_projects:bool = true

var file_deleted_directory:String:
	get:
		return U.cat([current_project_filepath, "deleted_pages"])

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
var selected_editable_index:int ## Index within current_page_content

var is_initialized:bool = false:
	set(value):
		is_initialized = value
		if value:
			initialized.emit()
var page_content_modified:bool = false:
	set(value):
		page_content_modified = value
		if value:
			application_name["text"] = APP_NAME + "  -  [b]unsaved page changes[/b] 💔"
		else:
			application_name["text"] = APP_NAME

@onready var application_name: RichTextLabel = %ApplicationName
# SPACES
@onready var welcome: WelcomeScreen = %Welcome
@onready var special_popup_window: SpecialPopupWindow = $SpecialPopupWindow
@onready var file_popup_window: FilePopupMenu = $FilePopupWindow

@onready var log_console: RichTextLabel = %LogConsole:
	set(value):
		log_console = value
		U.log_console = log_console

@onready var top_tab_container: TabContainer = %TopTabContainer
@onready var middle_scroll_container: SmoothScrollContainer = %MiddleContainer
@onready var pd_display: Control = %PDDisplay
@onready var bottom_tab_container: TabContainer = %BottomTabContainer
# PROJECT
@onready var project_option_button: OptionButton = %ProjectOptionButton
@onready var open_user_folder_button: Button = %OpenUserFolderButton
@onready var file_menu_button: MenuButton = %FileMenuButton
@onready var project_rich_text_label: RichTextLabel = %ProjectRichTextLabel
# PAGE
@onready var page_filename_edit: LineEdit = %PageFilenameEdit
@onready var page_title_edit: LineEdit = %PageTitleEdit
@onready var page_select: OptionButton = %PageSelect
@onready var delete_page_button: Button = %DeletePage
# OBJECT
@onready var new_object_menu: MenuButton = %NewObjectMenu
@onready var selected_object_type: Label = %ObjectType
@onready var object_tree: Tree = %ObjectTree
# CONTENT
@onready var content_text_edit: TextEdit = %ContentTextEdit

@onready var list_edit_container: HBoxContainer = %ListEditContainer
@onready var content_tree: Tree = %ContentTree

@onready var button_edit_container: VBoxContainer = %ButtonEditContainer
@onready var button_prelabel_line_edit: LineEdit = %ButtonPrelabelLineEdit
@onready var button_label_line_edit: LineEdit = %ButtonLabelLineEdit
@onready var button_action_menu: MenuButton = %ActionMenuButton

@onready var import_image_data_button: MenuButton = %ImportImageDataButton
@onready var image_edit_container: VBoxContainer = %ImageEditContainer
@onready var image_width_spin_box: SpinBox = %ImageWidthSpinBox
@onready var image_height_spin_box: SpinBox = %ImageHeightSpinBox

@onready var content_empty_label: Label = %ContentEmptyLabel


# STYLE
@onready var style_empty_label: Label = %StyleEmptyLabel
@onready var style_add_menu: MenuButton = %StyleAddMenu

@onready var style_text_align_container: HBoxContainer = %StyleTextAlignContainer
@onready var style_text_align_edit: OptionButton = %StyleTextAlignEdit

@onready var style_margins_top_container: HBoxContainer = %StyleMarginsTopContainer
@onready var style_margin_top_edit: SpinBox = %StyleMarginTopEdit

@onready var style_margins_bottom_container: HBoxContainer = %StyleMarginsBottomContainer
@onready var style_margin_bottom_edit: SpinBox = %StyleMarginBottomEdit

@onready var style_scale_container: HBoxContainer = %StyleScaleContainer
@onready var style_scale_edit: SpinBox = %StyleScaleEdit

@onready var style_save_buttons: HBoxContainer = %StyleSaveButtons


# JSON
@onready var json_edit: CodeEdit = %JSONEdit
var json_edit_is_word_wrap:bool = false

#endregion
#region VIRTUALS

func _ready() -> void:
	U.log_console = log_console
	application_name.text = APP_NAME

	## Hide overlays
	#special_popup_window.hide() # Handled by script
	#file_popup_window.hide() # Handled by script

	## Typically web platform
	if not OS.is_userfs_persistent():
		l("Warning: File storage is not persistent.")
		flag_fs_not_persistent = true

	## Signals
	welcome.ok_pressed.connect(_on_welcome_screen_ok_button_pressed)
	#---TOP TABS
	# PROJECT tab
	project_option_button.get_popup().id_pressed.connect(_on_project_option_button_popup_id_pressed)
	file_menu_button.get_popup().id_pressed.connect(_on_project_file_menu_button_popup_id_pressed)

	#---BOTTOM TABS
	# CONTENT edit tab
	button_action_menu.get_popup().id_pressed.connect(_on_button_action_menu_pressed)
	import_image_data_button.get_popup().id_pressed.connect(_on_import_image_button_popup_id_pressed)

	# STYLE edit tab
	style_add_menu.get_popup().id_pressed.connect(_on_style_add_menu_popup_id_pressed)

	# JSON edit tab
	## Set up a button in the right click context menu for WORD WRAP
	var _json_context_menu:PopupMenu = json_edit.get_menu()
	var id:int = _json_context_menu.item_count + 1
	_json_context_menu.add_check_item("Word Wrap", id)
	_json_context_menu.id_pressed.connect(_on_json_edit_context_menu_pressed.bind(id))

	#
	ui_set_starting_state() # HACK The project list is populated when the tab switches to Project. We could check ourselves.
	l("Application initialized.")
	is_initialized = true

	if flag_user_no_projects:
		welcome.show()

#endregion
#region PROJECT
func prompt_user_new_project() -> void:
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

func new_project(project_name:String) -> void:
	current_project_name = project_name
	new_page("index")
	ui_set_starting_state()
	top_tab_container.current_tab = TOP_TABS.PROJECT_T

func load_project(project_dir_path:String) -> void:
	var _filepath = U.cat([project_dir_path, "index"], "/", ".json")
	if FileAccess.file_exists(_filepath):
		# this "rsplit" method is cool because it automatically discards a trailing delimiter when "allow_empty"=false
		var load_project_name:String = project_dir_path.rsplit("/", false, 1)[1]
		current_project_name = load_project_name

		ui_set_starting_state()
		ui_refresh_project_pages(true)
		load_page(_filepath, false)
	else:
		special_popup_window.popup(
			"Project is missing!\n%s" % [_filepath],
			"Load Project  -  Index Doesn't Exist"
		)
		return

#endregion
#region PAGES

func new_page(filename:String, overwrite:bool = false, new_page_json:String = ParticleParser.pagify(PAGE_TEMPLATE), dirpath:String = current_project_filepath) -> void:
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

	var did_save:bool = ParticleParser.save_json_to_file(new_page_json, _filepath)
	if did_save:
		l(U.bold("New page created and saved!"))
		ui_refresh_project_pages(true)
		await get_tree().process_frame
		load_page(_filepath, false)
	else:
		l(U.bold("Failed to save new page JSON!"))


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
			new_page(_filepath, true, ParticleParser.pagify(PAGE_TEMPLATE), "") # TEST
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
			new_page(_filepath, true, ParticleParser.pagify(PAGE_TEMPLATE), "")
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
			new_page(_filepath, false, ParticleParser.pagify(PAGE_TEMPLATE), "")
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
			new_page(_filepath, false, ParticleParser.pagify(PAGE_TEMPLATE), "")
			load_page(_filepath, false)
		return
	else:
		l("Loading page...")
		load_page_json(payload, _filepath)
		#page_content_modified = false
		#current_page_json = payload.duplicate(true)
		#current_page_filepath = _filepath
		#pages[_filepath] = payload.duplicate(true) ## Lazy loading. Set the keys on project load

		#ui_set_starting_state() # I think these are just causing problems, handle this in the calling function
		#ui_reset_current_tabs()
		#ui_reset_page_tab()
		render_current_page_content()
		return

func load_page_json(payload:Dictionary, filepath:String = "TEMP") -> void:
	if payload.is_empty():
		return
	elif not "format" in payload:
		l("--Loaded page JSON has bad format.")
		return
	elif payload["format"] != "particle":
		l("--Loaded page JSON has bad format.")
		return
	else:
		l("Loading page...")
		page_content_modified = false
		current_page_json = payload.duplicate(true)

		current_page_filepath = filepath
		pages[filepath] = payload.duplicate(true)

		#ui_set_starting_state() # I think these are just causing problems, handle this in the calling function
		#ui_reset_current_tabs()
		#ui_reset_page_tab()
		render_current_page_content()
		return


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
		ui_reset_page_tab()
	else:
		l(U.bold("--Failed to save page to " + _filepath))


func render_current_page_content() -> void:
	object_tree.clear()
	reset_editables()

	for child in pd_display.get_children():
		child.queue_free()

	current_page_content.clear()

	l("Rendering page: [b]"+current_page_json["title"]+"[/b]")
	page_title_edit.text = current_page_json["title"]
	page_filename_edit.text = current_page_filepath.get_file()

	## Object tree population happens alongside this.
	var tree_root:TreeItem = object_tree.create_item()
	tree_root.set_text(0, current_page_json["title"])
	tree_root.set_metadata(0, "title")
	for obj in current_page_json["content"]:
		var instance = _render_content(obj)
		current_page_content.append(instance)

		var tree_item:TreeItem = tree_root.create_child()
		tree_item.set_text(0, obj["type"])
		tree_item.set_metadata(0, obj["type"])

func delete_page(page:String, in_current_project:bool = true) -> void: # Filepath in Pages
	if in_current_project:
		if page in pages:
			# Delete the file
			_move_file_to_deleted_cache(page)

			# Delete our page in memory
			var next_page:String # Filepath

			# Find a valid page to switch to
			for _page in pages:
				if _page == current_page_filepath:
					continue
				else:
					next_page == _page
					break

			pages.erase(page)
			if not next_page.is_empty():
				load_page(next_page)
			else:
				ui_reset_current_tabs()

func _move_file_to_deleted_cache(filepath:String) -> void:
	if filepath.is_absolute_path():
		## Get the filename+extension
		var target_filename:String = filepath.get_file()
		## Temporarily remove the extension
		var ideal_target_filepath:String = U.cat([file_deleted_directory, target_filename.get_basename()])

		## Make a copy to work with
		var _actual_target_filepath:String = ideal_target_filepath
		var iter:int = 1
		while FileAccess.file_exists(_actual_target_filepath):
			## Add the iterator to the end of the filename if it exists
			_actual_target_filepath = ideal_target_filepath + "_" + str(iter)
			iter += 1

		## Add the extension back on
		_actual_target_filepath = _actual_target_filepath + "." + target_filename.get_extension()

		## Copy the data from source file to target
		var source = FileAccess.open(filepath, FileAccess.READ)
		ParticleParser.save_json_to_file(source.get_as_text(), _actual_target_filepath)
		source.close()

		## Delete the source file
		DirAccess.remove_absolute(filepath)


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

func add_content(content:Dictionary, index:int = -1) -> void:
	if content.is_empty():
		push_warning("Tried to add empty content to page. Returning.")
		return
	if not current_page_json:
		push_warning("Tried to make a new object without a page selected!")
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
#region USER INTERFACE

func ui_set_starting_state() -> void:
	# Menu initial states
	top_tab_container.current_tab = TOP_TABS.PROJECT_T # Project tab
	bottom_tab_container.current_tab = BOTTOM_TABS.CONTENT_T # Content tab

func ui_repopulate_project_list() -> void:
	if not is_initialized:
		await initialized
	# Initialization
	project_option_button.clear()
	project_option_button.add_icon_item(
		TILE_0233,
		"New Project",
		0
	)
	project_option_button.add_item("~~~~~ ~ ~ ~  ~  ~  ~   ~   ~    ~-.   ~      ~-`       ~    .       `  .", 1)

	## Check if user projects folder exists
	flag_user_no_projects = true
	if not DirAccess.dir_exists_absolute(Particles.file_saves_directory):
		DirAccess.make_dir_recursive_absolute(Particles.file_saves_directory)
	else:
		## Look for Projects

		# UI variables
		var id_index:int = 2 # To assign to the Project menu buttons
		var current_project_index:int = -1 # To select the current project in our popup menu

		## Scan for index.json within all immediate subfolders
		var directories:PackedStringArray = DirAccess.get_directories_at(Particles.file_saves_directory)
		for dir:String in directories:
			if not FileAccess.file_exists(U.cat([Particles.file_saves_directory, dir, "index"], "/", ".json")):
				U.l("Directory %s has no 'index.json.'" % [dir])
				continue
			else:
				flag_user_no_projects = false
				project_option_button.add_item(dir, id_index)

				if current_project_name == dir:
					current_project_index = id_index

				var dirpath:String = U.cat([Particles.file_saves_directory, dir])
				project_option_button.set_item_metadata(id_index, dirpath)
				id_index += 1

		if current_project_index > -1:
			project_option_button.select(current_project_index)
		return

		# No currently selected project
		project_option_button.select(1)


func ui_refresh_project_pages(force_refresh:bool = false, reload_current:bool = true) -> void:
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

## TABS
func ui_reset_current_tabs() -> void:
	top_tab_container.tab_selected.emit(top_tab_container.current_tab)
	bottom_tab_container.tab_selected.emit(bottom_tab_container.current_tab)

## UPPER
func ui_reset_project_tab() -> void:
	ui_repopulate_project_list()

	if not is_initialized:
		await initialized

	var total_pages:int
	#var total_contents:int
	total_pages = pages.size()
	#for page in pages:
		#total_contents += pages[page]["content"].size()
	## We aren't going to get this total contents value because we are lazy loading pages.
	## Uncached pages don't have a dictionary in their value slot.
	project_rich_text_label.text = "%s pages" % [total_pages]

func ui_reset_page_tab() -> void:
	## NOTE We don't reload the page files inside the project here, only reference the pages[] dictionary.
	##      See ui_refresh_project_pages()
	if not is_initialized:
		await initialized

	if current_page_filepath:
		page_filename_edit.text = current_page_filepath.get_file()
		delete_page_button.disabled = false
	else:
		page_filename_edit.text = ""
		delete_page_button.disabled = true
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

func ui_reset_object_tab():
	if not is_initialized: await initialized

	if not check_editable():
		return
	if "_type" in selected_editable:
		selected_editable_index = current_page_content.find(selected_editable)
		l("Selected %s to edit at index %s" % [selected_editable._type, selected_editable_index])
		selected_object_type.text = "Now editing: " + selected_editable._type + "  -  "
		selected_object_type.text += "Indexed at %s / %s." % [selected_editable_index, current_page_content.size()-1]

		var selected_tree_object:TreeItem = object_tree.get_root().get_child(selected_editable_index)
		object_tree.scroll_to_item(selected_tree_object)
		object_tree.deselect_all()
		object_tree.set_selected(selected_tree_object, 0)

## LOWER
func ui_reset_content_tab() -> void:
	if not is_initialized:
		await initialized

	content_empty_label.show()
	list_edit_container.hide()
	button_edit_container.hide()
	image_edit_container.hide()
	content_text_edit.hide()

	if not check_editable():
		return
	## PARAGRAPH && BLOCKQUOTE
	if "_text" in selected_editable:
		content_empty_label.hide()
		content_text_edit.text = selected_editable["_text"]
		content_text_edit.show()

	## BUTTON
	if selected_editable is ConstellationButton:
		content_empty_label.hide()
		button_edit_container.show()

		var action_display_text:String = selected_editable["_action"]
		if action_display_text.is_empty() or action_display_text == BUTTON_ACTION_EMPTY.VALUE:
			action_display_text = BUTTON_ACTION_EMPTY.DISPLAY
		button_action_menu.text = action_display_text

		button_prelabel_line_edit.text = selected_editable["_prelabel"]
		button_label_line_edit.text = selected_editable["_label"]

	## LIST
	elif selected_editable is ConstellationList:
		content_empty_label.hide()
		content_text_edit.show()
		list_edit_container.show()
		content_tree.clear()

		# TODO allow for adding/removing items
		#content_tree

		var root:TreeItem = content_tree.create_item()
		root.set_text(0, "List")

		var index:int = 1
		for item in selected_editable._items:
			var tree_item:TreeItem = content_tree.create_item(root, index)
			tree_item.set_text(0, item)
			index += 1

	## IMAGE
	elif selected_editable is ConstellationImage:
		content_empty_label.hide()
		image_edit_container.show()
		content_text_edit.show()
		image_width_spin_box.value = int(selected_editable["_width"])
		image_height_spin_box.value = int(selected_editable["_height"])
		content_text_edit.text = selected_editable["_pixels"]

	## REEL
	elif selected_editable is ConstellationReel:
		content_empty_label.hide()
		image_edit_container.show()
		#content_text_edit.show()
		image_width_spin_box.value = int(selected_editable["_width"])
		image_height_spin_box.value = int(selected_editable["_height"])
		#content_text_edit.text = selected_editable["_pixels"]

func ui_reset_style_tab() -> void:
	if not is_initialized:
		await initialized

	# Set up add/remove menu
	var _add_menu_popup:PopupMenu = style_add_menu.get_popup()
	_add_menu_popup.clear(true)
	_add_menu_popup.add_check_item("Text Align", STYLE_MENU_ID_INDEX.TEXT_ALIGN)
	_add_menu_popup.add_check_item("Margin Top", STYLE_MENU_ID_INDEX.MARGIN_TOP)
	_add_menu_popup.add_check_item("Margin Bottom", STYLE_MENU_ID_INDEX.MARGIN_BOTTOM)
	_add_menu_popup.add_check_item("Scale", STYLE_MENU_ID_INDEX.SCALE)
	# Metadata not used for anything yet
	_add_menu_popup.set_item_metadata(STYLE_MENU_ID_INDEX.TEXT_ALIGN, "text-align")
	_add_menu_popup.set_item_metadata(STYLE_MENU_ID_INDEX.MARGIN_TOP, "margin-top")
	_add_menu_popup.set_item_metadata(STYLE_MENU_ID_INDEX.MARGIN_BOTTOM, "margin-bottom")
	_add_menu_popup.set_item_metadata(STYLE_MENU_ID_INDEX.SCALE, "scale")

	# Set up text align options
	style_text_align_edit.clear()
	style_text_align_edit.add_item("Left", Style.get_align("left"))
	style_text_align_edit.add_item("Center", Style.get_align("center"))
	style_text_align_edit.add_item("Right", Style.get_align("right"))

	style_text_align_edit.set_item_metadata(Style.get_align("left"), "left")
	style_text_align_edit.set_item_metadata(Style.get_align("center"), "center")
	style_text_align_edit.set_item_metadata(Style.get_align("right"), "right")

	# Close all containers
	style_text_align_container.hide()
	style_margins_top_container.hide()
	style_margins_bottom_container.hide()
	style_scale_container.hide()
	style_empty_label.show()

	if not check_editable():
		return
	else:
		if "style" in selected_editable:
			var style:Style = selected_editable["style"]
			if not is_instance_valid(style): return

			var modified_style_properties:Dictionary = style.get_modified_properties()
			if not modified_style_properties.is_empty():
				style_empty_label.hide()

				if "text-align" in modified_style_properties:
					_add_menu_popup.set_item_checked(STYLE_MENU_ID_INDEX.TEXT_ALIGN, true)
					style_text_align_container.show()
					style_text_align_edit.select(selected_editable.style.get_align_int())

				if "margin-top" in modified_style_properties:
					_add_menu_popup.set_item_checked(STYLE_MENU_ID_INDEX.MARGIN_TOP, true)
					style_margins_top_container.show()
					style_margin_top_edit.value = modified_style_properties["margin-top"]

				if "margin-bottom" in modified_style_properties:
					_add_menu_popup.set_item_checked(STYLE_MENU_ID_INDEX.MARGIN_BOTTOM, true)
					style_margins_bottom_container.show()
					style_margin_bottom_edit.value = modified_style_properties["margin-bottom"]

				if "scale" in modified_style_properties:
					_add_menu_popup.set_item_checked(STYLE_MENU_ID_INDEX.SCALE, true)
					style_scale_container.show()
					style_scale_edit.value = modified_style_properties["scale"]

func ui_reset_json_tab() -> void:
	json_edit.text = str(selected_editable) # Uses _to_string() of instance

#endregion
#region EDITING

func open_edit_content(instance:Object) -> void:
	reset_editables()
	selected_editable = instance

	ui_reset_current_tabs()

	# Top: Show Objects tab (but don't double refresh)
	if top_tab_container.current_tab != TOP_TABS.OBJECTS_T:
		top_tab_container.current_tab = TOP_TABS.OBJECTS_T

	# Scroll to content in viewer
	#middle_scroll_container.ensure_control_visible(selected_editable)
	middle_scroll_container.smooth_scroll(selected_editable.position.y)

	#var selected_tree_item:TreeItem = object_tree.get_root().get_child(get_index_of(selected_editable))
	#object_tree.scroll_to_item(selected_tree_item)


func reset_editables() -> void: ## Called typically by changing focus with mouse click, or saving and loading.
	if check_editable(): l("Deselected.")
	selected_editable = null
	selected_editable_index = -1

	selected_object_type.text = "No object selected."
	content_empty_label.show()

	button_edit_container.hide()
	button_prelabel_line_edit.clear()
	button_label_line_edit.clear()

	content_text_edit.hide()
	content_text_edit.clear()

	list_edit_container.hide()
	content_tree.clear()

	image_edit_container.hide()

func check_editable(type = null, check_has_style:bool = false) -> bool:
	if selected_editable != null:
		if is_instance_valid(selected_editable):

			if check_has_style:
				if "style" in selected_editable: return true
				else: return false

			if type != null:
				# Classes must match argument object's class
				var matches = is_instance_of(selected_editable, type)
				if matches:
					return true
			else:
				# Any class
				return true
	return false

func cache_changes(refresh:bool = false):
	var index:int = 0
	for item:Control in current_page_content:
		if not item == null:
			if item.has_method("to_dict"):
				## CRITICAL Set the current page JSON
				current_page_json["content"][index] = item.to_dict()
		index += 1

	l("Cached %s items." % [index])

	## NONE of this is working for some reason so we'll keep it manual for now.
	#if current_page_json != pages[current_page_filepath]:
	#if current_page_json.hash() != pages[current_page_filepath].hash():
	#if not current_page_json.recursive_equal(pages[current_page_filepath], 6): #BUG
	#if ParticleParser.stringify(current_page_json) != ParticleParser.stringify(pages[current_page_filepath]):
		#page_content_modified = true
	#else:
		#page_content_modified = false
	page_content_modified = true

	if refresh: render_current_page_content()

func save_content_edits() -> void:
	if not check_editable():
		l("Failed to save content edits: no selection.")
		return

	## WORKING
	if selected_editable is ConstellationParagraph:
		selected_editable._text = content_text_edit.text

	## WORKING
	elif selected_editable is ConstellationBlockquote:
		selected_editable._text = content_text_edit.text

	## WORKING
	elif selected_editable is ConstellationList:
		#var tree_item = content_tree.get_selected()
		#tree_item.set_text(0, content_text_edit.text)
		#selected_editable._items[tree_item.get_index()] = tree_item.get_text(0)
		var list_items:Array[String] = []
		for item in content_tree.get_root().get_children():
			list_items.append(item.get_text(0))

		selected_editable._items = list_items

	## WORKING
	elif selected_editable is ConstellationButton:
		var _action:String = button_action_menu.text
		if _action == BUTTON_ACTION_EMPTY.DISPLAY: _action == BUTTON_ACTION_EMPTY.VALUE

		selected_editable["_action"] = _action
		selected_editable["_prelabel"] = button_prelabel_line_edit.text
		selected_editable["_label"] = button_label_line_edit.text

	## WORKING
	elif selected_editable is ConstellationImage:
		selected_editable["_width"] = image_width_spin_box.value
		selected_editable["_height"] = image_height_spin_box.value
		selected_editable["_pixels"] = content_text_edit.text

	## TODO TEST
	elif selected_editable is ConstellationReel:
		selected_editable["_width"] = image_width_spin_box.value
		selected_editable["_height"] = image_height_spin_box.value
		selected_editable["_frames"] = content_text_edit.text # TODO

	cache_changes(true)

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
	elif not "content" in current_page_json: return false
	return true

func get_index_of(content:Object) -> int: ## Returns -1 for bad value
	return current_page_content.find(content)

## Returns instance from [member current_page_content]
func get_content_at(index:int) -> Object:
	return current_page_content[index]

#endregion
#region SIGNAL HANDLERS

## TOP TAB
func _on_top_tab_container_tab_selected(tab: int) -> void:
	if tab == TOP_TABS.PROJECT_T:
		ui_reset_project_tab()
	elif tab == TOP_TABS.PAGE_T:
		ui_reset_page_tab()
	elif tab == TOP_TABS.OBJECTS_T:
		ui_reset_object_tab()

func _on_project_option_button_popup_id_pressed(id:int) -> void:
	if id == 0:
		# New project
		prompt_user_new_project()

	elif id != 1:
		# Load project
		var selected_project_path:String = project_option_button.get_item_metadata(project_option_button.get_item_index(id))
		load_project(selected_project_path)
		ui_reset_current_tabs()


func _on_open_user_folder_button_pressed() -> void:
	#if flag_fs_not_persistent: # Doesn't work?
	if OS.has_feature("web"):
		special_popup_window.popup(
			"Some features are not yet available on Web, such as user file access.\n
			If you want to export your pages, use (Project->File->Export), and copy the JSON manually into your file.\
			You can also select individual content objects, and navigate to the JSON tab to copy only specific pieces.",
			"Web Version  -  File Access Restricted"
		)
		return
	else:
		#OS.shell_show_in_file_manager(OS.get_user_data_dir())
		var d:String = U.cat([OS.get_user_data_dir(), current_project_filepath.lstrip("user://")])
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(d))

func _on_project_file_menu_button_popup_id_pressed(id:int) -> void:
	match id:
		0:
			# Export Separator
			pass
		1:
			## Export page as JSON
			#if page_content_modified:
				#var confirm:bool = await special_popup_window.popup(
					#"Page content has changed. Save changes?",
					#"Export  -  Page Modified",
					#true
				#
				#if confirm:
			cache_changes(true)

			# cache_changes() is where the JSON is saved for the page
			file_popup_window.popup_code(ParticleParser.stringify(current_page_json))
		50: # Import separator
			pass
		51:
			## Import page as JSON
			cache_changes(true)
			var confirm:bool = await file_popup_window.popup_code("", true)
			if confirm:
				# Make a new page with the JSON
				var new_page_json:String = file_popup_window.text_box.text

				var result:String = await special_popup_window.popup_text_entry(
					"Enter a filepath for your page.",
					"Save Page  -  New File",
					true, SpecialPopupWindow.TEXT_FORMAT.FILE)
				if result.is_empty():
					return
				else:
					var filepath:String = result
					new_page(filepath, false, new_page_json)


				#if ParticleParser.is_valid_page(new_page_json):
				#	pass


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
			#ui_reset_page_tab()
			ui_reset_current_tabs()

func _on_welcome_screen_ok_button_pressed() -> void:
	prompt_user_new_project()


func _on_delete_page_pressed() -> void:
	if is_current_page_valid():
		var confirm:bool = await special_popup_window.popup(
			"Are you sure you want to delete this page?",
			"Warning  -  Delete Page",
			true
		)
		if confirm:
			delete_page(current_page_filepath)
		else:
			return

func _on_new_page_pressed() -> void:
	var text_input:String = await special_popup_window.popup_text_entry(
		"Enter a file name for your New Page:",
		"Create a New Page",
		true,
		SpecialPopupWindow.TEXT_FORMAT.FILE
	)
	if not text_input.is_empty():
		new_page(text_input, false, ParticleParser.pagify(PAGE_TEMPLATE), current_page_filepath.get_base_dir())
	else:
		## Cancelled
		return

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
		cache_changes(true)
		reset_editables()

#func _on_page_title_edit_text_changed(new_text: String) -> void:
func _on_page_title_edit_text_submitted(new_text: String) -> void:
	current_page_json["title"] = new_text
	l("Page title modified.")
	cache_changes()
	#render_current_page_content() # Might not be necessary

func _on_save_edits_button_pressed() -> void:
	save_content_edits()

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
			if selected_editable_index == i:
				return
			open_edit_content(get_content_at(i))


## BOTTOM TAB

func _on_bottom_tab_container_tab_selected(tab: int) -> void:
	match tab:
		BOTTOM_TABS.CONTENT_T:
			ui_reset_content_tab()
			pass
		BOTTOM_TABS.STYLE_T:
			ui_reset_style_tab()
		BOTTOM_TABS.JSON_T:
			ui_reset_json_tab()

## LISTS

func _on_content_text_edit_text_changed() -> void:
	if check_editable(ConstellationList):
		content_tree.get_selected().set_text(0, content_text_edit.text)

func _on_content_tree_item_selected() -> void:
	content_text_edit.text = content_tree.get_selected().get_text(0)

func _on_list_insert_above_pressed() -> void:
	_insert_content_tree_list_item(true)

func _on_list_selected_delete_pressed() -> void:
	content_tree.get_root().remove_child(content_tree.get_selected())

func _on_list_insert_below_pressed() -> void:
	_insert_content_tree_list_item(false)


func _insert_content_tree_list_item(above:bool = true) -> void:
	var new_item:TreeItem = content_tree.create_item()
	new_item.set_text(0, "Lorem ipsum")

	if above:
		# Insert Above
		new_item.move_before(content_tree.get_selected())
	else:
		# Insert Below
		new_item.move_after(content_tree.get_selected())


## BUTTONS

func _on_button_action_menu_about_to_popup() -> void:
	# Populate the list
	var popup = button_action_menu.get_popup()
	popup.clear(true)

	## Manual Entry
	popup.add_icon_radio_check_item(TILE_0233, "URL / Enter Manually", BUTTON_ACTION_MENU_ID_INDEX.MANUAL_ENTRY)
	var _current_action_value:String = selected_editable["_action"]
	if not _current_action_value.is_empty() && _current_action_value != BUTTON_ACTION_EMPTY.VALUE:
		popup.set_item_checked(BUTTON_ACTION_MENU_ID_INDEX.MANUAL_ENTRY, true)
		popup.set_item_text(BUTTON_ACTION_MENU_ID_INDEX.MANUAL_ENTRY, _current_action_value)

	## No Action
	popup.add_radio_check_item(BUTTON_ACTION_EMPTY.DISPLAY, BUTTON_ACTION_MENU_ID_INDEX.NO_ACTION)
	popup.set_item_metadata(BUTTON_ACTION_MENU_ID_INDEX.NO_ACTION, BUTTON_ACTION_EMPTY.VALUE)
	if _current_action_value == BUTTON_ACTION_EMPTY.VALUE:
		popup.set_item_checked(BUTTON_ACTION_MENU_ID_INDEX.NO_ACTION, true)

	## Separator
	popup.add_separator("Project Pages:", BUTTON_ACTION_MENU_ID_INDEX.SEPARATOR)

	## Project pages items
	var index_id = BUTTON_ACTION_MENU_ID_INDEX.SEPARATOR + 1
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
	if id == BUTTON_ACTION_MENU_ID_INDEX.MANUAL_ENTRY:
		## Manual entry / existing action
		var display:String = selected_editable["_action"]
		if display == BUTTON_ACTION_EMPTY.VALUE:
			display = ""
		var custom_action:String = await special_popup_window.popup_text_entry(
			"Type a value to assign to this button's action field. You don't need to include the file extension.\
			This should begin with a forward slash '/' for local paths.\
			If the path ends in a slash, it's treated as a directory, within Constellation will try to load 'index.json'.",
			"Manual Button 'Action'",
			true, 0,
			display
		)
		if custom_action.is_empty():
			## User canceled
			return
		else:
			_result_action = custom_action
	elif id != BUTTON_ACTION_MENU_ID_INDEX.SEPARATOR:
		_result_action = str(popup.get_item_metadata(id))
	# Set the UI
	if not ParticleParser.is_valid_webpath(_result_action):
		special_popup_window.popup("Invalid webpath, canceling.")
	else:
		button_action_menu.text = _result_action


## IMAGES

func _on_import_image_button_popup_id_pressed(id:int) -> void:
	if not check_editable(): return
	match id:
		IMAGE_IMPORT_MENU_ID_INDEX.CLIPBOARD:
			var jason:Dictionary = ParticleParser.grab_json_from_clipboard()
			if jason.is_empty(): return

			if selected_editable is ConstellationImage:
				if "type" in jason:
					if jason["type"] == ConstellationImage._type:
						if "width" in jason:
							image_width_spin_box.value = jason["width"]
						if "height" in jason:
							image_height_spin_box.value = jason["height"]
						if "pixels" in jason:
							content_text_edit.text = jason["pixels"]
							# TODO Fancy image viewing/editing

			elif selected_editable is ConstellationReel:
				if "type" in jason:
					if jason["type"] == ConstellationReel._type:
						if "width" in jason:
							image_width_spin_box.value = jason["width"]
						if "height" in jason:
							image_height_spin_box.value = jason["height"]
						if "frames" in jason:
							content_text_edit.text = jason["frames"].duplicate(true)
							# TODO Fancy reel viewing/editing

			if "style" in jason:
				# TODO Style import from clipboard data
				#for param in jason["style"]:
				pass

		IMAGE_IMPORT_MENU_ID_INDEX.FILE:
			## TODO File picker from Assets folder
			var user_selection:String = await file_popup_window.popup_image_file_picker()
			if user_selection.is_empty():
				## User cancel
				return
			elif not user_selection.is_absolute_path():
				push_error("Bad path!")
			elif selected_editable is ConstellationImage:
				var image:ConstellationImage = ConstellationImageProcessor.create_constellation_image_from(user_selection, 0.5) # TODO allow user to configure
				content_text_edit.text = image._pixels
				image_height_spin_box.value = image._height
				image_width_spin_box.value = image._width
			pass

## STYLE

func _on_style_add_menu_popup_id_pressed(id:int) -> void:
	if not check_editable(null, true):
		push_error("Style: No editable selected / No 'style' in editable.")
		return
	#else:
		#if not is_instance_valid(editable.style):
			#editable.style = Style.new()

	var _add_menu_popup:PopupMenu = style_add_menu.get_popup()
	var _index:int = _add_menu_popup.get_item_index(id)

	# Toggle the check
	_add_menu_popup.toggle_item_checked(_index)

	match id:
		## If the arrangements of the menu items ever change, this will break. To fix, instantiate popup items in code. HACK
		## The buttons for each id have checkboxes & are check'ed when opening the editable based on its Style.
		STYLE_MENU_ID_INDEX.TEXT_ALIGN: # Text Align
			style_text_align_container.visible = _add_menu_popup.is_item_checked(_index)
			style_text_align_edit.select(Style.get_align(Style.DEFAULTS.TEXT_ALIGN))

		STYLE_MENU_ID_INDEX.MARGIN_TOP: # Margin Top
			style_margins_top_container.visible = _add_menu_popup.is_item_checked(_index)
			style_margin_top_edit.value = Style.DEFAULTS.MARGIN_TOP

		STYLE_MENU_ID_INDEX.MARGIN_BOTTOM: # Margin Bottom
			style_margins_bottom_container.visible = _add_menu_popup.is_item_checked(_index)
			style_margin_bottom_edit.value = Style.DEFAULTS.MARGIN_BOTTOM

		STYLE_MENU_ID_INDEX.SCALE: # Scale
			style_scale_container.visible = _add_menu_popup.is_item_checked(_index)
			if selected_editable is ConstellationImage:
				style_scale_edit.value = Style.DEFAULTS.SCALE_IMAGE
			elif selected_editable is ConstellationReel:
				style_scale_edit.value = Style.DEFAULTS.SCALE_REEL

func _on_style_save_button_pressed() -> void:
	if not check_editable(null, true):
		push_error("Invalid editable for Style save.")
		return

	selected_editable.style.text_align = style_text_align_edit.get_item_metadata(style_text_align_edit.selected)
	selected_editable.style.margin_top = style_margin_top_edit.value
	selected_editable.style.margin_bottom = style_margin_bottom_edit.value
	selected_editable.style.scale = style_scale_edit.value

	cache_changes(true)

## JSON

func _on_json_edit_context_menu_pressed(id:int, trigger_id:int) -> void:
	if id == trigger_id:
		json_edit_is_word_wrap = !json_edit_is_word_wrap
		var index:int = json_edit.get_menu().get_item_index(trigger_id)
		json_edit.get_menu().set_item_checked(index, json_edit_is_word_wrap)

		if json_edit_is_word_wrap:
			json_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		else:
			json_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE


func _on_style_text_align_edit_item_selected(index: int) -> void:
	style_text_align_edit.alignment = style_text_align_edit.get_selected_id()
