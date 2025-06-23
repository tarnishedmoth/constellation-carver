class_name ConstellationImageProcessor extends Control

## NOTICE Some key code lovingly adapted from - https://browser.particlestudios.eu/
##     Thank you Bird.

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
var image_pixels:String
var copy_pixels:String
# _private
# @onready
@onready var vbox: VBoxContainer = $VBoxContainer

#endregion


#region--Virtuals
#func _init() -> void: pass
#func _enter_tree() -> void: pass
func _ready() -> void:
	test_binary()
	test_display_images()
	pass

func test_binary() -> void:
	var image:Image = Image.new().load_from_file(test_image)
	image.convert(Image.Format.FORMAT_RGB8)
	var binary_from_image:String = convert_rgb8_to_binary(image)
	var pixels_from_image:String = compress_binary(binary_from_image)
	var binary_from_pixels:String = decompress_unicode(pixels_from_image)

	var pixels_from_copy:String = compress_binary(binary_from_pixels)

	var equal:bool = (binary_from_pixels == binary_from_image)
	print("BINARIES ARE EQUAL: %s" % [equal])
	#if !equal:
		#print(pixels_from_image)

func test_display_images() -> void:
	var image:Image = Image.new().load_from_file(test_image)

	var preview_image_display:TextureRect = TextureRect.new()
	preview_image_display.texture = ImageTexture.create_from_image(image)
	vbox.add_child(preview_image_display)

	image.convert(Image.FORMAT_RGB8)
	var preview_binary_from_image_display:TextureRect = TextureRect.new()
	preview_binary_from_image_display.texture = ImageTexture.create_from_image(
		create_image_from(
			convert_rgb8_to_binary(image),
			image.get_width(),
			image.get_height()
		))
	vbox.add_child(preview_binary_from_image_display)

	var test_content:ConstellationImage = create_constellation_image_from(test_image)

	var preview_copy_display:TextureRect = TextureRect.new()
	preview_copy_display.texture = ImageTexture.create_from_image(
		create_image_from(
			decompress_unicode(test_content._pixels),
			test_content._width,
			test_content._height
			)
		)
	vbox.add_child(preview_copy_display)

#func _input(event: InputEvent) -> void: pass
#func _unhandled_input(event: InputEvent) -> void: pass
#func _physics_process(delta: float) -> void: pass
#func _process(delta: float) -> void: pass
#endregion
#region Public
static func convert_rgb8_to_binary(image:Image, brightness:float = 0.5) -> String:
	var buffer:String = ""
	for y in image.get_height():
		for x in image.get_width():
			var color:Color = image.get_pixel(x, y)
			var r:float = color.r
			var g:float = color.g
			var b:float = color.b
			var luminosity:float = (0.299 * r + 0.587 * g + 0.114 * b) ## TODO give sliders for user control

			var black_pixel:bool = luminosity < (1.0 - brightness)
			buffer += "1" if black_pixel else "0"

		buffer += " "

	buffer = buffer.strip_edges()
	return buffer

static func create_constellation_image_from(filepath:String, brightness:float = 0.5) -> ConstellationImage:
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


	var binary:String = convert_rgb8_to_binary(img, brightness)
	var compressed_pixels:String = compress_binary(binary)
	#var compressed_pct:int = 100 - roundi((compressed_pixels.length() / binary.length()) * 100)

	var converted_image:ConstellationImage = ConstellationImage.new(
		img.get_width(),
		img.get_height(),
		compressed_pixels
	)

	return converted_image


static func create_image_from(binary:String, width:int, height:int, rescale:int = 1) -> Image:
	var img:Image = Image.create_empty(width, height, false, Image.FORMAT_L8)

	var pos:Vector2i = Vector2i(0,0)
	var index:int = 0
	for c in binary:
		if c == " ":
			continue  # Skip row delimiters

		var column:int = index % width
		var row:int = floori(index / width)
		pos = Vector2i(column, row)

		var color:Color = Color.BLACK if c == "1" else Color.WHITE
		img.set_pixelv(pos, color)
		#var rect = Rect2i(pos * rescale, Vector2i(rescale, rescale))
		#img.fill_rect(rect, color)

		index += 1
	return img
#endregion

#region Compression
static func string_from_char_codes(arr:Array[int]) -> String:
	var result:String = ""
	for i in arr:
		result += String.chr(i)
	return result


## Accepts a binary string and compresses using alphabetical unicodes.
##
## This function will read the 0s and 1s from the passed in buffer, and will replace sequence of the
## same number with a letter. The value of a letter is based on it's position in the ABC, so
## to replace 1s, the uppercase "A" should replace "1", while uppercase "C" should replace "111".
## Always use the highest value letter possible, until the letter "Y" inclusive.
## To replace 0s, the same rule applies, but using lowercase letters.
## So "a" should replace "0", wherease "c" should replace "000".
## Do not affect other characters that aren't 0s or 1s.
## Then, return the result.
static func compress_binary(binary:String) -> String:
	var compressed:String = ""
	var count:int = 1
	var current:String = ""

	for i in binary.length():
		var _char = binary[i]

		## If not 0 or 1, add the current sequence compression, if any
		if _char != "0" && _char != "1":

			if not current.is_empty() && count > 0:
				compressed += _compress_sequence(int(current), count)
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
			compressed += _compress_sequence(int(current), count);
			current = _char;
			count = 1;

	## Add any remaining sequence
	if not current.is_empty() && count > 0:
		compressed += _compress_sequence(int(current), count)

	return compressed

static func _compress_sequence(character:int, count:int) -> String:
	## Maximum sequence length for a single letter is 25 (corresponds to 'Y')
	const max_letter_value = 25
	var result:String = ""

	## Process the sequence in chunks of up to max_letter_value
	var _characters:int = count
	while _characters > 0:
		var chunk_size:int = mini(_characters, max_letter_value)

		var letter_code:int = chunk_size + (64 if character == 1 else 96)

		result += string_from_char_codes([letter_code]) ## 100% sure I could just use char(letter_code) here but this is code parity.
		_characters -= chunk_size

	return result

## Decompression function to reverse `compress_sequence` output
static func decompress_unicode(compressed:String) -> String:
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
