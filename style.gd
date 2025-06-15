class_name Style

const _type:String = "style"

const DEFAULT_MARGIN_TOP:int = 20
const DEFAULT_MARGIN_BOTTOM:int = 20
const DEFAULT_TEXT_ALIGN:String = "left"
const DEFAULT_SCALE:int = 1

const TEXT_ALIGN_OPTIONS:Array[String] = [
	"left",
	"center",
	"right"
]

var text_align:String = DEFAULT_TEXT_ALIGN:
	set(value):
		if value in TEXT_ALIGN_OPTIONS:
			text_align = value
		else:
			push_error("Invalid text alignment assigned to style")

var margin_top:int = DEFAULT_MARGIN_TOP
var margin_bottom:int = DEFAULT_MARGIN_BOTTOM
var scale:int = DEFAULT_SCALE

func _init(params:Dictionary = {}) -> void:
	if not params.is_empty():
		if "margin-top" in params:
			margin_top = params["margin-top"]
		if "margin-bottom" in params:
			margin_bottom = params["margin-bottom"]
		if "scale" in params:
			scale = params["scale"]
		if "text-align" in params:
			text_align = params["text-align"]

func get_align_int() -> int:
	match text_align:
		"center": return 1
		"right": return 2
		_: return 0

func to_dict() -> Dictionary:
	var write:Dictionary = {}

	if margin_top != Style.DEFAULT_MARGIN_TOP:
		write["margin-top"] = margin_top
	if margin_bottom != Style.DEFAULT_MARGIN_BOTTOM:
		write["margin-bottom"] = margin_bottom
	if text_align != Style.DEFAULT_TEXT_ALIGN:
		write["text-align"] = text_align
	if scale != Style.DEFAULT_SCALE:
		write["scale"] = scale

	return write
