extends MenuButton

@export var Main:MainScreen

@onready var _popup:PopupMenu = self.get_popup()

func _ready() -> void:
	_popup.id_pressed.connect(_on_popup_id_pressed)

func _on_popup_id_pressed(id:int) -> void:
	if not Main.is_current_project_valid():
		Main.special_popup_window.popup(
			"No project!\n\nLoad or create a Project to edit pages & content.",
			"New Content  -  No Project Selected"
		)
		return
	if not Main.is_current_page_valid():
		Main.special_popup_window.popup(
			"No page!\n\nLoad or create a Page to edit content.",
			"New Content  -  No Page Selected"
		)
		return

	var content:Dictionary
	match id:
		0: # Paragraph
			U.l(U.bold("--New Paragraph"))
			content = ConstellationParagraph.TEMPLATE
		1: # List
			U.l(U.bold("--New List"))
			content = ConstellationList.TEMPLATE
		2: # Blockquote
			U.l(U.bold("--New Blockquote"))
			content = ConstellationBlockquote.TEMPLATE
		3: # Button
			U.l(U.bold("--New Button"))
			content = ConstellationButton.TEMPLATE
		4: # Separator
			U.l(U.bold("--New Separator"))
			content = ConstellationSeparator.TEMPLATE
		5: # Image
			U.l(U.bold("--New Image"))
			content = ConstellationImage.TEMPLATE
		6: # Reel
			U.l(U.bold("--New Reel"))
			content = ConstellationReel.TEMPLATE

	if is_instance_valid(Main.selected_editable):
		Main.add_content(
			content.duplicate(true),
			Main.get_index_of(Main.selected_editable)
			)
	else:
		Main.add_content(content.duplicate(true))
