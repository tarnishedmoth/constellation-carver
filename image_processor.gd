class_name ConstellationImageProcessor extends Control

#region-- signals
#endregion


#region--Variables
# statics
# Enums
# constants
const IMAGE_MAX_WIDTH = 400
const IMAGE_MAX_HEIGHT = 260
# @exports
@export_file() var test_image:String
# public
# _private
# @onready
#endregion


#region--Virtuals
#func _init() -> void: pass
#func _enter_tree() -> void: pass
func _ready() -> void:
	var new_image = process_image(test_image)
	add_child(new_image)
	print_debug(new_image)
	pass
#func _input(event: InputEvent) -> void: pass
#func _unhandled_input(event: InputEvent) -> void: pass
#func _physics_process(delta: float) -> void: pass
#func _process(delta: float) -> void: pass
#endregion
#region Public
func process_image(filepath:String, brightness:float = 0.5) -> ConstellationImage:
	if not filepath.is_absolute_path():
		push_error("process_image(): Bad Path")
		return null
	if not FileAccess.file_exists(filepath):
		push_error("process_image(): Bad Path")
		return null

	var img:Image = Image.load_from_file(filepath)
	img.convert(Image.FORMAT_RGB8)

	if img.get_width() > IMAGE_MAX_WIDTH or img.get_height() > IMAGE_MAX_HEIGHT:
		U.l("Image dimensions can only be up to %sx%s pixels." % [IMAGE_MAX_WIDTH, IMAGE_MAX_HEIGHT])
		return null


	var buffer:String = ""
	for y in img.get_height():
		for x in img.get_width():
			var color:Color = img.get_pixel(x, y)
			var r:float = color.r
			var g:float = color.g
			var b:float = color.b
			var luminosity:float = (0.299 * r + 0.587 * g + 0.114 * b) ## TODO give sliders for user control

			var blackPixel:bool = luminosity < (1.0 - brightness)
			buffer += "1" if blackPixel else "0"

		buffer += " "

	buffer = buffer.strip_edges()
	var compressedBuffer = compress_buffer(buffer)
	var compressedPercentage:int = 100 - roundi((compressedBuffer.length() / buffer.length()) * 100)

	var converted_image:ConstellationImage = ConstellationImage.new(
		img.get_width(),
		img.get_height(),
		compressedBuffer
	)

	return converted_image

#endregion

#region Compression
func string_from_char_codes(arr:Array[int]) -> String:
	var result:String = ""
	for i in arr:
		result += String.chr(i)
	return result

## Code lovingly taken from - https://browser.particlestudios.eu/js/shared.js
## Thank you Bird
func compress_sequence(character:int, count:int) -> String:
	## Maximum sequence length for a single letter is 25 (corresponds to 'Y')
	const max_letter_value = 25
	var result:String = ""
	var _characters:int = count

	## Process the sequence in chunks of up to maxLetterValue
	while _characters > 0:
		var chunk_size:int = mini(count, max_letter_value)
		#var _ternary:int = 64 if char == 1 else 96
		var letter_code:int = chunk_size + (64 if character == 1 else 96)
		result += string_from_char_codes([letter_code]) ## 100% sure I could just use char(letter_code) here but this is code parity.
		_characters -= chunk_size

	return result


## This function will read the 0s and 1s from the passed in buffer, and will replace sequence of the
## same number with a letter. The value of a letter is based on it's position in the ABC, so
## to replace 1s, the uppercase "A" should replace "1", while uppercase "C" should replace "111".
## Always use the highest value letter possible, until the letter "Y" inclusive.
## To replace 0s, the same rule applies, but using lowercase letters.
## So "a" should replace "0", wherease "c" should replace "000".
## Do not affect other characters that aren't 0s or 1s.
## Then, return the result.
func compress_buffer(buffer:String) -> String:
	var compressed:String = ""
	var count:int = 1
	var current:String = ""

	var iter:int = 0
	for i in buffer.length():
		var _char = buffer[iter]

		## If not 0 or 1, add the current sequence compression, if any
		if _char != "0" && _char != "1":

			if not current.is_empty() && count > 0:
				compressed += compress_sequence(int(current), count)
				count = 1

			## Add the non-binary character as is
			compressed += _char
			current = ""

		elif current.is_empty():
			## Start a new sequence
			current = _char

		elif _char == current:
			## Continue the current sequence
			count += 1

		else:
			## End the current sequence and start a new one
			compressed += compress_sequence(int(current), count);
			current = _char;
			count = 1;

		iter += 1

	## Add any remaining sequence
	if not current.is_empty() && count > 0:
		compressed += compress_sequence(int(current), count)

	return compressed

## Decompression function to reverse `compress_sequence` output
static func decompress_buffer(compressed:String) -> String:
	var uncompressed:String = ""

	for c in compressed.length():
		var code:int = compressed.unicode_at(c)

		# Uppercase: 65 ('A') to 89 ('Y') => 1s
		# Lowercase: 97 ('a') to 121 ('y') => 0s
		if code >= 65 and code <= 89:
			var count:int = code - 64
			uncompressed += "1".repeat(count)
		elif code >= 97 and code <= 121:
			var count:int = code - 96
			uncompressed += "0".repeat(count)
		else:
			# Leave other characters as-is
			uncompressed += char(code)

	return uncompressed

#endregion
