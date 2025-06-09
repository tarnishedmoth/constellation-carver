class_name Paragraph extends Control

const DEFAULT_MARGIN_TOP:int = 20
const DEFAULT_MARGIN_BOTTOM:int = 20
const DEFAULT_TEXT_ALIGN:String = "left"
const DEFAULT_SCALE:int = 1

var text:String
var style:ParticleParser.Style

func _init(text:String, style:ParticleParser.Style = null) -> void:
	self.text = text
	self.style = style
	
func get_style() -> Dictionary:
	var write:Dictionary = {}
	
	if style.margin_top != DEFAULT_MARGIN_TOP:
		write["margin-top"] = style.margin_top
	if style.margin_bottom != DEFAULT_MARGIN_BOTTOM:
		write["margin-bottom"] = style.margin_bottom
	if style.text_align != DEFAULT_TEXT_ALIGN:
		write["text-align"] = style.text_align
	if style.scale != DEFAULT_SCALE:
		write["scale"] = style.scale
		
	return write
	
func to_dict() -> Dictionary:
	var data:Dictionary = {
		"type": "paragraph",
		"text": text,
	}
	
	var style = get_style()
	if not style.is_empty():
		data.merge({"style": style})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict())
