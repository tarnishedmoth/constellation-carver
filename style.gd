class_name Style

const DEFAULT_MARGIN_TOP:int = 20
const DEFAULT_MARGIN_BOTTOM:int = 20
const DEFAULT_TEXT_ALIGN:String = "left"
const DEFAULT_SCALE:int = 1

var text_align:String
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
