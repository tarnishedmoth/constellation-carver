extends MarginContainer

@export var main:MainScreen

@onready var style_add_menu: MenuButton = %StyleAddMenu
@onready var _popup:PopupMenu = style_add_menu.get_popup()


func _ready() -> void:
	style_add_menu.get_popup().id_pressed.connect(_on_style_add_menu_popup_id_pressed)

func _on_style_add_menu_popup_id_pressed(id:int) -> void:
	var editable = main.selected_editable
	if not main.check_editable(Control):
		push_error("Style: No editable selected.")
		return
	elif not "style" in editable:
		push_error("Style: No style property in this item.")
	else:
		if not is_instance_valid(editable.style):
			editable.style = Style.new()

	match id:
		0: # Text Align
			editable.style.text_align = "left"
			pass
		1: # Margin Top
			pass
		2: # Margin Bottom
			pass
		3: # Scale
			pass
