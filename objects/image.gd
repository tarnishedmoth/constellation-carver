class_name ConstellationImage extends Control

# TODO margins, helper methods for showing content & creating

const PLACEHOLDER_SCENE = preload("res://objects/placeholder.tscn")
var placeholder:Control # Instance

const DEFAULTS:Dictionary = {
	WIDTH = 16,
	HEIGHT = 16,
	PIXELS = "",
	SCALE = 1
}

const TEMPLATE = {
	"type": "image",
	"width": "16",
	"height": "16",
	"pixels": DEFAULTS.PIXELS
}

const _type:String = "image"

var _width:int:
	set(value):
		_width = value
		refresh_visuals()
var _height:int:
	set(value):
		_height = value
		refresh_visuals()
var _pixels:String:
	set(value):
		_pixels = value
		refresh_visuals()
var style:Style = Style.new():
	set(value):
		style = value
		refresh_visuals()

var display_image:TextureRect

var redraw_count:int = 0

func _init(width, height, pixels:String, rescale:int = 1) -> void:
	self._width = maxi(int(width), 0)
	self._height = maxi(int(height), 0)
	self._pixels = pixels

	self.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	self.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if rescale > 1: self.style.scale = rescale

	self.focus_mode = Control.FOCUS_CLICK

	self.tooltip_text = "Image"

func _ready() -> void:
	display_image = TextureRect.new()
	add_child(display_image)

	refresh_visuals()

func toggle_placeholder(on=true) -> void:
	if on:
		placeholder = PLACEHOLDER_SCENE.instantiate()
		#placeholder.custom_minimum_size = Vector2(_width*style.scale, _height*style.scale)
		placeholder.text = "Image\n%s x %s" % [_width, _height] # Label
		add_child(placeholder)
	else:
		if placeholder:
			placeholder.queue_free()


func centered(width:int) -> int: return 400/2 - width/2

func refresh_visuals() -> void:
	if not display_image:
		# Not set up yet
		return

	redraw_count += 1
	custom_minimum_size = Vector2i(_width*style.scale, _height*style.scale)

	if not _pixels.is_empty():
		var image = ConstellationImageProcessor.create_image_from(
			ConstellationImageProcessor.decompress_unicode(_pixels),
			_width,
			_height,
			style.scale
			)
		display_image.texture = ImageTexture.create_from_image(image)
		display_image.show()
		toggle_placeholder(false)
	else:
		display_image.hide()
		toggle_placeholder(true)
	queue_redraw()


func to_dict() -> Dictionary:
	var data:Dictionary = TEMPLATE.duplicate()
	data["width"] = _width
	data["height"] = _height
	data["pixels"] = _pixels

	if style:
		var style_output = style.to_dict(DEFAULTS)
		if not style_output.is_empty():
			data.merge({"style": style_output})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t", false)
