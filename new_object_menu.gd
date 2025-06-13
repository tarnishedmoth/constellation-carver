extends MenuButton

@export var Main:MainScreen

@onready var _popup:PopupMenu = self.get_popup()

func _ready() -> void:
	_popup.id_pressed.connect(_on_popup_id_pressed)
	
func _on_popup_id_pressed(id:int) -> void:
	var content:Dictionary
	match id:
		0: # Paragraph
			Utils.l(Utils.bold("--New Paragraph"))
			content = ConstellationParagraph.TEMPLATE
		1: # List
			Utils.l(Utils.bold("--New List"))
			content = ConstellationList.TEMPLATE
		2: # Blockquote
			Utils.l(Utils.bold("--New Blockquote"))
			content = ConstellationBlockquote.TEMPLATE
		3: # Button
			Utils.l(Utils.bold("--New Button"))
		4: # Separator
			Utils.l(Utils.bold("--New Separator"))
			content = ConstellationSeparator.TEMPLATE
		5: # Image
			Utils.l(Utils.bold("--New Image"))
			content = ConstellationImage.TEMPLATE
		6: # Reel
			Utils.l(Utils.bold("--New Reel"))
	
	if is_instance_valid(Main.selected_editable):
		Main.add_content(
			content.duplicate(true),
			Main.get_index_of(Main.selected_editable)
			)
