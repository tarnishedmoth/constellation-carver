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


	var cchar:int = 0
	var is_open:bool = false
	while cchar != -1:
		var next_char:int = f.find(special_character, cchar)
		if next_char != -1:
			# Note that length returns the number of characters but string[0] is character 1.
			if f.length()-1 > next_char: # If this isn't the end
				if f[next_char] == f[next_char+1]: # If the next character is also
					# Escaped
					cchar = next_char + 2 # Skip past these characters
					continue

			cchar = next_char

			var insert:String = TextFormatting.do(type, is_open)
			is_open = !is_open # Toggle

			# Replace the stuff
			f = f.erase(next_char)
			f = f.insert(next_char, insert)

			cchar += insert.length() - 1 # Math cus we erase one character before adding our insert
			continue # Keep looping
		cchar = -1
	return f
