class_name Paragraph extends RichTextLabel

const FONT = preload("res://objects/paragraph_font.tres")

var _text:String:
	set(value):
		_text = value
		refresh_visuals()
var style:Style:
	set(value):
		style = value
		refresh_visuals()

func _prepare_text(t:String) -> String:
	var f:String = t
	
	# RichTextLabel uses bbcode for text alignment
	if style:
		if style.text_align == "center":
			f = f.insert(0, "[center]")
		elif style.text_align == "right":
			f = f.insert(0, "[right]")
	
	f = TextFormatting.replace(f, TextFormatting.TYPES.BOLD)
	f = TextFormatting.replace(f, TextFormatting.TYPES.ITALIC)
	
	return f

func _init(titties:String, style:Style = null) -> void:
	self._text = titties
	self.style = style
	
	self.fit_content = true
	self.bbcode_enabled = true
	self.scroll_active = false
	self.autowrap_mode = TextServer.AUTOWRAP_WORD
	self.context_menu_enabled = true ## TODO
	self.meta_underlined = false
	self.hint_underlined = false

func refresh_visuals() -> void:
	text = _prepare_text(_text) # Because special formatting on PD
	
	
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
