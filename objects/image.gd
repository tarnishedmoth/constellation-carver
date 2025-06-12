class_name ConstellationImage extends Control

const TEMPLATE = {
	"type": "image",
	"width": "0",
	"height": "0",
	"pixels": ""
}

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
var style:Style:
	set(value):
		style = value
		refresh_visuals()

func _init(width:int, height:int, pixels:String) -> void:
	self._width = maxi(width, 0)
	self._height = maxi(height, 0)
	self._pixels = pixels
	
	self.focus_mode = Control.FOCUS_CLICK
	
func _draw() -> void:
	draw_rect(
		Rect2i(
			centered(_width),
			0,
			_width,
			_height
		),
		Color.YELLOW
	)
	
func centered(width:int) -> int: return 400/2 - width/2

func refresh_visuals() -> void:
	custom_minimum_size = Vector2i(_width, _height)
	queue_redraw()
	#_data_to_pixels()
	
func _data_to_pixels(data:String) -> void:
	pass
	
func to_dict() -> Dictionary:
	var data:Dictionary = TEMPLATE.duplicate()
	data["width"] = _width
	data["height"] = _height
	data["pixels"] = _pixels
	
	if style:
		var style_output = style.to_dict()
		if not style_output.is_empty():
			data.merge({"style": style_output})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict())
