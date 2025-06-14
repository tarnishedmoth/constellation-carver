class_name TextFormatting

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
	var is_open:bool = false
	while char != -1:
		var next_char = f.find(special_character, char)
		if next_char != -1:
			# Note that length returns the number of characters but string[0] is character 1.
			if f.length()-1 > next_char: # If this isn't the end
				if f[next_char] == f[next_char+1]: # If the next character is also
					# Escaped
					char = next_char + 2 # Skip past these characters
					continue

			char = next_char

			var insert:String = TextFormatting.do(type, is_open)
			is_open = !is_open # Toggle

			# Replace the stuff
			f = f.erase(next_char)
			f = f.insert(next_char, insert)

			char += insert.length() - 1 # Math cus we erase one character before adding our insert
			continue # Keep looping
		char = -1
	return f
