class_name ConstellationReel extends Control

const PLACEHOLDER_SCENE = preload("res://objects/placeholder.tscn")
var placeholder:Control # Instance

const TEMPLATE = {
	"type": "reel",
	"width": "1", # irange 1-200
	"height": "1", # irange 1-120
	"frames": []
	#frame-duration default 2, irange 1-1800. Divide 30 by this for framerate
}
const _type:String = "reel"
var _size:Vector2i:
	get:
		return Vector2i(_width, _height)
var _width:int:
	set(value):
		_width = value
		refresh_visuals()
var _height:int:
	set(value):
		_height = value
		refresh_visuals()
var _frames:Array:
	set(value):
		_frames = value
		refresh_visuals()
var _frame_duration:int:
	set(value):
		_frame_duration = clampi(value, 1, 1800)
		refresh_visuals()
var style:Style = Style.new():
	set(value):
		style = value
		refresh_visuals()

func _init(width:int, height:int, frames:Array, rescale:int = 2) -> void:
	self._width = maxi(width, 0)
	self._height = maxi(height, 0)
	self._frames = frames
	
	self.focus_mode = Control.FOCUS_CLICK
	
func _ready() -> void:
	toggle_placeholder(true)

#func _draw() -> void:
	#draw_texture_rect(
		#TEXTURE,
		#Rect2i(
			#centered(_width*style.scale),
			#0,
			#_width*style.scale,
			#_height*style.scale
		#),
		#false
		##Color.YELLOW
	#)

func toggle_placeholder(on=true) -> void:
	if on:
		placeholder = PLACEHOLDER_SCENE.instantiate()
		#placeholder.size = _size
		placeholder.text = "Reel\n%s frames | %s x %s" % [_frames.size(), _width, _height] # Label
		add_child(placeholder)
	else:
		if placeholder:
			placeholder.queue_free()
	
func centered(width:int) -> int: return 400/2 - width/2

func refresh_visuals() -> void:
	custom_minimum_size = Vector2i(
		clampi(_width*style.scale, 0, 400), ## HACK
		_height*style.scale
		)
	queue_redraw()
	#_data_to_pixels()
	
func _data_to_pixels(data:String) -> void:
	pass
	
func to_dict() -> Dictionary:
	var data:Dictionary = TEMPLATE.duplicate()
	data["width"] = _width
	data["height"] = _height
	data["frames"] = _frames
	if _frame_duration:
		data["frame-duration"] = _frame_duration
	
	if style:
		var style_output = style.to_dict()
		if not style_output.is_empty():
			data.merge({"style": style_output})
	return data

func _to_string() -> String:
	return JSON.stringify(to_dict(), "\t", false)
