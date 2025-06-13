extends MarginContainer

@export var main:MainScreen

@onready var style_add_menu: MenuButton = %StyleAddMenu
@onready var _popup:PopupMenu = style_add_menu.get_popup()

func _ready() -> void:
	_popup.id_pressed.connect(_on_popup_id_pressed)
	
func _on_popup_id_pressed(id:int) -> void:
	match id:
		0: # Text Align
			pass
		1: # Margin Top
			pass
		2: # Margin Bottom
			pass
		3: # Scale
			pass
