class_name Paragraph extends RichTextLabel

const FONT = preload("res://objects/paragraph_font.tres")

class Styling:
	enum TYPES {
		BOLD,
		ITALIC
	}
	static func do(type:TYPES, is_open:bool = false) -> String:
		match type:
			TYPES.BOLD:
				if is_open: return "[/b]"
				else: return "[b]"
			TYPES.ITALIC:
				if is_open: return "[/i]"
				else: return "[i]"
			_:
				push_error("Invalid enum integer")
				return ""

var _text:String:
	set(value):
		_text = value
		text = _prepare_text(value) # Because special formatting on PD
var style:Style

func _prepare_text(t:String) -> String:
	var f:String = t
	
	var char:int = 0
	while char != -1: # Set to -1 manually to exit
		var is_bold:bool = false
		var next_bold = f.find("*", char)
		if next_bold != -1:
			# Note that length returns the number of characters but string[0] is character 1.
			if f.length()-1 > next_bold: # If this isn't the end
				if f[next_bold] == f[next_bold+1]: # If the next character is also 
					# Escaped
					char = next_bold + 2 # Skip past these characters
					continue
					
			char = next_bold
			
			var insert:String = Styling.do(Styling.TYPES.BOLD, is_bold)
			is_bold = !is_bold # Toggle
			
			# Replace the stuff
			f = f.erase(next_bold)
			f = f.insert(next_bold, insert)
			
			char += insert.length() - 1 # Math cus we erase one character before adding our insert
			continue # Keep looping
		char = -1
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
	
	
#func _draw() -> void:
	#var location = Vector2(global_position.x, global_position.y - 14)
	#draw_string(FONT, location, _prepare_text(_text), HORIZONTAL_ALIGNMENT_LEFT, 0, 14, Color.BLACK)
	
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
