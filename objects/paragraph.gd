class_name Paragraph extends Control

const FONT = preload("res://objects/paragraph_font.tres")

var text:String
var style:Style

var _last_global_position:Vector2

func _prepare_text(t:String) -> String:
	return t

func _init(text:String, style:Style = null) -> void:
	self.text = text
	self.style = style
	
func _draw() -> void:
	draw_string(FONT, global_position, _prepare_text(text), HORIZONTAL_ALIGNMENT_LEFT, 0, 14, Color.BLACK)
	
func to_dict() -> Dictionary:
	var data:Dictionary = {
		"type": "paragraph",
		"text": text,
	}
	
	var style_output = style.to_dict()
	if not style_output.is_empty():
		data.merge({"style": style_output})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict())
