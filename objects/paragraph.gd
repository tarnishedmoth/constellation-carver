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
	static func replace(t:String, type:TYPES) -> String:
		var f:String = t
		
		var special_character:String
		if type == TYPES.BOLD:
			special_character = "*"
		elif type == TYPES.ITALIC:
			special_character = "_"
			
		
		var char:int = 0
		while char != -1:
			var is_open:bool = false
			var next_char = f.find(special_character, char)
			if next_char != -1:
				# Note that length returns the number of characters but string[0] is character 1.
				if f.length()-1 > next_char: # If this isn't the end
					if f[next_char] == f[next_char+1]: # If the next character is also 
						# Escaped
						char = next_char + 2 # Skip past these characters
						continue
						
				char = next_char
				
				var insert:String = Styling.do(type, is_open)
				is_open = !is_open # Toggle
				
				# Replace the stuff
				f = f.erase(next_char)
				f = f.insert(next_char, insert)
				
				char += insert.length() - 1 # Math cus we erase one character before adding our insert
				continue # Keep looping
			char = -1
		return f

var is_visual_current:bool = true

var _text:String:
	set(value):
		_text = value
		is_visual_current = false
		refresh_visuals()
var style:Style:
	set(value):
		style = value
		is_visual_current = false
		refresh_visuals()

func _prepare_text(t:String) -> String:
	var f:String = t
	
	# RichTextLabel uses bbcode for text alignment
	if style:
		if style.text_align == "center":
			f = f.insert(0, "[center]")
		elif style.text_align == "right":
			f = f.insert(0, "[right]")
	
	f = Styling.replace(f, Styling.TYPES.BOLD)
	f = Styling.replace(f, Styling.TYPES.ITALIC)
	
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
	is_visual_current = true
	
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
