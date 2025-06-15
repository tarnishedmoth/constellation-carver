class_name Style

const _type:String = "style"

const DEFAULTS:Dictionary = {
	TEXT_ALIGN = "left",
	MARGIN_TOP = 20,
	MARGIN_BOTTOM = 20,
	SCALE_IMAGE = 1,
	SCALE_REEL = 2
}

const DEFAULT:Dictionary = {
	"text-align" = "left",
	"margin-top" = 20,
	"margin-bottom" = 20,
	"scale" = 1
}

const TEXT_ALIGN_OPTIONS:Array[String] = [
	"left",
	"center",
	"right"
]

var text_align:String = DEFAULT["text-align"]:
	set(value):
		if value in TEXT_ALIGN_OPTIONS:
			text_align = value
		else:
			push_error("Invalid text alignment assigned to style")

var margin_top:int = DEFAULT["margin-top"]

var margin_bottom:int = DEFAULT["margin-bottom"]

var scale:int = DEFAULT["scale"]:
	set(value):
		scale = clampi(value, 1, 4)

func _init(params:Dictionary = {}) -> void:
	if not params.is_empty():
		if "text-align" in params:
			text_align = params["text-align"]
		if "margin-top" in params:
			margin_top = params["margin-top"]
		if "margin-bottom" in params:
			margin_bottom = params["margin-bottom"]
		if "scale" in params:
			scale = params["scale"]

func get_align_int() -> int:
	match text_align:
		"center": return 1
		"right": return 2
		_: return 0

## Will return a 'String' if given an 'int', and vice versa.
static func get_align(value:Variant) -> Variant:
	if value is String:
		match value.to_lower():
			"center": return 1
			"right": return 2
			_: return 0
	if value is int:
		match value:
			1: return "center"
			2: return "right"
			_: return "left"
	push_error("Invalid value passed to static method get_align(v) -> String/Int")
	return null

## Returns a Dictionary that only contains key-value pairs of Style parameters
##     that don't match the KVPs provided in Defaults.
func get_modified_properties(defaults:Dictionary = DEFAULT) -> Dictionary:
	var _defaults:Dictionary = DEFAULT.duplicate()
	_defaults.merge(defaults, true)

	var write:Dictionary = {}

	#if text_align:
	if text_align != _defaults["text-align"]:
		write["text-align"] = text_align

	#if margin_top:
	if margin_top != int(_defaults["margin-top"]):
		write["margin-top"] = margin_top

	#if margin_bottom:
	if margin_bottom != int(_defaults["margin-bottom"]):
		write["margin-bottom"] = margin_bottom

	#if scale:
	if scale != int(_defaults["scale"]):
		write["scale"] = scale

	return write


func to_dict(defaults:Dictionary = DEFAULT) -> Dictionary:
	var write:Dictionary = get_modified_properties(defaults)
	return write
