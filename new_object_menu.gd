extends MenuButton

@export var Main:MainScreen

@onready var _popup:PopupMenu = self.get_popup()

func _ready() -> void:
	_popup.id_pressed.connect(_on_popup_id_pressed)
	
func _on_popup_id_pressed(id:int) -> void:
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
		4: # Separator
			U.l(U.bold("--New Separator"))
			content = ConstellationSeparator.TEMPLATE
		5: # Image
			U.l(U.bold("--New Image"))
			content = ConstellationImage.TEMPLATE
		6: # Reel
			U.l(U.bold("--New Reel"))
	
	if is_instance_valid(Main.selected_editable):
		Main.add_content(
			content.duplicate(true),
			Main.get_index_of(Main.selected_editable)
			)
