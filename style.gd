class_name Style

const DEFAULT_MARGIN_TOP:int = 20
const DEFAULT_MARGIN_BOTTOM:int = 20
const DEFAULT_TEXT_ALIGN:String = "left"
const DEFAULT_SCALE:int = 1

const TEXT_ALIGN_OPTIONS:Array[String] = [
	"left",
	"center",
	"right"
]

var text_align:String:
	set(value):
		if value in TEXT_ALIGN_OPTIONS:
			text_align = value
		else:
			push_error("Invalid text alignment assigned to style")
	get:
		if text_align:
			return text_align
		else:
			return DEFAULT_TEXT_ALIGN
var margin_top:int
var margin_bottom:int
var scale:int

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
