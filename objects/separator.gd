class_name ConstellationSeparator extends Control

const FONT = preload("res://objects/paragraph_font.tres")

const TEMPLATE = {
	"type": "separator"
}

func _init() -> void:
	self.custom_minimum_size = Vector2i(240, 12)
	
func _draw() -> void:
	draw_line(
		Vector2i(0, 10),
		Vector2i(400, 10),
		Color.BLACK
	)
	
func to_dict() -> Dictionary:
	return TEMPLATE

func _to_string() -> String:
	return JSON.stringify(to_dict())
