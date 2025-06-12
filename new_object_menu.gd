extends MenuButton

@export var Main:MainScreen

@onready var _popup:PopupMenu = self.get_popup()

func _ready() -> void:
	_popup.id_pressed.connect(_on_popup_id_pressed)
	
func _on_popup_id_pressed(id:int) -> void:
	match id:
		0: # Paragraph
			Utils.l(Utils.bold("--New Paragraph"))
			Main.add_content(ConstellationParagraph.TEMPLATE)
		1: # List
			Utils.l(Utils.bold("--New List"))
		2: # Blockquote
			Utils.l(Utils.bold("--New Blockquote"))
		3: # Button
			Utils.l(Utils.bold("--New Button"))
		4: # Separator
			Utils.l(Utils.bold("--New Separator"))
		5: # Image
			Utils.l(Utils.bold("--New Image"))
		6: # Reel
			Utils.l(Utils.bold("--New Reel"))
