class_name Paragraph extends Control

var text:String
var style:Style

var font:FontFile

func _init(text:String, style:Style = null) -> void:
	self.text = text
	self.style = style
	
func _draw() -> void:
	#draw_string()
	pass
	
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
