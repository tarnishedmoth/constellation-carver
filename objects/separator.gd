class_name ConstellationSeparator extends Control

const FONT = preload("res://objects/paragraph_font.tres")

const TEMPLATE = {
	"type": "separator"
}

func _init() -> void:
	# TODO figure out exactly how big this has to be
	self.custom_minimum_size = Vector2i(240, 12)
	self.focus_mode = Control.FOCUS_CLICK
	
func _draw() -> void:
	# TODO figure out exactly where this has to be
	draw_line(
		Vector2i(0, 10),
		Vector2i(400, 10),
		Color.BLACK
	)
	
func to_dict() -> Dictionary:
	return TEMPLATE.duplicate()

func _to_string() -> String:
	return JSON.stringify(to_dict())
